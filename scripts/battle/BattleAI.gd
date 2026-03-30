class_name BattleAI
extends Node
## IA ennemie avec niveaux de difficulte.
## Enfant de BattleScene, accede au contexte via scene.

const HeldItemEffects = preload("res://scripts/battle/HeldItemEffects.gd")
const BattleField = preload("res://scripts/battle/BattleField.gd")
const MoveInstance = preload("res://scripts/data/MoveInstance.gd")
const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
enum Difficulty { EASY, NORMAL, HARD, ELITE }

var scene  # Reference to BattleScene (set externally)
var difficulty: Difficulty = Difficulty.NORMAL

# =========================================================================
#  Choix du move
# =========================================================================

func pick_move(enemy: PokemonInstance, player: PokemonInstance, field: BattleField) -> MoveInstance:
	var usable: Array = _get_usable_moves(enemy)
	if usable.is_empty():
		return null  # Struggle

	match difficulty:
		Difficulty.EASY:
			return _pick_random(usable)
		Difficulty.NORMAL:
			return _pick_scored(enemy, player, usable, field, 0.20)
		Difficulty.HARD:
			return _pick_scored(enemy, player, usable, field, 0.05)
		Difficulty.ELITE:
			return _pick_elite(enemy, player, usable, field)

	return _pick_scored(enemy, player, usable, field, 0.20)

# =========================================================================
#  Difficulte : EASY — choix aleatoire
# =========================================================================

func _pick_random(usable: Array) -> MoveInstance:
	return usable[randi() % usable.size()]

# =========================================================================
#  Difficulte : NORMAL/HARD — score avec % random
# =========================================================================

func _pick_scored(
	enemy: PokemonInstance, player: PokemonInstance,
	usable: Array, field: BattleField, random_chance: float
) -> MoveInstance:
	# Random chance to just pick random
	if randf() < random_chance:
		return _pick_random(usable)

	var best_move: MoveInstance = usable[0]
	var best_score: float = -1.0

	for mv: MoveInstance in usable:
		var score := _score_move(mv, enemy, player, field)
		if score > best_score:
			best_score = score
			best_move = mv

	return best_move

# =========================================================================
#  Difficulte : ELITE — scoring avance + predictions
# =========================================================================

func _pick_elite(
	enemy: PokemonInstance, player: PokemonInstance,
	usable: Array, field: BattleField
) -> MoveInstance:
	var best_move: MoveInstance = usable[0]
	var best_score: float = -999.0

	for mv: MoveInstance in usable:
		var score := _score_move_elite(mv, enemy, player, field)
		if score > best_score:
			best_score = score
			best_move = mv

	return best_move

# =========================================================================
#  Scoring functions
# =========================================================================

func _score_move(
	mv: MoveInstance, enemy: PokemonInstance,
	player: PokemonInstance, field: BattleField
) -> float:
	var power: int = mv.get_power()
	var move_type: String = mv.get_type()

	# Status moves
	if power == 0:
		return _score_status_move(mv, enemy, player, field)

	# Damage moves: power * effectiveness * STAB
	var eff: float = GameData.get_total_effectiveness(move_type, player.get_types())
	var stab: float = 1.5 if move_type in enemy.get_types() else 1.0
	var score: float = power * eff * stab

	# Bonus for likely KO
	var estimated_dmg := score * 0.5  # Rough estimate
	if estimated_dmg >= player.current_hp:
		score *= 1.5  # Prefer finishing moves

	# Weather bonus
	if field != null:
		score *= field.get_weather_multiplier(move_type)

	# Priority bonus when player is low HP
	if mv.get_priority() > 0 and player.current_hp < player.max_hp * 0.3:
		score *= 1.3

	return score

func _score_status_move(
	mv: MoveInstance, enemy: PokemonInstance,
	player: PokemonInstance, field: BattleField
) -> float:
	var effect: String = mv.get_effect()
	var score := 15.0  # Base status move score

	match effect:
		# Setup moves are valuable early
		"raise_self_atk", "raise_self_atk_2", "raise_self_speed_2":
			if enemy.stat_stages.get("atk", 0) < 4:
				score = 35.0
			else:
				score = 2.0  # Already boosted enough
		"dragon_dance", "bulk_up", "calm_mind":
			var avg_stage: float = (enemy.stat_stages.get("atk", 0) + enemy.stat_stages.get("speed", 0)) / 2.0
			if avg_stage < 2:
				score = 40.0  # Very valuable early
			else:
				score = 5.0

		# Status moves depend on opponent having no status
		"burn", "paralyze", "poison", "bad_poison", "sleep", "freeze":
			if player.status == "":
				score = 25.0
				# Sleep and paralyze are more valuable
				if effect == "sleep": score = 30.0
				if effect == "paralyze" and player.get_effective_stat("speed") > enemy.get_effective_stat("speed"):
					score = 35.0  # Slow down faster opponent
			else:
				score = 0.0  # Already has status

		# Screens are valuable
		"reflect", "light_screen":
			if field != null:
				var side := "enemy"
				if field.screens[side].get(effect, 0) > 0:
					score = 0.0  # Already up
				else:
					score = 30.0

		# Hazards
		"stealth_rock", "spikes", "toxic_spikes":
			score = 20.0
			if field != null:
				if effect == "stealth_rock" and field.hazards["player"]["stealth_rock"]:
					score = 0.0
				elif effect == "spikes" and field.hazards["player"]["spikes"] >= 3:
					score = 0.0
				elif effect == "toxic_spikes" and field.hazards["player"]["toxic_spikes"] >= 2:
					score = 0.0

		# Recovery
		"heal_half", "rest":
			var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
			if hp_ratio < 0.5:
				score = 30.0
			elif hp_ratio < 0.75:
				score = 15.0
			else:
				score = 2.0  # Don't heal when healthy

		# Protect
		"protect":
			score = 10.0  # Situational

		_:
			score = 15.0

	return score

func _score_move_elite(
	mv: MoveInstance, enemy: PokemonInstance,
	player: PokemonInstance, field: BattleField
) -> float:
	var base_score := _score_move(mv, enemy, player, field)

	# Elite AI considers survival
	var effect: String = mv.get_effect()

	# Prefer priority moves when both are low HP
	if mv.get_priority() > 0:
		if enemy.current_hp < enemy.max_hp * 0.3 and player.current_hp < player.max_hp * 0.3:
			base_score *= 1.5

	# Avoid recoil moves when low HP
	if effect in ["recoil_quarter", "recoil_third", "recoil_half"]:
		if enemy.current_hp < enemy.max_hp * 0.25:
			base_score *= 0.3

	# Prefer setup when at high HP
	if effect in ["dragon_dance", "bulk_up", "calm_mind", "raise_self_atk_2", "raise_self_speed_2"]:
		var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
		if hp_ratio > 0.8:
			base_score *= 1.4
		elif hp_ratio < 0.4:
			base_score *= 0.3  # Don't setup when low

	# Prefer healing when mid-HP
	if effect in ["heal_half", "rest"]:
		var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
		if hp_ratio < 0.4:
			base_score *= 1.5

	return base_score

# =========================================================================
#  Helpers
# =========================================================================

func _get_usable_moves(pkmn: PokemonInstance) -> Array:
	var usable: Array = pkmn.moves.filter(func(m: MoveInstance) -> bool: return m.is_usable())

	# Filter out taunted status moves
	if pkmn.has_bmeta("taunted"):
		usable = usable.filter(func(m: MoveInstance) -> bool: return m.get_category() != "status")

	# Filter out disabled moves
	if pkmn.has_bmeta("disabled_move"):
		var disabled_id: String = pkmn.get_bmeta("disabled_move", "")
		if disabled_id != "":
			usable = usable.filter(func(m: MoveInstance) -> bool: return m.move_id != disabled_id)

	# Choice lock — if a move has been chosen, only allow that move
	if HeldItemEffects.is_choice_locked(pkmn) and pkmn.has_bmeta("choice_locked_move"):
		var locked_id: String = pkmn.get_bmeta("choice_locked_move", "")
		var locked := usable.filter(func(m: MoveInstance) -> bool: return m.move_id == locked_id)
		if not locked.is_empty():
			return locked

	return usable

## Decide si le dresseur IA devrait switch.
func should_switch(enemy: PokemonInstance, player: PokemonInstance, team: Array) -> int:
	if difficulty < Difficulty.HARD:
		return -1  # Easy/Normal never switch

	# Check if current matchup is very bad
	var dominated := true
	for mv in enemy.moves:
		if mv.get_power() > 0:
			var eff := GameData.get_total_effectiveness(mv.get_type(), player.get_types())
			if eff >= 1.0:
				dominated = false
				break

	if not dominated:
		return -1  # Not dominated, stay

	# Look for a better matchup in team
	for i in range(team.size()):
		var candidate: PokemonInstance = team[i]
		if candidate == enemy or candidate.is_fainted():
			continue
		# Check if candidate has super-effective moves
		for mv in candidate.moves:
			if mv.get_power() > 0:
				var eff := GameData.get_total_effectiveness(mv.get_type(), player.get_types())
				if eff > 1.0:
					return i
	return -1
