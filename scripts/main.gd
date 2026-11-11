extends Control

func _ready() -> void:
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 24)
	add_child(layout)
	var title := Label.new()
	title.text = "HOLO TACTICS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var start := Button.new()
	start.text = "수성 전투 시작"
	start.custom_minimum_size = Vector2(240, 64)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/battle.tscn"))
	layout.add_child(start)
