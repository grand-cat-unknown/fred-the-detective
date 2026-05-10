extends Node

signal room_changed(room_id: StringName)
signal phase_changed(phase: GameEnums.Phase)

signal clue_inspected(clue_id: StringName)
signal suspect_talked(suspect_id: StringName)

signal dialogue_opened(suspect_id: StringName)
signal dialogue_closed
signal dialogue_line_appended(suspect_id: StringName, speaker: String, text: String)
signal dialogue_busy_changed(is_busy: bool, status: String)

signal clue_panel_opened(clue_id: StringName)
signal clue_panel_closed

signal accusation_started
signal accusation_step_changed(step: GameEnums.AccusationStep)
signal accusation_busy_changed(is_busy: bool, status: String)
signal accusation_resolved(verdict: AccusationVerdict)
signal accusation_cancelled

signal interact_target_changed(target: InteractTarget)

signal restart_requested
