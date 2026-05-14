class_name DialogueService
extends Node

signal line_appended(speaker: String, text: String)
signal busy_changed(is_busy: bool)
signal error_received(message: String)

const DETECTIVE_LABEL := "Fred"
const MAX_HISTORY_LINES := 40

var _llm: LLMClient
var _active_suspect: SuspectData
var _history: Dictionary = {}  # StringName id -> Array[Dictionary]


func configure(llm: LLMClient) -> void:
	if _llm != null and _llm.completed.is_connected(_on_llm_completed):
		_llm.completed.disconnect(_on_llm_completed)
	_llm = llm
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)


func open(suspect: SuspectData) -> void:
	_active_suspect = suspect
	if suspect == null:
		return
	if not _history.has(suspect.id):
		_history[suspect.id] = []
		var greeting := suspect.dialogue.strip_edges()
		if greeting != "":
			_append(suspect.id, suspect.display_name, greeting)


func close() -> void:
	_active_suspect = null


func get_lines(suspect_id: StringName) -> Array:
	return _history.get(suspect_id, [])


func active_suspect() -> SuspectData:
	return _active_suspect


func submit(message: String) -> bool:
	if _active_suspect == null or _llm == null:
		return false
	var trimmed := message.strip_edges()
	if trimmed.is_empty() or _llm.is_busy():
		return false
	_append(_active_suspect.id, DETECTIVE_LABEL, trimmed)
	var err := _llm.send(_build_instructions(_active_suspect), _build_input(_active_suspect))
	if err != OK:
		error_received.emit("Could not reach the LLM (%s)." % err)
		return false
	busy_changed.emit(true)
	return true


func reset() -> void:
	_history.clear()
	_active_suspect = null


func _append(suspect_id: StringName, speaker: String, text: String) -> void:
	var lines: Array = _history.get(suspect_id, [])
	lines.append({"speaker": speaker, "text": text})
	while lines.size() > MAX_HISTORY_LINES:
		lines.pop_front()
	_history[suspect_id] = lines
	line_appended.emit(speaker, text)


func _build_instructions(suspect: SuspectData) -> String:
	var parts: Array[String] = []
	parts.append("You are roleplaying a character in the detective game 'Fred the Detective'. The player is Detective Fred, who is interviewing you about the murder of Felix Vance at The Grandview Hotel.")
	if suspect.subtitle != "":
		parts.append("Role: %s" % suspect.subtitle)
	if suspect.persona != "":
		parts.append("Character notes: %s" % suspect.persona)
	if suspect.system_prompt != "":
		parts.append(suspect.system_prompt)
	parts.append("Reply as the character only. Do not narrate actions in brackets. Do not include your name as a prefix. Keep replies under 80 words.")
	return "\n\n".join(parts)


func _build_input(suspect: SuspectData) -> String:
	var lines: Array = _history.get(suspect.id, [])
	var transcript: Array[String] = []
	for entry in lines:
		transcript.append("%s: %s" % [entry["speaker"], entry["text"]])
	transcript.append("%s:" % suspect.display_name)
	return "Conversation so far:\n" + "\n".join(transcript)


func _on_llm_completed(text: String, error: String) -> void:
	busy_changed.emit(false)
	if _active_suspect == null:
		return
	if error != "":
		error_received.emit(error)
		return
	if text.strip_edges().is_empty():
		error_received.emit("(no response)")
		return
	_append(_active_suspect.id, _active_suspect.display_name, text)
