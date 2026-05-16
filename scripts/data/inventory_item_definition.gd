class_name InventoryItemDefinition
extends Resource

@export var item_id: StringName
@export var states: Array = []


func resolve(state: CaseState) -> Dictionary:
	for item_state in states:
		if item_state is Resource and item_state.has_method("is_available") and item_state.has_method("to_dictionary") and item_state.is_available(state):
			var resolved: Dictionary = item_state.to_dictionary()
			resolved["item_id"] = item_id
			return resolved
	return {}
