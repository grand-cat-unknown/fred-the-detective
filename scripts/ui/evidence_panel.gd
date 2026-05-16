class_name EvidencePanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var _image_rect: TextureRect = $Root/Panel/Margin/VBox/Body/Image
@onready var _description_label: RichTextLabel = $Root/Panel/Margin/VBox/Body/Description
@onready var _hint_label: Label = $Root/Panel/Margin/VBox/Footer/Hint


func _ready() -> void:
	_root.visible = false


func open(title: String, image: Texture2D, description: String) -> void:
	_title_label.text = title
	_image_rect.texture = image
	_image_rect.visible = image != null
	_description_label.text = description
	_root.visible = true


func hide_panel() -> void:
	_root.visible = false


func is_open() -> bool:
	return _root.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if event.is_action_pressed("ui_cancel"):
		hide_panel()
		return true
	return false
