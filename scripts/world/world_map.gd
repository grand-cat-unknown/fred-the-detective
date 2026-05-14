@tool
class_name WorldMap
extends Node2D

const FLOOR_LAYER := "Floor"
const BLOCKING_LAYERS := ["Walls", "Props"]

var case_data: CaseData
var current_room: StringName = &""
var show_all_rooms := false:
	set(value):
		show_all_rooms = value
		_apply_visible_cells()

var background_color := Palette.BACKGROUND:
	set(value):
		background_color = value
		queue_redraw()
var floor_color := Palette.FLOOR
var floor_alt_color := Palette.FLOOR_ALT
var wall_color := Palette.WALL
var wall_top_color := Palette.WALL_TOP
var rug_color := Palette.RUG
var rug_trim_color := Palette.RUG_TRIM
var runner_color := Palette.RUNNER
var outline_color := Palette.OUTLINE

var _tile_layers: Dictionary = {}
var _source_cells_by_layer: Dictionary = {}


func _ready() -> void:
	_collect_tile_layers()
	_capture_source_cells()
	_apply_visible_cells()


func configure(new_case: CaseData) -> void:
	case_data = new_case
	_collect_tile_layers()
	_capture_source_cells()
	_apply_visible_cells()
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	if current_room == room_id:
		return
	current_room = room_id
	_apply_visible_cells()


func is_walkable(tile_position: Vector2i) -> bool:
	if tile_position.x < 0 or tile_position.x >= TileMap2D.MAP_WIDTH:
		return false
	if tile_position.y < 0 or tile_position.y >= TileMap2D.MAP_HEIGHT:
		return false

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


func _capture_source_cells() -> void:
	if not _source_cells_by_layer.is_empty():
		return

	for layer_name in _tile_layers:
		var tile_layer := _layer(layer_name)
		var cells := {}
		for cell in tile_layer.get_used_cells():
			cells[cell] = [
				tile_layer.get_cell_source_id(cell),
				tile_layer.get_cell_atlas_coords(cell),
				tile_layer.get_cell_alternative_tile(cell),
			]
		_source_cells_by_layer[layer_name] = cells


func _apply_visible_cells() -> void:
	if Engine.is_editor_hint() or _source_cells_by_layer.is_empty():
		return

	var visible_bounds := Rect2i(Vector2i.ZERO, Vector2i(TileMap2D.MAP_WIDTH, TileMap2D.MAP_HEIGHT))
	if not show_all_rooms and case_data != null:
		var room := case_data.room_by_id(current_room)
		if room != null:
			visible_bounds = room.tile_bounds

	for layer_name in _source_cells_by_layer:
		var tile_layer := _layer(layer_name)
		if tile_layer == null:
			continue

		tile_layer.clear()
		var cells: Dictionary = _source_cells_by_layer[layer_name]
		for cell in cells:
			if show_all_rooms or visible_bounds.has_point(cell):
				var cell_data: Array = cells[cell]
				tile_layer.set_cell(cell, cell_data[0], cell_data[1], cell_data[2])


func _layer(layer_name: String) -> TileMapLayer:
	if not _tile_layers.has(layer_name):
		return null
	return _tile_layers[layer_name]
