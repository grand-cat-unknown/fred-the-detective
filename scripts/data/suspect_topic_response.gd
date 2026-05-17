class_name SuspectTopicResponse
extends Resource

@export var topic_id: StringName
@export var topic_label: String = ""
@export var trigger_phrases: Array[String] = []
@export var states: Array = []


func matches_message(message: String) -> bool:
	var clean_message := message.strip_edges().to_lower()
	if clean_message == "":
		return false
	for phrase in trigger_phrases:
		var clean_phrase := phrase.strip_edges().to_lower()
		if clean_phrase != "" and clean_message.contains(clean_phrase):
			return true
	return false


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
