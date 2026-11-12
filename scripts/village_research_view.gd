extends Control

var model: VillageModel
var layout: VBoxContainer
var list: VBoxContainer
var balance: Label

func _ready() -> void:
	model = VillageModel.new()
	layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	var title := Label.new()
	title.text = "마을 영구 연구"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	balance = Label.new()
	balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(balance)
	list = VBoxContainer.new()
	layout.add_child(list)
	_refresh()
	var back := Button.new()
	back.text = "마을로"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/village.tscn"))
	layout.add_child(back)

func _refresh() -> void:
	balance.text = "영구 재화 %d" % model.progress.data.permanent_currency if model.available else "저장 오류 · 연구 구매 잠김"
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for research_id in model.research_definitions:
		var research: Dictionary = model.research_definitions[research_id]
		var button := Button.new()
		var owned: bool = model.progress.data.get("unlocked_research", []).has(research_id)
		button.text = "%s · %d%s" % [research.label, research.cost, " · 완료" if owned else ""]
		button.disabled = owned or not model.can_purchase_research(research_id)
		button.pressed.connect(_purchase.bind(research_id))
		list.add_child(button)

func _purchase(research_id: String) -> void:
	if model.purchase_research(research_id):
		_refresh()
