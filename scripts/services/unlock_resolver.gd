class_name UnlockResolver
extends RefCounted

static func is_clue_available(clue: ClueData) -> bool:
	if clue == null:
		return false
	if not clue.has_unlock_requirements():
		return true
	for required_clue_id in clue.unlock_clue_ids:
		if not GameState.is_clue_inspected(required_clue_id):
			return false
	for required_suspect_id in clue.unlock_suspect_ids:
		if not GameState.is_suspect_talked(required_suspect_id):
			return false
	return true


static func is_hint_active(hint: UnlockHint) -> bool:
	for clue_id in hint.required_clue_ids:
		if not GameState.is_clue_inspected(clue_id):
			return false
	for suspect_id in hint.required_suspect_ids:
		if not GameState.is_suspect_talked(suspect_id):
			return false
	return true


static func active_hint_lines(case: CaseData) -> Array[String]:
	var lines: Array[String] = []
	for hint in case.unlock_hints:
		if is_hint_active(hint):
			lines.append("- %s" % hint.text)
	return lines


static func unlocked_context(case: CaseData) -> String:
	var lines := active_hint_lines(case)
	if lines.is_empty():
		return "No extra case unlocks are active yet."
	return "Current investigation unlocks:\n%s" % "\n".join(lines)
