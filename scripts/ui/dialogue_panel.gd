class_name DialoguePanel
extends PanelContainer

signal submitted(text: String)
signal closed

@onready var _title_label: Label = %DialogueTitleLabel
@onready var _status_label: Label = %DialogueStatusLabel
@onready var _output: RichTextLabel = %DialogueOutput
@onready var _input: LineEdit = %DialogueInput
@onready var _send_button: Button = %SendButton
@onready var _close_button: Button = %DialogueCloseButton


func _ready() -> void:
	_output.bbcode_enabled = false
	_output.scroll_following = true
	_input.text_submitted.connect(_on_text_submitted)
	_send_button.pressed.connect(_emit_submission)
	_close_button.pressed.connect(_on_close_pressed)


func open(title: String, lines: Array) -> void:
	_title_label.text = title
	set_lines(lines)
	set_busy(false, "")
	visible = true
	_input.grab_focus()


func close() -> void:
	visible = false
	_input.clear()


func set_lines(lines: Array) -> void:
	_output.clear()
	if lines.size() > 0:
		_output.append_text("\n\n".join(lines))
		_output.scroll_to_line(max(0, _output.get_line_count() - 1))


func set_busy(is_busy: bool, status_text: String) -> void:
	_input.editable = not is_busy
	_send_button.disabled = is_busy
	_status_label.visible = not status_text.is_empty()
	_status_label.text = status_text
	if not is_busy and visible:
		_input.grab_focus()


func clear_input() -> void:
	_input.clear()


func focus_input() -> void:
	if visible:
		_input.grab_focus()


func _on_text_submitted(_text: String) -> void:
	_emit_submission()


func _emit_submission() -> void:
	submitted.emit(_input.text)


func _on_close_pressed() -> void:
	closed.emit()
