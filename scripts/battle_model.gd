class_name BattleModel
extends RefCounted

const COLUMNS := 8
const ROWS := 10
const STAGE_ID := "stage.m1.frontier"

var stage_id := STAGE_ID
var content: Dictionary = {}
var stage: Dictionary = {}
var balance_seed: Dictionary = {}
var facility_definitions: Dictionary = {}
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
var enemy_facilities: Array[Dictionary] = []
var rewarded_waves: Array[int] = []
var blocked_cells: Dictionary = {}
var walls: Array[Dictionary] = []
var wave_elapsed := 0.0
var pending_reinforcements: Array[Dictionary] = []

func _init(selected_stage_id: String = STAGE_ID) -> void:
	stage_id = selected_stage_id
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
		balance_seed[unit.kind] = unit
	for facility in content.categories.facilities:
		facility_definitions[facility.id] = facility
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

func deploy(kind: String, cell: Vector2i) -> bool:
	if not balance_seed.has(kind) or balance_seed[kind].team != "ally" or not stage.get("available_units", []).has(kind) or not _is_inside(cell) or cell.y < 6 or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or _occupied(cell):
		return false
	var cost: int = balance_seed[kind].cost
	if combat_gold < cost:
		return false
	combat_gold -= cost
	var stats: Dictionary = balance_seed[kind]
	units.append({"id": next_id, "kind": kind, "cell": cell, "hp": stats.hp, "damage": stats.damage, "range": stats.range, "heal": stats.get("heal", 0), "heal_range": stats.get("heal_range", 0), "splash_radius": stats.get("splash_radius", 0), "cooldown": 0.0, "alive": true})
	next_id += 1
	return true

func move_unit(unit_id: int, destination: Vector2i) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or phase != "combat" or not _is_inside(destination) or destination.y < 5 or destination == core_cell or blocked_cells.has(destination) or _wall_at(destination) >= 0 or _occupied(destination):
		return false
	unit.destination = destination
	unit.cooldown = maxf(unit.cooldown, 0.5)
	return true

func build_facility(facility_id: String, cell: Vector2i) -> bool:
	if phase not in ["preparation", "combat"] or not facility_definitions.has(facility_id) or not _is_inside(cell) or cell.y < 5 or cell == core_cell or blocked_cells.has(cell) or _wall_at(cell) >= 0 or _occupied(cell):
		return false
	var definition: Dictionary = facility_definitions[facility_id]
	if definition.team != "ally" or combat_gold < definition.cost:
		return false
	combat_gold -= definition.cost
	facilities.append({"id": next_id, "facility_id": facility_id, "kind": definition.kind, "cell": cell, "hp": definition.hp, "damage": definition.damage, "heal": definition.get("heal", 0), "splash_radius": definition.get("splash_radius", 0), "range": definition.range, "attack_time": definition.attack_time, "blocks_path": definition.blocks_path, "cooldown": 0.0, "alive": true})
	next_id += 1
	return true

func move_facility(facility_instance_id: int, destination: Vector2i) -> bool:
	var facility := _facility_by_id(facility_instance_id)
	if facility.is_empty() or phase != "preparation" or not _is_inside(destination) or destination.y < 5 or destination == core_cell or blocked_cells.has(destination) or _wall_at(destination) >= 0 or destination == facility.cell:
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
		unit.cooldown = maxf(0.0, unit.cooldown - delta)
		if unit.has("destination"):
			if unit.cell == unit.destination:
				unit.erase("destination")
			else:
				var route := _find_path(unit, unit.destination)
				if not route.is_empty():
					unit.cell = route[0]
				if unit.cell == unit.destination:
					unit.erase("destination")
				continue
		if unit.get("heal", 0) > 0 and unit.cooldown <= 0.0:
			var ally_index := _lowest_hp_ally(unit.cell, unit.get("heal_range", 0), unit.id)
			if ally_index >= 0:
				units[ally_index].hp = minf(float(balance_seed[units[ally_index].kind].hp), units[ally_index].hp + unit.heal)
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
					unit.cooldown = 0.0
			enemies.clear()
			_prepare_wave_preview()
			pending_reinforcements.clear()
			wave_elapsed = 0.0

func to_dict() -> Dictionary:
	var saved_units: Array[Dictionary] = []
	var saved_facilities: Array[Dictionary] = []
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
	for definition in stage.get("walls", []):
		var cell := Vector2i(definition.cell[0], definition.cell[1])
		var wall_index := _wall_at(cell)
		saved_walls.append({"cell": [cell.x, cell.y], "hp": walls[wall_index].hp if wall_index >= 0 else 0.0})
	return {"stage_id": stage_id, "mode": stage.get("mode", "defense"), "content_version": ProjectVersions.CONTENT_VERSION, "schema_version": ProjectVersions.SCHEMA_VERSION, "save_version": ProjectVersions.SAVE_VERSION, "wave": wave, "phase": phase, "core_hp": core_hp, "combat_gold": combat_gold, "next_id": next_id, "units": saved_units, "facilities": saved_facilities, "walls": saved_walls, "rewarded_waves": rewarded_waves}

func restore(snapshot: Dictionary) -> bool:
	if snapshot.get("stage_id") != stage_id or snapshot.get("mode") != stage.get("mode") or not _version_matches(snapshot.get("content_version"), ProjectVersions.CONTENT_VERSION) or not _version_matches(snapshot.get("schema_version"), ProjectVersions.SCHEMA_VERSION) or not _version_matches(snapshot.get("save_version"), ProjectVersions.SAVE_VERSION) or not _version_matches(snapshot.get("wave"), int(snapshot.get("wave", 0))) or int(snapshot.get("wave", 0)) < 1 or int(snapshot.get("wave", 0)) > waves.size() or not snapshot.get("units") is Array or not snapshot.get("rewarded_waves", []) is Array or (snapshot.has("walls") and not snapshot.walls is Array) or (snapshot.has("facilities") and not snapshot.facilities is Array):
		return false
	var restored_core := float(snapshot.get("core_hp", 0.0))
	var restored_gold := int(snapshot.get("combat_gold", -1))
	var restored_next_id := int(snapshot.get("next_id", 0))
	if snapshot.get("phase") != "preparation" or not is_finite(restored_core) or restored_core <= 0.0 or restored_core > stage.core_hp or restored_gold < 0 or restored_next_id < 1:
		return false
	var restored_units: Array[Dictionary] = []
	var restored_facilities: Array[Dictionary] = []
	var ids: Dictionary = {}
	var occupied: Dictionary = {}
	var max_id := 0
	for saved_unit in snapshot.units:
		if not saved_unit is Dictionary or not _is_integer_value(saved_unit.get("id")) or not _is_valid_cell(saved_unit.get("cell")) or not balance_seed.has(saved_unit.get("kind")) or balance_seed[saved_unit.kind].team != "ally" or not saved_unit.get("alive") is bool:
			return false
		var unit: Dictionary = saved_unit.duplicate(true)
		var id := int(saved_unit.id)
		var cell := Vector2i(int(saved_unit.cell[0]), int(saved_unit.cell[1]))
		var stats: Dictionary = balance_seed[saved_unit.kind]
		if ids.has(id) or cell.y < 5 or occupied.has(cell) or not _is_finite_nonnegative(saved_unit.get("hp")) or float(saved_unit.hp) > stats.hp or not _version_matches(saved_unit.get("damage"), int(stats.damage)) or not _version_matches(saved_unit.get("range"), int(stats.range)) or not _version_matches(saved_unit.get("heal", stats.get("heal", 0)), int(stats.get("heal", 0))) or not _version_matches(saved_unit.get("heal_range", stats.get("heal_range", 0)), int(stats.get("heal_range", 0))) or not _version_matches(saved_unit.get("splash_radius", stats.get("splash_radius", 0)), int(stats.get("splash_radius", 0))) or not _is_finite_nonnegative(saved_unit.get("cooldown")):
			return false
		if unit.has("destination") and not _is_valid_cell(unit.destination):
			return false
		if unit.has("destination"):
			unit.destination = Vector2i(int(unit.destination[0]), int(unit.destination[1]))
			if unit.destination.y < 5:
				return false
		if unit.alive and unit.hp <= 0.0 or not unit.alive and unit.hp > 0.0:
			return false
		unit.cell = cell
		unit.heal = stats.get("heal", 0)
		unit.heal_range = stats.get("heal_range", 0)
		unit.splash_radius = stats.get("splash_radius", 0)
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
	wave = int(snapshot.wave)
	phase = "preparation"
	core_hp = restored_core
	combat_gold = restored_gold
	next_id = restored_next_id
	units.assign(restored_units)
	facilities.assign(restored_facilities)
	walls.assign(restored_walls)
	rewarded_waves.assign(snapshot.get("rewarded_waves", []))
	enemies.clear()
	_prepare_wave_preview()
	return true

func _version_matches(value: Variant, expected: int) -> bool:
	return (value is int or value is float) and float(value) == float(expected)

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

func _strike(attacker: Dictionary, target: Dictionary) -> void:
	if attacker.cooldown > 0.0:
		return
	_apply_damage(attacker, target)
	attacker.cooldown = float(attacker.attack_time) if attacker.has("attack_time") else float(balance_seed[attacker.kind].attack_time)

func _strike_area(attacker: Dictionary, targets: Array[Dictionary], center: Vector2i, radius: int) -> void:
	if attacker.cooldown > 0.0:
		return
	for target in targets:
		var distance := absi(center.x - target.cell.x) + absi(center.y - target.cell.y)
		if target.alive and target.get("active", true) and distance <= radius:
			_apply_damage(attacker, target)
	attacker.cooldown = float(attacker.attack_time) if attacker.has("attack_time") else float(balance_seed[attacker.kind].attack_time)

func _apply_damage(attacker: Dictionary, target: Dictionary) -> void:
	target.hp -= attacker.damage
	if target.hp <= 0.0:
		target.hp = 0.0
		target.alive = false
		if target.get("team", "") == "enemy" or target.kind == "goblin":
				combat_gold += stage.kill_reward

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
	destination.append({"id": -1000 - destination.size(), "kind": enemy_definition.kind, "team": "enemy", "cell": spawn, "hp": enemy_definition.hp, "damage": enemy_definition.damage, "range": enemy_definition.range, "heal": enemy_definition.get("heal", 0), "heal_range": enemy_definition.get("heal_range", 0), "splash_radius": enemy_definition.get("splash_radius", 0), "ai_profile_id": enemy_definition.ai_profile_id, "ai_weights": ai_weights, "cooldown": 0.0, "alive": true, "active": active})
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
	return false

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
	var target_index := _closest_target(enemy.cell, targets, enemy.range)
	if target_index >= 0:
		var target: Dictionary = targets[target_index]
		var distance := absi(enemy.cell.x - target.cell.x) + absi(enemy.cell.y - target.cell.y)
		var attack_score: float = weights.get("attack", 1.2) * (1.0 + 0.5 * (1.0 - float(distance) / float(enemy.range + 1)))
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
	for wall in walls:
		blocked[wall.cell] = true
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
		if not _is_inside(adjacent) or blocked_cells.has(adjacent) or _wall_at(adjacent) >= 0:
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
	for index in walls.size():
		if index != removed_wall:
			blocked[walls[index].cell] = true
	for facility in facilities:
		if facility.alive and facility.blocks_path:
			blocked[facility.cell] = true
	for item in units + enemies:
		if item.alive and item.id != mover.id and item.cell != start:
			blocked[item.cell] = true
	return GridPathfinder.find_path(start, core_cell, COLUMNS, ROWS, blocked)

func _path_to_core_after_facility(mover: Dictionary, start: Vector2i, removed_facility: int) -> Array[Vector2i]:
	var blocked := blocked_cells.duplicate()
	for wall in walls:
		blocked[wall.cell] = true
	for index in facilities.size():
		if index != removed_facility and facilities[index].alive and facilities[index].blocks_path:
			blocked[facilities[index].cell] = true
	for item in units + enemies:
		if item.alive and item.id != mover.id and item.cell != start:
			blocked[item.cell] = true
	return GridPathfinder.find_path(start, core_cell, COLUMNS, ROWS, blocked)

func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS
