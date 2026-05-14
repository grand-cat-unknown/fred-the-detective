class_name SuspectData
extends Resource

@export var id: StringName
@export var display_name: String
@export var position: Vector2
@export var color: Color
@export var hat_color: Color
@export var texture: Texture2D

@export_group("Character")
@export var subtitle: String = ""
@export_multiline var persona: String = ""

@export_group("Dialogue")
@export_multiline var dialogue: String = "They glance up but say nothing of note."
@export_multiline var system_prompt: String = ""


func _init(
	p_id: StringName = &"",
	p_display_name: String = "",
	p_position: Vector2 = Vector2.ZERO,
	p_color: Color = Color.WHITE,
	p_hat_color: Color = Color.BLACK,
	p_texture: Texture2D = null,
) -> void:
	id = p_id
	display_name = p_display_name
	position = p_position
	color = p_color
	hat_color = p_hat_color
	texture = p_texture
