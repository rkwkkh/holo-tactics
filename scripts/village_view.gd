extends Control

var model: VillageModel
var selected_kind := ""
var status: Label
var grid: GridContainer

func _ready() -> void:
	model = VillageModel.new()
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 6)
	add_child(layout)
	var title := Label.new()
	title.text = "마을 관리 · 영구 재화 %d" % model.progress.data.permanent_currency
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	status = Label.new()
	status.text = "건물을 선택한 뒤 빈 칸을 누르세요."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status)
	for kind in ["training_hall", "workshop", "arcane_lab"]:
		var definition: Dictionary = model.definitions[kind]
		var button := Button.new()
		button.text = "%s · %d" % [definition.label, definition.cost]
		button.disabled = not model.can_build(kind)
		button.pressed.connect(_select_building.bind(kind))
		layout.add_child(button)
	grid = GridContainer.new()
	grid.columns = VillageModel.COLUMNS
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(grid)
	for y in VillageModel.ROWS:
		for x in VillageModel.COLUMNS:
			var button := Button.new()
			button.custom_minimum_size = Vector2(44, 44)
			button.pressed.connect(_select_cell.bind(Vector2i(x, y)))
			grid.add_child(button)
	var back := Button.new()
	back.text = "캠페인으로"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	layout.add_child(back)
	_refresh_grid()

func _select_building(kind: String) -> void:
	selected_kind = kind
	status.text = "%s 배치 위치를 선택하세요." % model.definitions[kind].label

func _select_cell(cell: Vector2i) -> void:
	if selected_kind.is_empty():
		return
	if model.place_building(selected_kind, cell):
		selected_kind = ""
		status.text = "건물을 배치했습니다."
		_refresh_grid()
	else:
		status.text = "배치할 수 없는 위치이거나 해금되지 않았습니다."

func _refresh_grid() -> void:
	for index in grid.get_child_count():
		var button := grid.get_child(index) as Button
		var building := model.building_at(Vector2i(index % VillageModel.COLUMNS, index / VillageModel.COLUMNS))
		button.text = str(model.definitions.get(building.get("kind", ""), {}).get("label", "·"))
