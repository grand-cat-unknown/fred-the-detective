@tool
class_name WorldMap
extends Node2D


const BLOCKING_LAYERS := {
	"Walls": true,
	"furniture": true,
	"furniture-16": true,
	"Props": true,
	"props-16": true,
}
const INSPECT_TITLE_DATA := "inspect_title"
const INSPECT_DESCRIPTION_DATA := "inspect_description"
const INSPECT_OBJECT_ID_DATA := "inspect_object_id"

const COVER_LAYERS := {
	"RoomCover": true,
	"PanicHallwayCover": true,
}
const COVER_OPAQUE_ALPHA := 1.0
const COVER_REVEAL_ALPHA := 0.3
const COVER_FADE_SECONDS := 0.15
const ACTOR_BLOCKING_FOOT_OFFSET := Vector2(0.0, TileMap2D.TILE_SIZE * 0.5 - 1.0)
const SUBTILE_APPROACH_OFFSET := 1.0
const SUBTILE_SIDE_SAMPLE_OFFSET := 7.0

var background_color := Palette.BACKGROUND:
	set(value):
		background_color = value
		queue_redraw()

var _tile_layers: Dictionary = {}
var _cover_tweens: Dictionary = {}


func _ready() -> void:
	_collect_tile_layers()
	_verify_layer_alignment()


func is_walkable(tile_position: Vector2i, approach_direction := Vector2i.ZERO) -> bool:
	for layer_name in _tile_layers:
		if not BLOCKING_LAYERS.has(layer_name):
			continue
		var blocking_layer := _tile_layers[layer_name] as TileMapLayer
		if _layer_has_cell_in_world_tile(blocking_layer, tile_position, approach_direction):
			return false

	return true


func update_cover_visibility(player_tile: Vector2i) -> void:
	for layer_name in COVER_LAYERS:
		_update_cover_layer_visibility(layer_name, player_tile)


func _update_cover_layer_visibility(layer_name: String, player_tile: Vector2i) -> void:
	var cover := _layer(layer_name)
	if cover == null:
		return
	var on_cover := cover.get_cell_source_id(player_tile) != -1
	var target_alpha := COVER_REVEAL_ALPHA if on_cover else COVER_OPAQUE_ALPHA
	if is_equal_approx(cover.modulate.a, target_alpha):
		return
	var cover_tween := _cover_tweens.get(layer_name) as Tween
	if cover_tween != null and cover_tween.is_valid():
		cover_tween.kill()
	cover_tween = create_tween()
	_cover_tweens[layer_name] = cover_tween
	cover_tween.tween_property(cover, "modulate:a", target_alpha, COVER_FADE_SECONDS)


func tile_to_world(tile_position: Vector2i) -> Vector2:
	return transform * TileMap2D.tile_to_world_center(tile_position)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return TileMap2D.world_to_tile(transform.affine_inverse() * world_position)


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
	_collect_tile_layers_from(self)


func _collect_tile_layers_from(parent: Node) -> void:
	for child in parent.get_children():
		if child is TileMapLayer:
			_tile_layers[child.name] = child
		_collect_tile_layers_from(child)


func _verify_layer_alignment() -> void:
	for layer_name in _tile_layers:
		var layer := _tile_layers[layer_name] as TileMapLayer
		if layer.position != Vector2.ZERO:
			push_error("TileMapLayer '%s' has non-zero position %s — keep layers at (0, 0) so world->tile math stays consistent." % [layer_name, layer.position])
		if layer.transform != Transform2D.IDENTITY:
			push_error("TileMapLayer '%s' has a non-identity transform — keep layers untransformed so world->tile math stays consistent." % layer_name)


func _layer(layer_name: String) -> TileMapLayer:
	if _tile_layers.is_empty():
		_collect_tile_layers()
	if not _tile_layers.has(layer_name):
		return null
	return _tile_layers[layer_name]


func _layer_has_cell_in_world_tile(layer: TileMapLayer, tile_position: Vector2i, approach_direction: Vector2i) -> bool:
	if _uses_world_tile_sized_cells(layer):
		return layer.get_cell_source_id(tile_position) != -1

	var tile_center := TileMap2D.tile_to_world_center(tile_position)
	if approach_direction.x != 0:
		var approach_offset := Vector2(-float(approach_direction.x) * SUBTILE_APPROACH_OFFSET, 0.0)
		return _layer_has_cell_at_world_position(layer, tile_center + ACTOR_BLOCKING_FOOT_OFFSET + approach_offset)

	return (
		_layer_has_cell_at_world_position(layer, tile_center + ACTOR_BLOCKING_FOOT_OFFSET + Vector2(-SUBTILE_SIDE_SAMPLE_OFFSET, 0.0))
		and _layer_has_cell_at_world_position(layer, tile_center + ACTOR_BLOCKING_FOOT_OFFSET + Vector2(SUBTILE_SIDE_SAMPLE_OFFSET, 0.0))
	)


func _layer_has_cell_at_world_position(layer: TileMapLayer, world_position: Vector2) -> bool:
	var cell := layer.local_to_map(world_position)
	return layer.get_cell_source_id(cell) != -1


func _uses_world_tile_sized_cells(layer: TileMapLayer) -> bool:
	if layer.tile_set == null:
		return true
	var tile_size := Vector2(layer.tile_set.tile_size)
	return tile_size.x >= TileMap2D.TILE_SIZE and tile_size.y >= TileMap2D.TILE_SIZE


func _get_custom_data(tile_set: TileSet, tile_data: TileData, data_name: String) -> String:
	if tile_set == null or not _has_custom_data_layer(tile_set, data_name):
		return ""
	var value: Variant = tile_data.get_custom_data(data_name)
	return str(value).strip_edges() if value != null else ""


func _has_custom_data_layer(tile_set: TileSet, data_name: String) -> bool:
	for layer_index in range(tile_set.get_custom_data_layers_count()):
		if tile_set.get_custom_data_layer_name(layer_index) == data_name:
			return true
	return false
