extends CanvasLayer
## PC Box moderne — deux panneaux : Equipe (gauche) + Boite PC 5x6 (droite).
## Layer 35.

const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
const BOX_COLS  := 5
const BOX_ROWS  := 6
const CELL_SIZE := 22

var _visible_flag  := false
var _cursor_panel  := 0
var _cursor_team   := 0
var _cursor_box    := 0

var _bg:           ColorRect
var _team_cells:   Array[ColorRect] = []
var _box_cells:    Array[ColorRect] = []
var _info_label:   Label
var _hint_label:   Label

const C_BG     := Color(0.06, 0.06, 0.14, 0.97)
const C_PANEL  := Color(0.10, 0.12, 0.22)
const C_BORDER := Color(0.22, 0.25, 0.38)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const C_GOLD   := Color(0.96, 0.80, 0.22)
const C_TEXT   := Color(0.90, 0.90, 0.95)
const C_TEXT2  := Color(0.55, 0.55, 0.68)

func _ready() -> void:
	layer = 35
	_build_ui()
	hide_pc()

func open_pc() -> void:
	_cursor_panel = 0
	_cursor_team  = 0
	_cursor_box   = 0
	_visible_flag = true
	_bg.show()
	_refresh()

func hide_pc() -> void:
	_visible_flag = false
	_bg.hide()

func is_active() -> bool:
	return _visible_flag

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag: return
	if event.is_action_pressed("ui_cancel"):
		hide_pc()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right") and _cursor_panel == 0:
		_cursor_panel = 1
		_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") and _cursor_panel == 1:
		_cursor_panel = 0
		_refresh()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_try_move_pokemon()
		get_viewport().set_input_as_handled()

func _move_cursor(dir: int) -> void:
	if _cursor_panel == 0:
		_cursor_team = clamp(_cursor_team + dir, 0, max(0, GameState.team.size() - 1))
	else:
		_cursor_box = clamp(_cursor_box + dir * BOX_COLS, 0, BOX_COLS * BOX_ROWS - 1)
	_refresh()

func _try_move_pokemon() -> void:
	if _cursor_panel == 0:
		if GameState.team.size() <= 1:
			_set_info("Impossible : dernier Pokemon !")
			return
		var poke: PokemonInstance = GameState.team[_cursor_team]
		GameState.team.remove_at(_cursor_team)
		GameState.pc_boxes.append(poke)
		_cursor_team = clamp(_cursor_team, 0, max(0, GameState.team.size() - 1))
	else:
		if _cursor_box >= GameState.pc_boxes.size():
			_set_info("Case vide.")
			return
		if GameState.team.size() >= 6:
			_set_info("Equipe pleine !")
			return
		var poke: PokemonInstance = GameState.pc_boxes[_cursor_box]
		GameState.pc_boxes.remove_at(_cursor_box)
		GameState.team.append(poke)
		_cursor_box = clamp(_cursor_box, 0, max(0, GameState.pc_boxes.size() - 1))
	_refresh()

func _set_info(msg: String) -> void:
	_info_label.text = msg

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = C_BG
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	# Top accent
	var accent := ColorRect.new()
	accent.color = C_ACCENT
	accent.position = Vector2(0, 0)
	accent.size = Vector2(320, 2)
	add_child(accent)

	var title := Label.new()
	title.text     = "PC STOCKAGE"
	title.position = Vector2(6, 5)
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", C_ACCENT)
	add_child(title)

	# Team panel title
	var team_title := Label.new()
	team_title.text     = "EQUIPE"
	team_title.position = Vector2(6, 18)
	team_title.add_theme_font_size_override("font_size", 6)
	team_title.add_theme_color_override("font_color", C_GOLD)
	add_child(team_title)

	for i in 6:
		var cell := ColorRect.new()
		cell.position = Vector2(4, 28 + i * 24)
		cell.size     = Vector2(106, 22)
		cell.color    = C_PANEL
		add_child(cell)
		_team_cells.append(cell)

		var lbl := Label.new()
		lbl.name     = "TeamLabel%d" % i
		lbl.position = Vector2(20, 3)
		lbl.add_theme_font_size_override("font_size", 6)
		lbl.add_theme_color_override("font_color", C_TEXT)
		cell.add_child(lbl)

	# Separator
	var sep := ColorRect.new()
	sep.color    = C_BORDER
	sep.position = Vector2(114, 16)
	sep.size     = Vector2(1, 210)
	add_child(sep)

	# Box panel title
	var box_title := Label.new()
	box_title.text     = "BOITE PC"
	box_title.position = Vector2(118, 18)
	box_title.add_theme_font_size_override("font_size", 6)
	box_title.add_theme_color_override("font_color", C_GOLD)
	add_child(box_title)

	for row in BOX_ROWS:
		for col in BOX_COLS:
			var cell := ColorRect.new()
			cell.position = Vector2(118 + col * (CELL_SIZE + 2), 28 + row * (CELL_SIZE + 2))
			cell.size     = Vector2(CELL_SIZE, CELL_SIZE)
			cell.color    = C_PANEL
			add_child(cell)
			_box_cells.append(cell)

			var lbl := Label.new()
			lbl.position = Vector2(1, 1)
			lbl.add_theme_font_size_override("font_size", 5)
			lbl.add_theme_color_override("font_color", C_TEXT)
			cell.add_child(lbl)

	# Info + hint
	_info_label = Label.new()
	_info_label.position = Vector2(4, 222)
	_info_label.add_theme_font_size_override("font_size", 6)
	_info_label.add_theme_color_override("font_color", C_GOLD)
	add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.text     = "Z: deplacer   X: fermer"
	_hint_label.position = Vector2(180, 222)
	_hint_label.add_theme_font_size_override("font_size", 6)
	_hint_label.add_theme_color_override("font_color", C_TEXT2)
	add_child(_hint_label)

func _refresh() -> void:
	_info_label.text = ""

	for i in 6:
		var cell := _team_cells[i]
		var lbl: Label = cell.get_node("TeamLabel%d" % i)
		# Clear old icon sprites to prevent leaks
		for c in cell.get_children():
			if c.name.begins_with("Icon"):
				c.queue_free()
		if i < GameState.team.size():
			var poke: PokemonInstance = GameState.team[i]
			var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
			lbl.text = "Lv%d %s" % [poke.level, pdata.get("name", poke.pokemon_id)]
			# Mini icon
			var icon := SpriteLoader.make_sprite(poke.pokemon_id, "front", Vector2(16, 16))
			icon.position = Vector2(2, 3)
			icon.name = "Icon%d" % i
			cell.add_child(icon)
			if _cursor_panel == 0 and i == _cursor_team:
				cell.color = Color(0.20, 0.30, 0.55)
			else:
				cell.color = Color(0.10, 0.16, 0.12)
		else:
			lbl.text   = "—"
			cell.color = C_PANEL

	for idx in BOX_COLS * BOX_ROWS:
		var cell  := _box_cells[idx]
		var lbl: Label = cell.get_child(0)
		if idx < GameState.pc_boxes.size():
			var poke: PokemonInstance = GameState.pc_boxes[idx]
			var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
			lbl.text = pdata.get("name", poke.pokemon_id).substr(0, 5)
			if _cursor_panel == 1 and idx == _cursor_box:
				cell.color = Color(0.20, 0.30, 0.55)
			else:
				cell.color = Color(0.10, 0.16, 0.12)
		else:
			lbl.text   = ""
			if _cursor_panel == 1 and idx == _cursor_box:
				cell.color = Color(0.14, 0.16, 0.28)
			else:
				cell.color = C_PANEL
