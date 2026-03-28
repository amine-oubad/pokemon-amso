extends Node2D
## Scène de combat Phase 5 — combat complet + dresseurs + XP/level-up/évolution.

# ── State machine ─────────────────────────────────────────────────────────────
enum State {
	INTRO,
	PLAYER_CHOOSE, CHOOSE_MOVE, CHOOSE_ITEM, CHOOSE_POKEMON,
	PLAYER_MOVE, FLEE_ATTEMPT,
	ENEMY_MOVE,
	CHECK_END, CAPTURE_ANIM, SHOW_XP, LEARN_MOVE, EVOLVE, TRAINER_NEXT, BATTLE_OVER
}

# ── File d'events post-XP (level-up, moves, évolution) ───────────────────────
var _pending_moves: Array = []  # [move_id, ...]
var _pending_evolution: String = ""
var _state: State = State.INTRO
var _last_attacker: String = ""
var _animating: bool       = false
var _forced_switch: bool   = false  # true = KO forcé, pas de tour ennemi après
var _fled: bool            = false
var _flee_attempts: int    = 0
var _is_trainer_battle: bool = false

# ── Trainer battle data ───────────────────────────────────────────────────────
var _trainer_id: String      = ""
var _trainer_name: String    = ""
var _trainer_team: Array     = []  # Array of PokemonInstance
var _trainer_team_idx: int   = 0
var _reward_money: int       = 0
var _badge_id: String        = ""
var _is_gym_leader: bool     = false

# ── Pokémon ───────────────────────────────────────────────────────────────────
var player_pkmn: PokemonInstance   ## Raccourci vers le Pokémon actif de l'équipe
var _active_idx: int = 0
var enemy_pkmn:  PokemonInstance
var _selected_move: MoveInstance

# ── Constantes UI ─────────────────────────────────────────────────────────────
const C_BG    := Color(0.93, 0.89, 0.79)
const C_DARK  := Color(0.20, 0.15, 0.10)
const C_PANEL := Color(0.97, 0.94, 0.86)
const C_HP_BG := Color(0.25, 0.12, 0.12)
const HP_W    := 96

# ── UI nodes ──────────────────────────────────────────────────────────────────
var _msg_label:       Label
var _enemy_name:      Label
var _enemy_level:     Label
var _enemy_hp_fill:   ColorRect
var _enemy_status:    Label
var _player_name:     Label
var _player_level:    Label
var _player_hp_fill:  ColorRect
var _player_hp_text:  Label
var _player_status:   Label
var _action_menu:     Control
var _move_menu:       Control
var _item_menu:       Control
var _pkmn_menu:       Control
var _move_buttons:    Array[Button] = []

# ── Initialisation ────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_ui()
	_load_battle()
	_refresh_ui()
	_set_state(State.INTRO)

func _load_battle() -> void:
	var bd := GameState.pending_battle
	_is_trainer_battle = bd.get("is_trainer", false)
	_trainer_id    = bd.get("trainer_id", "")
	_trainer_name  = bd.get("trainer_name", "Dresseur")
	_reward_money  = bd.get("reward_money", 0)
	_badge_id      = bd.get("badge_id", "")
	_is_gym_leader = bd.get("is_gym_leader", false)

	# Construire l'équipe du dresseur
	if _is_trainer_battle:
		var team_data: Array = bd.get("trainer_team", [])
		_trainer_team.clear()
		for td in team_data:
			var pkmn := PokemonInstance.create(td.get("id", "025"), td.get("level", 5))
			_trainer_team.append(pkmn)
		_trainer_team_idx = 0
		if _trainer_team.size() > 0:
			enemy_pkmn = _trainer_team[0]
		else:
			enemy_pkmn = PokemonInstance.from_encounter(bd.get("enemy_data", {}))
	else:
		enemy_pkmn = PokemonInstance.from_encounter(bd.get("enemy_data", {}))

	GameState.register_seen(enemy_pkmn.pokemon_id)

	# Pokémon joueur actif
	var leader := GameState.get_first_alive()
	if leader:
		player_pkmn = leader
		_active_idx  = GameState.team.find(leader)
	else:
		player_pkmn = PokemonInstance.create("025", 5)  # Pikachu Lv5 de secours
		GameState.team.append(player_pkmn)
		_active_idx = 0

# ── State machine ─────────────────────────────────────────────────────────────

func _set_state(s: State) -> void:
	_state = s
	_action_menu.visible = false
	_move_menu.visible   = false
	_item_menu.visible   = false
	_pkmn_menu.visible   = false

	match _state:
		State.INTRO:
			if _is_trainer_battle:
				_msg("%s veut se battre !\n%s envoie %s !" % [_trainer_name, _trainer_name, enemy_pkmn.get_name()])
			else:
				_msg("Un %s sauvage apparaît !" % enemy_pkmn.get_name())

		State.PLAYER_CHOOSE:
			_msg("Que va faire %s ?" % player_pkmn.get_name())
			_action_menu.visible = true

		State.CHOOSE_MOVE:
			_refresh_move_buttons()
			_move_menu.visible = true

		State.CHOOSE_ITEM:
			_populate_item_menu()
			_item_menu.visible = true

		State.CHOOSE_POKEMON:
			_populate_pkmn_menu()
			_pkmn_menu.visible = true

		State.PLAYER_MOVE:   _do_player_move()
		State.FLEE_ATTEMPT:  _do_flee()
		State.ENEMY_MOVE:    _do_enemy_move()
		State.CHECK_END:     _check_end()
		State.CAPTURE_ANIM:  pass
		State.SHOW_XP:       _award_xp()
		State.LEARN_MOVE:    _show_learn_move()
		State.EVOLVE:        _show_evolution()
		State.TRAINER_NEXT:  _trainer_send_next()
		State.BATTLE_OVER:   _finish()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	match _state:
		State.INTRO:        _set_state(State.PLAYER_CHOOSE)
		State.CHOOSE_MOVE:  _set_state(State.PLAYER_CHOOSE)  # retour
		State.CHOOSE_ITEM:  _set_state(State.PLAYER_CHOOSE)
		State.CHOOSE_POKEMON:
			if not _forced_switch:
				_set_state(State.PLAYER_CHOOSE)

# ── Boutons d'action ──────────────────────────────────────────────────────────

func _on_attack() -> void:
	if _state == State.PLAYER_CHOOSE: _set_state(State.CHOOSE_MOVE)

func _on_bag() -> void:
	if _state == State.PLAYER_CHOOSE: _set_state(State.CHOOSE_ITEM)

func _on_switch_btn() -> void:
	if _state == State.PLAYER_CHOOSE: _set_state(State.CHOOSE_POKEMON)

func _on_flee() -> void:
	if _state == State.PLAYER_CHOOSE: _set_state(State.FLEE_ATTEMPT)

func _on_move(idx: int) -> void:
	if _state != State.CHOOSE_MOVE or _animating: return
	if idx >= player_pkmn.moves.size(): return
	_selected_move = player_pkmn.moves[idx]
	_move_menu.visible = false
	_set_state(State.PLAYER_MOVE)

func _on_item_used(item_id: String) -> void:
	if _animating: return
	_item_menu.visible = false
	var idata := GameData.items_data.get(item_id, {})
	GameState.remove_item(item_id)
	_last_attacker = "player"
	_animating = true

	match idata.get("category", ""):
		"heal":
			var healed := player_pkmn.heal(idata.get("heal_amount", 20))
			_refresh_ui()
			_msg("%s utilise %s !\n%s récupère %d PV !" % [
				GameState.player_name, idata.get("name", item_id),
				player_pkmn.get_name(), healed
			])
			await get_tree().create_timer(1.8).timeout
			_animating = false
			_set_state(State.CHECK_END)

		"status_cure":
			var cures: Array = idata.get("cures", [])
			if player_pkmn.status in cures:
				player_pkmn.status = ""
				player_pkmn.status_turns = 0
				_refresh_ui()
				_msg("%s utilise %s !\nLe statut de %s est guéri !" % [
					GameState.player_name, idata.get("name", item_id), player_pkmn.get_name()
				])
			else:
				GameState.add_item(item_id)  # remboursement
				_msg("Cet objet n'a aucun effet ici !")
			await get_tree().create_timer(1.8).timeout
			_animating = false
			_set_state(State.CHECK_END)

		"ball":
			if _is_trainer_battle:
				GameState.add_item(item_id)
				_msg("Voler les Pokémon\nd'un Dresseur ? Impossible !")
				await get_tree().create_timer(1.8).timeout
				_animating = false
				_set_state(State.PLAYER_CHOOSE)
				return
			var bonus: float = idata.get("ball_bonus", 1.0)
			_msg("%s lance une %s !" % [GameState.player_name, idata.get("name", item_id)])
			await get_tree().create_timer(0.8).timeout
			# Animation secousses
			for i in range(3):
				_msg("La Ball tremble" + "." * (i + 1))
				await get_tree().create_timer(0.5).timeout
			var caught := BattleCalc.try_catch(enemy_pkmn, bonus)
			if caught:
				GameState.register_caught(enemy_pkmn.pokemon_id)
				if GameState.team.size() < 6:
					GameState.team.append(enemy_pkmn)
					_msg("%s est capturé !\n%s rejoint votre équipe !" % [enemy_pkmn.get_name(), enemy_pkmn.get_name()])
				else:
					GameState.pc_boxes.append(enemy_pkmn)
					_msg("%s est capturé !\nEnvoyé au PC." % enemy_pkmn.get_name())
				await get_tree().create_timer(2.0).timeout
				_animating = false
				GameState.pending_battle = {}
				EventBus.battle_ended.emit("caught")
				get_tree().change_scene_to_file(GameState.return_to_scene)
			else:
				_msg("%s s'échappe de la Ball !" % enemy_pkmn.get_name())
				await get_tree().create_timer(1.5).timeout
				_animating = false
				_set_state(State.ENEMY_MOVE)

func _on_switch_pkmn(idx: int) -> void:
	if _animating: return
	if idx == _active_idx: return
	if GameState.team[idx].is_fainted(): return
	var old_name := player_pkmn.get_name()
	player_pkmn.reset_stat_stages()
	_active_idx  = idx
	player_pkmn  = GameState.team[idx]
	_pkmn_menu.visible = false
	_animating = true
	_msg("Reviens, %s !\nAllez, %s !" % [old_name, player_pkmn.get_name()])
	_refresh_ui()
	await get_tree().create_timer(1.5).timeout
	_animating = false
	if _forced_switch:
		_forced_switch = false
		_set_state(State.PLAYER_CHOOSE)  # force switch après KO → pas de tour ennemi
	else:
		_last_attacker = "player"
		_set_state(State.CHECK_END)

# ── Tours de combat ───────────────────────────────────────────────────────────

func _do_player_move() -> void:
	if _animating: return
	_animating = true
	_last_attacker = "player"

	# Vérification statut
	var sc := MoveEffects.check_can_move(player_pkmn)
	_msg(sc.message if sc.message != "" else "%s attaque !" % player_pkmn.get_name())
	if sc.message != "": await get_tree().create_timer(1.2).timeout
	if not sc.can_move:
		_animating = false
		_set_state(State.CHECK_END)
		return

	var move := _selected_move
	move.use()

	# Précision
	if not BattleCalc.accuracy_check(move, player_pkmn, enemy_pkmn):
		_msg("%s rate son attaque !" % player_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Dégâts
	var calc := BattleCalc.calculate_damage(player_pkmn, enemy_pkmn, move)
	enemy_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [player_pkmn.get_name(), move.get_name()]
	if calc.critical: msg += "\nCoup critique !"
	match calc.effectiveness:
		2.0, 4.0:   msg += "\nC'est super efficace !"
		0.5, 0.25:  msg += "\nCe n'est pas très efficace..."
		0.0:        msg += "\nSans effet sur %s !" % enemy_pkmn.get_name()
	_msg(msg)
	_refresh_move_buttons()
	await get_tree().create_timer(1.8).timeout

	# Effet secondaire
	if not enemy_pkmn.is_fainted():
		var eff := MoveEffects.apply_move_effect(move, player_pkmn, enemy_pkmn)
		if eff != "":
			_msg(eff); _refresh_ui()
			await get_tree().create_timer(1.2).timeout

	_animating = false
	_set_state(State.CHECK_END)

func _do_enemy_move() -> void:
	if _animating: return
	_animating = true
	_last_attacker = "enemy"

	# IA : move aléatoire avec PP > 0
	var usable: Array = enemy_pkmn.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())
	if usable.is_empty():
		_animating = false
		_set_state(State.PLAYER_CHOOSE)
		return

	# Vérification statut ennemi
	var sc := MoveEffects.check_can_move(enemy_pkmn)
	if sc.message != "":
		_msg(sc.message); _refresh_ui()
		await get_tree().create_timer(1.2).timeout
	if not sc.can_move:
		_animating = false
		_set_state(State.CHECK_END)
		return

	var move: MoveInstance = usable[randi() % usable.size()]
	move.use()

	if not BattleCalc.accuracy_check(move, enemy_pkmn, player_pkmn):
		_msg("%s rate son attaque !" % enemy_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	var calc := BattleCalc.calculate_damage(enemy_pkmn, player_pkmn, move)
	player_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [enemy_pkmn.get_name(), move.get_name()]
	if calc.critical: msg += "\nCoup critique !"
	match calc.effectiveness:
		2.0, 4.0:  msg += "\nC'est super efficace !"
		0.5, 0.25: msg += "\nCe n'est pas très efficace..."
	_msg(msg)
	await get_tree().create_timer(1.8).timeout

	if not player_pkmn.is_fainted():
		var eff := MoveEffects.apply_move_effect(move, enemy_pkmn, player_pkmn)
		if eff != "":
			_msg(eff); _refresh_ui()
			await get_tree().create_timer(1.2).timeout

	_animating = false
	_set_state(State.CHECK_END)

func _do_flee() -> void:
	if _animating: return
	if _is_trainer_battle:
		_msg("Impossible de fuir\nun combat de Dresseur !")
		_animating = true
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.PLAYER_CHOOSE)
		return
	_animating = true
	_flee_attempts += 1
	var p_spd := player_pkmn.get_effective_stat("speed")
	var e_spd := enemy_pkmn.get_effective_stat("speed")
	var success := false
	if p_spd >= e_spd:
		success = true
	else:
		var chance := int(p_spd * 32.0 / e_spd + 30.0) * _flee_attempts % 256
		success = randi() % 256 < chance
	if success:
		_fled = true
		_msg("Vous prenez la fuite !")
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.BATTLE_OVER)
	else:
		_msg("Impossible de fuir !")
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_last_attacker = "player"
		_set_state(State.CHECK_END)

# ── Check fin de tour ─────────────────────────────────────────────────────────

func _check_end() -> void:
	if enemy_pkmn.is_fainted():
		_set_state(State.SHOW_XP)
		return
	if player_pkmn.is_fainted():
		await _handle_player_ko()
		return

	# Effets fin de tour sur le défenseur du tour précédent
	if _last_attacker == "player":
		await _apply_eot(enemy_pkmn)
		if enemy_pkmn.is_fainted(): _set_state(State.SHOW_XP); return
		_set_state(State.ENEMY_MOVE)
	else:
		await _apply_eot(player_pkmn)
		if player_pkmn.is_fainted(): await _handle_player_ko(); return
		_set_state(State.PLAYER_CHOOSE)

func _apply_eot(pkmn: PokemonInstance) -> void:
	var msg := MoveEffects.apply_end_of_turn(pkmn)
	if msg != "":
		_msg(msg); _refresh_ui()
		await get_tree().create_timer(1.2).timeout

func _handle_player_ko() -> void:
	var next := GameState.get_first_alive()
	if next:
		_msg("%s est K.O. !\nChoisissez un remplaçant !" % player_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_forced_switch = true
		_set_state(State.CHOOSE_POKEMON)
	else:
		_msg("Tous vos Pokémon\nsont K.O. !")
		await get_tree().create_timer(2.0).timeout
		_set_state(State.BATTLE_OVER)

func _award_xp() -> void:
	var xp := BattleCalc.calculate_exp_gain(enemy_pkmn, player_pkmn.level)
	_msg("%s est K.O. !\n%s gagne %d EXP !" % [enemy_pkmn.get_name(), player_pkmn.get_name(), xp])
	await get_tree().create_timer(2.0).timeout

	# Appliquer l'XP et gérer les level-ups
	var result := player_pkmn.gain_exp(xp)
	if result.levels_gained > 0:
		_refresh_ui()
		_msg("%s monte au Lv.%d !" % [player_pkmn.get_name(), player_pkmn.level])
		await get_tree().create_timer(2.0).timeout

	# Stocker les moves à apprendre et l'évolution
	_pending_moves = result.new_moves
	_pending_evolution = result.evolution

	_advance_post_xp()

## Avance dans la file post-XP : moves → évolution → suite du combat.
func _advance_post_xp() -> void:
	if _pending_moves.size() > 0:
		_set_state(State.LEARN_MOVE)
		return
	if _pending_evolution != "":
		_set_state(State.EVOLVE)
		return
	_go_to_next_or_end()

func _go_to_next_or_end() -> void:
	if _is_trainer_battle and _trainer_team_idx + 1 < _trainer_team.size():
		_set_state(State.TRAINER_NEXT)
	else:
		_set_state(State.BATTLE_OVER)

# ── Apprentissage de move ─────────────────────────────────────────────────────

func _show_learn_move() -> void:
	var move_id: String = _pending_moves[0]
	_pending_moves.remove_at(0)
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var move_name: String = mdata.get("name", move_id)

	if player_pkmn.moves.size() < 4:
		player_pkmn.learn_move(move_id)
		_msg("%s apprend %s !" % [player_pkmn.get_name(), move_name])
		await get_tree().create_timer(2.0).timeout
		_advance_post_xp()
	else:
		# 4 moves → proposer de remplacer
		_msg("%s veut apprendre %s...\nMais il connaît déjà 4 capacités !" % [player_pkmn.get_name(), move_name])
		await get_tree().create_timer(2.5).timeout
		_show_move_replace_menu(move_id)

func _show_move_replace_menu(new_move_id: String) -> void:
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)

	# Réutiliser le menu moves pour le choix de remplacement
	_move_menu.visible = true
	for i in range(4):
		var btn: Button = _move_buttons[i]
		if i < player_pkmn.moves.size():
			var mv: MoveInstance = player_pkmn.moves[i]
			btn.text = "%s\n%d/%d PP" % [mv.get_name(), mv.current_pp, mv.max_pp]
			btn.disabled = false
			btn.visible = true
			# Déconnecter les anciens signaux et reconnecter
			for conn in btn.pressed.get_connections():
				btn.pressed.disconnect(conn.callable)
			var idx := i
			var mid := new_move_id
			btn.pressed.connect(func() -> void: _on_replace_move(idx, mid))
		else:
			btn.visible = false
	_msg("Oublier quelle capacité\npour %s ?" % new_name)

func _on_replace_move(idx: int, new_move_id: String) -> void:
	_move_menu.visible = false
	var old_name := player_pkmn.moves[idx].get_name()
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)
	player_pkmn.learn_move(new_move_id, idx)
	_msg("1, 2, 3... %s oublie %s\net apprend %s !" % [player_pkmn.get_name(), old_name, new_name])

	# Restaurer les callbacks normaux des boutons
	_reconnect_move_buttons()
	_animating = true
	await get_tree().create_timer(2.5).timeout
	_animating = false
	_advance_post_xp()

func _reconnect_move_buttons() -> void:
	for i in range(_move_buttons.size()):
		var btn: Button = _move_buttons[i]
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		var idx := i
		btn.pressed.connect(func() -> void: _on_move(idx))

# ── Évolution ─────────────────────────────────────────────────────────────────

func _show_evolution() -> void:
	var target_id := _pending_evolution
	_pending_evolution = ""
	var old_name := player_pkmn.get_name()
	var target_data: Dictionary = GameData.pokemon_data.get(target_id, {})
	var new_name: String = target_data.get("name", target_id)

	_msg("Hein !? %s évolue !" % old_name)
	await get_tree().create_timer(2.5).timeout

	player_pkmn.evolve(target_id)
	_refresh_ui()
	_msg("Félicitations !\n%s a évolué en %s !" % [old_name, new_name])
	GameState.register_seen(target_id)
	GameState.register_caught(target_id)
	await get_tree().create_timer(3.0).timeout
	_go_to_next_or_end()

func _trainer_send_next() -> void:
	_trainer_team_idx += 1
	enemy_pkmn = _trainer_team[_trainer_team_idx]
	GameState.register_seen(enemy_pkmn.pokemon_id)
	_refresh_ui()
	_msg("%s envoie %s !" % [_trainer_name, enemy_pkmn.get_name()])
	_animating = true
	await get_tree().create_timer(2.0).timeout
	_animating = false
	_set_state(State.PLAYER_CHOOSE)

func _finish() -> void:
	var result := "flee" if _fled else ("win" if not player_pkmn.is_fainted() else "lose")
	player_pkmn.reset_stat_stages()

	# Récompenses dresseur
	if _is_trainer_battle and result == "win":
		GameState.mark_trainer_defeated(_trainer_id)
		_msg("Vous avez battu %s !" % _trainer_name)
		await get_tree().create_timer(2.0).timeout

		if _reward_money > 0:
			GameState.money += _reward_money
			_msg("Vous remportez %d P$ !" % _reward_money)
			await get_tree().create_timer(1.5).timeout

		if _badge_id != "":
			GameState.add_badge(_badge_id)
			# Chercher le nom du badge dans les données d'arènes
			var badge_name := _badge_id
			for gym_id in GameData.gyms_data:
				var g: Dictionary = GameData.gyms_data[gym_id]
				if g.get("badge_id", "") == _badge_id:
					badge_name = g.get("badge_name", _badge_id)
					break
			_msg("Vous obtenez le %s !" % badge_name)
			await get_tree().create_timer(2.5).timeout

	GameState.pending_battle = {}
	EventBus.battle_ended.emit(result)
	get_tree().change_scene_to_file(GameState.return_to_scene)

# ── Refresh UI ────────────────────────────────────────────────────────────────

func _msg(text: String) -> void:
	_msg_label.text = text

func _refresh_ui() -> void:
	# Ennemi
	_enemy_name.text  = enemy_pkmn.get_name().to_upper()
	_enemy_level.text = "Lv%d" % enemy_pkmn.level
	var er := maxf(0.0, float(enemy_pkmn.current_hp) / float(enemy_pkmn.max_hp))
	_enemy_hp_fill.size  = Vector2(int(HP_W * er), _enemy_hp_fill.size.y)
	_enemy_hp_fill.color = _hp_color(er)
	_set_status_tag(_enemy_status, enemy_pkmn.status)

	# Joueur
	_player_name.text  = player_pkmn.get_name().to_upper()
	_player_level.text = "Lv%d" % player_pkmn.level
	var pr := maxf(0.0, float(player_pkmn.current_hp) / float(player_pkmn.max_hp))
	_player_hp_fill.size  = Vector2(int(HP_W * pr), _player_hp_fill.size.y)
	_player_hp_fill.color = _hp_color(pr)
	_player_hp_text.text  = "%d/%d" % [player_pkmn.current_hp, player_pkmn.max_hp]
	_set_status_tag(_player_status, player_pkmn.status)

func _set_status_tag(lbl: Label, status: String) -> void:
	if status == "":
		lbl.text = ""; lbl.visible = false; return
	lbl.text    = MoveEffects.STATUS_ABBR.get(status, "???")
	lbl.add_theme_color_override("font_color", MoveEffects.STATUS_COLOR.get(status, Color.GRAY))
	lbl.visible = true

func _refresh_move_buttons() -> void:
	for i in range(4):
		var btn: Button = _move_buttons[i]
		if i < player_pkmn.moves.size():
			var mv: MoveInstance = player_pkmn.moves[i]
			btn.text    = "%s\n%d/%d PP" % [mv.get_name(), mv.current_pp, mv.max_pp]
			btn.disabled = not mv.is_usable()
			btn.visible  = true
		else:
			btn.visible = false

func _hp_color(r: float) -> Color:
	if r > 0.50: return Color(0.20, 0.75, 0.20)
	if r > 0.20: return Color(0.88, 0.70, 0.08)
	return Color(0.88, 0.18, 0.10)

# ── Menus dynamiques ──────────────────────────────────────────────────────────

func _populate_item_menu() -> void:
	for c in _item_menu.get_children(): c.queue_free()
	var y := 0
	var found := false
	for item_id in GameState.bag:
		if GameState.bag[item_id] <= 0: continue
		var idata := GameData.items_data.get(item_id, {})
		if idata.is_empty(): continue
		var cat: String = idata.get("category", "")
		if cat not in ["heal", "ball", "status_cure"]: continue
		found = true
		var btn := _make_btn(_item_menu, Vector2(2, y), Vector2(196, 18),
			"%s   x%d" % [idata.get("name", item_id), GameState.bag[item_id]])
		var disable := false
		if cat == "heal" and player_pkmn.current_hp >= player_pkmn.max_hp:
			disable = true
		if cat == "ball" and _is_trainer_battle:
			disable = true
		btn.disabled = disable
		var id := item_id
		btn.pressed.connect(func() -> void: _on_item_used(id))
		y += 20
	if not found:
		var lbl := _add_label(_item_menu, Vector2(8, 6), "Sac vide !", 9)
		lbl.add_theme_color_override("font_color", C_DARK)

func _populate_pkmn_menu() -> void:
	for c in _pkmn_menu.get_children(): c.queue_free()
	var y := 0
	for i in range(GameState.team.size()):
		var pk: PokemonInstance = GameState.team[i]
		var is_active := i == _active_idx
		var is_faint  := pk.is_fainted()
		var bg := _add_rect(_pkmn_menu, Vector2(2, y), Vector2(196, 28),
			Color(0.85, 0.82, 0.72) if is_active else (Color(0.7, 0.7, 0.7) if is_faint else C_PANEL))
		_add_label(bg, Vector2(4, 2), pk.get_name().to_upper() + (" ◀" if is_active else ""), 8)
		var hp_r := maxf(0.0, float(pk.current_hp) / float(pk.max_hp))
		var hp_bg := _add_rect(bg, Vector2(4, 14), Vector2(80, 6), C_HP_BG)
		_add_rect(hp_bg, Vector2(0, 0), Vector2(int(80 * hp_r), 6), _hp_color(hp_r))
		_add_label(bg, Vector2(88, 12), "%d/%d" % [pk.current_hp, pk.max_hp], 7)
		if not is_active and not is_faint:
			var btn := Button.new()
			btn.position = Vector2(2, y); btn.size = Vector2(196, 28)
			btn.modulate.a = 0.0  # invisible mais cliquable
			var idx := i
			btn.pressed.connect(func() -> void: _on_switch_pkmn(idx))
			_pkmn_menu.add_child(btn)
		y += 30

# ── Construction de l'UI ──────────────────────────────────────────────────────

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_add_rect(layer, Vector2.ZERO, Vector2(320, 240), C_BG)

	# Zone sprite ennemi
	_add_rect(layer, Vector2(8, 10), Vector2(80, 72), Color(0.85, 0.82, 0.72))
	_add_rect(layer, Vector2(28, 26), Vector2(40, 40), _type_col(
		GameData.pokemon_data.get(
			GameState.pending_battle.get("enemy_data", {}).get("id", "025"), {}
		).get("types", ["Normal"])[0]))

	# Panel info ennemi
	var ep := _add_panel(layer, Vector2(164, 8), Vector2(152, 62))
	_enemy_name   = _add_label(ep, Vector2(6, 4),  "...", 8)
	_enemy_level  = _add_label(ep, Vector2(104, 4), "Lv?", 8)
	_enemy_status = _add_label(ep, Vector2(104, 16), "", 7)
	_add_label(ep, Vector2(6, 24), "HP", 7)
	_add_rect(ep, Vector2(22, 26), Vector2(HP_W, 7), C_HP_BG)
	_enemy_hp_fill = _add_rect(ep, Vector2(22, 26), Vector2(HP_W, 7), Color(0.2, 0.75, 0.2))

	# Zone sprite joueur
	_add_rect(layer, Vector2(200, 88), Vector2(80, 68), Color(0.80, 0.78, 0.68))
	_add_rect(layer, Vector2(224, 104), Vector2(32, 32), Color(0.196, 0.408, 0.941))

	# Panel info joueur
	var pp := _add_panel(layer, Vector2(8, 106), Vector2(160, 70))
	_player_name   = _add_label(pp, Vector2(6, 4),  "...", 8)
	_player_level  = _add_label(pp, Vector2(108, 4), "Lv?", 8)
	_player_status = _add_label(pp, Vector2(108, 16), "", 7)
	_add_label(pp, Vector2(6, 24), "HP", 7)
	_add_rect(pp, Vector2(22, 26), Vector2(HP_W, 7), C_HP_BG)
	_player_hp_fill = _add_rect(pp, Vector2(22, 26), Vector2(HP_W, 7), Color(0.2, 0.75, 0.2))
	_player_hp_text = _add_label(pp, Vector2(6, 42), "?/?", 8)

	# Boîte message
	_add_rect(layer, Vector2(0, 176), Vector2(320, 4), C_DARK)
	var mbox := _add_rect(layer, Vector2(0, 180), Vector2(320, 60), C_PANEL)
	_add_rect(layer, Vector2(0, 180), Vector2(4, 60), C_DARK)
	_add_rect(layer, Vector2(316, 180), Vector2(4, 60), C_DARK)
	_add_rect(layer, Vector2(0, 236), Vector2(320, 4), C_DARK)
	_msg_label = _add_label(mbox, Vector2(10, 6), "...", 9)
	_msg_label.size = Vector2(200, 52)
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ── Menu action ────────────────────────────────────────────────────────────
	_action_menu = _add_overlay(layer, Vector2(210, 182), Vector2(106, 56))
	var a_atk := _make_btn(_action_menu, Vector2(0, 0),  Vector2(104, 16), "⚔  ATTAQUER")
	a_atk.pressed.connect(_on_attack)
	var a_bag := _make_btn(_action_menu, Vector2(0, 18), Vector2(104, 16), "🎒  SAC")
	a_bag.pressed.connect(_on_bag)
	var a_sw  := _make_btn(_action_menu, Vector2(0, 36), Vector2(104, 16), "🔄  SWITCH")
	a_sw.pressed.connect(_on_switch_btn)

	# ── FUIR (sous la boîte message) ──────────────────────────────────────────
	var flee_btn := _make_btn(layer, Vector2(240, 224), Vector2(76, 12), "↩  FUIR")
	flee_btn.add_theme_font_size_override("font_size", 7)
	flee_btn.pressed.connect(_on_flee)

	# ── Menu moves ─────────────────────────────────────────────────────────────
	_move_menu = _add_overlay(layer, Vector2(2, 180), Vector2(316, 58))
	var mpos := [Vector2(0,0), Vector2(160,0), Vector2(0,30), Vector2(160,30)]
	for i in range(4):
		var btn := _make_btn(_move_menu, mpos[i], Vector2(158, 28), "—")
		btn.add_theme_font_size_override("font_size", 8)
		var idx := i
		btn.pressed.connect(func() -> void: _on_move(idx))
		_move_buttons.append(btn)

	# ── Menu items (overlay latéral gauche) ────────────────────────────────────
	_item_menu = _add_panel(layer, Vector2(4, 106), Vector2(204, 68))
	_add_label(_item_menu, Vector2(4, 2), "━ SAC ━", 8)

	# ── Menu Pokémon (overlay latéral gauche) ─────────────────────────────────
	_pkmn_menu = _add_panel(layer, Vector2(4, 4), Vector2(204, 170))
	_add_label(_pkmn_menu, Vector2(4, 2), "━ ÉQUIPE ━", 8)

# ── Helpers UI ────────────────────────────────────────────────────────────────

func _add_rect(p: Node, pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos; r.size = sz; r.color = col
	p.add_child(r); return r

func _add_panel(p: Node, pos: Vector2, sz: Vector2) -> ColorRect:
	var border := _add_rect(p, pos, sz, C_DARK)
	return _add_rect(border, Vector2(2, 2), sz - Vector2(4, 4), C_PANEL)

func _add_overlay(p: Node, pos: Vector2, sz: Vector2) -> Control:
	var c := Control.new()
	c.position = pos; c.size = sz
	p.add_child(c); return c

func _add_label(p: Node, pos: Vector2, text: String, fsize: int) -> Label:
	var l := Label.new()
	l.position = pos; l.text = text
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", C_DARK)
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
