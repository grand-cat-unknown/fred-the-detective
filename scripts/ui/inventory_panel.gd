class_name InventoryPanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/List

var _case: CaseData
var _state: CaseState


func _ready() -> void:
	_root.visible = false


func configure(case: CaseData, state: CaseState) -> void:
	_case = case
	if _state != null and _state.fact_changed.is_connected(_on_fact_changed):
		_state.fact_changed.disconnect(_on_fact_changed)
	_state = state
	if _state != null:
		_state.fact_changed.connect(_on_fact_changed)
	refresh()


func refresh() -> void:
	for child in _list.get_children():
		child.queue_free()

	if _case == null or _state == null:
		_panel.visible = false
		_root.visible = false
		return

	var any_visible := false
	for item in _case.inventory_items:
		if item == null or not item.has_method("resolve"):
			continue
		var resolved: Dictionary = item.call("resolve", _state)
		if resolved.is_empty():
			continue
		_list.add_child(_make_row(resolved))
		any_visible = true

	_panel.visible = any_visible
	_root.visible = any_visible


func _make_row(resolved: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var icon: Texture2D = resolved.get("icon")
	if icon != null:
		var rect := TextureRect.new()
		rect.texture = icon
		rect.custom_minimum_size = Vector2(20, 20)
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(rect)

	var label := Label.new()
	label.text = str(resolved.get("label", ""))
	label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65, 1))
	label.add_theme_font_size_override("font_size", 14)
	var tooltip := str(resolved.get("description", ""))
	if tooltip != "":
		label.tooltip_text = tooltip
	row.add_child(label)
	return row


func _on_fact_changed(_fact_id: StringName, _value: bool) -> void:
	refresh()
