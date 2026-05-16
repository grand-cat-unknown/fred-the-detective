class_name InventoryPanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _list: VBoxContainer = $Root/Panel/Margin/VBox/List

var _case: CaseData
var _state: CaseState
var _active_items: Array[Dictionary] = []


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
	_active_items.clear()

	if _case == null or _state == null:
		_panel.visible = false
		_root.visible = false
		return

	for item in _case.inventory_items:
		if item == null or not item.has_method("resolve"):
			continue
		var resolved: Dictionary = item.call("resolve", _state)
		if resolved.is_empty():
			continue
		_active_items.append(resolved)
		_list.add_child(_make_row(resolved))

	var any_visible := not _active_items.is_empty()
	_panel.visible = any_visible
	_root.visible = any_visible


func get_active_items() -> Array[Dictionary]:
	return _active_items


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
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tooltip := str(resolved.get("description", ""))
	if tooltip != "":
		label.tooltip_text = tooltip
	row.add_child(label)

	var key_hint := str(resolved.get("action_key_hint", "")).strip_edges()
	if key_hint != "":
		row.add_child(_make_key_chip(key_hint))
	return row


func _make_key_chip(text: String) -> Control:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.2, 0.23, 1.0)
	style.border_color = Color(0.85, 0.78, 0.55, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", style)

	var key_label := Label.new()
	key_label.text = text
	key_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.65, 1))
	key_label.add_theme_font_size_override("font_size", 12)
	chip.add_child(key_label)
	return chip


func _on_fact_changed(_fact_id: StringName, _value: bool) -> void:
	refresh()
