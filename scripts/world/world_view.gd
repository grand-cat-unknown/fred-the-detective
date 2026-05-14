@tool
class_name WorldView
extends Node2D

@export_group("Movement")
@export_range(60.0, 600.0, 5.0, "or_greater") var player_speed := Gameplay.PLAYER_SPEED:
	set(value):
		player_speed = value
		if _player != null:
			_player.speed = player_speed

@export_group("Camera")
@export_range(0.25, 4.0, 0.05, "or_greater") var camera_zoom := 2.0:
	set(value):
		camera_zoom = value
		_apply_camera_to_player(true)
@export_range(0.0, 30.0, 0.5, "or_greater") var camera_follow_smoothing := 12.0:
	set(value):
		camera_follow_smoothing = value

@export_group("Palette")
@export var background_color := Palette.BACKGROUND:
	set(value):
		background_color = value
		_apply_palette()
@export var player_color := Palette.PLAYER_BODY:
	set(value):
		player_color = value
		_apply_palette()
@export var player_hat_color := Palette.PLAYER_HAT:
	set(value):
		player_hat_color = value
		_apply_palette()

var case_data: CaseData

var _world_map: WorldMap
var _player: Player
var _camera: Camera2D
var _npc_nodes: Array[NPC] = []


func _ready() -> void:
	if Engine.is_editor_hint() and case_data == null:
		configure(CaseLoader.load_default())


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_apply_camera_to_player(false, delta)


func configure(new_case: CaseData) -> void:
	case_data = new_case
	_rebuild_content()


func reset_player(start_tile: Vector2i) -> void:
	if _player == null:
		return
	_player.reset_to_tile(start_tile)
	_apply_camera_to_player(true)


func process_player_step(delta: float) -> bool:
	if _player == null:
		return false
	var was_stepping := _player.is_stepping
	_player.process_step(delta)
	return was_stepping and not _player.is_stepping


func try_start_tile_step(direction: Vector2i) -> void:
	if _player == null:
		return
	_player.speed = player_speed
	_player.try_step(direction, _world_map, _npc_tiles())


func is_player_stepping() -> bool:
	return _player != null and _player.is_stepping


func _apply_palette() -> void:
	if _world_map != null:
		_world_map.background_color = background_color
	if _player != null:
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.queue_redraw()


func _apply_camera_to_player(instant: bool, delta: float = 0.0) -> void:
	if _camera == null:
		return

	if Engine.is_editor_hint() or _player == null:
		_camera.position = TileMap2D.VIEW_SIZE * 0.5
		_camera.zoom = Vector2.ONE
		return

	var target_position := _player.position
	var target_zoom := Vector2(camera_zoom, camera_zoom)

	if instant or camera_follow_smoothing <= 0.0 or not is_inside_tree():
		_camera.position = target_position
		_camera.zoom = target_zoom
		return

	var follow_weight := clampf(1.0 - exp(-camera_follow_smoothing * delta), 0.0, 1.0)
	_camera.position = _camera.position.lerp(target_position, follow_weight)
	_camera.zoom = target_zoom


func _rebuild_content() -> void:
	_npc_nodes.clear()
	_world_map = null
	_player = null
	_camera = null

	for child in get_children():
		if child is WorldMap:
			_world_map = child
		elif child is Player:
			_player = child
		elif child is Camera2D:
			_camera = child
		elif child is NPC:
			_npc_nodes.append(child)

	if _camera != null and not Engine.is_editor_hint():
		_camera.make_current()

	if case_data != null:
		for npc in _npc_nodes:
			for suspect in case_data.suspects:
				if suspect.id == npc.entity_id:
					suspect.position = npc.position
					npc.configure(suspect)
					break

	if _player != null:
		_player.speed = player_speed
		_player.visible = not Engine.is_editor_hint()

	_apply_palette()
	_apply_camera_to_player(false)


func _npc_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for npc in _npc_nodes:
		tiles.append(TileMap2D.world_to_tile(npc.position))
	return tiles
