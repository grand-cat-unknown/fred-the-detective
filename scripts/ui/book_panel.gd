class_name BookPanel
extends CanvasLayer

const _PAGE_PAD_X := 28.0
const _PAGE_PAD_Y := 24.0
const _SAFETY_PX := 6.0

@onready var _root: Control = $Root
@onready var _backdrop: ColorRect = $Root/Backdrop
@onready var _title_label: Label = $Root/Book/Margin/VBox/Title
@onready var _left_page: RichTextLabel = $Root/Book/Margin/VBox/Pages/LeftPage
@onready var _right_page: RichTextLabel = $Root/Book/Margin/VBox/Pages/RightPage
@onready var _page_info: Label = $Root/Book/Margin/VBox/Footer/PageInfo
@onready var _prev_button: Button = $Root/Book/Margin/VBox/Footer/PrevButton
@onready var _next_button: Button = $Root/Book/Margin/VBox/Footer/NextButton
@onready var _hint_label: Label = $Root/Book/Margin/VBox/Hint
@onready var _measurer: RichTextLabel = $Root/Measurer

var _pages: Array = []
var _spread_index := 0


func _ready() -> void:
	_root.visible = false
	_prev_button.pressed.connect(func() -> void: _turn_page(-1))
	_next_button.pressed.connect(func() -> void: _turn_page(1))
	_prev_button.focus_mode = Control.FOCUS_NONE
	_next_button.focus_mode = Control.FOCUS_NONE


func open(title: String, pages: Array) -> void:
	_title_label.text = title
	_root.visible = true
	await get_tree().process_frame
	_pages = _paginate(pages)
	_spread_index = 0
	_render_spread()


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
		_prev_button.visible = false
		_next_button.visible = false
	else:
		_page_info.text = "Page %d of %d" % [_spread_index + 1, spread_count]
		_prev_button.visible = true
		_next_button.visible = true
		_prev_button.disabled = _spread_index <= 0
		_next_button.disabled = _spread_index >= spread_count - 1


func _page_text(index: int) -> String:
	if index < 0 or index >= _pages.size():
		return ""
	return str(_pages[index])


func _paginate(input_pages: Array) -> Array:
	var page_size := _left_page.size
	var avail_w := page_size.x - _PAGE_PAD_X
	var avail_h := page_size.y - _PAGE_PAD_Y - _SAFETY_PX
	if avail_w <= 0.0 or avail_h <= 0.0:
		return input_pages.duplicate()
	_measurer.custom_minimum_size = Vector2(avail_w, 0)
	_measurer.size = Vector2(avail_w, 0)

	var result: Array = []
	for page_text in input_pages:
		var text: String = str(page_text)
		var paragraphs: Array = _split_paragraphs(text)
		var current: String = ""
		for para_variant in paragraphs:
			var para: String = str(para_variant)
			var candidate: String = para if current.is_empty() else current + "\n\n" + para
			if _measure_height(candidate, avail_w) <= avail_h:
				current = candidate
				continue
			if not current.is_empty():
				result.append(current)
				current = para
			if _measure_height(current, avail_w) > avail_h:
				var chunks: Array = _split_long_paragraph(current, avail_w, avail_h)
				for i in range(chunks.size() - 1):
					result.append(chunks[i])
				current = str(chunks[chunks.size() - 1]) if chunks.size() > 0 else ""
		if not current.is_empty():
			result.append(current)
	return result


func _split_paragraphs(text: String) -> Array:
	var raw := text.split("\n\n", false)
	var out: Array = []
	for piece in raw:
		var trimmed: String = piece.strip_edges(false, true)
		if trimmed != "":
			out.append(trimmed)
	return out


func _split_long_paragraph(para: String, avail_w: float, avail_h: float) -> Array:
	var lines: PackedStringArray = para.split("\n", false)
	if lines.size() <= 1:
		return [para]
	var out: Array = []
	var current: String = ""
	for line in lines:
		var line_s: String = str(line)
		var candidate: String = line_s if current.is_empty() else current + "\n" + line_s
		if _measure_height(candidate, avail_w) <= avail_h:
			current = candidate
		else:
			if not current.is_empty():
				out.append(current)
			current = line_s
	if not current.is_empty():
		out.append(current)
	return out


func _measure_height(text: String, avail_w: float) -> float:
	_measurer.custom_minimum_size = Vector2(avail_w, 0)
	_measurer.size = Vector2(avail_w, 0)
	_measurer.text = text
	return _measurer.get_content_height()
