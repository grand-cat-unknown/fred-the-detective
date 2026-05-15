class_name StateEffect
extends Resource

@export var fact_id: StringName
@export var value := true


func is_valid() -> bool:
	return fact_id != &""
