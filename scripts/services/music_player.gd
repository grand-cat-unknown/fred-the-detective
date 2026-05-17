extends Node

const TRACK_PATH := "res://assets/music/Unclaimed_Keys.mp3"
const VOLUME_DB := -8.0
const ICON_SIZE := Vector2(32, 32)
const ICON_MARGIN := Vector2(12, 12)
const ICON_COLOR := Color(1, 1, 1, 0.45)
const ICON_HOVER_COLOR := Color(1, 1, 1, 0.85)
const MUTE_LINE_COLOR := Color(0.95, 0.35, 0.35, 0.85)

var _player: AudioStreamPlayer
var _muted: bool = false
var _icon: Control
var _hovered: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_player = AudioStreamPlayer.new()
	_player.name = "AudioStreamPlayer"
	_player.bus = &"Master"
	_player.volume_db = VOLUME_DB
	add_child(_player)

	var stream := load(TRACK_PATH)
	if stream == null:
		push_warning("[music] could not load %s" % TRACK_PATH)
	else:
		if stream is AudioStreamMP3:
			stream.loop = true
		_player.stream = stream
		_player.play()

	_build_icon()


func _build_icon() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MusicHUD"
	layer.layer = 128
	add_child(layer)

	_icon = Control.new()
	_icon.name = "MuteIcon"
	_icon.anchor_left = 1.0
	_icon.anchor_top = 1.0
	_icon.anchor_right = 1.0
	_icon.anchor_bottom = 1.0
	_icon.offset_left = -ICON_SIZE.x - ICON_MARGIN.x
	_icon.offset_top = -ICON_SIZE.y - ICON_MARGIN.y
	_icon.offset_right = -ICON_MARGIN.x
	_icon.offset_bottom = -ICON_MARGIN.y
	_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_icon.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_icon.tooltip_text = "Mute music (M)"
	_icon.gui_input.connect(_on_icon_gui_input)
	_icon.mouse_entered.connect(_on_icon_mouse_entered)
	_icon.mouse_exited.connect(_on_icon_mouse_exited)
	_icon.draw.connect(_on_icon_draw)
	layer.add_child(_icon)


func _on_icon_mouse_entered() -> void:
	_hovered = true
	_icon.queue_redraw()


func _on_icon_mouse_exited() -> void:
	_hovered = false
	_icon.queue_redraw()


func _on_icon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_icon.accept_event()
		toggle_mute()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_mute()
		get_viewport().set_input_as_handled()


func toggle_mute() -> void:
	_muted = not _muted
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, _muted)
	if _icon:
		_icon.queue_redraw()


func _on_icon_draw() -> void:
	var color := ICON_HOVER_COLOR if _hovered else ICON_COLOR
	var size := _icon.size

	# Speaker body — small rectangle on the left.
	var body_left := size.x * 0.18
	var body_right := size.x * 0.42
	var body_top := size.y * 0.38
	var body_bottom := size.y * 0.62
	_icon.draw_rect(Rect2(Vector2(body_left, body_top), Vector2(body_right - body_left, body_bottom - body_top)), color, true)

	# Speaker cone — triangle flaring to the right.
	var cone_tip_x := body_right
	var cone_far_x := size.x * 0.62
	var cone_top := size.y * 0.20
	var cone_bottom := size.y * 0.80
	var cone := PackedVector2Array([
		Vector2(cone_tip_x, body_top),
		Vector2(cone_far_x, cone_top),
		Vector2(cone_far_x, cone_bottom),
		Vector2(cone_tip_x, body_bottom),
	])
	_icon.draw_colored_polygon(cone, color)

	if _muted:
		# Red strike-through line.
		_icon.draw_line(Vector2(size.x * 0.18, size.y * 0.20), Vector2(size.x * 0.86, size.y * 0.80), MUTE_LINE_COLOR, 2.5, true)
	else:
		# Two sound-wave arcs.
		var wave_center := Vector2(cone_far_x, size.y * 0.5)
		_draw_arc_segment(wave_center, size.x * 0.10, color, 2.0)
		_draw_arc_segment(wave_center, size.x * 0.18, color, 2.0)


func _draw_arc_segment(center: Vector2, radius: float, color: Color, width: float) -> void:
	var start_angle := -PI / 4.0
	var end_angle := PI / 4.0
	_icon.draw_arc(center, radius, start_angle, end_angle, 12, color, width, true)
