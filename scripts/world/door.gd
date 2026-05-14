@tool
class_name Door
extends Node2D

@export var room_a: StringName
@export var room_b: StringName
@export var draw_debug_marker := false

var door_data: DoorData
var door_color := Palette.DOOR
var trim_color := Palette.DOOR_TRIM
var outline_color := Palette.OUTLINE


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
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	visible = door_data != null and door_data.connects(room_id)


func _draw() -> void:
	if not draw_debug_marker:
		return

	var rect := Rect2(Vector2.ZERO, Vector2(TileMap2D.TILE_SIZE, TileMap2D.TILE_SIZE))
	var door_rect := Rect2(rect.position + Layout.DOOR_OFFSET, rect.size - Layout.DOOR_PAD)
	draw_rect(door_rect, door_color, true)
	draw_rect(door_rect, trim_color, false, Layout.OBJECT_OUTLINE_WIDTH)
	draw_circle(rect.position + Vector2(rect.size.x - Layout.DOOR_KNOB_OFFSET_RIGHT, rect.size.y * 0.5), Layout.DOOR_KNOB_RADIUS, trim_color)
