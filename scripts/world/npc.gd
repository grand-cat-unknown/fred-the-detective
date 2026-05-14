@tool
class_name NPC
extends Node2D

@export var entity_id: StringName

var suspect: SuspectData


func configure(new_suspect: SuspectData) -> void:
	suspect = new_suspect
	if suspect != null:
		entity_id = suspect.id
		name = "NPC_%s" % suspect.id
	queue_redraw()


func set_current_room(room_id: StringName) -> void:
	visible = suspect != null and suspect.room == room_id


func _draw() -> void:
	if suspect == null:
		return
	ActorDraw.draw_actor(self, Vector2.ZERO, suspect.color, suspect.hat_color)
