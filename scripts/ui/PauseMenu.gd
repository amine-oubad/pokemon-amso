extends CanvasLayer
## Menu Pause — 4 onglets : Équipe / Sac / Pokédex / Sauver.
## Layer 30. Ouvert par ui_cancel quand aucun autre menu n'est actif.

var _visible_flag := false
var _in_battle    := false
var _tab_index    := 0

var _bg:         ColorRect
var _tab_labels: Array[Label] = []
var _content:    Control

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
	if DialogueManager.is_active(): return
	if ShopMenu.is_active(): return

	if event.is_action_pressed("ui_cancel"):
		if _visible_flag:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()
		return

	if not _visible_flag: return

	if event.is_action_pressed("ui_right"):
		_tab_index = (_tab_index + 1) % TABS.size()
		_refresh_tabs()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_tab_index = (_tab_index - 1 + TABS.size()) % TABS.size()
		_refresh_tabs()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_execute_tab()
		get_viewport().set_input_as_handled()

# ── Public API ───────────────────────────────────────────────────────────────

func show_menu() -> void:
	_visible_flag = true
	_tab_index    = 0
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

	# Titre
	var title := Label.new()
	title.text     = "MENU"
	title.position = Vector2(40, 22)
	title.add_theme_font_size_override("font_size", 8)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	# Onglets
	var tab_x := 42
	for i in TABS.size():
		var lbl := Label.new()
		lbl.text     = TABS[i]
		lbl.position = Vector2(tab_x, 36)
		lbl.add_theme_font_size_override("font_size", 6)
		add_child(lbl)
		_tab_labels.append(lbl)
		tab_x += 58

	# Zone de contenu
	_content = Control.new()
	_content.position = Vector2(44, 52)
	_content.size     = Vector2(232, 160)
	add_child(_content)

# ── Tabs ─────────────────────────────────────────────────────────────────────

func _refresh_tabs() -> void:
	for i in _tab_labels.size():
		if i == _tab_index:
			_tab_labels[i].add_theme_color_override("font_color", Color.YELLOW)
		else:
			_tab_labels[i].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_refresh_content()

func _refresh_content() -> void:
	for child in _content.get_children():
		child.queue_free()

	match _tab_index:
		0: _build_team_tab()
		1: _build_bag_tab()
		2: _build_pokedex_tab()
		3: _build_save_tab()

# ── Onglet Équipe ─────────────────────────────────────────────────────────────

func _build_team_tab() -> void:
	if GameState.team.is_empty():
		_add_line("Aucun Pokémon dans l'équipe.", 0, Color.GRAY)
		return
	var y := 0
	for poke in GameState.team:
		var pdata: Dictionary = GameData.pokemon_data.get(poke.id, {})
		var name_str: String = pdata.get("name", poke.id)
		var hp_str: String   = "%d / %d" % [poke.current_hp, poke.max_hp]
		var lv_str: String   = "Lv%d" % poke.level
		_add_line("%s  %s  PV %s" % [lv_str, name_str, hp_str], y, Color.WHITE)
		y += 14

# ── Onglet Sac ────────────────────────────────────────────────────────────────

func _build_bag_tab() -> void:
	if GameState.bag.is_empty():
		_add_line("Sac vide.", 0, Color.GRAY)
		return
	var y := 0
	for item_id in GameState.bag:
		var qty: int        = GameState.bag[item_id]
		var idata: Dictionary = GameData.items_data.get(item_id, {})
		var item_name: String = idata.get("name", item_id)
		_add_line("× %d  %s" % [qty, item_name], y, Color.WHITE)
		y += 12

# ── Onglet Pokédex ────────────────────────────────────────────────────────────

func _build_pokedex_tab() -> void:
	var seen_count := GameState.pokedex_seen.size()
	var caught_count := GameState.pokedex_caught.size()
	_add_line("Pokémon vus : %d" % seen_count, 0, Color(0.8, 0.9, 1.0))
	_add_line("Pokémon capturés : %d" % caught_count, 14, Color(0.6, 1.0, 0.6))
	if caught_count == 0:
		_add_line("Capturez des Pokémon pour remplir le Pokédex !", 32, Color.GRAY)
		return
	var y := 32
	for pid in GameState.pokedex_caught:
		var pdata: Dictionary = GameData.pokemon_data.get(pid, {})
		var pname: String     = pdata.get("name", "#" + pid)
		_add_line("#%s — %s" % [pid, pname], y, Color.WHITE)
		y += 11
		if y > 140: break

# ── Onglet Sauver ─────────────────────────────────────────────────────────────

func _build_save_tab() -> void:
	_add_line("Appuyez sur Z pour sauvegarder.", 0, Color(1.0, 0.9, 0.5))
	_add_line("Emplacement : Slot 1", 16, Color.GRAY)

func _execute_tab() -> void:
	if _tab_index == 3:
		SaveManager.save_game(0)
		for child in _content.get_children():
			child.queue_free()
		_add_line("Partie sauvegardée !", 0, Color.GREEN)
		_add_line("Emplacement : Slot 1", 16, Color.GRAY)

# ── Helper ───────────────────────────────────────────────────────────────────

func _add_line(text: String, y_offset: int, color: Color) -> void:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(0, y_offset)
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", color)
	_content.add_child(lbl)
