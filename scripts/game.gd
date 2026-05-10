extends Node2D

const VIEW_SIZE := Vector2(960.0, 540.0)
const ROOM_RECT := Rect2(Vector2(92.0, 92.0), Vector2(776.0, 356.0))
const EXIT_RECT := Rect2(Vector2(768.0, 214.0), Vector2(84.0, 96.0))
const PLAYER_START := Vector2(160.0, 274.0)
const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 18.0
const CLUE_RADIUS := 12.0
const CLUE_POSITIONS := [
	Vector2(176.0, 156.0),
	Vector2(476.0, 170.0),
	Vector2(340.0, 368.0),
]

const BACKGROUND_COLOR := Color8(236, 229, 214)
const ROOM_COLOR := Color8(213, 205, 187)
const OUTLINE_COLOR := Color8(53, 45, 36)
const PLAYER_COLOR := Color8(43, 77, 117)
const HAT_COLOR := Color8(32, 43, 56)
const CLUE_COLOR := Color8(214, 164, 75)
const CLUE_FOUND_COLOR := Color8(132, 180, 132)
const EXIT_LOCKED_COLOR := Color8(126, 94, 75)
const EXIT_OPEN_COLOR := Color8(103, 175, 126)
const FURNITURE_COLOR := Color8(147, 109, 83)

var player_position := PLAYER_START
var clue_found: Array[bool] = [false, false, false]
var game_won := false

var status_label: Label
var hint_label: Label


func _ready() -> void:
	_build_hud()
	_reset_game()


func _process(delta: float) -> void:
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
	if game_won and event.is_action_pressed("ui_accept"):
		_reset_game()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), BACKGROUND_COLOR, true)
	draw_rect(ROOM_RECT, ROOM_COLOR, true)
	draw_rect(ROOM_RECT, OUTLINE_COLOR, false, 4.0)

	_draw_furniture()
	_draw_exit()
	_draw_clues()
	_draw_player()


func _build_hud() -> void:
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(20.0, 20.0)
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	canvas_layer.add_child(panel)

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
	_update_hud()
	queue_redraw()


func _update_hud() -> void:
	var found_total := 0
	for found in clue_found:
		if found:
			found_total += 1

	status_label.text = "Clues found: %d / %d" % [found_total, clue_found.size()]

	if game_won:
		hint_label.text = "Case closed. Press Enter or Space to restart."
	elif _all_clues_found():
		hint_label.text = "All clues found. Head to the green exit."
	else:
		hint_label.text = "Use arrow keys or WASD to collect the clues."


func _all_clues_found() -> bool:
	for found in clue_found:
		if not found:
			return false
	return true


func _clamp_to_room(target_position: Vector2) -> Vector2:
	return Vector2(
		clampf(target_position.x, ROOM_RECT.position.x + PLAYER_RADIUS, ROOM_RECT.end.x - PLAYER_RADIUS),
		clampf(target_position.y, ROOM_RECT.position.y + PLAYER_RADIUS, ROOM_RECT.end.y - PLAYER_RADIUS)
	)