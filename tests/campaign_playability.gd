extends SceneTree

const BattleModel = preload("res://scripts/battle_model.gd")
const CheckpointStore = preload("res://scripts/checkpoint_store.gd")
const ProgressStore = preload("res://scripts/progress_store.gd")

func _initialize() -> void:
	var file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	var catalog: Dictionary = JSON.parse_string(file.get_as_text())
	var stages: Array = catalog.categories.stages.filter(func(stage): return stage.get("campaign_kind", "") in ["main", "optional"])
	stages.sort_custom(func(a: Dictionary, b: Dictionary): return a.campaign_kind == b.campaign_kind and a.campaign_order < b.campaign_order or a.campaign_kind == "main" and b.campaign_kind == "optional")
	var progress_path := "user://campaign_playability_%s.json" % Time.get_ticks_usec()
	var progress = ProgressStore.new(progress_path)
	assert(progress.load_progress())
	for stage in stages:
		assert(stage.get("dependencies", []).all(func(id): return progress.data.completed_stages.has(id)), "%s was not unlocked by campaign progress" % stage.id)
		var model = BattleModel.new(stage.id)
		var preferred: Array[String] = ["swordsman", "archer", "spearman"]
		if stage.id == "stage.m5.citadel": preferred = ["swordsman", "archer", "mage"]
		if stage.id == "stage.s2.supply": preferred = ["swordsman", "archer", "support"]
		var cell_index := 0
		for kind in preferred:
			if stage.available_units.has(kind) and model.combat_gold >= model.balance_seed[kind].cost:
				var cell := Vector2i(2 + cell_index, 7 if stage.mode == "defense" else 8)
				if model.deploy(kind, cell): cell_index += 1
		if stage.mode == "defense" and model.combat_gold >= model.facility_definitions["facility.arrow_tower"].cost:
			model.build_facility("facility.arrow_tower", Vector2i(5, 8))
		var store = CheckpointStore.new("user://campaign_probe_%s.json" % stage.id.replace(".", "_"))
		var frames := 0
		while model.phase != "finished" and frames < 30000:
			if model.phase == "preparation":
				_deploy_reinforcements(model, preferred)
				if not model.start_wave(store): break
			if stage.mode == "siege":
				for unit in model.units:
					_issue_move_toward_target(model, unit)
			for _tick in 5000:
				if model.phase != "combat": break
				model.tick(0.2)
				frames += 1
				if stage.mode == "siege" and frames % 10 == 0:
					for unit in model.units:
						if unit.alive and not unit.has("destination") and not model.enemies.any(func(enemy): return enemy.alive and model._distance(unit.cell, enemy.cell) <= unit.range):
							_issue_move_toward_target(model, unit)
				if model.phase != "combat": break
		assert(model.phase == "finished" and model.battle_result == "victory" and model.wave == model.waves.size(), "%s did not clear every campaign wave" % stage.id)
		var reward := progress.settle_run(model.run_id, stage.id, model.battle_result, model.wave, int(stage.permanent_first_bonus), int(stage.permanent_repeat_reward), int(stage.permanent_partial_per_wave))
		assert(reward >= 0 and progress.data.completed_stages.has(stage.id), "%s did not persist campaign completion" % stage.id)
		assert(progress.settle_run(model.run_id, stage.id, model.battle_result, model.wave, int(stage.permanent_first_bonus), int(stage.permanent_repeat_reward), int(stage.permanent_partial_per_wave)) == reward, "%s reward was not idempotent" % stage.id)
		store.clear_checkpoint()
	for suffix in ["", ".tmp", ".bak"]:
		var cleanup_path: String = progress_path + suffix
		if FileAccess.file_exists(cleanup_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(cleanup_path))
	print("All 8 campaign stages won in the seeded playability simulation")
	quit(0)

func _deploy_reinforcements(model, preferred: Array[String]) -> void:
	var cells: Array[Vector2i] = []
	for y in [8, 7, 6]:
		for x in range(1, 7):
			cells.append(Vector2i(x, y))
	for kind in preferred:
		if model.units.size() >= 6: return
		for cell in cells:
			if not model._occupied(cell) and model.deploy(kind, cell): break

func _issue_move_toward_target(model, unit: Dictionary) -> void:
	var best_goal := Vector2i(-1, -1)
	var best_score := 100000
	for enemy in model.enemies:
		if not enemy.alive: continue
		for y in BattleModel.ROWS:
			for x in BattleModel.COLUMNS:
				var goal := Vector2i(x, y)
				if model._occupied(goal) or model._distance(goal, enemy.cell) > unit.range: continue
				var route: Array[Vector2i] = model._find_path(unit, goal)
				if route.is_empty() and goal != unit.cell: continue
				var score := route.size()
				if score < best_score:
					best_score = score
					best_goal = goal
	if best_goal.x >= 0 and best_goal != unit.cell:
		model.move_unit(unit.id, best_goal)
