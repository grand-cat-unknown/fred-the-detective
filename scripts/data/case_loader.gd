class_name CaseLoader
extends RefCounted

const PLAYER_START_TILE := Vector2i(5, 13)
const FACT_DIR := "res://assets/facts"
const INTERACTABLE_DIR := "res://assets/interactables"
const SUSPECT_DIR := "res://assets/suspects"
const SUSPECT_IDS := [
	&"mara",
	&"theo",
	&"otis",
	&"iris",
	&"rival",
	&"bellhop",
	&"maid",
]


static func load_default() -> CaseData:
	var case := CaseData.new()
	case.player_start_tile = PLAYER_START_TILE
	case.fact_definitions = _load_fact_definitions()
	case.interactables = _load_interactables()
	var suspects: Array[SuspectData] = []
	for id in SUSPECT_IDS:
		var suspect := _load_suspect(id)
		if suspect != null:
			suspects.append(suspect)
	case.suspects = suspects
	return case


static func _load_suspect(id: StringName) -> SuspectData:
	var path := "%s/%s.tres" % [SUSPECT_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing suspect resource: %s" % path)
		return null
	return load(path) as SuspectData


static func _load_fact_definitions() -> Array[FactDefinition]:
	var resources: Array[FactDefinition] = []
	for resource in _load_resources_from_dir(FACT_DIR):
		if resource is FactDefinition:
			resources.append(resource)
	return resources


static func _load_interactables() -> Array[InteractableDefinition]:
	var resources: Array[InteractableDefinition] = []
	for resource in _load_resources_from_dir(INTERACTABLE_DIR):
		if resource is InteractableDefinition:
			resources.append(resource)
	return resources


static func _load_resources_from_dir(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return resources

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := "%s/%s" % [path, file_name]
			var resource := load(resource_path) as Resource
			if resource != null:
				resources.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return resources
