extends SceneTree

func _initialize() -> void:
	var plugin_script: Script = load("res://addons/content_editor/content_editor.gd")
	var plugin: EditorPlugin = plugin_script.new()
	assert(plugin != null)
	plugin.tabs = TabContainer.new()
	for key in ["stages_waves", "evolutions", "upgrades"]:
		plugin.call("_build_panel", key)
	assert(plugin.tabs.get_child_count() == 3)
	assert(plugin.panels.evolutions.picker.item_count == 6)
	assert(plugin.panels.upgrades.picker.item_count == 20)
	assert(plugin.panels.stages_waves.picker.item_count > 0)
	for key in ["stages_waves", "evolutions", "upgrades"]:
		var panel: Dictionary = plugin.panels[key]
		assert(panel.picker.item_count > 0 and panel.picker.selected == 0)
		assert(panel.edit.text.begins_with("{"))
	var preview_controls: HBoxContainer = plugin.tabs.get_child(0).get_child(8)
	assert(preview_controls.get_child(0).text == "스테이지 실행")
	assert(preview_controls.get_child(1).text == "선택 웨이브 실행")
	print("Editor content panels passed: stages/waves, 6 evolutions, 20 upgrades")
	plugin.tabs.queue_free()
	plugin.free()
	await create_timer(2.0).timeout
	quit(0)
