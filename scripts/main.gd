extends Control

func _ready() -> void:
	var progress := ProgressStore.new()
	var progress_ok := progress.load_progress()
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)
	var title := Label.new()
	title.text = "HOLO TACTICS · 캠페인"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var currency := Label.new()
	currency.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency.text = "영구 재화 %d" % progress.data.permanent_currency if progress_ok else "영구 진행 저장 오류 · 원본 데이터 보존 중"
	layout.add_child(currency)
	var content_file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if content_file == null:
		return
	var catalog: Variant = JSON.parse_string(content_file.get_as_text())
	if not catalog is Dictionary:
		return
	var stages: Array = catalog.categories.stages.filter(func(stage): return stage.get("campaign_kind", "") in ["main", "optional"])
	stages.sort_custom(func(a: Dictionary, b: Dictionary): return (a.campaign_kind == "main" and b.campaign_kind == "optional") or (a.campaign_kind == b.campaign_kind and int(a.campaign_order) < int(b.campaign_order)))
	var resume_stage_id := CheckpointStore.latest_stage_with_checkpoint(stages)
	if not resume_stage_id.is_empty():
		get_tree().set_meta("selected_stage_id", resume_stage_id)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/battle.tscn")
		return
	var campaign := GridContainer.new()
	campaign.columns = 2
	campaign.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(campaign)
	var cleared: Array = progress.data.get("completed_stages", [])
	for stage in stages:
		var button := Button.new()
		var unlocked: bool = stage.get("dependencies", []).all(func(dependency): return cleared.has(dependency))
		button.text = "%s\n%s" % [stage.get("name", stage.id), "입장 가능" if unlocked and progress_ok else "잠김"]
		button.custom_minimum_size = Vector2(168, 58)
		button.disabled = not unlocked or not progress_ok
		button.pressed.connect(_start_stage.bind(stage.id))
		campaign.add_child(button)
	var village := Button.new()
	village.text = "마을 관리"
	village.custom_minimum_size = Vector2(220, 52)
	village.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	village.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/village.tscn"))
	layout.add_child(village)

func _start_stage(stage_id: String) -> void:
	get_tree().set_meta("selected_stage_id", stage_id)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
