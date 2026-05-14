class_name DoorData
extends Resource

@export var tile: Vector2i
@export var room_a: StringName
@export var room_b: StringName


func _init(
	p_tile: Vector2i = Vector2i.ZERO,
	p_room_a: StringName = &"",
	p_room_b: StringName = &"",
) -> void:
	tile = p_tile
	room_a = p_room_a
	room_b = p_room_b


func target_from(room_id: StringName) -> StringName:
	if room_id == room_a:
		return room_b
	return room_a
