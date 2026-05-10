class_name Player
extends Node2D

signal moved(tile: Vector2i)

var tile := Vector2i.ZERO
var target_tile := Vector2i.ZERO
var target_position := Vector2.ZERO
var is_stepping := false
var face_direction := Vector2i(1, 0)
var speed := Gameplay.PLAYER_SPEED
var body_color := Palette.PLAYER_BODY
var hat_color := Palette.PLAYER_HAT


func reset_to_tile(start_tile: Vector2i) -> void:
	tile = start_tile
	target_tile = start_tile
	position = TileMap2D.tile_to_world_center(start_tile)
	target_position = position
	is_stepping = false
	face_direction = Vector2i(1, 0)
	queue_redraw()
	moved.emit(tile)


func try_step(direction: Vector2i, world_map: WorldMap, blocked_tiles: Array[Vector2i]) -> bool:
	face_direction = direction
	var next_tile := tile + direction
	if world_map == null or not world_map.is_walkable(next_tile) or blocked_tiles.has(next_tile):
		queue_redraw()
		return false

	tile = next_tile
	target_tile = next_tile
	target_position = world_map.tile_to_world(next_tile)
	is_stepping = true
	queue_redraw()
	return true


func process_step(delta: float) -> bool:
	if not is_stepping:
		return false

	position = position.move_toward(target_position, speed * delta)
	if position.is_equal_approx(target_position):
		position = target_position
		tile = TileMap2D.world_to_tile(position)
		is_stepping = false
		moved.emit(tile)
	queue_redraw()
	return true


func _draw() -> void:
	ActorDraw.draw_actor(self, Vector2.ZERO, body_color, hat_color, face_direction)
