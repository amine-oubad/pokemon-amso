class_name BattleTurnManager
extends Node
## Execution des tours de combat : ordre, attaques, fuite, struggle.
## Gen 1-9 compatible. Enfant de BattleScene.

var scene  # Reference to BattleScene

var _enemy_queued_move: MoveInstance = null
var _enemy_goes_first: bool = false
var _turn_phase: int = 0
var _charging_move: MoveInstance = null
var _enemy_charging_move: MoveInstance = null

# =========================================================================
#  Turn order (with Trick Room + Prankster + Tailwind)
# =========================================================================

func resolve_turn_order(selected_move: MoveInstance) -> void:
	_turn_phase = 0
	var enemy = scene.enemy_pkmn
	var player = scene.player_pkmn

	var usable: Array = enemy.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())
	if usable.is_empty():
		scene.set_state(scene.State.PLAYER_MOVE)
		return

	var enemy_move: MoveInstance
	if _enemy_charging_move != null:
		enemy_move = _enemy_charging_move
	else:
		enemy_move = scene.ai.pick_move(enemy, player, scene.field)
	_enemy_queued_move = enemy_move

	# Priority with Prankster / Gale Wings
	var player_prio: int = selected_move.get_priority() + AbilityEffects.get_priority_modifier(player, selected_move.get_category())
	var enemy_prio: int = enemy_move.get_priority() + AbilityEffects.get_priority_modifier(enemy, enemy_move.get_category())

	if player_prio > enemy_prio:
		_enemy_goes_first = false
		scene.set_state(scene.State.PLAYER_MOVE)
	elif enemy_prio > player_prio:
		_enemy_goes_first = true
		scene.set_state(scene.State.ENEMY_MOVE)
	else:
		var p_spd := _get_battle_speed(player)
		var e_spd := _get_battle_speed(enemy)

		# Trick Room reverses speed
		if scene.field.is_trick_room():
			if p_spd < e_spd:
				_enemy_goes_first = false
				scene.set_state(scene.State.PLAYER_MOVE)
			elif e_spd < p_spd:
				_enemy_goes_first = true
				scene.set_state(scene.State.ENEMY_MOVE)
			else:
				_resolve_speed_tie()
		else:
			if p_spd > e_spd:
				_enemy_goes_first = false
				scene.set_state(scene.State.PLAYER_MOVE)
			elif e_spd > p_spd:
				_enemy_goes_first = true
				scene.set_state(scene.State.ENEMY_MOVE)
			else:
				_resolve_speed_tie()

func _resolve_speed_tie() -> void:
	if randf() < 0.5:
		_enemy_goes_first = false
		scene.set_state(scene.State.PLAYER_MOVE)
	else:
		_enemy_goes_first = true
		scene.set_state(scene.State.ENEMY_MOVE)

## Effective battle speed including ability, item, tailwind
func _get_battle_speed(pkmn: PokemonInstance) -> int:
	var spd := BattleCalc.get_effective_speed(pkmn, scene.field)
	# Tailwind doubles speed
	var side := "player" if pkmn == scene.player_pkmn else "enemy"
	if scene.field.has_tailwind(side):
		spd *= 2
	return spd

# =========================================================================
#  Shared attack execution logic
# =========================================================================

## Execute an attack for either side. Returns true if a pivot switch should happen.
func _execute_attack(attacker: PokemonInstance, defender: PokemonInstance, move: MoveInstance, atk_side: String) -> bool:
	var is_player := (atk_side == "player")
	var def_side := "enemy" if is_player else "player"
	var pivot_switch := false

	# Set current move metadata for ability hooks
	attacker.set_bmeta("current_move_id", move.move_id)
	attacker.set_bmeta("current_move_type", move.get_type())

	# Status check
	var sc := MoveEffects.check_can_move(attacker)
	scene.ui.msg(sc.message if sc.message != "" else "%s attaque !" % attacker.get_name())
	if sc.message != "":
		scene.ui.refresh()
		await scene.get_tree().create_timer(1.2).timeout
	if not sc.can_move:
		return false

	# Two-turn: charge phase
	if move.get_effect() == "two_turn" and not attacker.has_bmeta("charging"):
		move.use()
		if AbilityEffects.check_pressure(defender):
			move.use()
		attacker.set_bmeta("charging", true)
		if is_player:
			_charging_move = move
		else:
			_enemy_charging_move = move
		scene.ui.msg("%s accumule de l'energie !" % attacker.get_name())
		await scene.get_tree().create_timer(1.5).timeout
		return false

	if attacker.has_bmeta("charging"):
		attacker.remove_bmeta("charging")

	move.use()
	if AbilityEffects.check_pressure(defender):
		move.use()
	attacker.set_bmeta("last_move_used", move.move_id)

	# Choice lock
	if HeldItemEffects.is_choice_locked(attacker):
		attacker.set_bmeta("choice_locked_move", move.move_id)

	# Gorilla Tactics lock (same as choice)
	if attacker.ability == "gorilla_tactics":
		attacker.set_bmeta("choice_locked_move", move.move_id)

	# -ate ability type modification
	var actual_type := AbilityEffects.get_modified_move_type(attacker, move.get_type(), move.move_id)

	# Baton Pass
	if move.get_effect() == "baton_pass":
		scene.ui.msg("%s utilise %s !" % [attacker.get_name(), move.get_name()])
		await scene.get_tree().create_timer(1.2).timeout
		if is_player:
			scene._baton_pass_stages = attacker.stat_stages.duplicate()
			scene._forced_switch = false
			scene.set_state(scene.State.CHOOSE_POKEMON)
		else:
			_enemy_baton_pass()
		return false

	# Protect variants
	var effect := move.get_effect()
	if effect in ["protect", "king_shield", "baneful_bunker", "spiky_shield"]:
		var eff := MoveEffects.apply_move_effect(move, attacker, defender, 0, scene.field)
		for m in eff:
			scene.ui.msg(m)
			await scene.get_tree().create_timer(1.2).timeout
		return false

	# Check opponent Protect
	if defender.has_bmeta("protect") and defender.get_bmeta("protect"):
		scene.ui.msg("%s utilise %s !\n%s se protege !" % [attacker.get_name(), move.get_name(), defender.get_name()])
		await scene.get_tree().create_timer(1.5).timeout

		# Protect variant punishments (contact into King's Shield, Spiky Shield, Baneful Bunker)
		if MoveEffects.is_contact_move(move.move_id):
			if defender.has_bmeta("king_shield"):
				attacker.modify_stat_stage("atk", -1)
				scene.ui.msg("%s : l'Attaque baisse a cause du Bouclier Royal !" % attacker.get_name())
				await scene.get_tree().create_timer(1.0).timeout
			elif defender.has_bmeta("spiky_shield"):
				var dmg := maxi(1, int(attacker.max_hp / 8.0))
				attacker.take_damage(dmg)
				scene.ui.msg("%s est blesse par le Bouclier Piquant !" % attacker.get_name())
				scene.ui.refresh()
				await scene.get_tree().create_timer(1.0).timeout
			elif defender.has_bmeta("baneful_bunker"):
				if attacker.status == "":
					attacker.status = "poison"
					scene.ui.msg("%s est empoisonne par le Blockhaus !" % attacker.get_name())
					scene.ui.refresh()
					await scene.get_tree().create_timer(1.0).timeout
		return false

	# Status-only moves
	if move.get_power() == 0 and effect != "fixed_damage_level":
		scene.ui.msg("%s utilise %s !" % [attacker.get_name(), move.get_name()])
		await scene.get_tree().create_timer(1.0).timeout

		# Magic Bounce reflects status moves
		if AbilityEffects.has_magic_bounce(defender) and move.get_category() == "status":
			scene.ui.msg("%s renvoie l'attaque avec Miroir Magik !" % defender.get_name())
			await scene.get_tree().create_timer(1.0).timeout
			var eff := MoveEffects.apply_move_effect(move, defender, attacker, 0, scene.field)
			for m in eff:
				scene.ui.msg(m)
				scene.ui.refresh()
				await scene.get_tree().create_timer(1.2).timeout
			return false

		# Powder move immunity (Grass types, Overcoat, Safety Goggles)
		if MoveEffects.is_powder_move(move.move_id):
			if "Grass" in defender.get_types() or defender.ability == "overcoat":
				scene.ui.msg("Ca n'affecte pas %s !" % defender.get_name())
				await scene.get_tree().create_timer(1.2).timeout
				return false

		var eff := MoveEffects.apply_move_effect(move, attacker, defender, 0, scene.field)
		for m in eff:
			scene.ui.msg(m)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.2).timeout

		# Parting Shot: lower stats then switch out
		if effect == "parting_shot":
			pivot_switch = true
		return pivot_switch

	# Accuracy check
	if not BattleCalc.accuracy_check(move, attacker, defender):
		scene.ui.msg("%s rate son attaque !" % attacker.get_name())
		await scene.get_tree().create_timer(1.5).timeout
		return false

	# Damage calculation
	var calc := BattleCalc.calculate_damage(attacker, defender, move, scene.field)

	# Ability block (Levitate, Flash Fire, etc.)
	if calc.blocked:
		scene.ui.msg("%s utilise %s !\n%s" % [attacker.get_name(), move.get_name(), calc.block_message])
		scene.ui.refresh()
		await scene.get_tree().create_timer(1.8).timeout
		return false

	# Screen reduction
	calc.damage = BattleCalc.apply_screen_reduction(calc.damage, scene.field, def_side, move.get_category(), calc.critical)

	# Multi-hit loop
	var total_damage := 0
	for hit_i in range(calc.hits):
		var surv := BattleCalc.check_survival(defender, calc.damage)
		var actual_dmg: int = surv.final_damage if surv.survived else calc.damage
		defender.take_damage(actual_dmg)
		total_damage += actual_dmg
		scene.ui.refresh()

		if hit_i == 0:
			var msg := "%s utilise %s !" % [attacker.get_name(), move.get_name()]
			if calc.critical: msg += "\nCoup critique !"
			if calc.effectiveness == 0.0:
				msg += "\nSans effet sur %s !" % defender.get_name()
			elif calc.effectiveness > 1.0:
				msg += "\nC'est super efficace !"
			elif calc.effectiveness < 1.0:
				msg += "\nCe n'est pas tres efficace..."
			scene.ui.msg(msg)

		for sm in surv.messages:
			await scene.get_tree().create_timer(0.8).timeout
			scene.ui.msg(sm)

		await scene.get_tree().create_timer(0.6 if calc.hits > 1 else 1.8).timeout

		if defender.is_fainted():
			break

	if calc.hits > 1 and not defender.is_fainted():
		scene.ui.msg("Touche %d fois !" % calc.hits)
		await scene.get_tree().create_timer(1.0).timeout

	# Move effect (recoil, drain, status, etc.)
	# Sheer Force suppresses secondary effects but boosts damage (already in calc)
	if not defender.is_fainted() and not AbilityEffects.suppresses_secondary_effects(attacker):
		var eff := MoveEffects.apply_move_effect(move, attacker, defender, total_damage, scene.field)
		for m in eff:
			scene.ui.msg(m)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.2).timeout
	elif not defender.is_fainted():
		# Still apply guaranteed effects (recoil, drain) even with Sheer Force
		var eff_key := move.get_effect()
		if eff_key in ["recoil_quarter", "recoil_third", "recoil_half", "drain_half", "drain_quarter", "drain_three_quarter"]:
			var eff := MoveEffects.apply_move_effect(move, attacker, defender, total_damage, scene.field)
			for m in eff:
				scene.ui.msg(m)
				scene.ui.refresh()
				await scene.get_tree().create_timer(1.2).timeout

	# Contact ability effects (Static, Flame Body, Rough Skin, etc.)
	if MoveEffects.is_contact_move(move.move_id) and not defender.is_fainted():
		var contact_msg := AbilityEffects.on_after_contact(attacker, defender)
		if contact_msg != "":
			scene.ui.msg(contact_msg)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.2).timeout

	# Held item after attacking (Life Orb, Shell Bell)
	# Sheer Force prevents Life Orb recoil
	if not AbilityEffects.suppresses_secondary_effects(attacker):
		var item_after := HeldItemEffects.on_after_attacking(attacker, total_damage)
		if item_after.self_damage > 0:
			attacker.take_damage(item_after.self_damage)
			scene.ui.msg(item_after.message)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.0).timeout
		if item_after.self_heal > 0:
			attacker.heal(item_after.self_heal)
			scene.ui.msg(item_after.message)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.0).timeout

	# Rocky Helmet on defender
	if MoveEffects.is_contact_move(move.move_id) and not defender.is_fainted():
		var helmet_msg := HeldItemEffects.on_after_hit_contact(attacker, defender)
		if helmet_msg != "":
			scene.ui.msg(helmet_msg)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.0).timeout

	# Color Change
	if not defender.is_fainted():
		var cc_msg := AbilityEffects.check_color_change(defender, actual_type)
		if cc_msg != "":
			scene.ui.msg(cc_msg)
			await scene.get_tree().create_timer(1.0).timeout

	# Berry check on defender
	if not defender.is_fainted():
		var berry := HeldItemEffects.check_berry(defender)
		if berry.message != "":
			scene.ui.msg(berry.message)
			scene.ui.refresh()
			if berry.consume: HeldItemEffects.consume_item(defender)
			await scene.get_tree().create_timer(1.0).timeout

	# Moxie / Beast Boost / Soul Heart on KO
	if defender.is_fainted():
		var ko_msg := AbilityEffects.on_faint_opponent(attacker)
		if ko_msg != "":
			scene.ui.msg(ko_msg)
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.0).timeout

		# Destiny Bond
		if defender.has_bmeta("destiny_bond"):
			attacker.take_damage(attacker.current_hp)
			scene.ui.msg("%s emporte %s avec lui !" % [defender.get_name(), attacker.get_name()])
			scene.ui.refresh()
			await scene.get_tree().create_timer(1.5).timeout

	# U-turn / Volt Switch / Flip Turn — pivot after dealing damage
	if effect in ["u_turn"] and not attacker.is_fainted() and not defender.is_fainted():
		pivot_switch = true

	# Clean up move metadata
	attacker.remove_bmeta("current_move_id")
	attacker.remove_bmeta("current_move_type")

	return pivot_switch

# =========================================================================
#  Player move
# =========================================================================

func do_player_move() -> void:
	if scene._animating: return
	scene._animating = true
	scene._last_attacker = "player"
	var player = scene.player_pkmn
	var move = scene._selected_move

	var pivot := await _execute_attack(player, scene.enemy_pkmn, move, "player")

	if pivot and not player.is_fainted() and not scene.enemy_pkmn.is_fainted():
		# U-turn / Volt Switch: switch after attacking
		scene.ui.msg("%s revient !" % player.get_name())
		await scene.get_tree().create_timer(1.0).timeout
		scene._animating = false
		scene._forced_switch = false
		scene.set_state(scene.State.CHOOSE_POKEMON)
		return

	scene.ui.refresh_move_buttons()
	scene._animating = false
	scene.set_state(scene.State.CHECK_END)

# =========================================================================
#  Enemy move
# =========================================================================

func do_enemy_move() -> void:
	if scene._animating: return
	scene._animating = true
	scene._last_attacker = "enemy"
	var player = scene.player_pkmn
	var enemy = scene.enemy_pkmn

	var usable: Array = enemy.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())
	if usable.is_empty():
		await do_struggle(enemy, player)
		scene._animating = false
		scene.set_state(scene.State.CHECK_END)
		return

	var move: MoveInstance
	if _enemy_queued_move != null:
		move = _enemy_queued_move
		_enemy_queued_move = null
		if _enemy_charging_move != null and _enemy_charging_move == move:
			_enemy_charging_move = null
	elif _enemy_charging_move != null:
		move = _enemy_charging_move
		_enemy_charging_move = null
	else:
		move = scene.ai.pick_move(enemy, player, scene.field)

	var pivot := await _execute_attack(enemy, player, move, "enemy")

	if pivot and not enemy.is_fainted() and not player.is_fainted():
		# Enemy U-turn: trainer sends next Pokemon
		if scene._is_trainer_battle:
			_enemy_pivot_switch()

	scene._animating = false
	scene.set_state(scene.State.CHECK_END)

# =========================================================================
#  Check end of turn
# =========================================================================

func check_end() -> void:
	var player = scene.player_pkmn
	var enemy = scene.enemy_pkmn

	if enemy.is_fainted():
		_reset_protect_flags()
		scene.set_state(scene.State.SHOW_XP)
		return
	if player.is_fainted():
		_reset_protect_flags()
		await _handle_player_ko()
		return

	if _turn_phase == 0:
		_turn_phase = 1
		if scene._last_attacker == "player":
			await _apply_eot(enemy)
			if enemy.is_fainted(): _reset_protect_flags(); _turn_phase = 0; scene.set_state(scene.State.SHOW_XP); return
			scene.set_state(scene.State.ENEMY_MOVE)
		else:
			await _apply_eot(player)
			if player.is_fainted(): _reset_protect_flags(); _turn_phase = 0; await _handle_player_ko(); return
			scene.set_state(scene.State.PLAYER_MOVE)
	else:
		_turn_phase = 0
		if scene._last_attacker == "player":
			await _apply_eot(enemy)
			if enemy.is_fainted(): _reset_protect_flags(); scene.set_state(scene.State.SHOW_XP); return
		else:
			await _apply_eot(player)
			if player.is_fainted(): _reset_protect_flags(); await _handle_player_ko(); return
		_enemy_goes_first = false

		# End of full turn: weather, screens, terrain, trick room, tailwind
		var weather_msg = scene.field.tick_weather()
		if weather_msg != "":
			scene.ui.msg(weather_msg)
			await scene.get_tree().create_timer(1.0).timeout

		var screen_msgs = scene.field.tick_screens()
		for sm in screen_msgs:
			scene.ui.msg(sm)
			await scene.get_tree().create_timer(1.0).timeout

		var terrain_msg = scene.field.tick_terrain()
		if terrain_msg != "":
			scene.ui.msg(terrain_msg)
			await scene.get_tree().create_timer(1.0).timeout

		var tr_msg = scene.field.tick_trick_room()
		if tr_msg != "":
			scene.ui.msg(tr_msg)
			await scene.get_tree().create_timer(1.0).timeout

		var tw_msgs = scene.field.tick_tailwind()
		for tm in tw_msgs:
			scene.ui.msg(tm)
			await scene.get_tree().create_timer(1.0).timeout

		_reset_protect_flags()
		scene.ui.refresh()
		scene.set_state(scene.State.PLAYER_CHOOSE)

func _apply_eot(pkmn: PokemonInstance) -> void:
	var msgs := MoveEffects.apply_end_of_turn(pkmn, scene.field)
	for m in msgs:
		scene.ui.msg(m)
		scene.ui.refresh()
		await scene.get_tree().create_timer(1.2).timeout

func _handle_player_ko() -> void:
	var next = GameState.get_first_alive()
	if next:
		scene.ui.msg("%s est K.O. !\nChoisissez un remplacant !" % scene.player_pkmn.get_name())
		await scene.get_tree().create_timer(1.5).timeout
		scene._forced_switch = true
		scene.set_state(scene.State.CHOOSE_POKEMON)
	else:
		scene.ui.msg("Tous vos Pokemon\nsont K.O. !")
		await scene.get_tree().create_timer(2.0).timeout
		scene.set_state(scene.State.BATTLE_OVER)

# =========================================================================
#  Struggle
# =========================================================================

func do_struggle(attacker: PokemonInstance, defender: PokemonInstance) -> void:
	scene.ui.msg("%s n'a plus de PP !\n%s utilise Lutte !" % [attacker.get_name(), attacker.get_name()])
	await scene.get_tree().create_timer(1.5).timeout
	var atk_val: int = attacker.get_effective_stat("atk")
	var def_val: int = defender.get_effective_stat("def")
	var base: int = int(int(int(2.0 * attacker.level / 5.0 + 2.0) * 50 * atk_val / def_val) / 50.0) + 2
	var rng := randf_range(0.85, 1.0)
	var dmg := maxi(1, int(base * rng))
	defender.take_damage(dmg)
	var recoil := maxi(1, int(attacker.max_hp / 4.0))
	attacker.take_damage(recoil)
	scene.ui.refresh()
	scene.ui.msg("%s inflige %d degats !\n%s subit le contrecoup !" % [attacker.get_name(), dmg, attacker.get_name()])
	await scene.get_tree().create_timer(1.8).timeout

# =========================================================================
#  Flee
# =========================================================================

func do_flee() -> void:
	if scene._animating: return
	if scene._is_trainer_battle:
		scene.ui.msg("Impossible de fuir\nun combat de Dresseur !")
		scene._animating = true
		await scene.get_tree().create_timer(1.5).timeout
		scene._animating = false
		scene.set_state(scene.State.PLAYER_CHOOSE)
		return

	if AbilityEffects.prevents_flee(scene.enemy_pkmn):
		scene.ui.msg("%s empeche la fuite !" % scene.enemy_pkmn.get_name())
		scene._animating = true
		await scene.get_tree().create_timer(1.5).timeout
		scene._animating = false
		scene.set_state(scene.State.PLAYER_CHOOSE)
		return

	scene._animating = true
	scene._flee_attempts += 1
	var p_spd := _get_battle_speed(scene.player_pkmn)
	var e_spd := _get_battle_speed(scene.enemy_pkmn)
	var success := false
	if p_spd >= e_spd:
		success = true
	else:
		var chance := mini(255, int(p_spd * 32.0 / maxi(1, e_spd) + 30.0) * scene._flee_attempts)
		success = chance >= 255 or randi() % 256 < chance
	if success:
		scene._fled = true
		scene.ui.msg("Vous prenez la fuite !")
		await scene.get_tree().create_timer(1.5).timeout
		scene._animating = false
		scene.set_state(scene.State.BATTLE_OVER)
	else:
		scene.ui.msg("Impossible de fuir !")
		await scene.get_tree().create_timer(1.5).timeout
		scene._animating = false
		scene._last_attacker = "player"
		_turn_phase = 0
		scene.set_state(scene.State.CHECK_END)

# =========================================================================
#  Helpers
# =========================================================================

func _reset_protect_flags() -> void:
	for pkmn in [scene.player_pkmn, scene.enemy_pkmn]:
		if pkmn.has_bmeta("flinch"): pkmn.remove_bmeta("flinch")
		if pkmn.has_bmeta("protect"):
			pkmn.remove_bmeta("protect")
		else:
			if pkmn.has_bmeta("protect_consecutive"): pkmn.remove_bmeta("protect_consecutive")
		# Clean protect variant flags
		for flag in ["king_shield", "spiky_shield", "baneful_bunker"]:
			if pkmn.has_bmeta(flag): pkmn.remove_bmeta(flag)
		# Reset Destiny Bond
		if pkmn.has_bmeta("destiny_bond"): pkmn.remove_bmeta("destiny_bond")
		# Reset Protean
		if pkmn.has_bmeta("protean_used"): pkmn.remove_bmeta("protean_used")

func _enemy_baton_pass() -> void:
	if not scene._is_trainer_battle: return
	var next_idx := _find_next_alive_trainer_pkmn()
	if next_idx >= 0:
		var old_stages: Dictionary = scene.enemy_pkmn.stat_stages.duplicate()
		scene._trainer_team_idx = next_idx
		scene.enemy_pkmn = scene._trainer_team[next_idx]
		for k in old_stages:
			scene.enemy_pkmn.stat_stages[k] = old_stages[k]
		scene.ui.refresh()
		scene.ui.msg("%s passe le relais a %s !" % [scene._trainer_name, scene.enemy_pkmn.get_name()])

func _enemy_pivot_switch() -> void:
	if not scene._is_trainer_battle: return
	var next_idx := _find_next_alive_trainer_pkmn()
	if next_idx >= 0:
		AbilityEffects.on_switch_out(scene.enemy_pkmn)
		scene._trainer_team_idx = next_idx
		scene.enemy_pkmn = scene._trainer_team[next_idx]
		scene.ui.refresh()
		scene.ui.msg("%s envoie %s !" % [scene._trainer_name, scene.enemy_pkmn.get_name()])

func _find_next_alive_trainer_pkmn() -> int:
	for i in range(scene._trainer_team.size()):
		if i != scene._trainer_team_idx and not scene._trainer_team[i].is_fainted():
			return i
	return -1

func get_charging_move() -> MoveInstance:
	return _charging_move

func clear_charging_move() -> void:
	_charging_move = null
