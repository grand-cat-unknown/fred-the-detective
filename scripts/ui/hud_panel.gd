class_name HudPanel
extends PanelContainer

signal accuse_pressed

@onready var _status_label: Label = %StatusLabel
@onready var _hint_label: Label = %HintLabel
@onready var _accuse_button: Button = %AccuseButton


func _ready() -> void:
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_accuse_button.pressed.connect(_on_accuse_pressed)


func set_status(text: String) -> void:
	_status_label.text = text


func set_hint(text: String) -> void:
	_hint_label.text = text


func set_accuse_enabled(enabled: bool) -> void:
	_accuse_button.disabled = not enabled


func _on_accuse_pressed() -> void:
	accuse_pressed.emit()
