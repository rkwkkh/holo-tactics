extends SceneTree

func _initialize() -> void:
	var icon := _rasterize("res://assets/icon.svg", "res://store_assets/draft/app_icon_512.png", Vector2i(512, 512))
	if icon != OK:
		quit(1)
		return
	var feature := _rasterize("res://store_assets/play_feature.svg", "res://build/play-feature-base.png", Vector2i(1024, 500))
	quit(0 if feature == OK else 1)

func _rasterize(source_path: String, output_path: String, expected_size: Vector2i) -> Error:
	# shortcut: direct SVG rasterization logs a tool-only export warning; use an EditorImportPlugin if this becomes a runtime pipeline.
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		push_error("Could not rasterize %s" % source_path)
		return ERR_CANT_CREATE
	if image.get_size() != expected_size:
		image.resize(expected_size.x, expected_size.y, Image.INTERPOLATE_NEAREST)
	var result := image.save_png(ProjectSettings.globalize_path(output_path))
	if result != OK:
		push_error("Could not write %s" % output_path)
	return result
