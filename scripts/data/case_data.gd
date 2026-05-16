class_name CaseData
extends Resource

const INTERACTABLE_DIR := "res://assets/interactables"

@export var player_start_tile: Vector2i = Vector2i.ZERO
@export var fact_definitions: Array[FactDefinition] = []
@export var interactables: Array = []
@export var suspects: Array[SuspectData] = []


func get_interactable(object_id: StringName, warn_missing := true) -> Resource:
	if object_id == &"":
		return null
	var normalized_id := StringName(str(object_id).strip_edges())
	for interactable in interactables:
		if _resource_object_id(interactable) == normalized_id:
			return interactable

	var path := "%s/%s.tres" % [INTERACTABLE_DIR, normalized_id]
	if not ResourceLoader.exists(path):
		if warn_missing:
			push_warning("No interactable definition found for object_id '%s' at %s." % [normalized_id, path])
		return null

	var loaded := load(path) as Resource
	if loaded == null or not loaded.has_method("resolve"):
		push_warning("Resource at %s cannot resolve interactable object_id '%s'." % [path, normalized_id])
		return null
	if _resource_object_id(loaded) != normalized_id:
		push_warning("Resource at %s has object_id '%s', expected '%s'." % [path, _resource_object_id(loaded), normalized_id])
		return null

	interactables.append(loaded)
	return loaded


func _resource_object_id(resource: Resource) -> StringName:
	if resource == null:
		return &""
	return StringName(str(resource.get("object_id")).strip_edges())
