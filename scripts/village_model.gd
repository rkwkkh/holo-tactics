class_name VillageModel
extends RefCounted

const COLUMNS := 6
const ROWS := 6
var progress: ProgressStore
var definitions: Dictionary = {}
var research_definitions: Dictionary = {}
var available := false

func _init(save_path: String = ProgressStore.PATH) -> void:
	progress = ProgressStore.new(save_path)
	if not progress.load_progress():
		return
	available = true
	if not progress.data.has("buildings") or progress.data.buildings.is_empty():
		progress.data.buildings = [{"kind": "headquarters", "cell": [2, 2], "stored": false}]
	var file := FileAccess.open("res://data/catalog.json", FileAccess.READ)
	if file == null:
		return
	var catalog: Variant = JSON.parse_string(file.get_as_text())
	if not catalog is Dictionary:
		return
	for definition in catalog.categories.get("town_buildings", []):
		definitions[definition.kind] = definition
	for research in catalog.categories.get("research", []):
		research_definitions[research.id] = research

func building_at(cell: Vector2i) -> Dictionary:
	for building in progress.data.get("buildings", []):
		if not building.get("stored", false) and building.cell == [cell.x, cell.y]:
			return building
	return {}

func has_building(kind: String) -> bool:
	return progress.data.get("buildings", []).any(func(building): return building.kind == kind and not building.get("stored", false))

func can_build(kind: String) -> bool:
	if not available or not definitions.has(kind):
		return false
	var owned := _building_by_kind(kind)
	if not owned.is_empty():
		return bool(owned.stored)
	var definition: Dictionary = definitions[kind]
	return kind != "headquarters" and _is_unlocked(definition) and int(definition.cost) <= progress.data.permanent_currency

func is_stored(kind: String) -> bool:
	return bool(_building_by_kind(kind).get("stored", false))

func can_purchase_research(research_id: String) -> bool:
	if not available or not research_definitions.has(research_id) or progress.data.unlocked_research.has(research_id):
		return false
	var research: Dictionary = research_definitions[research_id]
	if not has_building(research.building_kind) or int(research.cost) > progress.data.permanent_currency:
		return false
	if not _is_unlocked(research) or research.dependencies.any(func(id): return not progress.data.completed_stages.has(id) and not progress.data.unlocked_research.has(id)):
		return false
	return true

func purchase_research(research_id: String) -> bool:
	if not can_purchase_research(research_id):
		return false
	var before := progress.data.duplicate(true)
	var research: Dictionary = research_definitions[research_id]
	progress.data.permanent_currency -= int(research.cost)
	progress.data.unlocked_research.append(research_id)
	return _save_or_restore(before)

func place_building(kind: String, cell: Vector2i) -> bool:
	if not can_build(kind) or not _is_valid_cell(cell) or not building_at(cell).is_empty():
		return false
	var instance: Dictionary = {}
	for building in progress.data.buildings:
		if building.kind == kind:
			instance = building
			break
	var definition: Dictionary = definitions[kind]
	if instance.is_empty():
		if kind == "headquarters" or not _is_unlocked(definition) or progress.data.permanent_currency < int(definition.cost):
			return false
		var before := progress.data.duplicate(true)
		instance = {"kind": kind, "cell": [cell.x, cell.y], "stored": false}
		progress.data.buildings.append(instance)
		progress.data.permanent_currency -= int(definition.cost)
		return _save_or_restore(before)
	else:
		if not instance.stored:
			return false
		var before := progress.data.duplicate(true)
		instance.cell = [cell.x, cell.y]
		instance.stored = false
		return _save_or_restore(before)

func move_building(kind: String, cell: Vector2i) -> bool:
	if not available or not _is_valid_cell(cell) or not building_at(cell).is_empty():
		return false
	var building: Dictionary = _building_by_kind(kind)
	if building.is_empty() or building.stored or kind == "headquarters":
		return false
	var before := progress.data.duplicate(true)
	building.cell = [cell.x, cell.y]
	return _save_or_restore(before)

func store_building(kind: String) -> bool:
	if not available:
		return false
	var building: Dictionary = _building_by_kind(kind)
	if building.is_empty() or building.stored or kind == "headquarters":
		return false
	var before := progress.data.duplicate(true)
	building.stored = true
	return _save_or_restore(before)

func _building_by_kind(kind: String) -> Dictionary:
	for building in progress.data.get("buildings", []):
		if building.kind == kind:
			return building
	return {}

func _is_unlocked(definition: Dictionary) -> bool:
	var required: String = definition.get("requires_stage", "")
	return required.is_empty() or progress.data.completed_stages.has(required)

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMNS and cell.y >= 0 and cell.y < ROWS

func _save_or_restore(before: Dictionary) -> bool:
	if progress.save_progress():
		return true
	progress.data = before
	return false
