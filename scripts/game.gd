extends Node2D

@onready var _world: WorldView = %WorldView
@onready var _inspect_panel: InspectPanel = %InspectPanel
@onready var _dialogue_panel: DialoguePanel = %DialoguePanel

var _llm: LLMClient
var _dialogue: DialogueService


func _ready() -> void:
	var case := CaseLoader.load_default()
	_world.configure(case)
	_world.reset_player(case.player_start_tile)

	_llm = LLMClient.new()
	_llm.name = "LLMClient"
	add_child(_llm)

	_dialogue = DialogueService.new()
	_dialogue.name = "DialogueService"
	add_child(_dialogue)
	_dialogue.configure(_llm)

	_dialogue.line_appended.connect(_on_dialogue_line_appended)
	_dialogue.busy_changed.connect(_on_dialogue_busy_changed)
	_dialogue.error_received.connect(_on_dialogue_error)
	_dialogue_panel.submitted.connect(_on_dialogue_submitted)
	_dialogue_panel.closed.connect(_on_dialogue_closed)


func _unhandled_input(event: InputEvent) -> void:
	if _dialogue_panel.is_open():
		if _dialogue_panel.handle_input_event(event):
			get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed("interact"):
		return

	if _inspect_panel.is_open():
		_inspect_panel.hide_panel()
		get_viewport().set_input_as_handled()
		return

	var npc := _world.find_npc_at_player()
	if npc != null and npc.suspect != null:
		_open_dialogue_with(npc.suspect)
		get_viewport().set_input_as_handled()
		return

	var inspection := _world.find_inspection_at_player()
	if not inspection.is_empty():
		_inspect_panel.show_text(str(inspection["title"]), str(inspection["description"]))
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _inspect_panel.is_open() or _dialogue_panel.is_open():
		return
	_world.update_player_movement(delta, _get_pressed_tile_direction())


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


func _on_dialogue_busy_changed(is_busy: bool) -> void:
	_dialogue_panel.set_busy(is_busy)


func _on_dialogue_error(message: String) -> void:
	_dialogue_panel.show_error(message)


func _on_dialogue_closed() -> void:
	_dialogue.close()


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
