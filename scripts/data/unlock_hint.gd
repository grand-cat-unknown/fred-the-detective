class_name UnlockHint
extends Resource

@export var required_clue_ids: Array[StringName] = []
@export var required_suspect_ids: Array[StringName] = []
@export_multiline var text: String = ""


func _init(
	p_required_clue_ids: Array[StringName] = [],
	p_required_suspect_ids: Array[StringName] = [],
	p_text: String = "",
) -> void:
	required_clue_ids = p_required_clue_ids
	required_suspect_ids = p_required_suspect_ids
	text = p_text
