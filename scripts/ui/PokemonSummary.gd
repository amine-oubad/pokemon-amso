extends CanvasLayer
## Fiche résumé d'un Pokémon — stats, moves, type, XP.
## Layer 36. Ouvert depuis PauseMenu ou PCBoxScreen.

var _visible_flag := false
var _pkmn: PokemonInstance = null
var _bg: ColorRect

func _ready() -> void:
	layer = 36
	_build_base()
	_hide()

func show_summary(pkmn: PokemonInstance) -> void:
	_pkmn = pkmn
	_visible_flag = true
	_refresh()
	_bg.show()

func _hide() -> void:
	_visible_flag = false
	_bg.hide()

func is_active() -> bool:
	return _visible_flag

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag: return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_hide()
		get_viewport().set_input_as_handled()

func _build_base() -> void:
	_bg = ColorRect.new()
	_bg.color    = Color(0.04, 0.04, 0.14, 0.97)
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

func _refresh() -> void:
	# Nettoyer les enfants précédents (sauf _bg)
	for child in get_children():
		if child != _bg:
			child.queue_free()

	if _pkmn == null: return

	var pdata: Dictionary = GameData.pokemon_data.get(_pkmn.pokemon_id, {})
	var pname: String = pdata.get("name", _pkmn.pokemon_id)
	var types: Array  = pdata.get("types", ["Normal"])

	# Nom + Niveau
	_lbl(Vector2(6, 4), "%s  Lv.%d" % [pname, _pkmn.level], 10, Color.WHITE)

	# Types
	var type_str := " / ".join(types)
	_lbl(Vector2(6, 20), "Type: %s" % type_str, 7, Color(0.7, 0.8, 1.0))

	# Barre HP
	_lbl(Vector2(6, 34), "PV: %d / %d" % [_pkmn.current_hp, _pkmn.max_hp], 7, Color.WHITE)
	var hp_ratio: float = float(_pkmn.current_hp) / float(_pkmn.max_hp) if _pkmn.max_hp > 0 else 0.0
	_bar(Vector2(6, 46), Vector2(180, 6), hp_ratio,
		Color(0.2, 0.8, 0.2) if hp_ratio > 0.5 else (Color(0.9, 0.75, 0.1) if hp_ratio > 0.25 else Color(0.9, 0.15, 0.15)))

	# XP
	var xp_to_next: int = (_pkmn.level + 1) ** 3
	var xp_this_lv: int = _pkmn.level ** 3
	var xp_progress: float = float(_pkmn.exp - xp_this_lv) / float(max(1, xp_to_next - xp_this_lv))
	_lbl(Vector2(6, 56), "EXP: %d / %d" % [_pkmn.exp, xp_to_next], 6, Color(0.5, 0.7, 1.0))
	_bar(Vector2(6, 66), Vector2(180, 4), clampf(xp_progress, 0.0, 1.0), Color(0.3, 0.5, 1.0))

	# Statut
	if _pkmn.status != "":
		_lbl(Vector2(200, 34), "Statut: %s" % _pkmn.status.to_upper(), 6, Color(0.9, 0.4, 0.3))

	# Stats
	_lbl(Vector2(6, 78), "━━ STATS ━━", 7, Color(0.96, 0.77, 0.18))
	var stats := {
		"PV max": _pkmn.max_hp,
		"Attaque": _pkmn.get_effective_stat("atk"),
		"Défense": _pkmn.get_effective_stat("def"),
		"Atq. Spé": _pkmn.get_effective_stat("sp_atk"),
		"Déf. Spé": _pkmn.get_effective_stat("sp_def"),
		"Vitesse": _pkmn.get_effective_stat("speed"),
	}
	var y := 92
	for stat_name in stats:
		var val: int = stats[stat_name]
		_lbl(Vector2(10, y), "%s" % stat_name, 6, Color(0.7, 0.7, 0.8))
		_lbl(Vector2(80, y), "%d" % val, 6, Color.WHITE)
		# Mini barre (max ~150 pour échelle)
		_bar(Vector2(100, y + 2), Vector2(80, 4), clampf(float(val) / 150.0, 0.0, 1.0), _stat_color(val))
		y += 12

	# Moves
	_lbl(Vector2(6, 170), "━━ CAPACITÉS ━━", 7, Color(0.96, 0.77, 0.18))
	y = 184
	for mv: MoveInstance in _pkmn.moves:
		var mdata: Dictionary = GameData.moves_data.get(mv.move_id, {})
		var mname: String = mdata.get("name", mv.move_id)
		var mtype: String = mdata.get("type", "Normal")
		var power: int    = mdata.get("power", 0)
		var pp_str: String = "%d/%d PP" % [mv.current_pp, mv.max_pp]
		_lbl(Vector2(10, y), mname, 6, Color.WHITE)
		_lbl(Vector2(110, y), mtype, 6, Color(0.6, 0.7, 0.9))
		_lbl(Vector2(170, y), "Pwr:%d" % power if power > 0 else "---", 6, Color(0.8, 0.6, 0.5))
		_lbl(Vector2(220, y), pp_str, 6, Color(0.5, 0.8, 0.5))
		y += 12

	_lbl(Vector2(6, 228), "[X] Fermer", 5, Color(0.4, 0.4, 0.5))

func _lbl(pos: Vector2, text: String, fsize: int, color: Color) -> void:
	var l := Label.new()
	l.text     = text
	l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	add_child(l)

func _bar(pos: Vector2, size: Vector2, ratio: float, color: Color) -> void:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size     = size
	bg.color    = Color(0.15, 0.15, 0.25)
	add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size     = Vector2(size.x * ratio, size.y)
	fill.color    = color
	add_child(fill)

func _stat_color(val: int) -> Color:
	if val >= 100: return Color(0.2, 0.9, 0.3)
	if val >= 70:  return Color(0.5, 0.8, 0.3)
	if val >= 40:  return Color(0.9, 0.8, 0.2)
	return Color(0.9, 0.4, 0.2)
