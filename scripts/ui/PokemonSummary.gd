extends CanvasLayer
## Fiche resume d'un Pokemon — style moderne avec artwork.
## Layer 36. Ouvert depuis PauseMenu ou PCBoxScreen.

const MoveEffects = preload("res://scripts/battle/MoveEffects.gd")
const MoveInstance = preload("res://scripts/data/MoveInstance.gd")
const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
var _visible_flag := false
var _pkmn: PokemonInstance = null
var _bg: ColorRect

const C_BG     := Color(0.06, 0.06, 0.14)
const C_PANEL  := Color(0.12, 0.14, 0.24)
const C_BORDER := Color(0.22, 0.25, 0.38)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const C_TEXT   := Color(0.92, 0.92, 0.96)
const C_TEXT2  := Color(0.55, 0.55, 0.68)
const C_GOLD   := Color(0.96, 0.80, 0.22)

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
	_bg.color    = C_BG
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

func _refresh() -> void:
	for child in get_children():
		if child != _bg:
			child.queue_free()

	if _pkmn == null: return

	var pdata: Dictionary = GameData.pokemon_data.get(_pkmn.pokemon_id, {})
	var pname: String = pdata.get("name", _pkmn.pokemon_id)
	var types: Array  = pdata.get("types", ["Normal"])

	# Top accent line
	_rect(Vector2(0, 0), Vector2(320, 2), C_ACCENT)

	# Left panel — artwork + basic info
	_rect(Vector2(4, 6), Vector2(104, 150), C_PANEL)
	_rect(Vector2(3, 5), Vector2(106, 152), C_BORDER)  # border behind
	# Move border behind
	var border_node := get_children()[-1]
	border_node.z_index = -1

	# Artwork sprite
	var artwork := SpriteLoader.make_sprite(_pkmn.pokemon_id, "artwork", Vector2(88, 88))
	artwork.position = Vector2(12, 10)
	add_child(artwork)

	# Name + Level
	_lbl(Vector2(10, 100), pname, 9, C_TEXT)
	_lbl(Vector2(72, 100), "Lv.%d" % _pkmn.level, 9, C_ACCENT)

	# Types badges
	var tx := 10
	for t in types:
		var tcol: Color = _type_col(t)
		_rect(Vector2(tx, 116), Vector2(42, 11), tcol.darkened(0.3))
		_lbl(Vector2(tx + 2, 115), t.to_upper(), 5, Color.WHITE)
		tx += 46

	# HP bar
	_lbl(Vector2(10, 130), "PV", 6, C_TEXT2)
	var hp_ratio: float = float(_pkmn.current_hp) / float(_pkmn.max_hp) if _pkmn.max_hp > 0 else 0.0
	_rect(Vector2(26, 134), Vector2(76, 5), Color(0.08, 0.08, 0.14))
	_rect(Vector2(26, 134), Vector2(76.0 * hp_ratio, 5), _hp_col(hp_ratio))
	_lbl(Vector2(26, 140), "%d / %d" % [_pkmn.current_hp, _pkmn.max_hp], 6, C_TEXT)

	# Status
	if _pkmn.status != "":
		var scol: Color = MoveEffects.STATUS_COLOR.get(_pkmn.status, Color.GRAY)
		_rect(Vector2(72, 130), Vector2(30, 11), scol.darkened(0.3))
		var sabbr: String = MoveEffects.STATUS_ABBR.get(_pkmn.status, "???")
		_lbl(Vector2(74, 129), sabbr, 5, Color.WHITE)

	# Right panel — Stats
	_rect(Vector2(114, 6), Vector2(202, 90), C_PANEL)
	_rect(Vector2(113, 5), Vector2(204, 92), C_BORDER)
	get_children()[-1].z_index = -1

	_lbl(Vector2(120, 8), "STATS", 7, C_GOLD)

	var stats := {
		"PV max": _pkmn.max_hp,
		"Attaque": _pkmn.get_effective_stat("atk"),
		"Defense": _pkmn.get_effective_stat("def"),
		"Atq. Spe": _pkmn.get_effective_stat("sp_atk"),
		"Def. Spe": _pkmn.get_effective_stat("sp_def"),
		"Vitesse": _pkmn.get_effective_stat("speed"),
	}
	var y := 22
	for stat_name in stats:
		var val: int = stats[stat_name]
		_lbl(Vector2(120, y), stat_name, 6, C_TEXT2)
		_lbl(Vector2(186, y), "%d" % val, 6, C_TEXT)
		# Stat bar
		_rect(Vector2(206, y + 3), Vector2(100, 3), Color(0.08, 0.08, 0.14))
		_rect(Vector2(206, y + 3), Vector2(100.0 * clampf(float(val) / 150.0, 0.0, 1.0), 3), _stat_color(val))
		y += 11

	# XP panel
	_rect(Vector2(114, 100), Vector2(202, 24), C_PANEL)
	_rect(Vector2(113, 99), Vector2(204, 26), C_BORDER)
	get_children()[-1].z_index = -1

	var xp_to_next: int = (_pkmn.level + 1) ** 3
	var xp_this_lv: int = _pkmn.level ** 3
	var xp_progress: float = float(_pkmn.exp - xp_this_lv) / float(max(1, xp_to_next - xp_this_lv))
	_lbl(Vector2(120, 102), "EXP", 6, C_TEXT2)
	_lbl(Vector2(148, 102), "%d / %d" % [_pkmn.exp, xp_to_next], 6, C_ACCENT)
	_rect(Vector2(120, 114), Vector2(188, 3), Color(0.08, 0.08, 0.14))
	_rect(Vector2(120, 114), Vector2(188.0 * clampf(xp_progress, 0.0, 1.0), 3), C_ACCENT)

	# Moves panel
	_rect(Vector2(114, 130), Vector2(202, 80), C_PANEL)
	_rect(Vector2(113, 129), Vector2(204, 82), C_BORDER)
	get_children()[-1].z_index = -1

	_lbl(Vector2(120, 132), "CAPACITES", 7, C_GOLD)
	y = 144
	for mv: MoveInstance in _pkmn.moves:
		var mdata: Dictionary = GameData.moves_data.get(mv.move_id, {})
		var mname: String = mdata.get("name", mv.move_id)
		var mtype: String = mdata.get("type", "Normal")
		var power: int    = mdata.get("power", 0)
		var pp_str: String = "%d/%d" % [mv.current_pp, mv.max_pp]
		# Type badge
		_rect(Vector2(120, y + 1), Vector2(30, 10), _type_col(mtype).darkened(0.4))
		_lbl(Vector2(122, y), mtype.substr(0, 4).to_upper(), 5, Color.WHITE)
		_lbl(Vector2(154, y), mname, 6, C_TEXT)
		_lbl(Vector2(244, y), "Pw:%d" % power if power > 0 else "---", 5, C_TEXT2)
		_lbl(Vector2(280, y), pp_str, 5, Color(0.4, 0.75, 0.4))
		y += 13

	# Close hint
	_lbl(Vector2(6, 230), "[X] Fermer", 5, Color(0.30, 0.30, 0.42))

func _lbl(pos: Vector2, text: String, fsize: int, color: Color) -> void:
	var l := Label.new()
	l.text     = text
	l.position = pos
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	add_child(l)

func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size     = size
	r.color    = color
	add_child(r)
	return r

func _hp_col(r: float) -> Color:
	if r > 0.50: return Color(0.20, 0.85, 0.40)
	if r > 0.25: return Color(0.95, 0.75, 0.10)
	return Color(0.95, 0.22, 0.15)

func _stat_color(val: int) -> Color:
	if val >= 100: return Color(0.2, 0.9, 0.3)
	if val >= 70:  return Color(0.5, 0.8, 0.3)
	if val >= 40:  return Color(0.9, 0.8, 0.2)
	return Color(0.9, 0.4, 0.2)

func _type_col(t: String) -> Color:
	const C := { "Fire":Color(0.9,0.35,0.1),"Water":Color(0.25,0.55,0.95),"Grass":Color(0.3,0.75,0.3),
		"Electric":Color(0.95,0.85,0.1),"Psychic":Color(0.9,0.2,0.55),"Ice":Color(0.6,0.85,0.95),
		"Dragon":Color(0.4,0.2,0.9),"Dark":Color(0.3,0.2,0.15),"Fairy":Color(0.95,0.6,0.8),
		"Fighting":Color(0.7,0.2,0.15),"Poison":Color(0.55,0.2,0.65),"Ground":Color(0.85,0.7,0.35),
		"Flying":Color(0.6,0.7,0.95),"Bug":Color(0.6,0.75,0.1),"Rock":Color(0.6,0.55,0.3),
		"Ghost":Color(0.35,0.25,0.55),"Steel":Color(0.7,0.7,0.8),"Normal":Color(0.65,0.65,0.6) }
	return C.get(t, Color(0.65, 0.65, 0.6))
