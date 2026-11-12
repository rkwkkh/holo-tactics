@tool
class_name EditableCatalogRecord
extends Resource

var values: Dictionary = {}

func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	for key in values:
		properties.append({"name": key, "type": typeof(values[key]), "usage": PROPERTY_USAGE_DEFAULT})
	return properties

func _get(property: StringName) -> Variant:
	return values.get(String(property))

func _set(property: StringName, value: Variant) -> bool:
	var key := String(property)
	if not values.has(key):
		return false
	values[key] = value
	emit_changed()
	return true

func set_record(record: Dictionary) -> void:
	values = record.duplicate(true)
	notify_property_list_changed()
