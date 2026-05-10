class_name CaseData
extends Resource

@export var title: String = ""
@export var question: String = ""
@export var start_room: StringName = &""
@export var player_start_tile: Vector2i = Vector2i.ZERO

@export var suspects: Array[SuspectData] = []
@export var clues: Array[ClueData] = []
@export var rooms: Array[RoomData] = []
@export var doors: Array[DoorData] = []
@export var elevators: Array[ElevatorData] = []

@export var correct_suspect_id: StringName = &""
@export var required_evidence_id: StringName = &""

@export_multiline var verifier_instructions: String = ""
@export_multiline var trusted_case_truth: String = ""

var _suspect_index: Dictionary[StringName, int] = {}
var _clue_index: Dictionary[StringName, int] = {}
var _room_index: Dictionary[StringName, int] = {}


func build_indexes() -> void:
	_suspect_index.clear()
	_clue_index.clear()
	_room_index.clear()
	for i in range(suspects.size()):
		_suspect_index[suspects[i].id] = i
	for i in range(clues.size()):
		_clue_index[clues[i].id] = i
	for i in range(rooms.size()):
		_room_index[rooms[i].id] = i


func suspect_by_id(id: StringName) -> SuspectData:
	var idx: int = _suspect_index.get(id, -1)
	if idx < 0:
		return null
	return suspects[idx]


func clue_by_id(id: StringName) -> ClueData:
	var idx: int = _clue_index.get(id, -1)
	if idx < 0:
		return null
	return clues[idx]


func room_by_id(id: StringName) -> RoomData:
	var idx: int = _room_index.get(id, -1)
	if idx < 0:
		return null
	return rooms[idx]


func suspect_index(id: StringName) -> int:
	return _suspect_index.get(id, -1)


func clue_index(id: StringName) -> int:
	return _clue_index.get(id, -1)


func suspects_in_room(room_id: StringName) -> Array[SuspectData]:
	var result: Array[SuspectData] = []
	for s in suspects:
		if s.room == room_id:
			result.append(s)
	return result


func clues_in_room(room_id: StringName) -> Array[ClueData]:
	var result: Array[ClueData] = []
	for c in clues:
		if c.room == room_id:
			result.append(c)
	return result
