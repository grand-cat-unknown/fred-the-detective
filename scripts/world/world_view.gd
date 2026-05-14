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

@export_group("Palette")
@export var background_color := Palette.BACKGROUND:
	set(value):
		background_color = value
		refresh()
@export var floor_color := Palette.FLOOR:
	set(value):
		floor_color = value
		refresh()
@export var floor_alt_color := Palette.FLOOR_ALT:
	set(value):
		floor_alt_color = value
		refresh()
@export var wall_color := Palette.WALL:
	set(value):
		wall_color = value
		refresh()
@export var wall_top_color := Palette.WALL_TOP:
	set(value):
		wall_top_color = value
		refresh()
@export var rug_color := Palette.RUG:
	set(value):
		rug_color = value
		refresh()
@export var rug_trim_color := Palette.RUG_TRIM:
	set(value):
		rug_trim_color = value
		refresh()
@export var runner_color := Palette.RUNNER:
	set(value):
		runner_color = value
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

	_world_map.background_color = background_color
	_world_map.floor_color = floor_color
	_world_map.floor_alt_color = floor_alt_color
	_world_map.wall_color = wall_color
	_world_map.wall_top_color = wall_top_color
	_world_map.rug_color = rug_color
	_world_map.rug_trim_color = rug_trim_color
	_world_map.runner_color = runner_color
	_world_map.outline_color = outline_color
	_world_map.set_current_room(current_room)

	for room_zone in _room_zones:
		room_zone.border_color = room_border_color
		room_zone.label_color = room_label_color
		room_zone.label_font_size = room_label_font_size
		room_zone.set_current_room(current_room)

	for door_node in _door_nodes:
		door_node.door_color = Palette.DOOR
		door_node.trim_color = Palette.DOOR_TRIM
		door_node.outline_color = outline_color
		door_node.set_current_room(current_room)

	for elevator_node in _elevator_nodes:
		elevator_node.outline_color = outline_color
		elevator_node.set_current_room(current_room)

	for clue_marker in _clue_markers:
		clue_marker.clue_color = clue_color
		clue_marker.clue_inspected_color = clue_inspected_color
		clue_marker.outline_color = outline_color
		clue_marker.show_locked_clues = Engine.is_editor_hint() and editor_show_locked_clues
		clue_marker.set_current_room(current_room)

	for npc in _npc_nodes:
		npc.set_current_room(current_room)

	if _player != null:
		_player.speed = player_speed
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.visible = not Engine.is_editor_hint()
		_player.queue_redraw()

	_redraw_content()


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

	for child in get_children():
		if child is WorldMap:
			_world_map = child
		elif child is Player:
			_player = child
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
			npc.configure(suspect)

	for clue_marker in _clue_markers:
		var clue := case_data.clue_by_id(clue_marker.entity_id)
		if clue != null:
			clue_marker.configure(clue)

	for door_node in _door_nodes:
		var door := _find_door(door_node.room_a, door_node.room_b)
		if door != null:
			door_node.configure(door)

	for elevator_node in _elevator_nodes:
		var elevator := _find_elevator(elevator_node.room_a, elevator_node.room_b)
		if elevator != null:
			elevator_node.configure(elevator)

	refresh()


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
	for door_node in _door_nodes:
		door_node.queue_redraw()
	for elevator_node in _elevator_nodes:
		elevator_node.queue_redraw()
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
