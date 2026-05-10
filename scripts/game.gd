extends Node2D

const VIEW_SIZE := Vector2(960.0, 540.0)
const ROOM_RECT := Rect2(Vector2(92.0, 92.0), Vector2(776.0, 356.0))
const EXIT_RECT := Rect2(Vector2(768.0, 214.0), Vector2(84.0, 96.0))
const PLAYER_START := Vector2(160.0, 274.0)
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 18.0
const NPC_POSITION := Vector2(640.0, 278.0)
const NPC_RADIUS := 18.0
const NPC_INTERACT_RADIUS := 54.0
const CLUE_RADIUS := 12.0
const CLUE_POSITIONS := [
	Vector2(176.0, 156.0),
	Vector2(476.0, 170.0),
	Vector2(340.0, 368.0),
]
const MAX_CONVERSATION_LINES := 10
const MAX_DIALOGUE_LINES := 12
const NPC_NAME := "Mysterious Stranger"
const NPC_INSTRUCTIONS := "You are a cautious witness in Fred the Detective. Stay in character, keep replies concise, and answer as if Fred is speaking to you inside a detective game. Do not include speaker labels in your reply."

const BACKGROUND_COLOR := Color8(236, 229, 214)
const ROOM_COLOR := Color8(213, 205, 187)
const OUTLINE_COLOR := Color8(53, 45, 36)
const PLAYER_COLOR := Color8(43, 77, 117)
const HAT_COLOR := Color8(32, 43, 56)
const NPC_COLOR := Color8(116, 78, 63)
const NPC_HAT_COLOR := Color8(60, 50, 46)
const CLUE_COLOR := Color8(214, 164, 75)
const CLUE_FOUND_COLOR := Color8(132, 180, 132)
const EXIT_LOCKED_COLOR := Color8(126, 94, 75)
const EXIT_OPEN_COLOR := Color8(103, 175, 126)
const FURNITURE_COLOR := Color8(147, 109, 83)

var player_position := PLAYER_START
var clue_found: Array[bool] = [false, false, false]
var game_won := false
var dialog_open := false
var request_in_flight := false
var conversation_turns: Array[String] = []
var dialogue_lines: Array[String] = []

var hud_layer: CanvasLayer
var status_label: Label
var hint_label: Label
var interact_prompt: PanelContainer
var dialogue_panel: PanelContainer
var dialogue_output: RichTextLabel
var dialogue_input: LineEdit
var dialogue_status_label: Label
var send_button: Button
var llm_request: HTTPRequest


func _ready() -> void:
	_ensure_input_actions()
	_build_hud()
	_build_dialogue_ui()
	_build_llm_request()
	_reset_game()


func _process(delta: float) -> void:
	_update_interact_prompt()

	if dialog_open or request_in_flight:
		return

	if game_won:
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction == Vector2.ZERO:
		return

	player_position += direction * PLAYER_SPEED * delta
	player_position = _clamp_to_room(player_position)
	_collect_clues()
	_check_exit()
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if dialog_open:
		if event.is_action_pressed("ui_cancel"):
			_close_dialogue()
			get_viewport().set_input_as_handled()
		return

	if game_won and event.is_action_pressed("ui_accept"):
		_reset_game()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact") and _can_talk_to_npc():
		_open_dialogue()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), BACKGROUND_COLOR, true)
	draw_rect(ROOM_RECT, ROOM_COLOR, true)
	draw_rect(ROOM_RECT, OUTLINE_COLOR, false, 4.0)

	_draw_furniture()
	_draw_exit()
	_draw_clues()
	_draw_npc()
	_draw_player()


func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 20.0)
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	hud_layer.add_child(panel)

	var box := VBoxContainer.new()
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = "Fred the Detective"
	box.add_child(title_label)

	status_label = Label.new()
	box.add_child(status_label)

	hint_label = Label.new()
	hint_label.text = "Use arrow keys or WASD to collect the clues."
	box.add_child(hint_label)

	interact_prompt = PanelContainer.new()
	interact_prompt.visible = false
	hud_layer.add_child(interact_prompt)

	var prompt_label := Label.new()
	prompt_label.text = "[E] Talk"
	interact_prompt.add_child(prompt_label)


func _build_dialogue_ui() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.visible = false
	dialogue_panel.position = Vector2(140.0, 296.0)
	dialogue_panel.custom_minimum_size = Vector2(680.0, 208.0)
	hud_layer.add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	dialogue_panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	var title_label := Label.new()
	title_label.text = NPC_NAME
	box.add_child(title_label)

	dialogue_status_label = Label.new()
	dialogue_status_label.visible = false
	box.add_child(dialogue_status_label)

	dialogue_output = RichTextLabel.new()
	dialogue_output.bbcode_enabled = false
	dialogue_output.scroll_following = true
	dialogue_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_output.custom_minimum_size = Vector2(0.0, 138.0)
	box.add_child(dialogue_output)

	var input_row := HBoxContainer.new()
	box.add_child(input_row)

	dialogue_input = LineEdit.new()
	dialogue_input.placeholder_text = "Ask a question..."
	dialogue_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_input.text_submitted.connect(_on_dialogue_submitted)
	input_row.add_child(dialogue_input)

	send_button = Button.new()
	send_button.text = "Send"
	send_button.pressed.connect(_send_dialogue_request)
	input_row.add_child(send_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_close_dialogue)
	input_row.add_child(close_button)


func _build_llm_request() -> void:
	llm_request = HTTPRequest.new()
	add_child(llm_request)
	llm_request.request_completed.connect(_on_llm_request_completed)


func _draw_furniture() -> void:
	draw_rect(Rect2(Vector2(120.0, 116.0), Vector2(120.0, 48.0)), FURNITURE_COLOR, true)
	draw_rect(Rect2(Vector2(120.0, 116.0), Vector2(120.0, 48.0)), OUTLINE_COLOR, false, 2.0)
	draw_rect(Rect2(Vector2(560.0, 128.0), Vector2(140.0, 56.0)), FURNITURE_COLOR, true)
	draw_rect(Rect2(Vector2(560.0, 128.0), Vector2(140.0, 56.0)), OUTLINE_COLOR, false, 2.0)
	draw_rect(Rect2(Vector2(570.0, 330.0), Vector2(132.0, 64.0)), FURNITURE_COLOR, true)
	draw_rect(Rect2(Vector2(570.0, 330.0), Vector2(132.0, 64.0)), OUTLINE_COLOR, false, 2.0)


func _draw_exit() -> void:
	var exit_color := EXIT_LOCKED_COLOR
	if _all_clues_found():
		exit_color = EXIT_OPEN_COLOR

	draw_rect(EXIT_RECT, exit_color, true)
	draw_rect(EXIT_RECT, OUTLINE_COLOR, false, 3.0)


func _draw_clues() -> void:
	for index in range(CLUE_POSITIONS.size()):
		var color := CLUE_COLOR
		if clue_found[index]:
			color = CLUE_FOUND_COLOR

		draw_circle(CLUE_POSITIONS[index], CLUE_RADIUS, color)
		draw_circle(CLUE_POSITIONS[index], CLUE_RADIUS, OUTLINE_COLOR, false, 2.0)


func _draw_npc() -> void:
	draw_circle(NPC_POSITION, NPC_RADIUS, NPC_COLOR)
	draw_circle(NPC_POSITION + Vector2(0.0, -24.0), 10.0, Color.WHITE)

	var hat_points := PackedVector2Array([
		NPC_POSITION + Vector2(-14.0, -26.0),
		NPC_POSITION + Vector2(14.0, -26.0),
		NPC_POSITION + Vector2(9.0, -38.0),
		NPC_POSITION + Vector2(-9.0, -38.0),
	])
	draw_colored_polygon(hat_points, NPC_HAT_COLOR)
	draw_rect(Rect2(NPC_POSITION + Vector2(-18.0, -27.0), Vector2(36.0, 4.0)), NPC_HAT_COLOR, true)


func _draw_player() -> void:
	draw_circle(player_position, PLAYER_RADIUS, PLAYER_COLOR)
	draw_circle(player_position + Vector2(0.0, -24.0), 10.0, Color.WHITE)

	var hat_points := PackedVector2Array([
		player_position + Vector2(-14.0, -26.0),
		player_position + Vector2(14.0, -26.0),
		player_position + Vector2(9.0, -38.0),
		player_position + Vector2(-9.0, -38.0),
	])
	draw_colored_polygon(hat_points, HAT_COLOR)
	draw_rect(Rect2(player_position + Vector2(-18.0, -27.0), Vector2(36.0, 4.0)), HAT_COLOR, true)


func _collect_clues() -> void:
	for index in range(CLUE_POSITIONS.size()):
		if clue_found[index]:
			continue

		if player_position.distance_to(CLUE_POSITIONS[index]) <= PLAYER_RADIUS + CLUE_RADIUS:
			clue_found[index] = true


func _check_exit() -> void:
	if not _all_clues_found():
		return

	if EXIT_RECT.has_point(player_position):
		game_won = true


func _reset_game() -> void:
	player_position = PLAYER_START
	clue_found = [false, false, false]
	game_won = false
	dialog_open = false
	request_in_flight = false
	conversation_turns.clear()
	dialogue_lines.clear()
	dialogue_input.clear()
	dialogue_panel.visible = false
	_append_dialogue(NPC_NAME, "Need anything, detective?")
	_update_hud()
	_update_interact_prompt()
	queue_redraw()


func _update_hud() -> void:
	var found_total := _count_found_clues()
	status_label.text = "Clues found: %d / %d" % [found_total, clue_found.size()]

	if game_won:
		hint_label.text = "Case closed. Press Enter or Space to restart."
	elif dialog_open:
		hint_label.text = "Talking to the stranger. Press Esc to close the dialogue."
	elif _can_talk_to_npc():
		hint_label.text = "Press E near the stranger to ask about the case."
	elif _all_clues_found():
		hint_label.text = "All clues found. Head to the green exit."
	else:
		hint_label.text = "Use arrow keys or WASD to collect the clues."


func _all_clues_found() -> bool:
	for found in clue_found:
		if not found:
			return false
	return true


func _count_found_clues() -> int:
	var found_total := 0
	for found in clue_found:
		if found:
			found_total += 1
	return found_total


func _can_talk_to_npc() -> bool:
	if game_won:
		return false

	return player_position.distance_to(NPC_POSITION) <= PLAYER_RADIUS + NPC_INTERACT_RADIUS


func _update_interact_prompt() -> void:
	if interact_prompt == null:
		return

	var should_show := _can_talk_to_npc() and not dialog_open
	interact_prompt.visible = should_show
	if should_show:
		interact_prompt.position = NPC_POSITION + Vector2(-34.0, -88.0)


func _open_dialogue() -> void:
	dialog_open = true
	dialogue_panel.visible = true
	_set_dialogue_busy(false, "")
	dialogue_input.grab_focus()
	_update_hud()
	_update_interact_prompt()


func _close_dialogue() -> void:
	dialog_open = false
	dialogue_panel.visible = false
	get_viewport().gui_release_focus()
	_update_hud()
	_update_interact_prompt()


func _set_dialogue_busy(is_busy: bool, status_text: String) -> void:
	request_in_flight = is_busy
	dialogue_input.editable = not is_busy
	send_button.disabled = is_busy
	dialogue_status_label.visible = not status_text.is_empty()
	dialogue_status_label.text = status_text


func _append_dialogue(speaker: String, text: String) -> void:
	dialogue_lines.append("%s: %s" % [speaker, text])
	while dialogue_lines.size() > MAX_DIALOGUE_LINES:
		dialogue_lines.remove_at(0)

	dialogue_output.clear()
	dialogue_output.append_text("\n\n".join(dialogue_lines))
	dialogue_output.scroll_to_line(max(0, dialogue_output.get_line_count() - 1))


func _on_dialogue_submitted(_text: String) -> void:
	_send_dialogue_request()


func _send_dialogue_request() -> void:
	if request_in_flight:
		return

	var message := dialogue_input.text.strip_edges()
	if message.is_empty():
		return

	_append_dialogue("Fred", message)
	conversation_turns.append("Fred: %s" % message)
	_trim_conversation_turns()
	dialogue_input.clear()
	_set_dialogue_busy(true, "%s is thinking..." % NPC_NAME)

	var payload := JSON.stringify({
		"input": _build_llm_input(),
		"instructions": NPC_INSTRUCTIONS,
		"max_output_tokens": 180,
	})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := llm_request.request(_get_llm_endpoint(), headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		_set_dialogue_busy(false, "")
		_append_dialogue("System", "Could not reach /api/llm. Run the web build or a local server that exposes the API.")


func _build_llm_input() -> String:
	var transcript := "\n".join(conversation_turns)
	return "Fred the Detective is talking to %s. Fred has found %d of %d clues. Conversation so far:\n%s\nReply as %s to Fred's latest line." % [
		NPC_NAME,
		_count_found_clues(),
		clue_found.size(),
		transcript,
		NPC_NAME,
	]


func _trim_conversation_turns() -> void:
	while conversation_turns.size() > MAX_CONVERSATION_LINES:
		conversation_turns.remove_at(0)


func _on_llm_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_set_dialogue_busy(false, "")

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS:
		_append_dialogue("System", "The connection failed before %s could answer." % NPC_NAME)
		return

	if response_code != 200:
		var error_text := "The line went dead."
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error"):
			error_text = str(parsed["error"])
		_append_dialogue("System", error_text)
		return

	var reply := ""
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("text"):
		reply = str(parsed["text"]).strip_edges()
	if reply.is_empty():
		reply = "%s just watches you in silence." % NPC_NAME

	conversation_turns.append("%s: %s" % [NPC_NAME, reply])
	_trim_conversation_turns()
	_append_dialogue(NPC_NAME, reply)
	if dialog_open:
		dialogue_input.grab_focus()


func _get_llm_endpoint() -> String:
	if OS.has_feature("web"):
		var origin: String = ""
		if Engine.has_singleton("JavaScriptBridge"):
			origin = str(JavaScriptBridge.eval("window.location.origin", true)).strip_edges()
		if not origin.is_empty() and origin != "null":
			return "%s/api/llm" % origin.trim_suffix("/")
		return "http://127.0.0.1:3000/api/llm"
	return "http://127.0.0.1:3000/api/llm"


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


func _clamp_to_room(target_position: Vector2) -> Vector2:
	return Vector2(
		clampf(target_position.x, ROOM_RECT.position.x + PLAYER_RADIUS, ROOM_RECT.end.x - PLAYER_RADIUS),
		clampf(target_position.y, ROOM_RECT.position.y + PLAYER_RADIUS, ROOM_RECT.end.y - PLAYER_RADIUS)
	)
