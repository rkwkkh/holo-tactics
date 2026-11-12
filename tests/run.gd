extends SceneTree

func _initialize() -> void:
	var inspector_record := EditableCatalogRecord.new()
	inspector_record.set_record({"id": "test.record", "label": "Before", "cost": 1})
	assert(inspector_record._get("label") == "Before")
	assert(inspector_record._set("cost", 50) and inspector_record.values.cost == 50)
	assert(not inspector_record._set("unknown", 1))
	var main_script: Script = load("res://scripts/main.gd")
	for viewport_width in [320.0, 360.0, 412.0]:
		assert(main_script.campaign_stage_button_width(viewport_width) * 2.0 <= viewport_width)
	var catalog_recovery_path := "user://catalog_recovery_test.json"
	for suffix in ["", ".bak"]:
		var stale_path: String = catalog_recovery_path + suffix
		if FileAccess.file_exists(stale_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_path))
	var catalog_backup := FileAccess.open(catalog_recovery_path + ".bak", FileAccess.WRITE)
	assert(catalog_backup != null)
	catalog_backup.store_string("{\"recovered\":true}")
	catalog_backup.close()
	var content_editor_script: Script = load("res://addons/content_editor/content_editor.gd")
	var error_field_edit := TextEdit.new()
	error_field_edit.text = JSON.stringify({"id": "unit.test", "hp": 0, "special_skill": {"mode": "broken"}}, "\t")
	content_editor_script._focus_error_field(error_field_edit, "unit.test.hp: invalid unit data", "unit.test")
	assert(error_field_edit.get_selected_text() == "\"hp\"")
	error_field_edit.deselect()
	content_editor_script._focus_error_field(error_field_edit, "evolution.test.special_skill.mode|effect: invalid skill", "evolution.test")
	assert(error_field_edit.get_selected_text() == "\"mode\"")
	error_field_edit.free()
	var battle_view_script: Script = load("res://scripts/battle_view.gd")
	var synthetic_frame_times: Array[float] = [0.01, 0.02, 0.03, 0.04]
	var frame_stats: Dictionary = battle_view_script.summarize_frame_times(synthetic_frame_times)
	assert(is_equal_approx(frame_stats.avg_fps, 40.0) and is_equal_approx(frame_stats.p50_ms, 20.0) and is_equal_approx(frame_stats.p95_ms, 40.0) and is_equal_approx(frame_stats.max_ms, 40.0))
	var sprite_probe: Variant = battle_view_script.new()
	sprite_probe.battle_sprite_atlas = load("res://assets/battle_sprites.svg")
	for sprite_id in battle_view_script.BATTLE_SPRITE_CELLS:
		var sprite: Texture2D = sprite_probe._battle_sprite(sprite_id)
		assert(sprite != null and sprite.get_width() == 32 and sprite.get_height() == 32)
	var sprite_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	for unit in sprite_catalog.categories.units:
		assert(battle_view_script.BATTLE_SPRITE_CELLS.has(unit.kind))
	for facility in sprite_catalog.categories.facilities:
		assert(battle_view_script.BATTLE_SPRITE_CELLS.has(facility.kind) if facility.team == "ally" else battle_view_script.BATTLE_SPRITE_CELLS.has(facility.id))
	sprite_probe.free()
	var recovered_catalog: Variant = content_editor_script.read_catalog(catalog_recovery_path)
	assert(recovered_catalog is Dictionary and recovered_catalog.get("recovered", false))
	assert(FileAccess.file_exists(catalog_recovery_path) and not FileAccess.file_exists(catalog_recovery_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(catalog_recovery_path))
	var resume_test_dir := "user://resume_discovery_%s" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(resume_test_dir)) == OK)
	assert(CheckpointStore.path_for_stage(BattleModel.STAGE_ID, resume_test_dir) == resume_test_dir.path_join("battle_checkpoint.json"))
	var resume_stage_id := "stage.m4.forest"
	var resume_checkpoint_path := CheckpointStore.path_for_stage(resume_stage_id, resume_test_dir)
	assert(resume_checkpoint_path == resume_test_dir.path_join("battle_checkpoint_stage_m4_forest.json"))
	assert(CheckpointStore.latest_stage_with_checkpoint([{"id": resume_stage_id}], resume_test_dir).is_empty())
	var resume_checkpoint := FileAccess.open(resume_checkpoint_path + ".bak", FileAccess.WRITE)
	assert(resume_checkpoint != null)
	resume_checkpoint.store_string("{}")
	resume_checkpoint.close()
	assert(CheckpointStore.latest_stage_with_checkpoint([{"id": resume_stage_id}], resume_test_dir) == resume_stage_id)
	assert(FileAccess.file_exists(resume_checkpoint_path) and not FileAccess.file_exists(resume_checkpoint_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(resume_checkpoint_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(resume_test_dir))
	var valid := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "unit.swordsman", "kind": "swordsman", "team": "ally", "movement_type": "ground", "hp": 100, "damage": 10, "range": 1, "attack_time": 1.0, "cost": 5, "references": ["skill.slash", "skill.guard"], "dependencies": []}], "skills": [{"id": "skill.slash", "unit_kind": "swordsman", "mode": "automatic", "effect": "strike", "cooldown": 5.0, "cost": 0, "value": 10, "radius": 0, "label": "Strike", "references": [], "dependencies": []}, {"id": "skill.guard", "unit_kind": "swordsman", "mode": "manual", "effect": "shield", "cooldown": 5.0, "cost": 1, "value": 10, "radius": 1, "label": "Guard", "references": [], "dependencies": []}]}}
	assert(ContentValidator.validate(valid).is_empty())
	var progress_test_path := "user://progress_store_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var old_path: String = progress_test_path + suffix
		if FileAccess.file_exists(old_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
	var progress_test := ProgressStore.new(progress_test_path)
	assert(progress_test.load_progress())
	assert(progress_test.data.permanent_currency == ProjectVersions.STARTING_PERMANENT_CURRENCY)
	assert(progress_test.grant_reward_once("clear.stage.1.first", 12))
	assert(not progress_test.grant_reward_once("clear.stage.1.first", 12))
	var progress_restore := ProgressStore.new(progress_test_path)
	assert(progress_restore.load_progress() and progress_restore.data.permanent_currency == 112)
	assert(progress_restore.settle_run("attempt-1", "stage.m1.frontier", "victory", 2, 30, 10, 5) == 40)
	assert(progress_restore.data.completed_stages.has("stage.m1.frontier"))
	assert(progress_restore.settle_run("attempt-1", "stage.m1.frontier", "victory", 2, 30, 10, 5) == 40)
	assert(progress_restore.settle_run("attempt-2", "stage.m1.frontier", "victory", 2, 30, 10, 5) == 10)
	assert(progress_restore.settle_run("attempt-3", "stage.m2.siege", "abandoned", 2, 40, 12, 6) == 12)
	assert(progress_restore.data.permanent_currency == 174)
	assert(progress_restore.settle_run("attempt-4", "stage.m2.siege", "defeat", 0, 40, 12, 6) == 0)
	progress_restore.data.permanent_currency = -1
	assert(not progress_restore.save_progress())
	assert(DirAccess.rename_absolute(ProjectSettings.globalize_path(progress_test_path), ProjectSettings.globalize_path(progress_test_path + ".bak")) == OK)
	var backup_restore := ProgressStore.new(progress_test_path)
	assert(backup_restore.load_progress() and backup_restore.data.permanent_currency == 174)
	assert(FileAccess.file_exists(progress_test_path) and not FileAccess.file_exists(progress_test_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_test_path))
	var village_test_path := "user://village_model_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var old_village_path: String = village_test_path + suffix
		if FileAccess.file_exists(old_village_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(old_village_path))
	var village_test := VillageModel.new(village_test_path)
	assert(load("res://scenes/village.tscn") != null)
	assert(village_test.has_building("headquarters") and village_test.place_building("training_hall", Vector2i(0, 0)))
	assert(village_test.progress.data.permanent_currency == 25)
	assert(village_test.move_building("training_hall", Vector2i(1, 0)))
	assert(village_test.store_building("training_hall") and not village_test.has_building("training_hall"))
	assert(village_test.place_building("training_hall", Vector2i(0, 1)) and village_test.progress.data.permanent_currency == 25)
	var village_unlock_path := "user://village_unlock_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var old_unlock_path: String = village_unlock_path + suffix
		if FileAccess.file_exists(old_unlock_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(old_unlock_path))
	var village_unlock_test := VillageModel.new(village_unlock_path)
	assert(not village_unlock_test.place_building("workshop", Vector2i(0, 0)))
	village_unlock_test.progress.data.completed_stages.append("stage.m2.crossroads")
	assert(village_unlock_test.progress.save_progress() and village_unlock_test.place_building("workshop", Vector2i(0, 0)))
	assert(village_unlock_test.has_building("workshop") and village_unlock_test.progress.data.permanent_currency == 0)
	var research_path := "user://village_research_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		var old_research_path: String = research_path + suffix
		if FileAccess.file_exists(old_research_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(old_research_path))
	var research_village := VillageModel.new(research_path)
	research_village.progress.data.completed_stages.append("stage.m1.frontier")
	research_village.progress.data.permanent_currency = 200
	assert(research_village.progress.save_progress())
	assert(not research_village.can_purchase_research("research.swordsman.damage"))
	assert(research_village.place_building("training_hall", Vector2i(0, 0)))
	assert(research_village.can_purchase_research("research.swordsman.damage"))
	assert(research_village.purchase_research("research.swordsman.damage"))
	assert(not research_village.purchase_research("research.swordsman.damage"))
	assert(not research_village.can_purchase_research("research.evolution.swordsman.knight"))
	research_village.progress.data.permanent_currency = 100
	assert(research_village.progress.save_progress())
	assert(research_village.can_purchase_research("research.evolution.swordsman.knight"))
	assert(research_village.purchase_research("research.evolution.swordsman.knight"))
	assert(research_village.store_building("training_hall"))
	assert(not research_village.can_purchase_research("research.archer.damage"))
	var researched_battle := BattleModel.new()
	assert(researched_battle.set_permanent_research(["research.swordsman.damage", "research.evolution.swordsman.knight"]))
	assert(researched_battle.unlocked_evolutions == ["evolution.swordsman.knight"])
	assert(not researched_battle.set_permanent_research(["research.missing"]))
	assert(researched_battle.deploy("swordsman", Vector2i(3, 6)))
	assert(researched_battle.units[0].damage == researched_battle.balance_seed.swordsman.damage)
	var researched_restore := BattleModel.new()
	assert(researched_restore.restore(researched_battle.to_dict()))
	assert(researched_restore.permanent_research == ["research.swordsman.damage", "research.evolution.swordsman.knight"])
	assert(researched_restore.unlocked_evolutions == ["evolution.swordsman.knight"])
	var evolution_research_ids: Array[String] = []
	for research in researched_battle.content.categories.research:
		if research.get("effect", "") == "unlock_evolution":
			evolution_research_ids.append(research.id)
	var all_evolutions_model := BattleModel.new()
	assert(all_evolutions_model.set_permanent_research(evolution_research_ids))
	assert(all_evolutions_model.unlocked_evolutions.size() == 6)
	var evolved_battle := BattleModel.new()
	assert(evolved_battle.set_permanent_research(["research.evolution.swordsman.knight"]))
	assert(evolved_battle.deploy("swordsman", Vector2i(3, 6)))
	var evolved_unit: Dictionary = evolved_battle.units[0]
	evolved_unit.upgrades = {"upgrade.swordsman.charge": 2, "upgrade.swordsman.combo": 3}
	evolved_battle._apply_unit_upgrades(evolved_unit)
	evolved_battle.combat_gold = 200
	var evolved_unit_id: int = evolved_unit.id
	assert(evolved_battle.can_evolve_unit(evolved_unit_id, "evolution.swordsman.knight"))
	assert(evolved_battle.evolve_unit(evolved_unit_id, "evolution.swordsman.knight"))
	assert(evolved_unit.id == evolved_unit_id and evolved_unit.cell == Vector2i(3, 6) and evolved_unit.upgrades["upgrade.swordsman.charge"] == 2 and evolved_battle.combat_gold == 115)
	assert(not evolved_battle.can_evolve_unit(evolved_unit_id, "evolution.swordsman.knight"))
	evolved_battle.phase = "combat"
	evolved_battle.enemies.append({"id": 400, "kind": "goblin", "cell": Vector2i(3, 5), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 10.0, "alive": true})
	assert(evolved_battle.cast_skill(evolved_unit_id, "evolution.swordsman.knight.special"))
	evolved_battle.phase = "preparation"
	var evolved_snapshot := evolved_battle.to_dict()
	var evolved_restore := BattleModel.new()
	assert(evolved_restore.restore(evolved_snapshot))
	assert(evolved_restore.units[0].evolution_id == "evolution.swordsman.knight" and evolved_restore.units[0].skill_cooldowns["evolution.swordsman.knight.special"] == 14.0)
	var invalid_evolution_snapshot: Dictionary = evolved_snapshot.duplicate(true)
	invalid_evolution_snapshot.units[0].evolution_id = "evolution.archer.bomber"
	var rejected_evolution_restore := BattleModel.new()
	assert(not rejected_evolution_restore.restore(invalid_evolution_snapshot) and rejected_evolution_restore.units.is_empty() and rejected_evolution_restore.unlocked_evolutions.is_empty())
	var legacy_save := researched_battle.to_dict()
	legacy_save.save_version = 1
	assert(BattleModel.new().restore(legacy_save))
	var automatic_evolution := BattleModel.new("stage.m2.crossroads")
	assert(automatic_evolution.set_permanent_research(["research.evolution.spearman.guardian"]))
	assert(automatic_evolution.deploy("spearman", Vector2i(2, 8)))
	automatic_evolution.units[0].upgrades = {"upgrade.spearman.shield": 2, "upgrade.spearman.taunt": 3}
	automatic_evolution.combat_gold = 200
	assert(automatic_evolution.evolve_unit(automatic_evolution.units[0].id, "evolution.spearman.guardian"))
	automatic_evolution.phase = "combat"
	automatic_evolution.units[0].skill_cooldowns["skill.spearman.guard"] = 12.0
	automatic_evolution.pending_reinforcements.append({"enemy_id": "enemy.goblin", "remaining": 1, "spawn": Vector2i(0, 0), "at": 10.0, "attempts": 0})
	automatic_evolution.tick(0.2)
	assert(automatic_evolution.units[0].shield == 15.0 and automatic_evolution.units[0].skill_cooldowns["evolution.spearman.guardian.special"] == 14.0)
	var archer_branches := BattleModel.new()
	assert(archer_branches.set_permanent_research(["research.evolution.archer.ice", "research.evolution.archer.bomber"]))
	assert(archer_branches.deploy("archer", Vector2i(2, 6)))
	archer_branches.units[0].upgrades = {"upgrade.archer.freeze": 3, "upgrade.archer.explosive": 2, "upgrade.archer.multi": 2}
	archer_branches.combat_gold = 300
	assert(archer_branches.can_evolve_unit(archer_branches.units[0].id, "evolution.archer.ice") and archer_branches.can_evolve_unit(archer_branches.units[0].id, "evolution.archer.bomber"))
	assert(archer_branches.evolve_unit(archer_branches.units[0].id, "evolution.archer.ice"))
	assert(not archer_branches.can_evolve_unit(archer_branches.units[0].id, "evolution.archer.bomber"))
	var atomic_restore := BattleModel.new()
	for version_key in ["content_version", "schema_version", "save_version"]:
		var incompatible_research_snapshot: Dictionary = researched_battle.to_dict()
		incompatible_research_snapshot[version_key] += 1
		assert(not atomic_restore.restore(incompatible_research_snapshot))
		assert(atomic_restore.permanent_research.is_empty() and atomic_restore.balance_seed.swordsman.damage == atomic_restore.base_balance_seed.swordsman.damage)
	var malformed_research_snapshot: Dictionary = researched_battle.to_dict()
	malformed_research_snapshot.units[0].damage += 1
	assert(not atomic_restore.restore(malformed_research_snapshot))
	assert(atomic_restore.permanent_research.is_empty() and atomic_restore.balance_seed.swordsman.damage == atomic_restore.base_balance_seed.swordsman.damage)
	var movement_snapshot: Dictionary = researched_battle.to_dict()
	var legacy_movement_snapshot: Dictionary = movement_snapshot.duplicate(true)
	legacy_movement_snapshot.units[0].erase("movement_type")
	var legacy_movement_restore := BattleModel.new()
	assert(legacy_movement_restore.restore(legacy_movement_snapshot))
	assert(legacy_movement_restore.units[0].movement_type == "ground")
	var invalid_movement_snapshot: Dictionary = movement_snapshot.duplicate(true)
	invalid_movement_snapshot.units[0].movement_type = "air"
	assert(not BattleModel.new().restore(invalid_movement_snapshot))
	var direct_wave_preview := BattleModel.new("stage.m1.frontier")
	assert(direct_wave_preview.select_preview_wave(direct_wave_preview.waves[1].id))
	assert(direct_wave_preview.wave == 2 and direct_wave_preview.phase == "preparation" and direct_wave_preview.combat_gold == direct_wave_preview.stage.start_resource)
	var siege_movement := BattleModel.new("stage.m3.fortress")
	var siege_movement_store := CheckpointStore.new("user://siege_movement_test.json")
	assert(siege_movement.deploy("swordsman", Vector2i(3, 8)))
	assert(siege_movement.start_wave(siege_movement_store))
	var original_blocked := siege_movement.blocked_cells.duplicate()
	for x in BattleModel.COLUMNS:
		siege_movement.blocked_cells[Vector2i(x, 4)] = true
	assert(not siege_movement.move_unit(1, Vector2i(2, 3)))
	siege_movement.blocked_cells = original_blocked
	assert(siege_movement.move_unit(1, Vector2i(2, 3)))
	siege_movement.phase = "preparation"
	var siege_movement_restore := BattleModel.new("stage.m3.fortress")
	assert(siege_movement_restore.restore(siege_movement.to_dict()))
	assert(siege_movement_restore.units[0].destination == Vector2i(2, 3))
	siege_movement_store.clear_checkpoint()
	var m4_store_path := "user://m4_playability_test.json"
	if FileAccess.file_exists(m4_store_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(m4_store_path))
	var m4_playable := BattleModel.new("stage.m4.forest")
	assert(m4_playable.combat_gold == 260)
	assert(m4_playable.deploy("swordsman", Vector2i(2, 8)))
	assert(m4_playable.deploy("archer", Vector2i(4, 8)))
	assert(m4_playable.deploy("spearman", Vector2i(3, 8)))
	assert(m4_playable.build_facility("facility.arrow_tower", Vector2i(5, 8)))
	var m4_playable_store := CheckpointStore.new(m4_store_path)
	for _wave in 4:
		assert(m4_playable.start_wave(m4_playable_store))
		for _frame in 2500:
			if m4_playable.phase != "combat": break
			m4_playable.tick(0.2)
		if m4_playable.phase == "finished": break
	assert(m4_playable.phase == "finished" and m4_playable.battle_result == "victory")
	m4_playable_store.clear_checkpoint()
	var legacy_path := "user://legacy_progress_test.json"
	var legacy := village_unlock_test.progress.data.duplicate(true)
	legacy.erase("buildings")
	var legacy_file := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	var migrated := ProgressStore.new(legacy_path)
	assert(migrated.load_progress() and migrated.data.buildings.size() == 1 and migrated.data.buildings[0].kind == "headquarters")
	var corrupt_path := "user://corrupt_village_progress_test.json"
	var corrupt_file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	corrupt_file.store_string("{}")
	corrupt_file.close()
	var protected_village := VillageModel.new(corrupt_path)
	assert(not protected_village.available and not protected_village.place_building("training_hall", Vector2i(0, 0)))
	assert(FileAccess.get_file_as_string(corrupt_path) == "{}")
	var protected_progress := ProgressStore.new(corrupt_path)
	protected_progress.data.permanent_currency = 777
	assert(not protected_progress.load_progress())
	assert(protected_progress.data.permanent_currency == 777 and FileAccess.get_file_as_string(corrupt_path) == "{}")
	for path in [village_test_path, village_unlock_path, research_path]:
		for suffix in ["", ".tmp", ".bak"]:
			var cleanup_path: String = path + suffix
			if FileAccess.file_exists(cleanup_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(cleanup_path))
	if FileAccess.file_exists(legacy_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_path))
	if FileAccess.file_exists(corrupt_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(corrupt_path))
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
	assert(ContentValidator.warnings(seeded_catalog).is_empty())
	var stale_catalog_path := "user://catalog_stale_backup_test.json"
	for suffix in ["", ".bak"]:
		var stale_catalog_file: String = stale_catalog_path + suffix
		if FileAccess.file_exists(stale_catalog_file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_catalog_file))
	for catalog_path in [stale_catalog_path, stale_catalog_path + ".bak"]:
		var catalog_file := FileAccess.open(catalog_path, FileAccess.WRITE)
		assert(catalog_file != null)
		catalog_file.store_string(JSON.stringify(seeded_catalog))
		catalog_file.close()
	assert(content_editor_script.read_catalog(stale_catalog_path) is Dictionary)
	assert(not FileAccess.file_exists(stale_catalog_path + ".bak"))
	var invalid_catalog_file := FileAccess.open(stale_catalog_path, FileAccess.WRITE)
	assert(invalid_catalog_file != null)
	invalid_catalog_file.store_string("{}")
	invalid_catalog_file.close()
	var invalid_catalog_backup := FileAccess.open(stale_catalog_path + ".bak", FileAccess.WRITE)
	assert(invalid_catalog_backup != null)
	invalid_catalog_backup.store_string(JSON.stringify(seeded_catalog))
	invalid_catalog_backup.close()
	assert(content_editor_script.read_catalog(stale_catalog_path) is Dictionary)
	assert(FileAccess.file_exists(stale_catalog_path + ".bak"))
	for suffix in ["", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(stale_catalog_path + suffix))
	var off_target_campaign: Dictionary = seeded_catalog.duplicate(true)
	off_target_campaign.categories.stages[0].references.append("wave.s2.supply.3")
	assert(ContentValidator.validate(off_target_campaign).is_empty())
	assert(ContentValidator.warnings(off_target_campaign).size() == 1 and ContentValidator.warnings(off_target_campaign)[0].contains("27 waves"))
	var editor_save_path := "user://content_editor_save_test.json"
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(editor_save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(editor_save_path + suffix))
	var initial_editor_catalog := FileAccess.open(editor_save_path, FileAccess.WRITE)
	assert(initial_editor_catalog != null)
	initial_editor_catalog.store_string(JSON.stringify(seeded_catalog, "\t"))
	initial_editor_catalog.close()
	var catalog_before_rejected_edit := FileAccess.get_file_as_string(editor_save_path)
	var invalid_wave: Dictionary = seeded_catalog.categories.waves[0].duplicate(true)
	invalid_wave.enemy_id = "enemy.missing"
	var rejected_editor_save: Dictionary = content_editor_script.save_catalog_record(editor_save_path, "waves", invalid_wave.id, invalid_wave)
	assert(not rejected_editor_save.saved and not rejected_editor_save.errors.is_empty())
	assert(FileAccess.get_file_as_string(editor_save_path) == catalog_before_rejected_edit)
	var renamed_wave: Dictionary = seeded_catalog.categories.waves[0].duplicate(true)
	renamed_wave.id = "wave.renamed"
	var rejected_rename: Dictionary = content_editor_script.save_catalog_record(editor_save_path, "waves", seeded_catalog.categories.waves[0].id, renamed_wave)
	assert(not rejected_rename.saved and rejected_rename.get("errors", []).is_empty())
	assert(FileAccess.get_file_as_string(editor_save_path) == catalog_before_rejected_edit)
	var warned_stage: Dictionary = off_target_campaign.categories.stages[0]
	var warning_editor_save: Dictionary = content_editor_script.save_catalog_record(editor_save_path, "stages", warned_stage.id, warned_stage)
	assert(warning_editor_save.saved and warning_editor_save.warnings.size() == 1)
	assert(content_editor_script.read_catalog(editor_save_path).categories.stages[0].references.has("wave.s2.supply.3"))
	assert(not FileAccess.file_exists(editor_save_path + ".tmp") and not FileAccess.file_exists(editor_save_path + ".bak"))
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(editor_save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(editor_save_path + suffix))
	assert(seeded_catalog.categories.evolutions.size() == 6)
	for evolution in seeded_catalog.categories.evolutions:
		assert(evolution.references.has("unit.%s" % evolution.unit_kind))
		assert(evolution.required_upgrades.size() > 0 and evolution.special_skill.has("mode"))
	var invalid_evolution_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_evolution_catalog.categories.evolutions[0].required_upgrades = {"upgrade.mage.chain": 1}
	assert(ContentValidator.validate(invalid_evolution_catalog).any(func(error): return error == "evolution.spearman.guardian.required_upgrades: invalid evolution requirements"))
	invalid_evolution_catalog = seeded_catalog.duplicate(true)
	invalid_evolution_catalog.categories.evolutions[0].special_skill.cooldown = 0
	assert(ContentValidator.validate(invalid_evolution_catalog).any(func(error): return error == "evolution.spearman.guardian.special_skill.mode|effect|cooldown|cost|value|radius|label: invalid evolution special skill"))
	invalid_evolution_catalog = seeded_catalog.duplicate(true)
	invalid_evolution_catalog.categories.evolutions[0].special_skill = []
	assert(ContentValidator.validate(invalid_evolution_catalog).any(func(error): return error.begins_with("evolution.spearman.guardian.special_skill.mode|effect|cooldown|cost|value|radius|label:")))
	invalid_evolution_catalog = seeded_catalog.duplicate(true)
	invalid_evolution_catalog.categories.evolutions[0].combat_cost = 0
	assert(ContentValidator.validate(invalid_evolution_catalog).any(func(error): return error == "evolution.spearman.guardian.unit_kind|label|total_upgrade_levels|combat_cost: invalid evolution data"))
	invalid_evolution_catalog = seeded_catalog.duplicate(true)
	invalid_evolution_catalog.categories.evolutions.pop_back()
	assert(ContentValidator.validate(invalid_evolution_catalog).has("evolutions: evolutions must contain exactly six forms"))
	var invalid_evolution_research: Dictionary = seeded_catalog.duplicate(true)
	invalid_evolution_research.categories.research[5].evolution_id = "evolution.missing"
	assert(ContentValidator.validate(invalid_evolution_research).any(func(error): return error == "research.evolution.swordsman.knight.evolution_id|unit_kind: has invalid evolution unlock data"))
	invalid_evolution_research = seeded_catalog.duplicate(true)
	invalid_evolution_research.categories.research.remove_at(5)
	assert(ContentValidator.validate(invalid_evolution_research).any(func(error): return error == "evolution.swordsman.knight.research: must have exactly one permanent unlock research"))
	assert(ContentValidator.content_id_from_error("stage.m1.frontier has invalid core data", seeded_catalog) == "stage.m1.frontier")
	assert(ContentValidator.content_id_from_error("campaign must have six main stages", seeded_catalog).is_empty())
	assert(ContentValidator.content_id_from_error("stage.m1.frontier failed", {"categories": 1}).is_empty())
	assert(ContentValidator.with_field_path("stage.m1.frontier blocks a required wave route", seeded_catalog) == "stage.m1.frontier.blocked_cells|walls|core_cell|waves: blocks a required wave route")
	var invalid_research_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_research_catalog.categories.research[0].amount = 0
	assert(ContentValidator.validate(invalid_research_catalog).any(func(error): return error == "research.swordsman.damage.amount: has invalid permanent research data"))
	var invalid_obstacle_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_obstacle_catalog.categories.obstacles[0].cost = "20"
	assert(ContentValidator.validate(invalid_obstacle_catalog).any(func(error): return error == "obstacle.barricade.cost: invalid obstacle data"))
	var invalid_movement_type_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_movement_type_catalog.categories.units[0].movement_type = "air"
	assert(ContentValidator.validate(invalid_movement_type_catalog).any(func(error): return error == "unit.swordsman.movement_type: unsupported movement type"))
	var invalid_obstacle_movement_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_obstacle_movement_catalog.categories.obstacles[0].blocked_movement_types = ["air"]
	assert(ContentValidator.validate(invalid_obstacle_movement_catalog).any(func(error): return error == "obstacle.barricade.blocked_movement_types: invalid obstacle movement types"))
	var invalid_obstacle_limits: Dictionary = seeded_catalog.duplicate(true)
	invalid_obstacle_limits.categories.stages.filter(func(stage): return stage.id == "stage.m2.crossroads")[0].obstacle_max_owned = "3"
	assert(ContentValidator.validate(invalid_obstacle_limits).any(func(error): return error.begins_with("stage.m2.crossroads.obstacle_max_owned|obstacle_max_placed|references:")))
	for malformed_field in ["damage", "heal", "splash_radius", "range", "attack_time"]:
		var malformed_facility_catalog: Dictionary = seeded_catalog.duplicate(true)
		malformed_facility_catalog.categories.facilities[0][malformed_field] = "invalid"
		var malformed_facility_errors := ContentValidator.validate(malformed_facility_catalog)
		assert(malformed_facility_errors.any(func(error): return error.begins_with("facility.arrow_tower.%s:" % malformed_field)))
	assert(seeded_catalog.categories.units.filter(func(unit): return unit.team == "ally").size() == 5)
	assert(seeded_catalog.categories.units.filter(func(unit): return unit.team == "enemy").size() == 6)
	var story_rosters := {"stage.m1.frontier": ["swordsman", "archer"], "stage.m2.crossroads": ["swordsman", "archer", "spearman"], "stage.m3.fortress": ["swordsman", "archer", "spearman"], "stage.m4.forest": ["swordsman", "archer", "spearman", "support"], "stage.m5.citadel": ["swordsman", "archer", "spearman", "support", "mage"]}
	for stage_id in story_rosters:
		var roster_stage: Dictionary = seeded_catalog.categories.stages.filter(func(stage): return stage.id == stage_id)[0]
		assert(roster_stage.available_units == story_rosters[stage_id])
	var roster_deploy_test := BattleModel.new()
	roster_deploy_test.combat_gold = 1000
	var ally_kinds := ["swordsman", "archer", "spearman", "support", "mage"]
	assert(not roster_deploy_test.deploy("spearman", Vector2i(0, 8)))
	var locked_unit_snapshot_test := BattleModel.new()
	locked_unit_snapshot_test.stage.available_units = ["swordsman", "archer", "spearman"]
	locked_unit_snapshot_test.combat_gold = 500
	assert(locked_unit_snapshot_test.deploy("spearman", Vector2i(1, 8)))
	var locked_snapshot := locked_unit_snapshot_test.to_dict()
	assert(not BattleModel.new().restore(locked_snapshot))
	roster_deploy_test.stage.available_units = ally_kinds
	for index in ally_kinds.size():
		assert(roster_deploy_test.deploy(ally_kinds[index], Vector2i(index, 8)))
	assert(roster_deploy_test.units.size() == 5 and roster_deploy_test.combat_gold == 660)
	assert(seeded_catalog.categories.upgrades.size() == 20)
	assert(seeded_catalog.categories.skills.size() == 10)
	var incomplete_campaign: Dictionary = seeded_catalog.duplicate(true)
	incomplete_campaign.categories.stages.erase(incomplete_campaign.categories.stages.filter(func(stage): return stage.get("id") == "stage.s2.supply")[0])
	assert(ContentValidator.validate(incomplete_campaign).any(func(error): return error.contains("six main stages and two optional stages")))
	var campaign_stages: Array = seeded_catalog.categories.stages.filter(func(stage): return stage.get("campaign_kind", "") in ["main", "optional"])
	assert(campaign_stages.size() == 8)
	for campaign_stage in campaign_stages:
		var stage_smoke := BattleModel.new(campaign_stage.id)
		assert(not stage_smoke.stage.is_empty() and not stage_smoke.waves.is_empty())
		assert(stage_smoke.preview_enemies.size() == int(stage_smoke.waves[0].count))
		var stage_checkpoint := CheckpointStore.new("user://campaign_smoke_%s.json" % campaign_stage.id.replace(".", "_"))
		stage_smoke.combat_gold = 500
		assert(stage_smoke.deploy("swordsman", Vector2i(1, 8)))
		for wave_index in stage_smoke.waves.size():
			assert(stage_smoke.start_wave(stage_checkpoint))
			for enemy in stage_smoke.enemies:
				enemy.alive = false
			stage_smoke.pending_reinforcements.clear()
			if stage_smoke.stage.mode == "siege" and stage_smoke.wave == stage_smoke.waves.size():
				stage_smoke.core_hp = 0.0
			stage_smoke.tick(0.1)
			assert(stage_smoke.phase == ("finished" if wave_index == stage_smoke.waves.size() - 1 else "preparation"))
		stage_checkpoint.clear_checkpoint()
	var skill_test := BattleModel.new()
	skill_test.stage.available_units = ["swordsman", "archer"]
	skill_test.combat_gold = 100
	assert(skill_test.deploy("swordsman", Vector2i(2, 8)))
	skill_test.phase = "combat"
	assert(not skill_test.cast_skill(skill_test.units[0].id, "skill.swordsman.heroic_charge"))
	assert(skill_test.combat_gold == 50)
	skill_test.enemies.append({"id": 89, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 7), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 100.0, "alive": true, "active": true, "statuses": {}})
	assert(skill_test.cast_skill(skill_test.units[0].id, "skill.swordsman.heroic_charge"))
	assert(skill_test.combat_gold == 30 and skill_test.enemies[0].hp == 75.0)
	assert(not skill_test.cast_skill(skill_test.units[0].id, "skill.swordsman.heroic_charge"))
	assert(skill_test.units[0].skill_cooldowns["skill.swordsman.heroic_charge"] == 15.0)
	var skill_checkpoint_model := BattleModel.new()
	skill_checkpoint_model.stage.available_units = ["swordsman", "archer"]
	skill_checkpoint_model.combat_gold = 100
	assert(skill_checkpoint_model.deploy("swordsman", Vector2i(2, 8)))
	skill_checkpoint_model.units[0].skill_cooldowns["skill.swordsman.heroic_charge"] = 4.0
	var skill_snapshot := skill_checkpoint_model.to_dict()
	var skill_restore := BattleModel.new()
	assert(skill_restore.restore(skill_snapshot))
	assert(skill_restore.units[0].skill_cooldowns["skill.swordsman.heroic_charge"] == 4.0)
	var legacy_skill_snapshot: Dictionary = skill_snapshot.duplicate(true)
	legacy_skill_snapshot.erase("run_id")
	var legacy_checkpoint_restore := BattleModel.new()
	assert(legacy_checkpoint_restore.restore(legacy_skill_snapshot) and not legacy_checkpoint_restore.run_id.is_empty())
	var invalid_skill_snapshot: Dictionary = skill_snapshot.duplicate(true)
	invalid_skill_snapshot.units[0].skill_cooldowns["skill.swordsman.heroic_charge"] = 99.0
	assert(not BattleModel.new().restore(invalid_skill_snapshot))
	var auto_skill_test := BattleModel.new()
	auto_skill_test.stage.available_units = ["swordsman", "archer"]
	assert(auto_skill_test.deploy("swordsman", Vector2i(2, 8)))
	auto_skill_test.enemies.append({"id": 88, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 7), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 100.0, "alive": true, "active": true, "statuses": {}})
	auto_skill_test.phase = "combat"
	auto_skill_test.tick(0.1)
	assert(auto_skill_test.units[0].skill_cooldowns["skill.swordsman.rend"] == 8.0)
	auto_skill_test.phase = "preparation"
	auto_skill_test.tick(1.0)
	assert(auto_skill_test.units[0].skill_cooldowns["skill.swordsman.rend"] == 8.0)
	var upgrade_test := BattleModel.new()
	upgrade_test.combat_gold = 1000
	assert(upgrade_test.deploy("swordsman", Vector2i(1, 8)))
	assert(not upgrade_test.purchase_upgrade(upgrade_test.units[0].id, "upgrade.archer.pierce"))
	assert(upgrade_test.purchase_upgrade(upgrade_test.units[0].id, "upgrade.swordsman.charge"))
	assert(upgrade_test.units[0].damage == 25.0 and upgrade_test.combat_gold == 920)
	assert(upgrade_test.purchase_upgrade(upgrade_test.units[0].id, "upgrade.swordsman.charge"))
	var upgraded_snapshot := upgrade_test.to_dict()
	var upgraded_restore := BattleModel.new()
	assert(upgraded_restore.restore(upgraded_snapshot))
	assert(upgraded_restore.units[0].upgrades["upgrade.swordsman.charge"] == 2 and upgraded_restore.units[0].damage == 28.0)
	assert(upgraded_restore.purchase_upgrade(upgraded_restore.units[0].id, "upgrade.swordsman.charge"))
	assert(not upgraded_restore.purchase_upgrade(upgraded_restore.units[0].id, "upgrade.swordsman.charge"))
	var combo_bleed_test := BattleModel.new()
	combo_bleed_test.combat_gold = 500
	assert(combo_bleed_test.deploy("swordsman", Vector2i(2, 8)))
	assert(combo_bleed_test.purchase_upgrade(combo_bleed_test.units[0].id, "upgrade.swordsman.combo"))
	assert(combo_bleed_test.purchase_upgrade(combo_bleed_test.units[0].id, "upgrade.swordsman.bleed"))
	combo_bleed_test.enemies.append({"id": 90, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 7), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	combo_bleed_test._strike(combo_bleed_test.units[0], combo_bleed_test.enemies[0])
	assert(combo_bleed_test.enemies[0].hp == 60.0 and combo_bleed_test.enemies[0].statuses.has("bleed"))
	assert(combo_bleed_test.enemies[0].statuses.bleed.stacks.size() == 2)
	combo_bleed_test._tick_statuses(combo_bleed_test.enemies[0], 0.5)
	assert(combo_bleed_test.enemies[0].hp == 58.0)
	combo_bleed_test.units[0].cooldown = 0.0
	combo_bleed_test._strike(combo_bleed_test.units[0], combo_bleed_test.enemies[0])
	assert(combo_bleed_test.enemies[0].statuses.bleed.stacks.size() == 3)
	var freeze_test := BattleModel.new()
	freeze_test.combat_gold = 500
	assert(freeze_test.deploy("archer", Vector2i(2, 8)))
	assert(freeze_test.purchase_upgrade(freeze_test.units[0].id, "upgrade.archer.freeze"))
	freeze_test.enemies.append({"id": 91, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 7), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	freeze_test._strike(freeze_test.units[0], freeze_test.enemies[0])
	assert(freeze_test.enemies[0].statuses.freeze.remaining == 0.5)
	freeze_test._add_status(freeze_test.enemies[0], "freeze", 0.2, 0.0)
	assert(freeze_test.enemies[0].statuses.freeze.remaining == 0.2)
	var status_damage_test := BattleModel.new()
	var status_target := {"id": 93, "kind": "goblin", "team": "enemy", "hp": 100.0, "damage_reduction": 0.5, "shield": 8.0, "alive": true, "statuses": {"bleed": {"stacks": [{"remaining": 1.0, "damage": 10.0}]}, "burn": {"stacks": [{"remaining": 1.0, "damage": 20.0}]}}}
	status_damage_test._tick_statuses(status_target, 0.5)
	assert(status_target.hp == 96.5 and status_target.shield == 0.0)
	var incapacitation_test := BattleModel.new()
	incapacitation_test.combat_gold = 500
	assert(incapacitation_test.deploy("swordsman", Vector2i(1, 8)))
	var incapacitated_unit: Dictionary = incapacitation_test.units[0]
	incapacitation_test._add_status(incapacitated_unit, "freeze", 0.5, 0.0)
	incapacitation_test._add_status(incapacitated_unit, "stun", 0.8, 0.0)
	incapacitation_test.enemies.append({"id": 94, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 8), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 100.0, "alive": true, "active": true, "statuses": {}})
	incapacitation_test.phase = "combat"
	var incapacitated_gold := incapacitation_test.combat_gold
	assert(incapacitation_test._incapacitated_remaining(incapacitated_unit) == 0.8)
	assert(not incapacitation_test.move_unit(incapacitated_unit.id, Vector2i(1, 7)))
	assert(not incapacitation_test.cast_skill(incapacitated_unit.id, "skill.swordsman.heroic_charge"))
	assert(incapacitation_test.combat_gold == incapacitated_gold and not incapacitated_unit.skill_cooldowns.has("skill.swordsman.heroic_charge"))
	incapacitation_test._add_status(incapacitated_unit, "freeze", 0.2, 0.0)
	assert(incapacitation_test._incapacitated_remaining(incapacitated_unit) == 0.8)
	incapacitation_test.tick(0.2)
	assert(incapacitation_test._is_incapacitated(incapacitated_unit) and incapacitation_test.enemies[0].hp == 100.0)
	incapacitation_test.tick(0.6)
	assert(not incapacitation_test._is_incapacitated(incapacitated_unit) and incapacitation_test.enemies[0].hp < 100.0)
	assert(incapacitation_test.cast_skill(incapacitated_unit.id, "skill.swordsman.heroic_charge"))
	var defense_test := BattleModel.new()
	defense_test.combat_gold = 500
	defense_test.stage.available_units = ["swordsman", "archer", "spearman"]
	assert(defense_test.deploy("spearman", Vector2i(1, 8)))
	assert(defense_test.purchase_upgrade(defense_test.units[0].id, "upgrade.spearman.shield"))
	defense_test._apply_damage({"kind": "goblin", "damage": 20.0}, defense_test.units[0])
	assert(defense_test.units[0].hp == 163.0)
	var support_upgrade_test := BattleModel.new()
	support_upgrade_test.combat_gold = 1000
	support_upgrade_test.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	assert(support_upgrade_test.deploy("swordsman", Vector2i(1, 8)) and support_upgrade_test.deploy("archer", Vector2i(1, 7)) and support_upgrade_test.deploy("support", Vector2i(2, 8)))
	assert(support_upgrade_test.purchase_upgrade(support_upgrade_test.units[2].id, "upgrade.support.heal_area"))
	assert(support_upgrade_test.purchase_upgrade(support_upgrade_test.units[2].id, "upgrade.support.shield"))
	assert(support_upgrade_test.purchase_upgrade(support_upgrade_test.units[2].id, "upgrade.support.attack"))
	assert(support_upgrade_test.purchase_upgrade(support_upgrade_test.units[2].id, "upgrade.support.cleanse"))
	support_upgrade_test.units[0].hp = 60.0
	support_upgrade_test.units[1].hp = 40.0
	support_upgrade_test.units[1].statuses.freeze = {"remaining": 1.0, "damage": 0.0}
	support_upgrade_test.units[2].skill_cooldowns["skill.support.mend"] = 10.0
	support_upgrade_test.enemies.append({"id": 92, "kind": "goblin", "team": "enemy", "cell": Vector2i(7, 0), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 100.0, "alive": true, "active": false, "statuses": {}})
	support_upgrade_test.phase = "combat"
	support_upgrade_test.tick(0.2)
	assert(support_upgrade_test.units[0].hp == 68.0 and support_upgrade_test.units[1].hp == 48.0)
	assert(support_upgrade_test.units[0].shield == 10.0 and support_upgrade_test.units[1].shield == 10.0 and not support_upgrade_test.units[1].statuses.has("freeze"))
	assert(support_upgrade_test.units[1].statuses.attack_buff.value == 0.1)
	for upgrade in seeded_catalog.categories.upgrades:
		var every_upgrade_test := BattleModel.new()
		every_upgrade_test.stage.available_units = [upgrade.unit_kind]
		every_upgrade_test.combat_gold = 10000
		assert(every_upgrade_test.deploy(upgrade.unit_kind, Vector2i(1, 8)))
		for level in 3:
			assert(every_upgrade_test.purchase_upgrade(every_upgrade_test.units[0].id, upgrade.id))
		assert(every_upgrade_test.units[0].upgrades[upgrade.id] == 3 and not every_upgrade_test.purchase_upgrade(every_upgrade_test.units[0].id, upgrade.id))
	var pierce_test := BattleModel.new()
	pierce_test.combat_gold = 500
	assert(pierce_test.deploy("archer", Vector2i(1, 8)))
	assert(pierce_test.purchase_upgrade(pierce_test.units[0].id, "upgrade.archer.pierce"))
	pierce_test.enemies.append({"id": 93, "kind": "goblin", "team": "enemy", "cell": Vector2i(1, 6), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	pierce_test.enemies.append({"id": 94, "kind": "goblin", "team": "enemy", "cell": Vector2i(1, 4), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	pierce_test._strike(pierce_test.units[0], pierce_test.enemies[0])
	assert(pierce_test.enemies[0].hp == 85.0 and pierce_test.enemies[1].hp == 85.0)
	var spear_control_test := BattleModel.new()
	spear_control_test.combat_gold = 500
	spear_control_test.stage.available_units = ["swordsman", "archer", "spearman"]
	assert(spear_control_test.deploy("spearman", Vector2i(1, 8)))
	assert(spear_control_test.purchase_upgrade(spear_control_test.units[0].id, "upgrade.spearman.pushback"))
	assert(spear_control_test.purchase_upgrade(spear_control_test.units[0].id, "upgrade.spearman.counter"))
	spear_control_test.enemies.append({"id": 95, "kind": "goblin", "team": "enemy", "cell": Vector2i(1, 7), "hp": 100.0, "damage": 20.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	spear_control_test._strike(spear_control_test.units[0], spear_control_test.enemies[0])
	assert(spear_control_test.enemies[0].cell == Vector2i(1, 6))
	spear_control_test._apply_damage(spear_control_test.enemies[0], spear_control_test.units[0])
	assert(spear_control_test.enemies[0].hp == 81.0)
	var taunt_test := BattleModel.new("stage.m2.siege")
	taunt_test.stage.available_units = ["swordsman", "archer", "spearman"]
	taunt_test.combat_gold = 1000
	assert(taunt_test.deploy("spearman", Vector2i(1, 8)) and taunt_test.deploy("swordsman", Vector2i(3, 8)))
	for _rank in 3:
		assert(taunt_test.purchase_upgrade(taunt_test.units[0].id, "upgrade.spearman.taunt"))
	var taunt_enemy := {"id": 96, "kind": "goblin", "team": "enemy", "cell": Vector2i(3, 7), "hp": 100.0, "damage": 5.0, "range": 3, "cooldown": 0.0, "alive": true, "active": true, "ai_weights": {"attack": 1.2, "objective": 1.0}}
	assert(taunt_test._choose_enemy_action(taunt_enemy).target_index == 0)
	var mage_upgrade_test := BattleModel.new()
	mage_upgrade_test.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	mage_upgrade_test.combat_gold = 1000
	assert(mage_upgrade_test.deploy("mage", Vector2i(3, 8)))
	assert(mage_upgrade_test.purchase_upgrade(mage_upgrade_test.units[0].id, "upgrade.mage.area"))
	assert(mage_upgrade_test.purchase_upgrade(mage_upgrade_test.units[0].id, "upgrade.mage.area"))
	assert(mage_upgrade_test.purchase_upgrade(mage_upgrade_test.units[0].id, "upgrade.mage.burst"))
	assert(mage_upgrade_test.units[0].splash_radius == 2)
	mage_upgrade_test.units[0].attack_count = 2
	mage_upgrade_test.enemies.append({"id": 97, "kind": "goblin", "team": "enemy", "cell": Vector2i(3, 7), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	mage_upgrade_test._strike(mage_upgrade_test.units[0], mage_upgrade_test.enemies[0])
	assert(mage_upgrade_test.enemies[0].hp == 70.0)
	assert(mage_upgrade_test.purchase_upgrade(mage_upgrade_test.units[0].id, "upgrade.mage.chain"))
	mage_upgrade_test.enemies.append({"id": 98, "kind": "goblin", "team": "enemy", "cell": Vector2i(3, 4), "hp": 100.0, "damage": 1.0, "range": 1, "cooldown": 10.0, "alive": true, "active": true, "statuses": {}})
	mage_upgrade_test.units[0].cooldown = 0.0
	mage_upgrade_test._strike_area(mage_upgrade_test.units[0], mage_upgrade_test.enemies, mage_upgrade_test.enemies[0].cell, mage_upgrade_test.units[0].splash_radius)
	assert(mage_upgrade_test.enemies[0].hp == 45.0 and mage_upgrade_test.enemies[1].hp == 75.0)
	var invalid_upgrade_checkpoint: Dictionary = upgraded_snapshot.duplicate(true)
	invalid_upgrade_checkpoint.units[0].upgrades["upgrade.swordsman.charge"] = 4
	assert(not BattleModel.new().restore(invalid_upgrade_checkpoint))
	var invalid_upgrade: Dictionary = seeded_catalog.duplicate(true)
	invalid_upgrade.categories.upgrades.pop_back()
	assert(ContentValidator.validate(invalid_upgrade).any(func(error): return error.contains("exactly four combat upgrades")))
	var invalid_support_unit: Dictionary = seeded_catalog.duplicate(true)
	invalid_support_unit.categories.units[3].heal_range = 0
	assert(ContentValidator.validate(invalid_support_unit).any(func(error): return error.contains("invalid unit healing data")))
	var invalid_available_unit: Dictionary = seeded_catalog.duplicate(true)
	invalid_available_unit.categories.stages[0].available_units.append("support")
	assert(ContentValidator.validate(invalid_available_unit).any(func(error): return error.contains("invalid available unit: support")))
	invalid_available_unit.categories.stages[0].references = "malformed"
	assert(not ContentValidator.validate(invalid_available_unit).is_empty())
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
	var invalid_splash_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_splash_catalog.categories.facilities[1].damage = 0
	assert(ContentValidator.validate(invalid_splash_catalog).any(func(error): return error.contains("invalid facility splash data")))
	var invalid_healer_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_healer_catalog.categories.facilities[2].range = 0
	assert(ContentValidator.validate(invalid_healer_catalog).any(func(error): return error.contains("invalid facility healing data")))
	var invalid_enemy_facility_catalog: Dictionary = seeded_catalog.duplicate(true)
	invalid_enemy_facility_catalog.categories.waves[2].enemy_facilities[0].facility_id = "facility.arrow_tower"
	assert(ContentValidator.validate(invalid_enemy_facility_catalog).any(func(error): return error.contains("invalid enemy facility placement")))
	invalid_enemy_facility_catalog = seeded_catalog.duplicate(true)
	invalid_enemy_facility_catalog.categories.waves[2].enemy_facilities[0].cell = [8, 1]
	assert(ContentValidator.validate(invalid_enemy_facility_catalog).any(func(error): return error.contains("invalid enemy facility placement")))
	invalid_enemy_facility_catalog = seeded_catalog.duplicate(true)
	invalid_enemy_facility_catalog.categories.waves[2].enemy_facilities[0].cell = [2, 2]
	assert(ContentValidator.validate(invalid_enemy_facility_catalog).any(func(error): return error.contains("conflicts with initial spawn")))
	invalid_enemy_facility_catalog = seeded_catalog.duplicate(true)
	invalid_enemy_facility_catalog.categories.waves[2].references.erase("facility.enemy_watchtower")
	assert(ContentValidator.validate(invalid_enemy_facility_catalog).any(func(error): return error.contains("enemy facility must be referenced")))
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
	assert(ProjectVersions.CONTENT_VERSION == 1 and ProjectVersions.SCHEMA_VERSION == 1 and ProjectVersions.SAVE_VERSION == 2)
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
	var obstacle_test := BattleModel.new("stage.m2.crossroads")
	assert(obstacle_test.install_obstacle("obstacle.barricade", Vector2i(3, 6)))
	assert(obstacle_test.install_obstacle("obstacle.barricade", Vector2i(1, 1)))
	assert(obstacle_test.combat_gold == 150 and not obstacle_test.install_obstacle("obstacle.barricade", Vector2i(7, 8)))
	assert(not obstacle_test.deploy("swordsman", Vector2i(3, 6)) and obstacle_test.combat_gold == 150)
	var obstacle_route_enemy := {"id": 900, "cell": Vector2i(3, 7)}
	assert(not obstacle_test._find_path(obstacle_route_enemy, obstacle_test.core_cell).has(Vector2i(3, 6)))
	var obstacle_instance_id: int = obstacle_test.obstacles[0].id
	assert(obstacle_test.store_obstacle(obstacle_instance_id) and obstacle_test.combat_gold == 150)
	assert(obstacle_test.place_stored_obstacle(obstacle_instance_id, Vector2i(3, 7)) and obstacle_test.combat_gold == 150)
	assert(obstacle_test.store_obstacle(int(obstacle_test.obstacles[1].id)))
	obstacle_test.phase = "combat"
	assert(not obstacle_test.move_obstacle(obstacle_instance_id, Vector2i(3, 7)))
	assert(not obstacle_test.store_obstacle(int(obstacle_test.obstacles[1].id)))
	assert(obstacle_test.install_obstacle("obstacle.barricade", Vector2i(6, 8)) and obstacle_test.combat_gold == 130)
	assert(not obstacle_test.install_obstacle("obstacle.barricade", Vector2i(7, 8)))
	obstacle_test.phase = "preparation"
	var obstacle_snapshot := obstacle_test.to_dict()
	var obstacle_restore := BattleModel.new("stage.m2.crossroads")
	assert(obstacle_restore.restore(obstacle_snapshot) and obstacle_restore.obstacles.size() == 3)
	assert(obstacle_restore.obstacles[0].cell == Vector2i(3, 7) and obstacle_restore.obstacles[0].placed and not obstacle_restore.obstacles[1].placed and obstacle_restore.combat_gold == 130)
	var obstacle_route_test := BattleModel.new("stage.m2.crossroads")
	obstacle_route_test.blocked_cells.clear()
	for x in BattleModel.COLUMNS:
		if x != 3:
			obstacle_route_test.blocked_cells[Vector2i(x, 5)] = true
	var route_gold_before := obstacle_route_test.combat_gold
	assert(not obstacle_route_test.install_obstacle("obstacle.barricade", Vector2i(3, 5)))
	assert(obstacle_route_test.combat_gold == route_gold_before and obstacle_route_test.obstacles.is_empty())
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
	var support_unit_test := BattleModel.new()
	support_unit_test.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	assert(support_unit_test.deploy("swordsman", Vector2i(1, 8)) and support_unit_test.deploy("support", Vector2i(2, 8)))
	support_unit_test.units[0].hp = 60.0
	support_unit_test.units[1].skill_cooldowns["skill.support.mend"] = 10.0
	support_unit_test.phase = "combat"
	support_unit_test.enemies.append({"id": 40, "kind": "goblin", "cell": Vector2i.ZERO, "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	support_unit_test.tick(0.2)
	assert(support_unit_test.units[0].hp == 68.0 and support_unit_test.units[1].cooldown == 1.5)
	support_unit_test.phase = "preparation"
	var support_unit_restore := BattleModel.new()
	support_unit_restore.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	assert(support_unit_restore.restore(support_unit_test.to_dict()) and support_unit_restore.units[1].heal == 8 and support_unit_restore.units[1].heal_range == 3)
	var mage_unit_test := BattleModel.new()
	mage_unit_test.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	assert(mage_unit_test.deploy("mage", Vector2i(4, 8)))
	mage_unit_test.units[0].skill_cooldowns["skill.mage.arcane_bolt"] = 10.0
	mage_unit_test.phase = "combat"
	mage_unit_test.enemies.append({"id": 41, "kind": "goblin", "cell": Vector2i(4, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	mage_unit_test.enemies.append({"id": 42, "kind": "goblin", "cell": Vector2i(5, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	mage_unit_test.enemies.append({"id": 43, "kind": "goblin", "cell": Vector2i(7, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	mage_unit_test.tick(0.2)
	assert(mage_unit_test.enemies[0].hp == 40.0 and mage_unit_test.enemies[1].hp == 40.0 and mage_unit_test.enemies[2].hp == 65.0)
	mage_unit_test.phase = "preparation"
	var mage_unit_restore := BattleModel.new()
	mage_unit_restore.stage.available_units = ["swordsman", "archer", "spearman", "support", "mage"]
	assert(mage_unit_restore.restore(mage_unit_test.to_dict()) and mage_unit_restore.units[0].splash_radius == 1)
	var enemy_support_test := BattleModel.new()
	enemy_support_test.phase = "combat"
	enemy_support_test.enemies.append({"id": 44, "kind": "enemy_support", "team": "enemy", "cell": Vector2i(1, 1), "hp": 90.0, "damage": 5.0, "range": 1, "heal": 10.0, "heal_range": 3, "cooldown": 0.0, "active": true, "alive": true})
	enemy_support_test.enemies.append({"id": 45, "kind": "goblin", "team": "enemy", "cell": Vector2i(2, 1), "hp": 20.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "active": true, "alive": true})
	enemy_support_test.tick(0.2)
	assert(enemy_support_test.enemies[1].hp == 30.0 and enemy_support_test.enemies[0].cooldown == 1.5)
	var non_goblin_reward := BattleModel.new()
	var orc_target: Dictionary = {"kind": "orc_warrior", "team": "enemy", "hp": 10.0, "alive": true}
	non_goblin_reward._strike({"kind": "swordsman", "damage": 20.0, "cooldown": 0.0, "attack_time": 1.0}, orc_target)
	assert(not orc_target.alive and non_goblin_reward.combat_gold == non_goblin_reward.stage.start_resource + non_goblin_reward.stage.kill_reward)
	var magic_splash_test := BattleModel.new()
	magic_splash_test.phase = "combat"
	assert(magic_splash_test.build_facility("facility.magic_tower", Vector2i(1, 8)))
	magic_splash_test.enemies.append({"id": 50, "kind": "goblin", "cell": Vector2i(1, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	magic_splash_test.enemies.append({"id": 51, "kind": "goblin", "cell": Vector2i(2, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	magic_splash_test.enemies.append({"id": 52, "kind": "goblin", "cell": Vector2i(4, 7), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 100.0, "alive": true})
	magic_splash_test.tick(0.2)
	assert(magic_splash_test.enemies[0].hp == 40.0 and magic_splash_test.enemies[1].hp == 40.0 and magic_splash_test.enemies[2].hp == 65.0)
	magic_splash_test.phase = "preparation"
	var magic_splash_restore := BattleModel.new()
	assert(magic_splash_restore.restore(magic_splash_test.to_dict()) and magic_splash_restore.facilities[0].splash_radius == 1)
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
	var repair_target: Dictionary = facility_targeting.facilities.back()
	repair_target.hp -= 40.0
	facility_targeting.phase = "combat"
	facility_targeting.combat_gold = 40
	var repair_gold := facility_targeting.combat_gold
	assert(facility_targeting.facility_repair_cost(repair_target.id) == 8)
	assert(facility_targeting.repair_facility(repair_target.id))
	assert(repair_target.hp == facility_targeting.facility_definitions[repair_target.facility_id].hp and facility_targeting.combat_gold == repair_gold - 8)
	assert(not facility_targeting.repair_facility(repair_target.id))
	facility_targeting.phase = "preparation"
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
	battle.pending_reinforcements.clear()
	battle.tick(0.2)
	assert(battle.phase == "finished" and battle.battle_result == "victory")
	assert(battle.rewarded_waves == [1, 2])
	var core_test := BattleModel.new()
	core_test.core_hp = 5.0
	core_test.phase = "combat"
	core_test.enemies.append({"id": 99, "kind": "goblin", "cell": Vector2i(4, 8), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "alive": true})
	core_test.tick(0.2)
	assert(core_test.phase == "finished" and core_test.battle_result == "defeat")
	var defense_no_allies_test := BattleModel.new()
	defense_no_allies_test.phase = "combat"
	defense_no_allies_test.core_hp = 300.0
	defense_no_allies_test.enemies.append({"id": 100, "kind": "goblin", "cell": Vector2i(4, 8), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "alive": true})
	defense_no_allies_test.tick(0.2)
	assert(defense_no_allies_test.units.is_empty() and defense_no_allies_test.core_hp > 0.0 and defense_no_allies_test.phase == "combat")
	defense_no_allies_test.enemies[0].alive = false
	defense_no_allies_test.tick(0.2)
	assert(defense_no_allies_test.phase == "preparation" and defense_no_allies_test.battle_result.is_empty())
	var siege_test := BattleModel.new("stage.m2.siege")
	assert(siege_test.stage.mode == "siege" and siege_test.core_cell == Vector2i(4, 0))
	var enemy_facility_test := BattleModel.new("stage.m2.siege")
	assert(enemy_facility_test.enemy_facilities.size() == 1 and not enemy_facility_test.enemy_facilities[0].active)
	assert(enemy_facility_test.preview_enemies.size() == 2 and not enemy_facility_test.preview_enemies[0].active and enemy_facility_test.enemies.is_empty())
	var enemy_facility_store := CheckpointStore.new("user://m2_enemy_facility_test.json")
	assert(enemy_facility_test.start_wave(enemy_facility_store) and enemy_facility_test.enemy_facilities[0].active)
	assert(enemy_facility_test.enemies.size() == 2 and enemy_facility_test.enemies.all(func(enemy: Dictionary): return enemy.active) and enemy_facility_test.preview_enemies.is_empty())
	var watchtower: Dictionary = enemy_facility_test.enemy_facilities[0]
	enemy_facility_test.units.append({"id": 400, "kind": "swordsman", "cell": Vector2i(1, 2), "hp": 120.0, "damage": 20.0, "range": 1, "cooldown": 0.0, "skill_cooldowns": {"skill.swordsman.rend": 8.0}, "alive": true})
	for enemy in enemy_facility_test.enemies:
		enemy.alive = false
	enemy_facility_test.enemies.append({"id": 401, "kind": "goblin", "cell": Vector2i(7, 2), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 0.0, "ai_weights": {"attack": 1.2, "objective": 1.0}, "alive": true})
	enemy_facility_test.tick(0.2)
	assert(watchtower.hp == 80.0 and enemy_facility_test.units[0].hp == 108.0)
	enemy_facility_test.enemies.back().alive = false
	enemy_facility_test.tick(0.2)
	assert(enemy_facility_test.wave == 2 and enemy_facility_test.enemy_facilities.size() == 1 and enemy_facility_test.enemy_facilities[0].kind == "mage_tower" and not enemy_facility_test.enemy_facilities[0].active)
	enemy_facility_store.clear_checkpoint()
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
	assert(siege_restore_test.preview_enemies.size() == 2 and siege_restore_test.enemy_facilities.size() == 1 and not siege_restore_test.enemy_facilities[0].active)
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
