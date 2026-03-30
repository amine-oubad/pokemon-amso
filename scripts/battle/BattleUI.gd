class_name BattleUI
extends Node
## Construction et mise a jour de l'interface de combat.
## Enfant de BattleScene.

var scene  # Reference to BattleScene

# -- Constantes UI (Modern Clean) -----------------------------------------
const C_BG     := Color(0.12, 0.14, 0.22)
const C_DARK   := Color(0.08, 0.08, 0.14)
const C_PANEL  := Color(0.16, 0.18, 0.28)
const C_BORDER := Color(0.28, 0.32, 0.45)
const C_HP_BG  := Color(0.10, 0.10, 0.18)
const C_TEXT   := Color(0.92, 0.92, 0.96)
const C_TEXT2  := Color(0.60, 0.62, 0.72)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const HP_W     := 100

# -- UI nodes -------------------------------------------------------------
var _msg_label:       Label
var _enemy_name:      Label
var _enemy_level:     Label
var _enemy_hp_fill:   ColorRect
var _enemy_status:    Label
var _enemy_ability:   Label
var _player_name:     Label
var _player_level:    Label
var _player_hp_fill:  ColorRect
var _player_hp_text:  Label
var _player_status:   Label
var _player_item:     Label
var action_menu:      Control
var move_menu:        Control
var item_menu:        Control
var pkmn_menu:        Control
var _move_buttons:    Array[Button] = []
var _enemy_sprite_node: Control
var _player_sprite_node: Control
var _enemy_sprite_container: Control
var _player_sprite_container: Control
var _cancel_learn_btn: Button = null
var _weather_label:   Label

# =========================================================================
#  Construction UI
# =========================================================================

func build_ui() -> void:
	var layer := CanvasLayer.new()
	scene.add_child(layer)

	# Background
	_add_rect(layer, Vector2.ZERO, Vector2(320, 120), Color(0.10, 0.12, 0.20))
	_add_rect(layer, Vector2(0, 120), Vector2(320, 60), Color(0.14, 0.16, 0.26))
	_add_rect(layer, Vector2(0, 180), Vector2(320, 60), C_DARK)

	# Ground line
	_add_rect(layer, Vector2(0, 156), Vector2(320, 2), Color(0.22, 0.25, 0.38))
	_add_rect(layer, Vector2(0, 158), Vector2(320, 18), Color(0.11, 0.13, 0.22, 0.6))

	# -- Enemy sprite area --
	_enemy_sprite_container = Control.new()
	_enemy_sprite_container.position = Vector2(8, 4)
	_enemy_sprite_container.size = Vector2(88, 88)
	layer.add_child(_enemy_sprite_container)
	_add_rect(_enemy_sprite_container, Vector2(4, 48), Vector2(80, 6), Color(0.2, 0.2, 0.3, 0.5))

	# -- Enemy info panel --
	var ep := _add_modern_panel(layer, Vector2(104, 8), Vector2(212, 54))
	_enemy_name   = _add_label(ep, Vector2(8, 4),  "...", 9)
	_enemy_name.add_theme_color_override("font_color", C_TEXT)
	_enemy_level  = _add_label(ep, Vector2(160, 4), "Lv?", 9)
	_enemy_level.add_theme_color_override("font_color", C_ACCENT)
	_enemy_status = _add_label(ep, Vector2(160, 18), "", 7)
	var hp_lbl_e := _add_label(ep, Vector2(8, 24), "HP", 7)
	hp_lbl_e.add_theme_color_override("font_color", C_TEXT2)
	_add_rect(ep, Vector2(26, 28), Vector2(HP_W, 6), C_HP_BG)
	_enemy_hp_fill = _add_rect(ep, Vector2(26, 28), Vector2(HP_W, 6), Color(0.2, 0.85, 0.4))
	_enemy_ability = _add_label(ep, Vector2(8, 40), "", 6)
	_enemy_ability.add_theme_color_override("font_color", C_TEXT2)

	# -- Player sprite area --
	_player_sprite_container = Control.new()
	_player_sprite_container.position = Vector2(220, 68)
	_player_sprite_container.size = Vector2(92, 92)
	layer.add_child(_player_sprite_container)
	_add_rect(_player_sprite_container, Vector2(6, 70), Vector2(80, 6), Color(0.15, 0.15, 0.25, 0.5))

	# -- Player info panel --
	var pp := _add_modern_panel(layer, Vector2(4, 96), Vector2(210, 66))
	_player_name   = _add_label(pp, Vector2(8, 4),  "...", 9)
	_player_name.add_theme_color_override("font_color", C_TEXT)
	_player_level  = _add_label(pp, Vector2(156, 4), "Lv?", 9)
	_player_level.add_theme_color_override("font_color", C_ACCENT)
	_player_status = _add_label(pp, Vector2(156, 18), "", 7)
	var hp_lbl_p := _add_label(pp, Vector2(8, 24), "HP", 7)
	hp_lbl_p.add_theme_color_override("font_color", C_TEXT2)
	_add_rect(pp, Vector2(26, 28), Vector2(HP_W, 6), C_HP_BG)
	_player_hp_fill = _add_rect(pp, Vector2(26, 28), Vector2(HP_W, 6), Color(0.2, 0.85, 0.4))
	_player_hp_text = _add_label(pp, Vector2(130, 24), "?/?", 8)
	_player_hp_text.add_theme_color_override("font_color", C_TEXT)
	# XP bar
	_add_rect(pp, Vector2(26, 38), Vector2(HP_W, 3), Color(0.08, 0.08, 0.14))
	var xp_fill := _add_rect(pp, Vector2(26, 38), Vector2(0, 3), Color(0.3, 0.5, 0.95))
	xp_fill.name = "XPFill"
	# Held item indicator
	_player_item = _add_label(pp, Vector2(8, 50), "", 6)
	_player_item.add_theme_color_override("font_color", Color(0.8, 0.7, 0.4))

	# -- Weather indicator --
	_weather_label = _add_label(layer, Vector2(130, 65), "", 7)
	_weather_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))

	# -- Message box --
	_add_rect(layer, Vector2(0, 175), Vector2(320, 1), C_BORDER)
	var mbox := _add_rect(layer, Vector2(0, 176), Vector2(320, 64), C_DARK)
	_add_rect(mbox, Vector2(0, 0), Vector2(4, 64), C_ACCENT)
	_msg_label = _add_label(mbox, Vector2(12, 8), "...", 9)
	_msg_label.size = Vector2(194, 52)
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_label.add_theme_color_override("font_color", C_TEXT)

	# -- Action menu --
	action_menu = _add_overlay(layer, Vector2(210, 178), Vector2(108, 60))
	var a_atk := _make_btn(action_menu, Vector2(0, 0),  Vector2(106, 18), "ATTAQUER")
	a_atk.pressed.connect(func(): scene._on_attack())
	var a_bag := _make_btn(action_menu, Vector2(0, 20), Vector2(106, 18), "SAC")
	a_bag.pressed.connect(func(): scene._on_bag())
	var a_sw  := _make_btn(action_menu, Vector2(0, 40), Vector2(52, 18), "SWITCH")
	a_sw.pressed.connect(func(): scene._on_switch_btn())
	var flee_btn := _make_btn(action_menu, Vector2(54, 40), Vector2(52, 18), "FUIR")
	flee_btn.pressed.connect(func(): scene._on_flee())

	# -- Move menu (2x2 grid) --
	move_menu = _add_overlay(layer, Vector2(2, 176), Vector2(316, 62))
	var mpos := [Vector2(0,2), Vector2(158,2), Vector2(0,32), Vector2(158,32)]
	for i in range(4):
		var btn := _make_btn(move_menu, mpos[i], Vector2(156, 28), "-")
		btn.add_theme_font_size_override("font_size", 8)
		var idx := i
		btn.pressed.connect(func(): scene._on_move(idx))
		_move_buttons.append(btn)

	# -- Item menu --
	item_menu = _add_modern_panel(layer, Vector2(4, 100), Vector2(204, 72))
	var item_title := _add_label(item_menu, Vector2(6, 2), "SAC", 8)
	item_title.add_theme_color_override("font_color", C_ACCENT)

	# -- Pokemon menu --
	pkmn_menu = _add_modern_panel(layer, Vector2(4, 4), Vector2(210, 170))
	var pkmn_title := _add_label(pkmn_menu, Vector2(6, 2), "EQUIPE", 8)
	pkmn_title.add_theme_color_override("font_color", C_ACCENT)

# =========================================================================
#  Refresh / Update
# =========================================================================

func msg(text: String) -> void:
	_msg_label.text = text

func refresh() -> void:
	var enemy = scene.enemy_pkmn
	var player = scene.player_pkmn

	# Enemy
	_enemy_name.text  = enemy.get_name().to_upper()
	_enemy_level.text = "Lv%d" % enemy.level
	var er := maxf(0.0, float(enemy.current_hp) / float(enemy.max_hp))
	_enemy_hp_fill.size  = Vector2(int(HP_W * er), _enemy_hp_fill.size.y)
	_enemy_hp_fill.color = _hp_color(er)
	_set_status_tag(_enemy_status, enemy.status)
	if enemy.ability != "":
		_enemy_ability.text = AbilityEffects.get_ability_name(enemy.ability)
	else:
		_enemy_ability.text = ""

	# Player
	_player_name.text  = player.get_name().to_upper()
	_player_level.text = "Lv%d" % player.level
	var pr := maxf(0.0, float(player.current_hp) / float(player.max_hp))
	_player_hp_fill.size  = Vector2(int(HP_W * pr), _player_hp_fill.size.y)
	_player_hp_fill.color = _hp_color(pr)
	_player_hp_text.text  = "%d/%d" % [player.current_hp, player.max_hp]
	_set_status_tag(_player_status, player.status)
	if player.held_item != "":
		_player_item.text = HeldItemEffects.get_item_name(player.held_item)
	else:
		_player_item.text = ""

	# Weather
	_update_weather_label()

	# Sprites
	_refresh_pokemon_sprites()

func _update_weather_label() -> void:
	if scene.field == null:
		_weather_label.text = ""
		return
	match scene.field.weather:
		BattleField.Weather.RAIN:      _weather_label.text = "Pluie"
		BattleField.Weather.SUN:       _weather_label.text = "Soleil"
		BattleField.Weather.SANDSTORM: _weather_label.text = "Sable"
		BattleField.Weather.HAIL:      _weather_label.text = "Grele"
		_: _weather_label.text = ""

func hide_all_menus() -> void:
	action_menu.visible = false
	move_menu.visible   = false
	item_menu.visible   = false
	pkmn_menu.visible   = false

func _set_status_tag(lbl: Label, status: String) -> void:
	if status == "":
		lbl.text = ""; lbl.visible = false; return
	lbl.text    = MoveEffects.STATUS_ABBR.get(status, "???")
	lbl.add_theme_color_override("font_color", MoveEffects.STATUS_COLOR.get(status, Color.GRAY))
	lbl.visible = true

func refresh_move_buttons() -> void:
	var player = scene.player_pkmn
	for i in range(4):
		var btn: Button = _move_buttons[i]
		if i < player.moves.size():
			var mv: MoveInstance = player.moves[i]
			var type_clr := _type_col(mv.get_type())
			btn.text    = "%s  %s\n%d/%d PP" % [mv.get_name(), mv.get_type(), mv.current_pp, mv.max_pp]
			btn.disabled = not mv.is_usable()
			# Disable if taunted and status move
			if player.has_bmeta("taunted") and mv.get_category() == "status":
				btn.disabled = true
			# Disable if disabled
			if player.has_bmeta("disabled_move") and mv.move_id == player.get_bmeta("disabled_move", ""):
				btn.disabled = true
			btn.visible  = true
		else:
			btn.visible = false

func _hp_color(r: float) -> Color:
	if r > 0.50: return Color(0.20, 0.85, 0.40)
	if r > 0.20: return Color(0.95, 0.75, 0.10)
	return Color(0.95, 0.22, 0.15)

func _refresh_pokemon_sprites() -> void:
	if _enemy_sprite_node != null:
		_enemy_sprite_node.queue_free()
	_enemy_sprite_node = SpriteLoader.make_sprite(scene.enemy_pkmn.pokemon_id, "front", Vector2(80, 80))
	_enemy_sprite_node.position = Vector2(4, 4)
	_enemy_sprite_container.add_child(_enemy_sprite_node)

	if _player_sprite_node != null:
		_player_sprite_node.queue_free()
	_player_sprite_node = SpriteLoader.make_sprite(scene.player_pkmn.pokemon_id, "back", Vector2(80, 80))
	_player_sprite_node.position = Vector2(6, -4)
	_player_sprite_container.add_child(_player_sprite_node)

# =========================================================================
#  Menus dynamiques
# =========================================================================

func populate_item_menu() -> void:
	for c in item_menu.get_children(): c.queue_free()
	# Re-add title
	var title := _add_label(item_menu, Vector2(6, 2), "SAC", 8)
	title.add_theme_color_override("font_color", C_ACCENT)

	var y := 16
	var found := false
	for item_id in GameState.bag:
		if GameState.bag[item_id] <= 0: continue
		var idata: Dictionary = GameData.items_data.get(item_id, {})
		if idata.is_empty(): continue
		var cat: String = idata.get("category", "")
		if cat not in ["heal", "ball", "status_cure", "revive"]: continue
		found = true
		var btn := _make_btn(item_menu, Vector2(2, y), Vector2(196, 18),
			"%s   x%d" % [idata.get("name", item_id), GameState.bag[item_id]])
		var disable := false
		if cat == "heal":
			var hp_full: bool = scene.player_pkmn.current_hp >= scene.player_pkmn.max_hp
			var has_curable_status := false
			var cures: Array = idata.get("cures", [])
			if not cures.is_empty() and scene.player_pkmn.status in cures:
				has_curable_status = true
			disable = hp_full and not has_curable_status
		if cat == "ball" and scene._is_trainer_battle:
			disable = true
		btn.disabled = disable
		var id: String = item_id
		btn.pressed.connect(func(): scene._on_item_used(id))
		y += 20
	if not found:
		var lbl := _add_label(item_menu, Vector2(8, 20), "Sac vide !", 9)
		lbl.add_theme_color_override("font_color", C_DARK)

func populate_pkmn_menu() -> void:
	for c in pkmn_menu.get_children(): c.queue_free()
	# Re-add title
	var title := _add_label(pkmn_menu, Vector2(6, 2), "EQUIPE", 8)
	title.add_theme_color_override("font_color", C_ACCENT)

	var y := 16
	for i in range(GameState.team.size()):
		var pk: PokemonInstance = GameState.team[i]
		var is_active: bool = i == scene._active_idx
		var is_faint  := pk.is_fainted()
		var bg := _add_rect(pkmn_menu, Vector2(2, y), Vector2(200, 28),
			Color(0.22, 0.26, 0.40) if is_active else (Color(0.12, 0.12, 0.18) if is_faint else C_PANEL))
		var name_text := pk.get_name().to_upper()
		if is_active: name_text += " <"
		if pk.held_item != "": name_text += " [%s]" % HeldItemEffects.get_item_name(pk.held_item)
		_add_label(bg, Vector2(4, 2), name_text, 7)
		var hp_r := maxf(0.0, float(pk.current_hp) / float(pk.max_hp))
		var hp_bg := _add_rect(bg, Vector2(4, 14), Vector2(80, 6), C_HP_BG)
		_add_rect(hp_bg, Vector2(0, 0), Vector2(int(80 * hp_r), 6), _hp_color(hp_r))
		_add_label(bg, Vector2(88, 12), "%d/%d" % [pk.current_hp, pk.max_hp], 7)
		if not is_active and not is_faint:
			var btn := Button.new()
			btn.position = Vector2(2, y); btn.size = Vector2(196, 28)
			btn.modulate.a = 0.0
			var idx := i
			btn.pressed.connect(func(): scene._on_switch_pkmn(idx))
			pkmn_menu.add_child(btn)
		y += 30

# =========================================================================
#  Move learning UI
# =========================================================================

func show_move_replace_menu(new_move_id: String) -> void:
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)

	move_menu.visible = true
	for i in range(4):
		var btn: Button = _move_buttons[i]
		if i < scene.player_pkmn.moves.size():
			var mv: MoveInstance = scene.player_pkmn.moves[i]
			btn.text = "%s\n%d/%d PP" % [mv.get_name(), mv.current_pp, mv.max_pp]
			btn.disabled = false
			btn.visible = true
			for conn in btn.pressed.get_connections():
				btn.pressed.disconnect(conn.callable)
			var idx := i
			var mid := new_move_id
			btn.pressed.connect(func(): scene._on_replace_move(idx, mid))
		else:
			btn.visible = false

	if _cancel_learn_btn == null:
		_cancel_learn_btn = Button.new()
		_cancel_learn_btn.position = Vector2(80, 60)
		_cancel_learn_btn.size     = Vector2(156, 16)
		_cancel_learn_btn.add_theme_font_size_override("font_size", 8)
		move_menu.add_child(_cancel_learn_btn)
	_cancel_learn_btn.text    = "X Ne pas apprendre"
	_cancel_learn_btn.visible = true
	for conn in _cancel_learn_btn.pressed.get_connections():
		_cancel_learn_btn.pressed.disconnect(conn.callable)
	var mid := new_move_id
	_cancel_learn_btn.pressed.connect(func(): scene._on_skip_learn(mid))
	msg("Oublier quelle capacite\npour %s ?" % new_name)

func hide_cancel_learn_btn() -> void:
	if _cancel_learn_btn:
		_cancel_learn_btn.visible = false

func reconnect_move_buttons() -> void:
	for i in range(_move_buttons.size()):
		var btn: Button = _move_buttons[i]
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		var idx := i
		btn.pressed.connect(func(): scene._on_move(idx))

# =========================================================================
#  UI Helpers
# =========================================================================

func _add_rect(p: Node, pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos; r.size = sz; r.color = col
	p.add_child(r); return r

func _add_modern_panel(p: Node, pos: Vector2, sz: Vector2) -> ColorRect:
	var border := _add_rect(p, pos - Vector2(1, 1), sz + Vector2(2, 2), C_BORDER)
	var panel := _add_rect(border, Vector2(1, 1), sz, C_PANEL)
	_add_rect(panel, Vector2.ZERO, Vector2(sz.x, 1), Color(1, 1, 1, 0.05))
	return panel

func _add_overlay(p: Node, pos: Vector2, sz: Vector2) -> Control:
	var c := Control.new()
	c.position = pos; c.size = sz
	p.add_child(c); return c

func _add_label(p: Node, pos: Vector2, text: String, fsize: int) -> Label:
	var l := Label.new()
	l.position = pos; l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", C_TEXT)
	p.add_child(l); return l

func _make_btn(p: Node, pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.position = pos; btn.size = sz; btn.text = text
	btn.custom_minimum_size = Vector2.ZERO
	btn.add_theme_font_size_override("font_size", 9)
	p.add_child(btn); return btn

func _type_col(t: String) -> Color:
	const C := { "Fire":Color(0.9,0.35,0.1),"Water":Color(0.25,0.55,0.95),"Grass":Color(0.3,0.75,0.3),
		"Electric":Color(0.95,0.85,0.1),"Psychic":Color(0.9,0.2,0.55),"Ice":Color(0.6,0.85,0.95),
		"Dragon":Color(0.4,0.2,0.9),"Dark":Color(0.3,0.2,0.15),"Fairy":Color(0.95,0.6,0.8),
		"Fighting":Color(0.7,0.2,0.15),"Poison":Color(0.55,0.2,0.65),"Ground":Color(0.85,0.7,0.35),
		"Flying":Color(0.6,0.7,0.95),"Bug":Color(0.6,0.75,0.1),"Rock":Color(0.6,0.55,0.3),
		"Ghost":Color(0.35,0.25,0.55),"Steel":Color(0.7,0.7,0.8),"Normal":Color(0.65,0.65,0.6) }
	return C.get(t, Color(0.65, 0.65, 0.6))
