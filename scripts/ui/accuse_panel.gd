class_name AccusePanel
extends CanvasLayer

signal accusation_resolved(success: bool, message: String)

const CORRECT_KILLER := &"otis"
const CORRECT_METHOD := &"containment_cell"
const CORRECT_EVIDENCE := &"recovered_cell"
const REQUIRED_EVIDENCE_FACT := &"has_evidence"

@onready var _root: Control = $Root
@onready var _accuse_button: Button = $Root/AccuseButton
@onready var _modal: Control = $Root/Modal
@onready var _killer_options: OptionButton = $Root/Modal/Panel/Margin/VBox/Slots/KillerRow/KillerOptions
@onready var _method_options: OptionButton = $Root/Modal/Panel/Margin/VBox/Slots/MethodRow/MethodOptions
@onready var _evidence_options: OptionButton = $Root/Modal/Panel/Margin/VBox/Slots/EvidenceRow/EvidenceOptions
@onready var _result_label: RichTextLabel = $Root/Modal/Panel/Margin/VBox/Result
@onready var _submit_button: Button = $Root/Modal/Panel/Margin/VBox/Actions/SubmitButton
@onready var _close_button: Button = $Root/Modal/Panel/Margin/VBox/Actions/CloseButton

var _state: CaseState


func _ready() -> void:
	_modal.visible = false
	_populate_options()
	_accuse_button.pressed.connect(open)
	_submit_button.pressed.connect(_submit_accusation)
	_close_button.pressed.connect(hide_panel)


func configure(state: CaseState) -> void:
	_state = state


func set_accuse_button_enabled(enabled: bool) -> void:
	_accuse_button.visible = enabled
	_accuse_button.disabled = not enabled


func open() -> void:
	_result_label.text = ""
	_modal.visible = true


func hide_panel() -> void:
	_modal.visible = false


func is_open() -> bool:
	return _modal.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if event.is_action_pressed("ui_cancel"):
		hide_panel()
		return true
	return false


func _populate_options() -> void:
	_add_options(_killer_options, [
		{"id": &"", "label": "Choose a suspect"},
		{"id": &"mara", "label": "Mara"},
		{"id": &"theo", "label": "Theo"},
		{"id": &"otis", "label": "Otis"},
		{"id": &"iris", "label": "Iris"},
		{"id": &"rival", "label": "Julian Vane"},
	])
	_add_options(_method_options, [
		{"id": &"", "label": "Choose the method"},
		{"id": &"ghost_attack", "label": "A ghost attack"},
		{"id": &"containment_cell", "label": "Siren containment cell"},
		{"id": &"poison", "label": "Poison"},
		{"id": &"blunt_force", "label": "Blunt force"},
	])
	_add_options(_evidence_options, [
		{"id": &"", "label": "Choose the evidence"},
		{"id": &"recovered_cell", "label": "Recovered containment cell"},
		{"id": &"field_book", "label": "Theo's field book"},
		{"id": &"wet_laundry", "label": "Wet laundry pile"},
	])


func _add_options(button: OptionButton, options: Array) -> void:
	button.clear()
	for option in options:
		var index := button.item_count
		button.add_item(str(option.get("label", "")))
		button.set_item_metadata(index, option.get("id", &""))


func _submit_accusation() -> void:
	var killer := _selected_id(_killer_options)
	var method := _selected_id(_method_options)
	var evidence := _selected_id(_evidence_options)
	var has_required_evidence := _state != null and _state.get_fact(REQUIRED_EVIDENCE_FACT, false)
	var is_correct := killer == CORRECT_KILLER and method == CORRECT_METHOD and evidence == CORRECT_EVIDENCE and has_required_evidence

	if is_correct:
		var success_message := "Case closed. Otis killed Vance by using the Siren containment cell as a weapon, and Fred has the recovered cell to prove it."
		_result_label.text = "[color=#f1dda0]%s[/color]" % success_message
		accusation_resolved.emit(true, success_message)
		return

	var problems: Array[String] = []
	if killer != CORRECT_KILLER:
		problems.append("the suspect")
	if method != CORRECT_METHOD:
		problems.append("the method")
	if evidence != CORRECT_EVIDENCE:
		problems.append("the evidence")
	elif not has_required_evidence:
		problems.append("you have not found that evidence yet")

	var message := "The accusation does not hold. Recheck %s." % _join_problem_list(problems)
	_result_label.text = "[color=#f0b0a0]%s[/color]" % message
	accusation_resolved.emit(false, message)


func _selected_id(button: OptionButton) -> StringName:
	if button.selected < 0:
		return &""
	return StringName(str(button.get_item_metadata(button.selected)))


func _join_problem_list(problems: Array[String]) -> String:
	if problems.is_empty():
		return "the case"
	if problems.size() == 1:
		return problems[0]
	if problems.size() == 2:
		return "%s and %s" % [problems[0], problems[1]]
	return "%s, %s, and %s" % [problems[0], problems[1], problems[2]]
