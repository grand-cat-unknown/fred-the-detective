class_name DialogueService
extends Node

signal line_appended(speaker: String, text: String)
signal line_updated(text: String)
signal busy_changed(is_busy: bool)
signal error_received(message: String)

const DETECTIVE_LABEL := "Fred"
const MAX_HISTORY_LINES := 40

var _llm: LLMClient
var _active_suspect: SuspectData
var _history: Dictionary = {}  # StringName id -> Array[Dictionary]
var _streaming_suspect_id: StringName = &""
var _streaming_text := ""


func configure(llm: LLMClient) -> void:
	if _llm != null:
		if _llm.completed.is_connected(_on_llm_completed):
			_llm.completed.disconnect(_on_llm_completed)
		if _llm.delta_received.is_connected(_on_llm_delta):
			_llm.delta_received.disconnect(_on_llm_delta)
	_llm = llm
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)
		_llm.delta_received.connect(_on_llm_delta)


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
	_streaming_suspect_id = _active_suspect.id
	_streaming_text = ""
	_append(_active_suspect.id, _active_suspect.display_name, "")
	busy_changed.emit(true)
	return true


func reset() -> void:
	_history.clear()
	_active_suspect = null
	_streaming_suspect_id = &""
	_streaming_text = ""


func _append(suspect_id: StringName, speaker: String, text: String) -> void:
	var lines: Array = _history.get(suspect_id, [])
	lines.append({"speaker": speaker, "text": text})
	while lines.size() > MAX_HISTORY_LINES:
		lines.pop_front()
	_history[suspect_id] = lines
	line_appended.emit(speaker, text)


func _update_last_line(suspect_id: StringName, text: String) -> void:
	var lines: Array = _history.get(suspect_id, [])
	if lines.is_empty():
		return
	lines[lines.size() - 1]["text"] = text
	_history[suspect_id] = lines


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
		var speaker := str(entry.get("speaker", ""))
		var text := str(entry.get("text", ""))
		if speaker == suspect.display_name and text.strip_edges().is_empty():
			continue
		transcript.append("%s: %s" % [speaker, text])
	transcript.append("%s:" % suspect.display_name)
	return "Conversation so far:\n" + "\n".join(transcript)


func _on_llm_delta(chunk: String) -> void:
	if _streaming_suspect_id == &"":
		print("[DialogueService] delta ignored: no streaming suspect")
		return
	_streaming_text += chunk
	_update_last_line(_streaming_suspect_id, _streaming_text)
	var emitting := _active_suspect != null and _active_suspect.id == _streaming_suspect_id
	print("[DialogueService] delta chars=%d total=%d emit=%s" % [chunk.length(), _streaming_text.length(), str(emitting)])
	if emitting:
		line_updated.emit(_streaming_text)


func _on_llm_completed(text: String, error: String) -> void:
	busy_changed.emit(false)
	var suspect_id := _streaming_suspect_id
	var accumulated := _streaming_text
	_streaming_suspect_id = &""
	_streaming_text = ""
	if error != "":
		if suspect_id != &"":
			_update_last_line(suspect_id, accumulated)
		error_received.emit(error)
		return
	var final_text := text.strip_edges()
	if final_text.is_empty():
		final_text = accumulated.strip_edges()
	if final_text.is_empty():
		error_received.emit("(no response)")
		return
	if suspect_id != &"":
		_update_last_line(suspect_id, final_text)
		if _active_suspect != null and _active_suspect.id == suspect_id:
			line_updated.emit(final_text)
