@tool
class_name ClueMarker
extends Node2D

@export var entity_id: StringName

var clue: ClueData
var show_locked_clues := false
var clue_color := Palette.CLUE
var clue_inspected_color := Palette.CLUE_INSPECTED
var outline_color := Palette.OUTLINE


func configure(new_clue: ClueData) -> void:
	clue = new_clue
	if clue != null:
		entity_id = clue.id
		name = "Clue_%s" % clue.id
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	if clue == null:
		visible = false
		return
	visible = clue.room == room_id and (show_locked_clues or UnlockResolver.is_clue_available(clue))
	queue_redraw()


func _draw() -> void:
	if clue == null:
		return

	var color := clue_inspected_color if GameState.is_clue_inspected(clue.id) else clue_color
	var diamond := PackedVector2Array([
		Vector2(0.0, -Layout.CLUE_RADIUS),
		Vector2(Layout.CLUE_RADIUS, 0.0),
		Vector2(0.0, Layout.CLUE_RADIUS),
		Vector2(-Layout.CLUE_RADIUS, 0.0),
	])
	var diamond_outline := PackedVector2Array([
		diamond[0],
		diamond[1],
		diamond[2],
		diamond[3],
		diamond[0],
	])
	draw_colored_polygon(diamond, color)
	draw_polyline(diamond_outline, outline_color, Layout.CLUE_OUTLINE_WIDTH)
