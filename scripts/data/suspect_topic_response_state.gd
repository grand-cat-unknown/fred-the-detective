class_name SuspectTopicResponseState
extends Resource

@export var condition: GateCondition
@export_multiline var response_instruction: String = ""
@export var effect_allowed: StringName = &""


func is_available(state: CaseState) -> bool:
	return condition == null or condition.is_met(state)


func instruction_text() -> String:
	var parts: Array[String] = []
	var clean_response := response_instruction.strip_edges()
	if clean_response != "":
		parts.append("Answer instruction: %s" % clean_response)
	if effect_allowed != &"":
		parts.append("This response may allow the conversation effect: %s." % str(effect_allowed))
	return "\n".join(parts)
