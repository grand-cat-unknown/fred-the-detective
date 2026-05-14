@tool
class_name Door
extends Node2D

@export var room_a: StringName
@export var room_b: StringName

var door_data: DoorData


func _ready() -> void:
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		var snapped_pos := (position / TileMap2D.TILE_SIZE).round() * TileMap2D.TILE_SIZE
		if position != snapped_pos:
			position = snapped_pos


func configure(new_door: DoorData) -> void:
	door_data = new_door
	if door_data != null:
		room_a = door_data.room_a
		room_b = door_data.room_b
		name = "Door_%s_%s" % [door_data.room_a, door_data.room_b]


func set_current_room(room_id: StringName) -> void:
	visible = door_data != null and door_data.connects(room_id)
