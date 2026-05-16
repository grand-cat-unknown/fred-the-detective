extends Control

const GAME_SCENE := "res://scenes/main.tscn"

@export var frames: Array[Texture2D] = []
@export_range(0.05, 2.0, 0.05, "or_greater") var frame_seconds := 0.45

@onready var _image: TextureRect = %StartImage
@onready var _timer: Timer = $FrameTimer

var _frame_index := 0
var _starting := false


func _ready() -> void:
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
		_start_game()


func _advance_frame() -> void:
	if frames.size() < 2:
		return
	_frame_index = (_frame_index + 1) % frames.size()
	_image.texture = frames[_frame_index]


func _start_game() -> void:
	_starting = true
	get_viewport().set_input_as_handled()
	get_tree().change_scene_to_file(GAME_SCENE)
