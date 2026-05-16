class_name InspectableVariant
extends Resource

@export var condition: GateCondition
@export var title := "Object"
@export_multiline var description := "An ordinary thing. Nothing of note."
@export var effects: Array = []
@export var action_label := ""
@export_multiline var action_prompt := ""
@export var action_effects: Array = []
@export var toast := ""


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
