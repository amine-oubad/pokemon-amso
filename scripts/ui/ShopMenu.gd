extends CanvasLayer
## Menu boutique moderne — achat d'objets avec PokeDollars.

signal shop_closed

const FONT_SIZE := 8
const ROW_H    := 20

var _active:   bool   = false
var _items:    Array  = []
var _selected: int    = 0

var _inner:        Control
var _title_label:  Label
var _money_label:  Label
var _item_rows:    Array = []
var _desc_label:   Label
var _status_label: Label
var _status_timer: float = 0.0

const C_BG     := Color(0.06, 0.06, 0.14)
const C_PANEL  := Color(0.10, 0.12, 0.22)
const C_BORDER := Color(0.22, 0.25, 0.38)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const C_GOLD   := Color(0.96, 0.80, 0.22)
const C_TEXT   := Color(0.90, 0.90, 0.95)
const C_TEXT2  := Color(0.55, 0.55, 0.68)

func _ready() -> void:
	layer = 25
	visible = false
	_build_ui()
	set_process_input(false)

func _build_ui() -> void:
	var root := ColorRect.new()
	root.color = Color(0.0, 0.0, 0.0, 0.88)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Border
	var border := ColorRect.new()
	border.color = C_BORDER
	border.position = Vector2(7, 7)
	border.size     = Vector2(306, 226)
	root.add_child(border)

	_inner = ColorRect.new()
	_inner.color    = C_BG
	_inner.position = Vector2(8, 8)
	_inner.size     = Vector2(304, 224)
	root.add_child(_inner)

	# Top accent
	var accent := ColorRect.new()
	accent.color = C_ACCENT
	accent.position = Vector2(0, 0)
	accent.size = Vector2(304, 2)
	_inner.add_child(accent)

	_title_label = Label.new()
	_title_label.position = Vector2(8, 6)
	_title_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_title_label.add_theme_color_override("font_color", C_GOLD)
	_inner.add_child(_title_label)

	_money_label = Label.new()
	_money_label.position = Vector2(200, 6)
	_money_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_money_label.add_theme_color_override("font_color", C_GOLD)
	_inner.add_child(_money_label)

	var sep := ColorRect.new()
	sep.color    = C_BORDER
	sep.position = Vector2(4, 20)
	sep.size     = Vector2(296, 1)
	_inner.add_child(sep)

	var sep2 := ColorRect.new()
	sep2.color    = C_BORDER
	sep2.position = Vector2(4, 192)
	sep2.size     = Vector2(296, 1)
	_inner.add_child(sep2)

	_desc_label = Label.new()
	_desc_label.position = Vector2(8, 196)
	_desc_label.size     = Vector2(288, 16)
	_desc_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_desc_label.add_theme_color_override("font_color", C_TEXT2)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inner.add_child(_desc_label)

	_status_label = Label.new()
	_status_label.position = Vector2(8, 210)
	_status_label.size     = Vector2(288, 10)
	_status_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	_inner.add_child(_status_label)

func open_shop(shop_id: String) -> void:
	if _active:
		return
	var shop: Dictionary = GameData.shops_data.get(shop_id, {})
	var item_ids: Array  = shop.get("items", [])
	_items = []
	for id in item_ids:
		var d: Dictionary = GameData.items_data.get(id, {})
		if not d.is_empty():
			_items.append({ "id": id, "data": d })
	if _items.is_empty():
		return
	_selected = 0
	_active   = true
	visible   = true
	set_process_input(true)
	_title_label.text = shop.get("name", "Boutique")
	_populate_rows()
	_refresh()

func is_active() -> bool:
	return _active

func _populate_rows() -> void:
	for row in _item_rows:
		row.queue_free()
	_item_rows.clear()

	for i in _items.size():
		var item: Dictionary = _items[i]

		var row := ColorRect.new()
		row.position = Vector2(4, 24 + i * ROW_H)
		row.size     = Vector2(296, ROW_H - 2)
		row.color    = Color(0.0, 0.0, 0.0, 0.0)
		_inner.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text     = item["data"].get("name", item["id"])
		name_lbl.position = Vector2(6, 2)
		name_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		row.add_child(name_lbl)

		var price_lbl := Label.new()
		price_lbl.text     = "%d P$" % item["data"].get("price", 0)
		price_lbl.position = Vector2(210, 2)
		price_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
		price_lbl.add_theme_color_override("font_color", C_GOLD)
		row.add_child(price_lbl)

		_item_rows.append(row)

func _refresh() -> void:
	_money_label.text = "P$ %d" % GameState.money
	for i in _item_rows.size():
		_item_rows[i].color = Color(0.16, 0.20, 0.38, 0.9) if i == _selected else Color(0.0, 0.0, 0.0, 0.0)
	if _selected < _items.size():
		_desc_label.text = _items[_selected]["data"].get("description", "")

func _try_buy() -> void:
	if _selected >= _items.size():
		return
	var item: Dictionary = _items[_selected]
	var price: int = item["data"].get("price", 0)
	if GameState.money < price:
		_show_status("Pas assez d'argent !", Color(0.9, 0.3, 0.3))
		return
	GameState.money -= price
	GameState.add_item(item["id"], 1)
	_refresh()
	_show_status("%s achete !" % item["data"].get("name", item["id"]), Color(0.3, 0.9, 0.3))

func _show_status(msg: String, color: Color) -> void:
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", color)
	_status_timer = 1.5

func _close() -> void:
	_active = false
	visible = false
	set_process_input(false)
	for row in _item_rows:
		row.queue_free()
	_item_rows.clear()
	shop_closed.emit()

func _process(delta: float) -> void:
	if _status_timer > 0.0:
		_status_timer -= delta
		if _status_timer <= 0.0:
			_status_label.text = ""

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		_selected = max(0, _selected - 1)
		_refresh()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_selected = mini(_items.size() - 1, _selected + 1)
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_try_buy()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
