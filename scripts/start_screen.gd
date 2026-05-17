extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const SHIMMER_PIXEL_COUNT := 48
const SHIMMER_COLORS := [
	Color(0.98, 0.91, 0.69, 1.0),
	Color(0.75, 0.64, 0.38, 1.0),
	Color(0.95, 0.86, 0.72, 1.0),
]

@export var frames: Array[Texture2D] = []
@export_range(0.05, 2.0, 0.05, "or_greater") var frame_seconds := 0.45

@onready var _image: TextureRect = %StartImage
@onready var _how_to_play: Control = %HowToPlay
@onready var _shimmer_pixels: Control = %ShimmerPixels
@onready var _timer: Timer = $FrameTimer

var _frame_index := 0
var _showing_how_to_play := false
var _starting := false
var _shimmer_time := 0.0
var _shimmer_dots: Array[ColorRect] = []


func _ready() -> void:
	_create_shimmer_pixels()
	set_process(false)
	if frames.is_empty():
		return
	_image.texture = frames[_frame_index]
	_timer.wait_time = frame_seconds
	_timer.timeout.connect(_advance_frame)
	_timer.start()


func _unhandled_input(event: InputEvent) -> void:
	if _starting:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		if _showing_how_to_play:
			_start_game()
		else:
			_show_how_to_play()


func _advance_frame() -> void:
	if frames.size() < 2:
		return
	_frame_index = (_frame_index + 1) % frames.size()
	_image.texture = frames[_frame_index]


func _process(delta: float) -> void:
	_shimmer_time += delta
	for dot in _shimmer_dots:
		var base_position: Vector2 = dot.get_meta("base_position", Vector2.ZERO)
		var phase: float = dot.get_meta("phase", 0.0)
		var speed: float = dot.get_meta("speed", 1.0)
		var drift: float = dot.get_meta("drift", 1.0)
		var brightness: float = dot.get_meta("brightness", 0.35)
		var pulse := sin((_shimmer_time * speed) + phase) * 0.5 + 0.5
		var alpha := 0.08 + (pulse * brightness)
		dot.position = base_position + Vector2(
			sin((_shimmer_time * speed * 0.7) + phase) * drift,
			cos((_shimmer_time * speed * 0.45) + phase) * drift
		)
		dot.modulate.a = alpha


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _shimmer_pixels != null:
		_create_shimmer_pixels()


func _create_shimmer_pixels() -> void:
	if _shimmer_pixels == null:
		return
	for child in _shimmer_pixels.get_children():
		child.queue_free()
	_shimmer_dots.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = 1289
	var size := get_viewport_rect().size
	for index in SHIMMER_PIXEL_COUNT:
		var dot := ColorRect.new()
		var pixel_size := rng.randi_range(2, 4)
		dot.size = Vector2(pixel_size, pixel_size)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.color = SHIMMER_COLORS[index % SHIMMER_COLORS.size()]
		dot.modulate.a = rng.randf_range(0.08, 0.28)
		dot.position = Vector2(
			rng.randf_range(24.0, maxf(24.0, size.x - 24.0)),
			rng.randf_range(24.0, maxf(24.0, size.y - 24.0))
		)
		dot.set_meta("base_position", dot.position)
		dot.set_meta("phase", rng.randf_range(0.0, TAU))
		dot.set_meta("speed", rng.randf_range(0.7, 1.9))
		dot.set_meta("drift", rng.randf_range(0.4, 1.4))
		dot.set_meta("brightness", rng.randf_range(0.08, 0.22))
		_shimmer_pixels.add_child(dot)
		_shimmer_dots.append(dot)


func _show_how_to_play() -> void:
	_showing_how_to_play = true
	get_viewport().set_input_as_handled()
	_how_to_play.visible = true
	_image.visible = false
	_timer.stop()
	set_process(true)


func _start_game() -> void:
	_starting = true
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file(GAME_SCENE)
