class_name InteractableDefinition
extends Resource

@export var object_id: StringName
@export var variants: Array = []
@export var tile_visuals: Array = []


func resolve(state: CaseState, fallback: Dictionary = {}) -> Dictionary:
	for variant in variants:
		if variant is InspectableVariant and variant.is_available(state):
			var resolved := (variant as InspectableVariant).to_inspection_dictionary()
			resolved["object_id"] = object_id
			return resolved

	var result := fallback.duplicate()
	if not result.has("object_id"):
		result["object_id"] = object_id
	return result


func resolve_tile_visual(state: CaseState) -> Resource:
	for visual in tile_visuals:
		if not visual is Resource or not visual.has_method("is_available"):
			continue
		var tile_visual := visual as Resource
		if tile_visual.is_available(state):
			return tile_visual
	return null
