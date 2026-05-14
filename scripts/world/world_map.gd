@tool
class_name WorldMap
extends Node2D

const FLOOR_LAYER := "Floor"
const BLOCKING_LAYERS := ["Walls"]

var background_color := Palette.BACKGROUND:
	set(value):
		background_color = value
		queue_redraw()

var _tile_layers: Dictionary = {}


func _ready() -> void:
	_collect_tile_layers()


func is_walkable(tile_position: Vector2i) -> bool:
	var floor_layer := _layer(FLOOR_LAYER)
	if floor_layer == null or floor_layer.get_cell_source_id(tile_position) == -1:
		return false

	for layer_name in BLOCKING_LAYERS:
		var blocking_layer := _layer(layer_name)
		if blocking_layer != null and blocking_layer.get_cell_source_id(tile_position) != -1:
			return false

	return true


func tile_to_world(tile_position: Vector2i) -> Vector2:
	return TileMap2D.tile_to_world_center(tile_position)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return TileMap2D.world_to_tile(world_position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, TileMap2D.VIEW_SIZE), background_color, true)


func _collect_tile_layers() -> void:
	_tile_layers.clear()
	for child in get_children():
		if child is TileMapLayer:
			_tile_layers[child.name] = child


func _layer(layer_name: String) -> TileMapLayer:
	if _tile_layers.is_empty():
		_collect_tile_layers()
	if not _tile_layers.has(layer_name):
		return null
	return _tile_layers[layer_name]
