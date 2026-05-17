@tool
class_name TileInspectionMarker
extends Node2D

@export var object_id: StringName
@export var title: String = "Object"
@export_multiline var description: String = "An ordinary thing. Nothing of note."
@export var snap_to_map_grid := true:
	set(value):
		snap_to_map_grid = value
		if snap_to_map_grid and Engine.is_editor_hint():
			_snap_in_editor()

var _is_snapping := false


func _ready() -> void:
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_snap_in_editor()


func get_tile(world_map: WorldMap = null) -> Vector2i:
	return world_map.world_to_tile(position) if world_map != null else TileMap2D.world_to_tile(position)


func to_inspection_dictionary() -> Dictionary:
	return {
		"object_id": object_id,
		"title": title,
		"description": description,
	}


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var half := Vector2(7.0, 7.0)
	draw_rect(Rect2(-half, half * 2.0), Color(0.2, 0.7, 1.0, 0.35), true)
	draw_rect(Rect2(-half, half * 2.0), Color(0.2, 0.7, 1.0, 0.95), false, 2.0)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 0.95))


func _snapped_position(world_map: WorldMap = null) -> Vector2:
	if world_map == null:
		return TileMap2D.tile_to_world_center(TileMap2D.world_to_tile(position))
	return world_map.tile_to_world(world_map.world_to_tile(position))


func _find_world_map() -> WorldMap:
	var parent_node := get_parent()
	while parent_node != null:
		for child in parent_node.get_children():
			if child is WorldMap:
				return child
		parent_node = parent_node.get_parent()
	return null


func _snap_in_editor() -> void:
	if not snap_to_map_grid or _is_snapping or position == Vector2.ZERO:
		return
	var world_map := _find_world_map()
	if world_map == null:
		return
	_is_snapping = true
	position = _snapped_position(world_map)
	_is_snapping = false
