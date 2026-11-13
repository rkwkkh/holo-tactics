@tool
extends EditorPlugin

const CATALOG_PATH := "res://data/catalog.json"
var tabs: TabContainer
var panels: Dictionary = {}

static func read_catalog(path: String = CATALOG_PATH) -> Variant:
	if not FileAccess.file_exists(path):
		var backup_path := path + ".bak"
		if not FileAccess.file_exists(backup_path) or DirAccess.rename_absolute(ProjectSettings.globalize_path(backup_path), ProjectSettings.globalize_path(path)) != OK:
			return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not catalog is Dictionary:
		return null
	var backup_path := path + ".bak"
	if FileAccess.file_exists(backup_path) and ContentValidator.validate(catalog).is_empty() and DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path)) != OK:
		return null
	return catalog

func _enter_tree() -> void:
	tabs = TabContainer.new()
	tabs.name = "콘텐츠 편집기"
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
	var errors_label := Label.new()
	errors_label.text = "검증 오류 / 경고 · 오류 항목은 클릭해 레코드 열기"
	page.add_child(errors_label)
	var error_list := ItemList.new()
	error_list.custom_minimum_size.y = 84
	page.add_child(error_list)
	var inspector_controls := HBoxContainer.new()
	var inspect := Button.new()
	inspect.text = "Inspector에서 편집"
	inspect.pressed.connect(_open_inspector.bind(key))
	inspector_controls.add_child(inspect)
	var import_inspector := Button.new()
	import_inspector.text = "Inspector 값 가져오기"
	import_inspector.pressed.connect(_import_inspector.bind(key))
	inspector_controls.add_child(import_inspector)
	page.add_child(inspector_controls)
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
	panels[key] = {"picker": picker, "edit": edit, "feedback": feedback, "errors": error_list, "drafts": {}, "active_id": "", "inspector_record": null}
	picker.item_selected.connect(_select_record.bind(key))
	error_list.item_selected.connect(_open_error_record.bind(key))
	_refresh_records(key)

func _categories_for(key: String) -> Array[String]:
	return ["stages", "waves"] if key == "stages_waves" else ["evolutions"] if key == "evolutions" else ["upgrades"]

func _refresh_records(key: String, selected_id: String = "") -> void:
	var picker: OptionButton = panels[key].picker
	picker.clear()
	var catalog: Variant = read_catalog()
	if not catalog is Dictionary:
		panels[key].feedback.text = "카탈로그를 읽거나 백업에서 복구할 수 없습니다."
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
	var previous_id: String = panels[key].active_id
	if not previous_id.is_empty():
		panels[key].drafts[previous_id] = panels[key].edit.text
	var item_meta: Dictionary = picker.get_item_metadata(index)
	panels[key].active_id = item_meta.id
	panels[key].inspector_record = null
	if panels[key].drafts.has(item_meta.id):
		panels[key].edit.text = panels[key].drafts[item_meta.id]
		return
	var catalog: Variant = read_catalog()
	if not catalog is Dictionary:
		return
	for item in catalog.categories.get(item_meta.category, []):
		if item.id == item_meta.id:
			panels[key].edit.text = JSON.stringify(item, "\t")
			panels[key].feedback.text = "JSON을 편집한 뒤 검증 후 저장을 누르세요."
			return

func _open_inspector(key: String) -> void:
	var panel: Dictionary = panels[key]
	var record: Variant = JSON.parse_string(panel.edit.text)
	if not record is Dictionary:
		panel.feedback.text = "Error: Inspector에 열기 전에 유효한 JSON 객체를 입력하세요."
		return
	var inspector_record := EditableCatalogRecord.new()
	inspector_record.set_record(record)
	panel.inspector_record = inspector_record
	EditorInterface.edit_resource(inspector_record)
	panel.feedback.text = "Inspector 수정 후 ‘Inspector 값 가져오기’를 눌러 패널과 동기화하세요."

func _import_inspector(key: String) -> void:
	var panel: Dictionary = panels[key]
	var inspector_record: Variant = panel.get("inspector_record")
	if not inspector_record is EditableCatalogRecord:
		panel.feedback.text = "Inspector에서 먼저 레코드를 여세요."
		return
	panel.edit.text = JSON.stringify(inspector_record.values, "\t")
	panel.feedback.text = "Inspector 값을 가져왔습니다. 저장 전 Validator가 전체 카탈로그를 검사합니다."

func _save_record(key: String) -> void:
	var panel: Dictionary = panels[key]
	var edited: Variant = JSON.parse_string(panel.edit.text)
	if panel.picker.item_count == 0 or panel.picker.selected < 0:
		panel.feedback.text = "Error: 저장할 항목을 선택하세요."
		return
	var item_meta: Dictionary = panel.picker.get_item_metadata(panel.picker.selected)
	var result := save_catalog_record(CATALOG_PATH, item_meta.category, item_meta.id, edited)
	if not result.saved:
		var errors: Array[String] = result.get("errors", [])
		if not errors.is_empty():
			panel.feedback.text = "Error · 저장 차단\n" + "\n".join(errors.slice(0, 5))
			_show_validation_errors(key, errors, result.catalog, result.warnings)
		else:
			panel.feedback.text = "Error: " + result.get("error", "카탈로그 저장에 실패했습니다.")
		return
	var catalog: Dictionary = result.catalog
	var warnings: Array[String] = result.warnings
	panel.feedback.text = "검증 통과 · 저장했습니다." if warnings.is_empty() else "저장했습니다. 경고: " + "\n".join(warnings)
	_show_validation_errors(key, [], catalog, warnings)
	panel.drafts.erase(item_meta.id)
	panel.active_id = ""
	EditorInterface.get_resource_filesystem().scan()
	_refresh_records(key, item_meta.id)

static func save_catalog_record(path: String, category: String, selected_id: String, edited: Variant) -> Dictionary:
	if not edited is Dictionary or not edited.get("id", "") is String:
		return {"saved": false, "error": "항목은 안정 ID가 포함된 JSON 객체여야 합니다."}
	if edited.id != selected_id:
		return {"saved": false, "error": "안정 ID 변경은 참조 무결성을 깨뜨릴 수 있어 여기서 허용하지 않습니다."}
	var catalog: Variant = read_catalog(path)
	if not catalog is Dictionary:
		return {"saved": false, "error": "카탈로그를 읽거나 백업에서 복구할 수 없습니다."}
	var categories: Variant = catalog.get("categories", {})
	if not categories is Dictionary or not categories.get(category, []) is Array:
		return {"saved": false, "error": "편집할 카테고리를 찾을 수 없습니다."}
	var replaced := false
	for index in categories[category].size():
		var item: Variant = categories[category][index]
		if item is Dictionary and item.get("id", "") == selected_id:
			categories[category][index] = edited
			replaced = true
			break
	if not replaced:
		return {"saved": false, "error": "선택 항목이 카탈로그에서 사라졌습니다. 새로 고침 후 다시 시도하세요."}
	var errors := ContentValidator.validate(catalog)
	var warnings := ContentValidator.warnings(catalog)
	if not errors.is_empty():
		return {"saved": false, "errors": errors, "warnings": warnings, "catalog": catalog}
	if not _write_catalog(JSON.stringify(catalog, "\t"), path):
		return {"saved": false, "error": "원자적 저장에 실패했습니다. 원본을 보존했습니다."}
	return {"saved": true, "warnings": warnings, "catalog": catalog}

func _show_validation_errors(key: String, errors: Array[String], catalog: Dictionary, warnings: Array[String] = []) -> void:
	var panel: Dictionary = panels[key]
	panel.errors.clear()
	for error in errors:
		panel.errors.add_item("Error · " + error)
		panel.errors.set_item_metadata(panel.errors.item_count - 1, ContentValidator.content_id_from_error(error, catalog))
	for warning in warnings:
		panel.errors.add_item("Warning · " + warning)
		panel.errors.set_item_metadata(panel.errors.item_count - 1, "")

func _open_error_record(index: int, source_key: String) -> void:
	var source: Dictionary = panels[source_key]
	var target_id: String = source.errors.get_item_metadata(index)
	if target_id.is_empty():
		return
	var error_text: String = source.errors.get_item_text(index).trim_prefix("Error · ")
	for key in ["stages_waves", "evolutions", "upgrades"]:
		var picker: OptionButton = panels[key].picker
		for item_index in picker.item_count:
			if picker.get_item_metadata(item_index).id == target_id:
				tabs.current_tab = ["stages_waves", "evolutions", "upgrades"].find(key)
				picker.select(item_index)
				_select_record(item_index, key)
				_focus_error_field(panels[key].edit, error_text, target_id)
				return

static func _focus_error_field(edit: TextEdit, error_text: String, target_id: String) -> void:
	var separator := error_text.find(":")
	if separator < 0:
		return
	var path := error_text.substr(0, separator).trim_prefix(target_id + ".").get_slice("|", 0)
	var search_from := 0
	var selected_start := -1
	var selected_end := -1
	for part in path.replace("[]", "").split("."):
		if part.is_empty():
			continue
		var key_token := "\"%s\"" % part
		var position := edit.text.find(key_token, search_from)
		if position < 0:
			break
		selected_start = position
		selected_end = position + key_token.length()
		search_from = selected_end
	if selected_start < 0:
		return
	var prefix := edit.text.substr(0, selected_start)
	var line := prefix.count("\n")
	var column := prefix.length() - prefix.rfind("\n") - 1 if prefix.contains("\n") else prefix.length()
	edit.set_caret_line(line)
	edit.set_caret_column(column)
	edit.select(line, column, line, column + selected_end - selected_start)

func _preview_selected(direct_wave: bool) -> void:
	var picker: OptionButton = panels.stages_waves.picker
	if picker.selected < 0:
		panels.stages_waves.feedback.text = "Error: 스테이지 또는 웨이브를 선택하세요."
		return
	var selected: Dictionary = picker.get_item_metadata(picker.selected)
	var catalog: Variant = read_catalog()
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

static func _write_catalog(contents: String, path: String = CATALOG_PATH) -> bool:
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
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
	var target_abs := ProjectSettings.globalize_path(path)
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
