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
@export var texture: Texture2D

const WALK_CYCLE_SECONDS := 0.65

var _walk_animation_time := 0.0


func reset_to_tile(start_tile: Vector2i, world_map: WorldMap = null) -> void:
	tile = start_tile
	target_tile = start_tile
	position = world_map.tile_to_world(start_tile) if world_map != null else TileMap2D.tile_to_world_center(start_tile)
	target_position = position
	is_stepping = false
	face_direction = Vector2i(1, 0)
	_walk_animation_time = 0.0
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


func process_step(delta: float) -> float:
	if not is_stepping or speed <= 0.0:
		return delta

	var distance_remaining := position.distance_to(target_position)
	var frame_distance := speed * delta
	if frame_distance >= distance_remaining:
		_walk_animation_time += distance_remaining / speed
		position = target_position
		tile = target_tile
		is_stepping = false
		queue_redraw()
		moved.emit(tile)
		return delta - distance_remaining / speed

	_walk_animation_time += delta
	position = position.move_toward(target_position, frame_distance)
	queue_redraw()
	return 0.0


func _draw() -> void:
	ActorDraw.draw_actor(self , Vector2.ZERO, body_color, hat_color, face_direction, texture, is_stepping, _walk_phase())


func _walk_phase() -> float:
	if not is_stepping:
		return 0.0
	return fmod(_walk_animation_time / WALK_CYCLE_SECONDS, 1.0)
