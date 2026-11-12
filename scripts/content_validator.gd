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
	var profile_ids := _ids_in(_as_array(categories.get("ai_profiles", [])))
	for unit in unit_items:
		if unit is Dictionary and (unit.get("team") not in ["ally", "enemy"] or not _is_positive_number(unit.get("hp")) or not _is_positive_number(unit.get("damage")) or not _is_positive_integer(unit.get("range")) or not _is_positive_number(unit.get("attack_time")) or not _is_nonnegative_integer(unit.get("cost"))):
			errors.append("%s has invalid combat or cost data" % unit.get("id", "<missing-id>"))
		if unit is Dictionary:
			unit_teams[unit.get("id", "")] = unit.get("team", "")
			if unit.get("team") == "enemy":
				var profile_id: Variant = unit.get("ai_profile_id", "")
				var references: Variant = unit.get("references", [])
				if not profile_ids.has(profile_id) or not references is Array or not references.has(profile_id):
					errors.append("%s must reference an AI profile" % unit.get("id", "<missing-id>"))
	for facility in _as_array(categories.get("facilities", [])):
		if not facility is Dictionary:
			continue
		if facility.get("team") not in ["ally", "enemy"] or not _is_positive_number(facility.get("hp")) or not _is_nonnegative_number(facility.get("damage")) or not _is_nonnegative_number(facility.get("heal", 0)) or not _is_nonnegative_integer(facility.get("range")) or not _is_nonnegative_number(facility.get("attack_time")) or not _is_nonnegative_integer(facility.get("cost")) or not facility.get("blocks_path") is bool:
			errors.append("%s has invalid facility data" % facility.get("id", "<missing-id>"))
		elif facility.damage > 0 and (facility.range < 1 or facility.attack_time <= 0):
			errors.append("%s has invalid facility attack data" % facility.get("id", "<missing-id>"))
		elif facility.heal > 0 and (facility.range < 1 or facility.attack_time <= 0 or facility.team != "ally"):
			errors.append("%s has invalid facility healing data" % facility.get("id", "<missing-id>"))
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
		if not _is_positive_number(stage.get("core_hp")) or not _is_nonnegative_integer(stage.get("start_resource")) or not _is_nonnegative_integer(stage.get("kill_reward")) or not _is_nonnegative_integer(stage.get("wave_reward")) or not _is_positive_integer(stage.get("intermission_seconds")):
			errors.append("%s has invalid core or resource values" % stage.get("id", "<missing-id>"))
	var cycle_nodes := _find_dependency_cycles(categories)
	for id in cycle_nodes:
		errors.append("cyclic dependency involving: %s" % id)
	return errors

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
