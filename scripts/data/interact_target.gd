class_name InteractTarget
extends RefCounted

var kind: GameEnums.InteractKind = GameEnums.InteractKind.NONE
var index: int = -1
var label: String = ""
var prompt_position: Vector2 = Vector2.ZERO


func _init(
	p_kind: GameEnums.InteractKind = GameEnums.InteractKind.NONE,
	p_index: int = -1,
	p_label: String = "",
	p_prompt_position: Vector2 = Vector2.ZERO,
) -> void:
	kind = p_kind
	index = p_index
	label = p_label
	prompt_position = p_prompt_position


static func none() -> InteractTarget:
	return InteractTarget.new()


func is_none() -> bool:
	return kind == GameEnums.InteractKind.NONE
