class_name ProgressStore
extends RefCounted

const PATH := "user://campaign_progress.json"
var path: String = PATH
var data: Dictionary = {}

func _init(save_path: String = PATH) -> void:
	path = save_path
	data = {"progress_version": ProjectVersions.PROGRESS_VERSION, "permanent_currency": 0, "unlocked_research": [], "completed_stages": [], "reward_events": {}}

func load_progress() -> bool:
	if not FileAccess.file_exists(path):
		return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not _is_valid(parsed):
		return false
	data = parsed
	data.permanent_currency = int(data.permanent_currency)
	for event_id in data.reward_events:
		data.reward_events[event_id] = int(data.reward_events[event_id])
	return true

func save_progress() -> bool:
	if not _is_valid(data):
		return false
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	if file.get_error() != OK:
		file.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	file.close()
	var final_abs := ProjectSettings.globalize_path(path)
	var temp_abs := ProjectSettings.globalize_path(temp_path)
	var backup_abs := ProjectSettings.globalize_path(backup_path)
	var had_old := FileAccess.file_exists(path)
	if had_old and DirAccess.rename_absolute(final_abs, backup_abs) != OK:
		return false
	if DirAccess.rename_absolute(temp_abs, final_abs) != OK:
		if had_old:
			DirAccess.rename_absolute(backup_abs, final_abs)
		return false
	if had_old:
		DirAccess.remove_absolute(backup_abs)
	return true

func grant_reward_once(event_id: String, amount: int) -> bool:
	if event_id.is_empty() or amount < 0 or data.reward_events.has(event_id):
		return false
	data.permanent_currency += amount
	data.reward_events[event_id] = amount
	if save_progress():
		return true
	data.permanent_currency -= amount
	data.reward_events.erase(event_id)
	return false

func settle_run(run_id: String, stage_id: String, result: String, completed_waves: int, first_clear_bonus: int, repeat_reward: int, partial_reward_per_wave: int) -> int:
	if run_id.is_empty() or stage_id.is_empty() or result not in ["victory", "defeat", "abandoned"] or completed_waves < 0 or first_clear_bonus < 0 or repeat_reward < 0 or partial_reward_per_wave < 0:
		return -1
	var event_id := "battle.%s" % run_id
	if data.reward_events.has(event_id):
		return int(data.reward_events[event_id])
	var first_clear: bool = result == "victory" and not data.completed_stages.has(stage_id)
	var amount: int = repeat_reward + (first_clear_bonus if first_clear else 0) if result == "victory" else partial_reward_per_wave * completed_waves
	data.permanent_currency += amount
	data.reward_events[event_id] = amount
	if result == "victory" and not data.completed_stages.has(stage_id):
		data.completed_stages.append(stage_id)
	if save_progress():
		return amount
	data.reward_events.erase(event_id)
	data.permanent_currency -= amount
	if result == "victory" and first_clear:
		data.completed_stages.erase(stage_id)
	return -1

func _is_valid(candidate: Dictionary) -> bool:
	if candidate.get("progress_version") != ProjectVersions.PROGRESS_VERSION or not _is_nonnegative_integer(candidate.get("permanent_currency")):
		return false
	for key in ["unlocked_research", "completed_stages"]:
		if not candidate.get(key) is Array or candidate[key].any(func(value): return not value is String or value.is_empty()):
			return false
	var events: Variant = candidate.get("reward_events")
	if not events is Dictionary:
		return false
	for event_id in events:
		if not event_id is String or event_id.is_empty() or not _is_nonnegative_integer(events[event_id]):
			return false
	return true

func _is_nonnegative_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0 and floor(float(value)) == float(value)
