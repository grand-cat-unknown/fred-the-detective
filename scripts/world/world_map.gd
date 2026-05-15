@tool
class_name WorldMap
extends Node2D

const FLOOR_LAYER := "Floor"
const BLOCKING_LAYERS := ["Walls", "Props"]
const INSPECT_TITLE_DATA := "inspect_title"
const INSPECT_DESCRIPTION_DATA := "inspect_description"
const INSPECT_OBJECT_ID_DATA := "inspect_object_id"

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


func get_tile_inspection(tile_position: Vector2i) -> Dictionary:
	if _tile_layers.is_empty():
		_collect_tile_layers()

	for layer in _tile_layers.values():
		var tile_layer := layer as TileMapLayer
		var tile_data := tile_layer.get_cell_tile_data(tile_position)
		if tile_data == null:
			continue

		var title := _get_custom_data(tile_layer.tile_set, tile_data, INSPECT_TITLE_DATA)
		var description := _get_custom_data(tile_layer.tile_set, tile_data, INSPECT_DESCRIPTION_DATA)
		var object_id := _get_custom_data(tile_layer.tile_set, tile_data, INSPECT_OBJECT_ID_DATA)
		if title.is_empty() and description.is_empty() and object_id.is_empty():
			continue

		return {
			"object_id": StringName(object_id),
			"title": title if not title.is_empty() else "Object",
			"description": description if not description.is_empty() else "An ordinary thing. Nothing of note.",
		}

	return {}


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


func _get_custom_data(tile_set: TileSet, tile_data: TileData, data_name: String) -> String:
	if tile_set == null or not _has_custom_data_layer(tile_set, data_name):
		return ""
	var value: Variant = tile_data.get_custom_data(data_name)
	return str(value) if value != null else ""


func _has_custom_data_layer(tile_set: TileSet, data_name: String) -> bool:
	for layer_index in range(tile_set.get_custom_data_layers_count()):
		if tile_set.get_custom_data_layer_name(layer_index) == data_name:
			return true
	return false
