extends CanvasLayer
## PC Box — deux panneaux : Équipe (gauche) + Boîte PC 5×6 (droite).
## Layer 35. Ouvert via NPC PC dans un Centre Pokémon.

const BOX_COLS  := 5
const BOX_ROWS  := 6
const CELL_SIZE := 20

var _visible_flag  := false
var _cursor_panel  := 0   # 0 = team, 1 = box
var _cursor_team   := 0
var _cursor_box    := 0   # index plat dans pc_storage

var _bg:           ColorRect
var _team_cells:   Array[ColorRect] = []
var _box_cells:    Array[ColorRect] = []
var _info_label:   Label
var _hint_label:   Label

func _ready() -> void:
	layer = 35
	_build_ui()
	hide_pc()

# ── Public API ───────────────────────────────────────────────────────────────

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

# ── Input ────────────────────────────────────────────────────────────────────

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
		var max_idx := max(0, GameState.pc_storage.size() - 1 + BOX_COLS * BOX_ROWS - GameState.pc_storage.size())
		_cursor_box = clamp(_cursor_box + dir * BOX_COLS, 0, BOX_COLS * BOX_ROWS - 1)
	_refresh()

func _try_move_pokemon() -> void:
	# Déplace entre équipe et boîte
	if _cursor_panel == 0:
		# Envoyer le Pokémon selectionné dans la boîte (si > 1 dans l'équipe)
		if GameState.team.size() <= 1:
			_set_info("Impossible : dernier Pokémon !")
			return
		var poke = GameState.team[_cursor_team]
		GameState.team.remove_at(_cursor_team)
		GameState.pc_storage.append(poke)
		_cursor_team = clamp(_cursor_team, 0, max(0, GameState.team.size() - 1))
	else:
		# Retirer de la boîte vers l'équipe
		if _cursor_box >= GameState.pc_storage.size():
			_set_info("Case vide.")
			return
		if GameState.team.size() >= 6:
			_set_info("Équipe pleine !")
			return
		var poke = GameState.pc_storage[_cursor_box]
		GameState.pc_storage.remove_at(_cursor_box)
		GameState.team.append(poke)
		_cursor_box = clamp(_cursor_box, 0, max(0, GameState.pc_storage.size() - 1))
	_refresh()

func _set_info(msg: String) -> void:
	_info_label.text = msg

# ── Build ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = Color(0.05, 0.05, 0.20, 0.95)
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	var title := Label.new()
	title.text     = "PC — STOCKAGE POKÉMON"
	title.position = Vector2(4, 4)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color.CYAN)
	add_child(title)

	# Panneau équipe (gauche)
	var team_title := Label.new()
	team_title.text     = "ÉQUIPE"
	team_title.position = Vector2(4, 18)
	team_title.add_theme_font_size_override("font_size", 6)
	team_title.add_theme_color_override("font_color", Color.WHITE)
	add_child(team_title)

	for i in 6:
		var cell := ColorRect.new()
		cell.position = Vector2(4, 28 + i * 22)
		cell.size     = Vector2(100, 20)
		cell.color    = Color(0.1, 0.1, 0.25)
		add_child(cell)
		_team_cells.append(cell)

		var lbl := Label.new()
		lbl.name     = "TeamLabel%d" % i
		lbl.position = Vector2(2, 2)
		lbl.add_theme_font_size_override("font_size", 6)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		cell.add_child(lbl)

	# Séparateur
	var sep := ColorRect.new()
	sep.color    = Color(0.3, 0.3, 0.5)
	sep.position = Vector2(108, 16)
	sep.size     = Vector2(2, 210)
	add_child(sep)

	# Panneau boîte (droite)
	var box_title := Label.new()
	box_title.text     = "BOÎTE PC"
	box_title.position = Vector2(114, 18)
	box_title.add_theme_font_size_override("font_size", 6)
	box_title.add_theme_color_override("font_color", Color.WHITE)
	add_child(box_title)

	for row in BOX_ROWS:
		for col in BOX_COLS:
			var cell := ColorRect.new()
			cell.position = Vector2(114 + col * (CELL_SIZE + 2), 28 + row * (CELL_SIZE + 2))
			cell.size     = Vector2(CELL_SIZE, CELL_SIZE)
			cell.color    = Color(0.1, 0.1, 0.25)
			add_child(cell)
			_box_cells.append(cell)

			var lbl := Label.new()
			lbl.position = Vector2(1, 1)
			lbl.add_theme_font_size_override("font_size", 5)
			lbl.add_theme_color_override("font_color", Color.WHITE)
			cell.add_child(lbl)

	# Zone info + hint
	_info_label = Label.new()
	_info_label.position = Vector2(4, 220)
	_info_label.add_theme_font_size_override("font_size", 6)
	_info_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(_info_label)

	_hint_label = Label.new()
	_hint_label.text     = "Z: déplacer   X: fermer"
	_hint_label.position = Vector2(160, 220)
	_hint_label.add_theme_font_size_override("font_size", 6)
	_hint_label.add_theme_color_override("font_color", Color.GRAY)
	add_child(_hint_label)

# ── Refresh ──────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_info_label.text = ""

	# Équipe
	for i in 6:
		var cell := _team_cells[i]
		var lbl: Label = cell.get_node("TeamLabel%d" % i)
		if i < GameState.team.size():
			var poke = GameState.team[i]
			var pdata: Dictionary = GameData.pokemon_data.get(poke.id, {})
			lbl.text = "Lv%d %s" % [poke.level, pdata.get("name", poke.id)]
			if _cursor_panel == 0 and i == _cursor_team:
				cell.color = Color(0.3, 0.5, 0.8)
			else:
				cell.color = Color(0.1, 0.25, 0.1)
		else:
			lbl.text   = "—"
			cell.color = Color(0.08, 0.08, 0.18)

	# Boîte
	for idx in BOX_COLS * BOX_ROWS:
		var cell  := _box_cells[idx]
		var lbl: Label = cell.get_child(0)
		if idx < GameState.pc_storage.size():
			var poke  = GameState.pc_storage[idx]
			var pdata: Dictionary = GameData.pokemon_data.get(poke.id, {})
			lbl.text = pdata.get("name", poke.id).substr(0, 6)
			if _cursor_panel == 1 and idx == _cursor_box:
				cell.color = Color(0.3, 0.5, 0.8)
			else:
				cell.color = Color(0.1, 0.25, 0.1)
		else:
			lbl.text   = ""
			if _cursor_panel == 1 and idx == _cursor_box:
				cell.color = Color(0.2, 0.2, 0.35)
			else:
				cell.color = Color(0.08, 0.08, 0.18)
