class_name InventoryItemState
extends Resource

@export var condition: GateCondition

@export_group("Display")
@export var label := "Item"
@export_multiline var description := ""
@export var icon: Texture2D

@export_group("Action")
@export var action_input: StringName = &""
@export var action_key_hint: String = ""
@export var action_kind: StringName = &""

@export_group("Book")
@export var book_title: String = ""
@export_multiline var book_pages: Array[String] = []


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)


func to_dictionary() -> Dictionary:
	return {
		"label": label,
		"description": description,
		"icon": icon,
		"action_input": action_input,
		"action_key_hint": action_key_hint,
		"action_kind": action_kind,
		"book_title": book_title,
		"book_pages": book_pages,
	}
