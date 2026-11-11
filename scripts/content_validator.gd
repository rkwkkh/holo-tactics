class_name ContentValidator
extends RefCounted

static func validate(catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for version_key in ["content_version", "schema_version"]:
		var version: Variant = catalog.get(version_key)
		if not (version is int or version is float) or version < 1 or floor(float(version)) != float(version):
			errors.append("%s must be a positive integer" % version_key)
	var categories: Variant = catalog.get("categories", {})
	if not categories is Dictionary:
		errors.append("categories must be an object")
		return errors
	var ids: Dictionary = {}
	for category in categories:
		if not categories[category] is Array:
			errors.append("category %s must be an array" % category)
			continue
		for item in categories[category]:
			if not item is Dictionary or not item.get("id", "") is String or item.get("id", "").is_empty():
				errors.append("category %s contains an item without a stable id" % category)
				continue
			var id: String = item.id
			if ids.has(id):
				errors.append("duplicate content id: %s" % id)
			else:
				ids[id] = true
	for category in categories:
		if not categories[category] is Array:
			continue
		for item in categories[category]:
			if not item is Dictionary:
				continue
			if not item.get("dependencies", []) is Array:
				errors.append("%s dependencies must be an array" % item.get("id", "<missing-id>"))
			if not item.get("references", []) is Array:
				errors.append("%s references must be an array" % item.get("id", "<missing-id>"))
				continue
			for target in item.get("references", []):
				if not target is String or not ids.has(target):
					errors.append("%s has unresolved reference: %s" % [item.get("id", "<missing-id>"), target])
	var cycle_nodes := _find_dependency_cycles(categories)
	for id in cycle_nodes:
		errors.append("cyclic dependency involving: %s" % id)
	return errors

static func _find_dependency_cycles(categories: Dictionary) -> Array[String]:
	var graph: Dictionary = {}
	for items in categories.values():
		if not items is Array:
			continue
		for item in items:
			if item is Dictionary and item.get("id", "") is String:
				graph[item.id] = item.get("dependencies", []) if item.get("dependencies", []) is Array else []
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	var cycles: Array[String] = []
	for id in graph:
		_visit(id, graph, visiting, visited, cycles)
	return cycles

static func _visit(id: String, graph: Dictionary, visiting: Dictionary, visited: Dictionary, cycles: Array[String]) -> void:
	if visited.has(id):
		return
	if visiting.has(id):
		if not cycles.has(id):
			cycles.append(id)
		return
	visiting[id] = true
	for dependency in graph.get(id, []):
		if dependency is String and graph.has(dependency):
			_visit(dependency, graph, visiting, visited, cycles)
			if cycles.has(dependency) and not cycles.has(id):
				cycles.append(id)
	visiting.erase(id)
	visited[id] = true
