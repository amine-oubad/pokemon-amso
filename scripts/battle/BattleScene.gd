extends Node2D
## Scène de combat Phase 1 — tour par tour, style Gen 3.
## State machine : INTRO → PLAYER_CHOOSE → CHOOSE_MOVE → PLAYER_MOVE
##                      → ENEMY_MOVE → CHECK_END → (boucle ou fin)
## UI entièrement construite en code (pas de .tscn UI).

# ── State machine ─────────────────────────────────────────────────────────────
enum State { INTRO, PLAYER_CHOOSE, CHOOSE_MOVE, PLAYER_MOVE, ENEMY_MOVE, CHECK_END, SHOW_XP, BATTLE_OVER }
var _state: State = State.INTRO
var _last_attacker: String = ""  # "player" | "enemy"
var _animating: bool = false     # garde contre les appels concurrents

# ── Pokémon ───────────────────────────────────────────────────────────────────
var player_pkmn: PokemonInstance
var enemy_pkmn: PokemonInstance
var _selected_move: MoveInstance

# ── Références UI (créées dans _build_ui) ─────────────────────────────────────
var _msg_label:      Label
var _enemy_name:     Label
var _enemy_level:    Label
var _enemy_hp_fill:  ColorRect
var _player_name:    Label
var _player_level:   Label
var _player_hp_fill: ColorRect
var _player_hp_text: Label
var _action_menu:    Control
var _move_menu:      Control
var _move_buttons:   Array[Button] = []

# ── Constantes UI (viewport 320×240) ─────────────────────────────────────────
const C_BG      := Color(0.93, 0.89, 0.79)
const C_DARK    := Color(0.20, 0.15, 0.10)
const C_PANEL   := Color(0.97, 0.94, 0.86)
const C_HP_BG   := Color(0.25, 0.12, 0.12)
const HP_BAR_W  := 96

# ── Initialisation ────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	_load_pokemon()
	_refresh_ui()
	_set_state(State.INTRO)

func _load_pokemon() -> void:
	var bd := GameState.pending_battle
	enemy_pkmn = PokemonInstance.from_encounter(bd.get("enemy_data", {}))

	# Pokémon joueur — premier non KO de l'équipe, ou Pikachu Nv.5 si équipe vide
	var leader := GameState.get_first_alive()
	if leader:
		player_pkmn = leader
	else:
		player_pkmn = PokemonInstance.create("025", 5)
		GameState.team.append(player_pkmn)

	# Pokédex : marquer l'ennemi comme vu
	GameState.register_seen(enemy_pkmn.pokemon_id)

# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(new_state: State) -> void:
	_state = new_state
	_action_menu.visible = false
	_move_menu.visible   = false

	match _state:
		State.INTRO:
			_msg("Un %s sauvage apparaît !" % enemy_pkmn.get_name())

		State.PLAYER_CHOOSE:
			_msg("Que va faire %s ?" % player_pkmn.get_name())
			_action_menu.visible = true

		State.CHOOSE_MOVE:
			_refresh_move_buttons()
			_move_menu.visible = true

		State.PLAYER_MOVE:
			_do_player_move()

		State.ENEMY_MOVE:
			_do_enemy_move()

		State.CHECK_END:
			_check_end()

		State.SHOW_XP:
			_award_xp()

		State.BATTLE_OVER:
			_finish()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	match _state:
		State.INTRO:
			_set_state(State.PLAYER_CHOOSE)
		State.CHOOSE_MOVE:
			_set_state(State.PLAYER_CHOOSE)  # Retour avec Z/Entrée

# ── Boutons ───────────────────────────────────────────────────────────────────

func _on_attack_pressed() -> void:
	if _state == State.PLAYER_CHOOSE:
		_set_state(State.CHOOSE_MOVE)

func _on_move_pressed(idx: int) -> void:
	if _state != State.CHOOSE_MOVE or _animating:
		return
	if idx >= player_pkmn.moves.size():
		return
	_selected_move = player_pkmn.moves[idx]
	_move_menu.visible = false
	_set_state(State.PLAYER_MOVE)

# ── Exécution des tours ───────────────────────────────────────────────────────

func _do_player_move() -> void:
	if _animating: return
	_animating = true
	_last_attacker = "player"

	var move := _selected_move
	move.use()

	# Vérification de la précision
	if not BattleCalc.accuracy_check(move, player_pkmn, enemy_pkmn):
		_msg("%s attaque mais rate !" % player_pkmn.get_name())
		await get_tree().create_timer(1.6).timeout
		_animating = false
		_set_state(State.ENEMY_MOVE)
		return

	var calc := BattleCalc.calculate_damage(player_pkmn, enemy_pkmn, move)
	enemy_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [player_pkmn.get_name(), move.get_name()]
	if calc.critical:      msg += "\nCoup critique !"
	match calc.effectiveness:
		2.0, 4.0: msg += "\nC'est super efficace !"
		0.5, 0.25: msg += "\nCe n'est pas très efficace..."
		0.0:       msg += "\nÇa n'affecte pas %s !" % enemy_pkmn.get_name()
	_msg(msg)

	_refresh_move_buttons()
	await get_tree().create_timer(1.8).timeout
	_animating = false
	_set_state(State.CHECK_END)

func _do_enemy_move() -> void:
	if _animating: return
	_animating = true
	_last_attacker = "enemy"

	# IA basique : move aléatoire parmi les PP > 0
	var usable: Array = enemy_pkmn.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())
	if usable.is_empty():
		_animating = false
		_set_state(State.PLAYER_CHOOSE)
		return

	var move: MoveInstance = usable[randi() % usable.size()]
	move.use()

	if not BattleCalc.accuracy_check(move, enemy_pkmn, player_pkmn):
		_msg("%s attaque mais rate !" % enemy_pkmn.get_name())
		await get_tree().create_timer(1.6).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	var calc := BattleCalc.calculate_damage(enemy_pkmn, player_pkmn, move)
	player_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [enemy_pkmn.get_name(), move.get_name()]
	if calc.critical:      msg += "\nCoup critique !"
	match calc.effectiveness:
		2.0, 4.0: msg += "\nC'est super efficace !"
		0.5, 0.25: msg += "\nCe n'est pas très efficace..."
	_msg(msg)

	await get_tree().create_timer(1.8).timeout
	_animating = false
	_set_state(State.CHECK_END)

func _check_end() -> void:
	if enemy_pkmn.is_fainted():
		_set_state(State.SHOW_XP)
		return
	if player_pkmn.is_fainted():
		_msg("%s est K.O. !" % player_pkmn.get_name())
		await get_tree().create_timer(2.0).timeout
		_set_state(State.BATTLE_OVER)
		return
	# Continuer le combat
	if _last_attacker == "player":
		_set_state(State.ENEMY_MOVE)
	else:
		_set_state(State.PLAYER_CHOOSE)

func _award_xp() -> void:
	var xp := BattleCalc.calculate_exp_gain(enemy_pkmn, player_pkmn.level)
	GameState.register_caught(enemy_pkmn.pokemon_id)
	_msg("%s est K.O. !\n%s gagne %d EXP !" % [
		enemy_pkmn.get_name(), player_pkmn.get_name(), xp
	])
	await get_tree().create_timer(2.5).timeout
	_set_state(State.BATTLE_OVER)

func _finish() -> void:
	var result := "win" if not player_pkmn.is_fainted() else "lose"
	player_pkmn.reset_stat_stages()
	GameState.pending_battle = {}
	EventBus.battle_ended.emit(result)
	get_tree().change_scene_to_file("res://scenes/overworld/maps/TestMap.tscn")

# ── Refresh UI ────────────────────────────────────────────────────────────────

func _msg(text: String) -> void:
	_msg_label.text = text

func _refresh_ui() -> void:
	# Ennemi
	_enemy_name.text  = enemy_pkmn.get_name().to_upper()
	_enemy_level.text = "Lv%d" % enemy_pkmn.level
	var er := float(enemy_pkmn.current_hp) / float(enemy_pkmn.max_hp)
	_enemy_hp_fill.size   = Vector2(int(HP_BAR_W * maxf(er, 0.0)), _enemy_hp_fill.size.y)
	_enemy_hp_fill.color  = _hp_color(er)

	# Joueur
	_player_name.text  = player_pkmn.get_name().to_upper()
	_player_level.text = "Lv%d" % player_pkmn.level
	var pr := float(player_pkmn.current_hp) / float(player_pkmn.max_hp)
	_player_hp_fill.size  = Vector2(int(HP_BAR_W * maxf(pr, 0.0)), _player_hp_fill.size.y)
	_player_hp_fill.color = _hp_color(pr)
	_player_hp_text.text  = "%d/%d" % [player_pkmn.current_hp, player_pkmn.max_hp]

func _refresh_move_buttons() -> void:
	for i in range(4):
		var btn: Button = _move_buttons[i]
		if i < player_pkmn.moves.size():
			var mv: MoveInstance = player_pkmn.moves[i]
			btn.text     = "%s\n%d/%d PP" % [mv.get_name(), mv.current_pp, mv.max_pp]
			btn.disabled = not mv.is_usable()
			btn.visible  = true
		else:
			btn.visible = false

func _hp_color(ratio: float) -> Color:
	if ratio > 0.5: return Color(0.20, 0.75, 0.20)
	if ratio > 0.2: return Color(0.88, 0.70, 0.08)
	return Color(0.88, 0.18, 0.10)

# ── Construction de l'UI en code ──────────────────────────────────────────────

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	# ── Fond ──────────────────────────────────────────────────────────────────
	_add_rect(layer, Vector2.ZERO, Vector2(320, 240), C_BG)

	# ── Zone sprite ennemi (haut-gauche) ──────────────────────────────────────
	var esp := _add_rect(layer, Vector2(8, 10), Vector2(80, 72), Color(0.85, 0.82, 0.72))
	# Représentation placeholder : cercle coloré selon le type
	var etype_color := _type_color(
		GameData.pokemon_data.get(
			GameState.pending_battle.get("enemy_data", {}).get("id", "025"), {}
		).get("types", ["Normal"])[0]
	)
	_add_rect(layer, Vector2(28, 26), Vector2(40, 40), etype_color)
	esp.color = Color(0.80, 0.78, 0.68)

	# ── Panel info ennemi (haut-droite) ───────────────────────────────────────
	var ep := _add_panel(layer, Vector2(164, 8), Vector2(148, 58))
	_enemy_name  = _add_label(ep, Vector2(6, 4),  "...", 8)
	_enemy_level = _add_label(ep, Vector2(102, 4), "Lv?", 8)
	_add_label(ep, Vector2(6, 22), "HP", 7)
	_add_rect(ep, Vector2(22, 24), Vector2(HP_BAR_W, 7), C_HP_BG)
	_enemy_hp_fill = _add_rect(ep, Vector2(22, 24), Vector2(HP_BAR_W, 7), Color(0.2, 0.75, 0.2))

	# ── Zone sprite joueur (bas-droite) ───────────────────────────────────────
	_add_rect(layer, Vector2(200, 88), Vector2(80, 68), Color(0.80, 0.78, 0.68))
	_add_rect(layer, Vector2(224, 104), Vector2(32, 32), Color(0.196, 0.408, 0.941))

	# ── Panel info joueur (bas-gauche) ────────────────────────────────────────
	var pp := _add_panel(layer, Vector2(8, 104), Vector2(160, 66))
	_player_name  = _add_label(pp, Vector2(6, 4),  "...", 8)
	_player_level = _add_label(pp, Vector2(108, 4), "Lv?", 8)
	_add_label(pp, Vector2(6, 22), "HP", 7)
	_add_rect(pp, Vector2(22, 24), Vector2(HP_BAR_W, 7), C_HP_BG)
	_player_hp_fill = _add_rect(pp, Vector2(22, 24), Vector2(HP_BAR_W, 7), Color(0.2, 0.75, 0.2))
	_player_hp_text = _add_label(pp, Vector2(6, 38), "?/?", 8)

	# ── Boîte de message ──────────────────────────────────────────────────────
	_add_rect(layer, Vector2(0, 174), Vector2(320, 4), C_DARK)
	var mbox := _add_rect(layer, Vector2(0, 178), Vector2(320, 62), C_PANEL)
	_add_rect(layer, Vector2(0, 178), Vector2(4, 62), C_DARK)
	_add_rect(layer, Vector2(316, 178), Vector2(4, 62), C_DARK)
	_add_rect(layer, Vector2(0, 236), Vector2(320, 4), C_DARK)
	_msg_label = _add_label(mbox, Vector2(10, 6), "...", 9)
	_msg_label.size = Vector2(200, 52)
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── Menu actions (overlay droit de la boîte de message) ───────────────────
	_action_menu = Control.new()
	_action_menu.position = Vector2(210, 178)
	layer.add_child(_action_menu)

	var atk_btn := _add_btn(_action_menu, Vector2(0,  2),  Vector2(108, 18), "⚔  ATTAQUER")
	atk_btn.pressed.connect(_on_attack_pressed)

	var bag_btn := _add_btn(_action_menu, Vector2(0, 22), Vector2(108, 18), "🎒  SAC")
	bag_btn.disabled = true

	var pok_btn := _add_btn(_action_menu, Vector2(0, 42), Vector2(108, 18), "🔵  POKÉMON")
	pok_btn.disabled = true

	_action_menu.visible = false

	# ── Menu moves (grille 2×2, overlay boîte) ────────────────────────────────
	_move_menu = Control.new()
	_move_menu.position = Vector2(2, 178)
	layer.add_child(_move_menu)

	var mpos := [Vector2(0, 0), Vector2(158, 0), Vector2(0, 32), Vector2(158, 32)]
	for i in range(4):
		var btn := _add_btn(_move_menu, mpos[i], Vector2(156, 30), "—")
		btn.add_theme_font_size_override("font_size", 8)
		var idx := i
		btn.pressed.connect(func() -> void: _on_move_pressed(idx))
		_move_buttons.append(btn)

	_move_menu.visible = false

# ── Helpers de construction UI ────────────────────────────────────────────────

func _add_rect(parent: Node, pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	parent.add_child(r)
	return r

func _add_panel(parent: Node, pos: Vector2, sz: Vector2) -> ColorRect:
	# Bordure sombre + fond clair
	var border := _add_rect(parent, pos, sz, C_DARK)
	var inner  := _add_rect(border, Vector2(2, 2), sz - Vector2(4, 4), C_PANEL)
	return inner

func _add_label(parent: Node, pos: Vector2, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", C_DARK)
	parent.add_child(l)
	return l

func _add_btn(parent: Node, pos: Vector2, sz: Vector2, text: String) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.text = text
	btn.custom_minimum_size = Vector2.ZERO
	btn.add_theme_font_size_override("font_size", 9)
	parent.add_child(btn)
	return btn

func _type_color(type_name: String) -> Color:
	var colors := {
		"Fire": Color(0.9, 0.35, 0.1), "Water": Color(0.25, 0.55, 0.95),
		"Grass": Color(0.3, 0.75, 0.3), "Electric": Color(0.95, 0.85, 0.1),
		"Psychic": Color(0.9, 0.2, 0.55), "Ice": Color(0.6, 0.85, 0.95),
		"Dragon": Color(0.4, 0.2, 0.9), "Dark": Color(0.3, 0.2, 0.15),
		"Fairy": Color(0.95, 0.6, 0.8), "Fighting": Color(0.7, 0.2, 0.15),
		"Poison": Color(0.55, 0.2, 0.65), "Ground": Color(0.85, 0.7, 0.35),
		"Flying": Color(0.6, 0.7, 0.95), "Bug": Color(0.6, 0.75, 0.1),
		"Rock": Color(0.6, 0.55, 0.3), "Ghost": Color(0.35, 0.25, 0.55),
		"Steel": Color(0.7, 0.7, 0.8), "Normal": Color(0.65, 0.65, 0.6),
	}
	return colors.get(type_name, Color(0.65, 0.65, 0.6))
