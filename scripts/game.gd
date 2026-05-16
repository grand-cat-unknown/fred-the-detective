extends Node2D

@onready var _world: WorldView = %WorldView
@onready var _inspect_panel: InspectPanel = %InspectPanel
@onready var _dialogue_panel: DialoguePanel = %DialoguePanel
@onready var _inventory_panel: InventoryPanel = %InventoryPanel
@onready var _book_panel: BookPanel = %BookPanel

var _llm: LLMClient
var _effect_llm: LLMClient
var _case_state: CaseState
var _effect_judge: ConversationEffectJudge
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

	_llm = LLMClient.new()
	_llm.name = "LLMClient"
	add_child(_llm)

	_effect_llm = LLMClient.new()
	_effect_llm.name = "ConversationEffectLLM"
	add_child(_effect_llm)

	_effect_judge = ConversationEffectJudge.new()
	_effect_judge.name = "ConversationEffectJudge"
	add_child(_effect_judge)
	_effect_judge.configure(_effect_llm, _case_state)
	_effect_judge.effects_applied.connect(_on_conversation_effects_applied)
	_effect_judge.judge_failed.connect(_on_conversation_judge_failed)

	_dialogue = DialogueService.new()
	_dialogue.name = "DialogueService"
	add_child(_dialogue)
	_dialogue.configure(_llm, _case_state, _effect_judge)

	_dialogue.line_appended.connect(_on_dialogue_line_appended)
	_dialogue.line_updated.connect(_on_dialogue_line_updated)
	_dialogue.busy_changed.connect(_on_dialogue_busy_changed)
	_dialogue.error_received.connect(_on_dialogue_error)
	_dialogue_panel.submitted.connect(_on_dialogue_submitted)
	_dialogue_panel.closed.connect(_on_dialogue_closed)
	_inspect_panel.action_confirmed.connect(_on_inspect_action_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if _dialogue_panel.is_open():
		if _dialogue_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _inspect_panel.is_open():
		if _inspect_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _book_panel.is_open():
		if _book_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if _try_trigger_inventory_action(event):
		get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("interact"):
		return

	var npc := _world.find_npc_at_player()
	if npc != null and npc.suspect != null:
		_open_dialogue_with(npc.suspect)
		get_viewport().set_input_as_handled()
		return

	var inspection := _world.find_inspection_at_player()
	if not inspection.is_empty():
		var action_label := str(inspection.get("action_label", "")).strip_edges()
		if action_label != "":
			_inspect_panel.show_action(
				str(inspection["title"]),
				str(inspection["description"]),
				action_label,
				str(inspection.get("action_prompt", "")),
				inspection.get("action_effects", [])
			)
		else:
			_inspect_panel.show_text(str(inspection["title"]), str(inspection["description"]))
		if _case_state != null:
			_case_state.apply_effects(inspection.get("effects", []))
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _inspect_panel.is_open() or _dialogue_panel.is_open() or _book_panel.is_open():
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


func _on_inspect_action_confirmed(effects: Array) -> void:
	if _case_state == null:
		return
	_case_state.apply_effects(effects)


func _on_conversation_effects_applied(changed_facts: Array) -> void:
	print("[case] conversation effects applied: %s" % [changed_facts])


func _on_conversation_judge_failed(message: String) -> void:
	print("[case] conversation effect judge failed: %s" % message)


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
