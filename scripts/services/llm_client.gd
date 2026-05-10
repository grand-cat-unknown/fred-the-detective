class_name LLMClient
extends Node

signal dialogue_completed(suspect_id: StringName, reply: String)
signal dialogue_failed(suspect_id: StringName, reason: String)
signal accusation_completed(verdict_text: String, suspect_id: StringName, clue_id: StringName, explanation: String)
signal accusation_failed(reason: String, suspect_id: StringName, clue_id: StringName, explanation: String)

const _CONTENT_TYPE_HEADERS := PackedStringArray(["Content-Type: application/json"])

var _http: HTTPRequest
var _kind: GameEnums.RequestKind = GameEnums.RequestKind.NONE
var _pending_suspect_id: StringName = &""
var _pending_clue_id: StringName = &""
var _pending_explanation: String = ""
var _queue: Array[Dictionary] = []


func _init(http: HTTPRequest = null) -> void:
	_http = http


func _ready() -> void:
	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)
	if not _http.request_completed.is_connected(_on_request_completed):
		_http.request_completed.connect(_on_request_completed)


func is_busy() -> bool:
	return _kind != GameEnums.RequestKind.NONE or not _queue.is_empty()


func request_dialogue(suspect_id: StringName, prompt_input: String, instructions: String) -> bool:
	var entry := {
		"kind": GameEnums.RequestKind.DIALOGUE,
		"suspect_id": suspect_id,
		"clue_id": &"",
		"explanation": "",
		"prompt_input": prompt_input,
		"instructions": instructions,
	}
	return _enqueue_or_start(entry)


func request_accusation(
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
	prompt_input: String,
	instructions: String,
) -> bool:
	var entry := {
		"kind": GameEnums.RequestKind.ACCUSATION,
		"suspect_id": suspect_id,
		"clue_id": clue_id,
		"explanation": explanation,
		"prompt_input": prompt_input,
		"instructions": instructions,
	}
	return _enqueue_or_start(entry)


func _enqueue_or_start(entry: Dictionary) -> bool:
	if _kind != GameEnums.RequestKind.NONE:
		_queue.append(entry)
		return true
	return _start_request(entry)


func _start_request(entry: Dictionary) -> bool:
	_kind = int(entry["kind"])
	_pending_suspect_id = StringName(entry["suspect_id"])
	_pending_clue_id = StringName(entry["clue_id"])
	_pending_explanation = str(entry["explanation"])
	if not _send(str(entry["prompt_input"]), str(entry["instructions"])):
		var failed_kind := _kind
		var sid := _pending_suspect_id
		var cid := _pending_clue_id
		var exp := _pending_explanation
		_clear_pending()
		_emit_failure(failed_kind, _start_failure_message(failed_kind), sid, cid, exp)
		_start_next_request()
		return false
	return true


func _send(prompt_input: String, instructions: String) -> bool:
	var payload := JSON.stringify({
		"input": prompt_input,
		"instructions": instructions,
		"max_output_tokens": Gameplay.LLM_MAX_OUTPUT_TOKENS,
	})
	var error := _http.request(_endpoint(), _CONTENT_TYPE_HEADERS, HTTPClient.METHOD_POST, payload)
	return error == OK


func _endpoint() -> String:
	if not OS.has_feature("web"):
		return Gameplay.LLM_LOCAL_ENDPOINT
	if not Engine.has_singleton("JavaScriptBridge"):
		return Gameplay.LLM_LOCAL_ENDPOINT
	var origin := str(JavaScriptBridge.eval("window.location.origin", true)).strip_edges()
	if origin.is_empty() or origin == "null":
		return Gameplay.LLM_LOCAL_ENDPOINT
	return "%s/api/llm" % origin.trim_suffix("/")


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
) -> void:
	var kind := _kind
	var suspect_id := _pending_suspect_id
	var clue_id := _pending_clue_id
	var explanation := _pending_explanation
	_clear_pending()

	if kind == GameEnums.RequestKind.NONE:
		_start_next_request()
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_failure(kind, "The connection failed.", suspect_id, clue_id, explanation)
		_start_next_request()
		return

	var parsed := _parse_response_body(body)

	if response_code != 200:
		var error_text := _extract_error(parsed)
		_emit_failure(kind, error_text, suspect_id, clue_id, explanation)
		_start_next_request()
		return

	var reply: String = str(parsed.get("text", "")).strip_edges()
	if kind == GameEnums.RequestKind.DIALOGUE:
		dialogue_completed.emit(suspect_id, reply)
	elif kind == GameEnums.RequestKind.ACCUSATION:
		accusation_completed.emit(reply, suspect_id, clue_id, explanation)
	_start_next_request()


func _emit_failure(
	kind: GameEnums.RequestKind,
	reason: String,
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
) -> void:
	if kind == GameEnums.RequestKind.DIALOGUE:
		dialogue_failed.emit(suspect_id, reason)
	elif kind == GameEnums.RequestKind.ACCUSATION:
		accusation_failed.emit(reason, suspect_id, clue_id, explanation)


func _clear_pending() -> void:
	_kind = GameEnums.RequestKind.NONE
	_pending_suspect_id = &""
	_pending_clue_id = &""
	_pending_explanation = ""


func _start_next_request() -> void:
	if _kind != GameEnums.RequestKind.NONE or _queue.is_empty():
		return
	var next: Dictionary = _queue.pop_front()
	_start_request(next)


static func _start_failure_message(kind: GameEnums.RequestKind) -> String:
	if kind == GameEnums.RequestKind.ACCUSATION:
		return "The verifier could not be reached, so Fred checked the theory against the case board."
	return "Could not reach /api/llm."


static func _parse_response_body(body: PackedByteArray) -> Dictionary:
	var raw := JSON.parse_string(body.get_string_from_utf8())
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


static func _extract_error(parsed: Dictionary) -> String:
	if parsed.has("error"):
		return str(parsed["error"])
	return "The line went dead."
