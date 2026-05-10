class_name ClueData
extends Resource

@export var id: StringName
@export var label: String
@export var description: String
@export var room: StringName
@export var position: Vector2
@export var unlock_clue_ids: Array[StringName] = []
@export var unlock_suspect_ids: Array[StringName] = []


func _init(
	p_id: StringName = &"",
	p_label: String = "",
	p_description: String = "",
	p_room: StringName = &"",
	p_position: Vector2 = Vector2.ZERO,
	p_unlock_clue_ids: Array[StringName] = [],
	p_unlock_suspect_ids: Array[StringName] = [],
) -> void:
	id = p_id
	label = p_label
	description = p_description
	room = p_room
	position = p_position
	unlock_clue_ids = p_unlock_clue_ids
	unlock_suspect_ids = p_unlock_suspect_ids


func has_unlock_requirements() -> bool:
	return not unlock_clue_ids.is_empty() or not unlock_suspect_ids.is_empty()
