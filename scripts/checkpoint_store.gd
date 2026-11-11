class_name CheckpointStore
extends RefCounted

const PATH := "user://battle_checkpoint.json"
var path: String = PATH

func _init(save_path: String = PATH) -> void:
	path = save_path

func _temp_path() -> String:
	return path + ".tmp"

func _backup_path() -> String:
	return path + ".bak"

func save_checkpoint(data: Dictionary) -> bool:
	var file := FileAccess.open(_temp_path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	if file.get_error() != OK:
		file.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_temp_path()))
		return false
	file.close()
	var final_path := ProjectSettings.globalize_path(path)
	var temp_path := ProjectSettings.globalize_path(_temp_path())
	var backup_path := ProjectSettings.globalize_path(_backup_path())
	var had_old := FileAccess.file_exists(path)
	if had_old and DirAccess.rename_absolute(final_path, backup_path) != OK:
		return false
	if DirAccess.rename_absolute(temp_path, final_path) != OK:
		if had_old:
			DirAccess.rename_absolute(backup_path, final_path)
		return false
	if had_old:
		DirAccess.remove_absolute(backup_path)
	return true

func load_checkpoint() -> Dictionary:
	var final_path := ProjectSettings.globalize_path(path)
	var backup_path := ProjectSettings.globalize_path(_backup_path())
	if not FileAccess.file_exists(path) and FileAccess.file_exists(_backup_path()):
		DirAccess.rename_absolute(backup_path, final_path)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func clear_checkpoint() -> void:
	for candidate in [path, _temp_path(), _backup_path()]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
