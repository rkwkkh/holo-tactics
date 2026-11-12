class_name ContentValidator
extends RefCounted

static func validate(catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for version_key in ["content_version", "schema_version"]:
		var version: Variant = catalog.get(version_key)
		if not (version is int or version is float) or version < 1 or floor(float(version)) != float(version):
			errors.append("%s must be a positive integer" % version_key)
		elif version != (ProjectVersions.CONTENT_VERSION if version_key == "content_version" else ProjectVersions.SCHEMA_VERSION):
			errors.append("unsupported %s: %s" % [version_key, version])
	var categories: Variant = catalog.get("categories", {})
	if not categories is Dictionary:
		errors.append("categories must be an object")
		return errors
	var ids: Dictionary = {}
	for category in categories:
		if not categories[category] is Array:
			errors.append("category %s must be an array" % category)
			continue
		for item in categories[category]:
			if not item is Dictionary or not item.get("id", "") is String or item.get("id", "").is_empty():
				errors.append("category %s contains an item without a stable id" % category)
				continue
			var id: String = item.id
			if ids.has(id):
				errors.append("duplicate content id: %s" % id)
			else:
				ids[id] = true
	for category in categories:
		if not categories[category] is Array:
			continue
		for item in categories[category]:
			if not item is Dictionary:
				continue
			var dependencies: Variant = item.get("dependencies", [])
			if not dependencies is Array:
				errors.append("%s dependencies must be an array" % item.get("id", "<missing-id>"))
			else:
				for target in dependencies:
					if not target is String or not ids.has(target):
						errors.append("%s has unresolved dependency: %s" % [item.get("id", "<missing-id>"), target])
			if not item.get("references", []) is Array:
				errors.append("%s references must be an array" % item.get("id", "<missing-id>"))
				continue
			for target in item.get("references", []):
				if not target is String or not ids.has(target):
					errors.append("%s has unresolved reference: %s" % [item.get("id", "<missing-id>"), target])
	var wave_items := _as_array(categories.get("waves", []))
	var unit_items := _as_array(categories.get("units", []))
	var stage_items := _as_array(categories.get("stages", []))
	var unit_teams: Dictionary = {}
	var facility_teams: Dictionary = {}
	var profile_ids := _ids_in(_as_array(categories.get("ai_profiles", [])))
	for unit in unit_items:
		if not unit is Dictionary:
			continue
		var unit_id: String = unit.get("id", "<missing-id>")
		if unit.get("team") not in ["ally", "enemy"]:
			_append_field_error(errors, unit_id, "team", "invalid combat or cost data")
		if unit.get("movement_type") != "ground":
			_append_field_error(errors, unit_id, "movement_type", "unsupported movement type")
		for field in ["hp", "damage", "range", "attack_time", "cost", "heal", "heal_range", "splash_radius"]:
			var value: Variant = unit.get(field, 0 if field in ["heal", "heal_range", "splash_radius"] else null)
			var valid := _is_nonnegative_integer(value) if field in ["cost", "heal_range", "splash_radius"] else _is_nonnegative_number(value) if field == "heal" else _is_positive_integer(value) if field == "range" else _is_positive_number(value)
			if not valid:
				_append_field_error(errors, unit_id, field, "invalid combat or cost data")
		if _is_positive_number(unit.get("heal", 0)) and (not _is_positive_integer(unit.get("heal_range", 0)) or unit.get("team") not in ["ally", "enemy"]):
			_append_field_error(errors, unit_id, "heal_range|team", "invalid unit healing data")
		if _is_positive_integer(unit.get("splash_radius", 0)) and not _is_positive_number(unit.get("damage", 0)):
			_append_field_error(errors, unit_id, "damage|splash_radius", "invalid unit splash data")
		unit_teams[unit_id] = unit.get("team", "")
		if unit.get("team") == "enemy":
			var profile_id: Variant = unit.get("ai_profile_id", "")
			var references: Variant = unit.get("references", [])
			if not profile_ids.has(profile_id) or not references is Array or not references.has(profile_id):
				_append_field_error(errors, unit_id, "ai_profile_id|references", "must reference an AI profile")
	var upgrade_counts: Dictionary = {}
	for upgrade in _as_array(categories.get("upgrades", [])):
		if not upgrade is Dictionary:
			continue
		var levels: Variant = upgrade.get("values", [])
		var costs: Variant = upgrade.get("costs", [])
		var matches: Array = unit_items.filter(func(unit): return unit is Dictionary and unit.get("kind") == upgrade.get("unit_kind") and unit.get("team") == "ally")
		var effect: Variant = upgrade.get("effect", null)
		var upgrade_id: String = upgrade.get("id", "<missing-id>")
		if matches.size() != 1:
			_append_field_error(errors, upgrade_id, "unit_kind", "invalid combat upgrade data")
		if not levels is Array or levels.size() != 3 or levels.any(func(value): return not _is_positive_number(value)):
			_append_field_error(errors, upgrade_id, "values", "invalid combat upgrade data")
		if not costs is Array or costs.size() != 3 or costs.any(func(value): return not _is_positive_integer(value)):
			_append_field_error(errors, upgrade_id, "costs", "invalid combat upgrade data")
		if not effect is String or effect not in ["combo", "bleed", "splash", "charge", "pierce", "multishot", "freeze", "pushback", "counter", "taunt", "defense", "heal_area", "shield", "attack_buff", "cleanse", "chain", "burn", "mana_burst"]:
			_append_field_error(errors, upgrade_id, "effect", "invalid combat upgrade data")
		upgrade_counts[upgrade.get("unit_kind", "")] = int(upgrade_counts.get(upgrade.get("unit_kind", ""), 0)) + 1
	for unit in unit_items:
		if categories.has("upgrades") and unit is Dictionary and unit.get("team") == "ally" and upgrade_counts.get(unit.get("kind", ""), 0) != 4:
			errors.append("%s must have exactly four combat upgrades" % unit.get("id", "<missing-id>"))
	var evolution_items := _as_array(categories.get("evolutions", []))
	if categories.has("evolutions") and evolution_items.size() != 6:
		errors.append("evolutions must contain exactly six forms")
	var upgrade_definitions: Dictionary = {}
	for upgrade in _as_array(categories.get("upgrades", [])):
		if upgrade is Dictionary:
			upgrade_definitions[upgrade.get("id", "")] = upgrade
	for evolution in evolution_items:
		if not evolution is Dictionary:
			continue
		var evolution_id: String = evolution.get("id", "<missing-id>")
		var evolution_unit: String = evolution.get("unit_kind", "")
		var matching_units: Array = unit_items.filter(func(unit): return unit is Dictionary and unit.get("team") == "ally" and unit.get("kind") == evolution_unit)
		if matching_units.size() != 1 or not evolution.get("label") is String or evolution.get("label", "").is_empty() or not _is_positive_integer(evolution.get("total_upgrade_levels")) or int(evolution.get("total_upgrade_levels", 0)) > 12 or not _is_positive_integer(evolution.get("combat_cost")):
			_append_field_error(errors, evolution_id, "unit_kind|label|total_upgrade_levels|combat_cost", "invalid evolution data")
		var requirements: Variant = evolution.get("required_upgrades")
		if not requirements is Dictionary or requirements.is_empty():
			_append_field_error(errors, evolution_id, "required_upgrades", "invalid evolution requirements")
		else:
			var required_levels := 0
			for upgrade_id in requirements:
				var upgrade: Dictionary = upgrade_definitions.get(upgrade_id, {})
				var level: Variant = requirements[upgrade_id]
				if upgrade.is_empty() or upgrade.get("unit_kind") != evolution_unit or not _is_positive_integer(level) or int(level) > 3:
					_append_field_error(errors, evolution_id, "required_upgrades", "invalid evolution requirements")
				else:
					required_levels += int(level)
			if _is_positive_integer(evolution.get("total_upgrade_levels")) and required_levels > int(evolution.total_upgrade_levels):
				_append_field_error(errors, evolution_id, "required_upgrades", "invalid evolution requirements")
		var references: Variant = evolution.get("references", [])
		if not references is Array or not references.has("unit.%s" % evolution_unit):
			_append_field_error(errors, evolution_id, "references", "invalid evolution references")
		elif requirements is Dictionary:
			for upgrade_id in requirements:
				if not references.has(upgrade_id):
					_append_field_error(errors, evolution_id, "references", "invalid evolution references")
					break
		var special_skill: Variant = evolution.get("special_skill")
		if not special_skill is Dictionary or special_skill.get("mode") not in ["automatic", "manual"] or special_skill.get("effect") not in ["strike", "area", "heal", "shield"] or not _is_positive_number(special_skill.get("cooldown")) or not _is_nonnegative_integer(special_skill.get("cost")) or not _is_positive_number(special_skill.get("value")) or not _is_nonnegative_integer(special_skill.get("radius")) or not special_skill.get("label") is String or special_skill.get("label", "").is_empty():
			_append_field_error(errors, evolution_id, "special_skill.mode|effect|cooldown|cost|value|radius|label", "invalid evolution special skill")
	var skill_modes: Dictionary = {}
	for skill in _as_array(categories.get("skills", [])):
		if not skill is Dictionary:
			continue
		var matches: Array = unit_items.filter(func(unit): return unit is Dictionary and unit.get("kind") == skill.get("unit_kind") and unit.get("team") == "ally")
		var skill_id: String = skill.get("id", "<missing-id>")
		if matches.size() != 1:
			_append_field_error(errors, skill_id, "unit_kind", "invalid skill data")
		if skill.get("mode") not in ["automatic", "manual"]:
			_append_field_error(errors, skill_id, "mode", "invalid skill data")
		if skill.get("effect") not in ["strike", "area", "heal", "shield"]:
			_append_field_error(errors, skill_id, "effect", "invalid skill data")
		if not _is_positive_number(skill.get("cooldown")):
			_append_field_error(errors, skill_id, "cooldown", "invalid skill data")
		if not _is_nonnegative_integer(skill.get("cost")):
			_append_field_error(errors, skill_id, "cost", "invalid skill data")
		if not _is_positive_number(skill.get("value")):
			_append_field_error(errors, skill_id, "value", "invalid skill data")
		if not _is_nonnegative_integer(skill.get("radius")):
			_append_field_error(errors, skill_id, "radius", "invalid skill data")
		if not skill.get("label") is String:
			_append_field_error(errors, skill_id, "label", "invalid skill data")
		var mode_key := "%s:%s" % [skill.get("unit_kind", ""), skill.get("mode", "")]
		skill_modes[mode_key] = int(skill_modes.get(mode_key, 0)) + 1
	for unit in unit_items:
		if unit is Dictionary and unit.get("team") == "ally":
			for mode in ["automatic", "manual"]:
				if categories.has("skills") and skill_modes.get("%s:%s" % [unit.get("kind", ""), mode], 0) != 1:
					errors.append("%s must have one %s skill" % [unit.get("id", "<missing-id>"), mode])
	for facility in _as_array(categories.get("facilities", [])):
		if not facility is Dictionary:
			continue
		facility_teams[facility.get("id", "")] = facility.get("team", "")
		var facility_id: String = facility.get("id", "<missing-id>")
		var valid_damage := _is_nonnegative_number(facility.get("damage"))
		var valid_heal := _is_nonnegative_number(facility.get("heal", 0))
		var valid_splash_radius := _is_nonnegative_integer(facility.get("splash_radius", 0))
		var valid_range := _is_nonnegative_integer(facility.get("range"))
		var valid_attack_time := _is_nonnegative_number(facility.get("attack_time"))
		if facility.get("team") not in ["ally", "enemy"]:
			_append_field_error(errors, facility_id, "team", "invalid facility data")
		if not _is_positive_number(facility.get("hp")):
			_append_field_error(errors, facility_id, "hp", "invalid facility data")
		if not valid_damage:
			_append_field_error(errors, facility_id, "damage", "invalid facility data")
		if not valid_heal:
			_append_field_error(errors, facility_id, "heal", "invalid facility data")
		if not valid_splash_radius:
			_append_field_error(errors, facility_id, "splash_radius", "invalid facility data")
		if not valid_range:
			_append_field_error(errors, facility_id, "range", "invalid facility data")
		if not valid_attack_time:
			_append_field_error(errors, facility_id, "attack_time", "invalid facility data")
		if not _is_nonnegative_integer(facility.get("cost")):
			_append_field_error(errors, facility_id, "cost", "invalid facility data")
		if not facility.get("blocks_path") is bool:
			_append_field_error(errors, facility_id, "blocks_path", "invalid facility data")
		if valid_damage and facility.damage > 0 and valid_range and facility.range < 1:
			_append_field_error(errors, facility_id, "range", "invalid facility attack data")
		if valid_damage and facility.damage > 0 and valid_attack_time and facility.attack_time <= 0:
			_append_field_error(errors, facility_id, "attack_time", "invalid facility attack data")
		if valid_splash_radius and facility.splash_radius > 0 and valid_damage and facility.damage <= 0:
			_append_field_error(errors, facility_id, "damage", "invalid facility splash data")
		if valid_heal and facility.heal > 0 and valid_range and facility.range < 1:
			_append_field_error(errors, facility_id, "range", "invalid facility healing data")
		if valid_heal and facility.heal > 0 and valid_attack_time and facility.attack_time <= 0:
			_append_field_error(errors, facility_id, "attack_time", "invalid facility healing data")
		if valid_heal and facility.heal > 0 and facility.team != "ally":
			_append_field_error(errors, facility_id, "team", "invalid facility healing data")
	for obstacle in _as_array(categories.get("obstacles", [])):
		if not obstacle is Dictionary:
			continue
		var obstacle_id: String = obstacle.get("id", "<missing-id>")
		if not obstacle.get("kind") is String or obstacle.get("kind", "").is_empty():
			_append_field_error(errors, obstacle_id, "kind", "invalid obstacle data")
		var blocked_movement_types: Variant = obstacle.get("blocked_movement_types")
		if not blocked_movement_types is Array or blocked_movement_types.is_empty() or blocked_movement_types.any(func(movement_type): return movement_type != "ground"):
			_append_field_error(errors, obstacle_id, "blocked_movement_types", "invalid obstacle movement types")
		if not _is_nonnegative_integer(obstacle.get("cost")):
			_append_field_error(errors, obstacle_id, "cost", "invalid obstacle data")
	var town_buildings := _as_array(categories.get("town_buildings", []))
	for research in _as_array(categories.get("research", [])):
		if not research is Dictionary:
			continue
		var research_units: Array = unit_items.filter(func(unit): return unit is Dictionary and unit.get("kind") == research.get("unit_kind") and unit.get("team") == "ally")
		var research_buildings: Array = town_buildings.filter(func(building): return building is Dictionary and building.get("kind") == research.get("building_kind"))
		var research_id: String = research.get("id", "<missing-id>")
		if research_units.size() != 1:
			_append_field_error(errors, research_id, "unit_kind", "has invalid permanent research data")
		if research_buildings.size() != 1:
			_append_field_error(errors, research_id, "building_kind", "has invalid permanent research data")
		if research.get("stat") != "damage":
			_append_field_error(errors, research_id, "stat", "has invalid permanent research data")
		if not _is_positive_number(research.get("amount")):
			_append_field_error(errors, research_id, "amount", "has invalid permanent research data")
		if not _is_nonnegative_integer(research.get("cost")):
			_append_field_error(errors, research_id, "cost", "has invalid permanent research data")
		if not ids.has(research.get("requires_stage", "")):
			_append_field_error(errors, research_id, "requires_stage", "has invalid permanent research data")
	for profile in _as_array(categories.get("ai_profiles", [])):
		var weights: Variant = profile.get("weights") if profile is Dictionary else null
		if not weights is Dictionary or weights.is_empty():
			errors.append("%s must define AI weights" % (profile.get("id", "<missing-id>") if profile is Dictionary else "<missing-id>"))
			continue
		for action in weights:
			if not action is String or not _is_positive_number(weights[action]):
				errors.append("%s has an invalid AI weight" % profile.get("id", "<missing-id>"))
	for wave in wave_items:
		if wave is Dictionary and (unit_teams.get(wave.get("enemy_id", "")) != "enemy" or not wave.get("references", []) is Array or not wave.get("references", []).has(wave.get("enemy_id", "")) or not _is_positive_integer(wave.get("count"))):
			errors.append("%s must reference an enemy and have a positive integer count" % wave.get("id", "<missing-id>"))
		if wave is Dictionary and wave.has("ai_weight_overrides"):
			var overrides: Variant = wave.ai_weight_overrides
			if not overrides is Dictionary:
				errors.append("%s AI weight overrides must be an object" % wave.get("id", "<missing-id>"))
			else:
				for action in overrides:
					if not action is String or not _is_positive_number(overrides[action]):
						errors.append("%s has an invalid AI weight override" % wave.get("id", "<missing-id>"))
		if wave is Dictionary and wave.has("reinforcements"):
			var reinforcements: Variant = wave.reinforcements
			if not reinforcements is Array:
				errors.append("%s reinforcements must be an array" % wave.get("id", "<missing-id>"))
			else:
				for group in reinforcements:
					var spawn: Variant = group.get("spawn", []) if group is Dictionary else null
					var enemy_id: Variant = group.get("enemy_id", "") if group is Dictionary else null
					if not group is Dictionary or unit_teams.get(enemy_id) != "enemy" or not _is_positive_integer(group.get("count")) or not _is_nonnegative_number(group.get("at")) or not _is_integer_cell(spawn):
						errors.append("%s has invalid reinforcement data" % wave.get("id", "<missing-id>"))
					elif not wave.get("references", []).has(enemy_id):
						errors.append("%s reinforcement enemy must be referenced" % wave.get("id", "<missing-id>"))
	for stage in stage_items:
		if not stage is Dictionary:
			continue
		if stage.has("obstacle_max_owned") or stage.has("obstacle_max_placed"):
			var max_owned: Variant = stage.get("obstacle_max_owned")
			var max_placed: Variant = stage.get("obstacle_max_placed")
			var obstacle_refs := _ids_in(_as_array(categories.get("obstacles", [])))
			var stage_references: Variant = stage.get("references", [])
			var invalid_limits := not _is_nonnegative_integer(max_owned) or not _is_nonnegative_integer(max_placed)
			if not invalid_limits:
				invalid_limits = max_placed > max_owned
			if not invalid_limits and max_owned > 0:
				invalid_limits = not stage_references is Array or not stage_references.any(func(reference): return obstacle_refs.has(reference))
			if invalid_limits:
				_append_field_error(errors, stage.get("id", "<missing-id>"), "obstacle_max_owned|obstacle_max_placed|references", "invalid obstacle limits or missing obstacle reference")
		var available_units: Variant = stage.get("available_units", [])
		var stage_references: Variant = stage.get("references", [])
		if not available_units is Array or available_units.is_empty():
			errors.append("%s must list available units" % stage.get("id", "<missing-id>"))
		else:
			for kind in available_units:
				var matching_units: Array = unit_items.filter(func(unit): return unit is Dictionary and unit.get("kind") == kind and unit.get("team") == "ally")
				if matching_units.size() != 1 or not stage_references is Array or not stage_references.has(matching_units[0].get("id", "")):
					errors.append("%s has invalid available unit: %s" % [stage.get("id", "<missing-id>"), kind])
		var columns := int(stage.get("columns", 0))
		var rows := int(stage.get("rows", 0))
		var core_cell: Variant = stage.get("core_cell", [])
		if not _is_positive_integer(stage.get("columns")) or not _is_positive_integer(stage.get("rows")) or not core_cell is Array or core_cell.size() != 2 or not _is_nonnegative_integer(core_cell[0]) or not _is_nonnegative_integer(core_cell[1]) or int(core_cell[0]) >= columns or int(core_cell[1]) >= rows:
			errors.append("%s has invalid board dimensions or core cell" % stage.get("id", "<missing-id>"))
		if stage.get("mode") not in ["defense", "siege"]:
			errors.append("%s has an unknown battle mode" % stage.get("id", "<missing-id>"))
		var enemy_spawn_row := int(stage.get("enemy_spawn_row", 0))
		if enemy_spawn_row < 0 or enemy_spawn_row >= rows:
			errors.append("%s has an invalid enemy spawn row" % stage.get("id", "<missing-id>"))
		var blocked_cells: Variant = stage.get("blocked_cells", [])
		var blocked: Dictionary = {}
		if not blocked_cells is Array:
			errors.append("%s blocked_cells must be an array" % stage.get("id", "<missing-id>"))
		else:
			for cell in blocked_cells:
				if not cell is Array or cell.size() != 2 or not _is_nonnegative_integer(cell[0]) or not _is_nonnegative_integer(cell[1]) or int(cell[0]) >= columns or int(cell[1]) >= rows:
					errors.append("%s has an invalid blocked cell" % stage.get("id", "<missing-id>"))
					continue
				var blocked_cell := Vector2i(int(cell[0]), int(cell[1]))
				if blocked.has(blocked_cell):
					errors.append("%s has a duplicate blocked cell" % stage.get("id", "<missing-id>"))
				blocked[blocked_cell] = true
		if core_cell is Array and core_cell.size() == 2 and _is_nonnegative_integer(core_cell[0]) and _is_nonnegative_integer(core_cell[1]) and blocked.has(Vector2i(int(core_cell[0]), int(core_cell[1]))):
			errors.append("%s blocks its core cell" % stage.get("id", "<missing-id>"))
		var wall_cells: Dictionary = {}
		var wall_data: Variant = stage.get("walls", [])
		if not wall_data is Array:
			errors.append("%s walls must be an array" % stage.get("id", "<missing-id>"))
		else:
			for wall in wall_data:
				var cell: Variant = wall.get("cell", []) if wall is Dictionary else null
				if not wall is Dictionary or not _is_integer_cell(cell) or int(cell[0]) >= columns or int(cell[1]) >= rows or not _is_positive_number(wall.get("hp")):
					errors.append("%s has invalid wall data" % stage.get("id", "<missing-id>"))
					continue
				var wall_cell := Vector2i(int(cell[0]), int(cell[1]))
				if blocked.has(wall_cell) or wall_cell == Vector2i(int(core_cell[0]), int(core_cell[1])) or wall_cells.has(wall_cell):
					errors.append("%s has a conflicting wall cell" % stage.get("id", "<missing-id>"))
				wall_cells[wall_cell] = true
		for reference in stage.get("references", []):
			for wave in wave_items:
				if not wave is Dictionary or wave.get("id") != reference or not wave.has("enemy_facilities"):
					continue
				var placements: Variant = wave.enemy_facilities
				if not placements is Array:
					errors.append("%s enemy_facilities must be an array" % wave.get("id", "<missing-id>"))
					continue
				var placed_cells: Dictionary = {}
				for placement in placements:
					var facility_id: Variant = placement.get("facility_id", "") if placement is Dictionary else null
					var cell: Variant = placement.get("cell", []) if placement is Dictionary else null
					if not placement is Dictionary or facility_teams.get(facility_id, "") != "enemy" or not _is_integer_cell(cell) or int(cell[0]) >= columns or int(cell[1]) >= rows:
						errors.append("%s has invalid enemy facility placement" % wave.get("id", "<missing-id>"))
						continue
					if not wave.get("references", []).has(facility_id):
						errors.append("%s enemy facility must be referenced" % wave.get("id", "<missing-id>"))
					var placed_cell := Vector2i(int(cell[0]), int(cell[1]))
					if placed_cell.y > enemy_spawn_row or blocked.has(placed_cell) or wall_cells.has(placed_cell) or placed_cell == Vector2i(int(core_cell[0]), int(core_cell[1])) or placed_cells.has(placed_cell):
						errors.append("%s has conflicting enemy facility cell" % wave.get("id", "<missing-id>"))
					for spawn_index in int(wave.get("count", 0)):
						if placed_cell == Vector2i(2 + spawn_index * 2, enemy_spawn_row):
							errors.append("%s enemy facility conflicts with initial spawn" % wave.get("id", "<missing-id>"))
					for group in wave.get("reinforcements", []):
						if group is Dictionary and _is_integer_cell(group.get("spawn")) and placed_cell == Vector2i(int(group.spawn[0]), int(group.spawn[1])):
							errors.append("%s enemy facility conflicts with reinforcement spawn" % wave.get("id", "<missing-id>"))
					placed_cells[placed_cell] = true
		if columns > 0 and rows > 0 and core_cell is Array and core_cell.size() == 2 and _is_nonnegative_integer(core_cell[0]) and _is_nonnegative_integer(core_cell[1]) and int(core_cell[0]) < columns and int(core_cell[1]) < rows:
			for reference in stage.get("references", []):
				for wave in wave_items:
					if wave is Dictionary and wave.get("id") == reference and _is_positive_integer(wave.get("count")):
						for index in int(wave.count):
							var spawn := Vector2i(2 + index * 2, rows - 1 if stage.get("mode") == "siege" else enemy_spawn_row)
							if spawn.x >= columns or blocked.has(spawn) or GridPathfinder.find_path(spawn, Vector2i(int(core_cell[0]), int(core_cell[1])), columns, rows, blocked).is_empty():
								errors.append("%s blocks a required wave route" % stage.get("id", "<missing-id>"))
								break
						for group in wave.get("reinforcements", []):
							if not group is Dictionary or not _is_integer_cell(group.get("spawn")):
								continue
							var reinforcement_spawn := Vector2i(int(group.spawn[0]), int(group.spawn[1]))
							if blocked.has(reinforcement_spawn) or reinforcement_spawn == Vector2i(int(core_cell[0]), int(core_cell[1])) or GridPathfinder.find_path(reinforcement_spawn, Vector2i(int(core_cell[0]), int(core_cell[1])), columns, rows, blocked).is_empty():
								errors.append("%s blocks a reinforcement route" % stage.get("id", "<missing-id>"))
		var wave_ids := _ids_in(wave_items)
		var references: Variant = stage.get("references", [])
		var has_wave := false
		if references is Array:
			for reference in references:
				if reference is String and wave_ids.has(reference):
					has_wave = true
		if not has_wave:
			errors.append("%s must reference at least one wave" % stage.get("id", "<missing-id>"))
		if not _is_positive_number(stage.get("core_hp")) or not _is_nonnegative_integer(stage.get("start_resource")) or not _is_nonnegative_integer(stage.get("kill_reward")) or not _is_nonnegative_integer(stage.get("wave_reward")) or not _is_nonnegative_integer(stage.get("permanent_first_bonus")) or not _is_nonnegative_integer(stage.get("permanent_repeat_reward")) or not _is_nonnegative_integer(stage.get("permanent_partial_per_wave")) or not _is_positive_integer(stage.get("intermission_seconds")):
			errors.append("%s has invalid core or resource values" % stage.get("id", "<missing-id>"))
	var campaign_stages: Array = stage_items.filter(func(stage): return stage is Dictionary and stage.get("campaign_kind", "") in ["main", "optional"])
	if not campaign_stages.is_empty():
		var main_stages: Array = campaign_stages.filter(func(stage): return stage.campaign_kind == "main")
		var optional_stages: Array = campaign_stages.filter(func(stage): return stage.campaign_kind == "optional")
		var campaign_wave_count := 0
		var campaign_orders: Dictionary = {}
		for stage in campaign_stages:
			if not _is_positive_integer(stage.get("campaign_order")):
				errors.append("%s has invalid campaign order" % stage.get("id", "<missing-id>"))
			var order_key := "%s:%s" % [stage.get("campaign_kind", ""), stage.get("campaign_order", "")]
			if campaign_orders.has(order_key):
				errors.append("%s duplicates campaign order" % stage.get("id", "<missing-id>"))
			campaign_orders[order_key] = true
			for reference in stage.get("references", []):
				if wave_items.any(func(wave): return wave is Dictionary and wave.get("id") == reference):
					campaign_wave_count += 1
		if main_stages.size() != 6 or optional_stages.size() != 2 or campaign_wave_count != 26:
			errors.append("campaign must contain six main stages, two optional stages, and 26 waves")
	var cycle_nodes := _find_dependency_cycles(categories)
	for id in cycle_nodes:
		errors.append("cyclic dependency involving: %s" % id)
	for index in errors.size():
		errors[index] = with_field_path(errors[index], catalog)
	return errors

static func with_field_path(message: String, catalog: Dictionary) -> String:
	var id := content_id_from_error(message, catalog)
	if not id.is_empty() and message.begins_with(id + "."):
		return message
	var field := _field_for_error(message)
	var detail := message.trim_prefix(id).strip_edges() if not id.is_empty() else message
	return "%s.%s: %s" % [id, field, detail] if not id.is_empty() else "%s: %s" % [field, detail]

static func _append_field_error(errors: Array[String], id: String, field: String, message: String) -> void:
	errors.append("%s.%s: %s" % [id, field, message])

static func _field_for_error(message: String) -> String:
	var hints := [
		["unsupported content_version", "content_version"], ["unsupported schema_version", "schema_version"],
		["evolutions must contain", "evolutions"],
		["content_version must", "content_version"], ["schema_version must", "schema_version"],
		["contains an item without a stable id", "id"], ["duplicate content id", "id"],
		["unresolved dependency", "dependencies"], ["dependencies must", "dependencies"], ["unresolved reference", "references"], ["references must", "references"],
		["invalid unit healing", "heal|heal_range|team"], ["invalid unit splash", "splash_radius|damage"], ["invalid combat or cost data", "team|hp|damage|range|attack_time|cost|heal|heal_range|splash_radius"], ["AI profile", "ai_profile_id|references"],
		["invalid combat upgrade", "unit_kind|values|costs|effect"], ["four combat upgrades", "upgrades[]"],
		["invalid skill data", "unit_kind|mode|effect|cooldown|cost|value|radius|label"], ["must have one ", "skills[mode]"],
		["invalid facility attack", "damage|range|attack_time"], ["invalid facility splash", "splash_radius|damage"], ["invalid facility healing", "heal|range|attack_time|team"], ["invalid facility data", "team|hp|damage|heal|splash_radius|range|attack_time|cost|blocks_path"],
		["invalid permanent research", "unit_kind|building_kind|stat|amount|cost|requires_stage"], ["AI weights", "weights"], ["AI weight", "weights.*"],
		["enemy and have a positive integer count", "enemy_id|count|references"], ["AI weight overrides", "ai_weight_overrides"], ["invalid reinforcement", "reinforcements[]"],
		["enemy_facilities must", "enemy_facilities"], ["invalid enemy facility placement", "enemy_facilities[].facility_id|cell"], ["enemy facility must be referenced", "references"], ["conflicting enemy facility cell", "enemy_facilities[].cell"], ["conflicts with initial spawn", "enemy_facilities[].cell"], ["conflicts with reinforcement spawn", "enemy_facilities[].cell"],
		["invalid evolution data", "unit_kind|label|total_upgrade_levels|combat_cost"], ["invalid evolution requirements", "required_upgrades"], ["invalid evolution references", "references"], ["invalid evolution special skill", "special_skill.mode|effect|cooldown|cost|value|radius|label"],
		["unsupported movement type", "movement_type"], ["invalid obstacle movement types", "blocked_movement_types"], ["invalid obstacle data", "kind|cost"], ["invalid obstacle limits", "obstacle_max_owned|obstacle_max_placed|references"], ["invalid available unit", "available_units"], ["must list available units", "available_units"], ["invalid board dimensions or core cell", "columns|rows|core_cell"], ["unknown battle mode", "mode"], ["invalid enemy spawn row", "enemy_spawn_row"], ["blocked_cells must", "blocked_cells"], ["invalid blocked cell", "blocked_cells[]"], ["duplicate blocked cell", "blocked_cells[]"], ["blocks its core cell", "blocked_cells[]|core_cell"], ["walls must", "walls"], ["invalid wall data", "walls[].cell|hp"], ["conflicting wall cell", "walls[].cell"], ["blocks a required wave route", "blocked_cells|walls|core_cell|waves"], ["blocks a reinforcement route", "blocked_cells|core_cell|waves|reinforcements"], ["must reference at least one wave", "references"], ["invalid core or resource values", "core_hp|start_resource|kill_reward|wave_reward|permanent_first_bonus|permanent_repeat_reward|permanent_partial_per_wave|intermission_seconds"], ["invalid campaign order", "campaign_order"], ["duplicates campaign order", "campaign_order"], ["campaign must contain", "stages|waves"], ["cyclic dependency", "dependencies"]
	]
	for hint in hints:
		if message.contains(hint[0]):
			return hint[1]
	if message.begins_with("category "):
		return "categories"
	return "catalog"

static func content_id_from_error(message: String, catalog: Dictionary) -> String:
	var match_id := ""
	var categories: Variant = catalog.get("categories", {})
	if not categories is Dictionary:
		return match_id
	for category in categories:
		if not categories[category] is Array:
			continue
		for item in categories[category]:
			if item is Dictionary:
				var id: String = item.get("id", "")
				if not id.is_empty() and message.contains(id) and id.length() > match_id.length():
					match_id = id
	return match_id

static func _ids_in(items: Array) -> Array[String]:
	var result: Array[String] = []
	for item in items:
		if item is Dictionary and item.get("id", "") is String:
			result.append(item.id)
	return result

static func _as_array(value: Variant) -> Array:
	return value if value is Array else []

static func _is_positive_integer(value: Variant) -> bool:
	return (value is int or value is float) and float(value) >= 1.0 and floor(float(value)) == float(value)

static func _is_nonnegative_integer(value: Variant) -> bool:
	return (value is int or value is float) and float(value) >= 0.0 and floor(float(value)) == float(value)

static func _is_positive_number(value: Variant) -> bool:
	return (value is int or value is float) and float(value) > 0.0

static func _is_nonnegative_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0

static func _is_integer_cell(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _is_nonnegative_integer(value[0]) and _is_nonnegative_integer(value[1]) and int(value[0]) < BattleModel.COLUMNS and int(value[1]) < BattleModel.ROWS

static func _find_dependency_cycles(categories: Dictionary) -> Array[String]:
	var graph: Dictionary = {}
	for items in categories.values():
		if not items is Array:
			continue
		for item in items:
			if item is Dictionary and item.get("id", "") is String:
				graph[item.id] = item.get("dependencies", []) if item.get("dependencies", []) is Array else []
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	var cycles: Array[String] = []
	for id in graph:
		_visit(id, graph, visiting, visited, cycles)
	return cycles

static func _visit(id: String, graph: Dictionary, visiting: Dictionary, visited: Dictionary, cycles: Array[String]) -> void:
	if visited.has(id):
		return
	if visiting.has(id):
		if not cycles.has(id):
			cycles.append(id)
		return
	visiting[id] = true
	for dependency in graph.get(id, []):
		if dependency is String and graph.has(dependency):
			_visit(dependency, graph, visiting, visited, cycles)
			if cycles.has(dependency) and not cycles.has(id):
				cycles.append(id)
	visiting.erase(id)
	visited[id] = true
