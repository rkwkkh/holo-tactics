extends SceneTree

func _initialize() -> void:
	var valid := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "unit.swordsman", "references": ["skill.slash"], "dependencies": []}], "skills": [{"id": "skill.slash", "references": [], "dependencies": []}]}}
	assert(ContentValidator.validate(valid).is_empty())
	var duplicate := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "same"}], "skills": [{"id": "same"}]}}
	assert(ContentValidator.validate(duplicate).any(func(error): return error.contains("duplicate content id")))
	var dangling := {"content_version": 1, "schema_version": 1, "categories": {"units": [{"id": "unit.a", "references": ["missing"]}]}}
	assert(ContentValidator.validate(dangling).any(func(error): return error.contains("unresolved reference")))
	var invalid_version := {"content_version": 1.5, "schema_version": 1, "categories": {}}
	assert(ContentValidator.validate(invalid_version).any(func(error): return error.contains("content_version")))
	var cyclic := {"content_version": 1, "schema_version": 1, "categories": {"research": [{"id": "research.a", "dependencies": ["research.b"]}, {"id": "research.b", "dependencies": ["research.a"]}]}}
	assert(ContentValidator.validate(cyclic).any(func(error): return error.contains("cyclic dependency")))
	assert(ProjectVersions.CONTENT_VERSION == 1 and ProjectVersions.SCHEMA_VERSION == 1 and ProjectVersions.SAVE_VERSION == 1)
	print("M0 tests passed")
	quit(0)
