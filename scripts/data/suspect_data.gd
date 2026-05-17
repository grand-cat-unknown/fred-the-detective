class_name SuspectData
extends Resource

@export var id: StringName
@export var display_name: String
@export var position: Vector2
@export var color: Color
@export var hat_color: Color
@export var texture: Texture2D

@export_group("Character")
@export var subtitle: String = ""
@export_multiline var persona: String = ""
@export_multiline var sheet_summary: String = ""
@export_multiline var sheet_details: Array[String] = []
@export_multiline var sheet_hooks: Array[String] = []

@export_group("Dialogue")
@export_multiline var dialogue: String = "They glance up but say nothing of note."
@export_multiline var system_prompt: String = ""
@export var prompt_blocks: Array = []
@export var reaction_blocks: Array = []
@export var topic_responses: Array = []
@export var allowed_effects: Array = []


func _init(
	p_id: StringName = &"",
	p_display_name: String = "",
	p_position: Vector2 = Vector2.ZERO,
	p_color: Color = Color.WHITE,
	p_hat_color: Color = Color.BLACK,
	p_texture: Texture2D = null,
) -> void:
	id = p_id
	display_name = p_display_name
	position = p_position
	color = p_color
	hat_color = p_hat_color
	texture = p_texture


func available_prompt_blocks(state: CaseState) -> Array[PromptBlock]:
	var blocks: Array[PromptBlock] = []
	for block in prompt_blocks:
		if block is PromptBlock and block.is_available(state):
			blocks.append(block as PromptBlock)
	return blocks


func available_reaction_blocks(state: CaseState) -> Array[PromptBlock]:
	var blocks: Array[PromptBlock] = []
	for block in reaction_blocks:
		if block is PromptBlock and block.is_available(state):
			blocks.append(block as PromptBlock)
	return blocks


func has_topic_responses() -> bool:
	for response in topic_responses:
		if response is SuspectTopicResponse and (response as SuspectTopicResponse).is_valid():
			return true
	return false


func topic_classifier_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for response in topic_responses:
		if response is SuspectTopicResponse:
			var topic_response := response as SuspectTopicResponse
			if topic_response.is_valid():
				options.append(topic_response.classifier_dictionary())
	return options


func active_topic_response_states(state: CaseState, topic_id: StringName) -> Array[SuspectTopicResponseState]:
	var responses: Array[SuspectTopicResponseState] = []
	if topic_id == &"":
		return responses
	for response in topic_responses:
		if not response is SuspectTopicResponse:
			continue
		var topic_response := response as SuspectTopicResponse
		if topic_response.topic_id != topic_id:
			continue
		var active_state := topic_response.active_state(state)
		if active_state != null:
			responses.append(active_state)
	return responses


func active_topic_response_instructions(state: CaseState, topic_id: StringName) -> Array[String]:
	var instructions: Array[String] = []
	if topic_id == &"":
		return instructions
	for response in topic_responses:
		if not response is SuspectTopicResponse:
			continue
		var topic_response := response as SuspectTopicResponse
		if topic_response.topic_id != topic_id:
			continue
		var instruction := topic_response.active_instruction(state).strip_edges()
		if instruction != "":
			instructions.append(instruction)
	return instructions


func topic_managed_effect_ids() -> Array[StringName]:
	var effect_ids: Array[StringName] = []
	for response in topic_responses:
		if not response is SuspectTopicResponse:
			continue
		var topic_response := response as SuspectTopicResponse
		for entry in topic_response.states:
			if not entry is SuspectTopicResponseState:
				continue
			var topic_state := entry as SuspectTopicResponseState
			if topic_state.effect_allowed != &"" and not effect_ids.has(topic_state.effect_allowed):
				effect_ids.append(topic_state.effect_allowed)
	return effect_ids


func available_conversation_effects(state: CaseState) -> Array[ConversationEffect]:
	var effects: Array[ConversationEffect] = []
	for effect in allowed_effects:
		if effect is ConversationEffect and effect.is_available(state):
			effects.append(effect as ConversationEffect)
	return effects


func available_conversation_effects_for_topic(state: CaseState, topic_id: StringName) -> Array[ConversationEffect]:
	var available_effects := available_conversation_effects(state)
	var topic_effect_ids := topic_managed_effect_ids()
	var allowed_by_topic: Array[StringName] = []
	for topic_state in active_topic_response_states(state, topic_id):
		if topic_state.effect_allowed != &"" and not allowed_by_topic.has(topic_state.effect_allowed):
			allowed_by_topic.append(topic_state.effect_allowed)
	if topic_effect_ids.is_empty():
		return available_effects

	var filtered: Array[ConversationEffect] = []
	for effect in available_effects:
		if not topic_effect_ids.has(effect.fact_id) or allowed_by_topic.has(effect.fact_id):
			filtered.append(effect)
	return filtered


func character_sheet_text() -> String:
	var lines: Array[String] = []
	if sheet_summary.strip_edges() != "":
		lines.append(sheet_summary.strip_edges())
	_append_sheet_section(lines, "Noted", sheet_details)
	_append_sheet_section(lines, "Ask About", sheet_hooks)
	return "\n".join(lines)


func _append_sheet_section(lines: Array[String], heading: String, entries: Array[String]) -> void:
	var clean_entries: Array[String] = []
	for entry in entries:
		var trimmed := entry.strip_edges()
		if trimmed != "":
			clean_entries.append(trimmed)
	if clean_entries.is_empty():
		return
	if not lines.is_empty():
		lines.append("")
	lines.append("%s:" % heading)
	for entry in clean_entries:
		lines.append("- %s" % entry)
