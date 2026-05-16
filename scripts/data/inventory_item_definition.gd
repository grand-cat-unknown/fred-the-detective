class_name InventoryItemDefinition
extends Resource

@export var item_id: StringName
@export var states: Array = []

@export_group("Compatibility")
@export var fact_id: StringName
@export var label := "Item"

@export_group("Tile Icon")
@export var layer_name := "Props"
@export var source_id := -1
@export var atlas_coords := Vector2i.ZERO
@export var alternative_tile := 0


func resolve(state: CaseState) -> Dictionary:
	for item_state in states:
		if item_state is Resource and item_state.has_method("is_available") and item_state.has_method("to_inventory_dictionary") and item_state.is_available(state):
			var resolved: Dictionary = item_state.to_inventory_dictionary()
			resolved["item_id"] = item_id
			return resolved

	if fact_id != &"" and state != null and state.get_fact(fact_id):
		return {
			"visible": true,
			"item_id": item_id,
			"label": label,
			"layer_name": layer_name,
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile,
		}

	return {
		"visible": false,
		"item_id": item_id,
	}
