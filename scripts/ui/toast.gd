class_name Toast
extends CanvasLayer

const FADE_IN_SECONDS := 0.18
const HOLD_SECONDS := 1.6
const FADE_OUT_SECONDS := 0.45
const RISE_DISTANCE := 18.0

@onready var _root: Control = $Root
@onready var _container: PanelContainer = $Root/Container
@onready var _label: Label = $Root/Container/Margin/Label

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
	_tween.chain().tween_interval(HOLD_SECONDS)
	_tween.chain().tween_property(_container, "modulate:a", 0.0, FADE_OUT_SECONDS)
	_tween.chain().tween_callback(_on_finished)


func _on_finished() -> void:
	_root.visible = false
