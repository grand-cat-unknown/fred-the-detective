@tool
class_name Inspectable
extends Node2D

@export var object_id: StringName
@export var title: String = "Object"
@export_multiline var description: String = "An ordinary thing. Nothing of note."
@export var texture: Texture2D:
	set(value):
		texture = value
		_apply_texture()
@export var body_color: Color = Color8(140, 100, 60)
@export var draw_marker: bool = true:
	set(value):
		draw_marker = value
		queue_redraw()
@export var blocks_movement: bool = true
@export var controlled_tile_offset := Vector2i.ZERO
@export var tile_visuals: Array = []
@export var snap_to_map_grid := true:
	set(value):
		snap_to_map_grid = value
		if snap_to_map_grid and Engine.is_editor_hint():
			_snap_in_editor()

var _sprite: Sprite2D
var _is_snapping := false


func _ready() -> void:
	set_notify_transform(true)
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_apply_texture()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_snap_in_editor()


func get_tile(world_map: WorldMap = null) -> Vector2i:
	return world_map.world_to_tile(position) if world_map != null else TileMap2D.world_to_tile(position)


func refresh_tile_visual(world_map: WorldMap, state: CaseState) -> void:
	if world_map == null:
		return
	for visual in tile_visuals:
		if not visual is Resource or not visual.has_method("is_available"):
			continue
		var tile_visual := visual as Resource
		if not tile_visual.is_available(state):
			continue
		world_map.apply_tile_visual(get_tile(world_map) + controlled_tile_offset, tile_visual)
		if tile_visual.update_blocks_movement:
			blocks_movement = tile_visual.blocks_movement
		return


func _draw() -> void:
	if not draw_marker and texture == null:
		return

	var half := Vector2(10.0, 10.0)
	var rect := Rect2(-half, half * 2.0)
	draw_rect(Rect2(-half + Vector2(-1.0, 7.0), Vector2(22.0, 5.0)), Palette.ACTOR_SHADOW, true)
	if texture != null:
		return
	draw_rect(rect, body_color, true)
	draw_rect(rect, Palette.OUTLINE, false, Layout.OBJECT_OUTLINE_WIDTH)
	# Question mark dot to hint it's interactable
	draw_rect(Rect2(Vector2(-1.5, -3.5), Vector2(3.0, 3.0)), Palette.OUTLINE, true)
	draw_rect(Rect2(Vector2(-1.5, 2.5), Vector2(3.0, 2.0)), Palette.OUTLINE, true)


func _apply_texture() -> void:
	if _sprite == null and is_node_ready():
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_sprite.texture = texture
	queue_redraw()


func snap_to_tile(world_map: WorldMap = null) -> void:
	var snapped_pos := _snapped_position(world_map)
	if position != snapped_pos:
		position = snapped_pos


func _snapped_position(world_map: WorldMap = null) -> Vector2:
	if world_map == null:
		return TileMap2D.tile_to_world_center(TileMap2D.world_to_tile(position))
	return world_map.tile_to_world(world_map.world_to_tile(position))


func _find_world_map() -> WorldMap:
	var node := get_parent()
	if node == null:
		return null
	for child in node.get_children():
		if child is WorldMap:
			return child
	return null


func _snap_in_editor() -> void:
	if not snap_to_map_grid or _is_snapping or position == Vector2.ZERO:
		return
	var world_map := _find_world_map()
	if world_map == null:
		return
	_is_snapping = true
	snap_to_tile(world_map)
	_is_snapping = false
