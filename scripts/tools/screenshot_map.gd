extends Node

const WORLD_MAP_SCENE := preload("res://scenes/world/world_map.tscn")
const TILE_SIZE := int(TileMap2D.TILE_SIZE)
const PADDING_TILES := 1
const DEFAULT_OUTPUT := "res://map_screenshot.png"


func _ready() -> void:
	var output_path := _resolve_output_path()
	await _capture(output_path)
	get_tree().quit()


func _capture(output_path: String) -> void:
	var map: Node2D = WORLD_MAP_SCENE.instantiate()
	map.background_color = Color(0, 0, 0, 0)

	var used_rect := _used_rect_union(map)
	if used_rect.size == Vector2i.ZERO:
		push_error("screenshot_map: no painted tiles found")
		return

	used_rect = used_rect.grow(PADDING_TILES)
	var pixel_size: Vector2i = used_rect.size * TILE_SIZE
	var pixel_offset := Vector2(-used_rect.position * TILE_SIZE)

	var viewport := SubViewport.new()
	viewport.size = pixel_size
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	add_child(viewport)

	map.position = pixel_offset
	viewport.add_child(map)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	if image == null:
		push_error("screenshot_map: failed to grab viewport image")
		return

	var err := image.save_png(output_path)
	if err != OK:
		push_error("screenshot_map: save_png failed (%d) -> %s" % [err, output_path])
		return

	print("screenshot_map: saved %s  (%d x %d px, tiles %s)" % [
		ProjectSettings.globalize_path(output_path),
		pixel_size.x,
		pixel_size.y,
		used_rect,
	])


func _used_rect_union(map: Node2D) -> Rect2i:
	var result := Rect2i()
	var initialized := false
	for child in map.get_children():
		var layer := child as TileMapLayer
		if layer == null:
			continue
		var layer_rect := layer.get_used_rect()
		if layer_rect.size == Vector2i.ZERO:
			continue
		if not initialized:
			result = layer_rect
			initialized = true
		else:
			result = result.merge(layer_rect)
	return result if initialized else Rect2i()


func _resolve_output_path() -> String:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--output="):
			return arg.substr("--output=".length())
	return DEFAULT_OUTPUT
