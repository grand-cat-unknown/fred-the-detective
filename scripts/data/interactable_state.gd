class_name InteractableState
extends Resource

@export var condition: GateCondition

@export_group("Inspection")
@export var title := "Object"
@export_multiline var description := "An ordinary thing. Nothing of note."
@export var effects: Array = []

@export_group("Action")
@export var action_label := ""
@export_multiline var action_prompt := ""
@export var action_effects: Array = []

@export_group("Toast")
@export var toast := ""

@export_group("Tile Visual")
@export var update_tile := false
@export var layer_name := "Doors"
@export var source_id := -1
@export var atlas_coords := Vector2i.ZERO
@export var alternative_tile := 0
@export var erase_tile := false

@export_group("Movement")
@export var update_blocks_movement := false
@export var blocks_movement := true


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)


func to_inspection_dictionary() -> Dictionary:
	return {
		"title": title,
		"description": description,
		"effects": effects,
		"action_label": action_label,
		"action_prompt": action_prompt,
		"action_effects": action_effects,
		"toast": toast,
	}
