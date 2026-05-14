class_name InspectPanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _title_label: Label = $Root/Panel/Margin/VBox/Title
@onready var _description_label: Label = $Root/Panel/Margin/VBox/Description
@onready var _hint_label: Label = $Root/Panel/Margin/VBox/Hint


func _ready() -> void:
	_root.visible = false


func show_inspectable(inspectable: Inspectable) -> void:
	_title_label.text = inspectable.title
	_description_label.text = inspectable.description
	_hint_label.text = "Press E or Space to close"
	_root.visible = true


func hide_panel() -> void:
	_root.visible = false


func is_open() -> bool:
	return _root.visible
