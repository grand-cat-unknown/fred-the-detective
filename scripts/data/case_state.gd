class_name CaseState
extends Node

signal fact_changed(fact_id: StringName, value: bool)

var _definitions: Dictionary = {}
var _facts: Dictionary = {}


func configure(fact_definitions: Array[FactDefinition]) -> void:
	_definitions.clear()
	for definition in fact_definitions:
		if definition == null or definition.id == &"":
			continue
		_definitions[definition.id] = definition
	reset()


func reset() -> void:
	_facts.clear()
	for fact_id in _definitions.keys():
		var definition := _definitions[fact_id] as FactDefinition
		_facts[fact_id] = definition.default_value


func get_fact(fact_id: StringName, default_value := false) -> bool:
	if fact_id == &"":
		return default_value
	return bool(_facts.get(fact_id, default_value))


func set_fact(fact_id: StringName, value := true) -> void:
	if fact_id == &"":
		return
	var old_value := get_fact(fact_id, false)
	_facts[fact_id] = value
	if old_value != value:
		fact_changed.emit(fact_id, value)


func apply_effects(effects: Variant) -> Array[StringName]:
	var changed: Array[StringName] = []
	if typeof(effects) != TYPE_ARRAY:
		return changed
	for effect in effects:
		if effect is StateEffect:
			var state_effect := effect as StateEffect
			if not state_effect.is_valid():
				continue
			var old_value := get_fact(state_effect.fact_id, false)
			set_fact(state_effect.fact_id, state_effect.value)
			if old_value != state_effect.value:
				changed.append(state_effect.fact_id)
		elif typeof(effect) == TYPE_DICTIONARY:
			var fact_id := StringName(str(effect.get("fact_id", "")))
			if fact_id == &"":
				continue
			var value := bool(effect.get("value", true))
			var old_value := get_fact(fact_id, false)
			set_fact(fact_id, value)
			if old_value != value:
				changed.append(fact_id)
	return changed


func snapshot() -> Dictionary:
	var result := {}
	for fact_id in _facts.keys():
		result[str(fact_id)] = bool(_facts[fact_id])
	return result


func true_fact_ids() -> Array[String]:
	var result: Array[String] = []
	for fact_id in _facts.keys():
		if bool(_facts[fact_id]):
			result.append(str(fact_id))
	result.sort()
	return result
