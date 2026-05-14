class_name ActorDraw
extends RefCounted


static func draw_actor(
	canvas: CanvasItem,
	pos: Vector2,
	body_color: Color,
	hat_color: Color,
	face_dir: Vector2i = Vector2i(1, 0),
	texture: Texture2D = null,
	is_walking: bool = false,
	walk_phase: float = 0.0,
) -> void:
	canvas.draw_rect(Rect2(pos + Layout.ACTOR_SHADOW_OFFSET, Layout.ACTOR_SHADOW_SIZE), Palette.ACTOR_SHADOW, true)
	if texture != null:
		_draw_sprite(canvas, pos, texture, face_dir, is_walking, walk_phase)
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
const SHEET_FRAME_SIZE := Vector2(32.0, 32.0)
const SHEET_COLUMNS := 3
const SHEET_ROWS := 4
const IDLE_FRAME := 1


static func _draw_sprite(
	canvas: CanvasItem,
	pos: Vector2,
	texture: Texture2D,
	face_dir: Vector2i,
	is_walking: bool,
	walk_phase: float,
) -> void:
	var size := texture.get_size()
	if _is_character_sheet(size):
		_draw_character_sheet_frame(canvas, pos, texture, face_dir, is_walking, walk_phase)
		return

	var feet := pos + SPRITE_FEET_OFFSET
	var top_left := Vector2(-size.x * 0.5, -size.y)
	if face_dir.x < 0:
		canvas.draw_set_transform(feet, 0.0, Vector2(-1.0, 1.0))
		canvas.draw_texture_rect(texture, Rect2(top_left, size), false)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		canvas.draw_texture_rect(texture, Rect2(feet + top_left, size), false)


static func _is_character_sheet(size: Vector2) -> bool:
	return int(size.x) == int(SHEET_FRAME_SIZE.x) * SHEET_COLUMNS and int(size.y) == int(SHEET_FRAME_SIZE.y) * SHEET_ROWS


static func _draw_character_sheet_frame(
	canvas: CanvasItem,
	pos: Vector2,
	texture: Texture2D,
	face_dir: Vector2i,
	is_walking: bool,
	walk_phase: float,
) -> void:
	var frame := IDLE_FRAME
	if is_walking:
		frame = _walk_frame(walk_phase)

	var row := _direction_row(face_dir)
	var source := Rect2(Vector2(frame * SHEET_FRAME_SIZE.x, row * SHEET_FRAME_SIZE.y), SHEET_FRAME_SIZE)
	var feet := pos + SPRITE_FEET_OFFSET
	var dest := Rect2(feet + Vector2(-SHEET_FRAME_SIZE.x * 0.5, -SHEET_FRAME_SIZE.y), SHEET_FRAME_SIZE)
	canvas.draw_texture_rect_region(texture, dest, source)


static func _walk_frame(walk_phase: float) -> int:
	var phase := clampf(walk_phase, 0.0, 1.0)
	if phase < 0.25:
		return 0
	if phase < 0.5:
		return 1
	if phase < 0.75:
		return 2
	return 1


static func _direction_row(face_dir: Vector2i) -> int:
	if face_dir.y > 0:
		return 0
	if face_dir.x < 0:
		return 1
	if face_dir.x > 0:
		return 2
	if face_dir.y < 0:
		return 3
	return 0
