extends Node

var phase: GameEnums.Phase = GameEnums.Phase.EXPLORE
var clues_inspected: Dictionary[StringName, bool] = {}
var suspects_talked: Dictionary[StringName, bool] = {}


func reset(case: CaseData) -> void:
	phase = GameEnums.Phase.EXPLORE
	clues_inspected.clear()
	suspects_talked.clear()
	for clue in case.clues:
		clues_inspected[clue.id] = false
	for suspect in case.suspects:
		suspects_talked[suspect.id] = false
	EventBus.phase_changed.emit(phase)


func set_phase(new_phase: GameEnums.Phase) -> void:
	if phase == new_phase:
		return
	phase = new_phase
	EventBus.phase_changed.emit(phase)


func mark_clue_inspected(clue_id: StringName) -> void:
	if clues_inspected.get(clue_id, false):
		return
	clues_inspected[clue_id] = true
	EventBus.clue_inspected.emit(clue_id)


func mark_suspect_talked(suspect_id: StringName) -> void:
	if suspects_talked.get(suspect_id, false):
		return
	suspects_talked[suspect_id] = true
	EventBus.suspect_talked.emit(suspect_id)


func is_clue_inspected(clue_id: StringName) -> bool:
	return clues_inspected.get(clue_id, false)


func is_suspect_talked(suspect_id: StringName) -> bool:
	return suspects_talked.get(suspect_id, false)


func inspected_clue_count() -> int:
	var n := 0
	for v in clues_inspected.values():
		if v:
			n += 1
	return n


func has_inspected_any_clue() -> bool:
	for v in clues_inspected.values():
		if v:
			return true
	return false


func has_talked_to_any_suspect() -> bool:
	for v in suspects_talked.values():
		if v:
			return true
	return false
