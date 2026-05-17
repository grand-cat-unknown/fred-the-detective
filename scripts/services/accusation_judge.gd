class_name AccusationJudge
extends Node

signal completed(is_correct: bool, message: String)
signal failed(message: String)

const CORRECT_KILLER := &"otis"
const REQUIRED_EVIDENCE_FACT := &"has_evidence"
const REQUIRED_FIELD_BOOK_FACT := &"has_field_book"
const REQUIRED_PALMS_FACT := &"pemberton_palms_shown"

const MESSAGE_CORRECT := "Yes. The accusation holds."
const MESSAGE_WRONG := "Wrong accusation."
const MESSAGE_PARTIAL := "You're pointing in the right direction. Keep trying."

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
	if killer_id != CORRECT_KILLER or not _has_all_required_final_facts():
		completed.emit(false, MESSAGE_WRONG)
		return

	var payload := {
		"accusation": {
			"killer_label": killer_label,
			"method_text": method,
			"evidence_text": evidence,
		},
		"case_truth": {
			"killer_name": "Dr. Otis Pemberton",
			"method": "Otis used the hidden service passage to enter Suite 1102 and killed Felix Vance with a Siren-grade containment cell as a point-blank weapon, like a gun.",
			"required_evidence": "Fred has the recovered Siren containment cell, Theo's field book/manual explaining the manual-purge signature, and Otis's exposed violet-stained palms.",
		},
	}

	var instructions := "\n\n".join([
		"You are the final accusation judge for Fred the Detective.",
		"The hard conditions have already passed: the player picked Otis and has gathered all the required evidence facts. Your only job is to decide whether the player's free-text method and evidence describe the case correctly.",
		"Return strict structured JSON only. Do not reveal, name, hint at, or explain the correct solution in the output.",
		"Set is_correct to true only when all four ideas below are clearly present across the method and evidence text:",
		"1. Otis entered Suite 1102 via a hidden service passage / secret corridor / hidden route.",
		"2. He killed Vance with the Siren containment cell used as the murder weapon, effectively as a gun or point-blank discharge.",
		"3. The recovered/missing Siren containment cell is identified as the physical proof.",
		"4. The manual-purge mechanism is connected to Otis's violet-stained palms via the field book / manual logic.",
		"Accept natural wording and small spelling mistakes. Wording does not have to match the case truth verbatim — only the ideas must be present.",
		"Reject vague answers such as only 'ghost', 'weapon', or 'evidence'.",
		"If any of the four ideas is missing or too vague, set is_correct to false. The player is still pointing in the right direction; the hard conditions already confirmed that.",
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
			},
			"required": ["is_correct"],
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
	var message := MESSAGE_CORRECT if is_correct else MESSAGE_PARTIAL
	completed.emit(is_correct, message)
