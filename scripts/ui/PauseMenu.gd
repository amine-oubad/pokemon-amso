extends CanvasLayer
## Menu Pause moderne — 4 onglets : Equipe / Sac / Pokedex / Sauver.
## Layer 30.

const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
var _visible_flag := false
var _in_battle    := false
var _tab_index    := 0
var _cursor_idx   := 0
var _swap_src     := -1

var _bag_target_mode := false
var _bag_selected_item := ""
var _bag_cursor_backup := 0

var _bg:         ColorRect
var _tab_labels: Array[Label] = []
var _content:    Control
var _scroll_offset := 0

const TABS := ["EQUIPE", "SAC", "POKEDEX", "SAUVER"]

const C_BG     := Color(0.06, 0.06, 0.14, 0.95)
const C_PANEL  := Color(0.10, 0.12, 0.22)
const C_BORDER := Color(0.22, 0.25, 0.38)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const C_GOLD   := Color(0.96, 0.80, 0.22)
const C_TEXT   := Color(0.90, 0.90, 0.95)
const C_TEXT2  := Color(0.55, 0.55, 0.68)

func _ready() -> void:
	layer = 30
	_build_ui()
	hide_menu()
	EventBus.battle_started.connect(func(_e, _t): _in_battle = true)
	EventBus.battle_ended.connect(func(_r):       _in_battle = false)

func _unhandled_input(event: InputEvent) -> void:
	if _in_battle: return
	if TitleScreen.is_active(): return
	if PokemonSummary.is_active(): return
	if DialogueManager.is_active(): return
	if ShopMenu.is_active(): return

	if event.is_action_pressed("ui_cancel"):
		if _bag_target_mode:
			_bag_target_mode = false
			_bag_selected_item = ""
			_cursor_idx = _bag_cursor_backup
			_refresh_content()
		elif _swap_src >= 0:
			_swap_src = -1
			_refresh_content()
		elif _visible_flag:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()
		return

	if not _visible_flag: return
	if _bag_target_mode:
		if event.is_action_pressed("ui_down"):
			_move_cursor(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_cursor(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_execute_tab()
			get_viewport().set_input_as_handled()
		return

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
	if _bag_target_mode:
		_cursor_idx = clampi(_cursor_idx + dir, 0, max(0, GameState.team.size() - 1))
		_refresh_content()
		return
	match _tab_index:
		0: _cursor_idx = clampi(_cursor_idx + dir, 0, max(0, GameState.team.size() - 1))
		1:
			var count := GameState.bag.size()
			_cursor_idx = clampi(_cursor_idx + dir, 0, max(0, count - 1))
		2:
			var total := GameState.pokedex_seen.size()
			_cursor_idx = clampi(_cursor_idx + dir, 0, max(0, total - 1))
			if _cursor_idx < _scroll_offset: _scroll_offset = _cursor_idx
			if _cursor_idx >= _scroll_offset + 10: _scroll_offset = _cursor_idx - 9
		3:
			_cursor_idx = clampi(_cursor_idx + dir, 0, SaveManager.NUM_SLOTS - 1)
	_refresh_content()

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

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = C_BG
	_bg.position = Vector2(30, 14)
	_bg.size     = Vector2(260, 212)
	add_child(_bg)

	# Border
	var border := ColorRect.new()
	border.color = C_BORDER
	border.position = Vector2(29, 13)
	border.size = Vector2(262, 214)
	border.z_index = -1
	add_child(border)

	# Top accent
	var accent := ColorRect.new()
	accent.color = C_ACCENT
	accent.position = Vector2(30, 14)
	accent.size = Vector2(260, 2)
	add_child(accent)

	# Tabs
	var tab_x := 36
	for i in TABS.size():
		var lbl := Label.new()
		lbl.text     = TABS[i]
		lbl.position = Vector2(tab_x, 20)
		lbl.add_theme_font_size_override("font_size", 7)
		add_child(lbl)
		_tab_labels.append(lbl)
		tab_x += 64

	# Tab underline
	var tab_line := ColorRect.new()
	tab_line.color = Color(0.18, 0.20, 0.32)
	tab_line.position = Vector2(32, 32)
	tab_line.size = Vector2(256, 1)
	add_child(tab_line)

	_content = Control.new()
	_content.position = Vector2(36, 38)
	_content.size     = Vector2(248, 180)
	add_child(_content)

func _refresh_tabs() -> void:
	for i in _tab_labels.size():
		_tab_labels[i].add_theme_color_override("font_color",
			C_ACCENT if i == _tab_index else C_TEXT2)
	_refresh_content()

func _refresh_content() -> void:
	for child in _content.get_children():
		child.queue_free()
	if _bag_target_mode:
		_build_bag_target_tab()
		return
	match _tab_index:
		0: _build_team_tab()
		1: _build_bag_tab()
		2: _build_pokedex_tab()
		3: _build_save_tab()

# ── Equipe ────────────────────────────────────────────────────────────────────

func _build_team_tab() -> void:
	if GameState.team.is_empty():
		_add_line("Aucun Pokemon dans l'equipe.", 0, C_TEXT2)
		return
	var y := 0
	for i in GameState.team.size():
		var poke: PokemonInstance = GameState.team[i]
		var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
		var name_str: String = pdata.get("name", poke.pokemon_id)
		var hp_str: String   = "%d/%d" % [poke.current_hp, poke.max_hp]

		# Row background
		var row_col := Color(0.14, 0.18, 0.32) if i == _cursor_idx else Color(0.08, 0.08, 0.16)
		if _swap_src == i: row_col = Color(0.20, 0.14, 0.10)
		var row := ColorRect.new()
		row.position = Vector2(0, y)
		row.size = Vector2(240, 22)
		row.color = row_col
		_content.add_child(row)

		# Pokemon mini sprite
		var icon := SpriteLoader.make_sprite(poke.pokemon_id, "front", Vector2(16, 16))
		icon.position = Vector2(2, 3)
		row.add_child(icon)

		var prefix := ""
		if _swap_src == i: prefix = ">> "
		elif i == _cursor_idx: prefix = "> "
		var col := C_GOLD if i == _cursor_idx else C_TEXT
		if poke.is_fainted(): col = Color(0.5, 0.25, 0.25)

		var lbl := Label.new()
		lbl.text = "%s%s Lv%d  PV %s" % [prefix, name_str, poke.level, hp_str]
		lbl.position = Vector2(20, 3)
		lbl.add_theme_font_size_override("font_size", 6)
		lbl.add_theme_color_override("font_color", col)
		row.add_child(lbl)

		# Mini HP bar
		var hp_ratio := float(poke.current_hp) / float(poke.max_hp) if poke.max_hp > 0 else 0.0
		var hpbg := ColorRect.new()
		hpbg.position = Vector2(180, 8)
		hpbg.size = Vector2(54, 3)
		hpbg.color = Color(0.06, 0.06, 0.12)
		row.add_child(hpbg)
		var hpfill := ColorRect.new()
		hpfill.position = Vector2(180, 8)
		hpfill.size = Vector2(54.0 * hp_ratio, 3)
		hpfill.color = _hp_col(hp_ratio)
		row.add_child(hpfill)

		y += 24
	y += 4
	if _swap_src >= 0:
		_add_line("[Z] Permuter  [X] Annuler", y, Color(0.4, 0.7, 0.4))
	else:
		_add_line("[Z] Fiche / [Z+Z] Permuter", y, C_TEXT2)

# ── Sac ──────────────────────────────────────────────────────────────────────

func _build_bag_tab() -> void:
	if GameState.bag.is_empty():
		_add_line("Sac vide.", 0, C_TEXT2)
		return
	var keys: Array = GameState.bag.keys()
	var y := 0
	for i in keys.size():
		var item_id: String   = keys[i]
		var qty: int          = GameState.bag[item_id]
		var idata: Dictionary = GameData.items_data.get(item_id, {})
		var item_name: String = idata.get("name", item_id)
		var prefix := "> " if i == _cursor_idx else "  "
		var col := C_GOLD if i == _cursor_idx else C_TEXT
		_add_line("%sx%d  %s" % [prefix, qty, item_name], y, col)
		y += 12
	if _cursor_idx < keys.size():
		var sel_id: String = keys[_cursor_idx]
		var idata: Dictionary = GameData.items_data.get(sel_id, {})
		var desc: String = idata.get("description", "")
		if desc != "":
			y += 4
			_add_line(desc, y, C_ACCENT)

# ── Pokedex ──────────────────────────────────────────────────────────────────

func _build_pokedex_tab() -> void:
	var seen: Array = GameState.pokedex_seen.duplicate()
	seen.sort()
	var caught: Array = GameState.pokedex_caught
	_add_line("Vus: %d  Captures: %d" % [seen.size(), caught.size()], 0, C_ACCENT)
	if seen.is_empty():
		_add_line("Aucun Pokemon vu.", 16, C_TEXT2)
		return
	var y := 16
	for i in range(_scroll_offset, mini(seen.size(), _scroll_offset + 10)):
		var pid: String = seen[i]
		var pdata: Dictionary = GameData.pokemon_data.get(pid, {})
		var pname: String = pdata.get("name", "#" + pid)
		var types: Array = pdata.get("types", [])
		var is_caught: bool = pid in caught
		var prefix := "> " if i == _cursor_idx else "  "
		var icon_char := "O" if is_caught else "o"
		var col := C_GOLD if i == _cursor_idx else (Color(0.4, 0.9, 0.4) if is_caught else C_TEXT2)
		_add_line("%s%s #%s %s  %s" % [prefix, icon_char, pid, pname, "/".join(types)], y, col)
		y += 12
	if seen.size() > 10:
		_add_line("[^][v] defiler (%d/%d)" % [_cursor_idx + 1, seen.size()], y + 4, C_TEXT2)

# ── Sauver ──────────────────────────────────────────────────────────────────

func _build_save_tab() -> void:
	_add_line("[Z] Sauvegarder   [^][v] Choisir slot", 0, C_GOLD)
	for i in SaveManager.NUM_SLOTS:
		var prefix := "> " if i == _cursor_idx else "  "
		var col := C_ACCENT if i == _cursor_idx else C_TEXT2
		if SaveManager.has_save(i):
			var info: Dictionary = SaveManager.get_save_info(i)
			_add_line("%sSlot %d — %s  Badges:%d  Equipe:%d" % [
				prefix, i + 1, info.get("player_name", "?"),
				info.get("badges", 0), info.get("team_size", 0)
			], 16 + i * 14, col)
		else:
			_add_line("%sSlot %d — Vide" % [prefix, i + 1], 16 + i * 14, col)
	var y := 16 + SaveManager.NUM_SLOTS * 14 + 6
	var team_str := ""
	for poke: PokemonInstance in GameState.team:
		var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
		team_str += pdata.get("name", "?") + " Lv%d  " % poke.level
	if team_str != "":
		_add_line(team_str, y, C_TEXT)
		y += 14
	_add_line("Badges: %d  Argent: %d P$" % [GameState.badges.size(), GameState.money], y, C_ACCENT)

func _execute_tab() -> void:
	if _bag_target_mode:
		_apply_bag_item()
		return
	match _tab_index:
		0: _action_team()
		1: _action_bag()
		2: pass
		3:
			var slot := clampi(_cursor_idx, 0, SaveManager.NUM_SLOTS - 1)
			SaveManager.save(slot)
			for child in _content.get_children():
				child.queue_free()
			_add_line("Partie sauvegardee !", 0, Color(0.3, 0.9, 0.3))
			_add_line("Emplacement : Slot %d" % (slot + 1), 16, C_TEXT2)

func _action_team() -> void:
	if GameState.team.is_empty(): return
	if _swap_src >= 0:
		if _swap_src != _cursor_idx:
			var tmp: PokemonInstance = GameState.team[_swap_src]
			GameState.team[_swap_src] = GameState.team[_cursor_idx]
			GameState.team[_cursor_idx] = tmp
		_swap_src = -1
		_refresh_content()
	else:
		var poke: PokemonInstance = GameState.team[_cursor_idx]
		PokemonSummary.show_summary(poke)

# ── Sac — utilisation d'items ────────────────────────────────────────────

func _action_bag() -> void:
	var keys: Array = GameState.bag.keys()
	if _cursor_idx >= keys.size(): return
	var item_id: String = keys[_cursor_idx]
	var idata: Dictionary = GameData.items_data.get(item_id, {})
	var cat: String = idata.get("category", "")
	if cat in ["heal", "status_cure", "revive"]:
		_bag_selected_item = item_id
		_bag_cursor_backup = _cursor_idx
		_bag_target_mode = true
		_cursor_idx = 0
		_refresh_content()
	elif cat == "repel":
		GameState.remove_item(item_id)
		var steps: int = idata.get("steps", 100)
		GameState.repel_steps = steps
		_refresh_content()
		for child in _content.get_children():
			child.queue_free()
		_add_line("Repousse active !", 0, Color(0.3, 0.9, 0.3))
		_add_line("%d pas restants." % steps, 14, Color(0.4, 0.7, 0.4))
	else:
		for child in _content.get_children():
			child.queue_free()
		_add_line("Cet objet ne peut pas", 0, Color(0.8, 0.4, 0.4))
		_add_line("etre utilise ici.", 14, Color(0.8, 0.4, 0.4))

func _apply_bag_item() -> void:
	if _cursor_idx >= GameState.team.size(): return
	var poke: PokemonInstance = GameState.team[_cursor_idx]
	var idata: Dictionary = GameData.items_data.get(_bag_selected_item, {})
	var cat: String = idata.get("category", "")
	var used := false
	var msg := ""

	match cat:
		"heal":
			if poke.is_fainted():
				msg = "Ce Pokemon est K.O. !"
			elif poke.current_hp >= poke.max_hp:
				var cures: Array = idata.get("cures", [])
				if not cures.is_empty() and poke.status in cures:
					poke.status = ""
					poke.status_turns = 0
					used = true
					msg = "%s est gueri !" % poke.get_name()
				else:
					msg = "PV deja au max !"
			else:
				var healed: int = poke.heal(idata.get("heal_amount", 20))
				var cures: Array = idata.get("cures", [])
				if not cures.is_empty() and poke.status in cures:
					poke.status = ""
					poke.status_turns = 0
				used = true
				msg = "%s recupere %d PV !" % [poke.get_name(), healed]
		"status_cure":
			if poke.is_fainted():
				msg = "Ce Pokemon est K.O. !"
			else:
				var cures: Array = idata.get("cures", [])
				if poke.status in cures:
					poke.status = ""
					poke.status_turns = 0
					used = true
					msg = "%s est gueri !" % poke.get_name()
				else:
					msg = "Sans effet sur ce Pokemon."
		"revive":
			if not poke.is_fainted():
				msg = "Ce Pokemon n'est pas K.O. !"
			else:
				poke.current_hp = poke.max_hp / 2
				used = true
				msg = "%s est ranime !" % poke.get_name()

	if used:
		GameState.remove_item(_bag_selected_item)

	_bag_target_mode = false
	_bag_selected_item = ""
	_cursor_idx = _bag_cursor_backup
	_refresh_content()
	for child in _content.get_children():
		child.queue_free()
	_add_line(msg, 0, Color(0.3, 0.9, 0.3) if used else Color(0.8, 0.4, 0.4))

func _build_bag_target_tab() -> void:
	var idata: Dictionary = GameData.items_data.get(_bag_selected_item, {})
	var item_name: String = idata.get("name", _bag_selected_item)
	_add_line("Utiliser %s sur :" % item_name, 0, C_ACCENT)
	var y := 16
	for i in GameState.team.size():
		var poke: PokemonInstance = GameState.team[i]
		var pdata: Dictionary = GameData.pokemon_data.get(poke.pokemon_id, {})
		var name_str: String = pdata.get("name", poke.pokemon_id)
		var hp_str: String = "%d/%d" % [poke.current_hp, poke.max_hp]
		var prefix := "> " if i == _cursor_idx else "  "
		var col := C_GOLD if i == _cursor_idx else C_TEXT
		if poke.is_fainted(): col = Color(0.5, 0.25, 0.25) if i != _cursor_idx else Color(0.7, 0.4, 0.25)
		var status_str := ""
		if poke.status != "": status_str = " [%s]" % poke.status.to_upper()
		_add_line("%s%s Lv%d  PV %s%s" % [prefix, name_str, poke.level, hp_str, status_str], y, col)
		y += 14
	_add_line("[Z] Utiliser  [X] Retour", y + 4, Color(0.4, 0.7, 0.4))

func _add_line(text: String, y_offset: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(0, y_offset)
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", color)
	_content.add_child(lbl)

func _hp_col(r: float) -> Color:
	if r > 0.50: return Color(0.20, 0.85, 0.40)
	if r > 0.25: return Color(0.95, 0.75, 0.10)
	return Color(0.95, 0.22, 0.15)
