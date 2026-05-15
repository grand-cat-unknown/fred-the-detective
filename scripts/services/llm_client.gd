class_name LLMClient
extends Node

signal delta_received(chunk: String)
signal completed(text: String, error: String)

const LOCAL_ENDPOINT := "http://127.0.0.1:3000/api/llm"
const MAX_OUTPUT_TOKENS := 2000

const _WEB_BRIDGE_JS := """
window.fredLLMStream = async function(url, body, cb) {
	try {
		const r = await fetch(url, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json', 'Accept': 'application/x-ndjson' },
			body: body,
			credentials: 'include',
		});
		if (!r.ok || !r.body) {
			let msg = 'HTTP ' + r.status;
			try { const j = await r.json(); if (j && j.error) msg = j.error; } catch (_) {}
			cb('error', msg);
			return;
		}
		const reader = r.body.getReader();
		const dec = new TextDecoder();
		let buf = '';
		let full = '';
		while (true) {
			const { value, done } = await reader.read();
			if (done) break;
			buf += dec.decode(value, { stream: true });
			let idx;
			while ((idx = buf.indexOf('\\n')) !== -1) {
				const line = buf.slice(0, idx);
				buf = buf.slice(idx + 1);
				if (!line) continue;
				let obj;
				try { obj = JSON.parse(line); } catch (_) { continue; }
				if (typeof obj.delta === 'string') {
					full += obj.delta;
					cb('delta', obj.delta);
				} else if (typeof obj.error === 'string') {
					cb('error', obj.error);
					return;
				} else if (obj.done) {
					cb('done', typeof obj.text === 'string' ? obj.text : full);
					return;
				}
			}
		}
		cb('done', full);
	} catch (e) {
		cb('error', String(e && e.message ? e.message : e));
	}
};
"""

var _in_flight := false
var _request_started_msec: int = 0
var _delta_count: int = 0

# Web path
var _web_ready := false
var _js_callback: JavaScriptObject
var _web_full_text := ""

# Native path
var _http_client: HTTPClient
var _native_request: Dictionary = {}


func is_busy() -> bool:
	return _in_flight


func send(instructions: String, messages: Array, text_format: Dictionary = {}, max_output_tokens := MAX_OUTPUT_TOKENS) -> Error:
	if _in_flight:
		return ERR_BUSY
	var payload := {
		"instructions": instructions,
		"messages": messages,
		"max_output_tokens": max_output_tokens,
	}
	if not text_format.is_empty():
		payload["text_format"] = text_format
	var body := JSON.stringify(payload)
	_request_started_msec = Time.get_ticks_msec()
	_delta_count = 0
	if _use_web_bridge():
		return _send_web(body)
	return _send_native(body)


func _elapsed_ms() -> int:
	return Time.get_ticks_msec() - _request_started_msec


func _use_web_bridge() -> bool:
	return OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge")


func _endpoint() -> String:
	if not OS.has_feature("web"):
		return LOCAL_ENDPOINT
	if not Engine.has_singleton("JavaScriptBridge"):
		return LOCAL_ENDPOINT
	var origin := str(JavaScriptBridge.eval("window.location.origin", true)).strip_edges()
	if origin.is_empty() or origin == "null":
		return LOCAL_ENDPOINT
	return "%s/api/llm" % origin.trim_suffix("/")


# ---------- Web streaming via fetch + ReadableStream ----------

func _send_web(body: String) -> Error:
	if not _web_ready:
		JavaScriptBridge.eval(_WEB_BRIDGE_JS, true)
		_js_callback = JavaScriptBridge.create_callback(_on_web_event)
		_web_ready = true
	_web_full_text = ""
	_in_flight = true
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	window.fredLLMStream(_endpoint(), body, _js_callback)
	return OK


func _on_web_event(args: Array) -> void:
	if args.size() < 2:
		return
	var kind := str(args[0])
	var text := str(args[1])
	match kind:
		"delta":
			_delta_count += 1
			_web_full_text += text
			delta_received.emit(text)
		"done":
			_in_flight = false
			var final_text := text if text != "" else _web_full_text
			completed.emit(final_text.strip_edges(), "")
		"error":
			_in_flight = false
			completed.emit("", text if text != "" else "Stream failed.")


# ---------- Native streaming via HTTPClient ----------

func _send_native(body: String) -> Error:
	var endpoint := _endpoint()
	var url := endpoint
	var scheme := "http"
	var host := "127.0.0.1"
	var port := 80
	var path := "/api/llm"
	if url.begins_with("https://"):
		scheme = "https"
		port = 443
		url = url.substr(8)
	elif url.begins_with("http://"):
		url = url.substr(7)
	var slash := url.find("/")
	var authority := url if slash == -1 else url.substr(0, slash)
	path = "/api/llm" if slash == -1 else url.substr(slash)
	var colon := authority.find(":")
	if colon == -1:
		host = authority
	else:
		host = authority.substr(0, colon)
		port = int(authority.substr(colon + 1))
	_http_client = HTTPClient.new()
	var err := _http_client.connect_to_host(host, port, TLSOptions.client() if scheme == "https" else null)
	if err != OK:
		return err
	_native_request = {
		"state": "connecting",
		"path": path,
		"body": body,
		"buffer": PackedByteArray(),
		"full_text": "",
	}
	_in_flight = true
	set_process(true)
	return OK


func _process(_delta: float) -> void:
	if not _in_flight or _http_client == null:
		set_process(false)
		return
	_http_client.poll()
	var status := _http_client.get_status()
	match status:
		HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING:
			return
		HTTPClient.STATUS_CONNECTED:
			if _native_request.get("state", "") == "connecting":
				var headers := PackedStringArray([
					"Content-Type: application/json",
					"Accept: application/x-ndjson",
				])
				var err := _http_client.request(HTTPClient.METHOD_POST, _native_request["path"], headers, _native_request["body"])
				if err != OK:
					_finish_native_error("Request failed (%s)." % err)
					return
				_native_request["state"] = "requesting"
		HTTPClient.STATUS_REQUESTING:
			return
		HTTPClient.STATUS_BODY:
			if _http_client.get_response_code() != 200:
				_drain_native_error_body()
				return
			var chunk := _http_client.read_response_body_chunk()
			if chunk.size() > 0:
				_native_request["buffer"].append_array(chunk)
				_consume_native_buffer()
		HTTPClient.STATUS_DISCONNECTED, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CANT_RESOLVE:
			_finish_native_error("Connection failed.")


func _consume_native_buffer() -> void:
	var buffer: PackedByteArray = _native_request["buffer"]
	while true:
		var newline_index := -1
		for i in range(buffer.size()):
			if buffer[i] == 10:
				newline_index = i
				break
		if newline_index == -1:
			break
		var line_bytes := buffer.slice(0, newline_index)
		buffer = buffer.slice(newline_index + 1)
		_native_request["buffer"] = buffer
		var line := line_bytes.get_string_from_utf8().strip_edges()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		if parsed.has("delta"):
			var chunk := str(parsed["delta"])
			_delta_count += 1
			_native_request["full_text"] = str(_native_request["full_text"]) + chunk
			delta_received.emit(chunk)
		elif parsed.has("error"):
			_finish_native_error(str(parsed["error"]))
			return
		elif parsed.has("done"):
			var final_text := str(parsed.get("text", _native_request["full_text"])).strip_edges()
			_finish_native_success(final_text)
			return


func _drain_native_error_body() -> void:
	var buf := PackedByteArray()
	while _http_client.get_status() == HTTPClient.STATUS_BODY:
		_http_client.poll()
		var chunk := _http_client.read_response_body_chunk()
		if chunk.size() == 0:
			break
		buf.append_array(chunk)
	var text := buf.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	var msg := "HTTP %d" % _http_client.get_response_code()
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error"):
		msg = str(parsed["error"])
	_finish_native_error(msg)


func _finish_native_success(text: String) -> void:
	_in_flight = false
	set_process(false)
	if _http_client != null:
		_http_client.close()
	_http_client = null
	completed.emit(text, "")


func _finish_native_error(message: String) -> void:
	_in_flight = false
	set_process(false)
	if _http_client != null:
		_http_client.close()
	_http_client = null
	completed.emit("", message)
