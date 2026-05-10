class_name AccusationService
extends Node

const _MENTION_KEYWORDS := {
	"cell": ["cell", "ghost cell", "spare"],
	"idol": ["idol", "anchor"],
	"method": ["discharge", "opened", "purge", "vent", "residue", "burn"],
	"pemberton_link": ["glove", "1220", "sweep", "motive", "research", "pemberton"],
}

var _case: CaseData
var _llm: LLMClient

var _step: GameEnums.AccusationStep = GameEnums.AccusationStep.PICK_SUSPECT
var _suspect_id: StringName = &""
var _evidence_id: StringName = &""
var _explanation: String = ""
var _is_busy: bool = false


func configure(case: CaseData, llm: LLMClient) -> void:
	_case = case
	_llm = llm
	if not _llm.accusation_completed.is_connected(_on_accusation_completed):
		_llm.accusation_completed.connect(_on_accusation_completed)
	if not _llm.accusation_failed.is_connected(_on_accusation_failed):
		_llm.accusation_failed.connect(_on_accusation_failed)


func reset() -> void:
	_step = GameEnums.AccusationStep.PICK_SUSPECT
	_suspect_id = &""
	_evidence_id = &""
	_explanation = ""
	_is_busy = false


func step() -> GameEnums.AccusationStep:
	return _step


func is_busy() -> bool:
	return _is_busy


func picked_suspect_id() -> StringName:
	return _suspect_id


func picked_evidence_id() -> StringName:
	return _evidence_id


func can_accuse() -> bool:
	return GameState.has_inspected_any_clue() and GameState.has_talked_to_any_suspect()


func start() -> void:
	reset()
	_set_step(GameEnums.AccusationStep.PICK_SUSPECT)
	EventBus.accusation_started.emit()


func cancel() -> void:
	if _is_busy:
		return
	reset()
	EventBus.accusation_cancelled.emit()


func choose_suspect(suspect_id: StringName) -> void:
	if _is_busy:
		return
	_suspect_id = suspect_id
	_set_step(GameEnums.AccusationStep.PICK_EVIDENCE)


func choose_evidence(clue_id: StringName) -> void:
	if _is_busy:
		return
	_evidence_id = clue_id
	_set_step(GameEnums.AccusationStep.EXPLAIN)


func submit(explanation: String) -> bool:
	if _is_busy:
		return false
	if _suspect_id == &"" or _evidence_id == &"":
		return false
	var trimmed := explanation.strip_edges()
	if trimmed.is_empty():
		return false
	_explanation = trimmed
	_is_busy = true
	_set_step(GameEnums.AccusationStep.RESOLVING)
	EventBus.accusation_busy_changed.emit(true, "Reviewing your case...")
	var prompt_input := _build_verifier_input(_suspect_id, _evidence_id, trimmed)
	if not _llm.request_accusation(_suspect_id, _evidence_id, trimmed, prompt_input, _case.verifier_instructions):
		if _is_busy:
			_resolve_with_local("The verifier could not be reached, so Fred checked the theory against the case board.")
	return true


func _on_accusation_completed(
	verdict_text: String,
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
) -> void:
	if not _matches_pending(suspect_id, clue_id, explanation):
		return
	var verdict := _parse_verdict_payload(verdict_text)
	if verdict == null:
		_resolve_with_local("The verifier returned an unclear verdict, so Fred checked the theory against the case board.")
		return
	verdict.suspect_id = suspect_id
	verdict.clue_id = clue_id
	verdict.explanation = explanation
	_finalize(verdict)


func _on_accusation_failed(
	reason: String,
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
) -> void:
	if not _matches_pending(suspect_id, clue_id, explanation):
		return
	_resolve_with_local(reason)


func _matches_pending(suspect_id: StringName, clue_id: StringName, explanation: String) -> bool:
	return _is_busy and suspect_id == _suspect_id and clue_id == _evidence_id and explanation == _explanation


func _resolve_with_local(prefix: String) -> void:
	var verdict := _build_local_verdict(_suspect_id, _evidence_id, _explanation, prefix)
	_finalize(verdict)


func _finalize(verdict: AccusationVerdict) -> void:
	var corrected := _coerce_verdict(verdict)
	_is_busy = false
	EventBus.accusation_busy_changed.emit(false, "")
	_set_step(GameEnums.AccusationStep.DONE)
	EventBus.accusation_resolved.emit(corrected)


func _coerce_verdict(verdict: AccusationVerdict) -> AccusationVerdict:
	var right_suspect := verdict.suspect_id == _case.correct_suspect_id
	var right_evidence := verdict.clue_id == _case.required_evidence_id
	var verifier_correct := verdict.is_correct
	verdict.is_correct = verifier_correct and right_suspect and right_evidence

	if verdict.headline.is_empty():
		verdict.headline = "Correct" if verdict.is_correct else "Not proven"
	if verdict.feedback.is_empty():
		verdict.feedback = _default_feedback(verdict.suspect_id, verdict.clue_id, verdict.explanation)
	if verifier_correct and not verdict.is_correct:
		verdict.headline = "Not proven"
		verdict.feedback = _default_feedback(verdict.suspect_id, verdict.clue_id, verdict.explanation)
	return verdict


func _set_step(new_step: GameEnums.AccusationStep) -> void:
	_step = new_step
	EventBus.accusation_step_changed.emit(new_step)


func _build_verifier_input(suspect_id: StringName, clue_id: StringName, explanation: String) -> String:
	var found_clues: Array[String] = []
	for clue in _case.clues:
		if GameState.is_clue_inspected(clue.id):
			found_clues.append("- %s: %s" % [clue.label, clue.description])

	var talked_names: Array[String] = []
	for suspect in _case.suspects:
		if GameState.is_suspect_talked(suspect.id):
			talked_names.append(suspect.display_name)

	var found_text := "\n".join(found_clues) if not found_clues.is_empty() else "(no clues inspected)"
	var talked_text := ", ".join(talked_names) if not talked_names.is_empty() else "(no suspects questioned)"

	var accused := _case.suspect_by_id(suspect_id)
	var clue := _case.clue_by_id(clue_id)
	var accused_name := accused.display_name if accused != null else "(unknown)"
	var clue_label := clue.label if clue != null else "(unknown)"

	return "%s\n\nPlayer progress:\nInspected clues:\n%s\nQuestioned suspects: %s\n\nPlayer accusation:\n- Accused suspect: %s\n- Chosen key evidence: %s\n- Explanation: %s" % [
		_case.trusted_case_truth,
		found_text,
		talked_text,
		accused_name,
		clue_label,
		explanation,
	]


func _parse_verdict_payload(reply: String) -> AccusationVerdict:
	var text := reply.strip_edges()
	if text.begins_with("```"):
		var first_newline := text.find("\n")
		var last_fence := text.rfind("```")
		if first_newline >= 0 and last_fence > first_newline:
			text = text.substr(first_newline + 1, last_fence - first_newline - 1).strip_edges()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		var start := text.find("{")
		var end := text.rfind("}")
		if start >= 0 and end > start:
			parsed = JSON.parse_string(text.substr(start, end - start + 1))

	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	var verdict_dict: Dictionary = parsed
	if not verdict_dict.has("is_correct"):
		return null

	return AccusationVerdict.new(
		bool(verdict_dict.get("is_correct", false)),
		str(verdict_dict.get("headline", "")).strip_edges(),
		str(verdict_dict.get("feedback", "")).strip_edges(),
	)


func _build_local_verdict(
	suspect_id: StringName,
	clue_id: StringName,
	explanation: String,
	prefix: String,
) -> AccusationVerdict:
	var right_suspect := suspect_id == _case.correct_suspect_id
	var right_evidence := clue_id == _case.required_evidence_id
	var explanation_fits := _explanation_mentions_core_solution(explanation)
	var is_correct := right_suspect and right_evidence and explanation_fits
	var feedback := _default_feedback(suspect_id, clue_id, explanation)
	if not prefix.is_empty():
		feedback = "%s %s" % [prefix, feedback]

	return AccusationVerdict.new(
		is_correct,
		"Correct" if is_correct else "Not proven",
		feedback,
		suspect_id,
		clue_id,
		explanation,
	)


func _default_feedback(suspect_id: StringName, clue_id: StringName, explanation: String) -> String:
	var right_suspect := suspect_id == _case.correct_suspect_id
	var right_evidence := clue_id == _case.required_evidence_id
	if right_suspect and right_evidence and _explanation_mentions_core_solution(explanation):
		return "The theory holds: Pemberton used the charged ghost cell, hid the idol inside it, and his gloves and false 1220 sweep tie him to the cover-up."
	if right_suspect and right_evidence:
		return "The suspect and clue are right, but the explanation needs to connect the ghost cell to the idol, the murder method, and Pemberton's opportunity."
	if right_suspect:
		return "Pemberton is the right suspect, but this clue alone does not prove how the idol theft and cell discharge fit together."
	return "The accusation does not fit the authored case facts."


func _explanation_mentions_core_solution(explanation: String) -> bool:
	var text := explanation.to_lower()
	for category in _MENTION_KEYWORDS:
		var keywords: Array = _MENTION_KEYWORDS[category]
		if not _text_mentions_any(text, keywords):
			return false
	return true


static func _text_mentions_any(text: String, keywords: Array) -> bool:
	for keyword in keywords:
		if text.contains(str(keyword)):
			return true
	return false
