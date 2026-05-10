class_name Gameplay
extends RefCounted

const PLAYER_SPEED := 240.0
const PLAYER_RADIUS := 12.0

const NPC_RADIUS := 12.0
const NPC_INTERACT_RADIUS := 54.0
const CLUE_INTERACT_RADIUS := 48.0

const MAX_CONVERSATION_LINES := 10
const MAX_DIALOGUE_LINES := 12

const LLM_MAX_OUTPUT_TOKENS := 180
const LLM_LOCAL_ENDPOINT := "http://127.0.0.1:3000/api/llm"
