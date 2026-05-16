class_name Toast
extends CanvasLayer

const FADE_IN_SECONDS := 0.18
const RISE_DISTANCE := 12.0

@onready var _root: Control = $Root
@onready var _container: PanelContainer = $Root/Container
@onready var _label: Label = $Root/Container/Margin/VBox/Label

var _tween: Tween
var _base_offset_top: float
var _base_offset_bottom: float


func _ready() -> void:
	_root.visible = false
	_base_offset_top = _container.offset_top
	_base_offset_bottom = _container.offset_bottom


func show_message(message: String) -> void:
	var text := message.strip_edges()
	if text == "":
		return
	_label.text = text
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_container.offset_top = _base_offset_top + RISE_DISTANCE
	_container.offset_bottom = _base_offset_bottom + RISE_DISTANCE
	_container.modulate.a = 0.0
	_root.visible = true

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(_container, "modulate:a", 1.0, FADE_IN_SECONDS)
	_tween.tween_property(_container, "offset_top", _base_offset_top, FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_container, "offset_bottom", _base_offset_bottom, FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func hide_panel() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		hide_panel()
		return true
	return false
