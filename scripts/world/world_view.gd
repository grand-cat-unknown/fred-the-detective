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
		refresh()
@export var outline_color := Palette.OUTLINE:
	set(value):
		outline_color = value
		refresh()
@export var player_color := Palette.PLAYER_BODY:
	set(value):
		player_color = value
		refresh()
@export var player_hat_color := Palette.PLAYER_HAT:
	set(value):
		player_hat_color = value
		refresh()
@export var clue_color := Palette.CLUE:
	set(value):
		clue_color = value
		refresh()
@export var clue_inspected_color := Palette.CLUE_INSPECTED:
	set(value):
		clue_inspected_color = value
		refresh()

var case_data: CaseData

var _world_map: WorldMap
var _player: Player
var _camera: Camera2D
var _npc_nodes: Array[NPC] = []
var _clue_markers: Array[ClueMarker] = []
var _elevator_nodes: Array[Elevator] = []


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


func player_position() -> Vector2:
	return _player.position if _player != null else TileMap2D.tile_to_world_center(Vector2i.ZERO)


func player_tile() -> Vector2i:
	return _player.tile if _player != null else Vector2i.ZERO


func player_face_direction() -> Vector2i:
	return _player.face_direction if _player != null else Vector2i(1, 0)


func refresh() -> void:
	if _world_map == null:
		return

	_world_map.background_color = background_color

	for clue_marker in _clue_markers:
		clue_marker.clue_color = clue_color
		clue_marker.clue_inspected_color = clue_inspected_color
		clue_marker.outline_color = outline_color
		clue_marker.refresh()

	if _player != null:
		_player.speed = player_speed
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.visible = not Engine.is_editor_hint()
		_player.queue_redraw()

	_redraw_content()
	_apply_camera_to_player(false)


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
	_clue_markers.clear()
	_elevator_nodes.clear()
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
		elif child is ClueMarker:
			_clue_markers.append(child)
		elif child is Elevator:
			_elevator_nodes.append(child)

	if _camera != null and not Engine.is_editor_hint():
		_camera.make_current()

	if case_data == null:
		return

	for npc in _npc_nodes:
		var suspect := case_data.suspect_by_id(npc.entity_id)
		if suspect != null:
			suspect.position = npc.position
			npc.configure(suspect)

	for clue_marker in _clue_markers:
		var clue := case_data.clue_by_id(clue_marker.entity_id)
		if clue != null:
			clue.position = clue_marker.position
			clue_marker.configure(clue)

	for elevator_node in _elevator_nodes:
		var elevator := _find_elevator(elevator_node.room_a, elevator_node.room_b)
		if elevator != null:
			elevator_node.configure(elevator)

	refresh()


func _find_elevator(a: StringName, b: StringName) -> ElevatorData:
	for elevator in case_data.elevators:
		if (elevator.room_a == a and elevator.room_b == b) or (elevator.room_a == b and elevator.room_b == a):
			return elevator
	return null


func _redraw_content() -> void:
	if _world_map != null:
		_world_map.queue_redraw()
	for clue_marker in _clue_markers:
		clue_marker.queue_redraw()
	for npc in _npc_nodes:
		npc.queue_redraw()


func _npc_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if case_data == null:
		return tiles
	for suspect in case_data.suspects:
		tiles.append(TileMap2D.world_to_tile(suspect.position))
	return tiles
