extends Node

func _ready() -> void:
	var path := "user://editor_preview.json"
	if not FileAccess.file_exists(path):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var request: Variant = null
	if file != null:
		request = JSON.parse_string(file.get_as_text())
		file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not request is Dictionary or not request.get("preview_id", "") is String or request.preview_id.is_empty() or not request.get("stage_id", "") is String:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
		return
	get_tree().set_meta("selected_stage_id", request.stage_id)
	get_tree().set_meta("editor_preview", true)
	get_tree().set_meta("preview_wave_id", request.get("wave_id", ""))
	get_tree().set_meta("editor_preview_id", request.preview_id)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/battle.tscn")
