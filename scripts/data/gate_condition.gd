class_name GateCondition
extends Resource

@export var all_of: Array[StringName] = []
@export var any_of: Array[StringName] = []
@export var none_of: Array[StringName] = []


func is_met(state: CaseState) -> bool:
	if state == null:
		return all_of.is_empty() and any_of.is_empty()

	for fact_id in all_of:
		if not state.get_fact(fact_id):
			return false

	if not any_of.is_empty():
		var matched_any := false
		for fact_id in any_of:
			if state.get_fact(fact_id):
				matched_any = true
				break
		if not matched_any:
			return false

	for fact_id in none_of:
		if state.get_fact(fact_id):
			return false

	return true
