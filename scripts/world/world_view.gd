@tool
class_name WorldView
extends Node2D

@export_group("Movement")
@export_range(60.0, 600.0, 5.0, "or_greater") var player_speed := Gameplay.PLAYER_SPEED:
	set(value):
		player_speed = value
		if _player != null:
			_player.speed = player_speed
@export_range(0.0, 2.0, 0.05, "or_greater") var stair_travel_pause_seconds := 0.35

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
@export var player_texture: Texture2D = preload("res://assets/art/characters/hs_retro/WhiteBunny_A.png"):
	set(value):
		player_texture = value
		_apply_palette()

var case_data: CaseData
var case_state: CaseState

var _world_map: WorldMap
var _player: Player
var _camera: Camera2D
var _npc_nodes: Array[NPC] = []
var _inspectables: Array[Inspectable] = []
var _stair_portals: Array[Node] = []
var _ignored_arrival_portal: Node
var _stair_travel_pause_remaining := 0.0


func _ready() -> void:
	if Engine.is_editor_hint() and case_data == null:
		configure(CaseLoader.load_default())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_apply_camera_to_player(false)
	_update_npc_facing()


func configure(new_case: CaseData, new_state: CaseState = null) -> void:
	if case_state != null and case_state.fact_changed.is_connected(_on_case_fact_changed):
		case_state.fact_changed.disconnect(_on_case_fact_changed)
	case_data = new_case
	case_state = new_state
	if case_state != null and not case_state.fact_changed.is_connected(_on_case_fact_changed):
		case_state.fact_changed.connect(_on_case_fact_changed)
	_rebuild_content()


func reset_player(start_tile: Vector2i) -> void:
	if _player == null:
		return
	_ignored_arrival_portal = null
	_stair_travel_pause_remaining = 0.0
	_player.reset_to_tile(start_tile, _world_map)
	_apply_camera_to_player(true)
	_update_npc_facing()


func update_player_movement(delta: float, held_direction: Vector2i) -> void:
	if _player == null:
		return
	_player.speed = player_speed
	if _stair_travel_pause_remaining > 0.0:
		_stair_travel_pause_remaining = maxf(0.0, _stair_travel_pause_remaining - delta)
		return
	var remaining := delta
	var safety := 8
	while safety > 0:
		safety -= 1
		if _player.is_stepping:
			remaining = _player.process_step(remaining)
			if _stair_travel_pause_remaining > 0.0:
				return
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
		if not Engine.is_editor_hint():
			_player.texture = player_texture
		_player.queue_redraw()


func _apply_camera_to_player(instant: bool) -> void:
	if _camera == null:
		return

	if Engine.is_editor_hint():
		return

	if _player == null:
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
			if _world_map != null and _world_map.world_to_tile(inspectable.position) == tile:
				return inspectable
	return null


func find_npc_at_player() -> NPC:
	if _player == null:
		return null
	for tile in _adjacent_tiles():
		for npc in _npc_nodes:
			if _world_map != null and _world_map.world_to_tile(npc.position) == tile:
				return npc
	return null


func find_inspection_at_player() -> Dictionary:
	var inspectable := find_inspectable_at_player()
	if inspectable != null:
		return _resolve_inspection({
			"object_id": inspectable.object_id,
			"title": inspectable.title,
			"description": inspectable.description,
		})

	if _player == null or _world_map == null:
		return {}

	for tile in _adjacent_tiles():
		var inspection := _world_map.get_tile_inspection(tile)
		if not inspection.is_empty():
			return _resolve_inspection(inspection)

	return {}


func _resolve_inspection(static_inspection: Dictionary) -> Dictionary:
	if case_data == null:
		return static_inspection
	var object_id := StringName(str(static_inspection.get("object_id", "")).strip_edges())
	if object_id == &"":
		return static_inspection
	var definition := case_data.get_interactable(object_id)
	if definition == null:
		return static_inspection
	if not definition.has_method("resolve"):
		push_warning("Interactable definition for '%s' does not implement resolve()." % object_id)
		return static_inspection
	return definition.call("resolve", case_state, static_inspection)


func _adjacent_tiles() -> Array[Vector2i]:
	var player_tile := _player.tile
	var facing_tile := player_tile + _player.face_direction
	var tiles: Array[Vector2i] = [
		facing_tile,
		player_tile + Vector2i(1, 0),
		player_tile + Vector2i(-1, 0),
		player_tile + Vector2i(0, 1),
		player_tile + Vector2i(0, -1),
	]
	return tiles


func _rebuild_content() -> void:
	_npc_nodes.clear()
	_inspectables.clear()
	_stair_portals.clear()
	_ignored_arrival_portal = null
	_stair_travel_pause_remaining = 0.0
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
		elif child.has_method("get_target") and child.has_method("get_tile"):
			_stair_portals.append(child)

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
		_player.visible = true
		if not Engine.is_editor_hint():
			_player.reset_to_current_position(_world_map)
		_update_npc_facing()

	if _player != null and _world_map != null:
		if not _player.moved.is_connected(_on_player_moved):
			_player.moved.connect(_on_player_moved)
		_world_map.update_cover_visibility(_player.tile)
	_refresh_inspectable_tile_visuals()

	_apply_palette()
	_apply_camera_to_player(false)


func _on_player_moved(tile: Vector2i) -> void:
	if _world_map != null:
		_world_map.update_cover_visibility(tile)
	_try_use_stair_portal(tile)


func _on_case_fact_changed(_fact_id: StringName, _value: bool) -> void:
	_refresh_inspectable_tile_visuals()


func _refresh_inspectable_tile_visuals() -> void:
	if _world_map == null:
		return
	for inspectable in _inspectables:
		inspectable.refresh_tile_visual(_world_map, case_state)


func _update_npc_facing() -> void:
	if _player == null:
		return
	for npc in _npc_nodes:
		npc.look_at_position(_player.position)


func _blocked_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for npc in _npc_nodes:
		if _world_map != null:
			tiles.append(_world_map.world_to_tile(npc.position))
	for inspectable in _inspectables:
		if inspectable.blocks_movement:
			if _world_map != null:
				tiles.append(_world_map.world_to_tile(inspectable.position))
	return tiles


func _try_use_stair_portal(tile: Vector2i) -> void:
	if _player == null or _world_map == null:
		return

	if _ignored_arrival_portal != null:
		if _portal_contains_tile(_ignored_arrival_portal, tile):
			return
		_ignored_arrival_portal = null

	for portal in _stair_portals:
		if not portal.get("enabled") or not _portal_contains_tile(portal, tile):
			continue
		var target := portal.call("get_target") as Node
		if target == null:
			push_warning("StairPortal '%s' has no target_portal." % portal.name)
			return
		_ignored_arrival_portal = target
		_player.reset_to_tile(target.call("get_tile", _world_map), _world_map)
		_stair_travel_pause_remaining = stair_travel_pause_seconds
		_apply_camera_to_player(true)
		_update_npc_facing()
		return


func _portal_contains_tile(portal: Node, tile: Vector2i) -> bool:
	if portal.has_method("contains_tile"):
		return portal.call("contains_tile", tile, _world_map)
	return portal.call("get_tile", _world_map) == tile
