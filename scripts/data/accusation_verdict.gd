class_name AccusationVerdict
extends RefCounted

var is_correct: bool = false
var headline: String = ""
var feedback: String = ""
var suspect_id: StringName = &""
var clue_id: StringName = &""
var explanation: String = ""


func _init(
	p_is_correct: bool = false,
	p_headline: String = "",
	p_feedback: String = "",
	p_suspect_id: StringName = &"",
	p_clue_id: StringName = &"",
	p_explanation: String = "",
) -> void:
	is_correct = p_is_correct
	headline = p_headline
	feedback = p_feedback
	suspect_id = p_suspect_id
	clue_id = p_clue_id
	explanation = p_explanation
