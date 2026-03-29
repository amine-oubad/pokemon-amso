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
var _cancel_learn_btn: Button = null
var _is_trainer_battle: bool = false
var _weather: String = ""        # "", "rain", "sun"
var _weather_turns: int = 0
var _baton_pass_stages: Dictionary = {}  # stat stages to transfer on switch
var _enemy_goes_first: bool = false       # true if enemy attacks before player this turn
var _enemy_queued_move: MoveInstance = null # pre-picked enemy move for turn order
var _turn_phase: int = 0                  # 0 = first attacker, 1 = second attacker done

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
var _charging_move: MoveInstance = null       ## Move two-turn joueur en charge
var _enemy_charging_move: MoveInstance = null ## Move two-turn ennemi en charge
var _selected_move: MoveInstance

# ── Constantes UI (Modern Clean) ──────────────────────────────────────────────
const C_BG     := Color(0.12, 0.14, 0.22)
const C_DARK   := Color(0.08, 0.08, 0.14)
const C_PANEL  := Color(0.16, 0.18, 0.28)
const C_BORDER := Color(0.28, 0.32, 0.45)
const C_HP_BG  := Color(0.10, 0.10, 0.18)
const C_TEXT   := Color(0.92, 0.92, 0.96)
const C_TEXT2  := Color(0.60, 0.62, 0.72)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const HP_W     := 100

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
var _enemy_sprite_node: Control
var _player_sprite_node: Control
var _enemy_sprite_container: Control
var _player_sprite_container: Control

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
			# Two-turn : tour 2, forcer l'attaque
			if _charging_move != null:
				_selected_move = _charging_move
				_charging_move = null
				_set_state(State.PLAYER_MOVE)
				return
			# Struggle — si aucun move utilisable, forcer Struggle
			var has_usable := false
			for mv in player_pkmn.moves:
				if mv.is_usable():
					has_usable = true; break
			if not has_usable:
				_animating = true
				_turn_phase = 0  # Struggle → enemy still gets their turn
				await _do_struggle(player_pkmn, enemy_pkmn)
				_animating = false
				_last_attacker = "player"
				_set_state(State.CHECK_END)
				return
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
				_baton_pass_stages = {}  # Annuler Baton Pass si retour
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
	# Determine turn order based on priority and Speed
	_resolve_turn_order()

## Determines who attacks first based on priority and Speed.
## Player actions (items, switch, flee) always go before enemy moves.
func _resolve_turn_order() -> void:
	_turn_phase = 0
	# Pre-pick the enemy move now to compare priority
	var usable: Array = enemy_pkmn.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())
	if usable.is_empty():
		_set_state(State.PLAYER_MOVE)
		return
	var enemy_move: MoveInstance
	if _enemy_charging_move != null:
		enemy_move = _enemy_charging_move
	else:
		enemy_move = _ai_pick_move(usable)
	_enemy_queued_move = enemy_move

	var player_prio: int = _selected_move.get_priority()
	var enemy_prio: int  = enemy_move.get_priority()

	if player_prio > enemy_prio:
		_set_state(State.PLAYER_MOVE)
	elif enemy_prio > player_prio:
		_enemy_goes_first = true
		_set_state(State.ENEMY_MOVE)
	else:
		# Same priority — faster Pokémon goes first, random on tie
		var p_spd := player_pkmn.get_effective_stat("speed")
		var e_spd := enemy_pkmn.get_effective_stat("speed")
		if p_spd > e_spd:
			_set_state(State.PLAYER_MOVE)
		elif e_spd > p_spd:
			_enemy_goes_first = true
			_set_state(State.ENEMY_MOVE)
		else:
			if randf() < 0.5:
				_set_state(State.PLAYER_MOVE)
			else:
				_enemy_goes_first = true
				_set_state(State.ENEMY_MOVE)

func _on_item_used(item_id: String) -> void:
	if _animating: return
	_item_menu.visible = false
	var idata := GameData.items_data.get(item_id, {})
	GameState.remove_item(item_id)
	_last_attacker = "player"
	_turn_phase = 0  # Item use → enemy still gets their turn
	_animating = true

	match idata.get("category", ""):
		"heal":
			var healed := player_pkmn.heal(idata.get("heal_amount", 20))
			# full_restore also cures status
			var cures: Array = idata.get("cures", [])
			if not cures.is_empty() and player_pkmn.status in cures:
				player_pkmn.status = ""
				player_pkmn.status_turns = 0
			_refresh_ui()
			_msg("%s utilise %s !\n%s récupère %d PV !" % [
				GameState.player_name, idata.get("name", item_id),
				player_pkmn.get_name(), healed
			])
			await get_tree().create_timer(1.8).timeout
			_animating = false
			_set_state(State.CHECK_END)

		"revive":
			# Revive can't be used on active pokemon in battle — refund
			GameState.add_item(item_id)
			_msg("Cet objet ne peut être\nutilisé qu'hors combat !")
			await get_tree().create_timer(1.8).timeout
			_animating = false
			_set_state(State.PLAYER_CHOOSE)

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
				_turn_phase = 1  # Ball was player's action → after enemy move, end turn
				_set_state(State.ENEMY_MOVE)

func _on_switch_pkmn(idx: int) -> void:
	if _animating: return
	if idx == _active_idx: return
	if GameState.team[idx].is_fainted(): return
	var old_name := player_pkmn.get_name()
	# Baton Pass : transférer les stat stages au lieu de reset
	if not _baton_pass_stages.is_empty():
		# Ne pas reset, on transfère
		pass
	else:
		player_pkmn.reset_stat_stages()
	player_pkmn.clear_battle_meta()
	_active_idx  = idx
	player_pkmn  = GameState.team[idx]
	# Appliquer les stat stages de Baton Pass
	if not _baton_pass_stages.is_empty():
		for k in _baton_pass_stages:
			player_pkmn.stat_stages[k] = _baton_pass_stages[k]
		_baton_pass_stages = {}
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
		_turn_phase = 0  # Switch → enemy still gets their turn
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

	# ── Two-turn : tour de charge ─────────────────────────────────────────
	if move.get_effect() == "two_turn" and not player_pkmn.has_meta("charging"):
		move.use()
		player_pkmn.set_meta("charging", true)
		_charging_move = move  # Forcer l'exécution au tour suivant
		_msg("%s accumule de l'énergie !" % player_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Tour 2 two-turn : retirer le flag charging
	if player_pkmn.has_meta("charging"):
		player_pkmn.remove_meta("charging")

	move.use()

	# ── Baton Pass : switch en gardant les stat stages ────────────────────
	if move.get_effect() == "baton_pass":
		_msg("%s utilise %s !" % [player_pkmn.get_name(), move.get_name()])
		await get_tree().create_timer(1.2).timeout
		_baton_pass_stages = player_pkmn.stat_stages.duplicate()
		_animating = false
		_forced_switch = false
		_set_state(State.CHOOSE_POKEMON)
		return

	# ── Rain Dance : météo pluie ──────────────────────────────────────────
	if move.get_effect() == "rain_dance":
		_weather = "rain"
		_weather_turns = 5
		_msg("%s utilise %s !\nIl commence à pleuvoir !" % [player_pkmn.get_name(), move.get_name()])
		await get_tree().create_timer(1.8).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# ── Protect : se protéger (effet déjà géré via MoveEffects) ───────────
	if move.get_effect() == "protect":
		var eff := MoveEffects.apply_move_effect(move, player_pkmn, enemy_pkmn)
		if eff != "":
			_msg(eff); await get_tree().create_timer(1.2).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Vérif Protect adverse
	if enemy_pkmn.has_meta("protect") and enemy_pkmn.get_meta("protect"):
		_msg("%s utilise %s !\n%s se protège !" % [player_pkmn.get_name(), move.get_name(), enemy_pkmn.get_name()])
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Précision
	if not BattleCalc.accuracy_check(move, player_pkmn, enemy_pkmn):
		_msg("%s rate son attaque !" % player_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Dégâts (avec bonus météo)
	var calc := BattleCalc.calculate_damage(player_pkmn, enemy_pkmn, move)
	var weather_mult := _get_weather_multiplier(move.get_type())
	calc.damage = int(calc.damage * weather_mult)
	enemy_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [player_pkmn.get_name(), move.get_name()]
	if calc.critical: msg += "\nCoup critique !"
	if calc.effectiveness == 0.0:
		msg += "\nSans effet sur %s !" % enemy_pkmn.get_name()
	elif calc.effectiveness > 1.0:
		msg += "\nC'est super efficace !"
	elif calc.effectiveness < 1.0:
		msg += "\nCe n'est pas très efficace..."
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
		# Struggle — typeless 50 power + 1/4 recoil
		await _do_struggle(enemy_pkmn, player_pkmn)
		_animating = false
		_set_state(State.CHECK_END)
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

	var move: MoveInstance
	# Use pre-picked move from turn order resolution if available
	if _enemy_queued_move != null:
		move = _enemy_queued_move
		_enemy_queued_move = null
		if _enemy_charging_move != null and _enemy_charging_move == move:
			_enemy_charging_move = null
	# Two-turn : tour 2, forcer le même move
	elif _enemy_charging_move != null:
		move = _enemy_charging_move
		_enemy_charging_move = null
	else:
		move = _ai_pick_move(usable)

	# ── Two-turn : tour de charge ─────────────────────────────────────────
	if move.get_effect() == "two_turn" and not enemy_pkmn.has_meta("charging"):
		move.use()
		enemy_pkmn.set_meta("charging", true)
		_enemy_charging_move = move
		_msg("%s accumule de l'énergie !" % enemy_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Tour 2 two-turn : retirer le flag charging
	if enemy_pkmn.has_meta("charging"):
		enemy_pkmn.remove_meta("charging")

	move.use()

	# ── Rain Dance ────────────────────────────────────────────────────────
	if move.get_effect() == "rain_dance":
		_weather = "rain"
		_weather_turns = 5
		_msg("%s utilise %s !\nIl commence à pleuvoir !" % [enemy_pkmn.get_name(), move.get_name()])
		await get_tree().create_timer(1.8).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# ── Protect ───────────────────────────────────────────────────────────
	if move.get_effect() == "protect":
		var eff := MoveEffects.apply_move_effect(move, enemy_pkmn, player_pkmn)
		if eff != "":
			_msg(eff); await get_tree().create_timer(1.2).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# ── Baton Pass (IA : pas de switch, juste boost stats) ────────────────
	if move.get_effect() == "baton_pass":
		_msg("%s utilise %s !" % [enemy_pkmn.get_name(), move.get_name()])
		await get_tree().create_timer(1.2).timeout
		# IA trainer : switch to next alive if possible
		if _is_trainer_battle:
			var next_idx := -1
			for i in range(_trainer_team.size()):
				if i != _trainer_team_idx and not _trainer_team[i].is_fainted():
					next_idx = i; break
			if next_idx >= 0:
				var old_stages := enemy_pkmn.stat_stages.duplicate()
				_trainer_team_idx = next_idx
				enemy_pkmn = _trainer_team[next_idx]
				for k in old_stages:
					enemy_pkmn.stat_stages[k] = old_stages[k]
				_refresh_ui()
				_msg("%s passe le relais à %s !" % [_trainer_name, enemy_pkmn.get_name()])
				await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	# Vérif Protect joueur
	if player_pkmn.has_meta("protect") and player_pkmn.get_meta("protect"):
		_msg("%s utilise %s !\n%s se protège !" % [enemy_pkmn.get_name(), move.get_name(), player_pkmn.get_name()])
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	if not BattleCalc.accuracy_check(move, enemy_pkmn, player_pkmn):
		_msg("%s rate son attaque !" % enemy_pkmn.get_name())
		await get_tree().create_timer(1.5).timeout
		_animating = false
		_set_state(State.CHECK_END)
		return

	var calc := BattleCalc.calculate_damage(enemy_pkmn, player_pkmn, move)
	var weather_mult := _get_weather_multiplier(move.get_type())
	calc.damage = int(calc.damage * weather_mult)
	player_pkmn.take_damage(calc.damage)
	_refresh_ui()

	var msg := "%s utilise %s !" % [enemy_pkmn.get_name(), move.get_name()]
	if calc.critical: msg += "\nCoup critique !"
	if calc.effectiveness == 0.0:
		msg += "\nSans effet sur %s !" % player_pkmn.get_name()
	elif calc.effectiveness > 1.0:
		msg += "\nC'est super efficace !"
	elif calc.effectiveness < 1.0:
		msg += "\nCe n'est pas très efficace..."
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
		var chance := mini(255, int(p_spd * 32.0 / maxi(1, e_spd) + 30.0) * _flee_attempts)
		if chance >= 255:
			success = true
		else:
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
		_turn_phase = 0  # Failed flee → enemy gets their turn
		_set_state(State.CHECK_END)

# ── Check fin de tour ─────────────────────────────────────────────────────────

func _check_end() -> void:
	if enemy_pkmn.is_fainted():
		_reset_protect_flags()
		_set_state(State.SHOW_XP)
		return
	if player_pkmn.is_fainted():
		_reset_protect_flags()
		await _handle_player_ko()
		return

	# Phase 0: first attacker just finished → apply EOT on defender, then second attacker
	# Phase 1: second attacker done → apply EOT on first attacker, then end turn
	if _turn_phase == 0:
		# First attacker just finished — apply EOT on defender
		_turn_phase = 1
		if _last_attacker == "player":
			await _apply_eot(enemy_pkmn)
			if enemy_pkmn.is_fainted(): _reset_protect_flags(); _turn_phase = 0; _set_state(State.SHOW_XP); return
			_set_state(State.ENEMY_MOVE)
		else:
			await _apply_eot(player_pkmn)
			if player_pkmn.is_fainted(): _reset_protect_flags(); _turn_phase = 0; await _handle_player_ko(); return
			_set_state(State.PLAYER_MOVE)
	else:
		# Second attacker done — apply EOT on first attacker, end full turn
		_turn_phase = 0
		if _last_attacker == "player":
			# Player was second (enemy went first) → EOT on enemy
			await _apply_eot(enemy_pkmn)
			if enemy_pkmn.is_fainted(): _reset_protect_flags(); _set_state(State.SHOW_XP); return
		else:
			# Enemy was second (player went first) → EOT on player
			await _apply_eot(player_pkmn)
			if player_pkmn.is_fainted(): _reset_protect_flags(); await _handle_player_ko(); return
		_enemy_goes_first = false
		await _tick_weather()
		_reset_protect_flags()
		_set_state(State.PLAYER_CHOOSE)

func _apply_eot(pkmn: PokemonInstance) -> void:
	var msg := MoveEffects.apply_end_of_turn(pkmn)
	if msg != "":
		_msg(msg); _refresh_ui()
		await get_tree().create_timer(1.2).timeout

func _tick_weather() -> void:
	if _weather_turns > 0:
		_weather_turns -= 1
		if _weather_turns == 0:
			_msg("La pluie s'arrête.")
			_weather = ""
			await get_tree().create_timer(1.0).timeout

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

	# Bouton "Ne pas apprendre" (utiliser le 4e slot s'il est caché, sinon ajouter temporaire)
	if _cancel_learn_btn == null:
		_cancel_learn_btn = Button.new()
		_cancel_learn_btn.position = Vector2(80, 60)
		_cancel_learn_btn.size     = Vector2(156, 16)
		_cancel_learn_btn.add_theme_font_size_override("font_size", 8)
		_move_menu.add_child(_cancel_learn_btn)
	_cancel_learn_btn.text    = "✕ Ne pas apprendre"
	_cancel_learn_btn.visible = true
	for conn in _cancel_learn_btn.pressed.get_connections():
		_cancel_learn_btn.pressed.disconnect(conn.callable)
	var mid := new_move_id
	_cancel_learn_btn.pressed.connect(func() -> void: _on_skip_learn(mid))

	_msg("Oublier quelle capacité\npour %s ?" % new_name)

func _on_skip_learn(new_move_id: String) -> void:
	_move_menu.visible = false
	if _cancel_learn_btn: _cancel_learn_btn.visible = false
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)
	_msg("%s n'apprend pas %s." % [player_pkmn.get_name(), new_name])
	_reconnect_move_buttons()
	_animating = true
	await get_tree().create_timer(1.5).timeout
	_animating = false
	_advance_post_xp()

func _on_replace_move(idx: int, new_move_id: String) -> void:
	if _cancel_learn_btn: _cancel_learn_btn.visible = false
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

	_msg("Hein !? %s évolue !\n(X pour annuler)" % old_name)

	# Fenêtre d'annulation de 3 secondes
	var cancelled := false
	var timer := 0.0
	while timer < 3.0:
		await get_tree().process_frame
		timer += get_process_delta_time()
		if Input.is_action_just_pressed("ui_cancel"):
			cancelled = true
			break

	if cancelled:
		_msg("%s n'évolue pas !" % old_name)
		await get_tree().create_timer(1.5).timeout
		_go_to_next_or_end()
		return

	player_pkmn.evolve(target_id)
	_refresh_ui()
	_msg("Félicitations !\n%s a évolué en %s !" % [old_name, new_name])
	GameState.register_seen(target_id)
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
	player_pkmn.clear_battle_meta()
	# Clear meta on all team members (leech seed etc.)
	for pkmn in GameState.team:
		pkmn.clear_battle_meta()

	# Défaite — afficher l'écran Game Over
	if result == "lose":
		GameOverScreen.show_game_over()
		return

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

		# Dialogue post-combat du dresseur
		var after_key: String = GameState.pending_battle.get("dialogue_after", "")
		if after_key != "":
			var after_lines: Array = GameData.dialogues_data.get(after_key, [])
			if not after_lines.is_empty():
				DialogueManager.start_dialogue(after_lines)
				await DialogueManager.dialogue_finished

	GameState.pending_battle = {}
	EventBus.battle_ended.emit(result)
	get_tree().change_scene_to_file(GameState.return_to_scene)

# ── Struggle (no PP left) ──────────────────────────────────────────────────────

func _do_struggle(attacker: PokemonInstance, defender: PokemonInstance) -> void:
	_msg("%s n'a plus de PP !\n%s utilise Lutte !" % [attacker.get_name(), attacker.get_name()])
	await get_tree().create_timer(1.5).timeout
	# Typeless 50 power physical attack
	var atk_val: int = attacker.get_effective_stat("atk")
	var def_val: int = defender.get_effective_stat("def")
	var base: int = int(int(int(2.0 * attacker.level / 5.0 + 2.0) * 50 * atk_val / def_val) / 50.0) + 2
	var rng := randf_range(0.85, 1.0)
	var dmg := maxi(1, int(base * rng))
	defender.take_damage(dmg)
	# Recoil: 1/4 of max HP
	var recoil := maxi(1, int(attacker.max_hp / 4.0))
	attacker.take_damage(recoil)
	_refresh_ui()
	_msg("%s inflige %d dégâts !\n%s subit le contrecoup !" % [attacker.get_name(), dmg, attacker.get_name()])
	await get_tree().create_timer(1.8).timeout

# ── Météo ─────────────────────────────────────────────────────────────────────

func _get_weather_multiplier(move_type: String) -> float:
	if _weather == "rain":
		if move_type == "Water": return 1.5
		if move_type == "Fire":  return 0.5
	return 1.0

func _reset_protect_flags() -> void:
	# Clear flinch at end of turn so it doesn't persist
	if player_pkmn.has_meta("flinch"): player_pkmn.remove_meta("flinch")
	if enemy_pkmn.has_meta("flinch"): enemy_pkmn.remove_meta("flinch")
	# Reset consecutive counter for Pokemon who did NOT protect this turn
	if not player_pkmn.has_meta("protect"):
		if player_pkmn.has_meta("protect_consecutive"): player_pkmn.remove_meta("protect_consecutive")
	else:
		player_pkmn.remove_meta("protect")
	if not enemy_pkmn.has_meta("protect"):
		if enemy_pkmn.has_meta("protect_consecutive"): enemy_pkmn.remove_meta("protect_consecutive")
	else:
		enemy_pkmn.remove_meta("protect")

# ── IA ennemie ────────────────────────────────────────────────────────────────

func _ai_pick_move(usable: Array) -> MoveInstance:
	# Score chaque move : power × type_effectiveness × STAB × category_bonus
	# 20% de chance de choisir au hasard (pour varier)
	if randf() < 0.2:
		return usable[randi() % usable.size()]

	var best_move: MoveInstance = usable[0]
	var best_score: float = -1.0

	for mv: MoveInstance in usable:
		var power: int = mv.get_power()
		if power == 0:
			# Moves de statut : score faible sauf si l'adversaire n'a pas de statut
			var score := 15.0 if player_pkmn.status == "" else 2.0
			if score > best_score:
				best_score = score
				best_move = mv
			continue

		var move_type: String = mv.get_type()
		var eff: float = GameData.get_total_effectiveness(move_type, player_pkmn.get_types())
		var stab: float = 1.5 if move_type in enemy_pkmn.get_types() else 1.0
		var score: float = power * eff * stab

		if score > best_score:
			best_score = score
			best_move = mv

	return best_move

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

	# Refresh sprites
	_refresh_pokemon_sprites()

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
	if r > 0.50: return Color(0.20, 0.85, 0.40)
	if r > 0.20: return Color(0.95, 0.75, 0.10)
	return Color(0.95, 0.22, 0.15)

func _refresh_pokemon_sprites() -> void:
	# Enemy sprite
	if _enemy_sprite_node != null:
		_enemy_sprite_node.queue_free()
	_enemy_sprite_node = SpriteLoader.make_sprite(enemy_pkmn.pokemon_id, "front", Vector2(80, 80))
	_enemy_sprite_node.position = Vector2(4, 4)
	_enemy_sprite_container.add_child(_enemy_sprite_node)
	# Player sprite
	if _player_sprite_node != null:
		_player_sprite_node.queue_free()
	_player_sprite_node = SpriteLoader.make_sprite(player_pkmn.pokemon_id, "back", Vector2(80, 80))
	_player_sprite_node.position = Vector2(6, -4)
	_player_sprite_container.add_child(_player_sprite_node)

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
		if cat not in ["heal", "ball", "status_cure", "revive"]: continue
		found = true
		var btn := _make_btn(_item_menu, Vector2(2, y), Vector2(196, 18),
			"%s   x%d" % [idata.get("name", item_id), GameState.bag[item_id]])
		var disable := false
		if cat == "heal":
			var hp_full := player_pkmn.current_hp >= player_pkmn.max_hp
			var has_curable_status := false
			var cures: Array = idata.get("cures", [])
			if not cures.is_empty() and player_pkmn.status in cures:
				has_curable_status = true
			disable = hp_full and not has_curable_status
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
		var bg := _add_rect(_pkmn_menu, Vector2(2, y), Vector2(200, 28),
			Color(0.22, 0.26, 0.40) if is_active else (Color(0.12, 0.12, 0.18) if is_faint else C_PANEL))
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

	# Fond gradient (deux rectangles pour simuler un dégradé)
	_add_rect(layer, Vector2.ZERO, Vector2(320, 120), Color(0.10, 0.12, 0.20))
	_add_rect(layer, Vector2(0, 120), Vector2(320, 60), Color(0.14, 0.16, 0.26))
	_add_rect(layer, Vector2(0, 180), Vector2(320, 60), C_DARK)

	# Ligne de sol stylisée
	_add_rect(layer, Vector2(0, 156), Vector2(320, 2), Color(0.22, 0.25, 0.38))
	_add_rect(layer, Vector2(0, 158), Vector2(320, 18), Color(0.11, 0.13, 0.22, 0.6))

	# ── Zone sprite ennemi (coin supérieur gauche) ─────────────────────────────
	_enemy_sprite_container = Control.new()
	_enemy_sprite_container.position = Vector2(8, 4)
	_enemy_sprite_container.size = Vector2(88, 88)
	layer.add_child(_enemy_sprite_container)
	# Fond circulaire derrière le sprite
	var enemy_glow := _add_rect(_enemy_sprite_container, Vector2(4, 48), Vector2(80, 6), Color(0.2, 0.2, 0.3, 0.5))
	# Sprite
	_enemy_sprite_node = SpriteLoader.make_sprite(
		GameState.pending_battle.get("enemy_data", {}).get("id", "025"), "front", Vector2(80, 80))
	_enemy_sprite_node.position = Vector2(4, 4)
	_enemy_sprite_container.add_child(_enemy_sprite_node)

	# ── Panel info ennemi (moderne — coin supérieur droit) ────────────────────
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
	# Type badge ennemi
	var etype: String = GameData.pokemon_data.get(
		GameState.pending_battle.get("enemy_data", {}).get("id", "025"), {}
	).get("types", ["Normal"])[0]
	var etype_badge := _add_rect(ep, Vector2(8, 38), Vector2(50, 12), _type_col(etype).darkened(0.3))
	var etype_lbl := _add_label(etype_badge, Vector2(2, -1), etype.to_upper(), 6)
	etype_lbl.add_theme_color_override("font_color", Color.WHITE)

	# ── Zone sprite joueur (coin inférieur droit) ──────────────────────────────
	_player_sprite_container = Control.new()
	_player_sprite_container.position = Vector2(220, 68)
	_player_sprite_container.size = Vector2(92, 92)
	layer.add_child(_player_sprite_container)
	# Ombre sous le sprite
	_add_rect(_player_sprite_container, Vector2(6, 70), Vector2(80, 6), Color(0.15, 0.15, 0.25, 0.5))
	# Sprite back
	var player_id := "025"
	if GameState.team.size() > 0:
		player_id = GameState.team[0].pokemon_id if _active_idx == 0 else GameState.team[_active_idx].pokemon_id
	_player_sprite_node = SpriteLoader.make_sprite(player_id, "back", Vector2(80, 80))
	_player_sprite_node.position = Vector2(6, -4)
	_player_sprite_container.add_child(_player_sprite_node)

	# ── Panel info joueur (moderne — coin inférieur gauche) ───────────────────
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
	# XP bar sous HP
	_add_rect(pp, Vector2(26, 38), Vector2(HP_W, 3), Color(0.08, 0.08, 0.14))
	var xp_fill := _add_rect(pp, Vector2(26, 38), Vector2(0, 3), Color(0.3, 0.5, 0.95))
	xp_fill.name = "XPFill"

	# ── Boîte message (moderne) ───────────────────────────────────────────────
	_add_rect(layer, Vector2(0, 175), Vector2(320, 1), C_BORDER)
	var mbox := _add_rect(layer, Vector2(0, 176), Vector2(320, 64), C_DARK)
	_add_rect(mbox, Vector2(0, 0), Vector2(4, 64), C_ACCENT)  # accent bar gauche
	_msg_label = _add_label(mbox, Vector2(12, 8), "...", 9)
	_msg_label.size = Vector2(194, 52)
	_msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_msg_label.add_theme_color_override("font_color", C_TEXT)

	# ── Menu action (moderne) ─────────────────────────────────────────────────
	_action_menu = _add_overlay(layer, Vector2(210, 178), Vector2(108, 60))
	var a_atk := _make_btn(_action_menu, Vector2(0, 0),  Vector2(106, 18), "ATTAQUER")
	a_atk.pressed.connect(_on_attack)
	var a_bag := _make_btn(_action_menu, Vector2(0, 20), Vector2(106, 18), "SAC")
	a_bag.pressed.connect(_on_bag)
	var a_sw  := _make_btn(_action_menu, Vector2(0, 40), Vector2(52, 18), "SWITCH")
	a_sw.pressed.connect(_on_switch_btn)
	var flee_btn := _make_btn(_action_menu, Vector2(54, 40), Vector2(52, 18), "FUIR")
	flee_btn.pressed.connect(_on_flee)

	# ── Menu moves (moderne — 2x2 grid) ───────────────────────────────────────
	_move_menu = _add_overlay(layer, Vector2(2, 176), Vector2(316, 62))
	var mpos := [Vector2(0,2), Vector2(158,2), Vector2(0,32), Vector2(158,32)]
	for i in range(4):
		var btn := _make_btn(_move_menu, mpos[i], Vector2(156, 28), "—")
		btn.add_theme_font_size_override("font_size", 8)
		var idx := i
		btn.pressed.connect(func() -> void: _on_move(idx))
		_move_buttons.append(btn)

	# ── Menu items (overlay) ──────────────────────────────────────────────────
	_item_menu = _add_modern_panel(layer, Vector2(4, 100), Vector2(204, 72))
	var item_title := _add_label(_item_menu, Vector2(6, 2), "SAC", 8)
	item_title.add_theme_color_override("font_color", C_ACCENT)

	# ── Menu Pokémon (overlay) ────────────────────────────────────────────────
	_pkmn_menu = _add_modern_panel(layer, Vector2(4, 4), Vector2(210, 170))
	var pkmn_title := _add_label(_pkmn_menu, Vector2(6, 2), "EQUIPE", 8)
	pkmn_title.add_theme_color_override("font_color", C_ACCENT)

# ── Helpers UI ────────────────────────────────────────────────────────────────

func _add_rect(p: Node, pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos; r.size = sz; r.color = col
	p.add_child(r); return r

func _add_panel(p: Node, pos: Vector2, sz: Vector2) -> ColorRect:
	var border := _add_rect(p, pos, sz, C_BORDER)
	return _add_rect(border, Vector2(1, 1), sz - Vector2(2, 2), C_PANEL)

func _add_modern_panel(p: Node, pos: Vector2, sz: Vector2) -> ColorRect:
	var border := _add_rect(p, pos - Vector2(1, 1), sz + Vector2(2, 2), C_BORDER)
	var panel := _add_rect(border, Vector2(1, 1), sz, C_PANEL)
	# Subtle top highlight
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
