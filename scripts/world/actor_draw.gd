class_name ActorDraw
extends RefCounted


static func draw_actor(
	canvas: CanvasItem,
	pos: Vector2,
	body_color: Color,
	hat_color: Color,
	face_dir: Vector2i = Vector2i(1, 0),
) -> void:
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_SHADOW_OFFSET, Layout.ACTOR_SHADOW_SIZE), Palette.ACTOR_SHADOW, true)
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
