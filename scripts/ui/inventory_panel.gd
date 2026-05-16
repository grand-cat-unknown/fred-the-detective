class_name InventoryPanel
extends CanvasLayer

@onready var _empty_label: Label = $Root/Panel/Margin/VBox/Empty
@onready var _items_list: VBoxContainer = $Root/Panel/Margin/VBox/Items

var _case_state: CaseState
var _world: WorldView
var _inventory_items: Array[Resource] = []
var _last_fact_signature := ""


func configure(case_state: CaseState, world: WorldView = null, inventory_items: Array[Resource] = []) -> void:
	if _case_state != null and _case_state.fact_changed.is_connected(_on_fact_changed):
		_case_state.fact_changed.disconnect(_on_fact_changed)

	_case_state = case_state
	_world = world
	_inventory_items = inventory_items
	if _case_state != null:
		_case_state.fact_changed.connect(_on_fact_changed)
	_update_items()


func _process(_delta: float) -> void:
	if _case_state == null:
		return
	var signature := "|".join(_case_state.true_fact_ids())
	if signature == _last_fact_signature:
		return
	_update_items()


func _exit_tree() -> void:
	if _case_state != null and _case_state.fact_changed.is_connected(_on_fact_changed):
		_case_state.fact_changed.disconnect(_on_fact_changed)


func _on_fact_changed(_fact_id: StringName, _value: bool) -> void:
	_update_items()


func _update_items() -> void:
	_last_fact_signature = "|".join(_case_state.true_fact_ids()) if _case_state != null else ""

	for child in _items_list.get_children():
		child.queue_free()

	var items: Array[Resource] = []
	if _case_state != null:
		for item in _inventory_items:
			if item != null:
				items.append(item)

	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return str(_resolve_item(a).get("label", "")) < str(_resolve_item(b).get("label", ""))
	)

	var visible_count := 0
	for item in items:
		var resolved := _resolve_item(item)
		if not bool(resolved.get("visible", false)):
			continue
		visible_count += 1

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 8)
		_items_list.add_child(row)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _get_item_icon(resolved)
		row.add_child(icon)

		var label := Label.new()
		label.text = str(resolved.get("label", "Item"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9, 1))
		label.add_theme_font_size_override("font_size", 14)
		row.add_child(label)

	_empty_label.visible = visible_count == 0
	_items_list.visible = visible_count > 0


func _resolve_item(item: Resource) -> Dictionary:
	if item == null:
		return {}
	if item.has_method("resolve"):
		return item.call("resolve", _case_state)

	var states: Variant = item.get("states")
	if typeof(states) == TYPE_ARRAY:
		for item_state in states:
			if item_state is Resource and item_state.has_method("is_available") and item_state.has_method("to_inventory_dictionary") and item_state.is_available(_case_state):
				var resolved: Dictionary = item_state.to_inventory_dictionary()
				resolved["item_id"] = StringName(str(item.get("item_id")))
				return resolved

	var fact_id := StringName(str(item.get("fact_id")))
	if fact_id != &"" and _case_state != null and _case_state.get_fact(fact_id):
		return {
			"visible": true,
			"item_id": StringName(str(item.get("item_id"))),
			"label": str(item.get("label")),
			"layer_name": str(item.get("layer_name")),
			"source_id": int(item.get("source_id")),
			"atlas_coords": item.get("atlas_coords"),
			"alternative_tile": int(item.get("alternative_tile")),
		}

	return {
		"visible": false,
		"item_id": StringName(str(item.get("item_id"))),
	}


func _get_item_icon(item: Dictionary) -> Texture2D:
	if _world == null:
		return null
	return _world.get_tile_icon_texture(
		str(item.get("layer_name", "")),
		int(item.get("source_id", -1)),
		item.get("atlas_coords", Vector2i.ZERO)
	)
