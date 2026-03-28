class_name BattleCalc
## Calculs purs du système de combat Gen 3.
## Toutes les fonctions sont statiques — pas besoin d'instancier.

# ── Dégâts ────────────────────────────────────────────────────────────────────

## Calcule les dégâts d'un move.
## Retourne un dict : { damage, critical, effectiveness, stab }
static func calculate_damage(
	attacker: PokemonInstance,
	defender: PokemonInstance,
	move: MoveInstance
) -> Dictionary:

	var result := { "damage": 0, "critical": false, "effectiveness": 1.0, "stab": false }

	var power: int = move.get_power()
	if power == 0:
		return result  # Move de statut — pas de dégâts directs

	# Sélection des stats selon la catégorie (physical / special)
	var atk_val: int
	var def_val: int
	if move.get_category() == "physical":
		atk_val = attacker.get_effective_stat("atk")
		def_val = defender.get_effective_stat("def")
	else:
		atk_val = attacker.get_effective_stat("sp_atk")
		def_val = defender.get_effective_stat("sp_def")

	# Formule Gen 3 :
	# damage = floor(floor(floor(2*level/5 + 2) * power * atk / def) / 50) + 2
	var base: int = int(int(int(2.0 * attacker.level / 5.0 + 2.0) * power * atk_val / def_val) / 50.0) + 2

	# Coup critique — taux de base 6.25%, high_crit moves → 25%
	var crit_rate := 0.25 if move.get_effect() == "high_crit" else 0.0625
	var is_crit := randf() < crit_rate
	if is_crit:
		base = int(base * 1.5)
		result.critical = true

	# STAB (Same Type Attack Bonus) — ×1.5 si le type du move = un type du Pokémon
	var move_type: String = move.get_type()
	var has_stab := move_type in attacker.get_types()
	var stab_mult := 1.5 if has_stab else 1.0
	result.stab = has_stab

	# Efficacité de type (×0, ×0.5, ×1, ×2, ×4...)
	var type_eff: float = GameData.get_total_effectiveness(move_type, defender.get_types())
	result.effectiveness = type_eff

	# Facteur aléatoire : 85 %–100 % (comme Gen 3)
	var rng := randf_range(0.85, 1.0)

	# Calcul final
	var final_dmg := int(base * stab_mult * type_eff * rng)
	result.damage = max(1 if type_eff > 0.0 else 0, final_dmg)

	return result

# ── XP ────────────────────────────────────────────────────────────────────────

## XP gagnée quand un Pokémon ennemi est K.O.
## Formule simplifiée (pas de commerce, pas de bonus Exp.Share).
static func calculate_exp_gain(fainted: PokemonInstance, _winner_level: int) -> int:
	var base_exp: int = fainted.get_base_exp_yield()
	# Formule Gen 5+ : floor(base_exp * level / 7)
	var gained := int(base_exp * fainted.level / 7.0)
	return max(1, gained)

# ── Capture ───────────────────────────────────────────────────────────────────

## Retourne true si le Pokémon est capturé (formule Gen 3 simplifiée).
## ball_bonus : Poké Ball = 1, Super Ball = 1.5, Hyper Ball = 2
static func try_catch(target: PokemonInstance, ball_bonus: float = 1.0) -> bool:
	var catch_rate: int = target.get_catch_rate()
	var hp_ratio: float = float(target.current_hp) / float(target.max_hp)

	# Valeur a = (3 * max_hp - 2 * current_hp) * catch_rate * ball_bonus / (3 * max_hp)
	var a: float = (3.0 * target.max_hp - 2.0 * target.current_hp) * catch_rate * ball_bonus / (3.0 * target.max_hp)
	a = clampf(a, 0.0, 255.0)

	# Statut bonus (brûlé/paralysé/empoisonné = ×1.5 ; endormi/gelé = ×2)
	var status_mult := 1.0
	if target.status in ["sleep", "freeze"]:
		status_mult = 2.0
	elif target.status in ["burn", "paralyze", "poison", "bad_poison"]:
		status_mult = 1.5
	a = minf(a * status_mult, 255.0)

	# Probabilité de capture : (a / 255)^(1/4)  — 4 secousses
	var p: float = pow(a / 255.0, 0.25)
	return randf() < p

# ── Précision ─────────────────────────────────────────────────────────────────

## Retourne true si le move touche sa cible.
static func accuracy_check(
	move: MoveInstance,
	attacker: PokemonInstance,
	defender: PokemonInstance
) -> bool:
	var acc: int = move.get_accuracy()
	if acc == 0:
		return true  # Move qui ne peut pas rater (ex: Jackpot)

	var acc_stage: int  = attacker.stat_stages.get("accuracy", 0)
	var eva_stage: int  = defender.stat_stages.get("evasion", 0)
	var net_stage: int  = clampi(acc_stage - eva_stage, -6, 6)

	var mult := 1.0
	if net_stage > 0:
		mult = (3.0 + net_stage) / 3.0
	elif net_stage < 0:
		mult = 3.0 / (3.0 - net_stage)

	return randf() * 100.0 < acc * mult
