class_name ConversationTopicClassifier
extends Node

signal completed(topic_id: StringName)
signal failed(message: String)

const NONE_TOPIC_ID := &"none"

var _llm: LLMClient
var _pending_topic_ids: Array[String] = []


func configure(llm: LLMClient) -> void:
	if _llm != null and _llm.completed.is_connected(_on_llm_completed):
		_llm.completed.disconnect(_on_llm_completed)
	_llm = llm
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)


func is_busy() -> bool:
	return _llm != null and _llm.is_busy()


func classify(suspect: SuspectData, latest_player_message: String) -> Error:
	if _llm == null:
		return ERR_UNCONFIGURED
	if _llm.is_busy():
		return ERR_BUSY
	if suspect == null or not suspect.has_topic_responses():
		completed.emit(&"")
		return OK

	var topic_options := suspect.topic_classifier_options()
	if topic_options.is_empty():
		completed.emit(&"")
		return OK

	_pending_topic_ids.clear()
	for option in topic_options:
		_pending_topic_ids.append(str(option.get("topic_id", "")))
	_pending_topic_ids.append(str(NONE_TOPIC_ID))

	var payload := {
		"active_suspect": str(suspect.id),
		"latest_player_message": latest_player_message,
		"topic_options": topic_options,
		"none_topic_id": str(NONE_TOPIC_ID),
	}
	var instructions := "\n\n".join([
		"You are a strict topic classifier for the detective game Fred the Detective.",
		"Classify what specific subject Detective Fred is pressing in his latest message.",
		"Choose exactly one topic_id from topic_options only when Fred is clearly pressing that topic.",
		"If the message is small talk, unclear, about another subject, or only loosely related, choose none.",
		"Use the structured output schema. Do not invent topic ids.",
	])
	var messages := [
		{
			"role": "user",
			"content": JSON.stringify(payload, "\t"),
		}
	]
	var err := _llm.send(instructions, messages, _build_text_format())
	if err != OK:
		_pending_topic_ids.clear()
	return err


func _build_text_format() -> Dictionary:
	return {
		"type": "json_schema",
		"name": "conversation_topic",
		"description": "The specific suspect topic Detective Fred is pressing, or none.",
		"strict": true,
		"schema": {
			"type": "object",
			"additionalProperties": false,
			"properties": {
				"topic_id": {
					"type": "string",
					"enum": _pending_topic_ids,
				},
			},
			"required": ["topic_id"],
		},
	}


func _on_llm_completed(text: String, error: String) -> void:
	if error != "":
		_pending_topic_ids.clear()
		failed.emit(error)
		return

	var parsed: Variant = JSON.parse_string(text.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		_pending_topic_ids.clear()
		failed.emit("Conversation topic classifier returned invalid structured output.")
		return

	var topic_id := str((parsed as Dictionary).get("topic_id", str(NONE_TOPIC_ID)))
	if not _pending_topic_ids.has(topic_id):
		topic_id = str(NONE_TOPIC_ID)
	_pending_topic_ids.clear()
	if topic_id == str(NONE_TOPIC_ID):
		completed.emit(&"")
	else:
		completed.emit(StringName(topic_id))
