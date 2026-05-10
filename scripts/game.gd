extends Node2D

const VIEW_SIZE := Vector2(960.0, 540.0)
const ROOM_RECT := Rect2(Vector2(92.0, 92.0), Vector2(776.0, 356.0))
const PLAYER_START := Vector2(160.0, 274.0)
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 18.0
const NPC_RADIUS := 18.0
const NPC_INTERACT_RADIUS := 54.0
const CLUE_RADIUS := 14.0
const CLUE_INTERACT_RADIUS := 48.0
const MAX_CONVERSATION_LINES := 10
const MAX_DIALOGUE_LINES := 12

const SUSPECTS := [
	{
		"name": "Victoria Ashmore",
		"subtitle": "Victim's wife",
		"position": Vector2(540.0, 200.0),
		"color": Color8(140, 90, 120),
		"hat_color": Color8(90, 50, 80),
		"instructions": "You are Victoria Ashmore, widow of Lord Pemberton who was found dead tonight in the drawing room. You killed him after discovering he changed his will, cutting you out entirely in favour of a distant cousin. You are poised, cold, and practised at deception. You deny any involvement. If pressed about the silk glove found near the body, claim you left it there earlier in the afternoon when you were reading. You do not know that James the butler saw you leave the drawing room quickly around 9pm. Speak as a composed aristocrat concealing guilt beneath good manners. Fred the Detective is questioning you. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": true,
	},
	{
		"name": "James",
		"subtitle": "The Butler",
		"position": Vector2(720.0, 390.0),
		"color": Color8(70, 90, 130),
		"hat_color": Color8(40, 55, 80),
		"instructions": "You are James, the butler of Pemberton Manor. You are innocent. You spent the evening preparing the dining room. You saw Lady Victoria Ashmore leave the drawing room very quickly at approximately 9pm, which struck you as unusual — Lord Pemberton was still inside at the time. You also overheard a telephone call last week in which Lord Pemberton spoke of changing his will. You are loyal and cautious, reluctant to implicate Lady Ashmore unless Fred presses you directly with evidence. Fred the Detective is questioning you. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
	{
		"name": "Chef Renard",
		"subtitle": "The Cook",
		"position": Vector2(260.0, 380.0),
		"color": Color8(160, 110, 70),
		"hat_color": Color8(100, 75, 50),
		"instructions": "You are Chef Renard, the cook at Pemberton Manor. You are innocent. You were in the kitchen all evening but stepped outside to smoke near the kitchen door around 9pm. While outside, you heard raised voices from the direction of the drawing room — one voice was clearly a woman's. You also noticed the drawing room light was still on past midnight when you went to bed. You are blunt and impatient with the proceedings. Fred the Detective is questioning you. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
]

const CLUES := [
	{
		"position": Vector2(176.0, 156.0),
		"label": "Shattered Wine Glass",
		"description": "A crystal glass in pieces near the armchair. The fragments spread in a fan — it was thrown with force, not dropped. There is a faint red stain on the nearby wall.",
	},
	{
		"position": Vector2(476.0, 270.0),
		"label": "Silk Glove",
		"description": "A single white silk glove, monogrammed 'V.A.' in gold thread. Found within arm's reach of the body.",
	},
	{
		"position": Vector2(820.0, 310.0),
		"label": "Broken Window Latch",
		"description": "The latch is snapped. The damage is on the inside face — it was forced open from within, not by someone entering from outside.",
	},
]

const BACKGROUND_COLOR := Color8(236, 229, 214)
const ROOM_COLOR := Color8(213, 205, 187)
const OUTLINE_COLOR := Color8(53, 45, 36)
const PLAYER_COLOR := Color8(43, 77, 117)
const HAT_COLOR := Color8(32, 43, 56)
const CLUE_COLOR := Color8(214, 164, 75)
const CLUE_INSPECTED_COLOR := Color8(132, 180, 132)
const FURNITURE_COLOR := Color8(147, 109, 83)

enum Phase { EXPLORE, ACCUSE, RESULT }

var player_position := PLAYER_START
var clue_inspected: Array[bool] = [false, false, false]
var suspect_talked: Array[bool] = [false, false, false]
var suspect_conversations: Array = [[], [], []]
var suspect_dialogue_lines: Array = [[], [], []]
var game_phase: Phase = Phase.EXPLORE
var active_npc_index := -1
var accusation_step := 0
var accusation_suspect_idx := -1
var dialog_open := false
var clue_panel_open := false
var request_in_flight := false
var accusation_correct := false

var hud_layer: CanvasLayer
var status_label: Label
var hint_label: Label
var interact_prompt: PanelContainer
var interact_prompt_label: Label
var dialogue_panel: PanelContainer
var dialogue_title_label: Label
var dialogue_output: RichTextLabel
var dialogue_input: LineEdit
var dialogue_status_label: Label
var send_button: Button
var accuse_button: Button
var clue_panel: PanelContainer
var clue_title_label: Label
var clue_body_label: RichTextLabel
var accusation_panel: PanelContainer
var accusation_label: Label
var accusation_suspect_box: VBoxContainer
var accusation_evidence_box: VBoxContainer
var accusation_clue_buttons: Array[Button] = []
var result_panel: PanelContainer
var result_label: RichTextLabel
var llm_request: HTTPRequest


func _ready() -> void:
	_ensure_input_actions()
	_build_hud()
	_build_dialogue_ui()
	_build_clue_ui()
	_build_accusation_ui()
	_build_result_ui()
	_build_llm_request()
	_reset_game()


func _process(delta: float) -> void:
	_update_interact_prompt()

	if dialog_open or clue_panel_open or game_phase != Phase.EXPLORE or request_in_flight:
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction == Vector2.ZERO:
		return

	player_position += direction * PLAYER_SPEED * delta
	player_position = _clamp_to_room(player_position)
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if clue_panel_open:
		if event.is_action_pressed("ui_cancel"):
			_close_clue_panel()
			get_viewport().set_input_as_handled()
		return

	if dialog_open:
		if event.is_action_pressed("ui_cancel"):
			_close_dialogue()
			get_viewport().set_input_as_handled()
		return

	if game_phase != Phase.EXPLORE:
		return

	if event.is_action_pressed("interact"):
		var npc_idx := _nearest_npc_in_range()
		var clue_idx := _nearest_clue_in_range()
		if npc_idx >= 0:
			_open_dialogue(npc_idx)
			get_viewport().set_input_as_handled()
		elif clue_idx >= 0:
			_open_clue_panel(clue_idx)
			get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), BACKGROUND_COLOR, true)
	draw_rect(ROOM_RECT, ROOM_COLOR, true)
	draw_rect(ROOM_RECT, OUTLINE_COLOR, false, 4.0)
	_draw_furniture()
	_draw_clues()
	_draw_npcs()
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
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint_label.custom_minimum_size = Vector2(340.0, 0.0)
	box.add_child(hint_label)

	accuse_button = Button.new()
	accuse_button.text = "Make Accusation"
	accuse_button.disabled = true
	accuse_button.pressed.connect(_on_accuse_pressed)
	box.add_child(accuse_button)

	interact_prompt = PanelContainer.new()
	interact_prompt.visible = false
	hud_layer.add_child(interact_prompt)

	interact_prompt_label = Label.new()
	interact_prompt_label.text = "[E] Interact"
	interact_prompt.add_child(interact_prompt_label)


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

	dialogue_title_label = Label.new()
	box.add_child(dialogue_title_label)

	dialogue_status_label = Label.new()
	dialogue_status_label.visible = false
	box.add_child(dialogue_status_label)

	dialogue_output = RichTextLabel.new()
	dialogue_output.bbcode_enabled = false
	dialogue_output.scroll_following = true
	dialogue_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_output.custom_minimum_size = Vector2(0.0, 120.0)
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

	var close_btn := Button.new()
	close_btn.text = "Close [Esc]"
	close_btn.pressed.connect(_close_dialogue)
	input_row.add_child(close_btn)


func _build_clue_ui() -> void:
	clue_panel = PanelContainer.new()
	clue_panel.visible = false
	clue_panel.position = Vector2(240.0, 180.0)
	clue_panel.custom_minimum_size = Vector2(480.0, 0.0)
	hud_layer.add_child(clue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	clue_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	clue_title_label = Label.new()
	box.add_child(clue_title_label)

	clue_body_label = RichTextLabel.new()
	clue_body_label.bbcode_enabled = false
	clue_body_label.fit_content = true
	clue_body_label.custom_minimum_size = Vector2(432.0, 60.0)
	box.add_child(clue_body_label)

	var close_btn := Button.new()
	close_btn.text = "Close [Esc]"
	close_btn.pressed.connect(_close_clue_panel)
	box.add_child(close_btn)


func _build_accusation_ui() -> void:
	accusation_panel = PanelContainer.new()
	accusation_panel.visible = false
	accusation_panel.position = Vector2(280.0, 160.0)
	accusation_panel.custom_minimum_size = Vector2(400.0, 0.0)
	hud_layer.add_child(accusation_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	accusation_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	accusation_label = Label.new()
	accusation_label.text = "Who killed Lord Pemberton?"
	box.add_child(accusation_label)

	accusation_suspect_box = VBoxContainer.new()
	box.add_child(accusation_suspect_box)
	for i in range(SUSPECTS.size()):
		var btn := Button.new()
		btn.text = "%s  —  %s" % [SUSPECTS[i]["name"], SUSPECTS[i]["subtitle"]]
		btn.pressed.connect(_on_suspect_chosen.bind(i))
		accusation_suspect_box.add_child(btn)

	accusation_evidence_box = VBoxContainer.new()
	accusation_evidence_box.visible = false
	box.add_child(accusation_evidence_box)
	for i in range(CLUES.size()):
		var btn := Button.new()
		btn.text = CLUES[i]["label"]
		btn.pressed.connect(_on_evidence_chosen.bind(i))
		accusation_clue_buttons.append(btn)
		accusation_evidence_box.add_child(btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.pressed.connect(_close_accusation)
	box.add_child(cancel_btn)


func _build_result_ui() -> void:
	result_panel = PanelContainer.new()
	result_panel.visible = false
	result_panel.position = Vector2(200.0, 140.0)
	result_panel.custom_minimum_size = Vector2(560.0, 0.0)
	hud_layer.add_child(result_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	result_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	result_label = RichTextLabel.new()
	result_label.bbcode_enabled = false
	result_label.fit_content = true
	result_label.custom_minimum_size = Vector2(496.0, 80.0)
	box.add_child(result_label)

	var restart_btn := Button.new()
	restart_btn.text = "Play Again"
	restart_btn.pressed.connect(_reset_game)
	box.add_child(restart_btn)


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


func _draw_clues() -> void:
	for i in range(CLUES.size()):
		var color := CLUE_INSPECTED_COLOR if clue_inspected[i] else CLUE_COLOR
		var pos: Vector2 = CLUES[i]["position"]
		draw_circle(pos, CLUE_RADIUS, color)
		draw_circle(pos, CLUE_RADIUS, OUTLINE_COLOR, false, 2.0)


func _draw_npcs() -> void:
	for i in range(SUSPECTS.size()):
		var pos: Vector2 = SUSPECTS[i]["position"]
		var col: Color = SUSPECTS[i]["color"]
		var hat_col: Color = SUSPECTS[i]["hat_color"]
		draw_circle(pos, NPC_RADIUS, col)
		draw_circle(pos + Vector2(0.0, -24.0), 10.0, Color.WHITE)
		var hat_points := PackedVector2Array([
			pos + Vector2(-14.0, -26.0),
			pos + Vector2(14.0, -26.0),
			pos + Vector2(9.0, -38.0),
			pos + Vector2(-9.0, -38.0),
		])
		draw_colored_polygon(hat_points, hat_col)
		draw_rect(Rect2(pos + Vector2(-18.0, -27.0), Vector2(36.0, 4.0)), hat_col, true)


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


func _nearest_npc_in_range() -> int:
	var best := -1
	var best_dist := INF
	for i in range(SUSPECTS.size()):
		var pos: Vector2 = SUSPECTS[i]["position"]
		var d := player_position.distance_to(pos)
		if d <= PLAYER_RADIUS + NPC_INTERACT_RADIUS and d < best_dist:
			best_dist = d
			best = i
	return best


func _nearest_clue_in_range() -> int:
	var best := -1
	var best_dist := INF
	for i in range(CLUES.size()):
		var pos: Vector2 = CLUES[i]["position"]
		var d := player_position.distance_to(pos)
		if d <= PLAYER_RADIUS + CLUE_INTERACT_RADIUS and d < best_dist:
			best_dist = d
			best = i
	return best


func _update_interact_prompt() -> void:
	if interact_prompt == null:
		return
	if dialog_open or clue_panel_open or game_phase != Phase.EXPLORE:
		interact_prompt.visible = false
		return

	var npc_idx := _nearest_npc_in_range()
	var clue_idx := _nearest_clue_in_range()

	if npc_idx >= 0:
		interact_prompt.visible = true
		interact_prompt_label.text = "[E] Talk to %s" % SUSPECTS[npc_idx]["name"]
		var pos: Vector2 = SUSPECTS[npc_idx]["position"]
		interact_prompt.position = pos + Vector2(-60.0, -88.0)
	elif clue_idx >= 0:
		interact_prompt.visible = true
		interact_prompt_label.text = "[E] Inspect: %s" % CLUES[clue_idx]["label"]
		var pos: Vector2 = CLUES[clue_idx]["position"]
		interact_prompt.position = pos + Vector2(-60.0, -38.0)
	else:
		interact_prompt.visible = false


func _open_dialogue(suspect_idx: int) -> void:
	active_npc_index = suspect_idx
	dialog_open = true
	dialogue_panel.visible = true
	dialogue_title_label.text = "%s  —  %s" % [SUSPECTS[suspect_idx]["name"], SUSPECTS[suspect_idx]["subtitle"]]
	_refresh_dialogue_output()
	_set_dialogue_busy(false, "")
	dialogue_input.grab_focus()
	_update_hud()


func _close_dialogue() -> void:
	dialog_open = false
	dialogue_panel.visible = false
	active_npc_index = -1
	get_viewport().gui_release_focus()
	_update_hud()


func _open_clue_panel(clue_idx: int) -> void:
	clue_inspected[clue_idx] = true
	clue_panel_open = true
	clue_title_label.text = CLUES[clue_idx]["label"]
	clue_body_label.clear()
	clue_body_label.append_text(CLUES[clue_idx]["description"])
	clue_panel.visible = true
	_update_hud()
	queue_redraw()


func _close_clue_panel() -> void:
	clue_panel_open = false
	clue_panel.visible = false
	_update_hud()


func _on_accuse_pressed() -> void:
	accusation_step = 0
	accusation_suspect_idx = -1
	accusation_label.text = "Who killed Lord Pemberton?"
	accusation_suspect_box.visible = true
	accusation_evidence_box.visible = false
	accusation_panel.visible = true
	game_phase = Phase.ACCUSE
	_update_hud()


func _close_accusation() -> void:
	accusation_step = 0
	accusation_suspect_idx = -1
	accusation_panel.visible = false
	game_phase = Phase.EXPLORE
	_update_hud()


func _on_suspect_chosen(suspect_idx: int) -> void:
	accusation_suspect_idx = suspect_idx
	accusation_step = 1
	accusation_label.text = "What is your key evidence?"
	accusation_suspect_box.visible = false
	for i in range(CLUES.size()):
		accusation_clue_buttons[i].visible = clue_inspected[i]
	accusation_evidence_box.visible = true


func _on_evidence_chosen(clue_idx: int) -> void:
	accusation_panel.visible = false
	game_phase = Phase.RESULT
	accusation_correct = SUSPECTS[accusation_suspect_idx]["is_murderer"]
	_show_result(accusation_suspect_idx, clue_idx)


func _show_result(suspect_idx: int, clue_idx: int) -> void:
	var suspect_name: String = SUSPECTS[suspect_idx]["name"]
	var clue_label_text: String = CLUES[clue_idx]["label"]
	result_label.clear()
	if accusation_correct:
		if clue_idx == 1:
			result_label.append_text(
				"Correct.\n\n%s is the killer. The %s seals it.\n\nShe poisoned Lord Pemberton's wine after discovering he had rewritten his will to cut her out. Her monogrammed glove placed her at the scene. James saw her leave at 9pm. The window was forced from inside.\n\nPerfect deduction. Case closed." % [suspect_name, clue_label_text]
			)
		else:
			result_label.append_text(
				"Correct.\n\n%s is the killer.\n\nYou cited the %s — solid supporting evidence. The sharpest single piece was the silk glove monogrammed 'V.A.' found beside the body. James saw her leave at 9pm. The window was forced from inside.\n\nCase closed." % [suspect_name, clue_label_text]
			)
	else:
		var murderer_name: String = ""
		for s in SUSPECTS:
			if s["is_murderer"]:
				murderer_name = s["name"]
		result_label.append_text(
			"Wrong.\n\n%s is innocent. You cited the %s — but the evidence did not lead here.\n\nThe real killer was %s. The silk glove monogrammed 'V.A.' placed her at the scene. James saw her leave the drawing room at 9pm. The window latch was broken from the inside — not by an intruder." % [suspect_name, clue_label_text, murderer_name]
		)
	result_panel.visible = true
	_update_hud()


func _can_accuse() -> bool:
	var any_clue := false
	for found in clue_inspected:
		if found:
			any_clue = true
			break
	var any_talked := false
	for talked in suspect_talked:
		if talked:
			any_talked = true
			break
	return any_clue and any_talked


func _refresh_dialogue_output() -> void:
	if active_npc_index < 0:
		return
	dialogue_output.clear()
	var lines: Array = suspect_dialogue_lines[active_npc_index]
	if lines.size() > 0:
		dialogue_output.append_text("\n\n".join(lines))
		dialogue_output.scroll_to_line(max(0, dialogue_output.get_line_count() - 1))


func _append_dialogue(speaker: String, text: String) -> void:
	if active_npc_index < 0:
		return
	suspect_dialogue_lines[active_npc_index].append("%s: %s" % [speaker, text])
	while suspect_dialogue_lines[active_npc_index].size() > MAX_DIALOGUE_LINES:
		suspect_dialogue_lines[active_npc_index].remove_at(0)
	_refresh_dialogue_output()


func _set_dialogue_busy(is_busy: bool, status_text: String) -> void:
	request_in_flight = is_busy
	dialogue_input.editable = not is_busy
	send_button.disabled = is_busy
	dialogue_status_label.visible = not status_text.is_empty()
	dialogue_status_label.text = status_text


func _on_dialogue_submitted(_text: String) -> void:
	_send_dialogue_request()


func _send_dialogue_request() -> void:
	if request_in_flight or active_npc_index < 0:
		return

	var message := dialogue_input.text.strip_edges()
	if message.is_empty():
		return

	_append_dialogue("Fred", message)
	suspect_conversations[active_npc_index].append("Fred: %s" % message)
	while suspect_conversations[active_npc_index].size() > MAX_CONVERSATION_LINES:
		suspect_conversations[active_npc_index].remove_at(0)
	suspect_talked[active_npc_index] = true
	dialogue_input.clear()

	var suspect: Dictionary = SUSPECTS[active_npc_index]
	_set_dialogue_busy(true, "%s is thinking..." % suspect["name"])

	var payload := JSON.stringify({
		"input": _build_llm_input(active_npc_index),
		"instructions": suspect["instructions"],
		"max_output_tokens": 180,
	})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var error := llm_request.request(_get_llm_endpoint(), headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		_set_dialogue_busy(false, "")
		_append_dialogue("System", "Could not reach /api/llm.")


func _build_llm_input(suspect_idx: int) -> String:
	var clue_lines: Array[String] = []
	for i in range(CLUES.size()):
		if clue_inspected[i]:
			clue_lines.append("- %s: %s" % [CLUES[i]["label"], CLUES[i]["description"]])

	var clue_context := "Fred has not yet found any physical evidence."
	if clue_lines.size() > 0:
		clue_context = "Fred has found the following physical evidence:\n%s" % "\n".join(clue_lines)

	var turns: Array = suspect_conversations[suspect_idx]
	var transcript := "\n".join(turns) if turns.size() > 0 else "(conversation just started)"

	return "%s\n\nConversation so far:\n%s\n\nReply as %s to Fred's latest message." % [
		clue_context,
		transcript,
		SUSPECTS[suspect_idx]["name"],
	]


func _on_llm_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_set_dialogue_busy(false, "")

	if active_npc_index < 0:
		return

	var suspect: Dictionary = SUSPECTS[active_npc_index]
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())

	if result != HTTPRequest.RESULT_SUCCESS:
		_append_dialogue("System", "The connection failed.")
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
		reply = "%s says nothing." % suspect["name"]

	suspect_conversations[active_npc_index].append("%s: %s" % [suspect["name"], reply])
	while suspect_conversations[active_npc_index].size() > MAX_CONVERSATION_LINES:
		suspect_conversations[active_npc_index].remove_at(0)

	_append_dialogue(suspect["name"], reply)
	_update_hud()

	if dialog_open:
		dialogue_input.grab_focus()


func _reset_game() -> void:
	player_position = PLAYER_START
	clue_inspected = [false, false, false]
	suspect_talked = [false, false, false]
	suspect_conversations = [[], [], []]
	suspect_dialogue_lines = [[], [], []]
	game_phase = Phase.EXPLORE
	active_npc_index = -1
	accusation_step = 0
	accusation_suspect_idx = -1
	dialog_open = false
	clue_panel_open = false
	request_in_flight = false
	accusation_correct = false

	dialogue_panel.visible = false
	clue_panel.visible = false
	accusation_panel.visible = false
	result_panel.visible = false

	if dialogue_input != null:
		dialogue_input.clear()

	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	var found_count := 0
	for found in clue_inspected:
		if found:
			found_count += 1
	status_label.text = "Clues inspected: %d / %d" % [found_count, CLUES.size()]
	accuse_button.disabled = not _can_accuse()

	if game_phase == Phase.RESULT:
		hint_label.text = "Case closed."
	elif game_phase == Phase.ACCUSE:
		hint_label.text = "Choose your suspect carefully."
	elif dialog_open:
		hint_label.text = "Press Esc to end the conversation."
	elif clue_panel_open:
		hint_label.text = "Press Esc to close."
	elif _can_accuse():
		hint_label.text = "You have enough to accuse — or keep digging."
	else:
		hint_label.text = "Inspect clues [E] and question suspects [E]. Find evidence to accuse."


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
