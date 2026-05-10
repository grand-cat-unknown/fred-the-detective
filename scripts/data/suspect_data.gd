class_name SuspectData
extends Resource

@export var id: StringName
@export var display_name: String
@export var subtitle: String
@export var room: StringName
@export var position: Vector2
@export var color: Color
@export var hat_color: Color
@export var instructions: String
@export var is_murderer: bool


func _init(
	p_id: StringName = &"",
	p_display_name: String = "",
	p_subtitle: String = "",
	p_room: StringName = &"",
	p_position: Vector2 = Vector2.ZERO,
	p_color: Color = Color.WHITE,
	p_hat_color: Color = Color.BLACK,
	p_instructions: String = "",
	p_is_murderer: bool = false,
) -> void:
	id = p_id
	display_name = p_display_name
	subtitle = p_subtitle
	room = p_room
	position = p_position
	color = p_color
	hat_color = p_hat_color
	instructions = p_instructions
	is_murderer = p_is_murderer
