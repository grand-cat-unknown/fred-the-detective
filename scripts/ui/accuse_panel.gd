class_name AccusePanel
extends CanvasLayer

signal accusation_resolved(success: bool, message: String)
signal accusation_submitted(killer_id: StringName, killer_label: String, method_text: String, evidence_text: String)

@onready var _root: Control = $Root
@onready var _accuse_button: Button = $Root/AccuseButton
@onready var _modal: Control = $Root/Modal
@onready var _killer_options: OptionButton = $Root/Modal/Panel/Margin/VBox/Slots/KillerRow/KillerOptions
@onready var _method_input: TextEdit = $Root/Modal/Panel/Margin/VBox/Slots/MethodRow/MethodInput
@onready var _evidence_input: TextEdit = $Root/Modal/Panel/Margin/VBox/Slots/EvidenceRow/EvidenceInput
@onready var _result_label: RichTextLabel = $Root/Modal/Panel/Margin/VBox/Result
@onready var _submit_button: Button = $Root/Modal/Panel/Margin/VBox/Actions/SubmitButton
@onready var _close_button: Button = $Root/Modal/Panel/Margin/VBox/Actions/CloseButton


func _ready() -> void:
	_modal.visible = false
	_populate_options()
	_accuse_button.pressed.connect(open)
	_submit_button.pressed.connect(_submit_accusation)
	_close_button.pressed.connect(hide_panel)


func configure(_state: CaseState) -> void:
	pass


func set_accuse_button_enabled(enabled: bool) -> void:
	_accuse_button.visible = enabled
	_accuse_button.disabled = not enabled


func open() -> void:
	_result_label.text = ""
	set_busy(false)
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


func set_busy(is_busy: bool) -> void:
	_submit_button.disabled = is_busy
	_close_button.disabled = is_busy
	_killer_options.disabled = is_busy
	_method_input.editable = not is_busy
	_evidence_input.editable = not is_busy
	if is_busy:
		_result_label.text = "[color=#f1dda0]Judging accusation...[/color]"


func show_result(success: bool, message: String) -> void:
	set_busy(false)
	var color := "#f1dda0" if success else "#f0b0a0"
	_result_label.text = "[color=%s]%s[/color]" % [color, message]
	accusation_resolved.emit(success, message)


func _populate_options() -> void:
	_add_options(_killer_options, [
		{"id": &"", "label": "Choose a suspect"},
		{"id": &"mara", "label": "Mara"},
		{"id": &"theo", "label": "Theo"},
		{"id": &"otis", "label": "Otis"},
		{"id": &"iris", "label": "Iris"},
		{"id": &"rival", "label": "Julian Vane"},
	])


func _add_options(button: OptionButton, options: Array) -> void:
	button.clear()
	for option in options:
		var index := button.item_count
		button.add_item(str(option.get("label", "")))
		button.set_item_metadata(index, option.get("id", &""))


func _submit_accusation() -> void:
	var killer := _selected_id(_killer_options)
	var method := _method_input.text.strip_edges()
	var evidence := _evidence_input.text.strip_edges()
	if killer == &"" or method == "" or evidence == "":
		show_result(false, "The accusation needs a suspect, a method, and evidence.")
		return
	set_busy(true)
	accusation_submitted.emit(killer, _killer_options.get_item_text(_killer_options.selected), method, evidence)


func _selected_id(button: OptionButton) -> StringName:
	if button.selected < 0:
		return &""
	return StringName(str(button.get_item_metadata(button.selected)))
