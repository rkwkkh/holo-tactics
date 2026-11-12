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

static func path_for_stage(stage_id: String, base_path: String = "user://") -> String:
	var filename := "battle_checkpoint.json" if stage_id == BattleModel.STAGE_ID else "battle_checkpoint_%s.json" % stage_id.replace(".", "_")
	return base_path.path_join(filename)

static func latest_stage_with_checkpoint(stages: Array, base_path: String = "user://") -> String:
	var latest_stage_id := ""
	var latest_modified := -1
	for stage in stages:
		if not stage is Dictionary or not stage.get("id", "") is String:
			continue
		var stage_id: String = stage.id
		var checkpoint_path := path_for_stage(stage_id, base_path)
		if not FileAccess.file_exists(checkpoint_path):
			continue
		var modified := FileAccess.get_modified_time(checkpoint_path)
		if modified > latest_modified:
			latest_modified = modified
			latest_stage_id = stage_id
	return latest_stage_id

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
