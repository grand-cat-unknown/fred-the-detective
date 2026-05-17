class_name AccusationJudge
extends Node

signal completed(is_correct: bool, message: String)
signal failed(message: String)

const CORRECT_KILLER := &"otis"
const REQUIRED_EVIDENCE_FACT := &"has_evidence"
const REQUIRED_FIELD_BOOK_FACT := &"has_field_book"
const REQUIRED_PALMS_FACT := &"pemberton_palms_shown"
const REASON_CORRECT := "correct"
const REASON_MISSING_EVIDENCE := "missing_evidence"
const REASON_WRONG_PERSON := "wrong_person"
const REASON_WRONG_METHOD := "wrong_method"
const REASON_WRONG_EVIDENCE := "wrong_evidence"
const REASON_PARTIAL := "partial"
const REASON_MULTIPLE_WRONG := "multiple_wrong"

var _llm: LLMClient
var _state: CaseState
var _pending := false


func configure(llm: LLMClient, state: CaseState) -> void:
	if _llm != null and _llm.completed.is_connected(_on_llm_completed):
		_llm.completed.disconnect(_on_llm_completed)
	_llm = llm
	_state = state
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)


func is_busy() -> bool:
	return _pending or (_llm != null and _llm.is_busy())


func judge(killer_id: StringName, killer_label: String, method_text: String, evidence_text: String) -> void:
	if _llm == null or _state == null:
		failed.emit("The accusation judge is not ready.")
		return
	if is_busy():
		failed.emit("The accusation judge is still thinking.")
		return

	var method := method_text.strip_edges()
	var evidence := evidence_text.strip_edges()
	if killer_id == &"" or method == "" or evidence == "":
		completed.emit(false, "The accusation needs a suspect, a method, and evidence.")
		return
	if killer_id != CORRECT_KILLER:
		completed.emit(false, _message_for_reason(false, REASON_WRONG_PERSON))
		return
	if not _has_all_required_final_facts():
		completed.emit(false, _message_for_reason(false, REASON_MISSING_EVIDENCE))
		return

	var payload := {
		"accusation": {
			"killer_id": str(killer_id),
			"killer_label": killer_label,
			"method_text": method,
			"evidence_text": evidence,
		},
		"case_truth": {
			"killer_id": str(CORRECT_KILLER),
			"killer_name": "Dr. Otis Pemberton",
			"method": "Otis used the hidden service passage to enter Suite 1102 and killed Felix Vance with a Siren-grade containment cell as a point-blank weapon, like a gun.",
			"required_evidence": "Fred must have found the recovered Siren containment cell, have Theo's field book/manual explaining the manual-purge signature, and have made Otis show his violet-stained palms.",
			"required_evidence_facts": [
				str(REQUIRED_EVIDENCE_FACT),
				str(REQUIRED_FIELD_BOOK_FACT),
				str(REQUIRED_PALMS_FACT),
			],
		},
		"current_true_facts": _state.true_fact_ids(),
		"has_required_evidence": _state.get_fact(REQUIRED_EVIDENCE_FACT, false),
		"has_required_field_book": _state.get_fact(REQUIRED_FIELD_BOOK_FACT, false),
		"has_required_palms": _state.get_fact(REQUIRED_PALMS_FACT, false),
	}

	var instructions := "\n\n".join([
		"You are the final accusation judge for Fred the Detective.",
		"Return strict structured JSON only.",
		"Do not reveal, name, hint at, or explain the correct solution in the output.",
		"Do not mention correct case details unless they were already present in the player's accusation text.",
		"The accusation is correct only if all of these are true:",
		"1. The selected killer is Dr. Otis Pemberton.",
		"2. The method text covers BOTH (a) Otis entered Suite 1102 via a hidden service passage / secret corridor / hidden route, AND (b) killed Vance with the Siren containment cell used as the murder weapon, effectively as a gun or point-blank discharge device. Both ideas must be present for the method to be accepted.",
		"3. The evidence text identifies the recovered/missing Siren containment cell or equivalent direct physical proof.",
		"4. The evidence text also connects the manual-purge mechanism to Otis's violet-stained palms, using the field book/manual logic.",
		"5. has_required_evidence, has_required_field_book, and has_required_palms are all true. If any are false, the player is accusing without the facts needed for the final proof.",
		"Accept natural wording and small spelling mistakes. Reject vague answers such as only 'ghost', 'weapon', or 'evidence'.",
		"Set is_correct to true only for a complete, supported accusation.",
		"Set reason_code to exactly one enum value. Prefer missing_evidence when any required fact is false and the player tries to use the final proof.",
		"Use multiple_wrong when more than one category is wrong or unclear.",
		"Use partial when the player has picked Otis, has_required_evidence + has_required_field_book + has_required_palms are all true, and at least one of the four content ideas (hidden-passage entry, Siren-cell-as-weapon, recovered cell as physical proof, manual-purge / field-book reasoning tying to palm stains) is clearly present in the method or evidence text, but the accusation is still incomplete because one or more of those four ideas is missing or vague. Use partial in preference to wrong_method or wrong_evidence when the player is on the right track and the killer pick is Otis.",
	])
	var messages := [
		{
			"role": "user",
			"content": JSON.stringify(payload, "\t"),
		}
	]
	var err := _llm.send(instructions, messages, _build_text_format(), 450)
	if err != OK:
		failed.emit("Could not judge the accusation (%s)." % err)
		return
	_pending = true


func _build_text_format() -> Dictionary:
	return {
		"type": "json_schema",
		"name": "final_accusation_judgment",
		"description": "Final game accusation result.",
		"strict": true,
		"schema": {
			"type": "object",
			"additionalProperties": false,
			"properties": {
				"is_correct": {
					"type": "boolean",
				},
				"reason_code": {
					"type": "string",
					"enum": [
						REASON_CORRECT,
						REASON_MISSING_EVIDENCE,
						REASON_WRONG_PERSON,
						REASON_WRONG_METHOD,
						REASON_WRONG_EVIDENCE,
						REASON_PARTIAL,
						REASON_MULTIPLE_WRONG,
					],
				},
			},
			"required": ["is_correct", "reason_code"],
		},
	}


func _has_all_required_final_facts() -> bool:
	return (
		_state.get_fact(REQUIRED_EVIDENCE_FACT, false)
		and _state.get_fact(REQUIRED_FIELD_BOOK_FACT, false)
		and _state.get_fact(REQUIRED_PALMS_FACT, false)
	)


func _on_llm_completed(text: String, error: String) -> void:
	if not _pending:
		return
	_pending = false
	if error != "":
		failed.emit(error)
		return

	var parsed: Variant = JSON.parse_string(text.strip_edges())
	if typeof(parsed) != TYPE_DICTIONARY:
		failed.emit("The accusation judge returned invalid structured output.")
		return

	var is_correct := bool(parsed.get("is_correct", false))
	var reason_code := str(parsed.get("reason_code", REASON_MULTIPLE_WRONG))
	completed.emit(is_correct, _message_for_reason(is_correct, reason_code))


func _message_for_reason(is_correct: bool, reason_code: String) -> String:
	if is_correct:
		return "Yes. The accusation holds."
	match reason_code:
		REASON_MISSING_EVIDENCE:
			return "No. You are making an accusation without the evidence to back it up."
		REASON_WRONG_PERSON:
			return "No. That culprit does not add up."
		REASON_WRONG_METHOD:
			return "No. The method does not add up."
		REASON_WRONG_EVIDENCE:
			return "No. The evidence does not add up."
		REASON_PARTIAL:
			return "Not quite. You're pointing in the right direction, but pieces of the story are still missing — keep gathering."
		_:
			return "No. The accusation does not add up."
