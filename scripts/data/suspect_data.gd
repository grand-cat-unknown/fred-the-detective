class_name SuspectData
extends Resource

@export var id: StringName
@export var display_name: String
@export var position: Vector2
@export var color: Color
@export var hat_color: Color


func _init(
	p_id: StringName = &"",
	p_display_name: String = "",
	p_position: Vector2 = Vector2.ZERO,
	p_color: Color = Color.WHITE,
	p_hat_color: Color = Color.BLACK,
) -> void:
	id = p_id
	display_name = p_display_name
	position = p_position
	color = p_color
	hat_color = p_hat_color
