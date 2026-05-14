class_name InteractionDetector
extends RefCounted

static func find_target(
	case: CaseData,
	current_room: StringName,
	player_position: Vector2,
	player_tile: Vector2i,
	player_face_direction: Vector2i,
) -> InteractTarget:
	var npc := _nearest_npc(case, player_position, player_face_direction)
	if npc != null:
		return InteractTarget.new(
			GameEnums.InteractKind.NPC,
			case.suspect_index(npc.id),
			"[E] Talk to %s" % npc.display_name,
			npc.position + Layout.INTERACT_PROMPT_NPC_OFFSET,
		)

	var clue := _nearest_clue(case, player_position, player_face_direction)
	if clue != null:
		return InteractTarget.new(
			GameEnums.InteractKind.CLUE,
			case.clue_index(clue.id),
			"[E] Inspect: %s" % clue.label,
			clue.position + Layout.INTERACT_PROMPT_CLUE_OFFSET,
		)

	var elev_idx := _adjacent_elevator(case, player_tile, player_face_direction)
	if elev_idx >= 0:
		var elev := case.elevators[elev_idx]
		var source_room := _elevator_source_room(elev, player_tile, player_face_direction)
		var target_room := elev.target_room_from(source_room)
		return InteractTarget.new(
			GameEnums.InteractKind.ELEVATOR,
			elev_idx,
			"[E] Take elevator to %s" % _room_label(case, target_room),
			TileMap2D.tile_to_world_center(elev.tile_for(source_room)) + Layout.INTERACT_PROMPT_TILE_OFFSET,
		)

	var door_idx := _adjacent_door(case, player_tile, player_face_direction)
	if door_idx >= 0:
		var door := case.doors[door_idx]
		return InteractTarget.new(
			GameEnums.InteractKind.DOOR,
			door_idx,
			"[E] Open door to %s" % _room_label(case, door.target_from(current_room)),
			TileMap2D.tile_to_world_center(door.tile) + Layout.INTERACT_PROMPT_TILE_OFFSET,
		)

	return InteractTarget.none()


static func _nearest_npc(
	case: CaseData,
	player_position: Vector2,
	player_face_direction: Vector2i,
) -> SuspectData:
	var face_vec := Vector2(player_face_direction)
	var best: SuspectData = null
	var best_dist := INF
	for suspect in case.suspects:
		var d := player_position.distance_to(suspect.position)
		if d > Gameplay.PLAYER_RADIUS + Gameplay.NPC_INTERACT_RADIUS or d >= best_dist:
			continue
		if (suspect.position - player_position).dot(face_vec) <= 0.0:
			continue
		best_dist = d
		best = suspect
	return best


static func _nearest_clue(
	case: CaseData,
	player_position: Vector2,
	player_face_direction: Vector2i,
) -> ClueData:
	var face_vec := Vector2(player_face_direction)
	var best: ClueData = null
	var best_dist := INF
	for clue in case.clues:
		if not UnlockResolver.is_clue_available(clue):
			continue
		var d := player_position.distance_to(clue.position)
		if d > Gameplay.PLAYER_RADIUS + Gameplay.CLUE_INTERACT_RADIUS or d >= best_dist:
			continue
		if (clue.position - player_position).dot(face_vec) <= 0.0:
			continue
		best_dist = d
		best = clue
	return best


static func _adjacent_door(
	case: CaseData,
	player_tile: Vector2i,
	player_face_direction: Vector2i,
) -> int:
	for i in range(case.doors.size()):
		if (case.doors[i].tile - player_tile) == player_face_direction:
			return i
	return -1


static func _adjacent_elevator(
	case: CaseData,
	player_tile: Vector2i,
	player_face_direction: Vector2i,
) -> int:
	for i in range(case.elevators.size()):
		var elev := case.elevators[i]
		if (elev.tile_a - player_tile) == player_face_direction:
			return i
		if (elev.tile_b - player_tile) == player_face_direction:
			return i
	return -1


static func _elevator_source_room(
	elev: ElevatorData,
	player_tile: Vector2i,
	player_face_direction: Vector2i,
) -> StringName:
	if (elev.tile_b - player_tile) == player_face_direction:
		return elev.room_a
	return elev.room_b


static func _room_label(case: CaseData, room_id: StringName) -> String:
	var room := case.room_by_id(room_id)
	return room.label if room != null else String(room_id)
