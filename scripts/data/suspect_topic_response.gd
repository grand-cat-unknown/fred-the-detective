class_name SuspectTopicResponse
extends Resource

@export var topic_id: StringName
@export var topic_label: String = ""
@export_multiline var topic_description: String = ""
@export var states: Array = []


func is_valid() -> bool:
	return topic_id != &"" and not states.is_empty()


func classifier_dictionary() -> Dictionary:
	var label := topic_label.strip_edges()
	if label == "":
		label = str(topic_id)
	return {
		"topic_id": str(topic_id),
		"label": label,
		"description": topic_description.strip_edges(),
	}


func active_state(state: CaseState) -> SuspectTopicResponseState:
	for entry in states:
		if entry is SuspectTopicResponseState and entry.is_available(state):
			return entry as SuspectTopicResponseState
	return null


func active_instruction(state: CaseState) -> String:
	var active := active_state(state)
	if active == null:
		return ""
	var label := topic_label.strip_edges()
	if label == "":
		label = str(topic_id)
	var body := active.instruction_text().strip_edges()
	if body == "":
		return ""
	return "Topic Fred is pressing: %s\n%s" % [label, body]
