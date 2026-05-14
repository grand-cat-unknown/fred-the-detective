@tool
extends Node2D
class_name DetectiveGame

@onready var _world: WorldView = %WorldView
@onready var _hud_panel: HudPanel = %HUDPanel
@onready var _interact_prompt: InteractPrompt = %InteractPrompt
@onready var _dialogue_panel: DialoguePanel = %DialoguePanel
@onready var _clue_panel: CluePanel = %CluePanel
@onready var _accusation_panel: AccusationPanel = %AccusationPanel
@onready var _result_panel: ResultPanel = %ResultPanel
@onready var _llm_request: HTTPRequest = %LLMRequest

var _case: CaseData
var _llm: LLMClient
var _dialogue: DialogueService
var _accusation: AccusationService
var _current_target := InteractTarget.none()

var _phase: GameEnums.Phase = GameEnums.Phase.EXPLORE
var _active_suspect_id: StringName = &""
var _dialogue_open := false
var _clue_panel_open := false
var _request_in_flight := false


func _ready() -> void:
	_case = CaseLoader.load_default()
	_world.configure(_case)
	if Engine.is_editor_hint():
		return

	_ensure_input_actions()
	_build_services()
	_wire_scene_signals()
	_wire_event_bus()
	_reset_game()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_interact_prompt()
	if _dialogue_open or _clue_panel_open or _phase != GameEnums.Phase.EXPLORE or _request_in_flight:
		return

	if _world.is_player_stepping():
		if _world.process_player_step(delta):
			_update_hud()
		return

	var direction := _get_pressed_tile_direction()
	if direction != Vector2i.ZERO:
		_world.try_start_tile_step(direction)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _clue_panel_open:
		if event.is_action_pressed("ui_cancel"):
			_close_clue_panel()
			get_viewport().set_input_as_handled()
		return

	if _dialogue_open:
		if event.is_action_pressed("ui_cancel"):
			_close_dialogue()
			get_viewport().set_input_as_handled()
		return

	if _phase != GameEnums.Phase.EXPLORE or _request_in_flight:
		return

	if event.is_action_pressed("interact"):
		_refresh_interact_target()
		_use_interact_target()


func _build_services() -> void:
	_llm = LLMClient.new(_llm_request)
	add_child(_llm)

	_dialogue = DialogueService.new()
	add_child(_dialogue)
	_dialogue.configure(_case, _llm)

	_accusation = AccusationService.new()
	add_child(_accusation)
	_accusation.configure(_case, _llm)
	_accusation_panel.configure(_case)


func _wire_scene_signals() -> void:
	_connect_once(_hud_panel.accuse_pressed, _on_accuse_pressed)
	_connect_once(_dialogue_panel.submitted, _send_dialogue_request)
	_connect_once(_dialogue_panel.closed, _close_dialogue)
	_connect_once(_clue_panel.closed, _close_clue_panel)
	_connect_once(_accusation_panel.suspect_chosen, _on_suspect_chosen)
	_connect_once(_accusation_panel.evidence_chosen, _on_evidence_chosen)
	_connect_once(_accusation_panel.explanation_changed, _on_accusation_explanation_changed)
	_connect_once(_accusation_panel.submitted, _on_accusation_submit_pressed)
	_connect_once(_accusation_panel.closed, _close_accusation)
	_connect_once(_result_panel.restart_pressed, _reset_game)


func _wire_event_bus() -> void:
	_connect_once(EventBus.clue_inspected, _on_clue_inspected)
	_connect_once(EventBus.suspect_talked, _on_suspect_talked)
	_connect_once(EventBus.dialogue_line_appended, _on_dialogue_line_appended)
	_connect_once(EventBus.dialogue_busy_changed, _set_dialogue_busy)
	_connect_once(EventBus.accusation_busy_changed, _set_accusation_busy)
	_connect_once(EventBus.accusation_resolved, _on_accusation_resolved)


func _connect_once(signal_value: Signal, callable: Callable) -> void:
	if not signal_value.is_connected(callable):
		signal_value.connect(callable)


func _use_interact_target() -> void:
	match _current_target.kind:
		GameEnums.InteractKind.NPC:
			_open_dialogue(_current_target.index)
		GameEnums.InteractKind.CLUE:
			_open_clue_panel(_current_target.index)
		GameEnums.InteractKind.ELEVATOR:
			_enter_elevator(_current_target.index)
		_:
			return
	get_viewport().set_input_as_handled()


func _enter_elevator(elevator_idx: int) -> void:
	if elevator_idx < 0 or elevator_idx >= _case.elevators.size():
		return
	var elevator := _case.elevators[elevator_idx]
	var player_tile := _world.player_tile()
	var face := _world.player_face_direction()
	var source_room: StringName = elevator.room_a if (elevator.tile_b - player_tile) == face else elevator.room_b
	_world.reset_player(elevator.target_spawn_from(source_room))
	_update_hud()


func _update_interact_prompt() -> void:
	if _dialogue_open or _clue_panel_open or _phase != GameEnums.Phase.EXPLORE:
		_interact_prompt.close()
		return

	_refresh_interact_target()
	if _current_target.is_none():
		_interact_prompt.close()
		return
	_interact_prompt.show_target(_current_target.label, _current_target.prompt_position)


func _refresh_interact_target() -> void:
	_current_target = InteractionDetector.find_target(
		_case,
		_world.player_position(),
		_world.player_tile(),
		_world.player_face_direction(),
	)


func _open_dialogue(suspect_idx: int) -> void:
	if suspect_idx < 0 or suspect_idx >= _case.suspects.size():
		return
	var suspect := _case.suspects[suspect_idx]
	_active_suspect_id = suspect.id
	_dialogue_open = true
	_dialogue.open(suspect.id)
	_dialogue_panel.open(
		"%s  -  %s" % [suspect.display_name, suspect.subtitle],
		_dialogue.get_dialogue_lines(suspect.id),
	)
	_update_hud()


func _close_dialogue() -> void:
	_dialogue.close()
	_dialogue_open = false
	_dialogue_panel.close()
	_active_suspect_id = &""
	get_viewport().gui_release_focus()
	_update_hud()


func _open_clue_panel(clue_idx: int) -> void:
	if clue_idx < 0 or clue_idx >= _case.clues.size():
		return
	var clue := _case.clues[clue_idx]
	GameState.mark_clue_inspected(clue.id)
	_clue_panel_open = true
	_clue_panel.open(clue.label, clue.description)
	_world.refresh()
	_update_hud()


func _close_clue_panel() -> void:
	_clue_panel_open = false
	_clue_panel.close()
	_update_hud()


func _on_accuse_pressed() -> void:
	_accusation.start()
	_accusation_panel.open(_case.question)
	_set_phase(GameEnums.Phase.ACCUSE)
	_update_hud()


func _close_accusation() -> void:
	if _request_in_flight:
		return
	_accusation.cancel()
	_accusation_panel.close()
	_set_phase(GameEnums.Phase.EXPLORE)
	_update_hud()


func _on_suspect_chosen(suspect_idx: int) -> void:
	if suspect_idx < 0 or suspect_idx >= _case.suspects.size():
		return
	_accusation.choose_suspect(_case.suspects[suspect_idx].id)
	_accusation_panel.show_evidence(_inspected_clue_ids())


func _on_evidence_chosen(clue_idx: int) -> void:
	if clue_idx < 0 or clue_idx >= _case.clues.size():
		return
	_accusation.choose_evidence(_case.clues[clue_idx].id)
	_accusation_panel.show_explanation()


func _on_accusation_explanation_changed() -> void:
	_accusation_panel.set_submit_enabled(
		not _request_in_flight and not _accusation_panel.explanation_text().strip_edges().is_empty()
	)


func _on_accusation_submit_pressed(explanation_text: String) -> void:
	if _request_in_flight:
		return

	var explanation := explanation_text.strip_edges()
	if explanation.is_empty():
		_accusation_panel.show_status("Fred needs a theory before he can close the case.")
		_accusation_panel.set_submit_enabled(false)
		return

	if not _accusation.submit(explanation):
		_accusation_panel.show_status("Fred cannot submit that accusation yet.")


func _set_accusation_busy(is_busy: bool, status_text: String) -> void:
	_request_in_flight = is_busy
	_accusation_panel.set_busy(is_busy, status_text)
	_update_hud()


func _on_accusation_resolved(verdict: AccusationVerdict) -> void:
	_accusation_panel.close()
	_set_phase(GameEnums.Phase.RESULT)
	_show_result(verdict)


func _show_result(verdict: AccusationVerdict) -> void:
	var suspect := _case.suspect_by_id(verdict.suspect_id)
	var clue := _case.clue_by_id(verdict.clue_id)
	var suspect_name := suspect.display_name if suspect != null else "(unknown)"
	var clue_label := clue.label if clue != null else "(unknown)"
	var right_suspect := verdict.suspect_id == _case.correct_suspect_id
	var right_evidence := verdict.clue_id == _case.required_evidence_id
	var accusation_correct := verdict.is_correct and right_suspect and right_evidence
	var headline := verdict.headline.strip_edges()
	var feedback := verdict.feedback.strip_edges()

	if headline.is_empty():
		headline = "Correct" if accusation_correct else "Not proven"
	if feedback.is_empty():
		feedback = "The accusation does not fit the authored case facts."
	if verdict.is_correct and not accusation_correct:
		headline = "Not proven"
		feedback = "The accusation does not fit the authored case facts."

	var result_text := ""
	if accusation_correct:
		result_text = "%s.\n\n%s\n\nCase closed." % [headline, feedback]
	elif right_suspect and not right_evidence:
		result_text = "%s.\n\n%s\n\nYou named the right person, but the %s does not carry the whole case. The ghost cell in the chute connects the stolen idol, the residue pattern, and the murder weapon." % [
			headline,
			feedback,
			clue_label,
		]
	else:
		result_text = "%s.\n\n%s\n\n%s is not proved by that evidence. The case points to %s: the ghost cell hid the idol and matched the discharge that killed Vance." % [
			headline,
			feedback,
			suspect_name,
			_murderer_name(),
		]
	_result_panel.open(result_text)
	_update_hud()


func _murderer_name() -> String:
	for suspect in _case.suspects:
		if suspect.is_murderer:
			return suspect.display_name
	return "(unknown)"


func _set_dialogue_busy(is_busy: bool, status_text: String) -> void:
	_request_in_flight = is_busy
	_dialogue_panel.set_busy(is_busy, status_text)
	_update_hud()


func _send_dialogue_request(message: String) -> void:
	if _request_in_flight or _active_suspect_id == &"":
		return
	if _dialogue.submit_message(message):
		_dialogue_panel.clear_input()


func _on_clue_inspected(_clue_id: StringName) -> void:
	_world.refresh()
	_update_hud()


func _on_suspect_talked(_suspect_id: StringName) -> void:
	_update_hud()


func _on_dialogue_line_appended(suspect_id: StringName, _speaker: String, _text: String) -> void:
	if _active_suspect_id != suspect_id:
		return
	_dialogue_panel.set_lines(_dialogue.get_dialogue_lines(suspect_id))
	if not _request_in_flight:
		_dialogue_panel.focus_input()


func _reset_game() -> void:
	GameState.reset(_case)
	_dialogue.reset()
	_accusation.reset()
	_world.reset_player(_case.player_start_tile)
	_world.refresh()
	_set_phase(GameEnums.Phase.EXPLORE)
	_active_suspect_id = &""
	_dialogue_open = false
	_clue_panel_open = false
	_request_in_flight = false

	_dialogue_panel.close()
	_clue_panel.close()
	_accusation_panel.close()
	_accusation_panel.set_busy(false, "")
	_result_panel.close()
	_update_hud()


func _update_hud() -> void:
	var found_count := GameState.inspected_clue_count()
	_hud_panel.set_status("Clues inspected: %d / %d" % [found_count, _case.clues.size()])
	_hud_panel.set_accuse_enabled(not _request_in_flight and _accusation.can_accuse())
	_hud_panel.set_hint(_hud_hint())


func _hud_hint() -> String:
	if _phase == GameEnums.Phase.RESULT:
		return "Case closed."
	if _request_in_flight:
		return "Waiting for an answer."
	if _phase == GameEnums.Phase.ACCUSE:
		return "Name a suspect, cite evidence, and explain the theory."
	if _dialogue_open:
		return "Press Esc to end the conversation."
	if _clue_panel_open:
		return "Press Esc to close."
	if _clue_is_available(CaseLoader.CLUE_GHOST_CELL) and not GameState.is_clue_inspected(CaseLoader.CLUE_GHOST_CELL):
		return "The chute lead is open. Check the floor 11 chute access."
	if _clue_is_available(CaseLoader.CLUE_GLOVES) and not GameState.is_clue_inspected(CaseLoader.CLUE_GLOVES):
		return "The ghost cell points back to the gear. Inspect Pemberton's gloves."
	if _accusation.can_accuse():
		return "You have enough to accuse -- or keep digging."
	return "Inspect clues [E] and question suspects [E]. Find evidence to accuse."


func _clue_is_available(clue_id: StringName) -> bool:
	var clue := _case.clue_by_id(clue_id)
	return clue != null and UnlockResolver.is_clue_available(clue)


func _inspected_clue_ids() -> Array[StringName]:
	var clue_ids: Array[StringName] = []
	for clue in _case.clues:
		if GameState.is_clue_inspected(clue.id):
			clue_ids.append(clue.id)
	return clue_ids


func _set_phase(new_phase: GameEnums.Phase) -> void:
	_phase = new_phase
	GameState.set_phase(new_phase)


func _ensure_input_actions() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")

	var has_e_key := false
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey and event.physical_keycode == KEY_E:
			has_e_key = true
			break

	if not has_e_key:
		var interact_key := InputEventKey.new()
		interact_key.physical_keycode = KEY_E
		InputMap.action_add_event("interact", interact_key)


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
