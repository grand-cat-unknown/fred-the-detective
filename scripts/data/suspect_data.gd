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


func available_conversation_effects(state: CaseState) -> Array[ConversationEffect]:
	var effects: Array[ConversationEffect] = []
	for effect in allowed_effects:
		if effect is ConversationEffect and effect.is_available(state):
			effects.append(effect as ConversationEffect)
	return effects


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
