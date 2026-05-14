class_name LLMClient
extends Node

signal completed(text: String, error: String)

const ENDPOINT := "/api/llm"
const MAX_OUTPUT_TOKENS := 400

var _http: HTTPRequest
var _in_flight := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.use_threads = false
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


func is_busy() -> bool:
	return _in_flight


func send(instructions: String, input: String) -> Error:
	if _in_flight:
		return ERR_BUSY
	var payload := {
		"instructions": instructions,
		"input": input,
		"max_output_tokens": MAX_OUTPUT_TOKENS,
	}
	var body := JSON.stringify(payload)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if err == OK:
		_in_flight = true
	return err


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_in_flight = false
	var text := body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if response_code != 200:
		var msg := "HTTP %d" % response_code
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error"):
			msg = str(parsed["error"])
		completed.emit("", msg)
		return
	if typeof(parsed) != TYPE_DICTIONARY:
		completed.emit("", "Malformed response")
		return
	completed.emit(str(parsed.get("text", "")).strip_edges(), "")
