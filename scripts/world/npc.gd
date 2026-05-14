@tool
class_name NPC
extends Node2D

@export var entity_id: StringName

var suspect: SuspectData


func _ready() -> void:
	set_notify_transform(true)


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
	queue_redraw()


func _draw() -> void:
	if suspect == null:
		return
	ActorDraw.draw_actor(self, Vector2.ZERO, suspect.color, suspect.hat_color, Vector2i(1, 0), suspect.texture)
