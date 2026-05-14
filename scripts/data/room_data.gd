class_name RoomData
extends Resource

@export var id: StringName
@export var label: String
@export var rect: Rect2
@export var label_position: Vector2
@export var color: Color


func _init(
	p_id: StringName = &"",
	p_label: String = "",
	p_rect: Rect2 = Rect2(),
	p_label_position: Vector2 = Vector2.ZERO,
	p_color: Color = Color(1, 1, 1, 0.2),
) -> void:
	id = p_id
	label = p_label
	rect = p_rect
	label_position = p_label_position
	color = p_color
