@tool
class_name Elevator
extends Node2D

@export var room_a: StringName
@export var room_b: StringName

var elevator_data: ElevatorData


func configure(new_elevator: ElevatorData) -> void:
	elevator_data = new_elevator
	if elevator_data != null:
		room_a = elevator_data.room_a
		room_b = elevator_data.room_b
		name = "Elevator_%s_%s" % [elevator_data.room_a, elevator_data.room_b]
