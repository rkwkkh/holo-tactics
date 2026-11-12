extends SceneTree

func _initialize() -> void:
	root.set_meta("selected_stage_id", "stage.m1.frontier")
	root.set_meta("editor_preview", true)
	root.set_meta("editor_preview_id", "result-view-test-%s" % Time.get_ticks_usec())
	call_deferred("_run")

func _run() -> void:
	var view = load("res://scenes/battle.tscn").instantiate()
	root.add_child(view)
	await process_frame
	assert(view.speed_button.disabled and view.timer.wait_time == 0.2)
	view.editor_preview = false
	view._refresh()
	assert(view.speed_button.disabled)
	view.progress.data.completed_stages.append(view.battle.stage_id)
	view._refresh()
	assert(not view.speed_button.disabled)
	view._toggle_speed()
	assert(view.simulation_speed == 2 and view.timer.wait_time == 0.1 and view.rest_timer.wait_time == 0.5)
	view._toggle_speed()
	assert(view.simulation_speed == 1 and view.timer.wait_time == 0.2 and view.rest_timer.wait_time == 1.0)
	view.editor_preview = false
	view.battle.phase = "finished"
	view.battle.battle_result = "victory"
	view.battle.wave = view.battle.waves.size() + 1
	view.result_reward = 30
	view.progress.data.permanent_currency = 123
	view._refresh_speed_control()
	assert(view.speed_button.disabled)
	view._refresh_result_panel()
	assert(view.result_panel.visible)
	assert(view.result_title.text == "전투 승리")
	assert(view.result_details.text.contains("2 / 2 완료"))
	assert(view.result_reward_label.text.contains("영구 재화 +30") and view.result_reward_label.text.contains("123"))
	assert(not view.result_button.disabled)
	view.battle.battle_result = "safe_abort"
	view.result_reward = -1
	view._refresh_result_panel()
	assert(view.result_title.text == "안전 종료" and not view.result_button.disabled)
	assert(view.result_reward_label.text.contains("체크포인트를 보존"))
	view.battle.battle_result = "defeat"
	view.status_override = "보상 저장 실패"
	view._refresh_result_panel()
	assert(view.result_title.text == "전투 패배" and view.result_button.disabled)
	assert(view.result_reward_label.text == "보상 저장 실패")
	view.queue_free()
	await process_frame
	set_meta("selected_stage_id", "stage.m2.crossroads")
	set_meta("editor_preview", true)
	set_meta("editor_preview_id", "obstacle-view-test-%s" % Time.get_ticks_usec())
	var obstacle_view = load("res://scenes/battle.tscn").instantiate()
	root.add_child(obstacle_view)
	await process_frame
	assert(obstacle_view.obstacle_controls != null and obstacle_view.obstacle_install_buttons.size() == 1)
	obstacle_view._select_obstacle_definition("obstacle.barricade")
	obstacle_view._on_tile_pressed(Vector2i(0, 1))
	assert(obstacle_view.battle.obstacles.size() == 1)
	obstacle_view._on_tile_pressed(Vector2i(0, 1))
	obstacle_view._store_selected_obstacle()
	assert(not obstacle_view.battle.obstacles[0].placed)
	obstacle_view._select_facility("facility.arrow_tower")
	obstacle_view._select_stored_obstacle()
	assert(obstacle_view.selected_facility_id.is_empty() and obstacle_view.selected_facility_instance == -1)
	obstacle_view._on_tile_pressed(Vector2i(1, 1))
	assert(obstacle_view.battle.obstacles[0].placed)
	obstacle_view.queue_free()
	print("Battle result panel tests passed")
	quit()
