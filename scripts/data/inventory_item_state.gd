class_name InventoryItemState
extends Resource

@export var condition: GateCondition

@export_group("Display")
@export var label := "Item"
@export_multiline var description := ""
@export var icon: Texture2D


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)


func to_dictionary() -> Dictionary:
	return {
		"label": label,
		"description": description,
		"icon": icon,
	}
