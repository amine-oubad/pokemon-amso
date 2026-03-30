class_name BattleRewards
extends Node
## Gestion post-combat : XP, level-up, evolution, move learning, fin.
## Enfant de BattleScene.

var scene  # Reference to BattleScene

var _pending_moves: Array = []
var _pending_evolution: String = ""

# =========================================================================
#  XP et level-up
# =========================================================================

func award_xp() -> void:
	var player = scene.player_pkmn
	var enemy = scene.enemy_pkmn

	var xp := BattleCalc.calculate_exp_gain(enemy, player.level)
	scene.ui.msg("%s est K.O. !\n%s gagne %d EXP !" % [enemy.get_name(), player.get_name(), xp])
	await scene.get_tree().create_timer(2.0).timeout

	# EV gain
	player.gain_evs_from(enemy)

	# Apply XP
	var result := player.gain_exp(xp)
	if result.levels_gained > 0:
		scene.ui.refresh()
		scene.ui.msg("%s monte au Lv.%d !" % [player.get_name(), player.level])
		await scene.get_tree().create_timer(2.0).timeout

	_pending_moves = result.new_moves
	_pending_evolution = result.evolution
	advance_post_xp()

func advance_post_xp() -> void:
	if _pending_moves.size() > 0:
		scene.set_state(scene.State.LEARN_MOVE)
		return
	if _pending_evolution != "":
		scene.set_state(scene.State.EVOLVE)
		return
	go_to_next_or_end()

func go_to_next_or_end() -> void:
	if scene._is_trainer_battle and scene._trainer_team_idx + 1 < scene._trainer_team.size():
		scene.set_state(scene.State.TRAINER_NEXT)
	else:
		scene.set_state(scene.State.BATTLE_OVER)

# =========================================================================
#  Move learning
# =========================================================================

func show_learn_move() -> void:
	var move_id: String = _pending_moves[0]
	_pending_moves.remove_at(0)
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var move_name: String = mdata.get("name", move_id)

	if scene.player_pkmn.moves.size() < 4:
		scene.player_pkmn.learn_move(move_id)
		scene.ui.msg("%s apprend %s !" % [scene.player_pkmn.get_name(), move_name])
		await scene.get_tree().create_timer(2.0).timeout
		advance_post_xp()
	else:
		scene.ui.msg("%s veut apprendre %s...\nMais il connait deja 4 capacites !" % [
			scene.player_pkmn.get_name(), move_name])
		await scene.get_tree().create_timer(2.5).timeout
		scene.ui.show_move_replace_menu(move_id)

func on_skip_learn(new_move_id: String) -> void:
	scene.ui.move_menu.visible = false
	scene.ui.hide_cancel_learn_btn()
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)
	scene.ui.msg("%s n'apprend pas %s." % [scene.player_pkmn.get_name(), new_name])
	scene.ui.reconnect_move_buttons()
	scene._animating = true
	await scene.get_tree().create_timer(1.5).timeout
	scene._animating = false
	advance_post_xp()

func on_replace_move(idx: int, new_move_id: String) -> void:
	scene.ui.hide_cancel_learn_btn()
	scene.ui.move_menu.visible = false
	var old_name: String = scene.player_pkmn.moves[idx].get_name()
	var mdata: Dictionary = GameData.moves_data.get(new_move_id, {})
	var new_name: String = mdata.get("name", new_move_id)
	scene.player_pkmn.learn_move(new_move_id, idx)
	scene.ui.msg("1, 2, 3... %s oublie %s\net apprend %s !" % [
		scene.player_pkmn.get_name(), old_name, new_name])
	scene.ui.reconnect_move_buttons()
	scene._animating = true
	await scene.get_tree().create_timer(2.5).timeout
	scene._animating = false
	advance_post_xp()

# =========================================================================
#  Evolution
# =========================================================================

func show_evolution() -> void:
	var target_id := _pending_evolution
	_pending_evolution = ""
	var old_name: String = scene.player_pkmn.get_name()
	var target_data: Dictionary = GameData.pokemon_data.get(target_id, {})
	var new_name: String = target_data.get("name", target_id)

	scene.ui.msg("Hein !? %s evolue !\n(X pour annuler)" % old_name)

	var cancelled := false
	var timer := 0.0
	while timer < 3.0:
		await scene.get_tree().process_frame
		timer += scene.get_process_delta_time()
		if Input.is_action_just_pressed("ui_cancel"):
			cancelled = true
			break

	if cancelled:
		scene.ui.msg("%s n'evolue pas !" % old_name)
		await scene.get_tree().create_timer(1.5).timeout
		go_to_next_or_end()
		return

	scene.player_pkmn.evolve(target_id)
	scene.ui.refresh()
	scene.ui.msg("Felicitations !\n%s a evolue en %s !" % [old_name, new_name])
	GameState.register_seen(target_id)
	await scene.get_tree().create_timer(3.0).timeout
	go_to_next_or_end()

# =========================================================================
#  Trainer next / Battle finish
# =========================================================================

func trainer_send_next() -> void:
	scene._trainer_team_idx += 1
	scene.enemy_pkmn = scene._trainer_team[scene._trainer_team_idx]
	GameState.register_seen(scene.enemy_pkmn.pokemon_id)
	scene.ui.refresh()
	scene.ui.msg("%s envoie %s !" % [scene._trainer_name, scene.enemy_pkmn.get_name()])

	# Apply entry hazards to new enemy
	var hazard_msgs := scene.field.apply_entry_hazards("enemy", scene.enemy_pkmn)
	scene._animating = true
	await scene.get_tree().create_timer(2.0).timeout

	for hm in hazard_msgs:
		scene.ui.msg(hm)
		scene.ui.refresh()
		await scene.get_tree().create_timer(1.2).timeout

	# Switch-in ability
	var ab_msgs := AbilityEffects.on_switch_in(scene.enemy_pkmn, scene.player_pkmn, scene.field)
	for am in ab_msgs:
		scene.ui.msg(am)
		scene.ui.refresh()
		await scene.get_tree().create_timer(1.2).timeout

	scene._animating = false
	scene.set_state(scene.State.PLAYER_CHOOSE)

func finish() -> void:
	var result := "flee" if scene._fled else ("win" if not scene.player_pkmn.is_fainted() else "lose")
	scene.player_pkmn.reset_stat_stages()
	scene.player_pkmn.clear_battle_meta()
	for pkmn in GameState.team:
		pkmn.clear_battle_meta()
		# Natural Cure on switch out
		AbilityEffects.on_switch_out(pkmn)

	# Defeat
	if result == "lose":
		GameOverScreen.show_game_over()
		return

	# Trainer rewards
	if scene._is_trainer_battle and result == "win":
		GameState.mark_trainer_defeated(scene._trainer_id)
		scene.ui.msg("Vous avez battu %s !" % scene._trainer_name)
		await scene.get_tree().create_timer(2.0).timeout

		if scene._reward_money > 0:
			GameState.money += scene._reward_money
			scene.ui.msg("Vous remportez %d P$ !" % scene._reward_money)
			await scene.get_tree().create_timer(1.5).timeout

		if scene._badge_id != "":
			GameState.add_badge(scene._badge_id)
			var badge_name := scene._badge_id
			for gym_id in GameData.gyms_data:
				var g: Dictionary = GameData.gyms_data[gym_id]
				if g.get("badge_id", "") == scene._badge_id:
					badge_name = g.get("badge_name", scene._badge_id)
					break
			scene.ui.msg("Vous obtenez le %s !" % badge_name)
			await scene.get_tree().create_timer(2.5).timeout

		var after_key: String = GameState.pending_battle.get("dialogue_after", "")
		if after_key != "":
			var after_lines: Array = GameData.dialogues_data.get(after_key, [])
			if not after_lines.is_empty():
				DialogueManager.start_dialogue(after_lines)
				await DialogueManager.dialogue_finished

	GameState.pending_battle = {}
	EventBus.battle_ended.emit(result)
	scene.get_tree().change_scene_to_file(GameState.return_to_scene)
