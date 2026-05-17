class_name DialogueService
extends Node

signal line_appended(speaker: String, text: String)
signal line_updated(text: String)
signal busy_changed(is_busy: bool)
signal error_received(message: String)

const DETECTIVE_LABEL := "Fred"
const MAX_HISTORY_LINES := 40

var _llm: LLMClient
var _state: CaseState
var _effect_judge: ConversationEffectJudge
var _topic_classifier: ConversationTopicClassifier
var _active_suspect: SuspectData
var _history: Dictionary = {}  # StringName id -> Array[Dictionary]
var _streaming_suspect_id: StringName = &""
var _streaming_suspect: SuspectData
var _streaming_latest_player_message := ""
var _streaming_topic_ids: Array[StringName] = []
var _streaming_text := ""
var _pending_suspect: SuspectData
var _pending_player_message := ""


func configure(
	llm: LLMClient,
	state: CaseState = null,
	effect_judge: ConversationEffectJudge = null,
	topic_classifier: ConversationTopicClassifier = null
) -> void:
	if _llm != null:
		if _llm.completed.is_connected(_on_llm_completed):
			_llm.completed.disconnect(_on_llm_completed)
		if _llm.delta_received.is_connected(_on_llm_delta):
			_llm.delta_received.disconnect(_on_llm_delta)
	if _topic_classifier != null:
		if _topic_classifier.completed.is_connected(_on_topic_classifier_completed):
			_topic_classifier.completed.disconnect(_on_topic_classifier_completed)
		if _topic_classifier.failed.is_connected(_on_topic_classifier_failed):
			_topic_classifier.failed.disconnect(_on_topic_classifier_failed)
	_llm = llm
	_state = state
	_effect_judge = effect_judge
	_topic_classifier = topic_classifier
	if _llm != null:
		_llm.completed.connect(_on_llm_completed)
		_llm.delta_received.connect(_on_llm_delta)
	if _topic_classifier != null:
		_topic_classifier.completed.connect(_on_topic_classifier_completed)
		_topic_classifier.failed.connect(_on_topic_classifier_failed)


func open(suspect: SuspectData) -> void:
	_active_suspect = suspect
	if suspect == null:
		return
	if not _history.has(suspect.id):
		_history[suspect.id] = []
		var greeting := suspect.dialogue.strip_edges()
		if greeting != "":
			_append(suspect.id, suspect.display_name, greeting)


func close() -> void:
	_active_suspect = null


func get_lines(suspect_id: StringName) -> Array:
	return _history.get(suspect_id, [])


func active_suspect() -> SuspectData:
	return _active_suspect


func submit(message: String) -> bool:
	if _active_suspect == null or _llm == null:
		return false
	var trimmed := message.strip_edges()
	if trimmed.is_empty() or _llm.is_busy() or (_topic_classifier != null and _topic_classifier.is_busy()):
		return false
	_append(_active_suspect.id, DETECTIVE_LABEL, trimmed)
	busy_changed.emit(true)
	if _topic_classifier != null and _active_suspect.has_topic_responses():
		_pending_suspect = _active_suspect
		_pending_player_message = trimmed
		var classify_err := _topic_classifier.classify(
			_active_suspect,
			trimmed,
			_build_recent_transcript(_active_suspect.id)
		)
		if classify_err != OK:
			_pending_suspect = null
			_pending_player_message = ""
			error_received.emit("Could not classify the topic (%s)." % classify_err)
			busy_changed.emit(false)
			return false
		return true

	if not _start_reply(_active_suspect, trimmed, []):
		busy_changed.emit(false)
		return false
	return true


func reset() -> void:
	_history.clear()
	_active_suspect = null
	_streaming_suspect_id = &""
	_streaming_suspect = null
	_streaming_latest_player_message = ""
	_streaming_topic_ids.clear()
	_streaming_text = ""
	_pending_suspect = null
	_pending_player_message = ""


func _append(suspect_id: StringName, speaker: String, text: String) -> void:
	var lines: Array = _history.get(suspect_id, [])
	lines.append({"speaker": speaker, "text": text})
	while lines.size() > MAX_HISTORY_LINES:
		lines.pop_front()
	_history[suspect_id] = lines
	line_appended.emit(speaker, text)


func _update_last_line(suspect_id: StringName, text: String) -> void:
	var lines: Array = _history.get(suspect_id, [])
	if lines.is_empty():
		return
	lines[lines.size() - 1]["text"] = text
	_history[suspect_id] = lines


func _start_reply(suspect: SuspectData, latest_player_message: String, topic_ids: Array[StringName]) -> bool:
	var err := _llm.send(_build_instructions(suspect, topic_ids), _build_messages(suspect))
	if err != OK:
		error_received.emit("Could not reach the LLM (%s)." % err)
		return false
	_streaming_suspect_id = suspect.id
	_streaming_suspect = suspect
	_streaming_latest_player_message = latest_player_message
	_streaming_topic_ids = topic_ids.duplicate()
	_streaming_text = ""
	_append(suspect.id, suspect.display_name, "")
	return true


func _build_instructions(suspect: SuspectData, topic_ids: Array[StringName] = []) -> String:
	var parts: Array[String] = []
	parts.append("You are roleplaying a character in the detective game 'Fred the Detective'. The player is Detective Fred, who is interviewing you about the murder of Felix Vance at The Sedgewick Hotel.")
	parts.append("PUBLIC CASE BRIEFING — common knowledge every character in the hotel already knows tonight. You may freely reference any of it without hedging, and you should actively use it to orient Fred when he asks about the night, the auction, the victim, the watch, the hotel, or the people involved. Treat these as facts you'd happily tell any colleague who just arrived on scene:\n- The Sedgewick Hotel is an old castle converted into a luxury hotel, owned and run by Vivian Marlowe (inherited from her father). Its grandest room is the Royal Suite, Room 1102.\n- Last night the hotel hosted a private occult auction in its auction hall. The headline lot was the Anchor Idol — rated the most spectrally dangerous artifact of the night, with a documented capacity to attract other entities.\n- The collector Felix Vance won the Anchor Idol by a single bid over rival collector Julian Vane (Suite 1204). Vance was staying in the Royal Suite and intended to check out tomorrow morning with the idol.\n- Per the auction contract, Ghostbusters Inc. was hired for a one-night containment watch on Suite 1102: team lead Mara Bell at the front door, Dr. Iris Thorne at the west observation post, Dr. Otis Pemberton on the east-side route, and Theo Griggs on tech and gear setup.\n- Vance was known in collector circles for a strict private meditation ritual every evening from 9:00 to 9:45 PM — completely alone, no calls, no staff. Long-term Sedgewick staff knew this too.\n- Tonight at roughly 9 PM, during the watch, Felix Vance was found dead in the Royal Suite. Detective Fred has been called in to investigate. The hotel is trying to contain scandal; the press is already sniffing.")
	parts.append("CAST YOU ALL RECOGNIZE TONIGHT — every character in the hotel knows roughly who these people are and may share these surface facts when asked about any of them. Personal opinions and private history beyond this stay in the matching topic state:\n- Vivian Marlowe — owner and night manager of The Sedgewick. Inherited the hotel from her father. Runs the front desk personally on big nights.\n- Leo Rossi — the hotel's veteran bellhop. Forty years on the floor. Was at the front desk area with Vivian during the watch window.\n- Dottie \"Mags\" Higgins — the hotel maid. Quiet, head-down. Handles rooms, linens, and the laundry chute.\n- Felix Vance — tonight's victim. Wealthy occult collector, staying in the Royal Suite, won the Anchor Idol at last night's auction. Known for a private 9:00–9:45 PM meditation ritual.\n- Julian Vane — collector in Suite 1204. Vance's auction rival; lost the Anchor Idol to him by a single bid. Refined, sarcastic, bitter about the loss.\n- Mara Bell — Ghostbusters team lead. Held the front door of Suite 1102 during the watch. Called Vivian and then Fred after Vance was found.\n- Dr. Iris Thorne — Ghostbusters observation and comms. Was at the west observation post with her logging equipment.\n- Dr. Otis Pemberton — Ghostbusters medical and occult specialist. Was assigned the east-side structural sweep. Grew up around the hotel as a child; long acquaintance with Vivian.\n- Theo Griggs — Ghostbusters tech and gear. Newest member of the team. Was at the gear cart for setup.\n- Detective Fred — the player. The detective Mara called in tonight. Newly arrived; getting up to speed on the people and the night.")
	parts.append("ORIENTING THE DETECTIVE: Fred is new to the hotel and to this case tonight — he was just called in. The locals (you) know the place, the people, and what happened. Part of your job in this conversation is to help him get up to speed on anything in the public briefing above when he asks about it. Do not stonewall, deflect, or play coy about common-knowledge facts; that breaks the scene. Save your caution and evasiveness for your character's private secrets and the items your topic-specific instructions explicitly tell you to protect. If your character has a personal angle on a public fact (your role on the team, your view of Vance, your relationship to the hotel), share that angle naturally instead of giving a flat textbook recap.")
	if suspect.subtitle != "":
		parts.append("Role: %s" % suspect.subtitle)
	if suspect.persona != "":
		parts.append("Character notes: %s" % suspect.persona)
	if suspect.team != null and suspect.team.body.strip_edges() != "":
		parts.append(suspect.team.body)
	if suspect.system_prompt != "":
		parts.append(suspect.system_prompt)
	for block in suspect.available_prompt_blocks(_state):
		parts.append(block.text)
	var reaction_blocks := suspect.available_reaction_blocks(_state)
	if not reaction_blocks.is_empty():
		parts.append("Current reactive interview beats. Apply these only when Fred's latest question or evidence makes them relevant; use them to change tone, evasiveness, or what the character will now admit.")
		for block in reaction_blocks:
			parts.append(block.text)
	var topic_instructions := suspect.active_topic_response_instructions_for_topics(_state, topic_ids)
	if not topic_instructions.is_empty():
		parts.append("Current topic-specific response state. Fred's latest question matches these topic gates; follow the matching state exactly and do not jump to later facts.")
		for instruction in topic_instructions:
			parts.append(instruction)
	parts.append("HANDLING ORIENTING QUESTIONS: If Fred asks something open-ended (\"what happened?\", \"tell me about tonight\", \"what's going on here?\", \"who are the players?\"), treat it as a request for orientation, not as a trap. Give him a real situational answer in your own voice: the occult auction was on last night, Vance won the Anchor Idol over Julian Vane, the Ghostbusters were on a containment watch on Suite 1102, and Vance was found dead in there around 9 tonight — colored by your own role and perspective. Two to four sentences is fine for this. Then offer a hook for him to dig deeper (\"want to know about the watch, the auction, or Vance himself?\") instead of demanding he narrow down before you'll say anything. The only things to withhold here are your character's private secrets and anything your topic-specific instructions explicitly gate. Never give generic \"busy night\" filler or pretend nothing notable happened.\n\nFor questions like \"who did it?\" or \"any suspicions?\" — answer as your character honestly would: say whom you'd suspect and why if you have a real hunch, or say plainly that you don't know and explain what you did see. Do not refuse to speculate as a blanket rule.")
	parts.append("HANDLING A RUDE OR HOSTILE DETECTIVE: If Fred is rude, accusatory, insulting, sarcastic, or aggressive, do not refuse to talk and do not exit the conversation. Stay in your character's voice — push back the way your character would (icily, nervously, wearily, etc.) — but keep cooperating with the investigation. Real interviewees get annoyed; they do not stage-walkouts. Never break character to scold the player.")
	parts.append("Reply as the character only. Do not narrate actions in brackets. Do not include your name as a prefix. Keep replies concise — 5 sentences maximum; usually 1–3 sentences for specific questions, up to 5 when orienting Fred on a broader question.")
	return "\n\n".join(parts)


func _on_topic_classifier_completed(topic_ids: Array[StringName]) -> void:
	var suspect := _pending_suspect
	var latest_player_message := _pending_player_message
	_pending_suspect = null
	_pending_player_message = ""
	if suspect == null:
		busy_changed.emit(false)
		return
	if not _start_reply(suspect, latest_player_message, topic_ids):
		busy_changed.emit(false)


func _on_topic_classifier_failed(message: String) -> void:
	var suspect := _pending_suspect
	var latest_player_message := _pending_player_message
	_pending_suspect = null
	_pending_player_message = ""
	if suspect != null and _start_reply(suspect, latest_player_message, []):
		return
	error_received.emit(message)
	busy_changed.emit(false)


func _build_messages(suspect: SuspectData) -> Array:
	var lines: Array = _history.get(suspect.id, [])
	var messages: Array = []
	for entry in lines:
		var speaker := str(entry.get("speaker", ""))
		var text := str(entry.get("text", "")).strip_edges()
		if text.is_empty():
			continue
		var role := "user" if speaker == DETECTIVE_LABEL else "assistant"
		messages.append({"role": role, "content": text})
	return messages


func _on_llm_delta(chunk: String) -> void:
	if _streaming_suspect_id == &"":
		return
	_streaming_text += chunk
	_update_last_line(_streaming_suspect_id, _streaming_text)
	if _active_suspect != null and _active_suspect.id == _streaming_suspect_id:
		line_updated.emit(_streaming_text)


func _on_llm_completed(text: String, error: String) -> void:
	busy_changed.emit(false)
	var suspect_id := _streaming_suspect_id
	var suspect := _streaming_suspect
	var latest_player_message := _streaming_latest_player_message
	var topic_ids := _streaming_topic_ids.duplicate()
	var accumulated := _streaming_text
	_streaming_suspect_id = &""
	_streaming_suspect = null
	_streaming_latest_player_message = ""
	_streaming_topic_ids.clear()
	_streaming_text = ""
	if error != "":
		if suspect_id != &"":
			_update_last_line(suspect_id, accumulated)
		error_received.emit(error)
		return
	var final_text := text.strip_edges()
	if final_text.is_empty():
		final_text = accumulated.strip_edges()
	if final_text.is_empty():
		error_received.emit("(no response)")
		return
	if suspect_id != &"":
		_update_last_line(suspect_id, final_text)
		if _active_suspect != null and _active_suspect.id == suspect_id:
			line_updated.emit(final_text)
		if _effect_judge != null:
			_effect_judge.judge(suspect, _build_recent_transcript(suspect_id), latest_player_message, final_text, topic_ids)


func _build_recent_transcript(suspect_id: StringName) -> Array:
	var lines: Array = _history.get(suspect_id, [])
	var transcript: Array = []
	for entry in lines:
		var speaker := str(entry.get("speaker", ""))
		var text := str(entry.get("text", "")).strip_edges()
		if text.is_empty():
			continue
		transcript.append({
			"speaker": speaker,
			"text": text,
		})
	return transcript
