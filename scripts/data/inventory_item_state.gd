class_name InventoryItemState
extends Resource

@export var condition: GateCondition

@export_group("Display")
@export var visible := true
@export var label := "Item"

@export_group("Tile Icon")
@export var layer_name := "Props"
@export var source_id := -1
@export var atlas_coords := Vector2i.ZERO
@export var alternative_tile := 0


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)


func to_inventory_dictionary() -> Dictionary:
	return {
		"visible": visible,
		"label": label,
		"layer_name": layer_name,
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_tile": alternative_tile,
	}
