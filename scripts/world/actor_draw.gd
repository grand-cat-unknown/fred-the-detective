class_name ActorDraw
extends RefCounted


static func draw_actor(
	canvas: CanvasItem,
	pos: Vector2,
	body_color: Color,
	hat_color: Color,
	face_dir: Vector2i = Vector2i(1, 0),
	texture: Texture2D = null,
) -> void:
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_SHADOW_OFFSET, Layout.ACTOR_SHADOW_SIZE), Palette.ACTOR_SHADOW, true)
	if texture != null:
		_draw_sprite(canvas, pos, texture, face_dir)
		return
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_BODY_OFFSET, Layout.ACTOR_BODY_SIZE), body_color, true)
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_BODY_OFFSET, Layout.ACTOR_BODY_SIZE), Palette.OUTLINE, false, Layout.OBJECT_OUTLINE_WIDTH)
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_HEAD_OFFSET, Layout.ACTOR_HEAD_SIZE), Palette.ACTOR_HEAD, true)
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_HEAD_OFFSET, Layout.ACTOR_HEAD_SIZE), Palette.OUTLINE, false, Layout.OBJECT_OUTLINE_WIDTH)

	var nose_offset := Vector2(
		face_dir.x * Layout.ACTOR_NOSE_FACE_DISTANCE,
		Layout.ACTOR_NOSE_RUNNING_OFFSET + face_dir.y * Layout.ACTOR_NOSE_FACE_DISTANCE,
	)
	canvas.draw_rect(Rect2(pos + nose_offset - Layout.ACTOR_NOSE_HALF_SIZE, Layout.ACTOR_NOSE_SIZE), Palette.ACTOR_NOSE, true)

	var hat_points := PackedVector2Array()
	for point in Layout.ACTOR_HAT_POINTS:
		hat_points.append(pos + point)

	var hat_outline := PackedVector2Array([
		hat_points[0],
		hat_points[1],
		hat_points[2],
		hat_points[3],
		hat_points[0],
	])
	canvas.draw_colored_polygon(hat_points, hat_color)
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_HAT_BRIM_OFFSET, Layout.ACTOR_HAT_BRIM_SIZE), hat_color, true)
	canvas.draw_polyline(hat_outline, Palette.OUTLINE, Layout.OBJECT_OUTLINE_WIDTH)


const SPRITE_FEET_OFFSET := Vector2(0.0, 8.0)


static func _draw_sprite(canvas: CanvasItem, pos: Vector2, texture: Texture2D, face_dir: Vector2i) -> void:
	var size := texture.get_size()
	var feet := pos + SPRITE_FEET_OFFSET
	var top_left := Vector2(-size.x * 0.5, -size.y)
	if face_dir.x < 0:
		canvas.draw_set_transform(feet, 0.0, Vector2(-1.0, 1.0))
		canvas.draw_texture_rect(texture, Rect2(top_left, size), false)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		canvas.draw_texture_rect(texture, Rect2(feet + top_left, size), false)
