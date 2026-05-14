@tool
class_name WorldView
extends Node2D

const _EDITOR_PREVIEW_ROOM_IDS: Array[StringName] = [
	CaseLoader.ROOM_CONCIERGE,
	CaseLoader.ROOM_1220,
	CaseLoader.ROOM_GEAR,
	CaseLoader.ROOM_HALL,
	CaseLoader.ROOM_SUITE,
	CaseLoader.ROOM_LOBBY,
	CaseLoader.ROOM_CHUTE,
	CaseLoader.ROOM_1223,
]

@export_group("Editor Preview")
@export_enum(
	"Concierge / Security",
	"Room 1220",
	"Gear Cart",
	"Twelfth Floor Hall",
	"Suite 1221",
	"Elevator Lobby",
	"Chute Access",
	"Room 1223"
) var editor_preview_room_index := 5:
	set(value):
		editor_preview_room_index = value
		if Engine.is_editor_hint():
			current_room = _editor_preview_room_id()
		refresh()
@export var editor_show_locked_clues := true:
	set(value):
		editor_show_locked_clues = value
		refresh()

@export_group("Movement")
@export_range(60.0, 600.0, 5.0, "or_greater") var player_speed := Gameplay.PLAYER_SPEED:
	set(value):
		player_speed = value
		if _player != null:
			_player.speed = player_speed

@export_group("Camera")
@export_range(0.0, 200.0, 1.0, "or_greater") var camera_padding := 30.0:
	set(value):
		camera_padding = value
		_apply_camera_to_room(true)
@export_range(0.0, 3.0, 0.05, "or_greater") var camera_transition_seconds := 1.3:
	set(value):
		camera_transition_seconds = value
@export var editor_show_all_rooms := true:
	set(value):
		editor_show_all_rooms = value
		refresh()

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
@export var room_border_color := Palette.ROOM_BORDER:
	set(value):
		room_border_color = value
		refresh()
@export var room_label_color := Palette.ROOM_LABEL:
	set(value):
		room_label_color = value
		refresh()
@export_range(8, 24, 1, "or_greater") var room_label_font_size := Layout.ROOM_LABEL_FONT_SIZE:
	set(value):
		room_label_font_size = value
		refresh()

var case_data: CaseData
var current_room: StringName = CaseLoader.ROOM_LOBBY

var _world_map: WorldMap
var _player: Player
var _camera: Camera2D
var _camera_tween: Tween
var _room_zones: Array[RoomZone] = []
var _npc_nodes: Array[NPC] = []
var _clue_markers: Array[ClueMarker] = []
var _door_nodes: Array[Door] = []
var _elevator_nodes: Array[Elevator] = []


func _ready() -> void:
	if Engine.is_editor_hint() and case_data == null:
		configure(CaseLoader.load_default())


func configure(new_case: CaseData) -> void:
	case_data = new_case
	if Engine.is_editor_hint():
		current_room = _editor_preview_room_id()
	elif case_data != null:
		current_room = case_data.start_room
	_rebuild_content()


func reset_player(start_tile: Vector2i) -> void:
	if _player == null:
		return
	_player.reset_to_tile(start_tile)


func transition_to(room_id: StringName, spawn_tile: Vector2i) -> void:
	current_room = room_id
	reset_player(spawn_tile)
	refresh()


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


func door_spawn_tile(door: DoorData) -> Vector2i:
	return door.tile * 2 - player_tile()


func refresh() -> void:
	if _world_map == null:
		return

	var show_all := Engine.is_editor_hint() and editor_show_all_rooms
	_world_map.show_all_rooms = show_all
	_world_map.background_color = background_color
	_world_map.set_current_room(current_room)

	for room_zone in _room_zones:
		room_zone.border_color = room_border_color
		room_zone.label_color = room_label_color
		room_zone.label_font_size = room_label_font_size
		room_zone.set_current_room(current_room)
		if show_all:
			room_zone.visible = true
			room_zone._apply_label()
			room_zone.queue_redraw()

	for door_node in _door_nodes:
		door_node.set_current_room(current_room)
		if show_all:
			door_node.visible = true

	for elevator_node in _elevator_nodes:
		elevator_node.set_current_room(current_room)
		if show_all:
			elevator_node.visible = true

	for clue_marker in _clue_markers:
		clue_marker.clue_color = clue_color
		clue_marker.clue_inspected_color = clue_inspected_color
		clue_marker.outline_color = outline_color
		clue_marker.show_locked_clues = Engine.is_editor_hint() and editor_show_locked_clues
		clue_marker.set_current_room(current_room)
		if show_all:
			clue_marker.visible = true

	for npc in _npc_nodes:
		npc.set_current_room(current_room)
		if show_all:
			npc.visible = true

	if _player != null:
		_player.speed = player_speed
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.visible = not Engine.is_editor_hint()
		_player.queue_redraw()

	_redraw_content()
	_apply_camera_to_room(false)


func _apply_camera_to_room(instant: bool) -> void:
	if _camera == null or case_data == null:
		return

	var target_rect: Rect2
	if Engine.is_editor_hint() and editor_show_all_rooms:
		target_rect = Rect2(Vector2.ZERO, TileMap2D.VIEW_SIZE)
	else:
		var room := case_data.room_by_id(current_room)
		if room == null:
			return
		target_rect = room.rect

	var viewport_size := Vector2(TileMap2D.VIEW_SIZE)
	var padded_size := target_rect.size + Vector2(camera_padding, camera_padding) * 2.0
	if padded_size.x <= 0.0 or padded_size.y <= 0.0:
		return
	var zoom_factor := minf(viewport_size.x / padded_size.x, viewport_size.y / padded_size.y)
	var target_zoom := Vector2(zoom_factor, zoom_factor)
	var target_position := target_rect.position + target_rect.size * 0.5

	if _camera_tween != null and _camera_tween.is_valid():
		_camera_tween.kill()

	if instant or Engine.is_editor_hint() or camera_transition_seconds <= 0.0 or not is_inside_tree():
		_camera.position = target_position
		_camera.zoom = target_zoom
		return

	_camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_property(_camera, "position", target_position, camera_transition_seconds)
	_camera_tween.tween_property(_camera, "zoom", target_zoom, camera_transition_seconds)


func _editor_preview_room_id() -> StringName:
	var index := clampi(editor_preview_room_index, 0, _EDITOR_PREVIEW_ROOM_IDS.size() - 1)
	return _EDITOR_PREVIEW_ROOM_IDS[index]


func _rebuild_content() -> void:
	_room_zones.clear()
	_npc_nodes.clear()
	_clue_markers.clear()
	_door_nodes.clear()
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
		elif child is RoomZone:
			_room_zones.append(child)
		elif child is NPC:
			_npc_nodes.append(child)
		elif child is ClueMarker:
			_clue_markers.append(child)
		elif child is Door:
			_door_nodes.append(child)
		elif child is Elevator:
			_elevator_nodes.append(child)

	if _camera != null and not Engine.is_editor_hint():
		_camera.make_current()

	if case_data == null:
		return

	if _world_map != null:
		_world_map.configure(case_data)

	for room_zone in _room_zones:
		var room := case_data.room_by_id(room_zone.entity_id)
		if room != null:
			room_zone.configure(room)

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

	for door_node in _door_nodes:
		var door := _find_door(door_node.room_a, door_node.room_b)
		if door != null:
			door.tile = _node_to_tile(door_node.position)
			door_node.configure(door)

	for elevator_node in _elevator_nodes:
		var elevator := _find_elevator(elevator_node.room_a, elevator_node.room_b)
		if elevator != null:
			elevator_node.configure(elevator)

	refresh()


func _node_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(
		roundi(world_position.x / TileMap2D.TILE_SIZE),
		roundi(world_position.y / TileMap2D.TILE_SIZE),
	)


func _find_door(a: StringName, b: StringName) -> DoorData:
	for door in case_data.doors:
		if (door.room_a == a and door.room_b == b) or (door.room_a == b and door.room_b == a):
			return door
	return null


func _find_elevator(a: StringName, b: StringName) -> ElevatorData:
	for elevator in case_data.elevators:
		if (elevator.room_a == a and elevator.room_b == b) or (elevator.room_a == b and elevator.room_b == a):
			return elevator
	return null


func _redraw_content() -> void:
	if _world_map != null:
		_world_map.queue_redraw()
	for room_zone in _room_zones:
		room_zone.queue_redraw()
	for clue_marker in _clue_markers:
		clue_marker.queue_redraw()
	for npc in _npc_nodes:
		npc.queue_redraw()


func _npc_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if case_data == null:
		return tiles
	for suspect in case_data.suspects:
		if suspect.room == current_room:
			tiles.append(TileMap2D.world_to_tile(suspect.position))
	return tiles
