class_name CaseData
extends Resource

@export var player_start_tile: Vector2i = Vector2i.ZERO
@export var fact_definitions: Array[FactDefinition] = []
@export var interactables: Array[InteractableDefinition] = []
@export var suspects: Array[SuspectData] = []


func get_interactable(object_id: StringName) -> InteractableDefinition:
	if object_id == &"":
		return null
	for interactable in interactables:
		if interactable != null and interactable.object_id == object_id:
			return interactable
	return null
