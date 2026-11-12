extends SceneTree

func _initialize() -> void:
	var valid := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "unit.swordsman", "team": "ally", "hp": 100, "damage": 10, "range": 1, "attack_time": 1.0, "cost": 5, "references": ["skill.slash"], "dependencies": []}], "skills": [{"id": "skill.slash", "references": [], "dependencies": []}]}}
	assert(ContentValidator.validate(valid).is_empty())
	var duplicate := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "same"}], "skills": [{"id": "same"}]}}
	assert(ContentValidator.validate(duplicate).any(func(error): return error.contains("duplicate content id")))
	var dangling := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "unit.a", "references": ["missing"]}]}}
	assert(ContentValidator.validate(dangling).any(func(error): return error.contains("unresolved reference")))
	var missing_dependency := {"content_version": 1, "schema_version": 1, "categories": {"research": [{"id": "research.a", "dependencies": ["missing"]}]}}
	assert(ContentValidator.validate(missing_dependency).any(func(error): return error.contains("unresolved dependency")))
	var invalid_version := {"content_version": 1.5, "schema_version": 1, "categories": {}}
	assert(ContentValidator.validate(invalid_version).any(func(error): return error.contains("content_version")))
	var unsupported_version := {"content_version": 2, "schema_version": 1, "categories": {}}
	assert(ContentValidator.validate(unsupported_version).any(func(error): return error.contains("unsupported content_version")))
	var invalid_category := {"content_version": 1, "schema_version": 1, "categories": {"waves": "bad"}}
	assert(ContentValidator.validate(invalid_category).any(func(error): return error.contains("category waves")))
	var route := GridPathfinder.find_path(Vector2i(0, 1), Vector2i(4, 1), 5, 3, {Vector2i(2, 1): true})
	assert(not route.is_empty() and route[-1] == Vector2i(4, 1) and not route.has(Vector2i(2, 1)))
	assert(GridPathfinder.find_path(Vector2i(0, 0), Vector2i(2, 0), 3, 1, {Vector2i(1, 0): true}).is_empty())
	var seeded_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	assert(ContentValidator.validate(seeded_catalog).is_empty())
	var ai_override_catalog: Dictionary = seeded_catalog.duplicate(true)
	ai_override_catalog.categories.waves[0].ai_weight_overrides = {"objective": 1.5}
	assert(ContentValidator.validate(ai_override_catalog).is_empty())
	ai_override_catalog.categories.waves[0].ai_weight_overrides = "invalid"
	assert(ContentValidator.validate(ai_override_catalog).any(func(error): return error.contains("AI weight overrides")))
	var reinforcement_catalog: Dictionary = seeded_catalog.duplicate(true)
	reinforcement_catalog.categories.waves[0].reinforcements = [{"enemy_id": "enemy.goblin", "count": 2, "at": 1.0, "spawn": [2, 0]}]
	assert(ContentValidator.validate(reinforcement_catalog).is_empty())
	reinforcement_catalog.categories.waves[0].reinforcements[0].spawn = [8, 0]
	assert(ContentValidator.validate(reinforcement_catalog).any(func(error): return error.contains("invalid reinforcement data")))
	var blocked_reinforcement_route: Dictionary = seeded_catalog.duplicate(true)
	blocked_reinforcement_route.categories.waves[0].reinforcements = [{"enemy_id": "enemy.goblin", "count": 1, "at": 1.0, "spawn": [4, 0]}]
	blocked_reinforcement_route.categories.stages[0].blocked_cells.append([4, 0])
	assert(ContentValidator.validate(blocked_reinforcement_route).any(func(error): return error.contains("blocks a reinforcement route")))
	var wall_catalog: Dictionary = seeded_catalog.duplicate(true)
	wall_catalog.categories.stages[0].walls = [{"cell": [3, 5], "hp": 60}]
	assert(ContentValidator.validate(wall_catalog).is_empty())
	wall_catalog.categories.stages[0].walls[0].cell = [4, 9]
	assert(ContentValidator.validate(wall_catalog).any(func(error): return error.contains("conflicting wall cell")))
	var invalid_facility_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_facility_catalog.categories.facilities[0].hp = 0
	assert(ContentValidator.validate(invalid_facility_catalog).any(func(error): return error.contains("invalid facility data")))
	var invalid_healer_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_healer_catalog.categories.facilities[2].range = 0
	assert(ContentValidator.validate(invalid_healer_catalog).any(func(error): return error.contains("invalid facility healing data")))
	var wall_restore_source := BattleModel.new()
	wall_restore_source.walls[0].hp = 20.0
	var wall_snapshot: Dictionary = wall_restore_source.to_dict()
	var wall_restore_target := BattleModel.new()
	assert(wall_restore_target.restore(wall_snapshot) and wall_restore_target.walls[0].hp == 20.0)
	wall_snapshot.erase("walls")
	var legacy_wall_restore := BattleModel.new()
	assert(legacy_wall_restore.restore(wall_snapshot) and legacy_wall_restore.walls[0].hp == 60.0)
	var blocked_route_catalog: Dictionary = seeded_catalog.duplicate(true)
	blocked_route_catalog.categories.stages[0].blocked_cells.clear()
	for x in 8:
		blocked_route_catalog.categories.stages[0].blocked_cells.append([x, 1])
	assert(ContentValidator.validate(blocked_route_catalog).any(func(error): return error.contains("required wave route")))
	var core_block_catalog: Dictionary = seeded_catalog.duplicate(true)
	core_block_catalog.categories.stages[0].blocked_cells.append([4, 9])
	assert(ContentValidator.validate(core_block_catalog).any(func(error): return error.contains("blocks its core cell")))
	var cyclic := {"content_version": 1, "schema_version": 1, "categories": {"research": [{"id": "research.a", "dependencies": ["research.b"]}, {"id": "research.b", "dependencies": ["research.a"]}]}}
	assert(ContentValidator.validate(cyclic).any(func(error): return error.contains("cyclic dependency")))
	assert(ProjectVersions.CONTENT_VERSION == 1 and ProjectVersions.SCHEMA_VERSION == 1 and ProjectVersions.SAVE_VERSION == 1)
	var reinforcement_test := BattleModel.new()
	reinforcement_test.waves[0].count = 1
	reinforcement_test.waves[0].reinforcements = [{"enemy_id": "enemy.goblin", "count": 2, "at": 1.0, "spawn": [2, 0]}]
	var reinforcement_store := CheckpointStore.new("user://m2_reinforcement_test.json")
	assert(reinforcement_test.start_wave(reinforcement_store))
	reinforcement_test.enemies[0].alive = false
	reinforcement_test.tick(0.5)
	assert(reinforcement_test.phase == "combat" and reinforcement_test.pending_reinforcements.size() == 1)
	reinforcement_test.enemies[0].alive = true
	reinforcement_test.enemies[0].cell = Vector2i(2, 0)
	reinforcement_test.wave_elapsed = 1.0
	assert(reinforcement_test._advance_reinforcements())
	assert(reinforcement_test.pending_reinforcements.size() == 1 and reinforcement_test.pending_reinforcements[0].remaining == 1)
	assert(reinforcement_test.enemies[1].cell != Vector2i(2, 0))
	assert(reinforcement_test._advance_reinforcements())
	assert(reinforcement_test.pending_reinforcements.is_empty() and reinforcement_test.enemies.size() == 3)
	var failed_reinforcement := BattleModel.new()
	failed_reinforcement.waves[0].count = 1
	failed_reinforcement.waves[0].reinforcements = [{"enemy_id": "enemy.goblin", "count": 1, "at": 0.0, "spawn": [0, 0]}]
	var failed_store := CheckpointStore.new("user://m2_failed_reinforcement_test.json")
	assert(failed_reinforcement.start_wave(failed_store))
	failed_reinforcement.enemies[0].alive = false
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			failed_reinforcement.blocked_cells[Vector2i(x, y)] = true
	for attempt in 6:
		failed_reinforcement.wave_elapsed += 0.5
		assert(not failed_reinforcement._advance_reinforcements() if attempt == 5 else failed_reinforcement._advance_reinforcements())
	assert(failed_reinforcement.phase == "finished" and failed_reinforcement.battle_result == "safe_abort")
	assert(failed_store.load_checkpoint().phase == "preparation" and failed_reinforcement.combat_gold == failed_reinforcement.stage.start_resource)
	reinforcement_store.clear_checkpoint()
	failed_store.clear_checkpoint()
	var wall_model := BattleModel.new()
	wall_model.walls = [{"cell": Vector2i(1, 0), "hp": 10.0, "max_hp": 10.0}]
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			if cell != Vector2i.ZERO and cell != Vector2i(1, 0):
				wall_model.blocked_cells[cell] = true
	wall_model.phase = "combat"
	wall_model.enemies.append({"id": 300, "kind": "goblin", "cell": Vector2i.ZERO, "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "alive": true})
	wall_model.tick(0.2)
	assert(wall_model.walls.is_empty() and wall_model.enemies[0].cooldown > 0.0)
	var wall_route_choice := BattleModel.new()
	wall_route_choice.phase = "combat"
	wall_route_choice.walls[0].hp = 1.0
	var wall_corridor: Array[Vector2i] = [Vector2i(3, 4), Vector2i(3, 5), Vector2i(3, 6), Vector2i(4, 6), Vector2i(4, 7), Vector2i(4, 8), Vector2i(4, 9)]
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			if not wall_corridor.has(cell):
				wall_route_choice.blocked_cells[cell] = true
	wall_route_choice.enemies.append({"id": 301, "kind": "goblin", "cell": Vector2i(3, 4), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"objective": 1.0}, "alive": true})
	assert(wall_route_choice._choose_enemy_action(wall_route_choice.enemies[0]).kind == "attack_wall")
	var wall_detour_choice := BattleModel.new()
	wall_detour_choice.phase = "combat"
	wall_detour_choice.enemies.append({"id": 302, "kind": "goblin", "cell": Vector2i(3, 4), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"objective": 1.0}, "alive": true})
	assert(wall_detour_choice._choose_enemy_action(wall_detour_choice.enemies[0]).kind == "advance")
	var facility_test := BattleModel.new()
	assert(facility_test.build_facility("facility.arrow_tower", Vector2i(1, 8)))
	assert(facility_test.combat_gold == 80 and not facility_test.build_facility("facility.arrow_tower", Vector2i(1, 8)) and facility_test.combat_gold == 80)
	var facility_instance_id: int = facility_test.facilities[0].id
	assert(facility_test.move_facility(facility_instance_id, Vector2i(2, 8)) and facility_test.combat_gold == 80)
	assert(not facility_test.move_facility(facility_instance_id, Vector2i(4, 9)))
	facility_test.enemies.append({"id": facility_test.next_id, "kind": "goblin", "cell": Vector2i(2, 5), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	facility_test.next_id += 1
	facility_test.phase = "combat"
	assert(not facility_test.move_facility(facility_instance_id, Vector2i(1, 8)))
	facility_test.tick(0.2)
	assert(facility_test.enemies[0].hp == 49.0)
	assert(facility_test.build_facility("facility.defense_wall", Vector2i(3, 8)))
	var facility_wall_test := BattleModel.new()
	assert(facility_wall_test.build_facility("facility.defense_wall", Vector2i(5, 5)))
	var facility_corridor: Array[Vector2i] = [Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7), Vector2i(5, 8), Vector2i(4, 8), Vector2i(4, 9)]
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			if not facility_corridor.has(cell):
				facility_wall_test.blocked_cells[cell] = true
	facility_wall_test.phase = "combat"
	facility_wall_test.enemies.append({"id": 350, "kind": "goblin", "cell": Vector2i(5, 4), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"objective": 1.0}, "alive": true})
	assert(facility_wall_test._path_to_core(facility_wall_test.enemies[0]).is_empty())
	facility_wall_test.tick(0.2)
	assert(facility_wall_test.facilities[0].hp == 50.0)
	var facility_snapshot_source := BattleModel.new()
	assert(facility_snapshot_source.build_facility("facility.arrow_tower", Vector2i(2, 8)))
	facility_snapshot_source.facilities[0].hp = 35.0
	var facility_snapshot: Dictionary = facility_snapshot_source.to_dict()
	var facility_snapshot_target := BattleModel.new()
	assert(facility_snapshot_target.restore(facility_snapshot) and facility_snapshot_target.facilities[0].hp == 35.0)
	var support_heal_test := BattleModel.new()
	support_heal_test.combat_gold = 205
	assert(support_heal_test.deploy("swordsman", Vector2i(1, 8)) and support_heal_test.deploy("archer", Vector2i(2, 8)))
	support_heal_test.units[0].hp = 110.0
	support_heal_test.units[1].hp = 30.0
	assert(support_heal_test.build_facility("facility.support_outpost", Vector2i(3, 8)))
	support_heal_test.phase = "combat"
	support_heal_test.enemies.append({"id": 4, "kind": "goblin", "cell": Vector2i.ZERO, "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	support_heal_test.tick(0.2)
	assert(support_heal_test.units[0].hp == 110.0 and support_heal_test.units[1].hp == 38.0)
	assert(support_heal_test.facilities[0].cooldown == 1.5)
	support_heal_test.facilities[0].cooldown = 0.0
	support_heal_test.units[0].hp = 120.0
	support_heal_test.units[1].hp = 75.0
	support_heal_test.tick(0.2)
	assert(support_heal_test.units[1].hp == 80.0)
	support_heal_test.units[0].alive = false
	support_heal_test.units[0].hp = 0.0
	support_heal_test.facilities[0].cooldown = 0.0
	support_heal_test.tick(0.2)
	assert(support_heal_test.units[0].hp == 0.0 and support_heal_test.units[1].hp == 80.0 and support_heal_test.facilities[0].cooldown == 0.0)
	support_heal_test.phase = "preparation"
	var support_heal_snapshot := support_heal_test.to_dict()
	var support_heal_restore := BattleModel.new()
	assert(support_heal_restore.restore(support_heal_snapshot) and support_heal_restore.facilities[0].heal == 8)
	var rebuilt_cell_model := BattleModel.new()
	assert(rebuilt_cell_model.deploy("swordsman", Vector2i(3, 8)))
	rebuilt_cell_model.units[0].alive = false
	rebuilt_cell_model.units[0].hp = 0.0
	assert(rebuilt_cell_model.build_facility("facility.arrow_tower", Vector2i(3, 8)))
	var rebuilt_cell_restore := BattleModel.new()
	assert(rebuilt_cell_restore.restore(rebuilt_cell_model.to_dict()) and rebuilt_cell_restore.facilities[0].alive)
	var facility_targeting := BattleModel.new()
	facility_targeting.phase = "combat"
	assert(facility_targeting.build_facility("facility.arrow_tower", Vector2i(2, 8)))
	facility_targeting.enemies.append({"id": 400, "kind": "goblin", "cell": Vector2i(2, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	facility_targeting.tick(0.2)
	assert(facility_targeting.facilities[0].hp == 110.0)
	facility_targeting.facilities[0].hp = 5.0
	facility_targeting.enemies[0].cooldown = 0.0
	facility_targeting.tick(0.2)
	assert(not facility_targeting.facilities[0].alive and facility_targeting.facilities[0].hp == 0.0)
	facility_targeting.phase = "preparation"
	assert(facility_targeting.build_facility("facility.arrow_tower", Vector2i(2, 8)))
	var destroyed_facility_snapshot: Dictionary = facility_targeting.to_dict()
	var destroyed_facility_restore := BattleModel.new()
	assert(destroyed_facility_restore.restore(destroyed_facility_snapshot) and not destroyed_facility_restore.facilities[0].alive and destroyed_facility_restore.facilities[1].alive)
	var battle := BattleModel.new()
	assert(battle.deploy("swordsman", Vector2i(3, 8)))
	assert(not battle.deploy("swordsman", Vector2i(3, 5)))
	assert(not battle.deploy("archer", Vector2i(3, 8)))
	var store := CheckpointStore.new("user://m0_checkpoint_test.json")
	assert(battle.start_wave(store))
	assert(battle.phase == "combat")
	var disk_snapshot := store.load_checkpoint()
	var restored := BattleModel.new()
	assert(restored.restore(disk_snapshot))
	assert(restored.phase == "preparation" and restored.units[0].cell == Vector2i(3, 8))
	var incompatible := disk_snapshot.duplicate(true)
	incompatible.schema_version = ProjectVersions.SCHEMA_VERSION + 1
	assert(not restored.restore(incompatible))
	assert(restored.wave == 1 and restored.units.size() == 1)
	assert(store.save_checkpoint({"revision": 2}))
	assert(store.load_checkpoint().revision == 2)
	assert(battle.move_unit(1, Vector2i(4, 7)))
	assert(battle.units[0].cell == Vector2i(3, 8))
	battle.enemies.resize(1)
	battle.enemies[0].cell = Vector2i(3, 7)
	battle.enemies[0].hp = 1.0
	battle.units[0].cell = Vector2i(3, 8)
	battle.units[0].destination = Vector2i(3, 8)
	battle.tick(1.0)
	assert(battle.enemies.is_empty())
	assert(battle.wave == 2 and battle.phase == "preparation")
	assert(battle.rewarded_waves == [1])
	assert(battle.start_wave(store))
	for enemy in battle.enemies:
		enemy.alive = false
	battle.tick(0.2)
	assert(battle.phase == "finished" and battle.battle_result == "victory")
	assert(battle.rewarded_waves == [1, 2])
	var core_test := BattleModel.new()
	core_test.core_hp = 5.0
	core_test.phase = "combat"
	core_test.enemies.append({"id": 99, "kind": "goblin", "cell": Vector2i(4, 8), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "alive": true})
	core_test.tick(0.2)
	assert(core_test.phase == "finished" and core_test.battle_result == "defeat")
	var siege_test := BattleModel.new("stage.m2.siege")
	assert(siege_test.stage.mode == "siege" and siege_test.core_cell == Vector2i(4, 0))
	siege_test.wave = siege_test.waves.size()
	siege_test.phase = "combat"
	siege_test.core_hp = 20.0
	siege_test.units.append({"id": 200, "kind": "swordsman", "cell": Vector2i(4, 1), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "alive": true})
	siege_test.enemies.append({"id": 201, "kind": "goblin", "cell": Vector2i(0, 2), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	siege_test.tick(0.2)
	assert(siege_test.phase == "finished" and siege_test.battle_result == "victory" and siege_test.enemies[0].alive)
	var siege_wipe_test := BattleModel.new("stage.m2.siege")
	siege_wipe_test.phase = "combat"
	siege_wipe_test.tick(0.2)
	assert(siege_wipe_test.phase == "finished" and siege_wipe_test.battle_result == "defeat")
	var siege_checkpoint_source := BattleModel.new("stage.m2.siege")
	assert(siege_checkpoint_source.deploy("swordsman", Vector2i(3, 8)))
	var siege_checkpoint := siege_checkpoint_source.to_dict()
	var siege_restore_test := BattleModel.new("stage.m2.siege")
	assert(siege_restore_test.restore(siege_checkpoint))
	assert(not BattleModel.new().restore(siege_checkpoint))
	var path_test := BattleModel.new()
	path_test.phase = "combat"
	path_test.blocked_cells[Vector2i(1, 9)] = true
	path_test.units.append({"id": 100, "kind": "swordsman", "cell": Vector2i(2, 9), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "alive": true})
	path_test.enemies.append({"id": 101, "kind": "goblin", "cell": Vector2i(0, 9), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	path_test.tick(0.2)
	assert(path_test.enemies[0].cell != Vector2i(0, 9) and path_test.enemies[0].cell != Vector2i(1, 9) and path_test.enemies[0].cell != Vector2i(2, 9))
	assert(path_test.enemies[0].fsm_state == "advance")
	var attack_test := BattleModel.new()
	attack_test.phase = "combat"
	attack_test.units.append({"id": 102, "kind": "swordsman", "cell": Vector2i(4, 7), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "alive": true})
	attack_test.enemies.append({"id": 103, "kind": "goblin", "cell": Vector2i(4, 6), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	attack_test.tick(0.2)
	assert(attack_test.enemies[0].fsm_state == "attack" and attack_test.units[0].hp == 110.0)
	attack_test.tick(0.2)
	assert(attack_test.enemies[0].fsm_state == "cooldown")
	var wave_override_test := BattleModel.new()
	wave_override_test.waves[0].ai_weight_overrides = {"objective": 2.5}
	var ai_store := CheckpointStore.new("user://m2_ai_override_test.json")
	assert(wave_override_test.start_wave(ai_store))
	assert(wave_override_test.enemies[0].ai_weights.objective == 2.5)
	ai_store.clear_checkpoint()
	var utility_test := BattleModel.new()
	utility_test.phase = "combat"
	utility_test.units.append({"id": 104, "kind": "swordsman", "cell": Vector2i(4, 7), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "alive": true})
	utility_test.enemies.append({"id": 105, "kind": "goblin", "cell": Vector2i(4, 6), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 0.1, "objective": 10.0}, "alive": true})
	utility_test.tick(0.2)
	assert(utility_test.enemies[0].fsm_state == "advance" and utility_test.units[0].hp == 120.0)
	var blocked_ai_test := BattleModel.new()
	blocked_ai_test.phase = "combat"
	blocked_ai_test.blocked_cells[Vector2i(1, 0)] = true
	blocked_ai_test.blocked_cells[Vector2i(0, 1)] = true
	blocked_ai_test.enemies.append({"id": 106, "kind": "goblin", "cell": Vector2i.ZERO, "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	blocked_ai_test.tick(0.2)
	assert(blocked_ai_test.enemies[0].fsm_state == "blocked" and blocked_ai_test.enemies[0].cell == Vector2i.ZERO)
	var ally_path_test := BattleModel.new()
	ally_path_test.phase = "combat"
	ally_path_test.units.append({"id": 102, "kind": "swordsman", "cell": Vector2i(2, 9), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "alive": true})
	ally_path_test.blocked_cells[Vector2i(3, 9)] = true
	assert(ally_path_test.move_unit(102, Vector2i(4, 8)))
	ally_path_test.tick(0.2)
	assert(ally_path_test.units[0].cell != Vector2i(3, 9) and ally_path_test.units[0].cell != Vector2i(2, 9))
	store.clear_checkpoint()
	var playable := BattleModel.new()
	var trial_store := CheckpointStore.new("user://m1_trial_checkpoint.json")
	assert(playable.deploy("swordsman", Vector2i(3, 6)))
	assert(playable.deploy("swordsman", Vector2i(4, 6)))
	assert(playable.deploy("archer", Vector2i(5, 6)))
	for trial_wave in 2:
		assert(playable.start_wave(trial_store))
		for _frame in 1000:
			if playable.phase != "combat":
				break
			playable.tick(0.2)
		if trial_wave == 0:
			assert(playable.wave == 2 and playable.phase == "preparation")
	assert(playable.phase == "finished" and playable.battle_result == "victory")
	trial_store.clear_checkpoint()
	var battle_scene: PackedScene = load("res://scenes/battle.tscn")
	assert(battle_scene != null)
	print("All headless project tests passed")
	quit(0)
