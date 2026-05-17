class_name ConversationTopicClassifier
extends Node

signal completed(topic_ids: Array[StringName])
signal failed(message: String)

const NONE_TOPIC_ID := &"none"
const MAX_RECENT_MESSAGES := 8

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


func classify(suspect: SuspectData, latest_player_message: String, recent_messages: Array = []) -> Error:
	if _llm == null:
		return ERR_UNCONFIGURED
	if _llm.is_busy():
		return ERR_BUSY
	if suspect == null or not suspect.has_topic_responses():
		completed.emit([])
		return OK

	var topic_options := suspect.topic_classifier_options()
	if topic_options.is_empty():
		completed.emit([])
		return OK

	_pending_topic_ids.clear()
	for option in topic_options:
		_pending_topic_ids.append(str(option.get("topic_id", "")))
	_pending_topic_ids.append(str(NONE_TOPIC_ID))

	var payload := {
		"active_suspect": str(suspect.id),
		"latest_player_message": latest_player_message,
		"recent_messages": _trim_recent_messages(recent_messages),
		"topic_options": topic_options,
		"none_topic_id": str(NONE_TOPIC_ID),
	}
	var instructions := "\n\n".join([
		"You are a strict topic classifier for the detective game Fred the Detective.",
		"Classify what specific subject Detective Fred is pressing in his latest message.",
		"Use recent_messages only as context for pronouns, follow-ups, and short references. Classify the latest player message, not an older turn.",
		"Return every topic_id from topic_options that Fred is clearly pressing in the latest message.",
		"If the message is small talk, unclear, about another subject, or only loosely related to all options, return an empty topic_ids array.",
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


func _trim_recent_messages(recent_messages: Variant) -> Array:
	if typeof(recent_messages) != TYPE_ARRAY:
		return []
	var messages: Array = recent_messages
	if messages.size() <= MAX_RECENT_MESSAGES:
		return messages
	return messages.slice(messages.size() - MAX_RECENT_MESSAGES)


func _build_text_format() -> Dictionary:
	return {
		"type": "json_schema",
		"name": "conversation_topics",
		"description": "The suspect topics Detective Fred is clearly pressing.",
		"strict": true,
		"schema": {
			"type": "object",
			"additionalProperties": false,
			"properties": {
				"topic_ids": {
					"type": "array",
					"items": {
						"type": "string",
						"enum": _pending_topic_ids,
					},
				},
			},
			"required": ["topic_ids"],
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

	var topic_ids: Array[StringName] = []
	var raw_topic_ids: Variant = (parsed as Dictionary).get("topic_ids", [])
	if typeof(raw_topic_ids) == TYPE_ARRAY:
		for raw_topic_id in raw_topic_ids:
			var topic_id := str(raw_topic_id)
			if topic_id == str(NONE_TOPIC_ID):
				continue
			if _pending_topic_ids.has(topic_id) and not topic_ids.has(StringName(topic_id)):
				topic_ids.append(StringName(topic_id))
	_pending_topic_ids.clear()
	completed.emit(topic_ids)
