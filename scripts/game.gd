extends Node2D

const AccusationJudgeScript := preload("res://scripts/services/accusation_judge.gd")
const CLEAN_HANDS_IMAGE := preload("res://assets/art/environments/clean_hands.png")
const STAINED_HANDS_IMAGE := preload("res://assets/art/environments/stained_hands.png")
const CLEAN_PALMS_FACTS := {
	&"mara_palms_shown": "Mara's hands",
	&"theo_palms_shown": "Theo's hands",
	&"iris_palms_shown": "Iris's hands",
	&"vivian_palms_shown": "Vivian's hands",
	&"mags_palms_shown": "Mags's hands",
	&"julian_palms_shown": "Julian's hands",
	&"leo_palms_shown": "Leo's hands",
}
const STAINED_PALMS_FACT := &"pemberton_palms_shown"

@onready var _world: WorldView = %WorldView
@onready var _inspect_panel: InspectPanel = %InspectPanel
@onready var _dialogue_panel: DialoguePanel = %DialoguePanel
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _book_panel: BookPanel = %BookPanel
@onready var _evidence_panel: EvidencePanel = %EvidencePanel
@onready var _accuse_panel: AccusePanel = %AccusePanel
@onready var _toast: Toast = %Toast

var _pending_action_toast: String = ""
var _pending_passive_toast: String = ""

var _llm: LLMClient
var _topic_llm: LLMClient
var _effect_llm: LLMClient
var _accusation_llm: LLMClient
var _case_state: CaseState
var _topic_classifier: ConversationTopicClassifier
var _effect_judge: ConversationEffectJudge
var _accusation_judge: Node
var _dialogue: DialogueService


func _ready() -> void:
	var case := CaseLoader.load_default()
	print("[case] loaded %d facts, %d interactables, %d inventory items" % [case.fact_definitions.size(), case.interactables.size(), case.inventory_items.size()])

	_case_state = CaseState.new()
	_case_state.name = "CaseState"
	add_child(_case_state)
	_case_state.configure(case.fact_definitions)
	_case_state.fact_changed.connect(_on_case_fact_changed)

	_world.configure(case, _case_state)
	_inventory_panel.configure(case, _case_state)
	_accuse_panel.configure(_case_state)

	_llm = LLMClient.new()
	_llm.name = "LLMClient"
	add_child(_llm)

	_topic_llm = LLMClient.new()
	_topic_llm.name = "ConversationTopicLLM"
	add_child(_topic_llm)

	_effect_llm = LLMClient.new()
	_effect_llm.name = "ConversationEffectLLM"
	add_child(_effect_llm)

	_accusation_llm = LLMClient.new()
	_accusation_llm.name = "AccusationLLM"
	add_child(_accusation_llm)

	_topic_classifier = ConversationTopicClassifier.new()
	_topic_classifier.name = "ConversationTopicClassifier"
	add_child(_topic_classifier)
	_topic_classifier.configure(_topic_llm)

	_effect_judge = ConversationEffectJudge.new()
	_effect_judge.name = "ConversationEffectJudge"
	add_child(_effect_judge)
	_effect_judge.configure(_effect_llm, _case_state)
	_effect_judge.effects_applied.connect(_on_conversation_effects_applied)
	_effect_judge.judge_failed.connect(_on_conversation_judge_failed)

	_accusation_judge = AccusationJudgeScript.new()
	_accusation_judge.name = "AccusationJudge"
	add_child(_accusation_judge)
	_accusation_judge.configure(_accusation_llm, _case_state)
	_accusation_judge.completed.connect(_on_accusation_judge_completed)
	_accusation_judge.failed.connect(_on_accusation_judge_failed)

	_dialogue = DialogueService.new()
	_dialogue.name = "DialogueService"
	add_child(_dialogue)
	_dialogue.configure(_llm, _case_state, _effect_judge, _topic_classifier)

	_dialogue.line_appended.connect(_on_dialogue_line_appended)
	_dialogue.line_updated.connect(_on_dialogue_line_updated)
	_dialogue.busy_changed.connect(_on_dialogue_busy_changed)
	_dialogue.error_received.connect(_on_dialogue_error)
	_dialogue_panel.submitted.connect(_on_dialogue_submitted)
	_dialogue_panel.closed.connect(_on_dialogue_closed)
	_inspect_panel.action_confirmed.connect(_on_inspect_action_confirmed)
	_accuse_panel.accusation_resolved.connect(_on_accusation_resolved)
	_accuse_panel.accusation_submitted.connect(_on_accusation_submitted)


func _input(event: InputEvent) -> void:
	if _evidence_panel.is_open() and _evidence_panel.handle_input_event(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _evidence_panel.is_open():
		if _evidence_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _dialogue_panel.is_open():
		if _dialogue_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _inspect_panel.is_open():
		if _inspect_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
			if not _inspect_panel.is_open():
				_flush_pending_passive_toast()
		return

	if _toast.is_open():
		if _toast.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _book_panel.is_open():
		if _book_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _accuse_panel.is_open():
		if _accuse_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		var npc := _world.find_npc_at_player()
		if npc != null and npc.suspect != null:
			_open_dialogue_with(npc.suspect)
			get_viewport().set_input_as_handled()
			return

		var inspection := _world.find_inspection_at_player()
		if not inspection.is_empty():
			var action_label := str(inspection.get("action_label", "")).strip_edges()
			var toast_text := str(inspection.get("toast", "")).strip_edges()
			var passive_effects: Array = inspection.get("effects", [])
			if action_label != "":
				_pending_action_toast = toast_text
				_pending_passive_toast = ""
				_inspect_panel.show_action(
					str(inspection["title"]),
					str(inspection["description"]),
					action_label,
					str(inspection.get("action_prompt", "")),
					inspection.get("action_effects", [])
				)
			else:
				_inspect_panel.show_text(str(inspection["title"]), str(inspection["description"]))
				if toast_text != "" and not passive_effects.is_empty():
					_pending_passive_toast = toast_text
				else:
					_pending_passive_toast = ""
			if _case_state != null:
				_case_state.apply_effects(passive_effects)
			get_viewport().set_input_as_handled()
			return

	if _try_trigger_inventory_action(event):
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	var other_panel_open: bool = _inspect_panel.is_open() or _dialogue_panel.is_open() or _book_panel.is_open() or _evidence_panel.is_open() or _toast.is_open()
	_accuse_panel.set_accuse_button_enabled(not other_panel_open)
	var panels_open: bool = other_panel_open or _accuse_panel.is_open()
	_world.set_interaction_prompt_enabled(not panels_open)
	if panels_open:
		return
	_world.update_player_movement(delta, _get_pressed_tile_direction())


func _try_trigger_inventory_action(event: InputEvent) -> bool:
	for item in _inventory_panel.get_active_items():
		var action_input := StringName(item.get("action_input", &""))
		if action_input == &"" or not InputMap.has_action(action_input):
			continue
		if not event.is_action_pressed(action_input):
			continue
		var kind := StringName(item.get("action_kind", &""))
		if kind == &"book":
			var title := str(item.get("book_title", item.get("label", "")))
			var pages: Array = item.get("book_pages", [])
			_book_panel.open(title, pages)
			return true
		if kind == &"evidence":
			var title := str(item.get("evidence_title", item.get("label", "")))
			var image: Texture2D = item.get("evidence_image")
			var description := str(item.get("evidence_description", item.get("description", "")))
			_evidence_panel.open(title, image, description)
			return true
	return false


func _open_dialogue_with(suspect: SuspectData) -> void:
	_dialogue.open(suspect)
	_dialogue_panel.open(suspect.display_name, suspect.subtitle, _dialogue.get_lines(suspect.id))


func _on_dialogue_submitted(message: String) -> void:
	if _dialogue.submit(message):
		_dialogue_panel.clear_input()


func _on_dialogue_line_appended(speaker: String, text: String) -> void:
	if not _dialogue_panel.is_open():
		return
	_dialogue_panel.append_line(speaker, text)


func _on_dialogue_line_updated(text: String) -> void:
	if not _dialogue_panel.is_open():
		print("[game] line_updated ignored: panel closed")
		return
	print("[game] line_updated len=%d" % text.length())
	_dialogue_panel.update_last_line(text)


func _on_dialogue_busy_changed(is_busy: bool) -> void:
	_dialogue_panel.set_busy(is_busy)


func _on_dialogue_error(message: String) -> void:
	_dialogue_panel.show_error(message)


func _on_dialogue_closed() -> void:
	_dialogue.close()


func _on_case_fact_changed(fact_id: StringName, value: bool) -> void:
	print("[case] %s = %s" % [fact_id, value])
	if value:
		_show_hand_photo_for_fact(fact_id)


func _on_inspect_action_confirmed(effects: Array) -> void:
	var toast_text := _pending_action_toast
	_pending_action_toast = ""
	if _case_state != null:
		_case_state.apply_effects(effects)
	if toast_text != "":
		_toast.show_message(toast_text)


func _flush_pending_passive_toast() -> void:
	if _pending_passive_toast == "":
		return
	var toast_text := _pending_passive_toast
	_pending_passive_toast = ""
	_toast.show_message(toast_text)


func _on_conversation_effects_applied(changed_facts: Array) -> void:
	print("[case] conversation effects applied: %s" % [changed_facts])


func _show_hand_photo_for_fact(fact_id: StringName) -> void:
	if fact_id == STAINED_PALMS_FACT:
		_evidence_panel.open(
			"Pemberton's hands",
			STAINED_HANDS_IMAGE,
			"Stained hands.",
			true,
			"Press Space to close"
		)
		return
	if not CLEAN_PALMS_FACTS.has(fact_id):
		return
	_evidence_panel.open(
		str(CLEAN_PALMS_FACTS[fact_id]),
		CLEAN_HANDS_IMAGE,
		"Clean hands.",
		true,
		"Press Space to close"
	)


func _on_conversation_judge_failed(message: String) -> void:
	print("[case] conversation effect judge failed: %s" % message)


func _on_accusation_resolved(success: bool, message: String) -> void:
	print("[case] accusation resolved success=%s: %s" % [success, message])


func _on_accusation_submitted(killer_id: StringName, killer_label: String, method_text: String, evidence_text: String) -> void:
	if _accusation_judge == null:
		_accuse_panel.show_result(false, "The accusation judge is not ready.")
		return
	_accusation_judge.judge(killer_id, killer_label, method_text, evidence_text)


func _on_accusation_judge_completed(success: bool, message: String) -> void:
	_accuse_panel.show_result(success, message)


func _on_accusation_judge_failed(message: String) -> void:
	_accuse_panel.show_result(false, message, false)


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
