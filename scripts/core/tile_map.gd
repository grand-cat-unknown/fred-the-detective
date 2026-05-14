class_name TileMap2D
extends RefCounted

const TILE_SIZE := 32.0
const MAP_WIDTH := 100
const MAP_HEIGHT := 100
const VIEW_SIZE := Vector2(TILE_SIZE * MAP_WIDTH, TILE_SIZE * MAP_HEIGHT)


static func tile_to_world_center(tile_position: Vector2i) -> Vector2:
	return Vector2(tile_position) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


static func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / TILE_SIZE),
		floori(world_position.y / TILE_SIZE),
	)
