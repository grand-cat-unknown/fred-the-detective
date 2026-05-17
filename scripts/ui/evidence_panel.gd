class_name EvidencePanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var _image_rect: TextureRect = $Root/Panel/Margin/VBox/Body/Image
@onready var _description_label: RichTextLabel = $Root/Panel/Margin/VBox/Body/Description
@onready var _hint_label: Label = $Root/Panel/Margin/VBox/Footer/Hint

var _close_with_interact := false


func _ready() -> void:
	_root.visible = false


func open(title: String, image: Texture2D, description: String, close_with_interact := false, close_hint := "Esc to close") -> void:
	_title_label.text = title
	_image_rect.texture = image
	_image_rect.visible = image != null
	_description_label.text = description
	_close_with_interact = close_with_interact
	_hint_label.text = close_hint
	_root.visible = true


func hide_panel() -> void:
	_root.visible = false
	_close_with_interact = false


func is_open() -> bool:
	return _root.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if event.is_action_pressed("ui_cancel") or (_close_with_interact and event.is_action_pressed("interact")):
		hide_panel()
		return true
	return false
