class_name BookPanel
extends CanvasLayer

@onready var _root: Control = $Root
@onready var _backdrop: ColorRect = $Root/Backdrop
@onready var _title_label: Label = $Root/Book/Margin/VBox/Title
@onready var _left_page: RichTextLabel = $Root/Book/Margin/VBox/Pages/LeftPage
@onready var _right_page: RichTextLabel = $Root/Book/Margin/VBox/Pages/RightPage
@onready var _page_info: Label = $Root/Book/Margin/VBox/Footer/PageInfo
@onready var _hint_label: Label = $Root/Book/Margin/VBox/Footer/Hint

var _pages: Array = []
var _spread_index := 0


func _ready() -> void:
	_root.visible = false


func open(title: String, pages: Array) -> void:
	_title_label.text = title
	_pages = pages.duplicate()
	_spread_index = 0
	_render_spread()
	_root.visible = true


func hide_panel() -> void:
	_root.visible = false
	_pages = []
	_spread_index = 0


func is_open() -> bool:
	return _root.visible


func handle_input_event(event: InputEvent) -> bool:
	if not is_open():
		return false
	if event.is_action_pressed("ui_cancel"):
		hide_panel()
		return true
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		_turn_page(1)
		return true
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		_turn_page(-1)
		return true
	return false


func _turn_page(direction: int) -> void:
	var spread_count := _spread_count()
	if spread_count == 0:
		return
	_spread_index = clampi(_spread_index + direction, 0, spread_count - 1)
	_render_spread()


func _spread_count() -> int:
	if _pages.is_empty():
		return 0
	return int(ceil(_pages.size() / 2.0))


func _render_spread() -> void:
	var left_index := _spread_index * 2
	var right_index := left_index + 1
	_left_page.text = _page_text(left_index)
	_right_page.text = _page_text(right_index)
	var spread_count := _spread_count()
	if spread_count <= 1:
		_page_info.text = ""
		_hint_label.text = "Esc to close"
	else:
		_page_info.text = "Page %d of %d" % [_spread_index + 1, spread_count]
		_hint_label.text = "←/→ to turn pages   ·   Esc to close"


func _page_text(index: int) -> String:
	if index < 0 or index >= _pages.size():
		return ""
	return str(_pages[index])
