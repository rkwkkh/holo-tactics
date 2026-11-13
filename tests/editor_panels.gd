extends SceneTree

func _initialize() -> void:
	var plugin_script: Script = load("res://addons/content_editor/content_editor.gd")
	var plugin: EditorPlugin = plugin_script.new()
	assert(plugin != null)
	plugin.tabs = TabContainer.new()
	plugin.tabs.name = "콘텐츠 편집기"
	for key in ["stages_waves", "evolutions", "upgrades"]:
		plugin.call("_build_panel", key)
	assert(plugin.tabs.get_child_count() == 3)
	assert(plugin.tabs.name == "콘텐츠 편집기")
	assert(plugin.panels.evolutions.picker.item_count == 6)
	assert(plugin.panels.upgrades.picker.item_count == 24)
	assert(plugin.panels.stages_waves.picker.item_count > 0)
	for key in ["stages_waves", "evolutions", "upgrades"]:
		var panel: Dictionary = plugin.panels[key]
		assert(panel.picker.item_count > 0 and panel.picker.selected == 0)
		assert(panel.edit.text.begins_with("{"))
	var catalog: Dictionary = plugin_script.read_catalog()
	var stage_id: String = catalog.categories.stages[0].id
	# Exercise the Inspector resource edit/import path without saving the source catalog.
	var inspector_script: Script = load("res://addons/content_editor/editable_catalog_record.gd")
	var inspector_record: Variant = inspector_script.new()
	inspector_record.set_record(JSON.parse_string(plugin.panels.stages_waves.edit.text))
	assert(inspector_record._set("start_resource", 161.0))
	plugin.panels.stages_waves.inspector_record = inspector_record
	plugin._import_inspector("stages_waves")
	var imported_record: Variant = JSON.parse_string(plugin.panels.stages_waves.edit.text)
	assert(float(imported_record.start_resource) == 161.0)
	assert(float(plugin_script.read_catalog().categories.stages[0].start_resource) == 160.0)
	# Exercise the dock's validation feedback and item routing without mutating the source catalog.
	var errors: Array[String] = ["%s.references: unresolved wave" % stage_id]
	var warnings: Array[String] = ["campaign contains 27 waves"]
	plugin._show_validation_errors("stages_waves", errors, catalog, warnings)
	var error_list: ItemList = plugin.panels.stages_waves.errors
	assert(error_list.item_count == 2)
	assert(error_list.get_item_text(0).begins_with("Error · ") and error_list.get_item_metadata(0) == stage_id)
	assert(error_list.get_item_text(1).begins_with("Warning · ") and error_list.get_item_metadata(1).is_empty())
	error_list.item_selected.emit(0)
	assert(plugin.panels.stages_waves.edit.get_selected_text() == "\"references\"")
	plugin.panels.stages_waves.picker.select(1)
	plugin._select_record(1, "stages_waves")
	var selected_id: String = plugin.panels.stages_waves.active_id
	assert(selected_id != stage_id)
	error_list.item_selected.emit(1)
	assert(plugin.panels.stages_waves.active_id == selected_id)
	var preview_controls: HBoxContainer = plugin.tabs.get_child(0).get_child(8)
	assert(preview_controls.get_child(0).text == "스테이지 실행")
	assert(preview_controls.get_child(1).text == "선택 웨이브 실행")
	print("Editor content panels passed: stages/waves, 6 evolutions, 24 upgrades, Inspector import, validation Error/Warning navigation")
	plugin.tabs.queue_free()
	plugin.free()
	await create_timer(2.0).timeout
	quit(0)
