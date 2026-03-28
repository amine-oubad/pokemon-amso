extends CanvasLayer
## Menu Pause — 4 onglets : Équipe / Sac / Pokédex / Sauver.
## Layer 30. Ouvert par ui_cancel quand aucun autre menu n'est actif.

var _visible_flag := false
var _in_battle    := false
var _tab_index    := 0
var _cursor_idx   := 0   # curseur dans l'onglet courant
var _swap_src     := -1  # index source pour réordonnement équipe

var _bg:         ColorRect
var _tab_labels: Array[Label] = []
var _content:    Control
var _scroll_offset := 0  # pour pokédex scroll

const TABS := ["ÉQUIPE", "SAC", "POKÉDEX", "SAUVER"]

func _ready() -> void:
	layer = 30
	_build_ui()
	hide_menu()
	EventBus.battle_started.connect(func(_e, _t): _in_battle = true)
	EventBus.battle_ended.connect(func(_r):       _in_battle = false)

# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _in_battle: return
	if TitleScreen.is_active(): return
	if PokemonSummary.is_active(): return
	if DialogueManager.is_active(): return
	if ShopMenu.is_active(): return

	if event.is_action_pressed("ui_cancel"):
		if _swap_src >= 0:
			_swap_src = -1
			_refresh_content()
		elif _visible_flag:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()
		return

	if not _visible_flag: return

	if event.is_action_pressed("ui_right"):
		_tab_index = (_tab_index + 1) % TABS.size()
		_cursor_idx = 0; _scroll_offset = 0; _swap_src = -1
		_refresh_tabs()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_tab_index = (_tab_index - 1 + TABS.size()) % TABS.size()
		_cursor_idx = 0; _scroll_offset = 0; _swap_src = -1
		_refresh_tabs()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_cursor(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_cursor(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_execute_tab()
		get_viewport().set_input_as_handled()

func _move_cursor(dir: int) -> void:
	match _tab_index:
		0: _cursor_idx = clampi(_cursor_idx + dir, 0, max(0, GameState.team.size() - 1))
		1:
			var count := GameState.bag.size()
			_cursor_idx = clampi(_cursor_idx + dir, 0, max(0, count - 1))
		2:
			var total := GameState.pokedex_seen.size()
			_cursor_idx = clampi(_cursor_idx + dir, 0, max(0, total - 1))
			# Scroll si nécessaire
			if _cursor_idx < _scroll_offset: _scroll_offset = _cursor_idx
			if _cursor_idx >= _scroll_offset + 10: _scroll_offset = _cursor_idx - 9
	_refresh_content()

# ── Public API ───────────────────────────────────────────────────────────────

func show_menu() -> void:
	_visible_flag = true
	_tab_index    = 0
	_cursor_idx   = 0
	_scroll_offset = 0
	_swap_src     = -1
	_bg.show()
	_refresh_tabs()
	_refresh_content()

func hide_menu() -> void:
	_visible_flag = false
	_bg.hide()

func is_active() -> bool:
	return _visible_flag

# ── Build ────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = Color(0.05, 0.05, 0.15, 0.92)
	_bg.position = Vector2(40, 20)
	_bg.size     = Vector2(240, 200)
	add_child(_bg)

	var title := Label.new()
	title.text     = "MENU"
	title.position = Vector2(40, 22)
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	var tab_x := 42
	for i in TABS.size():
		var lbl := Label.new()
		lbl.text     = TABS[i]
		lbl.position = Vector2(tab_x, 36)
		lbl.add_theme_font_size_override("font_size", 6)
		add_child(lbl)
		_tab_labels.append(lbl)
		tab_x += 58

	_content = Control.new()
	_content.position = Vector2(44, 52)
	_content.size     = Vector2(232, 160)
	add_child(_content)

# ── Tabs ─────────────────────────────────────────────────────────────────────

func _refresh_tabs() -> void:
	for i in _tab_labels.size():
		_tab_labels[i].add_theme_color_override("font_color",
			Color.YELLOW if i == _tab_index else Color(0.6, 0.6, 0.6))
	_refresh_content()

func _refresh_content() -> void:
	for child in _content.get_children():
		child.queue_free()
	match _tab_index:
		0: _build_team_tab()
		1: _build_bag_tab()
		2: _build_pokedex_tab()
		3: _build_save_tab()

# ── Onglet Équipe ────────────────────────────────────────────────────────────

func _build_team_tab() -> void:
	if GameState.team.is_empty():
		_add_line("Aucun Pokémon dans l'équipe.", 0, Color.GRAY)
		return
	var y := 0
	for i in GameState.team.size():
		var poke: PokemonInstance = GameState.team[i]
		var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
		var name_str: String = pdata.get("name", poke.pokemon_id)
		var hp_str: String   = "%d/%d" % [poke.current_hp, poke.max_hp]
		var prefix := ""
		if _swap_src == i:
			prefix = "⇄ "
		elif i == _cursor_idx:
			prefix = "▸ "
		else:
			prefix = "  "
		var col := Color.YELLOW if i == _cursor_idx else Color.WHITE
		if poke.is_fainted(): col = Color(0.6, 0.3, 0.3)
		_add_line("%s%s Lv%d  PV %s" % [prefix, name_str, poke.level, hp_str], y, col)
		y += 14
	y += 4
	if _swap_src >= 0:
		_add_line("[Z] Permuter  [X] Annuler", y, Color(0.5, 0.8, 0.5))
	else:
		_add_line("[Z] Fiche / [Z+Z] Permuter", y, Color(0.4, 0.4, 0.6))

# ── Onglet Sac ──────────────────────────────────────────────────────────────

func _build_bag_tab() -> void:
	if GameState.bag.is_empty():
		_add_line("Sac vide.", 0, Color.GRAY)
		return
	var keys := GameState.bag.keys()
	var y := 0
	for i in keys.size():
		var item_id: String   = keys[i]
		var qty: int          = GameState.bag[item_id]
		var idata: Dictionary = GameData.items_data.get(item_id, {})
		var item_name: String = idata.get("name", item_id)
		var prefix := "▸ " if i == _cursor_idx else "  "
		var col := Color.YELLOW if i == _cursor_idx else Color.WHITE
		_add_line("%s× %d  %s" % [prefix, qty, item_name], y, col)
		y += 12
	# Description de l'item sélectionné
	if _cursor_idx < keys.size():
		var sel_id: String = keys[_cursor_idx]
		var idata: Dictionary = GameData.items_data.get(sel_id, {})
		var desc: String = idata.get("description", "")
		if desc != "":
			y += 4
			_add_line(desc, y, Color(0.5, 0.6, 0.8))

# ── Onglet Pokédex ───────────────────────────────────────────────────────────

func _build_pokedex_tab() -> void:
	var seen := GameState.pokedex_seen.duplicate()
	seen.sort()
	var caught := GameState.pokedex_caught
	_add_line("Vus: %d  Capturés: %d" % [seen.size(), caught.size()], 0, Color(0.6, 0.8, 1.0))
	if seen.is_empty():
		_add_line("Aucun Pokémon vu.", 16, Color.GRAY)
		return
	var y := 16
	var visible_count := 0
	for i in range(_scroll_offset, mini(seen.size(), _scroll_offset + 10)):
		var pid: String = seen[i]
		var pdata: Dictionary = GameData.pokemon_data.get(pid, {})
		var pname: String = pdata.get("name", "#" + pid)
		var types: Array = pdata.get("types", [])
		var is_caught: bool = pid in caught
		var prefix := "▸ " if i == _cursor_idx else "  "
		var icon := "●" if is_caught else "○"
		var col := Color.YELLOW if i == _cursor_idx else (Color(0.5, 1.0, 0.5) if is_caught else Color(0.7, 0.7, 0.7))
		_add_line("%s%s #%s %s  %s" % [prefix, icon, pid, pname, "/".join(types)], y, col)
		y += 12
		visible_count += 1
	if seen.size() > 10:
		_add_line("↑↓ pour défiler (%d/%d)" % [_cursor_idx + 1, seen.size()], y + 4, Color(0.4, 0.4, 0.5))

# ── Onglet Sauver ────────────────────────────────────────────────────────────

func _build_save_tab() -> void:
	_add_line("Appuyez sur Z pour sauvegarder.", 0, Color(1.0, 0.9, 0.5))
	_add_line("Emplacement : Slot 1", 16, Color.GRAY)
	var team_str := ""
	for poke in GameState.team:
		var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
		team_str += pdata.get("name", "?") + " Lv%d  " % poke.level
	if team_str != "":
		_add_line(team_str, 36, Color(0.5, 0.6, 0.8))
	_add_line("Badges: %d  Argent: %d P$" % [GameState.badges.size(), GameState.money], 50, Color(0.5, 0.6, 0.8))

func _execute_tab() -> void:
	match _tab_index:
		0: _action_team()
		1: pass  # Sac: info seulement (utilisation en combat)
		2: pass  # Pokédex: consultatif
		3:
			SaveManager.save_game(0)
			for child in _content.get_children():
				child.queue_free()
			_add_line("Partie sauvegardée !", 0, Color.GREEN)
			_add_line("Emplacement : Slot 1", 16, Color.GRAY)

func _action_team() -> void:
	if GameState.team.is_empty(): return
	if _swap_src >= 0:
		# Permuter
		if _swap_src != _cursor_idx:
			var tmp = GameState.team[_swap_src]
			GameState.team[_swap_src] = GameState.team[_cursor_idx]
			GameState.team[_cursor_idx] = tmp
		_swap_src = -1
		_refresh_content()
	else:
		# Premier appui → ouvrir la fiche résumé
		# Deuxième appui rapide ou si on re-sélectionne → swap mode
		var poke: PokemonInstance = GameState.team[_cursor_idx]
		PokemonSummary.show_summary(poke)

# ── Helper ───────────────────────────────────────────────────────────────────

func _add_line(text: String, y_offset: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(0, y_offset)
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", color)
	_content.add_child(lbl)
