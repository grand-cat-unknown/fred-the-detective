@tool
class_name RoomZone
extends Node2D

var room: RoomData
var border_color := Palette.ROOM_BORDER
var label_color := Palette.ROOM_LABEL
var label_font_size := Layout.ROOM_LABEL_FONT_SIZE
var _label: Label


func configure(new_room: RoomData) -> void:
	room = new_room
	if room != null:
		name = "RoomZone_%s" % room.id
	_ensure_label()
	_apply_label()
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	visible = room != null and room.id == room_id
	_apply_label()
	queue_redraw()


func _ready() -> void:
	_ensure_label()
	_apply_label()


func _draw() -> void:
	if room == null:
		return
	draw_rect(room.rect, room.color, true)
	draw_rect(room.rect, border_color, false, Layout.ROOM_BORDER_WIDTH)


func _ensure_label() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _apply_label() -> void:
	if _label == null or room == null:
		return
	_label.text = room.label
	_label.position = room.label_position
	_label.custom_minimum_size = Layout.ROOM_LABEL_MIN_SIZE
	_label.add_theme_color_override("font_color", label_color)
	_label.add_theme_font_size_override("font_size", label_font_size)
	_label.visible = visible
