class_name ElevatorData
extends Resource

@export var tile_a: Vector2i
@export var spawn_a: Vector2i
@export var room_a: StringName
@export var tile_b: Vector2i
@export var spawn_b: Vector2i
@export var room_b: StringName


func _init(
	p_tile_a: Vector2i = Vector2i.ZERO,
	p_spawn_a: Vector2i = Vector2i.ZERO,
	p_room_a: StringName = &"",
	p_tile_b: Vector2i = Vector2i.ZERO,
	p_spawn_b: Vector2i = Vector2i.ZERO,
	p_room_b: StringName = &"",
) -> void:
	tile_a = p_tile_a
	spawn_a = p_spawn_a
	room_a = p_room_a
	tile_b = p_tile_b
	spawn_b = p_spawn_b
	room_b = p_room_b


func tile_for(room_id: StringName) -> Vector2i:
	return tile_a if room_id == room_a else tile_b


func target_room_from(room_id: StringName) -> StringName:
	return room_b if room_id == room_a else room_a


func target_spawn_from(room_id: StringName) -> Vector2i:
	return spawn_b if room_id == room_a else spawn_a
