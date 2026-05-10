class_name AccusationPanel
extends PanelContainer

signal suspect_chosen(index: int)
signal evidence_chosen(index: int)
signal explanation_changed
signal submitted(text: String)
signal closed

@onready var _label: Label = %AccusationLabel
@onready var _suspect_box: VBoxContainer = %AccusationSuspectBox
@onready var _evidence_box: VBoxContainer = %AccusationEvidenceBox
@onready var _explanation_box: VBoxContainer = %AccusationExplanationBox
@onready var _explanation_input: TextEdit = %AccusationExplanationInput
@onready var _status_label: Label = %AccusationStatusLabel
@onready var _submit_button: Button = %AccusationSubmitButton
@onready var _cancel_button: Button = %AccusationCancelButton

var _case: CaseData
var _evidence_buttons: Array[Button] = []


func _ready() -> void:
	_explanation_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_explanation_input.text_changed.connect(_on_explanation_changed)
	_submit_button.pressed.connect(_emit_submission)
	_cancel_button.pressed.connect(_on_cancel_pressed)


func configure(case_data: CaseData) -> void:
	_case = case_data
	_populate_buttons()


func open(question: String) -> void:
	_label.text = question
	_suspect_box.visible = true
	_evidence_box.visible = false
	_explanation_box.visible = false
	_explanation_input.clear()
	set_busy(false, "")
	set_submit_enabled(false)
	visible = true


func close() -> void:
	visible = false


func show_evidence(inspected_clue_ids: Array[StringName]) -> void:
	_label.text = "What is your key evidence?"
	_suspect_box.visible = false
	_explanation_box.visible = false
	for i in range(_evidence_buttons.size()):
		_evidence_buttons[i].visible = inspected_clue_ids.has(_case.clues[i].id)
	_evidence_box.visible = true


func show_explanation() -> void:
	_label.text = "Make the case."
	_evidence_box.visible = false
	_explanation_input.clear()
	set_busy(false, "")
	set_submit_enabled(false)
	_explanation_box.visible = true
	_explanation_input.grab_focus()


func set_busy(is_busy: bool, status_text: String) -> void:
	_explanation_input.editable = not is_busy
	_submit_button.disabled = is_busy or _explanation_input.text.strip_edges().is_empty()
	_status_label.visible = not status_text.is_empty()
	_status_label.text = status_text


func set_submit_enabled(enabled: bool) -> void:
	_submit_button.disabled = not enabled


func show_status(status_text: String) -> void:
	_status_label.visible = not status_text.is_empty()
	_status_label.text = status_text


func explanation_text() -> String:
	return _explanation_input.text


func _populate_buttons() -> void:
	_clear_children(_suspect_box)
	_clear_children(_evidence_box)
	_evidence_buttons.clear()

	for i in range(_case.suspects.size()):
		var suspect := _case.suspects[i]
		var btn := Button.new()
		btn.text = "%s - %s" % [suspect.display_name, suspect.subtitle]
		btn.pressed.connect(_on_suspect_button_pressed.bind(i))
		_suspect_box.add_child(btn)

	for i in range(_case.clues.size()):
		var clue := _case.clues[i]
		var btn := Button.new()
		btn.text = clue.label
		btn.pressed.connect(_on_evidence_button_pressed.bind(i))
		_evidence_buttons.append(btn)
		_evidence_box.add_child(btn)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _on_explanation_changed() -> void:
	explanation_changed.emit()


func _emit_submission() -> void:
	submitted.emit(_explanation_input.text)


func _on_cancel_pressed() -> void:
	closed.emit()


func _on_suspect_button_pressed(index: int) -> void:
	suspect_chosen.emit(index)


func _on_evidence_button_pressed(index: int) -> void:
	evidence_chosen.emit(index)
