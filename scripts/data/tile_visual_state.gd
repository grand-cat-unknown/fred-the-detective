class_name TileVisualState
extends Resource

@export var condition: GateCondition
@export var layer_name := "Doors"
@export var source_id := -1
@export var atlas_coords := Vector2i.ZERO
@export var alternative_tile := 0
@export var erase_tile := false
@export var update_blocks_movement := false
@export var blocks_movement := true


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)
