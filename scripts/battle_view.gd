extends Control

const TILE_SIZE := Vector2(40, 39)
const BATTLE_TICK_SECONDS := 0.2
const FRAME_SAMPLE_SECONDS := 10.0
const BATTLE_SPRITE_CELLS := {
	"swordsman": Vector2i(0, 0), "archer": Vector2i(1, 0), "spearman": Vector2i(2, 0), "support": Vector2i(3, 0), "mage": Vector2i(4, 0),
	"goblin": Vector2i(5, 0), "goblin_archer": Vector2i(6, 0), "orc_warrior": Vector2i(7, 0), "orc_charger": Vector2i(8, 0), "enemy_mage": Vector2i(9, 0), "enemy_support": Vector2i(10, 0),
	"arrow_tower": Vector2i(0, 1), "magic_tower": Vector2i(1, 1), "support_outpost": Vector2i(2, 1), "defense_wall": Vector2i(3, 1),
	"facility.enemy_watchtower": Vector2i(4, 1), "facility.enemy_mage_tower": Vector2i(5, 1), "core": Vector2i(6, 1), "wall": Vector2i(7, 1), "obstacle": Vector2i(8, 1)
}

var battle: BattleModel
var store: CheckpointStore
var progress: ProgressStore
var stage_title := ""
var tiles: Array[Button] = []
var tile_sprites: Array[TextureRect] = []
var battle_sprite_cache: Dictionary = {}
var battle_sprite_atlas: Texture2D
var frame_sample_times: Array[float] = []
var frame_sample_elapsed := 0.0
var status: Label
var hud: Label
var selected_kind := "swordsman"
var selected_facility_id := ""
var selected_facility_instance := -1
var selected_obstacle_id := ""
var selected_obstacle_instance := -1
var selected_unit := -1
var timer: Timer
var rest_timer: Timer
var rest_seconds := 0
var wave_button: Button
var speed_button: Button
var simulation_speed := 1
var pause_button: Button
var paused := false
var pause_timer_remaining := 0.0
var pause_rest_timer_remaining := 0.0
var pause_rest_timer_was_running := false
var back_button: Button
var deploy_buttons: Array[Button] = []
var obstacle_controls: GridContainer
var obstacle_install_buttons: Array[Button] = []
var obstacle_reuse_button: Button
var obstacle_store_button: Button
var upgrade_controls: GridContainer
var upgrade_buttons: Array[Button] = []
var upgrade_controls_unit := -1
var skill_buttons: Array[Button] = []
var skill_controls_unit := -1
var skill_controls_evolution := ""
var evolution_controls: GridContainer
var evolution_buttons: Array[Button] = []
var evolution_controls_unit := -1
var context_panel: PanelContainer
var context_box: VBoxContainer
var context_info: Label
var repair_button: Button
var facility_upgrade_button: Button
var controls_scroll: ScrollContainer
var status_override := ""
var result_reward := -1
var progress_available := false
var editor_preview := false
var result_panel: PanelContainer
var result_title: Label
var result_details: Label
var result_reward_label: Label
var result_button: Button

func _ready() -> void:
	battle_sprite_atlas = load("res://assets/battle_sprites.svg")
	var selected_stage_id: String = get_tree().get_meta("selected_stage_id", BattleModel.STAGE_ID)
	editor_preview = bool(get_tree().get_meta("editor_preview", false))
	battle = BattleModel.new(selected_stage_id)
	var preview_wave_id: String = get_tree().get_meta("preview_wave_id", "") if editor_preview else ""
	if not preview_wave_id.is_empty() and not battle.select_preview_wave(preview_wave_id):
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	var preview_id: String = get_tree().get_meta("editor_preview_id", "") if editor_preview else ""
	var checkpoint_path := "user://editor_preview_checkpoint_%s.json" % preview_id if editor_preview else CheckpointStore.path_for_stage(selected_stage_id)
	store = CheckpointStore.new(checkpoint_path)
	if editor_preview:
		store.clear_checkpoint()
	progress = ProgressStore.new()
	progress_available = progress.load_progress()
	if not progress_available:
		status_override = "영구 진행 저장을 읽지 못했습니다. 원본 데이터를 보존하고 보상 정산을 중단했습니다."
	else:
		battle.set_permanent_research(progress.data.unlocked_research)
	stage_title = "수성" if battle.stage.get("mode") == "defense" else "공성"
	var saved := store.load_checkpoint() if not editor_preview else {}
	var resume := FileAccess.file_exists(store.path) and not editor_preview
	if resume and (saved.is_empty() or not battle.restore(saved)):
		store.clear_checkpoint()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 4)
	add_child(layout)
	context_panel = PanelContainer.new()
	context_panel.visible = false
	context_panel.z_index = 5
	context_box = VBoxContainer.new()
	context_panel.add_child(context_box)
	add_child(context_panel)
	context_info = Label.new()
	context_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_box.add_child(context_info)
	repair_button = Button.new()
	repair_button.text = "시설 수리"
	repair_button.pressed.connect(_repair_selected_facility)
	repair_button.add_to_group("battle_commands")
	context_box.add_child(repair_button)
	facility_upgrade_button = Button.new()
	facility_upgrade_button.text = "시설 강화"
	facility_upgrade_button.pressed.connect(_upgrade_selected_facility)
	facility_upgrade_button.add_to_group("battle_commands")
	context_box.add_child(facility_upgrade_button)
	hud = Label.new()
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(hud)
	var grid := GridContainer.new()
	grid.columns = BattleModel.COLUMNS
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(grid)
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			var tile := Button.new()
			tile.custom_minimum_size = TILE_SIZE
			tile.focus_mode = Control.FOCUS_NONE
			var tile_color := Color("#26303a") if y < 3 else Color("#303138") if y < 6 else Color("#284334")
			if cell == battle.core_cell:
				tile_color = Color("#705a35")
			var tile_style := StyleBoxFlat.new()
			tile_style.bg_color = tile_color
			tile_style.border_color = Color("#111a22")
			tile_style.set_border_width_all(1)
			tile.add_theme_stylebox_override("normal", tile_style)
			var hover_style := tile_style.duplicate()
			hover_style.bg_color = tile_color.lightened(0.12)
			tile.add_theme_stylebox_override("hover", hover_style)
			var sprite := TextureRect.new()
			sprite.name = "PixelSprite"
			sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			sprite.offset_left = 5
			sprite.offset_top = 4
			sprite.offset_right = -5
			sprite.offset_bottom = -4
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite.visible = false
			tile.add_child(sprite)
			tile.pressed.connect(_on_tile_pressed.bind(cell))
			grid.add_child(tile)
			tiles.append(tile)
			tile_sprites.append(sprite)
	controls_scroll = ScrollContainer.new()
	controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(controls_scroll)
	var controls_box := VBoxContainer.new()
	controls_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.add_child(controls_box)
	var unit_controls := GridContainer.new()
	unit_controls.columns = 3
	unit_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_box.add_child(unit_controls)
	for kind in battle.stage.get("available_units", []):
		var deploy_button := Button.new()
		deploy_button.text = "%s %d" % [_unit_name(kind), battle.balance_seed[kind].cost]
		deploy_button.custom_minimum_size = Vector2(88, 40)
		deploy_button.pressed.connect(_select_unit_kind.bind(kind))
		deploy_button.add_to_group("battle_commands")
		unit_controls.add_child(deploy_button)
		deploy_buttons.append(deploy_button)
	upgrade_controls = GridContainer.new()
	upgrade_controls.columns = 2
	upgrade_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	context_box.add_child(upgrade_controls)
	var skill_controls := GridContainer.new()
	skill_controls.columns = 2
	skill_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	context_box.add_child(skill_controls)
	set_meta("skill_controls", skill_controls)
	evolution_controls = GridContainer.new()
	evolution_controls.columns = 2
	evolution_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	context_box.add_child(evolution_controls)
	var facility_controls := GridContainer.new()
	facility_controls.columns = 2
	facility_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_box.add_child(facility_controls)
	for facility_id in ["facility.arrow_tower", "facility.magic_tower", "facility.support_outpost", "facility.defense_wall"]:
		var definition: Dictionary = battle.facility_definitions[facility_id]
		var facility_button := Button.new()
		facility_button.text = "%s %d" % ["화살탑" if definition.kind == "arrow_tower" else "마법탑" if definition.kind == "magic_tower" else "지원" if definition.kind == "support_outpost" else "방벽", definition.cost]
		facility_button.custom_minimum_size = Vector2(156, 40)
		facility_button.pressed.connect(_select_facility.bind(facility_id))
		facility_button.add_to_group("battle_commands")
		facility_controls.add_child(facility_button)
	if int(battle.stage.get("obstacle_max_owned", 0)) > 0:
		obstacle_controls = GridContainer.new()
		obstacle_controls.columns = 2
		obstacle_controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		controls_box.add_child(obstacle_controls)
		for obstacle_id in battle.obstacle_definitions:
			var obstacle: Dictionary = battle.obstacle_definitions[obstacle_id]
			var install_button := Button.new()
			install_button.text = "장애물 설치 %d" % obstacle.cost
			install_button.custom_minimum_size = Vector2(156, 40)
			install_button.pressed.connect(_select_obstacle_definition.bind(obstacle_id))
			install_button.add_to_group("battle_commands")
			obstacle_controls.add_child(install_button)
			obstacle_install_buttons.append(install_button)
		obstacle_reuse_button = Button.new()
		obstacle_reuse_button.text = "보관 장애물 재설치"
		obstacle_reuse_button.pressed.connect(_select_stored_obstacle)
		obstacle_reuse_button.add_to_group("battle_commands")
		obstacle_controls.add_child(obstacle_reuse_button)
		obstacle_store_button = Button.new()
		obstacle_store_button.text = "선택 장애물 회수"
		obstacle_store_button.pressed.connect(_store_selected_obstacle)
		obstacle_store_button.add_to_group("battle_commands")
		obstacle_controls.add_child(obstacle_store_button)
	wave_button = Button.new()
	wave_button.text = "웨이브 시작"
	wave_button.pressed.connect(_start_wave)
	wave_button.add_to_group("battle_commands")
	var wave_controls := HBoxContainer.new()
	wave_controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_box.add_child(wave_controls)
	wave_controls.add_child(wave_button)
	speed_button = Button.new()
	speed_button.pressed.connect(_toggle_speed)
	speed_button.add_to_group("battle_commands")
	wave_controls.add_child(speed_button)
	pause_button = Button.new()
	pause_button.pressed.connect(_toggle_pause)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.custom_minimum_size.y = 72
	controls_box.add_child(status)
	back_button = Button.new()
	back_button.text = "전투 포기"
	back_button.pressed.connect(_on_back_pressed)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls_box.add_child(back_button)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(pause_button)
	_build_result_panel()
	var abandon_dialog := ConfirmationDialog.new()
	abandon_dialog.dialog_text = "테스트를 끝내고 돌아가시겠습니까? 전투 진행과 보상은 저장되지 않습니다." if editor_preview else "전투를 포기하고 돌아가시겠습니까? 완료한 웨이브 수만큼 부분 보상을 받습니다."
	abandon_dialog.confirmed.connect(_abandon_battle)
	add_child(abandon_dialog)
	set_meta("abandon_dialog", abandon_dialog)
	timer = Timer.new()
	timer.wait_time = BATTLE_TICK_SECONDS
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	rest_timer = Timer.new()
	rest_timer.wait_time = 1.0
	rest_timer.timeout.connect(_on_rest_tick)
	add_child(rest_timer)
	if resume:
		rest_seconds = 3
		rest_timer.start()
	_refresh()

func _process(delta: float) -> void:
	if not OS.is_debug_build() or battle == null:
		return
	if paused or battle.phase not in ["combat", "preparation"]:
		frame_sample_times.clear()
		frame_sample_elapsed = 0.0
		return
	frame_sample_times.append(delta)
	frame_sample_elapsed += delta
	if frame_sample_elapsed < FRAME_SAMPLE_SECONDS or frame_sample_times.size() < 30:
		return
	var stats := summarize_frame_times(frame_sample_times)
	print("[PERF] stage=%s frames=%d avg_fps=%.1f p50_ms=%.2f p95_ms=%.2f max_ms=%.2f" % [battle.stage_id, frame_sample_times.size(), stats.avg_fps, stats.p50_ms, stats.p95_ms, stats.max_ms])
	frame_sample_times.clear()
	frame_sample_elapsed = 0.0

static func summarize_frame_times(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {}
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0.0
	for frame_time in sorted:
		total += frame_time
	return {
		"avg_fps": float(sorted.size()) / total,
		"p50_ms": sorted[int((sorted.size() - 1) * 0.50)] * 1000.0,
		"p95_ms": sorted[mini(sorted.size() - 1, ceili(sorted.size() * 0.95) - 1)] * 1000.0,
		"max_ms": sorted[-1] * 1000.0
	}

func _on_tile_pressed(cell: Vector2i) -> void:
	if paused:
		status_override = _inspect_paused_cell(cell)
		_refresh()
		return
	status_override = ""
	var unit := _unit_at(cell)
	if not unit.is_empty():
		selected_unit = unit.id
		selected_facility_instance = -1
		selected_obstacle_instance = -1
		selected_obstacle_id = ""
		selected_kind = ""
		selected_facility_id = ""
	elif not _facility_at(cell).is_empty():
		selected_facility_instance = _facility_at(cell).id
		selected_unit = -1
		selected_obstacle_instance = -1
		selected_obstacle_id = ""
		selected_kind = ""
		selected_facility_id = ""
	elif battle._obstacle_at(cell) >= 0:
		selected_obstacle_instance = int(battle.obstacles[battle._obstacle_at(cell)].id)
		selected_obstacle_id = ""
		selected_unit = -1
		selected_facility_instance = -1
		selected_kind = ""
		selected_facility_id = ""
	elif selected_facility_instance >= 0:
		if not battle.move_facility(selected_facility_instance, cell):
			status_override = "시설은 재정비 중에만 이동할 수 있습니다"
		selected_facility_instance = -1
	elif selected_obstacle_instance >= 0:
		var obstacle_index := battle._obstacle_index(selected_obstacle_instance)
		var succeeded := battle.place_stored_obstacle(selected_obstacle_instance, cell) if obstacle_index >= 0 and not battle.obstacles[obstacle_index].placed else battle.move_obstacle(selected_obstacle_instance, cell)
		if not succeeded:
			status_override = "장애물 위치, 경로 또는 전투 단계를 확인하세요"
		selected_obstacle_instance = -1
	elif not selected_obstacle_id.is_empty():
		if not battle.install_obstacle(selected_obstacle_id, cell):
			status_override = "장애물 위치, 경로, 보유 한도 또는 전투 자원을 확인하세요"
	elif selected_unit >= 0:
		if not battle.move_unit(selected_unit, cell):
			status_override = "이동할 수 없는 칸입니다"
	elif not selected_facility_id.is_empty():
		if not battle.build_facility(selected_facility_id, cell):
			status_override = "시설 위치 또는 전투 자원을 확인하세요"
	elif battle.phase == "preparation" and not selected_kind.is_empty():
		if not battle.deploy(selected_kind, cell):
			status_override = "배치 위치 또는 전투 자원을 확인하세요"
	_refresh()

func _select_unit_kind(kind: String) -> void:
	if paused: return
	selected_kind = kind
	selected_facility_id = ""
	selected_facility_instance = -1
	selected_unit = -1
	selected_obstacle_id = ""
	selected_obstacle_instance = -1
	status_override = ""
	_refresh()

func _select_facility(facility_id: String) -> void:
	if paused: return
	selected_facility_id = facility_id
	selected_facility_instance = -1
	selected_kind = ""
	selected_unit = -1
	selected_obstacle_id = ""
	selected_obstacle_instance = -1
	status_override = "시설을 배치할 타일을 선택하세요"
	_refresh()

func _select_obstacle_definition(obstacle_id: String) -> void:
	if paused: return
	selected_obstacle_id = obstacle_id
	selected_obstacle_instance = -1
	selected_kind = ""
	selected_facility_id = ""
	selected_facility_instance = -1
	selected_unit = -1
	status_override = "장애물을 설치할 타일을 선택하세요"
	_refresh()

func _select_stored_obstacle() -> void:
	if paused: return
	for obstacle in battle.obstacles:
		if not obstacle.placed:
			selected_obstacle_instance = int(obstacle.id)
			selected_obstacle_id = ""
			selected_kind = ""
			selected_facility_id = ""
			selected_facility_instance = -1
			selected_unit = -1
			status_override = "저장된 장애물을 놓을 타일을 선택하세요"
			_refresh()
			return

func _store_selected_obstacle() -> void:
	if paused: return
	if selected_obstacle_instance < 0 or not battle.store_obstacle(selected_obstacle_instance):
		status_override = "재정비 중 배치된 장애물을 선택하세요"
	else:
		selected_obstacle_instance = -1
		status_override = "장애물을 회수했습니다. 재화는 환급되지 않습니다"
	_refresh()

func _start_wave() -> void:
	if paused: return
	rest_timer.stop()
	rest_seconds = 0
	if not battle.start_wave(store):
		status_override = "체크포인트 저장 실패: 저장 성공 전에는 전투를 시작할 수 없습니다"
	else:
		status_override = ""
	_refresh()

func _purchase_upgrade(unit_id: int, upgrade_id: String) -> void:
	if paused: return
	status_override = "" if battle.purchase_upgrade(unit_id, upgrade_id) else "강화에 필요한 전투 자원이 부족하거나 구매할 수 없습니다"
	_refresh()

func _cast_skill(unit_id: int, skill_id: String) -> void:
	if paused: return
	status_override = "" if battle.cast_skill(unit_id, skill_id) else "스킬을 사용할 수 없습니다"
	_refresh()

func _evolve_unit(unit_id: int, evolution_id: String) -> void:
	if paused: return
	status_override = "" if battle.evolve_unit(unit_id, evolution_id) else "진화 조건 또는 전투 자원을 확인하세요"
	_refresh()

func _repair_selected_facility() -> void:
	if paused: return
	status_override = "" if battle.repair_facility(selected_facility_instance) else "시설 수리 자원 또는 상태를 확인하세요"
	_refresh()

func _upgrade_selected_facility() -> void:
	if paused: return
	status_override = "" if battle.purchase_facility_upgrade(selected_facility_instance) else "시설 강화 자원 또는 상태를 확인하세요"
	_refresh()

func _on_back_pressed() -> void:
	if editor_preview:
		store.clear_checkpoint()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	if battle.phase == "finished":
		get_tree().change_scene_to_file("res://scenes/village.tscn")
	else:
		(get_meta("abandon_dialog") as ConfirmationDialog).popup_centered()

func _abandon_battle() -> void:
	if battle.phase in ["preparation", "combat"]:
		battle.phase = "finished"
		battle.battle_result = "abandoned"
		_process_result()
		_refresh()

func _completed_waves_for_result() -> int:
	return clampi(battle.wave if battle.battle_result == "victory" else battle.wave - 1, 0, battle.waves.size())

func _process_result() -> void:
	if editor_preview:
		result_reward = 0
		store.clear_checkpoint()
		status_override = "편집기 테스트 종료 · 영구 진행과 보상은 변경되지 않았습니다."
		return
	if battle.battle_result == "safe_abort" or result_reward >= 0:
		return
	if not progress_available:
		status_override = "영구 진행 저장을 읽지 못해 보상 정산을 중단했습니다."
		return
	var amount := progress.settle_run(battle.run_id, battle.stage_id, battle.battle_result, _completed_waves_for_result(), int(battle.stage.permanent_first_bonus), int(battle.stage.permanent_repeat_reward), int(battle.stage.permanent_partial_per_wave))
	if amount < 0:
		status_override = "보상 저장에 실패했습니다. 체크포인트를 보존하고 다시 저장을 시도합니다."
		return
	result_reward = amount
	store.clear_checkpoint()
	status_override = "%s · 영구 재화 +%d · 보유 %d" % ["승리" if battle.battle_result == "victory" else "패배" if battle.battle_result == "defeat" else "포기", amount, progress.data.permanent_currency]

func _tick() -> void:
	if paused: return
	var previous_phase := battle.phase
	battle.tick(BATTLE_TICK_SECONDS)
	if previous_phase == "combat" and battle.phase == "preparation":
		rest_seconds = battle.stage.intermission_seconds
		rest_timer.start()
	if battle.phase == "finished":
		rest_timer.stop()
		_process_result()
	_refresh()

func _on_rest_tick() -> void:
	if paused: return
	rest_seconds -= 1
	if rest_seconds <= 0:
		_start_wave()
	else:
		_refresh()

func _unit_at(cell: Vector2i) -> Dictionary:
	for unit in battle.units:
		if unit.alive and unit.cell == cell:
			return unit
	return {}

func _unit_name(kind: String) -> String:
	return {"swordsman": "검사", "archer": "궁수", "spearman": "창병", "support": "지원병", "mage": "마법사"}.get(kind, "유닛")

func _facility_at(cell: Vector2i) -> Dictionary:
	for facility in battle.facilities:
		if facility.alive and facility.cell == cell:
			return facility
	return {}

func _refresh() -> void:
	if not paused:
		for command in get_tree().get_nodes_in_group("battle_commands"):
			command.disabled = false
	_refresh_speed_control()
	hud.text = "%s · 웨이브 %d / 핵심 HP %.0f / 전투 자원 %d" % [stage_title, battle.wave, battle.core_hp, battle.combat_gold]
	_refresh_result_panel()
	wave_button.text = "웨이브 시작 (%d)" % rest_seconds if rest_seconds > 0 else "웨이브 시작"
	wave_button.disabled = battle.phase != "preparation"
	back_button.text = "테스트 종료" if editor_preview else "마을로 돌아가기" if battle.phase == "finished" else "전투 포기"
	back_button.disabled = paused
	for button in deploy_buttons:
		button.disabled = battle.phase != "preparation"
	_refresh_upgrade_controls()
	_refresh_skill_controls()
	_refresh_evolution_controls()
	_refresh_obstacle_controls()
	_refresh_context_panel()
	if paused:
		for command in get_tree().get_nodes_in_group("battle_commands"):
			command.disabled = true
	pause_button.text = "계속" if paused else "일시정지"
	pause_button.disabled = battle.phase == "finished"
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			var index := y * BattleModel.COLUMNS + x
			var tile := tiles[index]
			var tile_sprite := tile_sprites[index]
			tile.modulate = Color.WHITE
			var sprite_id := "core" if cell == battle.core_cell else "obstacle" if battle._obstacle_at(cell) >= 0 else "wall" if battle._wall_at(cell) >= 0 else ""
			tile.text = "◆" if cell == battle.core_cell else "▧" if battle.blocked_cells.has(cell) else "▤" if battle._wall_at(cell) >= 0 else ""
			if battle._obstacle_at(cell) >= 0:
				tile.text = "▨"
			for unit in battle.units:
				if unit.alive and unit.cell == cell:
					sprite_id = unit.kind
					_set_tile_selected(tile, unit.id == selected_unit)
			for facility in battle.facilities:
				if facility.alive and facility.cell == cell:
					sprite_id = facility.kind
					_set_tile_selected(tile, facility.id == selected_facility_instance)
			for enemy in battle.enemies + battle.preview_enemies:
				if enemy.alive and enemy.cell == cell:
					sprite_id = enemy.kind
			for facility in battle.enemy_facilities:
				if facility.alive and facility.cell == cell:
					sprite_id = facility.facility_id
			tile_sprite.texture = _battle_sprite(sprite_id)
			tile_sprite.visible = tile_sprite.texture != null
			if tile_sprite.visible:
				tile.text = ""
	if paused:
		status.text = "일시정지 · 전장 정보를 확인할 수 있습니다" if status_override.is_empty() else status_override
	elif not status_override.is_empty():
		status.text = status_override
	elif battle.phase == "finished":
		match battle.battle_result:
			"victory": status.text = "전투에서 승리했습니다!"
			"safe_abort": status.text = "증원 출현 실패로 전투를 안전 종료했습니다. 마지막 체크포인트에서 다시 시작할 수 있습니다."
			_: status.text = "전투에서 패배했습니다"
	elif battle.phase == "combat":
		status.text = "전투 중 · 선택 유닛을 누른 뒤 이동할 칸을 선택하세요"
	else:
		status.text = "배치 단계 · 검사/궁수를 선택한 뒤 아군 구역을 누르세요"

func _refresh_speed_control() -> void:
	var unlocked: bool = not editor_preview and progress_available and progress.data.completed_stages.has(battle.stage_id)
	speed_button.disabled = paused or not unlocked or battle.phase == "finished"
	speed_button.text = "속도 %d×" % simulation_speed

func _battle_sprite(sprite_id: String) -> Texture2D:
	if not BATTLE_SPRITE_CELLS.has(sprite_id):
		return null
	if not battle_sprite_cache.has(sprite_id):
		var cell: Vector2i = BATTLE_SPRITE_CELLS[sprite_id]
		var atlas := AtlasTexture.new()
		atlas.atlas = battle_sprite_atlas
		atlas.region = Rect2(cell * 32, Vector2i(32, 32))
		battle_sprite_cache[sprite_id] = atlas
	return battle_sprite_cache[sprite_id]

func _set_tile_selected(tile: Button, selected: bool) -> void:
	tile.modulate = Color("#ffe7a0") if selected else Color.WHITE

func _toggle_speed() -> void:
	if paused or speed_button.disabled:
		return
	simulation_speed = 1 if simulation_speed == 2 else 2
	timer.wait_time = BATTLE_TICK_SECONDS / simulation_speed
	rest_timer.wait_time = 1.0 / simulation_speed
	speed_button.text = "속도 %d×" % simulation_speed

func _toggle_pause() -> void:
	if battle.phase == "finished": return
	paused = not paused
	if paused:
		pause_timer_remaining = timer.time_left
		pause_rest_timer_remaining = rest_timer.time_left
		pause_rest_timer_was_running = rest_timer.time_left > 0.0
		timer.stop()
		rest_timer.stop()
	else:
		timer.start(maxf(pause_timer_remaining, 0.001))
		if pause_rest_timer_was_running:
			rest_timer.start(maxf(pause_rest_timer_remaining, 0.001))
	_refresh()

func _inspect_paused_cell(cell: Vector2i) -> String:
	var unit := _unit_at(cell)
	if not unit.is_empty(): return "%s · HP %.0f/%.0f" % [_unit_name(unit.kind), unit.hp, battle.balance_seed[unit.kind].hp]
	var facility := _facility_at(cell)
	if not facility.is_empty(): return "아군 시설 · HP %.0f/%.0f" % [facility.hp, battle.facility_definitions[facility.facility_id].hp]
	for enemy in battle.enemies + battle.preview_enemies:
		if enemy.alive and enemy.cell == cell: return "적 유닛 · HP %.0f/%.0f" % [enemy.hp, battle.balance_seed[enemy.kind].hp]
	for enemy_facility in battle.enemy_facilities:
		if enemy_facility.alive and enemy_facility.cell == cell: return "적 시설 · HP %.0f/%.0f" % [enemy_facility.hp, battle.facility_definitions[enemy_facility.facility_id].hp]
	if cell == battle.core_cell: return "핵심 · HP %.0f" % battle.core_hp
	if battle._wall_at(cell) >= 0: return "방어벽"
	if battle._obstacle_at(cell) >= 0: return "장애물"
	return "빈 타일"

func _refresh_context_panel() -> void:
	var unit := battle._unit_by_id(selected_unit)
	var facility := battle._facility_by_id(selected_facility_instance)
	context_panel.visible = not unit.is_empty() or not facility.is_empty()
	if not context_panel.visible:
		return
	if not unit.is_empty():
		var unit_label := _unit_name(unit.kind)
		if unit.has("evolution_id"):
			unit_label = battle.evolution_definitions[unit.evolution_id].label
		context_info.text = "%s · HP %.0f/%.0f" % [unit_label, unit.hp, battle.balance_seed[unit.kind].hp]
		repair_button.visible = false
		facility_upgrade_button.visible = false
	else:
		var move_hint := "다른 타일을 눌러 이동" if battle.phase == "preparation" else "전투 중 이동 불가"
		context_info.text = "시설 · HP %.0f/%.0f\n%s" % [facility.hp, facility.max_hp, move_hint]
		var repair_cost := battle.facility_repair_cost(selected_facility_instance)
		repair_button.visible = true
		repair_button.text = "수리 · %d" % repair_cost if repair_cost > 0 else "수리 완료"
		repair_button.disabled = battle.phase not in ["preparation", "combat"] or repair_cost <= 0 or battle.combat_gold < repair_cost
		var upgrade: Dictionary = battle.facility_upgrade_definitions.get(facility.facility_id, {})
		facility_upgrade_button.visible = not upgrade.is_empty()
		if not upgrade.is_empty():
			var level := int(facility.upgrades.get(upgrade.id, 0))
			var upgrade_cost := battle.facility_upgrade_cost(selected_facility_instance)
			facility_upgrade_button.text = "%s %d/3 · %d" % [upgrade.label, level, upgrade_cost] if level < 3 else "%s 최대" % upgrade.label
			facility_upgrade_button.disabled = battle.phase not in ["preparation", "combat"] or level >= 3 or battle.combat_gold < upgrade_cost
	var cell: Vector2i = unit.cell if not unit.is_empty() else facility.cell
	var tile_rect := tiles[cell.y * BattleModel.COLUMNS + cell.x].get_global_rect()
	var menu_size := context_panel.get_combined_minimum_size()
	var viewport_size := get_viewport_rect().size
	var x := tile_rect.end.x + 4.0
	if x + menu_size.x > viewport_size.x:
		x = tile_rect.position.x - menu_size.x - 4.0
	var y := tile_rect.position.y
	if y + menu_size.y > viewport_size.y:
		y = tile_rect.end.y - menu_size.y
	context_panel.global_position = Vector2(clampf(x, 0.0, maxf(0.0, viewport_size.x - menu_size.x)), clampf(y, 0.0, maxf(0.0, viewport_size.y - menu_size.y)))

func _refresh_obstacle_controls() -> void:
	if obstacle_controls == null:
		return
	var max_owned := int(battle.stage.get("obstacle_max_owned", 0))
	var max_placed := int(battle.stage.get("obstacle_max_placed", 0))
	var placed := battle._placed_obstacle_count()
	var stored := battle.obstacles.size() - placed
	var definitions: Array = battle.obstacle_definitions.values()
	for index in obstacle_install_buttons.size():
		var definition: Dictionary = definitions[index]
		obstacle_install_buttons[index].text = "새 장애물 %d · 보유 %d/%d" % [definition.cost, battle.obstacles.size(), max_owned]
		obstacle_install_buttons[index].disabled = battle.phase not in ["preparation", "combat"] or battle.obstacles.size() >= max_owned or placed >= max_placed or battle.combat_gold < int(definition.cost)
	obstacle_reuse_button.text = "보관 장애물 재설치 (%d)" % stored
	obstacle_reuse_button.disabled = stored == 0 or placed >= max_placed or battle.phase not in ["preparation", "combat"]
	var selected_index := battle._obstacle_index(selected_obstacle_instance)
	obstacle_store_button.disabled = selected_index < 0 or battle.phase != "preparation" or not battle.obstacles[selected_index].placed if selected_index >= 0 else true

func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.075, 0.97)
	style.border_color = Color("#caa65a")
	style.set_border_width_all(2)
	result_panel.add_theme_stylebox_override("panel", style)
	result_panel.visible = false
	var center := CenterContainer.new()
	result_panel.add_child(center)
	var content_box := VBoxContainer.new()
	content_box.custom_minimum_size.x = 280
	content_box.add_theme_constant_override("separation", 14)
	center.add_child(content_box)
	result_title = Label.new()
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 26)
	content_box.add_child(result_title)
	result_details = Label.new()
	result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(result_details)
	result_reward_label = Label.new()
	result_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(result_reward_label)
	result_button = Button.new()
	result_button.text = "마을로 돌아가기"
	result_button.pressed.connect(_on_back_pressed)
	content_box.add_child(result_button)
	add_child(result_panel)

func _refresh_result_panel() -> void:
	var finished := battle.phase == "finished"
	result_panel.visible = finished
	if not finished:
		return
	result_title.text = "전투 승리" if battle.battle_result == "victory" else "전투 패배" if battle.battle_result == "defeat" else "안전 종료" if battle.battle_result == "safe_abort" else "전투 포기"
	result_details.text = "%s · 웨이브 %d / %d 완료" % [battle.stage.get("name", stage_title), _completed_waves_for_result(), battle.waves.size()]
	if editor_preview:
		result_reward_label.text = "편집기 미리보기 · 진행과 보상은 저장되지 않았습니다"
		result_button.text = "테스트 종료"
	elif battle.battle_result == "safe_abort":
		result_reward_label.text = "체크포인트를 보존했습니다. 문제를 수정한 뒤 이어서 다시 시작할 수 있습니다."
	elif result_reward < 0:
		result_reward_label.text = status_override if not status_override.is_empty() else "보상 저장 중입니다."
	else:
		result_reward_label.text = "영구 재화 +%d\n보유 재화 %d" % [result_reward, progress.data.permanent_currency]
		result_button.text = "마을로 돌아가기"
	result_button.disabled = not editor_preview and battle.battle_result != "safe_abort" and result_reward < 0

func _refresh_upgrade_controls() -> void:
	var unit := battle._unit_by_id(selected_unit)
	if unit.is_empty():
		for button in upgrade_buttons:
			button.queue_free()
		upgrade_buttons.clear()
		upgrade_controls_unit = -1
		return
	var definitions: Array = battle.content.categories.upgrades.filter(func(item): return item.get("unit_kind", "") == unit.kind)
	if upgrade_controls_unit != unit.id:
		for button in upgrade_buttons:
			button.queue_free()
		upgrade_buttons.clear()
		upgrade_controls_unit = unit.id
		for upgrade in definitions:
			var button := Button.new()
			button.custom_minimum_size = Vector2(120, 36)
			button.pressed.connect(_purchase_upgrade.bind(unit.id, upgrade.id))
			button.add_to_group("battle_commands")
			upgrade_controls.add_child(button)
			upgrade_buttons.append(button)
	for index in upgrade_buttons.size():
		var upgrade: Dictionary = definitions[index]
		var level := int(unit.upgrades.get(upgrade.id, 0))
		var cost := int(upgrade.costs[level]) if level < 3 else 0
		var button := upgrade_buttons[index]
		button.text = "%s %d/3 · %d" % [upgrade.label, level, cost] if level < 3 else "%s 최대" % upgrade.label
		button.disabled = battle.phase not in ["preparation", "combat"] or level >= 3 or battle.combat_gold < cost

func _refresh_skill_controls() -> void:
	var controls: GridContainer = get_meta("skill_controls")
	var unit := battle._unit_by_id(selected_unit)
	if unit.is_empty():
		for button in skill_buttons: button.queue_free()
		skill_buttons.clear()
		skill_controls_unit = -1
		skill_controls_evolution = ""
		return
	var definitions: Array = battle.content.categories.skills.filter(func(item): return item.unit_kind == unit.kind and item.mode == "manual")
	var evolution_id: String = unit.get("evolution_id", "")
	if not evolution_id.is_empty():
		var evolved_skill: Dictionary = battle.evolution_definitions[evolution_id].special_skill.duplicate(true)
		if evolved_skill.mode == "manual":
			evolved_skill.id = "%s.special" % evolution_id
			evolved_skill.unit_kind = unit.kind
			definitions.append(evolved_skill)
	if skill_controls_unit != unit.id or skill_controls_evolution != evolution_id:
		for button in skill_buttons: button.queue_free()
		skill_buttons.clear()
		skill_controls_unit = unit.id
		skill_controls_evolution = evolution_id
		for skill in definitions:
			var button := Button.new()
			button.custom_minimum_size = Vector2(120, 36)
			button.pressed.connect(_cast_skill.bind(unit.id, skill.id))
			button.add_to_group("battle_commands")
			controls.add_child(button)
			skill_buttons.append(button)
	for index in skill_buttons.size():
		var skill: Dictionary = definitions[index]
		var remaining := float(unit.skill_cooldowns.get(skill.id, 0.0))
		var button := skill_buttons[index]
		button.text = "%s · %.0f" % [skill.label, remaining] if remaining > 0.0 else "%s · %d" % [skill.label, skill.cost]
		button.disabled = battle.phase != "combat" or unit.has("destination") or remaining > 0.0 or battle.combat_gold < int(skill.cost)

func _refresh_evolution_controls() -> void:
	var unit := battle._unit_by_id(selected_unit)
	if unit.is_empty() or unit.has("evolution_id"):
		evolution_controls.visible = false
		for button in evolution_buttons: button.queue_free()
		evolution_buttons.clear()
		evolution_controls_unit = -1
		return
	var definitions: Array = battle.content.categories.evolutions.filter(func(item): return item.unit_kind == unit.kind and battle.unlocked_evolutions.has(item.id))
	evolution_controls.visible = not definitions.is_empty()
	if evolution_controls_unit != unit.id:
		for button in evolution_buttons: button.queue_free()
		evolution_buttons.clear()
		evolution_controls_unit = unit.id
		for evolution in definitions:
			var button := Button.new()
			button.custom_minimum_size = Vector2(120, 36)
			button.pressed.connect(_evolve_unit.bind(unit.id, evolution.id))
			button.add_to_group("battle_commands")
			evolution_controls.add_child(button)
			evolution_buttons.append(button)
	for index in evolution_buttons.size():
		var evolution: Dictionary = definitions[index]
		var button := evolution_buttons[index]
		button.text = "%s · %d" % [evolution.label, evolution.combat_cost]
		button.disabled = not battle.can_evolve_unit(unit.id, evolution.id)
