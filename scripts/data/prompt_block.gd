class_name PromptBlock
extends Resource

@export var condition: GateCondition
@export_multiline var text := ""


func is_available(state: CaseState) -> bool:
	return text.strip_edges() != "" and (condition == null or condition.is_met(state))
