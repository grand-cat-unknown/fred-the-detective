class_name InspectPanel
extends CanvasLayer

signal action_confirmed(effects: Array)

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var _description_label: Label = $Root/Panel/Margin/VBox/Description
@onready var _hint_label: Label = $Root/Panel/Margin/VBox/Hint
@onready var _action_row: HBoxContainer = $Root/Panel/Margin/VBox/ActionRow
@onready var _yes_button: Button = $Root/Panel/Margin/VBox/ActionRow/YesButton
@onready var _no_button: Button = $Root/Panel/Margin/VBox/ActionRow/NoButton

var _action_effects: Array = []
var _has_action := false


func _ready() -> void:
	_root.visible = false
	_action_row.visible = false
	_yes_button.pressed.connect(_confirm_action)
	_no_button.pressed.connect(hide_panel)


func show_inspectable(inspectable: Inspectable) -> void:
	show_text(inspectable.title, inspectable.description)


func show_text(title: String, description: String) -> void:
	_has_action = false
	_action_effects = []
	_title_label.text = title
	_description_label.text = description
	_hint_label.text = "Press Space to close"
	_action_row.visible = false
	_root.visible = true


func show_action(title: String, description: String, action_label: String, action_prompt: String, effects: Array) -> void:
	_has_action = true
	_action_effects = effects
	_title_label.text = title
	_description_label.text = action_prompt if action_prompt.strip_edges() != "" else description
	_yes_button.text = action_label if action_label.strip_edges() != "" else "Yes"
	_no_button.text = "No"
	_hint_label.text = "Press Space for yes, Esc for no"
	_action_row.visible = true
	_root.visible = true
	_yes_button.grab_focus()


func hide_panel() -> void:
	_root.visible = false
	_has_action = false
	_action_effects = []


func is_open() -> bool:
	return _root.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if _has_action:
		if event.is_action_pressed("interact"):
			_confirm_action()
			return true
		if event.is_action_pressed("ui_cancel") or _is_key_pressed(event, KEY_N):
			hide_panel()
			return true
		if _is_key_pressed(event, KEY_Y):
			_confirm_action()
			return true
		return false
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		hide_panel()
		return true
	return false


func _confirm_action() -> void:
	var effects := _action_effects.duplicate()
	hide_panel()
	action_confirmed.emit(effects)


func _is_key_pressed(event: InputEvent, keycode: Key) -> bool:
	var key_event := event as InputEventKey
	return key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == keycode
