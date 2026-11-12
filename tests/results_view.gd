extends SceneTree

func _initialize() -> void:
	root.size = Vector2i(360, 640)
	root.set_meta("selected_stage_id", "stage.m1.frontier")
	root.set_meta("editor_preview", true)
	root.set_meta("editor_preview_id", "result-view-test-%s" % Time.get_ticks_usec())
	call_deferred("_run")

func _run() -> void:
	var view = load("res://scenes/battle.tscn").instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	assert(view.controls_scroll.get_parent() != null and view.controls_scroll.get_child_count() == 1)
	assert(view.wave_button.get_parent().get_parent().get_parent() == view.controls_scroll)
	assert(view.pause_button.get_parent() != view.controls_scroll and view.pause_button.visible)
	assert(view.tiles[0].get_parent() != view.controls_scroll and view.controls_scroll.size.y > 0.0)
	assert(view.controls_scroll.get_v_scroll_bar().max_value > view.controls_scroll.get_v_scroll_bar().page)
	assert(view.speed_button.disabled and view.timer.wait_time == 0.2)
	var initial_phase: String = view.battle.phase
	var initial_gold: int = view.battle.combat_gold
	view._toggle_pause()
	assert(view.paused and view.timer.time_left == 0.0 and view.wave_button.disabled and view.back_button.disabled)
	view._start_wave()
	view._on_tile_pressed(view.battle.core_cell)
	assert(view.status.text.contains("핵심 · HP") and view.battle.phase == initial_phase and view.battle.combat_gold == initial_gold)
	view._toggle_pause()
	assert(not view.paused and view.timer.time_left > 0.0 and not view.wave_button.disabled and not view.back_button.disabled)
	view.rest_seconds = 2
	view.rest_timer.start(0.5)
	view._toggle_pause()
	assert(view.paused and view.rest_timer.time_left == 0.0)
	view._toggle_pause()
	assert(view.rest_timer.time_left > 0.0)
	view._on_tile_pressed(Vector2i(0, 8))
	view._on_tile_pressed(Vector2i(0, 8))
	assert(view.context_panel.visible and view.context_info.text.begins_with("검사 · HP"))
	assert(view.upgrade_controls.get_parent() == view.context_box)
	var menu_rect := Rect2(view.context_panel.global_position, view.context_panel.get_combined_minimum_size())
	assert(menu_rect.position.x >= 0.0 and menu_rect.position.y >= 0.0)
	assert(menu_rect.end.x <= view.get_viewport_rect().size.x and menu_rect.end.y <= view.get_viewport_rect().size.y)
	view._toggle_pause()
	view._on_tile_pressed(Vector2i(0, 8))
	assert(view.status.text.begins_with("검사 · HP"))
	view._toggle_pause()
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
	assert(obstacle_view.battle.build_facility("facility.arrow_tower", Vector2i(1, 5)))
	obstacle_view._on_tile_pressed(Vector2i(1, 5))
	assert(obstacle_view.context_panel.visible and obstacle_view.context_info.text.begins_with("시설 · HP"))
	assert(obstacle_view.context_info.text.contains("다른 타일을 눌러 이동"))
	obstacle_view.battle.phase = "combat"
	obstacle_view._refresh()
	assert(obstacle_view.context_info.text.contains("전투 중 이동 불가"))
	obstacle_view._toggle_pause()
	obstacle_view._on_tile_pressed(Vector2i(1, 5))
	assert(obstacle_view.status.text.begins_with("아군 시설 · HP"))
	obstacle_view.queue_free()
	print("Battle result panel tests passed")
	quit()
