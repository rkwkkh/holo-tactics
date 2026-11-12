extends SceneTree

func _initialize() -> void:
	call_deferred("_run_preview")

func _run_preview() -> void:
	var progress_path := "user://campaign_progress.json"
	var had_progress := FileAccess.file_exists(progress_path)
	var original_progress := FileAccess.get_file_as_string(progress_path) if had_progress else ""
	var request_path := "user://editor_preview.json"
	var had_request := FileAccess.file_exists(request_path)
	var original_request := FileAccess.get_file_as_string(request_path) if had_request else ""
	var preview_id := "test_%s" % Time.get_ticks_usec()
	var request := FileAccess.open(request_path, FileAccess.WRITE)
	assert(request != null)
	request.store_string(JSON.stringify({"preview_id": preview_id, "stage_id": "stage.m1.frontier", "wave_id": "wave.m1.2"}))
	request.close()
	change_scene_to_file("res://scenes/editor_preview.tscn")
	await process_frame
	await process_frame
	await process_frame
	assert(not FileAccess.file_exists(request_path))
	assert(get_meta("editor_preview", false))
	assert(current_scene.scene_file_path == "res://scenes/battle.tscn")
	assert(current_scene.battle.wave == 2)
	assert(current_scene.editor_preview)
	current_scene.battle.phase = "finished"
	current_scene.battle.battle_result = "victory"
	current_scene._process_result()
	assert(FileAccess.file_exists(progress_path) == had_progress)
	if had_progress:
		assert(FileAccess.get_file_as_string(progress_path) == original_progress)
	if had_request:
		var restore_request := FileAccess.open(request_path, FileAccess.WRITE)
		restore_request.store_string(original_request)
		restore_request.close()
	var checkpoint_path := "user://editor_preview_checkpoint_%s.json" % preview_id
	if FileAccess.file_exists(checkpoint_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(checkpoint_path))
	print("Editor preview isolation passed")
	quit(0)
