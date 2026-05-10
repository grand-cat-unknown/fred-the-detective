class_name ResultPanel
extends PanelContainer

signal restart_pressed

@onready var _result_label: RichTextLabel = %ResultLabel
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_result_label.bbcode_enabled = false
	_result_label.fit_content = true
	_restart_button.pressed.connect(_on_restart_pressed)


func open(text: String) -> void:
	_result_label.clear()
	_result_label.append_text(text)
	visible = true


func close() -> void:
	visible = false


func _on_restart_pressed() -> void:
	restart_pressed.emit()
