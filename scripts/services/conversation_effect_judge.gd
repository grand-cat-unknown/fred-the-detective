class_name ConversationEffectJudge
extends Node

signal effects_applied(changed_facts: Array)
signal judge_failed(message: String)

const MAX_RECENT_MESSAGES := 8

var _llm: LLMClient
var _state: CaseState
var _pending_allowed_effects: Dictionary = {}
var _queued_jobs: Array[Dictionary] = []


func configure(llm: LLMClient, state: CaseState) -> void:
	if _llm != null and _llm.completed.is_connected(_on_llm_completed):
		_llm.completed.disconnect(_on_llm_completed)
	_llm = llm
	_state = state
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)


func judge(
	suspect: SuspectData,
	recent_messages: Array,
	latest_player_message: String,
	latest_character_reply: String
) -> void:
	if suspect == null or _llm == null or _state == null:
		return

	var job := {
		"suspect": suspect,
		"recent_messages": recent_messages,
		"latest_player_message": latest_player_message,
		"latest_character_reply": latest_character_reply,
	}
	if _llm.is_busy() or not _pending_allowed_effects.is_empty():
		_queued_jobs.append(job)
		return

	_start_job(job)


func _start_job(job: Dictionary) -> void:
	var suspect := job.get("suspect") as SuspectData
	if suspect == null or _llm == null or _state == null:
		_start_next_queued_job()
		return

	var available_effects := suspect.available_conversation_effects(_state)
	if available_effects.is_empty():
		_start_next_queued_job()
		return

	_pending_allowed_effects.clear()
	var allowed_effects: Array[Dictionary] = []
	for effect in available_effects:
		var effect_data := effect.to_judge_dictionary()
		allowed_effects.append(effect_data)
		_pending_allowed_effects[str(effect.fact_id)] = effect.value

	var payload := {
		"active_suspect": str(suspect.id),
		"current_true_facts": _state.true_fact_ids(),
		"allowed_effects": allowed_effects,
		"latest_exchange": {
			"player": str(job.get("latest_player_message", "")),
			"character": str(job.get("latest_character_reply", "")),
		},
		"recent_messages": _trim_recent_messages(job.get("recent_messages", [])),
	}

	var instructions := "\n\n".join([
		"You are a strict game-state transition judge for Fred the Detective.",
		"Decide whether the latest in-game exchange clearly caused any of the allowed effects.",
		"Only choose effects from allowed_effects. Do not invent facts.",
		"Return only JSON with this shape: {\"effects\":[{\"fact_id\":\"id\",\"value\":true}]}",
		"If no allowed effect clearly happened, return {\"effects\":[]}.",
	])
	var messages := [
		{
			"role": "user",
			"content": JSON.stringify(payload, "\t"),
		}
	]
	var err := _llm.send(instructions, messages)
	if err != OK:
		_pending_allowed_effects.clear()
		judge_failed.emit("Could not judge conversation effects (%s)." % err)
		_start_next_queued_job()


func _trim_recent_messages(recent_messages: Variant) -> Array:
	if typeof(recent_messages) != TYPE_ARRAY:
		return []
	var messages: Array = recent_messages
	if messages.size() <= MAX_RECENT_MESSAGES:
		return messages
	return messages.slice(messages.size() - MAX_RECENT_MESSAGES)


func _on_llm_completed(text: String, error: String) -> void:
	if error != "":
		_pending_allowed_effects.clear()
		judge_failed.emit(error)
		_start_next_queued_job()
		return

	var parsed := _parse_json_object(text)
	if parsed.is_empty():
		_pending_allowed_effects.clear()
		judge_failed.emit("Conversation effect judge returned invalid JSON.")
		_start_next_queued_job()
		return

	var effects: Array = []
	var raw_effects: Variant = parsed.get("effects", [])
	if typeof(raw_effects) == TYPE_ARRAY:
		for raw_effect in raw_effects:
			if typeof(raw_effect) != TYPE_DICTIONARY:
				continue
			var fact_id := str(raw_effect.get("fact_id", ""))
			if not _pending_allowed_effects.has(fact_id):
				continue
			effects.append({
				"fact_id": fact_id,
				"value": bool(_pending_allowed_effects[fact_id]),
			})

	_pending_allowed_effects.clear()
	if effects.is_empty():
		_start_next_queued_job()
		return

	var changed := _state.apply_effects(effects)
	if not changed.is_empty():
		effects_applied.emit(changed)
	_start_next_queued_job()


func _start_next_queued_job() -> void:
	if _queued_jobs.is_empty() or _llm == null or _llm.is_busy():
		return
	var next_job: Dictionary = _queued_jobs.pop_front()
	_start_job(next_job)


func _parse_json_object(text: String) -> Dictionary:
	var trimmed := text.strip_edges()
	var parsed: Variant = JSON.parse_string(trimmed)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	var start := trimmed.find("{")
	var end := trimmed.rfind("}")
	if start == -1 or end == -1 or end <= start:
		return {}

	parsed = JSON.parse_string(trimmed.substr(start, end - start + 1))
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}
