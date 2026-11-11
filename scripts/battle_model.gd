class_name BattleModel
extends RefCounted

const COLUMNS := 8
const ROWS := 10
const STAGE_ID := "stage.m1.frontier"

var stage_id := STAGE_ID
var content: Dictionary = {}
var stage: Dictionary = {}
var balance_seed: Dictionary = {}
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
var rewarded_waves: Array[int] = []
var blocked_cells: Dictionary = {}

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
	core_hp = stage.core_hp
	combat_gold = stage.start_resource

func deploy(kind: String, cell: Vector2i) -> bool:
	if not balance_seed.has(kind) or balance_seed[kind].team != "ally" or not _is_inside(cell) or cell.y < 6 or cell == core_cell or blocked_cells.has(cell) or _occupied(cell):
		return false
	var cost: int = balance_seed[kind].cost
	if combat_gold < cost:
		return false
	combat_gold -= cost
	var stats: Dictionary = balance_seed[kind]
	units.append({"id": next_id, "kind": kind, "cell": cell, "hp": stats.hp, "damage": stats.damage, "range": stats.range, "cooldown": 0.0, "alive": true})
	next_id += 1
	return true

func move_unit(unit_id: int, destination: Vector2i) -> bool:
	var unit := _unit_by_id(unit_id)
	if unit.is_empty() or phase != "combat" or not _is_inside(destination) or destination.y < 5 or destination == core_cell or blocked_cells.has(destination) or _occupied(destination):
		return false
	unit.destination = destination
	unit.cooldown = maxf(unit.cooldown, 0.5)
	return true

func start_wave(store: CheckpointStore) -> bool:
	if phase != "preparation" or not store.save_checkpoint(to_dict()):
		return false
	phase = "combat"
	var wave_definition: Dictionary = waves[wave - 1]
	var enemy_definition: Dictionary = _unit_by_content_id(wave_definition.enemy_id)
	var ai_profile: Dictionary = ai_profiles.get(enemy_definition.get("ai_profile_id", ""), {})
	var ai_weights: Dictionary = ai_profile.get("weights", {}).duplicate()
	for action in wave_definition.get("ai_weight_overrides", {}):
		ai_weights[action] = wave_definition.ai_weight_overrides[action]
	for i in wave_definition.count:
		var spawn := Vector2i(2 + i * 2, int(stage.get("enemy_spawn_row", 0)))
		enemies.append({"id": next_id, "kind": enemy_definition.kind, "cell": spawn, "hp": enemy_definition.hp, "damage": enemy_definition.damage, "range": enemy_definition.range, "ai_profile_id": enemy_definition.ai_profile_id, "ai_weights": ai_weights.duplicate(), "cooldown": 0.0, "alive": true})
		next_id += 1
	return true

func tick(delta: float) -> void:
	if phase != "combat":
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
		var target_index := _closest_target(unit.cell, enemies, unit.range)
		if target_index >= 0:
			_strike(unit, enemies[target_index])
		elif stage.mode == "siege" and wave == waves.size() and unit.cooldown <= 0.0:
			var distance := absi(unit.cell.x - core_cell.x) + absi(unit.cell.y - core_cell.y)
			if distance <= unit.range:
				core_hp = maxf(0.0, core_hp - unit.damage)
				unit.cooldown = balance_seed[unit.kind].attack_time
			else:
				var route := _find_path(unit, core_cell)
				if not route.is_empty() and route[0] != core_cell:
					unit.cell = route[0]
	for enemy in enemies:
		if not enemy.alive:
			continue
		enemy.cooldown = maxf(0.0, enemy.cooldown - delta)
		var decision := _choose_enemy_action(enemy)
		match decision.kind:
			"attack_unit": _strike(enemy, units[decision.target_index])
			"attack_core":
				core_hp = maxf(0.0, core_hp - enemy.damage)
				enemy.cooldown = balance_seed[enemy.kind].attack_time
			"advance": enemy.cell = decision.route[0]
	if stage.mode == "siege" and units.all(func(unit: Dictionary) -> bool: return not unit.alive):
		phase = "finished"
		battle_result = "defeat"
	elif stage.mode == "defense" and core_hp <= 0.0:
		phase = "finished"
		battle_result = "defeat"
	elif stage.mode == "siege" and wave == waves.size() and core_hp <= 0.0:
		phase = "finished"
		battle_result = "victory"
	elif enemies.all(func(enemy: Dictionary) -> bool: return not enemy.alive) and not (stage.mode == "siege" and wave == waves.size()):
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

func to_dict() -> Dictionary:
	var saved_units: Array[Dictionary] = []
	for unit in units:
		var saved_unit := unit.duplicate(true)
		saved_unit.cell = [unit.cell.x, unit.cell.y]
		if unit.has("destination"):
			saved_unit.destination = [unit.destination.x, unit.destination.y]
		saved_units.append(saved_unit)
	return {"stage_id": stage_id, "mode": stage.get("mode", "defense"), "content_version": ProjectVersions.CONTENT_VERSION, "schema_version": ProjectVersions.SCHEMA_VERSION, "save_version": ProjectVersions.SAVE_VERSION, "wave": wave, "phase": phase, "core_hp": core_hp, "combat_gold": combat_gold, "next_id": next_id, "units": saved_units, "rewarded_waves": rewarded_waves}

func restore(snapshot: Dictionary) -> bool:
	if snapshot.get("stage_id") != stage_id or snapshot.get("mode") != stage.get("mode") or not _version_matches(snapshot.get("content_version"), ProjectVersions.CONTENT_VERSION) or not _version_matches(snapshot.get("schema_version"), ProjectVersions.SCHEMA_VERSION) or not _version_matches(snapshot.get("save_version"), ProjectVersions.SAVE_VERSION) or not _version_matches(snapshot.get("wave"), int(snapshot.get("wave", 0))) or int(snapshot.get("wave", 0)) < 1 or int(snapshot.get("wave", 0)) > waves.size() or not snapshot.get("units") is Array or not snapshot.get("rewarded_waves", []) is Array:
		return false
	var restored_core := float(snapshot.get("core_hp", 0.0))
	var restored_gold := int(snapshot.get("combat_gold", -1))
	var restored_next_id := int(snapshot.get("next_id", 0))
	if snapshot.get("phase") != "preparation" or not is_finite(restored_core) or restored_core <= 0.0 or restored_core > stage.core_hp or restored_gold < 0 or restored_next_id < 1:
		return false
	var restored_units: Array[Dictionary] = []
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
		if ids.has(id) or cell.y < 5 or occupied.has(cell) or not _is_finite_nonnegative(saved_unit.get("hp")) or float(saved_unit.hp) > stats.hp or not _version_matches(saved_unit.get("damage"), int(stats.damage)) or not _version_matches(saved_unit.get("range"), int(stats.range)) or not _is_finite_nonnegative(saved_unit.get("cooldown")):
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
		ids[id] = true
		occupied[cell] = true
		max_id = maxi(max_id, id)
		restored_units.append(unit)
	for rewarded_wave in snapshot.get("rewarded_waves", []):
		if not _is_integer_value(rewarded_wave) or int(rewarded_wave) < 1 or int(rewarded_wave) >= int(snapshot.wave):
			return false
	if restored_next_id <= max_id:
		return false
	wave = int(snapshot.wave)
	phase = "preparation"
	core_hp = restored_core
	combat_gold = restored_gold
	next_id = restored_next_id
	units.assign(restored_units)
	rewarded_waves.assign(snapshot.get("rewarded_waves", []))
	enemies.clear()
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
		if not target.alive:
			continue
		var distance: int = absi(cell.x - target.cell.x) + absi(cell.y - target.cell.y)
		if distance <= attack_range and distance < best_distance:
			best = index
			best_distance = distance
	return best

func _strike(attacker: Dictionary, target: Dictionary) -> void:
	if attacker.cooldown > 0.0:
		return
	target.hp -= attacker.damage
	attacker.cooldown = balance_seed[attacker.kind].attack_time
	if target.hp <= 0.0:
		target.hp = 0.0
		target.alive = false
		if target.kind == "goblin":
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

func _occupied(cell: Vector2i) -> bool:
	for item in units + enemies:
		if item.alive and item.cell == cell:
			return true
	return false

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
	var target_index := _closest_target(enemy.cell, units, enemy.range)
	if target_index >= 0:
		var target: Dictionary = units[target_index]
		var distance := absi(enemy.cell.x - target.cell.x) + absi(enemy.cell.y - target.cell.y)
		var attack_score: float = weights.get("attack", 1.2) * (1.0 + 0.5 * (1.0 - float(distance) / float(enemy.range + 1)))
		options.append({"kind": "attack_unit", "target_index": target_index, "score": attack_score})
	if stage.mode == "siege":
		if options.is_empty():
			enemy.fsm_state = "guard"
			return {"kind": "wait"}
		enemy.fsm_state = "attack"
		return options[0]
	var route := _path_to_core(enemy)
	if not route.is_empty():
		var objective_score: float = weights.get("objective", 1.0) * (0.5 + 0.5 / float(route.size()))
		options.append({"kind": "attack_core" if route[0] == core_cell else "advance", "route": route, "score": objective_score})
	if options.is_empty():
		enemy.fsm_state = "blocked"
		return {"kind": "wait"}
	var best: Dictionary = options[0]
	for option in options.slice(1):
		if option.score > best.score:
			best = option
	enemy.fsm_state = "attack" if best.kind in ["attack_unit", "attack_core"] else "advance"
	return best

func _find_path(mover: Dictionary, goal: Vector2i) -> Array[Vector2i]:
	var blocked := blocked_cells.duplicate()
	for item in units + enemies:
		if item.alive and item.id != mover.id:
			blocked[item.cell] = true
	return GridPathfinder.find_path(mover.cell, goal, COLUMNS, ROWS, blocked)

func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS
