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
@export_range(0.0, 30.0, 0.5, "or_greater") var camera_follow_smoothing := 0.0:
	set(value):
		camera_follow_smoothing = value
		_apply_camera_smoothing()

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
@export var player_texture: Texture2D = preload("res://HS-Characters Retro/WhiteBunny_A.png"):
	set(value):
		player_texture = value
		_apply_palette()

var case_data: CaseData

var _world_map: WorldMap
var _player: Player
var _camera: Camera2D
var _npc_nodes: Array[NPC] = []
var _inspectables: Array[Inspectable] = []


func _ready() -> void:
	if Engine.is_editor_hint() and case_data == null:
		configure(CaseLoader.load_default())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_apply_camera_to_player(false)


func configure(new_case: CaseData) -> void:
	case_data = new_case
	_rebuild_content()


func reset_player(start_tile: Vector2i) -> void:
	if _player == null:
		return
	_player.reset_to_tile(start_tile)
	_apply_camera_to_player(true)


func update_player_movement(delta: float, held_direction: Vector2i) -> void:
	if _player == null:
		return
	_player.speed = player_speed
	var remaining := delta
	var safety := 8
	while safety > 0:
		safety -= 1
		if _player.is_stepping:
			remaining = _player.process_step(remaining)
			if _player.is_stepping or remaining <= 0.0:
				return
		if held_direction == Vector2i.ZERO:
			return
		if not _player.try_step(held_direction, _world_map, _blocked_tiles()):
			return


func _apply_palette() -> void:
	if _world_map != null:
		_world_map.background_color = background_color
	if _player != null:
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.texture = player_texture
		_player.queue_redraw()


func _apply_camera_to_player(instant: bool) -> void:
	if _camera == null:
		return

	if Engine.is_editor_hint() or _player == null:
		_camera.position_smoothing_enabled = false
		_camera.position = TileMap2D.VIEW_SIZE * 0.5
		_camera.zoom = Vector2.ONE
		return

	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	_camera.position = _player.position

	if instant:
		_camera.position_smoothing_enabled = false
		_camera.reset_smoothing()
		_apply_camera_smoothing()
	else:
		_apply_camera_smoothing()


func _apply_camera_smoothing() -> void:
	if _camera == null:
		return
	var enabled := camera_follow_smoothing > 0.0 and not Engine.is_editor_hint()
	_camera.position_smoothing_enabled = enabled
	if enabled:
		_camera.position_smoothing_speed = camera_follow_smoothing


func find_inspectable_at_player() -> Inspectable:
	if _player == null:
		return null
	var player_tile := _player.tile
	var facing_tile := player_tile + _player.face_direction
	var candidates: Array[Vector2i] = [
		facing_tile,
		player_tile + Vector2i(1, 0),
		player_tile + Vector2i(-1, 0),
		player_tile + Vector2i(0, 1),
		player_tile + Vector2i(0, -1),
	]
	for tile in candidates:
		for inspectable in _inspectables:
			if inspectable.get_tile() == tile:
				return inspectable
	return null


func find_inspection_at_player() -> Dictionary:
	var inspectable := find_inspectable_at_player()
	if inspectable != null:
		return {
			"object_id": inspectable.object_id,
			"title": inspectable.title,
			"description": inspectable.description,
		}

	if _player == null:
		return {}

	var player_tile := _player.tile
	var facing_tile := player_tile + _player.face_direction
	var candidates: Array[Vector2i] = [
		facing_tile,
		player_tile + Vector2i(1, 0),
		player_tile + Vector2i(-1, 0),
		player_tile + Vector2i(0, 1),
		player_tile + Vector2i(0, -1),
	]

	for tile in candidates:
		for npc in _npc_nodes:
			if npc.get_tile() == tile:
				var line := ""
				if npc.suspect != null:
					line = npc.suspect.dialogue
				return {
					"object_id": npc.entity_id,
					"title": npc.get_display_name(),
					"description": line,
				}

	if _world_map == null:
		return {}

	for tile in candidates:
		var inspection := _world_map.get_tile_inspection(tile)
		if not inspection.is_empty():
			return inspection

	return {}


func _rebuild_content() -> void:
	_npc_nodes.clear()
	_inspectables.clear()
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
		elif child is Inspectable:
			_inspectables.append(child)

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


func _blocked_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for npc in _npc_nodes:
		tiles.append(TileMap2D.world_to_tile(npc.position))
	for inspectable in _inspectables:
		if inspectable.blocks_movement:
			tiles.append(inspectable.get_tile())
	return tiles
