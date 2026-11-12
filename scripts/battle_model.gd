class_name BattleModel
extends RefCounted

const COLUMNS := 8
const ROWS := 10
const STAGE_ID := "stage.m1.frontier"

var stage_id := STAGE_ID
var run_id := ""
var content: Dictionary = {}
var stage: Dictionary = {}
var balance_seed: Dictionary = {}
var base_balance_seed: Dictionary = {}
var research_definitions: Dictionary = {}
var permanent_research: Array[String] = []
var upgrade_definitions: Dictionary = {}
var skill_definitions: Dictionary = {}
var facility_definitions: Dictionary = {}
var obstacle_definitions: Dictionary = {}
var ai_profiles: Dictionary = {}
var waves: Array = []
var core_cell := Vector2i(4, 9)
var core_hp := 0.0
var wave := 1
var phase := "preparation"
var battle_result := ""
var combat_gold := 0
var next_id := 1
var units: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var preview_enemies: Array[Dictionary] = []
var facilities: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var enemy_facilities: Array[Dictionary] = []
var rewarded_waves: Array[int] = []
var blocked_cells: Dictionary = {}
var walls: Array[Dictionary] = []
var wave_elapsed := 0.0
var pending_reinforcements: Array[Dictionary] = []

func _init(selected_stage_id: String = STAGE_ID) -> void:
	stage_id = selected_stage_id
	run_id = "%s-%s-%s" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
	var file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if file == null:
		push_error("Cannot load bundled content")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not ContentValidator.validate(parsed).is_empty():
		push_error("Bundled content failed validation")
		return
	content = parsed
	for unit in content.categories.units:
		base_balance_seed[unit.kind] = unit.duplicate(true)
		balance_seed[unit.kind] = unit.duplicate(true)
	for research in content.categories.research:
		research_definitions[research.id] = research
	for upgrade in content.categories.upgrades:
		upgrade_definitions[upgrade.id] = upgrade
	for skill in content.categories.skills:
		skill_definitions[skill.id] = skill
	for facility in content.categories.facilities:
		facility_definitions[facility.id] = facility
	for obstacle in content.categories.obstacles:
		obstacle_definitions[obstacle.id] = obstacle
	for profile in content.categories.ai_profiles:
		ai_profiles[profile.id] = profile
	for definition in content.categories.stages:
		if definition.id == stage_id:
			stage = definition
			break
	if stage.is_empty():
		push_error("Missing stage: %s" % stage_id)
		return
	for reference in stage.references:
		for definition in content.categories.waves:
			if definition.id == reference:
				waves.append(definition)
	core_cell = Vector2i(stage.core_cell[0], stage.core_cell[1])
	for cell in stage.get("blocked_cells", []):
		blocked_cells[Vector2i(cell[0], cell[1])] = true
	for wall in stage.get("walls", []):
		walls.append({"cell": Vector2i(wall.cell[0], wall.cell[1]), "hp": float(wall.hp), "max_hp": float(wall.hp)})
	core_hp = stage.core_hp
	combat_gold = stage.start_resource
	_prepare_wave_preview()

func set_permanent_research(research_ids: Array) -> bool:
	var research_state := _build_research_state(research_ids)
	if research_state.is_empty():
		return false
	permanent_research = research_state.ids
	balance_seed = research_state.balance
	return true

func _build_research_state(research_ids: Array) -> Dictionary:
	var selected: Array[String] = []
	var adjusted_balance := base_balance_seed.duplicate(true)
	for research_id in research_ids:
		if not research_id is String or not research_definitions.has(research_id) or selected.has(research_id):
			return {}
		selected.append(research_id)
	for research_id in selected:
		var research: Dictionary = research_definitions[research_id]
		var unit_kind: String = research.unit_kind
		if adjusted_balance.has(unit_kind) and adjusted_balance[unit_kind].team == "ally" and research.stat == "damage":
			adjusted_balance[unit_kind].damage += float(research.amount)
	return {"ids": selected, "balance": adjusted_balance}

func select_preview_wave(wave_id: String) -> bool:
	for index in waves.size():
		if waves[index].id == wave_id:
			wave = index + 1
			phase = "preparation"
			battle_result = ""
			core_hp = stage.core_hp
			combat_gold = stage.start_resource
			next_id = 1
			units.clear()
			facilities.clear()
			obstacles.clear()
			rewarded_waves.clear()
			walls.clear()
			for definition in stage.get("walls", []):
				walls.append({"cell": Vector2i(definition.cell[0], definition.cell[1]), "hp": float(definition.hp), "max_hp": float(definition.hp)})
			return _prepare_wave_preview()
	return false

func deploy(kind: String, cell: Vector2i) -> bool:
	if not balance_seed.has(kind) or balance_seed[kind].team != "ally" or not stage.get("available_units", []).has(kind) or not _is_inside(cell) or cell.y < 6 or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or _occupied(cell):
		return false
	var cost: int = balance_seed[kind].cost
	if combat_gold < cost:
		return false
	combat_gold -= cost
	var stats: Dictionary = balance_seed[kind]
	units.append({"id": next_id, "kind": kind, "movement_type": stats.movement_type, "cell": cell, "hp": stats.hp, "damage": stats.damage, "range": stats.range, "heal": stats.get("heal", 0), "heal_range": stats.get("heal_range", 0), "splash_radius": stats.get("splash_radius", 0), "attack_count": 0, "upgrades": {}, "skill_cooldowns": {}, "statuses": {}, "cooldown": 0.0, "alive": true})
	next_id += 1
	return true

func purchase_upgrade(unit_id: int, upgrade_id: String) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or phase not in ["preparation", "combat"] or not upgrade_definitions.has(upgrade_id):
		return false
	var definition: Dictionary = upgrade_definitions[upgrade_id]
	if definition.unit_kind != unit.kind:
		return false
	var level := int(unit.get("upgrades", {}).get(upgrade_id, 0))
	if level >= 3:
		return false
	var cost := int(definition.costs[level])
	if combat_gold < cost:
		return false
	combat_gold -= cost
	unit.upgrades[upgrade_id] = level + 1
	_apply_unit_upgrades(unit)
	return true

func cast_skill(unit_id: int, skill_id: String) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or phase != "combat" or unit.has("destination") or not skill_definitions.has(skill_id):
		return false
	var skill: Dictionary = skill_definitions[skill_id]
	if skill.unit_kind != unit.kind or skill.mode != "manual" or float(unit.skill_cooldowns.get(skill_id, 0.0)) > 0.0 or combat_gold < int(skill.cost):
		return false
	if not _execute_skill(unit, skill):
		return false
	combat_gold -= int(skill.cost)
	unit.skill_cooldowns[skill_id] = float(skill.cooldown)
	return true

func _tick_skills(unit: Dictionary, delta: float) -> void:
	unit.skill_cooldowns = unit.get("skill_cooldowns", {}) if unit.get("skill_cooldowns", {}) is Dictionary else {}
	for skill_id in unit.skill_cooldowns:
		unit.skill_cooldowns[skill_id] = maxf(0.0, float(unit.skill_cooldowns[skill_id]) - delta)
	if unit.has("destination"):
		return
	for skill in content.categories.skills:
		if skill.unit_kind == unit.kind and skill.mode == "automatic" and float(unit.skill_cooldowns.get(skill.id, 0.0)) <= 0.0 and _execute_skill(unit, skill):
			unit.skill_cooldowns[skill.id] = float(skill.cooldown)

func _execute_skill(unit: Dictionary, skill: Dictionary) -> bool:
	var enemies_in_range := (enemies + enemy_facilities).filter(func(target: Dictionary): return target.alive and target.get("active", true) and _distance(unit.cell, target.cell) <= 5)
	match skill.effect:
		"strike":
			if enemies_in_range.is_empty(): return false
			enemies_in_range.sort_custom(func(a: Dictionary, b: Dictionary): return _distance(unit.cell, a.cell) < _distance(unit.cell, b.cell))
			_apply_damage({"damage": float(skill.value)}, enemies_in_range[0])
		"area":
			if enemies_in_range.is_empty(): return false
			enemies_in_range.sort_custom(func(a: Dictionary, b: Dictionary): return _distance(unit.cell, a.cell) < _distance(unit.cell, b.cell))
			var center: Vector2i = enemies_in_range[0].cell
			for target in enemies_in_range:
				if _distance(center, target.cell) <= int(skill.radius):
					_apply_damage({"damage": float(skill.value)}, target)
		"heal":
			var target_index := _lowest_hp_ally(unit.cell, int(skill.radius), unit.id)
			if target_index < 0: return false
			var target: Dictionary = units[target_index]
			target.hp = minf(float(balance_seed[target.kind].hp), float(target.hp) + float(skill.value))
		"shield":
			var targets := units.filter(func(ally: Dictionary): return ally.alive and _distance(unit.cell, ally.cell) <= int(skill.radius) and float(ally.get("shield", 0.0)) < float(skill.value))
			if targets.is_empty(): return false
			for target in targets:
				target.shield = maxf(float(target.get("shield", 0.0)), float(skill.value))
		_: return false
	return true

func _upgrade_level(unit: Dictionary, effect: String) -> int:
	var level := 0
	for upgrade_id in unit.get("upgrades", {}):
		var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
		if definition.get("effect", "") == effect:
			level += int(unit.upgrades[upgrade_id])
	return level

func _upgrade_value(unit: Dictionary, effect: String) -> float:
	var value := 0.0
	for upgrade_id in unit.get("upgrades", {}):
		var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
		if definition.get("effect", "") == effect:
			value += float(definition.values[int(unit.upgrades[upgrade_id]) - 1])
	return value

func _apply_unit_upgrades(unit: Dictionary, balance: Dictionary = {}) -> void:
	var stats: Dictionary = balance.get(unit.kind, balance_seed[unit.kind])
	unit.damage = float(stats.damage)
	unit.range = int(stats.range)
	unit.heal = float(stats.get("heal", 0))
	unit.heal_range = int(stats.get("heal_range", 0))
	unit.splash_radius = int(stats.get("splash_radius", 0))
	unit.erase("taunt_range")
	unit.erase("damage_reduction")
	for upgrade_id in unit.upgrades:
		var definition: Dictionary = upgrade_definitions[upgrade_id]
		var level := int(unit.upgrades[upgrade_id])
		var value: float = float(definition.values[level - 1])
		match definition.effect:
			"charge": unit.damage += value
			"splash": unit.splash_radius = maxi(unit.splash_radius, int(value))
			"area": unit.splash_radius = maxi(unit.splash_radius, int(value))
			"taunt": unit.taunt_range = int(value)
			"defense": unit.damage_reduction = value

func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func move_unit(unit_id: int, destination: Vector2i) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or phase != "combat" or not _is_inside(destination) or destination == core_cell or blocked_cells.has(destination) or _wall_at(destination) >= 0 or _occupied(destination) or _find_path(unit, destination).is_empty():
		return false
	unit.destination = destination
	unit.cooldown = maxf(unit.cooldown, 0.5)
	return true

func build_facility(facility_id: String, cell: Vector2i) -> bool:
	if phase not in ["preparation", "combat"] or not facility_definitions.has(facility_id) or not _is_inside(cell) or cell.y < 5 or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or _occupied(cell) or _obstacle_at(cell) >= 0:
		return false
	var definition: Dictionary = facility_definitions[facility_id]
	if definition.team != "ally" or combat_gold < definition.cost:
		return false
	combat_gold -= definition.cost
	facilities.append({"id": next_id, "facility_id": facility_id, "kind": definition.kind, "cell": cell, "hp": definition.hp, "damage": definition.damage, "heal": definition.get("heal", 0), "splash_radius": definition.get("splash_radius", 0), "range": definition.range, "attack_time": definition.attack_time, "blocks_path": definition.blocks_path, "cooldown": 0.0, "alive": true})
	next_id += 1
	return true

func install_obstacle(obstacle_id: String, cell: Vector2i) -> bool:
	if phase not in ["preparation", "combat"] or not obstacle_definitions.has(obstacle_id) or obstacles.size() >= int(stage.get("obstacle_max_owned", 0)) or _placed_obstacle_count() >= int(stage.get("obstacle_max_placed", 0)):
		return false
	var definition: Dictionary = obstacle_definitions[obstacle_id]
	if combat_gold < int(definition.cost) or not _valid_obstacle_cell(cell, -1, obstacle_id):
		return false
	combat_gold -= int(definition.cost)
	obstacles.append({"id": next_id, "obstacle_id": obstacle_id, "cell": cell, "placed": true})
	next_id += 1
	return true

func place_stored_obstacle(instance_id: int, cell: Vector2i) -> bool:
	var index := _obstacle_index(instance_id)
	if index < 0 or obstacles[index].placed or phase not in ["preparation", "combat"] or _placed_obstacle_count() >= int(stage.get("obstacle_max_placed", 0)) or not _valid_obstacle_cell(cell, instance_id):
		return false
	obstacles[index].cell = cell
	obstacles[index].placed = true
	return true

func move_obstacle(instance_id: int, destination: Vector2i) -> bool:
	var index := _obstacle_index(instance_id)
	if index < 0 or not obstacles[index].placed or phase != "preparation" or not _valid_obstacle_cell(destination, instance_id):
		return false
	obstacles[index].cell = destination
	return true

func store_obstacle(instance_id: int) -> bool:
	var index := _obstacle_index(instance_id)
	if index < 0 or not obstacles[index].placed or phase != "preparation":
		return false
	obstacles[index].placed = false
	obstacles[index].cell = Vector2i(-1, -1)
	return true

func move_facility(facility_instance_id: int, destination: Vector2i) -> bool:
	var facility := _facility_by_id(facility_instance_id)
	if facility.is_empty() or phase != "preparation" or not _is_inside(destination) or destination.y < 5 or destination == core_cell or blocked_cells.has(destination) or _wall_at(destination) >= 0 or _obstacle_at(destination) >= 0 or destination == facility.cell:
		return false
	for item in units + enemies + facilities:
		if item.alive and item.id != facility_instance_id and item.cell == destination:
			return false
	facility.cell = destination
	return true

func start_wave(store: CheckpointStore) -> bool:
	if phase != "preparation" or not store.save_checkpoint(to_dict()):
		return false
	if not _prepare_wave_preview():
		phase = "finished"
		battle_result = "safe_abort"
		return false
	enemies.assign(preview_enemies)
	preview_enemies.clear()
	phase = "combat"
	for enemy in enemies:
		enemy.active = true
	for facility in enemy_facilities:
		facility.active = true
	var wave_definition: Dictionary = waves[wave - 1]
	wave_elapsed = 0.0
	pending_reinforcements.clear()
	for reinforcement in wave_definition.get("reinforcements", []):
		pending_reinforcements.append({"enemy_id": reinforcement.enemy_id, "remaining": reinforcement.count, "spawn": Vector2i(reinforcement.spawn[0], reinforcement.spawn[1]), "at": float(reinforcement.at), "attempts": 0})
	return true

func tick(delta: float) -> void:
	if phase != "combat":
		return
	wave_elapsed += delta
	if not _advance_reinforcements():
		return
	for unit in units:
		if not unit.alive:
			continue
		_tick_statuses(unit, delta)
		if not unit.alive:
			continue
		unit.cooldown = maxf(0.0, unit.cooldown - delta)
		_tick_skills(unit, delta)
		if unit.has("destination"):
			if unit.cell == unit.destination:
				unit.erase("destination")
			else:
				var route := _find_path(unit, unit.destination)
				if route.is_empty():
					unit.erase("destination")
					continue
				unit.cell = route[0]
				if unit.cell == unit.destination:
					unit.erase("destination")
				continue
		if unit.get("heal", 0) > 0 and unit.cooldown <= 0.0:
			var ally_index := _lowest_hp_ally(unit.cell, unit.get("heal_range", 0), unit.id)
			if ally_index >= 0:
				var primary: Dictionary = units[ally_index]
				for ally in units:
					var area := _upgrade_value(unit, "heal_area")
					if not ally.alive or _distance(unit.cell, ally.cell) > unit.heal_range or (ally.id != primary.id and (area <= 0.0 or _distance(primary.cell, ally.cell) > area)) or float(ally.hp) >= float(balance_seed[ally.kind].hp):
						continue
					_apply_support_effects(unit, ally)
				unit.cooldown = balance_seed[unit.kind].attack_time
				continue
		var unit_targets: Array[Dictionary] = enemies + enemy_facilities
		var target_index := _closest_target(unit.cell, unit_targets, unit.range)
		if target_index >= 0:
			if unit.get("splash_radius", 0) > 0:
				_strike_area(unit, unit_targets, unit_targets[target_index].cell, unit.splash_radius)
			else:
				_strike(unit, unit_targets[target_index])
		elif stage.mode == "siege" and wave == waves.size() and unit.cooldown <= 0.0:
			var distance := absi(unit.cell.x - core_cell.x) + absi(unit.cell.y - core_cell.y)
			if distance <= unit.range:
				core_hp = maxf(0.0, core_hp - unit.damage)
				unit.cooldown = balance_seed[unit.kind].attack_time
			else:
				var route := _find_path(unit, core_cell)
				if not route.is_empty() and route[0] != core_cell:
					unit.cell = route[0]
	for facility in facilities:
		if not facility.alive:
			continue
		facility.cooldown = maxf(0.0, facility.cooldown - delta)
		if facility.damage > 0:
			var targets: Array[Dictionary] = enemies + enemy_facilities
			var target_index := _closest_target(facility.cell, targets, facility.range)
			if target_index >= 0:
				if facility.splash_radius > 0:
					_strike_area(facility, targets, targets[target_index].cell, facility.splash_radius)
				else:
					_strike(facility, targets[target_index])
		elif facility.heal > 0 and facility.cooldown <= 0.0:
			var ally_index := _lowest_hp_ally(facility.cell, facility.range)
			if ally_index >= 0:
				var ally: Dictionary = units[ally_index]
				ally.hp = minf(float(balance_seed[ally.kind].hp), ally.hp + facility.heal)
				facility.cooldown = facility.attack_time
	for facility in enemy_facilities:
		if not facility.active or not facility.alive:
			continue
		facility.cooldown = maxf(0.0, facility.cooldown - delta)
		var target_index := _closest_target(facility.cell, units + facilities, facility.range)
		if target_index >= 0:
			_strike(facility, (units + facilities)[target_index])
	for enemy in enemies:
		if not enemy.alive or not enemy.get("active", true):
			continue
		_tick_statuses(enemy, delta)
		if not enemy.alive or enemy.get("statuses", {}).has("freeze"):
			continue
		enemy.cooldown = maxf(0.0, enemy.cooldown - delta)
		if enemy.get("heal", 0) > 0 and enemy.cooldown <= 0.0:
			var ally_index := _lowest_hp_enemy(enemy.cell, enemy.get("heal_range", 0), enemy.id)
			if ally_index >= 0:
				enemies[ally_index].hp = minf(float(balance_seed[enemies[ally_index].kind].hp), enemies[ally_index].hp + enemy.heal)
				enemy.cooldown = balance_seed[enemy.kind].attack_time
				continue
		var decision := _choose_enemy_action(enemy)
		match decision.kind:
			"attack_unit":
				var targets: Array[Dictionary] = units + facilities
				if enemy.get("splash_radius", 0) > 0:
					_strike_area(enemy, targets, targets[decision.target_index].cell, enemy.splash_radius)
				else:
					_strike(enemy, targets[decision.target_index])
			"attack_facility":
				var targets: Array[Dictionary] = units + facilities
				if enemy.get("splash_radius", 0) > 0:
					_strike_area(enemy, targets, targets[decision.target_index + units.size()].cell, enemy.splash_radius)
				else:
					_strike(enemy, facilities[decision.target_index])
			"advance_facility_wall": enemy.cell = decision.route[0]
			"attack_wall":
				walls[decision.wall_index].hp = maxf(0.0, walls[decision.wall_index].hp - enemy.damage)
				enemy.cooldown = balance_seed[enemy.kind].attack_time
				if walls[decision.wall_index].hp <= 0.0:
					walls.remove_at(decision.wall_index)
			"attack_core":
				core_hp = maxf(0.0, core_hp - enemy.damage)
				enemy.cooldown = balance_seed[enemy.kind].attack_time
			"advance": enemy.cell = decision.route[0]
			"advance_wall": enemy.cell = decision.route[0]
	if stage.mode == "siege" and units.all(func(unit: Dictionary) -> bool: return not unit.alive):
		phase = "finished"
		battle_result = "defeat"
	elif stage.mode == "defense" and core_hp <= 0.0:
		phase = "finished"
		battle_result = "defeat"
	elif stage.mode == "siege" and wave == waves.size() and core_hp <= 0.0:
		phase = "finished"
		battle_result = "victory"
	elif pending_reinforcements.is_empty() and enemies.all(func(enemy: Dictionary) -> bool: return not enemy.alive) and not (stage.mode == "siege" and wave == waves.size()):
		if not rewarded_waves.has(wave):
			combat_gold += stage.wave_reward
			rewarded_waves.append(wave)
		if wave == waves.size():
			phase = "finished"
			battle_result = "victory"
		else:
			wave += 1
			phase = "preparation"
			for unit in units:
				if unit.alive:
					unit.hp = balance_seed[unit.kind].hp
					if unit.has("statuses"):
						unit.statuses.clear()
					else:
						unit.statuses = {}
					unit.shield = 0.0
					unit.cooldown = 0.0
			enemies.clear()
			_prepare_wave_preview()
			pending_reinforcements.clear()
			wave_elapsed = 0.0

func to_dict() -> Dictionary:
	var saved_units: Array[Dictionary] = []
	var saved_facilities: Array[Dictionary] = []
	var saved_obstacles: Array[Dictionary] = []
	var saved_walls: Array[Dictionary] = []
	for unit in units:
		var saved_unit := unit.duplicate(true)
		saved_unit.cell = [unit.cell.x, unit.cell.y]
		if unit.has("destination"):
			saved_unit.destination = [unit.destination.x, unit.destination.y]
		saved_units.append(saved_unit)
	for facility in facilities:
		var saved_facility := facility.duplicate(true)
		saved_facility.cell = [facility.cell.x, facility.cell.y]
		saved_facilities.append(saved_facility)
	for obstacle in obstacles:
		var saved_obstacle := obstacle.duplicate(true)
		saved_obstacle.cell = [obstacle.cell.x, obstacle.cell.y]
		saved_obstacles.append(saved_obstacle)
	for definition in stage.get("walls", []):
		var cell := Vector2i(definition.cell[0], definition.cell[1])
		var wall_index := _wall_at(cell)
		saved_walls.append({"cell": [cell.x, cell.y], "hp": walls[wall_index].hp if wall_index >= 0 else 0.0})
	return {"stage_id": stage_id, "run_id": run_id, "mode": stage.get("mode", "defense"), "content_version": ProjectVersions.CONTENT_VERSION, "schema_version": ProjectVersions.SCHEMA_VERSION, "save_version": ProjectVersions.SAVE_VERSION, "permanent_research": permanent_research, "wave": wave, "phase": phase, "core_hp": core_hp, "combat_gold": combat_gold, "next_id": next_id, "units": saved_units, "facilities": saved_facilities, "obstacles": saved_obstacles, "walls": saved_walls, "rewarded_waves": rewarded_waves}

func restore(snapshot: Dictionary) -> bool:
	var saved_research: Variant = snapshot.get("permanent_research", [])
	if not saved_research is Array:
		return false
	var research_state := _build_research_state(saved_research)
	if research_state.is_empty():
		return false
	if snapshot.get("stage_id") != stage_id or snapshot.get("mode") != stage.get("mode") or (snapshot.has("run_id") and (not snapshot.run_id is String or snapshot.run_id.is_empty())) or not _version_matches(snapshot.get("content_version"), ProjectVersions.CONTENT_VERSION) or not _version_matches(snapshot.get("schema_version"), ProjectVersions.SCHEMA_VERSION) or not _version_matches(snapshot.get("save_version"), ProjectVersions.SAVE_VERSION) or not _version_matches(snapshot.get("wave"), int(snapshot.get("wave", 0))) or int(snapshot.get("wave", 0)) < 1 or int(snapshot.get("wave", 0)) > waves.size() or not snapshot.get("units") is Array or not snapshot.get("rewarded_waves", []) is Array or (snapshot.has("walls") and not snapshot.walls is Array) or (snapshot.has("facilities") and not snapshot.facilities is Array) or (snapshot.has("obstacles") and not snapshot.obstacles is Array):
		return false
	var restored_core := float(snapshot.get("core_hp", 0.0))
	var restored_gold := int(snapshot.get("combat_gold", -1))
	var restored_next_id := int(snapshot.get("next_id", 0))
	if snapshot.get("phase") != "preparation" or not is_finite(restored_core) or restored_core <= 0.0 or restored_core > stage.core_hp or restored_gold < 0 or restored_next_id < 1:
		return false
	var restored_units: Array[Dictionary] = []
	var restored_facilities: Array[Dictionary] = []
	var restored_obstacles: Array[Dictionary] = []
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	var max_id := 0
	for saved_unit in snapshot.units:
		if not saved_unit is Dictionary or not _is_integer_value(saved_unit.get("id")) or not _is_valid_cell(saved_unit.get("cell")) or not research_state.balance.has(saved_unit.get("kind")) or research_state.balance[saved_unit.kind].team != "ally" or not stage.get("available_units", []).has(saved_unit.get("kind")) or not saved_unit.get("alive") is bool:
			return false
		var unit: Dictionary = saved_unit.duplicate(true)
		var id := int(saved_unit.id)
		var cell := Vector2i(int(saved_unit.cell[0]), int(saved_unit.cell[1]))
		var stats: Dictionary = research_state.balance[saved_unit.kind]
		if saved_unit.has("movement_type") and saved_unit.movement_type != stats.movement_type:
			return false
		unit.movement_type = stats.movement_type
		if not _valid_saved_upgrades(saved_unit.get("upgrades", {}), saved_unit.kind) or not _valid_saved_skill_cooldowns(saved_unit.get("skill_cooldowns", {}), saved_unit.kind):
			return false
		if not _is_integer_value(saved_unit.get("attack_count", 0)) or int(saved_unit.get("attack_count", 0)) < 0:
			return false
		unit.upgrades = saved_unit.get("upgrades", {}).duplicate(true)
		unit.statuses = {}
		unit.shield = 0.0
		unit.attack_count = int(saved_unit.get("attack_count", 0))
		_apply_unit_upgrades(unit, research_state.balance)
		if ids.has(id) or occupied.has(cell) or not _is_finite_nonnegative(saved_unit.get("hp")) or float(saved_unit.hp) > stats.hp or not _version_matches(saved_unit.get("damage"), int(unit.damage)) or not _version_matches(saved_unit.get("range"), int(unit.range)) or not _version_matches(saved_unit.get("heal", stats.get("heal", 0)), int(unit.heal)) or not _version_matches(saved_unit.get("heal_range", stats.get("heal_range", 0)), int(unit.heal_range)) or not _version_matches(saved_unit.get("splash_radius", stats.get("splash_radius", 0)), int(unit.splash_radius)) or not _is_finite_nonnegative(saved_unit.get("cooldown")):
			return false
		if unit.has("destination") and not _is_valid_cell(unit.destination):
			return false
		if unit.has("destination"):
			unit.destination = Vector2i(int(unit.destination[0]), int(unit.destination[1]))
		if unit.alive and unit.hp <= 0.0 or not unit.alive and unit.hp > 0.0:
			return false
		unit.cell = cell
		ids[id] = true
		if unit.alive:
			occupied[cell] = true
		max_id = maxi(max_id, id)
		restored_units.append(unit)
	for saved_facility in snapshot.get("facilities", []):
		if not saved_facility is Dictionary or not _is_integer_value(saved_facility.get("id")) or not _is_valid_cell(saved_facility.get("cell")) or not facility_definitions.has(saved_facility.get("facility_id")) or not saved_facility.get("alive") is bool:
			return false
		var definition: Dictionary = facility_definitions[saved_facility.facility_id]
		var id := int(saved_facility.id)
		var cell := Vector2i(int(saved_facility.cell[0]), int(saved_facility.cell[1]))
		if definition.team != "ally" or ids.has(id) or cell.y < 5 or (saved_facility.alive and (cell == core_cell or occupied.has(cell) or blocked_cells.has(cell) or _wall_at(cell) >= 0)) or not _is_finite_nonnegative(saved_facility.get("hp")) or float(saved_facility.hp) > float(definition.hp) or not _is_finite_nonnegative(saved_facility.get("cooldown")) or (saved_facility.alive and saved_facility.hp <= 0.0) or (not saved_facility.alive and saved_facility.hp > 0.0):
			return false
		var facility: Dictionary = {"id": id, "facility_id": saved_facility.facility_id, "kind": definition.kind, "cell": cell, "hp": float(saved_facility.hp), "damage": definition.damage, "heal": definition.get("heal", 0), "splash_radius": definition.get("splash_radius", 0), "range": definition.range, "attack_time": definition.attack_time, "blocks_path": definition.blocks_path, "cooldown": float(saved_facility.cooldown), "alive": saved_facility.alive}
		ids[id] = true
		if facility.alive:
			occupied[cell] = true
		max_id = maxi(max_id, id)
		restored_facilities.append(facility)
	var obstacle_cells: Dictionary = {}
	var placed_obstacle_count := 0
	for saved_obstacle in snapshot.get("obstacles", []):
		if not saved_obstacle is Dictionary or not _is_integer_value(saved_obstacle.get("id")) or not saved_obstacle.get("obstacle_id") is String or not obstacle_definitions.has(saved_obstacle.get("obstacle_id")) or not saved_obstacle.get("placed") is bool:
			return false
		var obstacle_id: int = int(saved_obstacle.id)
		if ids.has(obstacle_id):
			return false
		var cell_data: Variant = saved_obstacle.get("cell")
		if not cell_data is Array or cell_data.size() != 2 or not cell_data.all(func(value): return _is_integer_value(value)):
			return false
		var cell := Vector2i(int(cell_data[0]), int(cell_data[1]))
		if saved_obstacle.placed:
			if not _is_inside(cell) or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or occupied.has(cell) or obstacle_cells.has(cell):
				return false
			obstacle_cells[cell] = true
			placed_obstacle_count += 1
		elif cell != Vector2i(-1, -1):
			return false
		ids[obstacle_id] = true
		max_id = maxi(max_id, obstacle_id)
		restored_obstacles.append({"id": obstacle_id, "obstacle_id": saved_obstacle.obstacle_id, "cell": cell, "placed": saved_obstacle.placed})
	if restored_obstacles.size() > int(stage.get("obstacle_max_owned", 0)) or placed_obstacle_count > int(stage.get("obstacle_max_placed", 0)) or not _obstacle_layout_preserves_paths(restored_obstacles):
		return false
	for rewarded_wave in snapshot.get("rewarded_waves", []):
		if not _is_integer_value(rewarded_wave) or int(rewarded_wave) < 1 or int(rewarded_wave) >= int(snapshot.wave):
			return false
	var restored_walls: Array[Dictionary] = []
	var saved_wall_hp: Dictionary = {}
	if snapshot.has("walls"):
		for saved_wall in snapshot.walls:
			if not saved_wall is Dictionary or not _is_valid_cell(saved_wall.get("cell")) or not _is_finite_nonnegative(saved_wall.get("hp")):
				return false
			var cell := Vector2i(int(saved_wall.cell[0]), int(saved_wall.cell[1]))
			if saved_wall_hp.has(cell):
				return false
			saved_wall_hp[cell] = float(saved_wall.hp)
	for definition in stage.get("walls", []):
		var cell := Vector2i(definition.cell[0], definition.cell[1])
		var hp := float(definition.hp) if not snapshot.has("walls") else float(saved_wall_hp.get(cell, -1.0))
		if hp < 0.0 or hp > float(definition.hp):
			return false
		if hp > 0.0:
			restored_walls.append({"cell": cell, "hp": hp, "max_hp": float(definition.hp)})
	if snapshot.has("walls") and saved_wall_hp.size() != stage.get("walls", []).size():
		return false
	if restored_next_id <= max_id:
		return false
	permanent_research = research_state.ids
	balance_seed = research_state.balance
	wave = int(snapshot.wave)
	run_id = snapshot.get("run_id", run_id)
	phase = "preparation"
	core_hp = restored_core
	combat_gold = restored_gold
	next_id = restored_next_id
	units.assign(restored_units)
	facilities.assign(restored_facilities)
	obstacles.assign(restored_obstacles)
	walls.assign(restored_walls)
	rewarded_waves.assign(snapshot.get("rewarded_waves", []))
	enemies.clear()
	_prepare_wave_preview()
	return true

func _version_matches(value: Variant, expected: int) -> bool:
	return (value is int or value is float) and float(value) == float(expected)

func _valid_saved_upgrades(saved_upgrades: Variant, unit_kind: String) -> bool:
	if not saved_upgrades is Dictionary:
		return false
	for upgrade_id in saved_upgrades:
		var definition: Dictionary = upgrade_definitions.get(upgrade_id, {})
		var level: Variant = saved_upgrades[upgrade_id]
		if definition.get("unit_kind", "") != unit_kind or not _is_integer_value(level) or int(level) < 1 or int(level) > 3:
			return false
	return true

func _valid_saved_skill_cooldowns(saved_cooldowns: Variant, unit_kind: String) -> bool:
	if not saved_cooldowns is Dictionary:
		return false
	for skill_id in saved_cooldowns:
		var skill: Dictionary = skill_definitions.get(skill_id, {})
		if skill.get("unit_kind") != unit_kind or not _is_finite_nonnegative(saved_cooldowns[skill_id]) or float(saved_cooldowns[skill_id]) > float(skill.get("cooldown", 0.0)):
			return false
	return true

func _is_integer_value(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and floor(float(value)) == float(value)

func _is_finite_nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0

func _is_valid_cell(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _is_integer_value(value[0]) and _is_integer_value(value[1]) and _is_inside(Vector2i(int(value[0]), int(value[1])))

func _closest_target(cell: Vector2i, targets: Array[Dictionary], attack_range: int) -> int:
	var best := -1
	var best_distance := attack_range + 1
	for index in targets.size():
		var target := targets[index]
		if not target.alive or not target.get("active", true):
			continue
		var distance: int = absi(cell.x - target.cell.x) + absi(cell.y - target.cell.y)
		if distance <= attack_range and distance < best_distance:
			best = index
			best_distance = distance
	return best

func _lowest_hp_ally(cell: Vector2i, heal_range: int, exclude_id: int = -1) -> int:
	var best := -1
	var lowest_ratio := 1.0
	for index in units.size():
		var unit: Dictionary = units[index]
		var max_hp := float(balance_seed[unit.kind].hp)
		var distance := absi(cell.x - unit.cell.x) + absi(cell.y - unit.cell.y)
		if not unit.alive or unit.id == exclude_id or unit.hp >= max_hp or distance > heal_range:
			continue
		var ratio: float = float(unit.hp) / max_hp
		if ratio < lowest_ratio:
			best = index
			lowest_ratio = ratio
	return best

func _lowest_hp_enemy(cell: Vector2i, heal_range: int, exclude_id: int) -> int:
	var best := -1
	var lowest_ratio := 1.0
	for index in enemies.size():
		var enemy: Dictionary = enemies[index]
		var max_hp := float(balance_seed[enemy.kind].hp)
		var distance := absi(cell.x - enemy.cell.x) + absi(cell.y - enemy.cell.y)
		if not enemy.alive or not enemy.get("active", true) or enemy.id == exclude_id or enemy.hp >= max_hp or distance > heal_range:
			continue
		var ratio: float = float(enemy.hp) / max_hp
		if ratio < lowest_ratio:
			best = index
			lowest_ratio = ratio
	return best

func _apply_support_effects(support: Dictionary, ally: Dictionary) -> void:
	ally.hp = minf(float(balance_seed[ally.kind].hp), ally.hp + support.heal)
	if not ally.has("statuses"):
		ally.statuses = {}
	var shield := _upgrade_value(support, "shield")
	if shield > float(ally.get("shield", 0.0)):
		ally.shield = shield
	var cleanse_radius := int(_upgrade_value(support, "cleanse"))
	if cleanse_radius > 0:
		for nearby_ally in units:
			if _distance(ally.cell, nearby_ally.cell) <= cleanse_radius and nearby_ally.has("statuses"):
				nearby_ally.statuses.clear()
	var buff := _upgrade_value(support, "attack_buff")
	if buff > 0.0:
		_add_status(ally, "attack_buff", 3.0, 0.0)
		ally.statuses.attack_buff.value = maxf(float(ally.statuses.attack_buff.get("value", 0.0)), buff)

func _strike(attacker: Dictionary, target: Dictionary) -> void:
	if attacker.cooldown > 0.0:
		return
	attacker.attack_count = int(attacker.get("attack_count", 0)) + 1
	var hits := 1 + _upgrade_level(attacker, "combo")
	for _hit in hits:
		_apply_damage(attacker, target)
	var multi_count := _upgrade_level(attacker, "multishot") + _upgrade_level(attacker, "pierce") + _upgrade_level(attacker, "chain")
	if multi_count > 0 and attacker in units:
		var candidates := enemies + enemy_facilities
		candidates.sort_custom(func(a: Dictionary, b: Dictionary): return _distance(attacker.cell, a.cell) < _distance(attacker.cell, b.cell))
		var extra := 0
		for candidate in candidates:
			if not candidate.alive or not candidate.get("active", true) or candidate == target or _distance(attacker.cell, candidate.cell) > attacker.range:
				continue
			if _upgrade_level(attacker, "pierce") > 0:
				var first_ray: Vector2i = target.cell - attacker.cell
				var next_ray: Vector2i = candidate.cell - attacker.cell
				if first_ray.x * next_ray.y != first_ray.y * next_ray.x or first_ray.x * next_ray.x + first_ray.y * next_ray.y <= first_ray.length_squared():
					continue
			if _upgrade_level(attacker, "chain") > 0 and _distance(candidate.cell, target.cell) > 2:
				continue
			_apply_damage(attacker, candidate)
			extra += 1
			if extra >= multi_count:
				break
	attacker.cooldown = float(attacker.attack_time) if attacker.has("attack_time") else float(balance_seed[attacker.kind].attack_time)

func _strike_area(attacker: Dictionary, targets: Array[Dictionary], center: Vector2i, radius: int) -> void:
	if attacker.cooldown > 0.0:
		return
	attacker.attack_count = int(attacker.get("attack_count", 0)) + 1
	var hit_ids: Dictionary = {}
	for target in targets:
		var distance := absi(center.x - target.cell.x) + absi(center.y - target.cell.y)
		if target.alive and target.get("active", true) and distance <= radius:
			for _hit in 1 + _upgrade_level(attacker, "combo"):
				_apply_damage(attacker, target)
			hit_ids[target.id] = true
	var chain_count := _upgrade_level(attacker, "chain") if attacker in units else 0
	if chain_count > 0:
		var candidates := enemies + enemy_facilities
		candidates.sort_custom(func(a: Dictionary, b: Dictionary): return _distance(center, a.cell) < _distance(center, b.cell))
		var chained := 0
		for target in candidates:
			if not target.alive or not target.get("active", true) or hit_ids.has(target.id) or _distance(center, target.cell) <= radius or _distance(center, target.cell) > radius + 2:
				continue
			_apply_damage(attacker, target)
			chained += 1
			if chained >= chain_count:
				break
	attacker.cooldown = float(attacker.attack_time) if attacker.has("attack_time") else float(balance_seed[attacker.kind].attack_time)

func _apply_damage(attacker: Dictionary, target: Dictionary) -> void:
	var damage := float(attacker.damage)
	if attacker.has("upgrades"):
		damage += _upgrade_value(attacker, "charge")
		if _upgrade_level(attacker, "mana_burst") > 0 and int(attacker.get("attack_count", 0)) % 3 == 0:
			damage *= _upgrade_value(attacker, "mana_burst")
	var buff: Dictionary = attacker.get("statuses", {}).get("attack_buff", {})
	if not buff.is_empty():
		damage *= 1.0 + float(buff.get("value", 0.0))
	var reduction := float(target.get("damage_reduction", 0.0))
	if target.has("upgrades"):
		reduction = maxf(reduction, _upgrade_value(target, "defense"))
	damage *= 1.0 - clampf(reduction, 0.0, 0.8)
	var shield := float(target.get("shield", 0.0))
	if shield > 0.0:
		var absorbed := minf(shield, damage)
		target.shield = shield - absorbed
		damage -= absorbed
	_deal_damage(target, damage)
	if not target.alive:
		return
	if attacker.has("upgrades"):
		if _upgrade_level(attacker, "bleed") > 0:
			_add_status(target, "bleed", 3.0, _upgrade_value(attacker, "bleed"))
		if _upgrade_level(attacker, "burn") > 0:
			_add_status(target, "burn", 3.0, _upgrade_value(attacker, "burn"))
		if _upgrade_level(attacker, "freeze") > 0:
			_add_status(target, "freeze", _upgrade_value(attacker, "freeze"), 0.0)
		if _upgrade_level(attacker, "pushback") > 0 and target in enemies:
			_pushback(target, attacker.cell, int(_upgrade_value(attacker, "pushback")))
	if target.has("upgrades") and _upgrade_level(target, "counter") > 0:
		_deal_damage(attacker, damage * _upgrade_value(target, "counter"))

func _deal_damage(target: Dictionary, damage: float) -> void:
	if not target.alive:
		return
	target.hp = maxf(0.0, float(target.hp) - maxf(0.0, damage))
	if target.hp <= 0.0:
		target.alive = false
		if target.get("team", "") == "enemy" or target.kind == "goblin":
			combat_gold += stage.kill_reward

func _add_status(target: Dictionary, id: String, duration: float, damage: float) -> void:
	if not target.has("statuses"):
		target.statuses = {}
	if id in ["bleed", "burn"]:
		var status: Dictionary = target.statuses.get(id, {"stacks": []})
		var stacks: Array = status.get("stacks", [])
		if stacks.size() < 3:
			stacks.append({"remaining": duration, "damage": damage})
		status.stacks = stacks
		target.statuses[id] = status
		return
	var status: Dictionary = target.statuses.get(id, {"remaining": 0.0, "damage": 0.0})
	status.remaining = duration
	status.damage = damage
	target.statuses[id] = status

func _tick_statuses(target: Dictionary, delta: float) -> void:
	for id in target.get("statuses", {}).keys():
		var status: Dictionary = target.statuses[id]
		if id in ["bleed", "burn"]:
			var active_stacks: Array = []
			for stack in status.get("stacks", []):
				_deal_damage(target, float(stack.damage) * delta)
				stack.remaining -= delta
				if stack.remaining > 0.0:
					active_stacks.append(stack)
			status.stacks = active_stacks
			if active_stacks.is_empty():
				target.statuses.erase(id)
		elif status.get("remaining", 0.0) > 0.0:
			status.remaining -= delta
			if status.remaining <= 0.0:
				target.statuses.erase(id)

func _pushback(target: Dictionary, from_cell: Vector2i, distance: int) -> void:
	var direction := Vector2i(signi(target.cell.x - from_cell.x), signi(target.cell.y - from_cell.y))
	for _step in distance:
		var destination: Vector2i = target.cell + direction
		if not _is_inside(destination) or destination == core_cell or blocked_cells.has(destination) or _wall_at(destination) >= 0 or _occupied(destination):
			break
		target.cell = destination

func _unit_by_id(unit_id: int) -> Dictionary:
	for unit in units:
		if unit.id == unit_id and unit.alive:
			return unit
	return {}

func _unit_by_content_id(content_id: String) -> Dictionary:
	for unit in content.categories.units:
		if unit.id == content_id:
			return unit
	return {}

func _facility_by_id(facility_instance_id: int) -> Dictionary:
	for facility in facilities:
		if facility.id == facility_instance_id and facility.alive:
			return facility
	return {}

func _spawn_enemy(content_id: String, cell: Vector2i, wave_definition: Dictionary, active: bool = true) -> bool:
	var enemy_definition := _unit_by_content_id(content_id)
	if enemy_definition.is_empty():
		return false
	var spawn := Vector2i(-1, -1)
	for distance in COLUMNS + ROWS:
		for y in ROWS:
			for x in COLUMNS:
				var candidate := Vector2i(x, y)
				if absi(candidate.x - cell.x) + absi(candidate.y - cell.y) == distance and candidate != core_cell and not blocked_cells.has(candidate) and not _occupied(candidate):
					spawn = candidate
					break
			if spawn.x >= 0:
				break
		if spawn.x >= 0:
			break
	if spawn.x < 0:
		return false
	var ai_profile: Dictionary = ai_profiles.get(enemy_definition.get("ai_profile_id", ""), {})
	var ai_weights: Dictionary = ai_profile.get("weights", {}).duplicate()
	for action in wave_definition.get("ai_weight_overrides", {}):
		ai_weights[action] = wave_definition.ai_weight_overrides[action]
	var destination := enemies if active else preview_enemies
	destination.append({"id": -1000 - destination.size(), "kind": enemy_definition.kind, "team": "enemy", "movement_type": enemy_definition.movement_type, "cell": spawn, "hp": enemy_definition.hp, "damage": enemy_definition.damage, "range": enemy_definition.range, "heal": enemy_definition.get("heal", 0), "heal_range": enemy_definition.get("heal_range", 0), "splash_radius": enemy_definition.get("splash_radius", 0), "ai_profile_id": enemy_definition.ai_profile_id, "ai_weights": ai_weights, "cooldown": 0.0, "alive": true, "active": active})
	return true

func _prepare_wave_preview() -> bool:
	enemies.clear()
	preview_enemies.clear()
	enemy_facilities.clear()
	if wave < 1 or wave > waves.size():
		return false
	var wave_definition: Dictionary = waves[wave - 1]
	for index in wave_definition.get("enemy_facilities", []).size():
		var placement: Dictionary = wave_definition.enemy_facilities[index]
		var definition: Dictionary = facility_definitions[placement.facility_id]
		enemy_facilities.append({"id": -index - 1, "facility_id": placement.facility_id, "kind": definition.kind, "cell": Vector2i(placement.cell[0], placement.cell[1]), "hp": definition.hp, "damage": definition.damage, "heal": definition.get("heal", 0), "range": definition.range, "attack_time": definition.attack_time, "blocks_path": definition.blocks_path, "cooldown": 0.0, "alive": true, "active": false})
	for index in wave_definition.count:
		var spawn := Vector2i(2 + index * 2, int(stage.get("enemy_spawn_row", 0)))
		if not _spawn_enemy(wave_definition.enemy_id, spawn, wave_definition, false):
			return false
	return true

func _advance_reinforcements() -> bool:
	var wave_definition: Dictionary = waves[wave - 1]
	for index in range(pending_reinforcements.size() - 1, -1, -1):
		var reinforcement: Dictionary = pending_reinforcements[index]
		if wave_elapsed < reinforcement.at:
			continue
		if _spawn_enemy(reinforcement.enemy_id, reinforcement.spawn, wave_definition):
			reinforcement.remaining -= 1
			reinforcement.attempts = 0
			if reinforcement.remaining <= 0:
				pending_reinforcements.remove_at(index)
		else:
			reinforcement.attempts += 1
			if reinforcement.attempts >= 6:
				phase = "finished"
				battle_result = "safe_abort"
				return false
			reinforcement.at = wave_elapsed + 0.5
	return true

func _occupied(cell: Vector2i) -> bool:
	for item in units + enemies + preview_enemies + facilities + enemy_facilities:
		if item.alive and item.cell == cell:
			return true
	return _obstacle_at(cell) >= 0

func _obstacle_index(instance_id: int) -> int:
	for index in obstacles.size():
		if int(obstacles[index].id) == instance_id:
			return index
	return -1

func _obstacle_at(cell: Vector2i, ignored_id: int = -1) -> int:
	for index in obstacles.size():
		if obstacles[index].placed and int(obstacles[index].id) != ignored_id and obstacles[index].cell == cell:
			return index
	return -1

func _obstacle_blocks_movement(cell: Vector2i, movement_type: String) -> bool:
	var index := _obstacle_at(cell)
	if index < 0:
		return false
	var definition: Dictionary = obstacle_definitions.get(obstacles[index].obstacle_id, {})
	return definition.get("blocked_movement_types", []).has(movement_type)

func _placed_obstacle_count() -> int:
	return obstacles.filter(func(obstacle: Dictionary): return obstacle.placed).size()

func _valid_obstacle_cell(cell: Vector2i, ignored_id: int, new_obstacle_id: String = "") -> bool:
	if not _is_inside(cell) or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or _occupied_without_obstacles(cell) or _obstacle_at(cell, ignored_id) >= 0:
		return false
	var proposed: Array[Dictionary] = []
	for obstacle in obstacles:
		proposed.append(obstacle.duplicate(true))
	var index := -1
	for candidate_index in proposed.size():
		if int(proposed[candidate_index].id) == ignored_id:
			index = candidate_index
			break
	if index >= 0:
		proposed[index].placed = true
		proposed[index].cell = cell
	else:
		proposed.append({"id": -1, "obstacle_id": new_obstacle_id, "cell": cell, "placed": true})
	return _obstacle_layout_preserves_paths(proposed)

func _occupied_without_obstacles(cell: Vector2i) -> bool:
	for item in units + enemies + preview_enemies + facilities + enemy_facilities:
		if item.alive and item.cell == cell:
			return true
	return false

func _obstacle_layout_preserves_paths(layout: Array[Dictionary]) -> bool:
	for wave_definition in waves:
		var movement_type := _movement_type_for_unit(wave_definition.enemy_id)
		var blocked := _blocked_for_obstacle_layout(layout, movement_type)
		for index in int(wave_definition.get("count", 0)):
			if not _route_exists_from_nearest(Vector2i(2 + index * 2, int(stage.get("enemy_spawn_row", 0))), blocked):
				return false
		for reinforcement in wave_definition.get("reinforcements", []):
			if reinforcement is Dictionary and reinforcement.get("spawn") is Array and reinforcement.spawn.size() == 2:
				var spawn := Vector2i(int(reinforcement.spawn[0]), int(reinforcement.spawn[1]))
				var reinforcement_type := _movement_type_for_unit(reinforcement.get("enemy_id", ""))
				if not _route_exists_from_nearest(spawn, _blocked_for_obstacle_layout(layout, reinforcement_type)):
					return false
	return true

func _blocked_for_obstacle_layout(layout: Array[Dictionary], movement_type: String) -> Dictionary:
	var blocked := blocked_cells.duplicate()
	for obstacle in layout:
		if not obstacle.placed:
			continue
		var definition: Dictionary = obstacle_definitions.get(obstacle.obstacle_id, {})
		if definition.get("blocked_movement_types", []).has(movement_type):
			blocked[obstacle.cell] = true
	return blocked

func _movement_type_for_unit(unit_id: String) -> String:
	return str(_unit_by_content_id(unit_id).get("movement_type", "ground"))

func _route_exists_from_nearest(requested: Vector2i, blocked: Dictionary) -> bool:
	var start := Vector2i(-1, -1)
	for distance in COLUMNS + ROWS:
		for y in ROWS:
			for x in COLUMNS:
				var candidate := Vector2i(x, y)
				if absi(candidate.x - requested.x) + absi(candidate.y - requested.y) == distance and candidate != core_cell and not blocked.has(candidate):
					start = candidate
					break
			if start.x >= 0:
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return false
	return not GridPathfinder.find_path(start, core_cell, COLUMNS, ROWS, blocked).is_empty()

func _wall_at(cell: Vector2i) -> int:
	for index in walls.size():
		if walls[index].hp > 0.0 and walls[index].cell == cell:
			return index
	return -1

func _path_to_core(enemy: Dictionary) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var goals: Array[Vector2i] = [core_cell]
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var adjacent: Vector2i = core_cell + direction
		if _is_inside(adjacent):
			goals.append(adjacent)
	for goal in goals:
		var route := _find_path(enemy, goal)
		if not route.is_empty() and (best.is_empty() or route.size() < best.size()):
			best = route
	return best

func _choose_enemy_action(enemy: Dictionary) -> Dictionary:
	if enemy.cooldown > 0.0:
		enemy.fsm_state = "cooldown"
		return {"kind": "wait"}
	var options: Array[Dictionary] = []
	var weights: Dictionary = enemy.get("ai_weights", {"attack": 1.2, "objective": 1.0})
	var targets: Array[Dictionary] = units.duplicate()
	targets.append_array(facilities)
	var taunt_targets: Array[Dictionary] = units.filter(func(unit): return unit.alive and unit.get("taunt_range", 0) > 0 and _distance(enemy.cell, unit.cell) <= unit.taunt_range and _distance(enemy.cell, unit.cell) <= enemy.range)
	var target_index := targets.find(taunt_targets[0]) if not taunt_targets.is_empty() else _closest_target(enemy.cell, targets, enemy.range)
	if target_index >= 0:
		var target: Dictionary = targets[target_index]
		var distance := absi(enemy.cell.x - target.cell.x) + absi(enemy.cell.y - target.cell.y)
		var attack_score: float = weights.get("attack", 1.2) * (1.0 + 0.5 * (1.0 - float(distance) / float(enemy.range + 1)))
		if target.has("taunt_range") and distance <= target.taunt_range:
			attack_score += 10.0
		options.append({"kind": "attack_facility" if target.has("facility_id") else "attack_unit", "target_index": target_index - units.size() if target.has("facility_id") else target_index, "score": attack_score})
	if stage.mode == "siege":
		if options.is_empty():
			enemy.fsm_state = "guard"
			return {"kind": "wait"}
		enemy.fsm_state = "attack"
		return options[0]
	var route := _path_to_core(enemy)
	if not route.is_empty():
		var objective_score: float = weights.get("objective", 1.0) / float(route.size() + 1)
		options.append({"kind": "attack_core" if route[0] == core_cell else "advance", "route": route, "score": objective_score})
	for wall_index in walls.size():
		var wall: Dictionary = walls[wall_index]
		var wall_route: Variant = _path_to_wall(enemy, wall.cell)
		if wall_route == null:
			continue
		var after_route: Array[Vector2i] = _path_to_core_after_wall(enemy, wall_route.target, wall_index)
		var breaking_turns := ceili(float(wall.hp) / float(enemy.damage))
		var detour_cost: int = route.size() if not route.is_empty() else 1000
		var breach_cost: int = wall_route.path.size() + breaking_turns + after_route.size()
		var breach_score: float = float(weights.get("objective", 1.0)) / float(breach_cost + 1)
		if route.is_empty() or breach_cost < detour_cost:
			options.append({"kind": "attack_wall" if wall_route.path.is_empty() else "advance_wall", "wall_index": wall_index, "route": wall_route.path, "score": breach_score})
	for facility_index in facilities.size():
		var facility: Dictionary = facilities[facility_index]
		if not facility.alive or not facility.blocks_path:
			continue
		var facility_route: Variant = _path_to_wall(enemy, facility.cell)
		if facility_route == null:
			continue
		var facility_after_route: Array[Vector2i] = _path_to_core_after_facility(enemy, facility_route.target, facility_index)
		var facility_break_turns := ceili(float(facility.hp) / float(enemy.damage))
		var facility_breach_cost: int = facility_route.path.size() + facility_break_turns + facility_after_route.size()
		var facility_detour_cost: int = route.size() if not route.is_empty() else 1000
		if route.is_empty() or facility_breach_cost < facility_detour_cost:
			var action_kind := "attack_facility" if facility_route.path.is_empty() else "advance_facility_wall"
			options.append({"kind": action_kind, "target_index": facility_index, "route": facility_route.path, "score": float(weights.get("objective", 1.0)) / float(facility_breach_cost + 1)})
	if options.is_empty():
		enemy.fsm_state = "blocked"
		return {"kind": "wait"}
	var best: Dictionary = options[0]
	for option in options.slice(1):
		if option.score > best.score:
			best = option
	enemy.fsm_state = "attack" if best.kind in ["attack_unit", "attack_facility", "attack_core", "attack_wall"] else "advance"
	return best

func _find_path(mover: Dictionary, goal: Vector2i) -> Array[Vector2i]:
	var blocked := blocked_cells.duplicate()
	var movement_type: String = mover.get("movement_type", "ground")
	for wall in walls:
		blocked[wall.cell] = true
	for obstacle in obstacles:
		var definition: Dictionary = obstacle_definitions.get(obstacle.obstacle_id, {})
		if obstacle.placed and definition.get("blocked_movement_types", []).has(movement_type):
			blocked[obstacle.cell] = true
	for facility in facilities:
		if facility.alive and facility.blocks_path:
			blocked[facility.cell] = true
	for item in units + enemies:
		if item.alive and item.id != mover.id:
			blocked[item.cell] = true
	return GridPathfinder.find_path(mover.cell, goal, COLUMNS, ROWS, blocked)

func _path_to_wall(mover: Dictionary, wall_cell: Vector2i) -> Variant:
	var best: Array[Vector2i] = []
	var target := Vector2i(-1, -1)
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var adjacent: Vector2i = wall_cell + direction
		if not _is_inside(adjacent) or blocked_cells.has(adjacent) or _wall_at(adjacent) >= 0 or _obstacle_blocks_movement(adjacent, mover.get("movement_type", "ground")):
			continue
		if adjacent == mover.cell:
			return {"path": [], "target": adjacent}
		var candidate := _find_path(mover, adjacent)
		if not candidate.is_empty() and (best.is_empty() or candidate.size() < best.size()):
			best = candidate
			target = adjacent
	if target.x < 0:
		return null
	return {"path": best, "target": target}

func _path_to_core_after_wall(mover: Dictionary, start: Vector2i, removed_wall: int) -> Array[Vector2i]:
	var blocked := blocked_cells.duplicate()
	var movement_type: String = mover.get("movement_type", "ground")
	for index in walls.size():
		if index != removed_wall:
			blocked[walls[index].cell] = true
	for facility in facilities:
		if facility.alive and facility.blocks_path:
			blocked[facility.cell] = true
	for obstacle in obstacles:
		var definition: Dictionary = obstacle_definitions.get(obstacle.obstacle_id, {})
		if obstacle.placed and definition.get("blocked_movement_types", []).has(movement_type):
			blocked[obstacle.cell] = true
	for item in units + enemies:
		if item.alive and item.id != mover.id and item.cell != start:
			blocked[item.cell] = true
	return GridPathfinder.find_path(start, core_cell, COLUMNS, ROWS, blocked)

func _path_to_core_after_facility(mover: Dictionary, start: Vector2i, removed_facility: int) -> Array[Vector2i]:
	var blocked := blocked_cells.duplicate()
	var movement_type: String = mover.get("movement_type", "ground")
	for wall in walls:
		blocked[wall.cell] = true
	for index in facilities.size():
		if index != removed_facility and facilities[index].alive and facilities[index].blocks_path:
			blocked[facilities[index].cell] = true
	for obstacle in obstacles:
		var definition: Dictionary = obstacle_definitions.get(obstacle.obstacle_id, {})
		if obstacle.placed and definition.get("blocked_movement_types", []).has(movement_type):
			blocked[obstacle.cell] = true
	for item in units + enemies:
		if item.alive and item.id != mover.id and item.cell != start:
			blocked[item.cell] = true
	return GridPathfinder.find_path(start, core_cell, COLUMNS, ROWS, blocked)

func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS
