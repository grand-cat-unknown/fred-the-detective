class_name InteractableDefinition
extends Resource

@export var object_id: StringName
@export var variants: Array = []


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
