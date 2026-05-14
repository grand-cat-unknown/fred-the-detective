@tool
extends SceneTree

const TILESET_PATH := "res://assets/tile_sets/interior_world_tiles.tres"
const WORLD_MAP_SCENE_PATH := "res://scenes/world/world_map.tscn"
const WORLD_MAP_SCENE_UID := "uid://55n455pd115y"
const WORLD_MAP_SCRIPT := "res://scripts/world/world_map.gd"
const ATLAS_TILE_SIZE := Vector2i(16, 16)
const TILEMAP_SCALE := Vector2(2.0, 2.0)

const SOURCE_INTERIORS := 0
const SOURCE_PROPS := 1
const SOURCE_DOORS := 2

const INTERIORS_TEXTURE := "res://Epic RPG World - Village(interiors) V1.3/assets/Interiors_tilesets.png"
const PROPS_TEXTURE := "res://Epic RPG World - Village(interiors) V1.3/assets/furniture_and_props.png"
const DOORS_TEXTURE := "res://Epic RPG World - Village(interiors) V1.3/assets/windows_and_doors.png"

const FLOOR_TILES: Array[Vector2i] = [
	Vector2i(72, 2),
	Vector2i(73, 2),
	Vector2i(74, 2),
	Vector2i(72, 3),
]
const WALL_TILE := Vector2i(42, 5)
const RUG_TILE := Vector2i(58, 80)
const RUNNER_TILE := Vector2i(56, 84)
const DOOR_TILE := Vector2i(2, 9)
const ELEVATOR_TILE := Vector2i(4, 10)

const PROP_TILES := {
	"D": Vector2i(31, 56),
	"B": Vector2i(8, 69),
	"C": Vector2i(42, 56),
	"G": Vector2i(2, 51),
	"P": Vector2i(31, 27),
}
const MIGRATION_ROWS := [
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


func _init() -> void:
	var tile_set := _build_tile_set()
	ResourceSaver.save(tile_set, TILESET_PATH)
	tile_set = load(TILESET_PATH)

	var root := Node2D.new()
	root.name = "WorldMap"
	root.set_script(load(WORLD_MAP_SCRIPT))

	var floor_layer := _make_layer("Floor", tile_set, 0)
	var rug_layer := _make_layer("Rugs", tile_set, 1)
	var wall_layer := _make_layer("Walls", tile_set, 2)
	var prop_layer := _make_layer("Props", tile_set, 3)

	for layer in [floor_layer, rug_layer, wall_layer, prop_layer]:
		root.add_child(layer)
		layer.owner = root

	_paint_existing_layout(floor_layer, rug_layer, wall_layer, prop_layer)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, WORLD_MAP_SCENE_PATH)
	_ensure_scene_uid(WORLD_MAP_SCENE_PATH, WORLD_MAP_SCENE_UID)
	print("Generated %s and %s" % [TILESET_PATH, WORLD_MAP_SCENE_PATH])
	quit()


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = ATLAS_TILE_SIZE
	_add_source(tile_set, SOURCE_INTERIORS, INTERIORS_TEXTURE)
	_add_source(tile_set, SOURCE_PROPS, PROPS_TEXTURE)
	_add_source(tile_set, SOURCE_DOORS, DOORS_TEXTURE)
	return tile_set


func _add_source(tile_set: TileSet, source_id: int, texture_path: String) -> void:
	var texture := load(texture_path) as Texture2D
	var image := Image.load_from_file(texture_path)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = ATLAS_TILE_SIZE

	for y in range(image.get_height() / ATLAS_TILE_SIZE.y):
		for x in range(image.get_width() / ATLAS_TILE_SIZE.x):
			var atlas_coords := Vector2i(x, y)
			if _tile_has_visible_pixels(image, atlas_coords):
				source.create_tile(atlas_coords)

	tile_set.add_source(source, source_id)


func _tile_has_visible_pixels(image: Image, atlas_coords: Vector2i) -> bool:
	var start := atlas_coords * ATLAS_TILE_SIZE
	for y in range(start.y, start.y + ATLAS_TILE_SIZE.y):
		for x in range(start.x, start.x + ATLAS_TILE_SIZE.x):
			if image.get_pixel(x, y).a > 0.0:
				return true
	return false


func _make_layer(layer_name: String, tile_set: TileSet, z_index: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.scale = TILEMAP_SCALE
	layer.z_index = z_index
	return layer


func _ensure_scene_uid(scene_path: String, scene_uid: String) -> void:
	var file_text := FileAccess.get_file_as_string(scene_path)
	var current_header := "[gd_scene format=4]"
	if not file_text.begins_with(current_header):
		return

	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	file.store_string(file_text.replace(current_header, "[gd_scene format=4 uid=\"%s\"]" % scene_uid))


func _paint_existing_layout(
	floor_layer: TileMapLayer,
	rug_layer: TileMapLayer,
	wall_layer: TileMapLayer,
	prop_layer: TileMapLayer,
) -> void:
	for y in range(TileMap2D.MAP_HEIGHT):
		var row: String = MIGRATION_ROWS[y]
		for x in range(TileMap2D.MAP_WIDTH):
			var tile := row.substr(x, 1)
			var coords := Vector2i(x, y)

			match tile:
				"#":
					wall_layer.set_cell(coords, SOURCE_INTERIORS, WALL_TILE)
				"d":
					prop_layer.set_cell(coords, SOURCE_DOORS, DOOR_TILE)
				"E":
					floor_layer.set_cell(coords, SOURCE_INTERIORS, FLOOR_TILES[(x + y) % FLOOR_TILES.size()])
					prop_layer.set_cell(coords, SOURCE_DOORS, ELEVATOR_TILE)
				",":
					floor_layer.set_cell(coords, SOURCE_INTERIORS, FLOOR_TILES[(x + y) % FLOOR_TILES.size()])
					rug_layer.set_cell(coords, SOURCE_INTERIORS, RUG_TILE)
				"=":
					floor_layer.set_cell(coords, SOURCE_INTERIORS, FLOOR_TILES[(x + y) % FLOOR_TILES.size()])
					rug_layer.set_cell(coords, SOURCE_INTERIORS, RUNNER_TILE)
				_:
					floor_layer.set_cell(coords, SOURCE_INTERIORS, FLOOR_TILES[(x + y) % FLOOR_TILES.size()])
					if PROP_TILES.has(tile):
						prop_layer.set_cell(coords, SOURCE_PROPS, PROP_TILES[tile])
