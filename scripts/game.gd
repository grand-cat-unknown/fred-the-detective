extends Node2D

@onready var _world: WorldView = %WorldView
@onready var _inspect_panel: InspectPanel = %InspectPanel


func _ready() -> void:
	var case := CaseLoader.load_default()
	_world.configure(case)
	_world.reset_player(case.player_start_tile)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _inspect_panel.is_open():
		_inspect_panel.hide_panel()
		get_viewport().set_input_as_handled()
		return
	var inspectable := _world.find_inspectable_at_player()
	if inspectable != null:
		_inspect_panel.show_inspectable(inspectable)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _inspect_panel.is_open():
		return
	_world.update_player_movement(delta, _get_pressed_tile_direction())


func _get_pressed_tile_direction() -> Vector2i:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		return Vector2i.ZERO
	if absf(input.x) > absf(input.y):
		return Vector2i(1 if input.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if input.y > 0.0 else -1)
