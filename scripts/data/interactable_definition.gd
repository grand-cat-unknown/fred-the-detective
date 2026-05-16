class_name InteractableDefinition
extends Resource

@export var object_id: StringName
@export var states: Array = []
@export var variants: Array = []
@export var tile_visuals: Array = []


func resolve(state: CaseState, fallback: Dictionary = {}) -> Dictionary:
	for interactable_state in states:
		if interactable_state is Resource and interactable_state.has_method("is_available") and interactable_state.has_method("to_inspection_dictionary") and interactable_state.is_available(state):
			var resolved: Dictionary = interactable_state.to_inspection_dictionary()
			resolved["object_id"] = object_id
			return resolved

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
	for interactable_state in states:
		if interactable_state is Resource and interactable_state.has_method("is_available") and interactable_state.is_available(state):
			return interactable_state if bool(interactable_state.get("update_tile")) else null

	for visual in tile_visuals:
		if not visual is Resource or not visual.has_method("is_available"):
			continue
		var tile_visual := visual as Resource
		if tile_visual.is_available(state):
			return tile_visual
	return null
