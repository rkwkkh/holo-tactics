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
	assert(view.battle.build_facility("facility.arrow_tower", Vector2i(1, 8)))
	view.battle.combat_gold += 100
	view._on_tile_pressed(Vector2i(1, 8))
	assert(view.facility_upgrade_button.visible and not view.facility_upgrade_button.disabled and view.facility_upgrade_button.text.contains("0/3"))
	var tower_before: float = view.battle.facilities[0].damage
	view._upgrade_selected_facility()
	assert(view.battle.facilities[0].damage == tower_before + 4.0 and view.facility_upgrade_button.text.contains("1/3"))
	view.battle.phase = "combat"
	view._refresh_context_panel()
	assert(not view.facility_upgrade_button.disabled)
	view._upgrade_selected_facility()
	assert(view.battle.facilities[0].damage == tower_before + 8.0)
	view.battle.phase = "preparation"
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
	view.battle.wave = view.battle.waves.size()
	assert(view._completed_waves_for_result() == view.battle.waves.size())
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
	assert(view._completed_waves_for_result() == view.battle.waves.size() - 1)
	view.status_override = "보상 저장 실패"
	view._refresh_result_panel()
	assert(view.result_title.text == "전투 패배" and view.result_button.disabled)
	assert(view.result_reward_label.text == "보상 저장 실패")
	view.queue_free()
	await process_frame
	for viewport_size in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(412, 915)]:
		var test_viewport := SubViewport.new()
		test_viewport.size = viewport_size
		test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(test_viewport)
		var responsive_view = load("res://scenes/battle.tscn").instantiate()
		test_viewport.add_child(responsive_view)
		await process_frame
		await process_frame
		assert(responsive_view.get_viewport_rect().size == Vector2(viewport_size))
		assert(responsive_view.controls_scroll.size.y > 0.0 and responsive_view.pause_button.visible)
		responsive_view._on_tile_pressed(Vector2i(0, 8))
		responsive_view._on_tile_pressed(Vector2i(0, 8))
		assert(responsive_view.context_panel.visible)
		var responsive_menu := Rect2(responsive_view.context_panel.global_position, responsive_view.context_panel.get_combined_minimum_size())
		var responsive_pause: Rect2 = responsive_view.pause_button.get_global_rect()
		assert(responsive_menu.position.x >= 0.0 and responsive_menu.position.y >= 0.0)
		assert(responsive_menu.end.x <= viewport_size.x and responsive_menu.end.y <= viewport_size.y)
		assert(responsive_pause.position.y >= 0.0 and responsive_pause.end.y <= viewport_size.y)
		responsive_view.queue_free()
		test_viewport.queue_free()
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
	var selected_facility: Dictionary = obstacle_view.battle.facilities.back()
	selected_facility.hp -= 5.0
	obstacle_view.battle.phase = "combat"
	obstacle_view._refresh()
	assert(obstacle_view.context_info.text.contains("전투 중 이동 불가"))
	assert(obstacle_view.repair_button.visible and not obstacle_view.repair_button.disabled)
	obstacle_view._repair_selected_facility()
	assert(selected_facility.hp == obstacle_view.battle.facility_definitions[selected_facility.facility_id].hp)
	obstacle_view._toggle_pause()
	obstacle_view._on_tile_pressed(Vector2i(1, 5))
	assert(obstacle_view.status.text.begins_with("아군 시설 · HP"))
	obstacle_view.queue_free()
	await process_frame
	set_meta("selected_stage_id", "stage.m1.frontier")
	set_meta("editor_preview_id", "evolution-view-test-%s" % Time.get_ticks_usec())
	var evolution_view = load("res://scenes/battle.tscn").instantiate()
	root.add_child(evolution_view)
	await process_frame
	assert(evolution_view.battle.set_permanent_research(["research.evolution.swordsman.knight"]))
	assert(evolution_view.battle.deploy("swordsman", Vector2i(3, 6)))
	var evolution_unit: Dictionary = evolution_view.battle.units[0]
	evolution_unit.upgrades = {"upgrade.swordsman.charge": 2, "upgrade.swordsman.combo": 3}
	evolution_view.battle._apply_unit_upgrades(evolution_unit)
	evolution_view.battle.combat_gold = 200
	evolution_view.selected_unit = evolution_unit.id
	evolution_view._refresh()
	assert(evolution_view.evolution_buttons.size() == 1 and not evolution_view.evolution_buttons[0].disabled)
	evolution_view._evolve_unit(evolution_unit.id, "evolution.swordsman.knight")
	assert(evolution_unit.has("evolution_id") and evolution_view.context_info.text.begins_with("기사"))
	assert(evolution_view.skill_buttons.any(func(button: Button): return button.text.begins_with("영웅 돌격")))
	evolution_view.battle.phase = "combat"
	evolution_view.battle.enemies.append({"id": 400, "kind": "goblin", "cell": Vector2i(3, 5), "hp": 65.0, "damage": 10.0, "range": 1, "cooldown": 10.0, "alive": true})
	evolution_view._refresh()
	var special_button: Button = evolution_view.skill_buttons.back()
	assert(not special_button.disabled)
	special_button.pressed.emit()
	assert(evolution_unit.skill_cooldowns.has("evolution.swordsman.knight.special"))
	evolution_view.queue_free()
	await process_frame
	var research_view = load("res://scenes/village_research.tscn").instantiate()
	root.add_child(research_view)
	await process_frame
	assert(research_view.research_scroll.get_child_count() == 1)
	assert(research_view.list.get_child_count() == 11)
	assert(research_view.research_scroll.get_v_scroll_bar().max_value > research_view.research_scroll.get_v_scroll_bar().page)
	research_view.queue_free()
	print("Battle result panel tests passed")
	quit()
