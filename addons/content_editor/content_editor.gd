@tool
extends EditorPlugin

const CATALOG_PATH := "res://data/catalog.json"
var tabs: TabContainer
var panels: Dictionary = {}

func _enter_tree() -> void:
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(340, 260)
	for key in ["stages_waves", "evolutions", "upgrades"]:
		_build_panel(key)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, tabs)

func _exit_tree() -> void:
	remove_control_from_docks(tabs)
	tabs.queue_free()

func _build_panel(key: String) -> void:
	var page := VBoxContainer.new()
	page.name = {"stages_waves": "스테이지·웨이브", "evolutions": "진화", "upgrades": "전투 강화"}[key]
	var picker := OptionButton.new()
	page.add_child(picker)
	var edit := TextEdit.new()
	edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size.y = 260
	edit.syntax_highlighter = CodeHighlighter.new()
	page.add_child(edit)
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 60
	page.add_child(feedback)
	var save := Button.new()
	save.text = "검증 후 저장"
	save.pressed.connect(_save_record.bind(key))
	page.add_child(save)
	if key == "stages_waves":
		var note := Label.new()
		note.text = "미리보기는 저장된 콘텐츠를 사용하며 진행/보상을 격리합니다."
		page.add_child(note)
		var previews := HBoxContainer.new()
		var full_stage := Button.new()
		full_stage.text = "스테이지 실행"
		full_stage.pressed.connect(_preview_selected.bind(false))
		previews.add_child(full_stage)
		var selected_wave := Button.new()
		selected_wave.text = "선택 웨이브 실행"
		selected_wave.pressed.connect(_preview_selected.bind(true))
		previews.add_child(selected_wave)
		page.add_child(previews)
	tabs.add_child(page)
	panels[key] = {"picker": picker, "edit": edit, "feedback": feedback}
	picker.item_selected.connect(_select_record.bind(key))
	_refresh_records(key)

func _categories_for(key: String) -> Array[String]:
	return ["stages", "waves"] if key == "stages_waves" else ["evolutions"] if key == "evolutions" else ["upgrades"]

func _refresh_records(key: String, selected_id: String = "") -> void:
	var picker: OptionButton = panels[key].picker
	picker.clear()
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		panels[key].feedback.text = "카탈로그를 읽을 수 없습니다."
		return
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	if not catalog is Dictionary:
		panels[key].feedback.text = "카탈로그 JSON 형식이 잘못되었습니다."
		return
	for category in _categories_for(key):
		for item in catalog.categories.get(category, []):
			var id: String = item.get("id", "")
			picker.add_item("%s · %s" % [category, id])
			picker.set_item_metadata(picker.item_count - 1, {"category": category, "id": id})
	if picker.item_count == 0:
		panels[key].edit.text = ""
		panels[key].feedback.text = "편집 가능한 항목이 없습니다."
		return
	var index := 0
	if not selected_id.is_empty():
		for i in picker.item_count:
			if picker.get_item_metadata(i).id == selected_id:
				index = i
				break
	picker.select(index)
	_select_record(index, key)

func _select_record(index: int, key: String) -> void:
	var picker: OptionButton = panels[key].picker
	if index < 0 or index >= picker.item_count:
		return
	var item_meta: Dictionary = picker.get_item_metadata(index)
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var catalog: Dictionary = JSON.parse_string(file.get_as_text())
	for item in catalog.categories.get(item_meta.category, []):
		if item.id == item_meta.id:
			panels[key].edit.text = JSON.stringify(item, "\t")
			panels[key].feedback.text = "JSON을 편집한 뒤 검증 후 저장을 누르세요."
			return

func _save_record(key: String) -> void:
	var panel: Dictionary = panels[key]
	var edited: Variant = JSON.parse_string(panel.edit.text)
	if not edited is Dictionary or not edited.get("id", "") is String:
		panel.feedback.text = "Error: 항목은 안정 ID가 포함된 JSON 객체여야 합니다."
		return
	if panel.picker.item_count == 0 or panel.picker.selected < 0:
		panel.feedback.text = "Error: 저장할 항목을 선택하세요."
		return
	var item_meta: Dictionary = panel.picker.get_item_metadata(panel.picker.selected)
	if edited.id != item_meta.id:
		panel.feedback.text = "Error: 안정 ID 변경은 참조 무결성을 깨뜨릴 수 있어 여기서 허용하지 않습니다."
		return
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		panel.feedback.text = "Error: 카탈로그를 읽을 수 없습니다."
		return
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	if not catalog is Dictionary:
		panel.feedback.text = "Error: 카탈로그 JSON을 읽을 수 없습니다."
		return
	var replaced := false
	for index in catalog.categories.get(item_meta.category, []).size():
		if catalog.categories[item_meta.category][index].id == item_meta.id:
			catalog.categories[item_meta.category][index] = edited
			replaced = true
			break
	if not replaced:
		panel.feedback.text = "Error: 선택 항목이 카탈로그에서 사라졌습니다. 새로 고침 후 다시 시도하세요."
		return
	var errors := ContentValidator.validate(catalog)
	if not errors.is_empty():
		panel.feedback.text = "Error · 저장 차단\n" + "\n".join(errors.slice(0, 5))
		return
	if not _write_catalog(JSON.stringify(catalog, "\t")):
		panel.feedback.text = "Error: 원자적 저장에 실패했습니다. 원본을 보존했습니다."
		return
	panel.feedback.text = "검증 통과 · 저장했습니다."
	EditorInterface.get_resource_filesystem().scan()
	_refresh_records(key, item_meta.id)

func _preview_selected(direct_wave: bool) -> void:
	var picker: OptionButton = panels.stages_waves.picker
	if picker.selected < 0:
		panels.stages_waves.feedback.text = "Error: 스테이지 또는 웨이브를 선택하세요."
		return
	var selected: Dictionary = picker.get_item_metadata(picker.selected)
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	if not catalog is Dictionary:
		return
	var stage: Dictionary = {}
	var wave_id := ""
	if selected.category == "stages":
		for item in catalog.categories.stages:
			if item.id == selected.id:
				stage = item
				break
		if direct_wave and not stage.get("references", []).is_empty():
			wave_id = stage.references[0]
	else:
		wave_id = selected.id
		for item in catalog.categories.stages:
			if item.get("references", []).has(wave_id):
				stage = item
				break
	if stage.is_empty() or (direct_wave and wave_id.is_empty()):
		panels.stages_waves.feedback.text = "Error: 실행할 스테이지/웨이브 연결을 찾지 못했습니다."
		return
	var request := {"preview_id": "%s_%s" % [Time.get_ticks_usec(), randi()], "stage_id": stage.id, "wave_id": wave_id if direct_wave else ""}
	var request_file := FileAccess.open("user://editor_preview.json", FileAccess.WRITE)
	if request_file == null:
		panels.stages_waves.feedback.text = "Error: 격리 테스트 프로필을 만들 수 없습니다."
		return
	request_file.store_string(JSON.stringify(request))
	request_file.flush()
	if request_file.get_error() != OK:
		request_file.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://editor_preview.json"))
		panels.stages_waves.feedback.text = "Error: 격리 테스트 프로필 저장에 실패했습니다."
		return
	request_file.close()
	EditorInterface.play_custom_scene("res://scenes/editor_preview.tscn")
	panels.stages_waves.feedback.text = "저장된 콘텐츠로 격리 테스트를 시작했습니다."

func _write_catalog(contents: String) -> bool:
	var temp_path := CATALOG_PATH + ".tmp"
	var backup_path := CATALOG_PATH + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	if file.get_error() != OK:
		file.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	file.close()
	var target_abs := ProjectSettings.globalize_path(CATALOG_PATH)
	var temp_abs := ProjectSettings.globalize_path(temp_path)
	var backup_abs := ProjectSettings.globalize_path(backup_path)
	if DirAccess.rename_absolute(target_abs, backup_abs) != OK:
		DirAccess.remove_absolute(temp_abs)
		return false
	if DirAccess.rename_absolute(temp_abs, target_abs) != OK:
		DirAccess.rename_absolute(backup_abs, target_abs)
		DirAccess.remove_absolute(temp_abs)
		return false
	DirAccess.remove_absolute(backup_abs)
	return true
