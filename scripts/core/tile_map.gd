class_name TileMap2D
extends RefCounted

const TILE_SIZE := 30.0
const MAP_WIDTH := 32
const MAP_HEIGHT := 18
const VIEW_SIZE := Vector2(TILE_SIZE * MAP_WIDTH, TILE_SIZE * MAP_HEIGHT)

const ROWS := [
	"################################",
	"#........##........##..........#",
	"#..DD....##...C....##....GG....#",
	"#........##........##..........#",
	"#........##........##..........#",
	"####d#########d##########d######",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"####d###########d#########d#####",
	"#.......#.....#.........#......#",
	"#..BB..E#E.C..#.,,PP,,..#..DD..#",
	"#.......#.....#.........#......#",
	"#.......#.....#.........#......#",
	"#.......#.....#.........#......#",
	"################################",
	"################################",
]

const BLOCKING_TILES := ["#", "D", "B", "C", "G", "P", "d", "E"]


static func tile_at(tile_position: Vector2i) -> String:
	if tile_position.x < 0 or tile_position.x >= MAP_WIDTH:
		return "#"
	if tile_position.y < 0 or tile_position.y >= MAP_HEIGHT:
		return "#"
	var row: String = ROWS[tile_position.y]
	if tile_position.x >= row.length():
		return "#"
	return row.substr(tile_position.x, 1)


static func is_walkable(tile_position: Vector2i) -> bool:
	return not BLOCKING_TILES.has(tile_at(tile_position))


static func tile_to_world_center(tile_position: Vector2i) -> Vector2:
	return Vector2(tile_position) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)


static func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / TILE_SIZE),
		floori(world_position.y / TILE_SIZE),
	)
