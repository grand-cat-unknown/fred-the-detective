class_name DialoguePanel
extends CanvasLayer

signal submitted(message: String)
signal closed

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Margin/VBox/Header/Title
@onready var _subtitle_label: Label = $Root/Panel/Margin/VBox/Header/Subtitle
@onready var _scroll: ScrollContainer = $Root/Panel/Margin/VBox/Scroll
@onready var _lines_box: VBoxContainer = $Root/Panel/Margin/VBox/Scroll/Lines
@onready var _status_label: Label = $Root/Panel/Margin/VBox/Status
@onready var _input_field: LineEdit = $Root/Panel/Margin/VBox/InputRow/Input
@onready var _send_button: Button = $Root/Panel/Margin/VBox/InputRow/Send

const COLOR_DETECTIVE := Color(0.78, 0.92, 1.0)
const COLOR_NPC := Color(0.98, 0.88, 0.7)
const COLOR_SYSTEM := Color(0.7, 0.7, 0.65)


func _ready() -> void:
	_root.visible = false
	_input_field.text_submitted.connect(_on_text_submitted)
	_send_button.pressed.connect(_on_send_pressed)


func open(title: String, subtitle: String, lines: Array) -> void:
	_title_label.text = title
	_subtitle_label.text = subtitle
	_clear_lines()
	for entry in lines:
		_append_line_view(entry.get("speaker", ""), entry.get("text", ""))
	_status_label.text = "Press Esc to leave the conversation."
	_input_field.text = ""
	_root.visible = true
	_input_field.editable = true
	_send_button.disabled = false
	_input_field.grab_focus()
	_scroll_to_bottom()


func is_open() -> bool:
	return _root.visible


func close() -> void:
	_root.visible = false
	_input_field.release_focus()


func append_line(speaker: String, text: String) -> void:
	_append_line_view(speaker, text)
	_scroll_to_bottom()


func update_last_line(text: String) -> void:
	var last := _last_line_label()
	if last == null:
		print("[DialoguePanel] update_last_line: no label found")
		return
	var speaker := str(last.get_meta("speaker", ""))
	last.text = _format_line(speaker, text)
	print("[DialoguePanel] update_last_line speaker=%s len=%d" % [speaker, text.length()])
	_scroll_to_bottom()


func set_busy(busy: bool, status: String = "") -> void:
	_input_field.editable = not busy
	_send_button.disabled = busy
	if busy:
		_status_label.text = status if status != "" else "Waiting for a reply..."
	else:
		_status_label.text = "Press Esc to leave the conversation."
		_input_field.grab_focus()


func show_error(message: String) -> void:
	_status_label.text = message


func clear_input() -> void:
	_input_field.text = ""


func handle_input_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		close()
		closed.emit()
		return true
	return false


func _on_text_submitted(text: String) -> void:
	_emit_submission(text)


func _on_send_pressed() -> void:
	_emit_submission(_input_field.text)


func _emit_submission(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	submitted.emit(trimmed)


func _clear_lines() -> void:
	for child in _lines_box.get_children():
		child.queue_free()


func _append_line_view(speaker: String, text: String) -> void:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var color := COLOR_NPC
	if speaker == DialogueService.DETECTIVE_LABEL:
		color = COLOR_DETECTIVE
	elif speaker == "":
		color = COLOR_SYSTEM
	label.add_theme_color_override("font_color", color)
	label.set_meta("speaker", speaker)
	label.text = _format_line(speaker, text)
	_lines_box.add_child(label)


func _format_line(speaker: String, text: String) -> String:
	if text == "":
		return "..."
	if speaker == "":
		return text
	return _strip_outer_quotes(_strip_speaker_prefix(speaker, text))


func _strip_speaker_prefix(speaker: String, text: String) -> String:
	var trimmed := text.strip_edges()
	var colon_index := trimmed.find(":")
	if colon_index <= 0 or colon_index > 32:
		return trimmed
	var prefix := trimmed.substr(0, colon_index).strip_edges()
	for alias in _speaker_aliases(speaker):
		if prefix == alias:
			return trimmed.substr(colon_index + 1).strip_edges()
	return trimmed


func _speaker_aliases(speaker: String) -> Array[String]:
	var aliases: Array[String] = [speaker]
	var normalized := speaker.replace("\"", " ").replace("Dr.", " ").replace(".", " ")
	for token in normalized.split(" ", false):
		var alias := token.strip_edges()
		if alias != "" and not aliases.has(alias):
			aliases.append(alias)
	return aliases


func _strip_outer_quotes(text: String) -> String:
	var trimmed := text.strip_edges()
	if trimmed.length() >= 2 and trimmed.begins_with("\"") and trimmed.ends_with("\""):
		return trimmed.substr(1, trimmed.length() - 2).strip_edges()
	return trimmed


func _last_line_label() -> Label:
	var children := _lines_box.get_children()
	for i in range(children.size() - 1, -1, -1):
		var child = children[i]
		if child is Label:
			return child as Label
	return null


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
