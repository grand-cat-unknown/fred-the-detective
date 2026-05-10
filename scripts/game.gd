@tool
extends Node2D
class_name DetectiveGame

const TILE_SIZE := 30.0
const MAP_WIDTH := 32
const MAP_HEIGHT := 18
const VIEW_SIZE := Vector2(TILE_SIZE * MAP_WIDTH, TILE_SIZE * MAP_HEIGHT)
const PLAYER_START_TILE := Vector2i(5, 13)
const PLAYER_START := Vector2(165.0, 405.0)
const DEFAULT_PLAYER_SPEED := 240.0
const DEFAULT_PLAYER_RADIUS := 12.0
const NPC_RADIUS := 12.0
const DEFAULT_NPC_INTERACT_RADIUS := 54.0
const CLUE_RADIUS := 10.0
const DEFAULT_CLUE_INTERACT_RADIUS := 48.0
const DEFAULT_MAX_CONVERSATION_LINES := 10
const DEFAULT_MAX_DIALOGUE_LINES := 12
const UNTRUSTED_PLAYER_START := "[UNTRUSTED_PLAYER_MESSAGE_BEGIN]"
const UNTRUSTED_PLAYER_END := "[UNTRUSTED_PLAYER_MESSAGE_END]"
const SUSPECT_PEMBERTON := 0
const SUSPECT_WALTER := 1
const SUSPECT_MARA := 2
const SUSPECT_THEO := 3
const SUSPECT_LENA := 4
const SUSPECT_VIV := 5
const CLUE_BODY_WALL := 0
const CLUE_PEDESTAL := 1
const CLUE_AUCTION_RECEIPT := 2
const CLUE_FIELD_BOOK := 3
const CLUE_ROOM_1220_LOG := 4
const CLUE_CHUTE_NOTICE := 5
const CLUE_GHOST_CELL := 6
const CLUE_GLOVES := 7
const ROOM_CONCIERGE := "concierge"
const ROOM_1220 := "room_1220"
const ROOM_GEAR := "gear_cart"
const ROOM_HALL := "twelfth_hall"
const ROOM_SUITE := "suite_1221"
const ROOM_LOBBY := "elevator_lobby"
const ROOM_CHUTE := "chute_access"
const ROOM_1223 := "room_1223"
const ROOM_START := ROOM_LOBBY
const EDITOR_PREVIEW_ROOM_IDS := [
	ROOM_CONCIERGE,
	ROOM_1220,
	ROOM_GEAR,
	ROOM_HALL,
	ROOM_SUITE,
	ROOM_LOBBY,
	ROOM_CHUTE,
	ROOM_1223,
]
const REQUIRED_ACCUSATION_CLUE_IDX := CLUE_GHOST_CELL
const ACCUSATION_VERIFIER_INSTRUCTIONS := "You are the final case-verdict verifier for Fred the Detective. You are not a suspect and you do not roleplay. The case truth is authored by the game and must be treated as authoritative. Return only compact JSON with this exact shape: {\"is_correct\": boolean, \"headline\": string, \"feedback\": string}. Mark is_correct true only when the player accuses Dr. Otis Pemberton, cites the Ghost Cell in the Chute as the key evidence, and gives a coherent explanation connecting the ghost cell to the murder method, the stolen idol, and Pemberton's motive or opportunity. Mark false if the suspect is wrong, the key evidence is wrong, the explanation is vague, or the explanation contradicts the authored truth. Keep headline under 8 words. Keep feedback under 90 words, written as Fred's case-board verdict."
const MAP_ROWS := [
	"################################",
	"#........##........##..........#",
	"#..DD....##...C....##....GG....#",
	"#........##........##..........#",
	"#........##........##..........#",
	"####d#########d##########d######",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"####d###########d#########d#####",
	"#.......#.....#.........#......#",
	"#..BB..E#E.C..#.,,PP,,..#..DD..#",
	"#.......#.....#.........#......#",
	"#.......#.....#.........#......#",
	"#.......#.....#.........#......#",
	"################################",
	"################################",
]
const BLOCKING_TILES := ["#", "D", "B", "C", "G", "P", "d", "E"]

const ROOMS := [
	{
		"id": ROOM_CONCIERGE,
		"label": "CONCIERGE / SECURITY",
		"rect": Rect2(30.0, 30.0, 240.0, 150.0),
		"label_position": Vector2(45.0, 42.0),
		"color": Color8(206, 184, 128, 44),
	},
	{
		"id": ROOM_1220,
		"label": "ROOM 1220",
		"rect": Rect2(330.0, 30.0, 240.0, 150.0),
		"label_position": Vector2(345.0, 42.0),
		"color": Color8(150, 175, 190, 44),
	},
	{
		"id": ROOM_GEAR,
		"label": "SERVICE CORRIDOR / GEAR CART",
		"rect": Rect2(630.0, 30.0, 300.0, 150.0),
		"label_position": Vector2(645.0, 42.0),
		"color": Color8(125, 155, 145, 44),
	},
	{
		"id": ROOM_HALL,
		"label": "TWELFTH FLOOR HALL",
		"rect": Rect2(30.0, 180.0, 900.0, 120.0),
		"label_position": Vector2(45.0, 192.0),
		"color": Color8(105, 130, 150, 34),
	},
	{
		"id": ROOM_SUITE,
		"label": "SUITE 1221 - VANCE",
		"rect": Rect2(450.0, 300.0, 300.0, 180.0),
		"label_position": Vector2(465.0, 312.0),
		"color": Color8(160, 95, 105, 44),
	},
	{
		"id": ROOM_LOBBY,
		"label": "ELEVATOR LOBBY / STAIRWELL",
		"rect": Rect2(30.0, 300.0, 240.0, 180.0),
		"label_position": Vector2(45.0, 312.0),
		"color": Color8(110, 150, 180, 44),
	},
	{
		"id": ROOM_CHUTE,
		"label": "11F CHUTE ACCESS",
		"rect": Rect2(270.0, 300.0, 180.0, 180.0),
		"label_position": Vector2(285.0, 312.0),
		"color": Color8(130, 120, 105, 48),
	},
	{
		"id": ROOM_1223,
		"label": "ROOM 1223",
		"rect": Rect2(750.0, 300.0, 180.0, 180.0),
		"label_position": Vector2(765.0, 312.0),
		"color": Color8(150, 115, 165, 44),
	},
]

const ROOM_TILE_BOUNDS := {
	ROOM_CONCIERGE: Rect2i(0, 0, 11, 6),
	ROOM_1220: Rect2i(9, 0, 12, 6),
	ROOM_GEAR: Rect2i(19, 0, 13, 6),
	ROOM_HALL: Rect2i(0, 5, 32, 6),
	ROOM_LOBBY: Rect2i(0, 10, 9, 7),
	ROOM_CHUTE: Rect2i(8, 10, 7, 7),
	ROOM_SUITE: Rect2i(14, 10, 11, 7),
	ROOM_1223: Rect2i(24, 10, 8, 7),
}

const DOORS := [
	{"tile": Vector2i(4, 5), "rooms": [ROOM_CONCIERGE, ROOM_HALL]},
	{"tile": Vector2i(14, 5), "rooms": [ROOM_1220, ROOM_HALL]},
	{"tile": Vector2i(25, 5), "rooms": [ROOM_GEAR, ROOM_HALL]},
	{"tile": Vector2i(4, 10), "rooms": [ROOM_HALL, ROOM_LOBBY]},
	{"tile": Vector2i(16, 10), "rooms": [ROOM_HALL, ROOM_SUITE]},
	{"tile": Vector2i(26, 10), "rooms": [ROOM_HALL, ROOM_1223]},
]

const ELEVATORS := [
	{
		"tile_a": Vector2i(7, 12),
		"spawn_a": Vector2i(6, 12),
		"room_a": ROOM_LOBBY,
		"tile_b": Vector2i(9, 12),
		"spawn_b": Vector2i(10, 12),
		"room_b": ROOM_CHUTE,
	},
]

const SUSPECTS := [
	{
		"name": "Dr. Otis Pemberton",
		"subtitle": "Ghostbusters physician",
		"position": Vector2(555.0, 255.0),
		"room": ROOM_HALL,
		"color": Color8(126, 89, 150),
		"hat_color": Color8(74, 45, 94),
		"instructions": "You are Dr. Otis Pemberton, a Ghostbusters physician and occult scholar. You murdered Reginald Vance in suite 1221 by opening a charged spare ghost cell at close range, stole the black anchor idol, hid it inside the cell's outer case, dropped it into the jammed laundry chute, and pretended you had checked room 1220. You wanted the idol for your research before Vance locked it away. Do not confess unless Fred has clearly named the ghost cell, the idol in the chute, your gloves, and the false 1220 sweep. Otherwise deny calmly, lean on the real haunting, and sound helpful but faintly superior. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": true,
	},
	{
		"name": "Walter Crane",
		"subtitle": "Rival collector",
		"position": Vector2(345.0, 255.0),
		"room": ROOM_HALL,
		"color": Color8(157, 102, 70),
		"hat_color": Color8(101, 64, 45),
		"instructions": "You are Walter Crane, a theatrical rival collector staying below the Sedgewick Hotel's twelfth floor. You lost the black idol to Reginald Vance at auction and wanted it badly, which makes you look suspicious, but you are innocent. Around 9:12 PM you heard something heavy strike the laundry chute. You did not understand its importance at first and resent being treated as obvious. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
	{
		"name": "Mara Bell",
		"subtitle": "Ghostbusters field lead",
		"position": Vector2(165.0, 435.0),
		"room": ROOM_LOBBY,
		"color": Color8(84, 128, 157),
		"hat_color": Color8(43, 75, 101),
		"instructions": "You are Mara Bell, the Ghostbusters field lead. You are innocent. During the haunting you assigned Otis Pemberton to clear room 1220, Lena Ortiz to check room 1223, Theo Griggs to guard the gear cart, and yourself to the elevator lobby and stairwell. You did not see Pemberton come out of room 1220; you saw him return from the direction of Vance's suite. You are disciplined, protective of your team, and increasingly troubled by the timeline. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
	{
		"name": "Theo Griggs",
		"subtitle": "Ghostbusters technician",
		"position": Vector2(765.0, 135.0),
		"room": ROOM_GEAR,
		"color": Color8(67, 119, 122),
		"hat_color": Color8(38, 76, 82),
		"instructions": "You are Theo Griggs, the Ghostbusters technician. You are innocent. You guarded the gear cart during the sweep and later noticed a charged spare ghost cell was missing; Pemberton waved it off as a paperwork error. You can explain that a purged charged cell can leave dark violet residue on protective gloves. You are practical, defensive about the equipment, and frustrated by sloppy assumptions. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
	{
		"name": "Lena Ortiz",
		"subtitle": "Ghostbusters trap operator",
		"position": Vector2(825.0, 435.0),
		"room": ROOM_1223,
		"color": Color8(138, 84, 148),
		"hat_color": Color8(82, 48, 96),
		"instructions": "You are Lena Ortiz, a Ghostbusters trap operator. You are innocent. You were checking room 1223 during the sweep. You noticed Pemberton return with his gloves still on and one hand tucked against his side, as if hiding equipment or residue. You do not want to accuse a teammate without proof, but you are observant and honest when Fred asks pointed questions. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
	{
		"name": "Vivian Marsh",
		"subtitle": "Hotel concierge",
		"position": Vector2(165.0, 105.0),
		"room": ROOM_CONCIERGE,
		"color": Color8(166, 133, 76),
		"hat_color": Color8(96, 75, 46),
		"instructions": "You are Vivian Marsh, the Sedgewick Hotel concierge. You are innocent and trying to protect guests and the hotel's reputation. The laundry chute has been jammed between floors 12 and 11 for a week. The security dashboard lagged during the haunting, but the room lock timestamps are accurate. Once Fred has found the 1220 door record and the ghost cell in the chute, you can clarify that you opened room 1220 at 9:18 PM after Vance's body was found; it was not Pemberton's sweep. Keep replies under three sentences and do not include speaker labels.",
		"is_murderer": false,
	},
]

const CLUES := [
	{
		"position": Vector2(525.0, 375.0),
		"room": ROOM_SUITE,
		"label": "Vance's Body and Wall Fan",
		"description": "Reginald Vance has a small cold-burn wound under his ribs. Violet ectoplasm smears his jacket, and a narrow fan of matching residue runs from the body toward the wall.",
	},
	{
		"position": Vector2(585.0, 375.0),
		"room": ROOM_SUITE,
		"label": "Empty Idol Pedestal",
		"description": "Gray binding dust surrounds a clean idol-shaped absence on the pedestal. The idol was present when the dust fell, then removed afterward.",
	},
	{
		"position": Vector2(495.0, 435.0),
		"room": ROOM_SUITE,
		"label": "Auction Receipt",
		"description": "The receipt shows Vance beat Walter Crane for the black stone idol. A folded note from Pemberton urges Vance to surrender the idol for scholarly study.",
	},
	{
		"position": Vector2(615.0, 435.0),
		"room": ROOM_SUITE,
		"label": "Anchor Idol Field Book",
		"description": "The field book says anchor idols attract hauntings but do not vanish when hauntings end. It also diagrams opened ghost cells: directional cones, cold-burn wounds, side-vent dust, and blocked silhouettes.",
	},
	{
		"position": Vector2(435.0, 105.0),
		"room": ROOM_1220,
		"label": "Room 1220 Door Record",
		"description": "The lock record shows room 1220 opened at 9:18 PM. The dashboard was lagging during the haunting, so the entry feels ambiguous until someone explains who opened it.",
	},
	{
		"position": Vector2(225.0, 255.0),
		"room": ROOM_HALL,
		"label": "Laundry Chute Notice",
		"description": "A maintenance notice says the laundry chute is blocked between floors 12 and 11. If something heavy went down the chute tonight, it may still be wedged there.",
	},
	{
		"position": Vector2(345.0, 435.0),
		"room": ROOM_CHUTE,
		"label": "Ghost Cell in the Chute",
		"description": "A spent spare ghost cell is wedged above floor 11. The black idol is hidden inside its outer case. Residue on the main port matches the wall fan, and gray dust on the side vents matches the pedestal.",
		"unlock": "chute",
	},
	{
		"position": Vector2(825.0, 105.0),
		"room": ROOM_GEAR,
		"label": "Pemberton's Gloves",
		"description": "Pemberton's protective gloves are stained dark violet inside the fingers, the pattern Theo described for someone who opened and purged a charged ghost cell by hand.",
		"unlock": "gloves",
	},
]

const DEFAULT_BACKGROUND_COLOR := Color8(34, 39, 43)
const DEFAULT_FLOOR_COLOR := Color8(195, 185, 160)
const DEFAULT_FLOOR_ALT_COLOR := Color8(184, 174, 149)
const DEFAULT_WALL_COLOR := Color8(94, 103, 111)
const DEFAULT_WALL_TOP_COLOR := Color8(128, 138, 145)
const DEFAULT_RUG_COLOR := Color8(112, 54, 62)
const DEFAULT_RUG_TRIM_COLOR := Color8(183, 150, 84)
const DEFAULT_RUNNER_COLOR := Color8(79, 119, 126)
const DEFAULT_OUTLINE_COLOR := Color8(45, 40, 36)
const DEFAULT_PLAYER_COLOR := Color8(43, 77, 117)
const DEFAULT_PLAYER_HAT_COLOR := Color8(32, 43, 56)
const DEFAULT_CLUE_COLOR := Color8(214, 164, 75)
const DEFAULT_CLUE_INSPECTED_COLOR := Color8(132, 180, 132)
const WOOD_COLOR := Color8(126, 86, 59)
const SOFA_COLOR := Color8(72, 109, 96)
const CABINET_COLOR := Color8(116, 88, 121)
const GEAR_COLOR := Color8(66, 84, 89)
const PEDESTAL_COLOR := Color8(156, 145, 126)
const DOOR_COLOR := Color8(142, 98, 66)
const DOOR_TRIM_COLOR := Color8(82, 58, 42)
const DEFAULT_ROOM_BORDER_COLOR := Color8(52, 48, 43)
const DEFAULT_ROOM_LABEL_COLOR := Color8(42, 38, 34)
const DEFAULT_ROOM_LABEL_FONT_SIZE := 12

enum Phase { EXPLORE, ACCUSE, RESULT }

@export_group("Editor Preview")
@export_enum(
	"Concierge / Security",
	"Room 1220",
	"Gear Cart",
	"Twelfth Floor Hall",
	"Suite 1221",
	"Elevator Lobby",
	"Chute Access",
	"Room 1223"
) var editor_preview_room_index := 5:
	set(value):
		editor_preview_room_index = value
		if Engine.is_editor_hint():
			current_room = _editor_preview_room_id()
		_queue_world_redraw()
@export var editor_show_locked_clues := true:
	set(value):
		editor_show_locked_clues = value
		_queue_world_redraw()

@export_group("Movement")
@export_range(60.0, 600.0, 5.0, "or_greater") var player_speed := DEFAULT_PLAYER_SPEED
@export_range(4.0, 32.0, 1.0, "or_greater") var player_radius := DEFAULT_PLAYER_RADIUS

@export_group("Interaction")
@export_range(16.0, 128.0, 1.0, "or_greater") var npc_interact_radius := DEFAULT_NPC_INTERACT_RADIUS
@export_range(16.0, 128.0, 1.0, "or_greater") var clue_interact_radius := DEFAULT_CLUE_INTERACT_RADIUS

@export_group("Dialogue")
@export_range(2, 30, 1, "or_greater") var max_conversation_lines := DEFAULT_MAX_CONVERSATION_LINES
@export_range(2, 40, 1, "or_greater") var max_dialogue_lines := DEFAULT_MAX_DIALOGUE_LINES

@export_group("Palette")
@export var background_color := DEFAULT_BACKGROUND_COLOR:
	set(value):
		background_color = value
		_queue_world_redraw()
@export var floor_color := DEFAULT_FLOOR_COLOR:
	set(value):
		floor_color = value
		_queue_world_redraw()
@export var floor_alt_color := DEFAULT_FLOOR_ALT_COLOR:
	set(value):
		floor_alt_color = value
		_queue_world_redraw()
@export var wall_color := DEFAULT_WALL_COLOR:
	set(value):
		wall_color = value
		_queue_world_redraw()
@export var wall_top_color := DEFAULT_WALL_TOP_COLOR:
	set(value):
		wall_top_color = value
		_queue_world_redraw()
@export var rug_color := DEFAULT_RUG_COLOR:
	set(value):
		rug_color = value
		_queue_world_redraw()
@export var rug_trim_color := DEFAULT_RUG_TRIM_COLOR:
	set(value):
		rug_trim_color = value
		_queue_world_redraw()
@export var runner_color := DEFAULT_RUNNER_COLOR:
	set(value):
		runner_color = value
		_queue_world_redraw()
@export var outline_color := DEFAULT_OUTLINE_COLOR:
	set(value):
		outline_color = value
		_queue_world_redraw()
@export var player_color := DEFAULT_PLAYER_COLOR:
	set(value):
		player_color = value
		_queue_world_redraw()
@export var player_hat_color := DEFAULT_PLAYER_HAT_COLOR:
	set(value):
		player_hat_color = value
		_queue_world_redraw()
@export var clue_color := DEFAULT_CLUE_COLOR:
	set(value):
		clue_color = value
		_queue_world_redraw()
@export var clue_inspected_color := DEFAULT_CLUE_INSPECTED_COLOR:
	set(value):
		clue_inspected_color = value
		_queue_world_redraw()
@export var room_border_color := DEFAULT_ROOM_BORDER_COLOR:
	set(value):
		room_border_color = value
		_queue_world_redraw()
@export var room_label_color := DEFAULT_ROOM_LABEL_COLOR
@export_range(8, 24, 1, "or_greater") var room_label_font_size := DEFAULT_ROOM_LABEL_FONT_SIZE

var _case: CaseData
var _llm: LLMClient
var _dialogue: DialogueService
var _accusation: AccusationService
var _current_target := InteractTarget.none()

var player_position := PLAYER_START
var player_tile := PLAYER_START_TILE
var player_target_position := PLAYER_START
var player_is_stepping := false
var player_face_direction := Vector2i(1, 0)
var current_room: StringName = &"elevator_lobby"
var game_phase: Phase = Phase.EXPLORE
var active_npc_index := -1
var accusation_step := 0
var accusation_suspect_idx := -1
var accusation_evidence_idx := -1
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
var accusation_explanation_box: VBoxContainer
var accusation_explanation_input: TextEdit
var accusation_submit_button: Button
var accusation_status_label: Label
var accusation_clue_buttons: Array[Button] = []
var result_panel: PanelContainer
var result_label: RichTextLabel
var llm_request: HTTPRequest
var _world_layer: Node2D
var _world_map: WorldMap
var _player: Player
var _room_zones: Array[RoomZone] = []
var _npc_nodes: Array[NPC] = []
var _clue_markers: Array[ClueMarker] = []
var _door_nodes: Array[Door] = []
var _elevator_nodes: Array[Elevator] = []


func _editor_preview_room_id() -> StringName:
	var index := clampi(editor_preview_room_index, 0, EDITOR_PREVIEW_ROOM_IDS.size() - 1)
	return StringName(EDITOR_PREVIEW_ROOM_IDS[index])


func _ready() -> void:
	_case = CaseLoader.load_default()
	_ensure_world_nodes()
	if Engine.is_editor_hint():
		current_room = _editor_preview_room_id()
		_refresh_world_nodes()
		return

	_ensure_input_actions()
	_cache_scene_nodes()
	_configure_scene_ui_defaults()
	_build_services()
	_wire_scene_signals()
	_wire_event_bus()
	_populate_accusation_buttons()
	_reset_game()


func _process(delta: float) -> void:
	_update_interact_prompt()

	if dialog_open or clue_panel_open or game_phase != Phase.EXPLORE or request_in_flight:
		return

	if player_is_stepping:
		_player.process_step(delta)
		_sync_player_state()
		if not player_is_stepping:
			_update_hud()
		return

	var direction := _get_pressed_tile_direction()
	if direction != Vector2i.ZERO:
		_try_start_tile_step(direction)


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

	if request_in_flight:
		return

	if event.is_action_pressed("interact"):
		_refresh_interact_target()
		match _current_target.kind:
			GameEnums.InteractKind.NPC:
				_open_dialogue(_current_target.index)
				get_viewport().set_input_as_handled()
			GameEnums.InteractKind.CLUE:
				_open_clue_panel(_current_target.index)
				get_viewport().set_input_as_handled()
			GameEnums.InteractKind.ELEVATOR:
				_enter_elevator(_current_target.index)
				get_viewport().set_input_as_handled()
			GameEnums.InteractKind.DOOR:
				_enter_door(_current_target.index)
				get_viewport().set_input_as_handled()


func _draw() -> void:
	pass


func _cache_scene_nodes() -> void:
	hud_layer = %HUDLayer
	status_label = %StatusLabel
	hint_label = %HintLabel
	interact_prompt = %InteractPrompt
	interact_prompt_label = %InteractPromptLabel
	dialogue_panel = %DialoguePanel
	dialogue_title_label = %DialogueTitleLabel
	dialogue_output = %DialogueOutput
	dialogue_input = %DialogueInput
	dialogue_status_label = %DialogueStatusLabel
	send_button = %SendButton
	accuse_button = %AccuseButton
	clue_panel = %CluePanel
	clue_title_label = %ClueTitleLabel
	clue_body_label = %ClueBodyLabel
	accusation_panel = %AccusationPanel
	accusation_label = %AccusationLabel
	accusation_suspect_box = %AccusationSuspectBox
	accusation_evidence_box = %AccusationEvidenceBox
	accusation_explanation_box = %AccusationExplanationBox
	accusation_explanation_input = %AccusationExplanationInput
	accusation_submit_button = %AccusationSubmitButton
	accusation_status_label = %AccusationStatusLabel
	result_panel = %ResultPanel
	result_label = %ResultLabel
	llm_request = %LLMRequest


func _configure_scene_ui_defaults() -> void:
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_output.bbcode_enabled = false
	dialogue_output.scroll_following = true
	clue_body_label.bbcode_enabled = false
	clue_body_label.fit_content = true
	accusation_explanation_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	accusation_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	result_label.bbcode_enabled = false
	result_label.fit_content = true


func _build_services() -> void:
	_llm = LLMClient.new(llm_request)
	add_child(_llm)

	_dialogue = DialogueService.new()
	add_child(_dialogue)
	_dialogue.configure(_case, _llm)

	_accusation = AccusationService.new()
	add_child(_accusation)
	_accusation.configure(_case, _llm)


func _wire_scene_signals() -> void:
	_connect_once(accuse_button.pressed, _on_accuse_pressed)
	_connect_once(dialogue_input.text_submitted, _on_dialogue_submitted)
	_connect_once(send_button.pressed, _send_dialogue_request)
	_connect_once(%DialogueCloseButton.pressed, _close_dialogue)
	_connect_once(%ClueCloseButton.pressed, _close_clue_panel)
	_connect_once(accusation_explanation_input.text_changed, _on_accusation_explanation_changed)
	_connect_once(accusation_submit_button.pressed, _on_accusation_submit_pressed)
	_connect_once(%AccusationCancelButton.pressed, _close_accusation)
	_connect_once(%RestartButton.pressed, _reset_game)


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


func _populate_accusation_buttons() -> void:
	_clear_children(accusation_suspect_box)
	_clear_children(accusation_evidence_box)
	accusation_clue_buttons.clear()

	for i in range(_case.suspects.size()):
		var suspect := _case.suspects[i]
		var btn := Button.new()
		btn.text = "%s - %s" % [suspect.display_name, suspect.subtitle]
		btn.pressed.connect(_on_suspect_chosen.bind(i))
		accusation_suspect_box.add_child(btn)

	for i in range(_case.clues.size()):
		var clue := _case.clues[i]
		var btn := Button.new()
		btn.text = clue.label
		btn.pressed.connect(_on_evidence_chosen.bind(i))
		accusation_clue_buttons.append(btn)
		accusation_evidence_box.add_child(btn)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _ensure_world_nodes() -> void:
	if _world_layer != null:
		return

	_world_layer = Node2D.new()
	_world_layer.name = "WorldLayer"
	add_child(_world_layer)
	move_child(_world_layer, 0)

	_world_map = WorldMap.new()
	_world_map.name = "WorldMap"
	_world_layer.add_child(_world_map)

	_rebuild_world_content()


func _rebuild_world_content() -> void:
	for child in _world_layer.get_children():
		if child != _world_map:
			child.queue_free()
	_room_zones.clear()
	_npc_nodes.clear()
	_clue_markers.clear()
	_door_nodes.clear()
	_elevator_nodes.clear()

	if _case == null:
		return

	_world_map.configure(_case)

	for door in _case.doors:
		var door_node := Door.new()
		door_node.configure(door)
		_world_layer.add_child(door_node)
		_door_nodes.append(door_node)

	for elevator in _case.elevators:
		var elevator_node := Elevator.new()
		elevator_node.configure(elevator)
		_world_layer.add_child(elevator_node)
		_elevator_nodes.append(elevator_node)

	for room in _case.rooms:
		var room_zone := RoomZone.new()
		room_zone.border_color = room_border_color
		room_zone.label_color = room_label_color
		room_zone.label_font_size = room_label_font_size
		room_zone.configure(room)
		_world_layer.add_child(room_zone)
		_room_zones.append(room_zone)

	for clue in _case.clues:
		var clue_marker := ClueMarker.new()
		clue_marker.clue_color = clue_color
		clue_marker.clue_inspected_color = clue_inspected_color
		clue_marker.outline_color = outline_color
		clue_marker.show_locked_clues = Engine.is_editor_hint() and editor_show_locked_clues
		clue_marker.configure(clue)
		_world_layer.add_child(clue_marker)
		_clue_markers.append(clue_marker)

	for suspect in _case.suspects:
		var npc := NPC.new()
		npc.configure(suspect)
		_world_layer.add_child(npc)
		_npc_nodes.append(npc)

	_player = Player.new()
	_player.name = "Player"
	_player.speed = player_speed
	_player.body_color = player_color
	_player.hat_color = player_hat_color
	_world_layer.add_child(_player)
	if Engine.is_editor_hint():
		_player.visible = false

	_refresh_world_nodes()


func _refresh_world_nodes() -> void:
	if _world_map == null:
		return

	_world_map.background_color = background_color
	_world_map.floor_color = floor_color
	_world_map.floor_alt_color = floor_alt_color
	_world_map.wall_color = wall_color
	_world_map.wall_top_color = wall_top_color
	_world_map.rug_color = rug_color
	_world_map.rug_trim_color = rug_trim_color
	_world_map.runner_color = runner_color
	_world_map.outline_color = outline_color
	_world_map.set_current_room(current_room)

	for room_zone in _room_zones:
		room_zone.border_color = room_border_color
		room_zone.label_color = room_label_color
		room_zone.label_font_size = room_label_font_size
		room_zone.set_current_room(current_room)

	for door_node in _door_nodes:
		door_node.door_color = DOOR_COLOR
		door_node.trim_color = DOOR_TRIM_COLOR
		door_node.outline_color = outline_color
		door_node.set_current_room(current_room)

	for elevator_node in _elevator_nodes:
		elevator_node.outline_color = outline_color
		elevator_node.set_current_room(current_room)

	for clue_marker in _clue_markers:
		clue_marker.clue_color = clue_color
		clue_marker.clue_inspected_color = clue_inspected_color
		clue_marker.outline_color = outline_color
		clue_marker.show_locked_clues = Engine.is_editor_hint() and editor_show_locked_clues
		clue_marker.set_current_room(current_room)

	for npc in _npc_nodes:
		npc.set_current_room(current_room)

	if _player != null:
		_player.speed = player_speed
		_player.body_color = player_color
		_player.hat_color = player_hat_color
		_player.queue_redraw()

	_redraw_world_nodes()


func _queue_world_redraw() -> void:
	if _world_map != null:
		_refresh_world_nodes()
		return
	queue_redraw()


func _redraw_world_nodes() -> void:
	if _world_map != null:
		_world_map.queue_redraw()
	for room_zone in _room_zones:
		room_zone.queue_redraw()
	for door_node in _door_nodes:
		door_node.queue_redraw()
	for elevator_node in _elevator_nodes:
		elevator_node.queue_redraw()
	for clue_marker in _clue_markers:
		clue_marker.queue_redraw()
	for npc in _npc_nodes:
		npc.queue_redraw()
	if _player != null:
		_player.queue_redraw()
	queue_redraw()


func _enter_door(door_idx: int) -> void:
	if door_idx < 0 or door_idx >= _case.doors.size():
		return
	var door := _case.doors[door_idx]
	var door_tile := door.tile
	var target_room := door.target_from(current_room)
	var spawn_tile: Vector2i = door_tile * 2 - player_tile
	_transition_to(target_room, spawn_tile)


func _enter_elevator(elev_idx: int) -> void:
	if elev_idx < 0 or elev_idx >= _case.elevators.size():
		return
	var target: Dictionary = _case.elevators[elev_idx].target_from(current_room)
	var target_room := target["room"] as StringName
	var spawn_tile := target["spawn"] as Vector2i
	_transition_to(target_room, spawn_tile)


func _transition_to(room_id: StringName, spawn_tile: Vector2i) -> void:
	current_room = room_id
	GameState.set_room(room_id)
	if _player != null:
		_player.reset_to_tile(spawn_tile)
	_sync_player_state()
	_refresh_world_nodes()
	_update_hud()


func _is_clue_available(clue_idx: int) -> bool:
	if _case == null or clue_idx < 0 or clue_idx >= _case.clues.size():
		return false
	return UnlockResolver.is_clue_available(_case.clues[clue_idx])


func _update_interact_prompt() -> void:
	if interact_prompt == null:
		return
	if dialog_open or clue_panel_open or game_phase != Phase.EXPLORE:
		interact_prompt.visible = false
		return

	_refresh_interact_target()
	if _current_target.is_none():
		interact_prompt.visible = false
		return

	interact_prompt.visible = true
	interact_prompt_label.text = _current_target.label
	interact_prompt.position = _current_target.prompt_position


func _refresh_interact_target() -> void:
	if _case == null:
		_current_target = InteractTarget.none()
		return
	_current_target = InteractionDetector.find_target(
		_case,
		current_room,
		player_position,
		player_tile,
		player_face_direction,
	)


func _open_dialogue(suspect_idx: int) -> void:
	if suspect_idx < 0 or suspect_idx >= _case.suspects.size():
		return
	var suspect := _case.suspects[suspect_idx]
	active_npc_index = suspect_idx
	dialog_open = true
	_dialogue.open(suspect.id)
	dialogue_panel.visible = true
	dialogue_title_label.text = "%s  -  %s" % [suspect.display_name, suspect.subtitle]
	_refresh_dialogue_output()
	_set_dialogue_busy(false, "")
	dialogue_input.grab_focus()
	_update_hud()


func _close_dialogue() -> void:
	_dialogue.close()
	dialog_open = false
	dialogue_panel.visible = false
	active_npc_index = -1
	get_viewport().gui_release_focus()
	_update_hud()


func _open_clue_panel(clue_idx: int) -> void:
	if clue_idx < 0 or clue_idx >= _case.clues.size():
		return
	var clue := _case.clues[clue_idx]
	GameState.mark_clue_inspected(clue.id)
	clue_panel_open = true
	clue_title_label.text = clue.label
	clue_body_label.clear()
	clue_body_label.append_text(clue.description)
	clue_panel.visible = true
	_refresh_world_nodes()
	_update_hud()


func _close_clue_panel() -> void:
	clue_panel_open = false
	clue_panel.visible = false
	_update_hud()


func _on_accuse_pressed() -> void:
	_accusation.start()
	accusation_step = 0
	accusation_suspect_idx = -1
	accusation_evidence_idx = -1
	accusation_label.text = _case.question
	accusation_suspect_box.visible = true
	accusation_evidence_box.visible = false
	accusation_explanation_box.visible = false
	accusation_explanation_input.clear()
	accusation_status_label.visible = false
	accusation_submit_button.disabled = true
	accusation_panel.visible = true
	game_phase = Phase.ACCUSE
	GameState.set_phase(GameEnums.Phase.ACCUSE)
	_update_hud()


func _close_accusation() -> void:
	if request_in_flight:
		return
	_accusation.cancel()
	accusation_step = 0
	accusation_suspect_idx = -1
	accusation_evidence_idx = -1
	accusation_panel.visible = false
	game_phase = Phase.EXPLORE
	GameState.set_phase(GameEnums.Phase.EXPLORE)
	_update_hud()


func _on_suspect_chosen(suspect_idx: int) -> void:
	if suspect_idx < 0 or suspect_idx >= _case.suspects.size():
		return
	accusation_suspect_idx = suspect_idx
	_accusation.choose_suspect(_case.suspects[suspect_idx].id)
	accusation_step = 1
	accusation_label.text = "What is your key evidence?"
	accusation_suspect_box.visible = false
	accusation_explanation_box.visible = false
	for i in range(_case.clues.size()):
		accusation_clue_buttons[i].visible = GameState.is_clue_inspected(_case.clues[i].id)
	accusation_evidence_box.visible = true


func _on_evidence_chosen(clue_idx: int) -> void:
	if clue_idx < 0 or clue_idx >= _case.clues.size():
		return
	accusation_evidence_idx = clue_idx
	_accusation.choose_evidence(_case.clues[clue_idx].id)
	accusation_step = 2
	accusation_label.text = "Make the case."
	accusation_evidence_box.visible = false
	accusation_explanation_input.clear()
	accusation_status_label.visible = false
	accusation_submit_button.disabled = true
	accusation_explanation_box.visible = true
	accusation_explanation_input.grab_focus()


func _on_accusation_explanation_changed() -> void:
	if accusation_submit_button == null:
		return
	accusation_submit_button.disabled = request_in_flight or accusation_explanation_input.text.strip_edges().is_empty()


func _on_accusation_submit_pressed() -> void:
	if request_in_flight:
		return
	if accusation_suspect_idx < 0 or accusation_evidence_idx < 0:
		return

	var explanation := accusation_explanation_input.text.strip_edges()
	if explanation.is_empty():
		accusation_status_label.visible = true
		accusation_status_label.text = "Fred needs a theory before he can close the case."
		accusation_submit_button.disabled = true
		return

	if not _accusation.submit(explanation):
		accusation_status_label.visible = true
		accusation_status_label.text = "Fred cannot submit that accusation yet."


func _set_accusation_busy(is_busy: bool, status_text: String) -> void:
	request_in_flight = is_busy
	if accusation_explanation_input != null:
		accusation_explanation_input.editable = not is_busy
	if accusation_submit_button != null:
		accusation_submit_button.disabled = is_busy or accusation_explanation_input.text.strip_edges().is_empty()
	if accusation_status_label != null:
		accusation_status_label.visible = not status_text.is_empty()
		accusation_status_label.text = status_text
	_update_hud()


func _on_accusation_resolved(verdict: AccusationVerdict) -> void:
	accusation_panel.visible = false
	game_phase = Phase.RESULT
	GameState.set_phase(GameEnums.Phase.RESULT)
	_show_result(verdict)


func _show_result(verdict: AccusationVerdict) -> void:
	var suspect := _case.suspect_by_id(verdict.suspect_id)
	var clue := _case.clue_by_id(verdict.clue_id)
	var suspect_name := suspect.display_name if suspect != null else "(unknown)"
	var clue_label_text := clue.label if clue != null else "(unknown)"
	result_label.clear()

	var right_suspect := verdict.suspect_id == _case.correct_suspect_id
	var right_evidence := verdict.clue_id == _case.required_evidence_id
	var verifier_correct := verdict.is_correct
	accusation_correct = verifier_correct and right_suspect and right_evidence

	var headline := verdict.headline.strip_edges()
	var feedback := verdict.feedback.strip_edges()
	if headline.is_empty():
		headline = "Correct" if accusation_correct else "Not proven"
	if feedback.is_empty():
		feedback = "The accusation does not fit the authored case facts."
	if verifier_correct and not accusation_correct:
		headline = "Not proven"
		feedback = "The accusation does not fit the authored case facts."

	if accusation_correct:
		result_label.append_text(
			"%s.\n\n%s\n\nCase closed." % [headline, feedback]
		)
	elif right_suspect and not right_evidence:
		result_label.append_text(
			"%s.\n\n%s\n\nYou named the right person, but the %s does not carry the whole case. The ghost cell in the chute connects the stolen idol, the residue pattern, and the murder weapon." % [headline, feedback, clue_label_text]
		)
	else:
		var murderer_name: String = ""
		for s in _case.suspects:
			if s.is_murderer:
				murderer_name = s.display_name
		result_label.append_text(
			"%s.\n\n%s\n\n%s is not proved by that evidence. The case points to %s: the ghost cell hid the idol and matched the discharge that killed Vance." % [headline, feedback, suspect_name, murderer_name]
		)
	result_panel.visible = true
	_update_hud()


func _can_accuse() -> bool:
	return _accusation != null and _accusation.can_accuse()


func _refresh_dialogue_output() -> void:
	if active_npc_index < 0 or _dialogue == null or active_npc_index >= _case.suspects.size():
		return
	dialogue_output.clear()
	var lines := _dialogue.get_dialogue_lines(_case.suspects[active_npc_index].id)
	if lines.size() > 0:
		dialogue_output.append_text("\n\n".join(lines))
		dialogue_output.scroll_to_line(max(0, dialogue_output.get_line_count() - 1))


func _set_dialogue_busy(is_busy: bool, status_text: String) -> void:
	request_in_flight = is_busy
	dialogue_input.editable = not is_busy
	send_button.disabled = is_busy
	dialogue_status_label.visible = not status_text.is_empty()
	dialogue_status_label.text = status_text
	if not is_busy and dialog_open:
		dialogue_input.grab_focus()
	if status_label != null:
		_update_hud()


func _on_dialogue_submitted(_text: String) -> void:
	_send_dialogue_request()


func _send_dialogue_request() -> void:
	if request_in_flight or active_npc_index < 0:
		return

	if not _dialogue.submit_message(dialogue_input.text):
		return
	dialogue_input.clear()


func _on_clue_inspected(_clue_id: StringName) -> void:
	_update_hud()
	_refresh_world_nodes()


func _on_suspect_talked(_suspect_id: StringName) -> void:
	_update_hud()


func _on_dialogue_line_appended(suspect_id: StringName, _speaker: String, _text: String) -> void:
	if active_npc_index < 0 or active_npc_index >= _case.suspects.size():
		return
	if _case.suspects[active_npc_index].id != suspect_id:
		return
	_refresh_dialogue_output()
	if not request_in_flight:
		dialogue_input.grab_focus()


func _reset_game() -> void:
	GameState.reset(_case)
	_dialogue.reset()
	_accusation.reset()
	current_room = _case.start_room
	if _player != null:
		_player.reset_to_tile(_case.player_start_tile)
	_sync_player_state()
	_refresh_world_nodes()
	game_phase = Phase.EXPLORE
	active_npc_index = -1
	accusation_step = 0
	accusation_suspect_idx = -1
	accusation_evidence_idx = -1
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
	if accusation_explanation_input != null:
		accusation_explanation_input.clear()
		accusation_explanation_input.editable = true
	if accusation_explanation_box != null:
		accusation_explanation_box.visible = false
	if accusation_status_label != null:
		accusation_status_label.visible = false

	_update_hud()
	_queue_world_redraw()


func _update_hud() -> void:
	var found_count := GameState.inspected_clue_count()
	status_label.text = "Clues inspected: %d / %d" % [found_count, _case.clues.size()]
	accuse_button.disabled = request_in_flight or not _can_accuse()

	if game_phase == Phase.RESULT:
		hint_label.text = "Case closed."
	elif request_in_flight:
		hint_label.text = "Waiting for an answer."
	elif game_phase == Phase.ACCUSE:
		hint_label.text = "Name a suspect, cite evidence, and explain the theory."
	elif dialog_open:
		hint_label.text = "Press Esc to end the conversation."
	elif clue_panel_open:
		hint_label.text = "Press Esc to close."
	elif _is_clue_available(_case.clue_index(CaseLoader.CLUE_GHOST_CELL)) and not GameState.is_clue_inspected(CaseLoader.CLUE_GHOST_CELL):
		hint_label.text = "The chute lead is open. Check the floor 11 chute access."
	elif _is_clue_available(_case.clue_index(CaseLoader.CLUE_GLOVES)) and not GameState.is_clue_inspected(CaseLoader.CLUE_GLOVES):
		hint_label.text = "The ghost cell points back to the gear. Inspect Pemberton's gloves."
	elif _can_accuse():
		hint_label.text = "You have enough to accuse — or keep digging."
	else:
		hint_label.text = "Inspect clues [E] and question suspects [E]. Find evidence to accuse."


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


func _try_start_tile_step(direction: Vector2i) -> void:
	if _player == null:
		return
	_player.speed = player_speed
	_player.try_step(direction, _world_map, _npc_tiles())
	_sync_player_state()


func _is_tile_walkable(tile_position: Vector2i) -> bool:
	if _world_map == null:
		return TileMap2D.is_walkable(tile_position)
	return _world_map.is_walkable(tile_position)


func _is_npc_at_tile(tile: Vector2i) -> bool:
	return _npc_tiles().has(tile)


func _npc_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for suspect in _case.suspects:
		if suspect.room == current_room:
			tiles.append(TileMap2D.world_to_tile(suspect.position))
	return tiles


func _tile_to_world_center(tile_position: Vector2i) -> Vector2:
	return TileMap2D.tile_to_world_center(tile_position)


func _world_to_tile(world_position: Vector2) -> Vector2i:
	return TileMap2D.world_to_tile(world_position)


func _tile_at(tile_position: Vector2i) -> String:
	return TileMap2D.tile_at(tile_position)


func _sync_player_state() -> void:
	if _player == null:
		return
	player_position = _player.position
	player_tile = _player.tile
	player_target_position = _player.target_position
	player_is_stepping = _player.is_stepping
	player_face_direction = _player.face_direction
