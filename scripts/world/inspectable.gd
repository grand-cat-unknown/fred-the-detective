@tool
class_name Inspectable
extends Node2D

@export var object_id: StringName
@export var title: String = "Object"
@export_multiline var description: String = "An ordinary thing. Nothing of note."
@export var texture: Texture2D:
	set(value):
		texture = value
		_apply_texture()
@export var body_color: Color = Color8(140, 100, 60)
@export var draw_marker: bool = true:
	set(value):
		draw_marker = value
		queue_redraw()
@export var blocks_movement: bool = true

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	set_notify_transform(true)
	_apply_texture()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		var snapped_pos := TileMap2D.tile_to_world_center(TileMap2D.world_to_tile(position))
		if position != snapped_pos:
			position = snapped_pos


func get_tile() -> Vector2i:
	return TileMap2D.world_to_tile(position)


func _draw() -> void:
	if not draw_marker and texture == null:
		return

	var half := Vector2(10.0, 10.0)
	var rect := Rect2(-half, half * 2.0)
	draw_rect(Rect2(-half + Vector2(-1.0, 7.0), Vector2(22.0, 5.0)), Palette.ACTOR_SHADOW, true)
	if texture != null:
		return
	draw_rect(rect, body_color, true)
	draw_rect(rect, Palette.OUTLINE, false, Layout.OBJECT_OUTLINE_WIDTH)
	# Question mark dot to hint it's interactable
	draw_rect(Rect2(Vector2(-1.5, -3.5), Vector2(3.0, 3.0)), Palette.OUTLINE, true)
	draw_rect(Rect2(Vector2(-1.5, 2.5), Vector2(3.0, 2.0)), Palette.OUTLINE, true)


func _apply_texture() -> void:
	if is_node_ready():
		_sprite.texture = texture
	queue_redraw()
