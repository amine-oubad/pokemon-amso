extends Node2D
## Scene de combat — coordinateur principal.
## Delegue aux composants : BattleUI, BattleTurnManager, BattleAI, BattleRewards.

# -- State machine --------------------------------------------------------
enum State {
	INTRO,
	PLAYER_CHOOSE, CHOOSE_MOVE, CHOOSE_ITEM, CHOOSE_POKEMON,
	PLAYER_MOVE, FLEE_ATTEMPT,
	ENEMY_MOVE,
	CHECK_END, CAPTURE_ANIM, SHOW_XP, LEARN_MOVE, EVOLVE, TRAINER_NEXT, BATTLE_OVER
}

# -- Composants -----------------------------------------------------------
var ui: BattleUI
var turns: BattleTurnManager
var ai: BattleAI
var rewards: BattleRewards
var field: BattleField

# -- Etat partage ---------------------------------------------------------
var player_pkmn: PokemonInstance
var enemy_pkmn:  PokemonInstance
var _active_idx: int = 0
var _selected_move: MoveInstance
var _state: State = State.INTRO
var _last_attacker: String = ""
var _animating: bool       = false
var _forced_switch: bool   = false
var _fled: bool            = false
var _flee_attempts: int    = 0
var _baton_pass_stages: Dictionary = {}

# -- Trainer battle data --------------------------------------------------
var _is_trainer_battle: bool = false
var _trainer_id: String      = ""
var _trainer_name: String    = ""
var _trainer_team: Array     = []
var _trainer_team_idx: int   = 0
var _reward_money: int       = 0
var _badge_id: String        = ""
var _is_gym_leader: bool     = false

# =========================================================================
#  Initialisation
# =========================================================================

func _ready() -> void:
	# Hide overworld autoload UIs during battle (save their state)
	_hidden_autoloads = []
	for autoload_name in ["OverworldHUD", "PauseMenu", "PCBoxScreen", "PokemonSummary",
			"ShopMenu", "StarterSelect", "TitleScreen", "GameOverScreen", "DialogueManager"]:
		var node = get_tree().root.get_node_or_null(autoload_name)
		if node and node is CanvasLayer and node.visible:
			_hidden_autoloads.append(autoload_name)
			node.visible = false

	# Create field state
	field = BattleField.new()

	# Create AI
	ai = BattleAI.new()
	ai.scene = self
	add_child(ai)

	# Create UI
	ui = BattleUI.new()
	ui.scene = self
	add_child(ui)

	# Create turn manager
	turns = BattleTurnManager.new()
	turns.scene = self
	add_child(turns)

	# Create rewards manager
	rewards = BattleRewards.new()
	rewards.scene = self
	add_child(rewards)

	# Load battle data
	_load_battle()

	# Build UI and refresh
	ui.build_ui()
	ui.refresh()

	# Set AI difficulty based on trainer type
	_configure_ai_difficulty()

	# Start
	set_state(State.INTRO)

func _load_battle() -> void:
	var bd := GameState.pending_battle
	_is_trainer_battle = bd.get("is_trainer", false)
	_trainer_id    = bd.get("trainer_id", "")
	_trainer_name  = bd.get("trainer_name", "Dresseur")
	_reward_money  = bd.get("reward_money", 0)
	_badge_id      = bd.get("badge_id", "")
	_is_gym_leader = bd.get("is_gym_leader", false)

	if _is_trainer_battle:
		var team_data: Array = bd.get("trainer_team", [])
		_trainer_team.clear()
		for td in team_data:
			var pkmn: PokemonInstance
			# Support enriched trainer format
			if td.has("nature") or td.has("held_item") or td.has("evs"):
				pkmn = PokemonInstance.create_with_details(
					td.get("id", "025"), td.get("level", 5),
					td.get("nature", ""), td.get("ability", ""),
					td.get("held_item", ""), td.get("evs", {}),
					td.get("moves", [])
				)
			else:
				pkmn = PokemonInstance.create(td.get("id", "025"), td.get("level", 5))
			_trainer_team.append(pkmn)
		_trainer_team_idx = 0
		if _trainer_team.size() > 0:
			enemy_pkmn = _trainer_team[0]
		else:
			enemy_pkmn = PokemonInstance.from_encounter(bd.get("enemy_data", {}))
	else:
		enemy_pkmn = PokemonInstance.from_encounter(bd.get("enemy_data", {}))

	GameState.register_seen(enemy_pkmn.pokemon_id)

	var leader = GameState.get_first_alive()
	if leader:
		player_pkmn = leader
		_active_idx = GameState.team.find(leader)
	else:
		player_pkmn = PokemonInstance.create("025", 5)
		GameState.team.append(player_pkmn)
		_active_idx = 0

var _hidden_autoloads: Array = []

func _restore_overworld_ui() -> void:
	for autoload_name in _hidden_autoloads:
		var node = get_tree().root.get_node_or_null(autoload_name)
		if node and node is CanvasLayer:
			node.visible = true
	_hidden_autoloads.clear()

func _configure_ai_difficulty() -> void:
	if _is_gym_leader:
		ai.difficulty = BattleAI.Difficulty.HARD
	elif _is_trainer_battle:
		ai.difficulty = BattleAI.Difficulty.NORMAL
	else:
		ai.difficulty = BattleAI.Difficulty.EASY

	# Elite 4 and Champion
	if _trainer_id.find("elite4") >= 0 or _trainer_id.find("champion") >= 0:
		ai.difficulty = BattleAI.Difficulty.ELITE

# =========================================================================
#  State machine
# =========================================================================

func set_state(s: State) -> void:
	_state = s
	ui.hide_all_menus()

	match _state:
		State.INTRO:
			if _is_trainer_battle:
				ui.msg("%s veut se battre !\n%s envoie %s !" % [_trainer_name, _trainer_name, enemy_pkmn.get_name()])
			else:
				ui.msg("Un %s sauvage apparait !" % enemy_pkmn.get_name())
			# Switch-in abilities at battle start
			_handle_initial_switch_in()

		State.PLAYER_CHOOSE:
			# Two-turn : force attack
			var charging := turns.get_charging_move()
			if charging != null:
				_selected_move = charging
				turns.clear_charging_move()
				set_state(State.PLAYER_MOVE)
				return
			# Struggle check
			var has_usable := false
			for mv in player_pkmn.moves:
				if mv.is_usable():
					has_usable = true; break
			if not has_usable:
				_animating = true
				await turns.do_struggle(player_pkmn, enemy_pkmn)
				_animating = false
				_last_attacker = "player"
				set_state(State.CHECK_END)
				return
			ui.msg("Que va faire %s ?" % player_pkmn.get_name())
			ui.action_menu.visible = true

		State.CHOOSE_MOVE:
			ui.refresh_move_buttons()
			ui.move_menu.visible = true

		State.CHOOSE_ITEM:
			ui.populate_item_menu()
			ui.item_menu.visible = true

		State.CHOOSE_POKEMON:
			ui.populate_pkmn_menu()
			ui.pkmn_menu.visible = true

		State.PLAYER_MOVE:   turns.do_player_move()
		State.FLEE_ATTEMPT:  turns.do_flee()
		State.ENEMY_MOVE:    turns.do_enemy_move()
		State.CHECK_END:     turns.check_end()
		State.CAPTURE_ANIM:  pass
		State.SHOW_XP:       rewards.award_xp()
		State.LEARN_MOVE:    rewards.show_learn_move()
		State.EVOLVE:        rewards.show_evolution()
		State.TRAINER_NEXT:  rewards.trainer_send_next()
		State.BATTLE_OVER:   rewards.finish()

func _handle_initial_switch_in() -> void:
	# Called after INTRO state, when player presses accept
	# Abilities like Intimidate, Drizzle, etc. trigger here
	pass  # Will be called from _input when transitioning from INTRO

var _action_cursor: int = 0
var _move_cursor: int = 0

func _input(event: InputEvent) -> void:
	if _animating:
		return

	match _state:
		State.INTRO:
			if event.is_action_pressed("ui_accept"):
				_trigger_switch_in_abilities()

		State.PLAYER_CHOOSE:
			if event.is_action_pressed("move_up"):
				_action_cursor = max(0, _action_cursor - 1)
				_highlight_action()
			elif event.is_action_pressed("move_down"):
				_action_cursor = min(3, _action_cursor + 1)
				_highlight_action()
			elif event.is_action_pressed("ui_accept"):
				match _action_cursor:
					0: _on_attack()
					1: _on_bag()
					2: _on_switch_btn()
					3: _on_flee()

		State.CHOOSE_MOVE:
			if event.is_action_pressed("move_left"):
				_move_cursor = max(0, _move_cursor - 1)
				_highlight_move()
			elif event.is_action_pressed("move_right"):
				_move_cursor = min(player_pkmn.moves.size() - 1, _move_cursor + 1)
				_highlight_move()
			elif event.is_action_pressed("move_up"):
				_move_cursor = max(0, _move_cursor - 2)
				_highlight_move()
			elif event.is_action_pressed("move_down"):
				_move_cursor = min(player_pkmn.moves.size() - 1, _move_cursor + 2)
				_highlight_move()
			elif event.is_action_pressed("ui_accept"):
				_on_move(_move_cursor)
			elif event.is_action_pressed("ui_cancel"):
				set_state(State.PLAYER_CHOOSE)

		State.CHOOSE_ITEM:
			if event.is_action_pressed("ui_cancel"):
				set_state(State.PLAYER_CHOOSE)

		State.CHOOSE_POKEMON:
			if event.is_action_pressed("ui_cancel"):
				if not _forced_switch:
					_baton_pass_stages = {}
					set_state(State.PLAYER_CHOOSE)

func _highlight_action() -> void:
	var labels := ["ATTAQUER", "SAC", "SWITCH", "FUIR"]
	for i in range(ui.action_menu.get_child_count()):
		var btn = ui.action_menu.get_child(i)
		if btn is Button:
			if i == _action_cursor:
				btn.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
			else:
				btn.remove_theme_color_override("font_color")

func _highlight_move() -> void:
	for i in range(ui._move_buttons.size()):
		var btn: Button = ui._move_buttons[i]
		if i == _move_cursor:
			btn.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
		else:
			btn.remove_theme_color_override("font_color")

func _trigger_switch_in_abilities() -> void:
	_animating = true
	# Player switch-in
	var p_msgs := AbilityEffects.on_switch_in(player_pkmn, enemy_pkmn, field)
	for m in p_msgs:
		ui.msg(m)
		ui.refresh()
		await get_tree().create_timer(1.2).timeout
	# Enemy switch-in
	var e_msgs := AbilityEffects.on_switch_in(enemy_pkmn, player_pkmn, field)
	for m in e_msgs:
		ui.msg(m)
		ui.refresh()
		await get_tree().create_timer(1.2).timeout
	_animating = false
	set_state(State.PLAYER_CHOOSE)

# =========================================================================
#  Action handlers (called by UI buttons)
# =========================================================================

func _on_attack() -> void:
	if _state == State.PLAYER_CHOOSE: set_state(State.CHOOSE_MOVE)

func _on_bag() -> void:
	if _state == State.PLAYER_CHOOSE: set_state(State.CHOOSE_ITEM)

func _on_switch_btn() -> void:
	if _state == State.PLAYER_CHOOSE: set_state(State.CHOOSE_POKEMON)

func _on_flee() -> void:
	if _state == State.PLAYER_CHOOSE: set_state(State.FLEE_ATTEMPT)

func _on_move(idx: int) -> void:
	if _state != State.CHOOSE_MOVE or _animating: return
	if idx >= player_pkmn.moves.size(): return
	_selected_move = player_pkmn.moves[idx]
	ui.move_menu.visible = false
	turns.resolve_turn_order(_selected_move)

func _on_item_used(item_id: String) -> void:
	if _animating: return
	ui.item_menu.visible = false
	var idata: Dictionary = GameData.items_data.get(item_id, {})
	GameState.remove_item(item_id)
	_last_attacker = "player"
	_animating = true

	match idata.get("category", ""):
		"heal":
			var healed := player_pkmn.heal(idata.get("heal_amount", 20))
			var cures: Array = idata.get("cures", [])
			if not cures.is_empty() and player_pkmn.status in cures:
				player_pkmn.status = ""
				player_pkmn.status_turns = 0
			ui.refresh()
			ui.msg("%s utilise %s !\n%s recupere %d PV !" % [
				GameState.player_name, idata.get("name", item_id),
				player_pkmn.get_name(), healed
			])
			await get_tree().create_timer(1.8).timeout
			_animating = false
			set_state(State.CHECK_END)

		"revive":
			GameState.add_item(item_id)
			ui.msg("Cet objet ne peut etre\nutilise qu'hors combat !")
			await get_tree().create_timer(1.8).timeout
			_animating = false
			set_state(State.PLAYER_CHOOSE)

		"status_cure":
			var cures: Array = idata.get("cures", [])
			if player_pkmn.status in cures:
				player_pkmn.status = ""
				player_pkmn.status_turns = 0
				ui.refresh()
				ui.msg("%s utilise %s !\nLe statut de %s est gueri !" % [
					GameState.player_name, idata.get("name", item_id), player_pkmn.get_name()
				])
			else:
				GameState.add_item(item_id)
				ui.msg("Cet objet n'a aucun effet ici !")
			await get_tree().create_timer(1.8).timeout
			_animating = false
			set_state(State.CHECK_END)

		"ball":
			if _is_trainer_battle:
				GameState.add_item(item_id)
				ui.msg("Voler les Pokemon\nd'un Dresseur ? Impossible !")
				await get_tree().create_timer(1.8).timeout
				_animating = false
				set_state(State.PLAYER_CHOOSE)
				return
			var bonus: float = idata.get("ball_bonus", 1.0)
			ui.msg("%s lance une %s !" % [GameState.player_name, idata.get("name", item_id)])
			await get_tree().create_timer(0.8).timeout
			for i in range(3):
				ui.msg("La Ball tremble" + ".".repeat(i + 1))
				await get_tree().create_timer(0.5).timeout
			var caught := BattleCalc.try_catch(enemy_pkmn, bonus)
			if caught:
				GameState.register_caught(enemy_pkmn.pokemon_id)
				if GameState.team.size() < 6:
					GameState.team.append(enemy_pkmn)
					ui.msg("%s est capture !\n%s rejoint votre equipe !" % [enemy_pkmn.get_name(), enemy_pkmn.get_name()])
				else:
					GameState.pc_boxes.append(enemy_pkmn)
					ui.msg("%s est capture !\nEnvoye au PC." % enemy_pkmn.get_name())
				await get_tree().create_timer(2.0).timeout
				_animating = false
				GameState.pending_battle = {}
				EventBus.battle_ended.emit("caught")
				get_tree().change_scene_to_file(GameState.return_to_scene)
			else:
				ui.msg("%s s'echappe de la Ball !" % enemy_pkmn.get_name())
				await get_tree().create_timer(1.5).timeout
				_animating = false
				set_state(State.ENEMY_MOVE)

func _on_switch_pkmn(idx: int) -> void:
	if _animating: return
	if idx == _active_idx: return
	if GameState.team[idx].is_fainted(): return
	var old_name := player_pkmn.get_name()

	# Switch-out effects
	AbilityEffects.on_switch_out(player_pkmn)

	if _baton_pass_stages.is_empty():
		player_pkmn.reset_stat_stages()
	player_pkmn.clear_battle_meta()
	_active_idx  = idx
	player_pkmn  = GameState.team[idx]

	# Baton Pass transfer
	if not _baton_pass_stages.is_empty():
		for k in _baton_pass_stages:
			player_pkmn.stat_stages[k] = _baton_pass_stages[k]
		_baton_pass_stages = {}

	ui.pkmn_menu.visible = false
	_animating = true
	ui.msg("Reviens, %s !\nAllez, %s !" % [old_name, player_pkmn.get_name()])
	ui.refresh()
	await get_tree().create_timer(1.5).timeout

	# Entry hazards on player side
	var hazard_msgs := field.apply_entry_hazards("player", player_pkmn)
	for hm in hazard_msgs:
		ui.msg(hm)
		ui.refresh()
		await get_tree().create_timer(1.2).timeout

	# Switch-in ability
	var ab_msgs := AbilityEffects.on_switch_in(player_pkmn, enemy_pkmn, field)
	for am in ab_msgs:
		ui.msg(am)
		ui.refresh()
		await get_tree().create_timer(1.2).timeout

	_animating = false
	if _forced_switch:
		_forced_switch = false
		set_state(State.PLAYER_CHOOSE)
	else:
		_last_attacker = "player"
		set_state(State.CHECK_END)

func _on_replace_move(idx: int, new_move_id: String) -> void:
	rewards.on_replace_move(idx, new_move_id)

func _on_skip_learn(new_move_id: String) -> void:
	rewards.on_skip_learn(new_move_id)
