extends Node2D

@onready var _world: WorldView = %WorldView


func _ready() -> void:
	var case := CaseLoader.load_default()
	_world.configure(case)
	_world.reset_player(case.player_start_tile)


func _process(delta: float) -> void:
	if _world.is_player_stepping():
		_world.process_player_step(delta)
		return

	var direction := _get_pressed_tile_direction()
	if direction != Vector2i.ZERO:
		_world.try_start_tile_step(direction)


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
