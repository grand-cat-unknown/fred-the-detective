@tool
class_name WorldMap
extends Node2D

var case_data: CaseData
var current_room: StringName = &""
var show_all_rooms := false

var background_color := Palette.BACKGROUND
var floor_color := Palette.FLOOR
var floor_alt_color := Palette.FLOOR_ALT
var wall_color := Palette.WALL
var wall_top_color := Palette.WALL_TOP
var rug_color := Palette.RUG
var rug_trim_color := Palette.RUG_TRIM
var runner_color := Palette.RUNNER
var outline_color := Palette.OUTLINE


func configure(new_case: CaseData) -> void:
	case_data = new_case
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	if current_room == room_id:
		return
	current_room = room_id
	queue_redraw()


func is_walkable(tile_position: Vector2i) -> bool:
	return TileMap2D.is_walkable(tile_position)


func tile_to_world(tile_position: Vector2i) -> Vector2:
	return TileMap2D.tile_to_world_center(tile_position)


func world_to_tile(world_position: Vector2) -> Vector2i:
	return TileMap2D.world_to_tile(world_position)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, TileMap2D.VIEW_SIZE), background_color, true)
	if case_data == null:
		return

	if show_all_rooms:
		for room_data in case_data.rooms:
			_draw_room_tiles(room_data.tile_bounds)
		return

	var room := case_data.room_by_id(current_room)
	if room == null:
		return
	_draw_room_tiles(room.tile_bounds)


func _draw_room_tiles(bounds: Rect2i) -> void:
	for y in range(TileMap2D.MAP_HEIGHT):
		for x in range(TileMap2D.MAP_WIDTH):
			var tile_pos := Vector2i(x, y)
			if not bounds.has_point(tile_pos):
				continue

			var rect := Rect2(Vector2(x, y) * TileMap2D.TILE_SIZE, Vector2(TileMap2D.TILE_SIZE, TileMap2D.TILE_SIZE))
			var tile := TileMap2D.tile_at(tile_pos)
			_draw_floor_tile(rect, x, y)
			match tile:
				"#":
					_draw_wall_tile(rect)
				",":
					_draw_rug_tile(rect, false)
				"=":
					_draw_rug_tile(rect, true)
				"D":
					_draw_object_tile(rect, Palette.WOOD)
				"B":
					_draw_object_tile(rect, Palette.SOFA)
				"C":
					_draw_object_tile(rect, Palette.CABINET)
				"G":
					_draw_object_tile(rect, Palette.GEAR)
				"P":
					_draw_pedestal_tile(rect)


func _draw_floor_tile(rect: Rect2, x: int, y: int) -> void:
	var color := floor_color if (x + y) % 2 == 0 else floor_alt_color
	draw_rect(rect, color, true)
	draw_rect(rect, Palette.FLOOR_OUTLINE, false, Layout.TILE_OUTLINE_WIDTH)


func _draw_wall_tile(rect: Rect2) -> void:
	draw_rect(rect, wall_color, true)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, Layout.WALL_TOP_HEIGHT)), wall_top_color, true)
	draw_rect(rect, outline_color, false, Layout.TILE_OUTLINE_WIDTH)


func _draw_rug_tile(rect: Rect2, is_runner: bool) -> void:
	var color := runner_color if is_runner else rug_color
	draw_rect(rect.grow(-Layout.RUG_INSET), color, true)
	draw_rect(rect.grow(-Layout.RUG_TRIM_OUTLINE_INSET), Palette.RUG_INNER_OUTLINE, false, Layout.TILE_OUTLINE_WIDTH)
	if (int(rect.position.x / TileMap2D.TILE_SIZE) + int(rect.position.y / TileMap2D.TILE_SIZE)) % 2 == 0:
		draw_rect(
			Rect2(
				rect.position + Layout.RUG_TRIM_OFFSET,
				Vector2(rect.size.x - Layout.RUG_TRIM_HORIZONTAL_PAD, Layout.RUG_TRIM_THICKNESS),
			),
			rug_trim_color,
			true,
		)


func _draw_object_tile(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(-Layout.OBJECT_INSET), color, true)
	draw_rect(
		Rect2(
			rect.position + Layout.OBJECT_HIGHLIGHT_OFFSET,
			Vector2(rect.size.x - Layout.OBJECT_HIGHLIGHT_HORIZONTAL_PAD, Layout.OBJECT_HIGHLIGHT_HEIGHT),
		),
		Palette.OBJECT_HIGHLIGHT,
		true,
	)
	draw_rect(rect.grow(-Layout.OBJECT_INSET), outline_color, false, Layout.OBJECT_OUTLINE_WIDTH)


func _draw_pedestal_tile(rect: Rect2) -> void:
	draw_rect(rect.grow(-Layout.PEDESTAL_OUTER_INSET), Palette.PEDESTAL, true)
	draw_rect(rect.grow(-Layout.PEDESTAL_INNER_INSET), Palette.PEDESTAL_TOP, true)
	draw_rect(rect.grow(-Layout.PEDESTAL_OUTER_INSET), outline_color, false, Layout.OBJECT_OUTLINE_WIDTH)
