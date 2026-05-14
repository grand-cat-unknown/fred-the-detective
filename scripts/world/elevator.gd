@tool
class_name Elevator
extends Node2D

@export var room_a: StringName
@export var room_b: StringName

var elevator_data: ElevatorData
var outline_color := Palette.OUTLINE


func configure(new_elevator: ElevatorData) -> void:
	elevator_data = new_elevator
	if elevator_data != null:
		room_a = elevator_data.room_a
		room_b = elevator_data.room_b
		name = "Elevator_%s_%s" % [elevator_data.room_a, elevator_data.room_b]
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	visible = elevator_data != null and elevator_data.connects(room_id)
	if visible:
		position = Vector2(elevator_data.tile_for(room_id)) * TileMap2D.TILE_SIZE
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(TileMap2D.TILE_SIZE, TileMap2D.TILE_SIZE))
	draw_rect(rect.grow(-Layout.ELEVATOR_FRAME_INSET), Palette.ELEVATOR_FRAME, true)
	draw_rect(rect.grow(-Layout.ELEVATOR_PANEL_INSET), Palette.ELEVATOR_PANEL, true)
	var seam_x := rect.position.x + rect.size.x * 0.5
	draw_line(
		Vector2(seam_x, rect.position.y + Layout.ELEVATOR_SEAM_INSET),
		Vector2(seam_x, rect.position.y + rect.size.y - Layout.ELEVATOR_SEAM_INSET),
		Palette.ELEVATOR_SEAM,
		Layout.OBJECT_OUTLINE_WIDTH,
	)
	draw_rect(rect.grow(-Layout.ELEVATOR_FRAME_INSET), outline_color, false, Layout.OBJECT_OUTLINE_WIDTH)

	var arrow := PackedVector2Array()
	for point in Layout.ELEVATOR_ARROW_NORMALIZED:
		arrow.append(rect.position + Vector2(rect.size.x * point.x, rect.size.y * point.y))
	draw_colored_polygon(arrow, outline_color)
