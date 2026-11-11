extends Control

const TILE_SIZE := Vector2(40, 39)

var battle: BattleModel
var store: CheckpointStore
var stage_title := ""
var tiles: Array[Button] = []
var status: Label
var hud: Label
var selected_kind := "swordsman"
var selected_unit := -1
var timer: Timer
var rest_timer: Timer
var rest_seconds := 0
var wave_button: Button
var deploy_buttons: Array[Button] = []
var status_override := ""

func _ready() -> void:
	var selected_stage_id: String = get_tree().get_meta("selected_stage_id", BattleModel.STAGE_ID)
	battle = BattleModel.new(selected_stage_id)
	var checkpoint_path := "user://battle_checkpoint.json" if selected_stage_id == BattleModel.STAGE_ID else "user://battle_checkpoint_%s.json" % selected_stage_id.replace(".", "_")
	store = CheckpointStore.new(checkpoint_path)
	stage_title = "수성" if battle.stage.get("mode") == "defense" else "공성"
	var saved := store.load_checkpoint()
	var resume := FileAccess.file_exists(store.path)
	if resume and (saved.is_empty() or not battle.restore(saved)):
		store.clear_checkpoint()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 4)
	add_child(layout)
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
			tile.pressed.connect(_on_tile_pressed.bind(cell))
			grid.add_child(tile)
			tiles.append(tile)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(controls)
	for kind in ["swordsman", "archer"]:
		var deploy_button := Button.new()
		deploy_button.text = "검사 (%d)" % battle.balance_seed[kind].cost if kind == "swordsman" else "궁수 (%d)" % battle.balance_seed[kind].cost
		deploy_button.pressed.connect(_select_unit_kind.bind(kind))
		controls.add_child(deploy_button)
		deploy_buttons.append(deploy_button)
	wave_button = Button.new()
	wave_button.text = "웨이브 시작"
	wave_button.pressed.connect(_start_wave)
	controls.add_child(wave_button)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.custom_minimum_size.y = 72
	layout.add_child(status)
	var back := Button.new()
	back.text = "메인 화면"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(back)
	timer = Timer.new()
	timer.wait_time = 0.2
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

func _on_tile_pressed(cell: Vector2i) -> void:
	status_override = ""
	var unit := _unit_at(cell)
	if not unit.is_empty():
		selected_unit = unit.id
		selected_kind = ""
	elif selected_unit >= 0:
		if not battle.move_unit(selected_unit, cell):
			status_override = "이동할 수 없는 칸입니다"
	elif battle.phase == "preparation" and not selected_kind.is_empty():
		if not battle.deploy(selected_kind, cell):
			status_override = "배치 위치 또는 전투 자원을 확인하세요"
	_refresh()

func _select_unit_kind(kind: String) -> void:
	selected_kind = kind
	selected_unit = -1
	status_override = ""
	_refresh()

func _start_wave() -> void:
	rest_timer.stop()
	rest_seconds = 0
	if not battle.start_wave(store):
		status_override = "체크포인트 저장 실패: 저장 성공 전에는 전투를 시작할 수 없습니다"
	else:
		status_override = ""
	_refresh()

func _tick() -> void:
	var previous_phase := battle.phase
	battle.tick(timer.wait_time)
	if previous_phase == "combat" and battle.phase == "preparation":
		rest_seconds = battle.stage.intermission_seconds
		rest_timer.start()
	if battle.phase == "finished":
		rest_timer.stop()
		if battle.battle_result != "safe_abort":
			store.clear_checkpoint()
	_refresh()

func _on_rest_tick() -> void:
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

func _refresh() -> void:
	hud.text = "%s · 웨이브 %d / 핵심 HP %.0f / 전투 자원 %d" % [stage_title, battle.wave, battle.core_hp, battle.combat_gold]
	wave_button.text = "웨이브 시작 (%d)" % rest_seconds if rest_seconds > 0 else "웨이브 시작"
	wave_button.disabled = battle.phase != "preparation"
	for button in deploy_buttons:
		button.disabled = battle.phase != "preparation"
	for y in BattleModel.ROWS:
		for x in BattleModel.COLUMNS:
			var cell := Vector2i(x, y)
			var index := y * BattleModel.COLUMNS + x
			var tile := tiles[index]
			tile.text = "◆" if cell == battle.core_cell else "▧" if battle.blocked_cells.has(cell) else "▤" if battle._wall_at(cell) >= 0 else ""
			for unit in battle.units:
				if unit.alive and unit.cell == cell:
					tile.text = "검" if unit.kind == "swordsman" else "궁"
					if unit.id == selected_unit:
						tile.text = "[" + tile.text + "]"
			for enemy in battle.enemies:
				if enemy.alive and enemy.cell == cell:
					tile.text = "적"
		if not status_override.is_empty():
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
