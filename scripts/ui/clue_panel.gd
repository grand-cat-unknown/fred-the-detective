class_name CluePanel
extends PanelContainer

signal closed

@onready var _title_label: Label = %ClueTitleLabel
@onready var _body_label: RichTextLabel = %ClueBodyLabel
@onready var _close_button: Button = %ClueCloseButton


func _ready() -> void:
	_body_label.bbcode_enabled = false
	_body_label.fit_content = true
	_close_button.pressed.connect(_on_close_pressed)


func open(title: String, body: String) -> void:
	_title_label.text = title
	_body_label.clear()
	_body_label.append_text(body)
	visible = true


func close() -> void:
	visible = false


func _on_close_pressed() -> void:
	closed.emit()
