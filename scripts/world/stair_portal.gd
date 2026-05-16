@tool
class_name StairPortal
extends Node2D

@export var target_portal: NodePath
@export var enabled := true
@export var draw_marker := true:
	set(value):
		draw_marker = value
		queue_redraw()
@export var marker_color := Color(0.25, 0.55, 1.0, 0.75):
	set(value):
		marker_color = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		_snap_to_tile()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_snap_to_tile()


func get_tile(world_map: WorldMap) -> Vector2i:
	if world_map != null:
		return world_map.world_to_tile(position)
	return TileMap2D.world_to_tile(position)


func get_target() -> StairPortal:
	if target_portal.is_empty():
		return null
	var node := get_node_or_null(target_portal)
	return node as StairPortal


func _draw() -> void:
	if not draw_marker:
		return
	var half_size := TileMap2D.TILE_SIZE * 0.5
	var rect := Rect2(Vector2(-half_size, -half_size), Vector2(TileMap2D.TILE_SIZE, TileMap2D.TILE_SIZE))
	draw_rect(rect, marker_color, false, 2.0)
	draw_line(Vector2(-6, 0), Vector2(6, 0), marker_color, 2.0)
	draw_line(Vector2(0, -6), Vector2(0, 6), marker_color, 2.0)


func _snap_to_tile() -> void:
	var snapped_pos := TileMap2D.tile_to_world_center(TileMap2D.world_to_tile(position))
	if position != snapped_pos:
		position = snapped_pos
