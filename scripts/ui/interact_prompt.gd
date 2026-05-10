class_name InteractPrompt
extends PanelContainer

@onready var _label: Label = %InteractPromptLabel


func show_target(label: String, prompt_position: Vector2) -> void:
	_label.text = label
	position = prompt_position
	visible = true


func close() -> void:
	visible = false
