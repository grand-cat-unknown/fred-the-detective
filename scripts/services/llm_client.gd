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


func _init(http: HTTPRequest = null) -> void:
	_http = http


func _ready() -> void:
	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)
	if not _http.request_completed.is_connected(_on_request_completed):
		_http.request_completed.connect(_on_request_completed)


func is_busy() -> bool:
	return _kind != GameEnums.RequestKind.NONE


func request_dialogue(suspect_id: StringName, prompt_input: String, instructions: String) -> bool:
	if is_busy():
		return false
	_kind = GameEnums.RequestKind.DIALOGUE
	_pending_suspect_id = suspect_id
	_pending_clue_id = &""
	_pending_explanation = ""
	if not _send(prompt_input, instructions):
		var sid := suspect_id
		_clear_pending()
		dialogue_failed.emit(sid, "Could not reach /api/llm.")
		return false
	return true


func request_accusation(
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
	prompt_input: String,
	instructions: String,
) -> bool:
	if is_busy():
		return false
	_kind = GameEnums.RequestKind.ACCUSATION
	_pending_suspect_id = suspect_id
	_pending_clue_id = clue_id
	_pending_explanation = explanation
	if not _send(prompt_input, instructions):
		var sid := suspect_id
		var cid := clue_id
		var exp := explanation
		_clear_pending()
		accusation_failed.emit("The verifier could not be reached, so Fred checked the theory against the case board.", sid, cid, exp)
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
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_failure(kind, "The connection failed.", suspect_id, clue_id, explanation)
		return

	var parsed := _parse_response_body(body)

	if response_code != 200:
		var error_text := _extract_error(parsed)
		_emit_failure(kind, error_text, suspect_id, clue_id, explanation)
		return

	var reply: String = str(parsed.get("text", "")).strip_edges()
	if kind == GameEnums.RequestKind.DIALOGUE:
		dialogue_completed.emit(suspect_id, reply)
	elif kind == GameEnums.RequestKind.ACCUSATION:
		accusation_completed.emit(reply, suspect_id, clue_id, explanation)


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


static func _parse_response_body(body: PackedByteArray) -> Dictionary:
	var raw := JSON.parse_string(body.get_string_from_utf8())
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return raw


static func _extract_error(parsed: Dictionary) -> String:
	if parsed.has("error"):
		return str(parsed["error"])
	return "The line went dead."
