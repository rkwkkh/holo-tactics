extends SceneTree

func _initialize() -> void:
	var file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if file == null:
		push_error("Cannot read res://data/catalog.json")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Content catalog must be a JSON object")
		quit(1)
		return
	var errors := ContentValidator.validate(parsed)
	for error in errors:
		push_error(error)
	if errors.is_empty():
		print("Content validation passed")
	quit(1 if not errors.is_empty() else 0)
