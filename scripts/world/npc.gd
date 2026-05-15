@tool
class_name NPC
extends Node2D

@export var entity_id: StringName:
	set(value):
		entity_id = value
		_refresh_editor_preview()

@export_group("Editor Preview")
@export var preview_name := ""
@export var preview_texture: Texture2D

var suspect: SuspectData
var face_direction := Vector2i(1, 0)


func get_tile() -> Vector2i:
	return TileMap2D.world_to_tile(position)


func look_at_position(target_world_pos: Vector2) -> void:
	var delta := target_world_pos - position
	if delta.is_zero_approx():
		return
	var new_direction: Vector2i
	if absf(delta.x) >= absf(delta.y):
		new_direction = Vector2i(1 if delta.x > 0.0 else -1, 0)
	else:
		new_direction = Vector2i(0, 1 if delta.y > 0.0 else -1)
	if new_direction == face_direction:
		return
	face_direction = new_direction
	queue_redraw()


func get_display_name() -> String:
	if suspect != null and suspect.display_name != "":
		return suspect.display_name
	if preview_name != "":
		return preview_name
	return "Stranger"


func _ready() -> void:
	ActorDraw.configure_canvas(self)
	set_notify_transform(true)
	_refresh_editor_preview()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		var snapped_pos := TileMap2D.tile_to_world_center(TileMap2D.world_to_tile(position))
		if position != snapped_pos:
			position = snapped_pos


func configure(new_suspect: SuspectData) -> void:
	suspect = new_suspect
	if suspect != null:
		entity_id = suspect.id
		name = "NPC_%s" % suspect.id
		preview_name = suspect.display_name
		preview_texture = suspect.texture
	queue_redraw()


func _draw() -> void:
	if suspect == null:
		if Engine.is_editor_hint():
			ActorDraw.draw_actor(self, Vector2.ZERO, Color8(105, 105, 110), Color8(62, 62, 68))
		return
	ActorDraw.draw_actor(self, Vector2.ZERO, suspect.color, suspect.hat_color, face_direction, suspect.texture)


func _get_configuration_warnings() -> PackedStringArray:
	if entity_id == &"":
		return ["Set entity_id to one of the case suspect ids so this NPC can preview and run correctly."]
	if _find_default_suspect(entity_id) == null:
		return ["No default suspect found for entity_id \"%s\"." % entity_id]
	return []


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return

	var preview_suspect := _find_default_suspect(entity_id)
	if preview_suspect == null:
		suspect = null
		preview_name = ""
		preview_texture = null
	else:
		suspect = preview_suspect
		preview_name = suspect.display_name
		preview_texture = suspect.texture
		if name == "NPC" or name.begins_with("NPC_"):
			name = "NPC_%s" % suspect.id

	queue_redraw()
	update_configuration_warnings()


func _find_default_suspect(id: StringName) -> SuspectData:
	if id == &"":
		return null
	var default_case := CaseLoader.load_default()
	for default_suspect in default_case.suspects:
		if default_suspect.id == id:
			return default_suspect
	return null
