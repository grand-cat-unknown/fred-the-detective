class_name ConversationEffect
extends Resource

@export var condition: GateCondition
@export var fact_id: StringName
@export var value := true
@export_multiline var description := ""


func is_available(state: CaseState) -> bool:
	return fact_id != &"" and (condition == null or condition.is_met(state))


func to_judge_dictionary() -> Dictionary:
	return {
		"fact_id": str(fact_id),
		"value": value,
		"description": description,
	}
