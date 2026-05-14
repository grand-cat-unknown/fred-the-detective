extends SceneTree


func _init() -> void:
	var world_map := load("res://scenes/world/world_map.tscn").instantiate() as WorldMap
	root.add_child(world_map)
	world_map.configure(CaseLoader.load_default())
	world_map.set_current_room(CaseLoader.ROOM_LOBBY)

	_assert_walkable(world_map, CaseLoader.PLAYER_START_TILE, true)
	_assert_walkable(world_map, Vector2i(4, 10), false)
	_assert_walkable(world_map, Vector2i(0, 0), false)
	_assert_walkable(world_map, Vector2i(30, 1), false)

	print("World tilemap runtime checks passed.")
	quit()


func _assert_walkable(world_map: WorldMap, tile: Vector2i, expected: bool) -> void:
	var actual := world_map.is_walkable(tile)
	if actual != expected:
		push_error("Expected %s walkable=%s, got %s" % [tile, expected, actual])
		quit(1)
