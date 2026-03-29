class_name MoveEffects
## Effets secondaires des moves et gestion des statuts.
## Toutes les fonctions sont statiques.

# ── Infos statut ───────────────────────────────────────────────────────────────
const STATUS_ABBR := {
	"burn":      "BRU",
	"paralyze":  "PAR",
	"sleep":     "SOM",
	"freeze":    "GEL",
	"poison":    "PSN",
	"bad_poison":"PSN",
}
const STATUS_COLOR := {
	"burn":       Color(0.90, 0.30, 0.10),
	"paralyze":   Color(0.90, 0.80, 0.10),
	"sleep":      Color(0.40, 0.40, 0.60),
	"freeze":     Color(0.45, 0.75, 0.90),
	"poison":     Color(0.60, 0.20, 0.70),
	"bad_poison": Color(0.45, 0.08, 0.55),
}

# ── Application de l'effet secondaire d'un move ───────────────────────────────

## Applique l'effet secondaire d'un move (après avoir infligé les dégâts).
## Retourne un message décrivant ce qui s'est passé, ou "" si rien.
static func apply_move_effect(
	move: MoveInstance,
	attacker: PokemonInstance,
	defender: PokemonInstance
) -> String:
	var effect: String = move.get_effect()
	if effect == "":
		return ""
	var chance: int = move.get_effect_chance()
	if chance < 100 and randf() * 100.0 > chance:
		return ""  # L'effet ne se déclenche pas ce tour

	match effect:
		# ── Statuts principaux ────────────────────────────────────────────────
		"burn":            return _apply_status(defender, "burn")
		"paralyze":        return _apply_status(defender, "paralyze")
		"poison":          return _apply_status(defender, "poison")
		"sleep":           return _apply_status(defender, "sleep")
		"freeze":          return _apply_status(defender, "freeze")

		# ── Baisses de stats de la cible ──────────────────────────────────────
		"lower_target_atk":      return _change_stat(defender, "atk",      -1)
		"lower_target_def":      return _change_stat(defender, "def",      -1)
		"lower_target_spdef":    return _change_stat(defender, "sp_def",   -1)
		"lower_target_speed":    return _change_stat(defender, "speed",    -1)
		"lower_target_spatk":    return _change_stat(defender, "sp_atk",  -1)
		"lower_target_accuracy": return _change_stat(defender, "accuracy", -1)

		# ── Hausses de stats de l'attaquant ───────────────────────────────────
		"raise_self_def":      return _change_stat(attacker, "def",     1)
		"raise_self_spatk":    return _change_stat(attacker, "sp_atk",  1)
		"raise_self_evasion":  return _change_stat(attacker, "evasion", 1)
		"raise_self_atk_2":
			return _change_stat(attacker, "atk", 2)
		"raise_self_speed_2":
			return _change_stat(attacker, "speed", 2)
		"raise_self_atk":
			return _change_stat(attacker, "atk", 1)
		"raise_self_spdef":    return _change_stat(attacker, "sp_def", 1)

		# ── Flinch (empêche l'adversaire d'agir ce tour) ─────────────────────
		"flinch":
			defender.set_meta("flinch", true)
			return ""

		# ── High crit (taux critique élevé — géré dans BattleCalc) ────────
		"high_crit":
			return ""  # Déjà géré via move flag dans BattleCalc

		# ── Confusion ─────────────────────────────────────────────────────
		"confuse":
			if defender.has_meta("confused"):
				return "%s est déjà confus !" % defender.get_name()
			defender.set_meta("confused", randi_range(2, 5))
			return "%s est confus !" % defender.get_name()

		# ── Soin 50% PV max (Recover, Soft-Boiled) ───────────────────────
		"heal_half":
			var heal_amt := int(attacker.max_hp / 2.0)
			var actual := attacker.heal(heal_amt)
			if actual == 0:
				return "%s a déjà tous ses PV !" % attacker.get_name()
			return "%s récupère des PV !" % attacker.get_name()

		# ── Rest — soin complet + endort 2 tours ─────────────────────────
		"rest":
			if attacker.current_hp == attacker.max_hp:
				return "Mais cela échoue ! %s a déjà tous ses PV !" % attacker.get_name()
			attacker.heal(attacker.max_hp)
			attacker.status = "sleep"
			attacker.status_turns = 2
			return "%s se repose et récupère tous ses PV !" % attacker.get_name()

		# ── Self-Destruct / Explosion — KO l'utilisateur ──────────────────
		"self_faint":
			attacker.take_damage(attacker.current_hp)
			return "%s se sacrifie !" % attacker.get_name()

		# ── Focus Energy — taux critique élevé ────────────────────────────
		"focus_energy":
			if attacker.has_meta("focus_energy"):
				return "Mais cela échoue !"
			attacker.set_meta("focus_energy", true)
			return "%s se concentre !" % attacker.get_name()

		# ── Dégâts fixes (ex: Dragon Rage = 40 HP) ───────────────────────
		"fixed_damage_20":
			defender.take_damage(20)
			return "%s subit 20 points de dégâts fixes !" % defender.get_name()
		"fixed_damage_40":
			defender.take_damage(40)
			return "%s subit 40 points de dégâts fixes !" % defender.get_name()

		# ── Vampigraine (drain 1/8 PV max par tour) ──────────────────────
		"leech_seed":
			if "Grass" in defender.get_types():
				return "Ça n'affecte pas %s..." % defender.get_name()
			if defender.has_meta("leech_seed"):
				return "%s est déjà parasité !" % defender.get_name()
			defender.set_meta("leech_seed", true)
			defender.set_meta("leech_seed_source", attacker)
			return "%s est parasité !" % defender.get_name()

		# ── Deux tours (Solar Beam, Dig, Fly…) — géré dans BattleScene ──────
		"two_turn":
			return ""

		# ── Protect — bloque toutes les attaques ce tour ─────────────────
		"protect":
			var consecutive: int = attacker.get_meta("protect_consecutive", 0)
			var success_rate := 1.0 / pow(3.0, consecutive)
			if randf() < success_rate:
				attacker.set_meta("protect", true)
				attacker.set_meta("protect_consecutive", consecutive + 1)
				return "%s se protège !" % attacker.get_name()
			else:
				attacker.set_meta("protect_consecutive", 0)
				return "Mais cela échoue !"

		# ── Rain Dance — météo pluie 5 tours ─────────────────────────────
		"rain_dance":
			return ""  # Géré dans BattleScene (set weather)

		# ── Baton Pass — switch en gardant les stat stages ────────────────
		"baton_pass":
			return ""  # Géré dans BattleScene (force switch menu)

	return ""

# ── Vérification de statut en début de tour ───────────────────────────────────

## Vérifie si un Pokémon peut agir ce tour.
## Retourne { can_move: bool, message: String }
static func check_can_move(pkmn: PokemonInstance) -> Dictionary:
	# Flinch — empêche d'agir ce tour puis se reset
	if pkmn.has_meta("flinch") and pkmn.get_meta("flinch"):
		pkmn.set_meta("flinch", false)
		return { "can_move": false, "message": "%s a tressailli !\nIl ne peut pas attaquer !" % pkmn.get_name() }

	# Confusion — chance de se frapper soi-même
	if pkmn.has_meta("confused"):
		var turns_left: int = pkmn.get_meta("confused")
		if turns_left <= 0:
			pkmn.remove_meta("confused")
		else:
			pkmn.set_meta("confused", turns_left - 1)
			if randf() < 0.33:
				var self_dmg := maxi(1, int(pkmn.max_hp / 8.0))
				pkmn.take_damage(self_dmg)
				return { "can_move": false, "message": "%s est confus !\nIl se blesse dans sa confusion !" % pkmn.get_name() }

	match pkmn.status:
		"paralyze":
			if randf() < 0.25:
				return { "can_move": false, "message": "%s est paralysé !\nIl ne peut pas bouger !" % pkmn.get_name() }
		"sleep":
			if pkmn.status_turns > 0:
				pkmn.status_turns -= 1
				if pkmn.status_turns == 0:
					pkmn.status = ""
					return { "can_move": true, "message": "%s se réveille !" % pkmn.get_name() }
				return { "can_move": false, "message": "%s dort profondément..." % pkmn.get_name() }
		"freeze":
			if randf() < 0.20:  # 20% de chance de dégel spontané
				pkmn.status = ""
				return { "can_move": true, "message": "%s dégèle !" % pkmn.get_name() }
			return { "can_move": false, "message": "%s est gelé !\nIl ne peut pas bouger !" % pkmn.get_name() }
	return { "can_move": true, "message": "" }

# ── Effets de fin de tour ─────────────────────────────────────────────────────

## Applique les dégâts de statut en fin de tour (brûlure, poison).
## Retourne un message, ou "" si rien.
static func apply_end_of_turn(pkmn: PokemonInstance) -> String:
	if pkmn.is_fainted():
		return ""
	match pkmn.status:
		"burn":
			var dmg := maxi(1, int(pkmn.max_hp / 8.0))
			pkmn.take_damage(dmg)
			return "%s souffre de sa brûlure !" % pkmn.get_name()
		"poison":
			var dmg := maxi(1, int(pkmn.max_hp / 8.0))
			pkmn.take_damage(dmg)
			return "%s souffre du poison !" % pkmn.get_name()
		"bad_poison":
			pkmn.status_turns += 1
			var dmg := maxi(1, int(pkmn.max_hp * pkmn.status_turns / 16.0))
			pkmn.take_damage(dmg)
			return "%s souffre du poison violent !" % pkmn.get_name()

	# Vampigraine (leech_seed) — drain 1/8 PV max, heal opponent
	if pkmn.has_meta("leech_seed") and pkmn.get_meta("leech_seed"):
		var seed_dmg := maxi(1, int(pkmn.max_hp / 8.0))
		var actual := pkmn.take_damage(seed_dmg)
		# Heal the opponent (stored in meta as the seeder)
		var seeder = pkmn.get_meta("leech_seed_source") if pkmn.has_meta("leech_seed_source") else null
		if seeder is PokemonInstance and not seeder.is_fainted():
			seeder.heal(actual)
		return "%s est drainé par Vampigraine !" % pkmn.get_name()

	return ""

# ── Helpers privés ─────────────────────────────────────────────────────────────

static func _apply_status(target: PokemonInstance, status: String) -> String:
	if target.status != "":
		return ""  # Déjà un statut primaire

	# Immunités de type
	var types := target.get_types()
	match status:
		"burn":     if "Fire"     in types: return ""
		"paralyze": if "Electric" in types: return ""
		"freeze":   if "Ice"      in types: return ""
		"poison", "bad_poison":
			if "Poison" in types or "Steel" in types: return ""

	target.status = status
	if status == "sleep":
		target.status_turns = randi_range(1, 3)  # 1–3 tours de sommeil
	elif status == "bad_poison":
		target.status_turns = 0

	match status:
		"burn":      return "%s est brûlé !" % target.get_name()
		"paralyze":  return "%s est paralysé !" % target.get_name()
		"sleep":     return "%s s'endort !" % target.get_name()
		"freeze":    return "%s est gelé !" % target.get_name()
		"poison":    return "%s est empoisonné !" % target.get_name()
		"bad_poison":return "%s est gravement empoisonné !" % target.get_name()
	return ""

static func _change_stat(target: PokemonInstance, stat: String, delta: int) -> String:
	var actual := target.modify_stat_stage(stat, delta)
	const NAMES := { "atk":"Attaque", "def":"Défense", "sp_atk":"Atq. Spé",
	                 "sp_def":"Déf. Spé", "speed":"Vitesse", "accuracy":"Précision",
	                 "evasion":"Esquive" }
	var lbl: String = NAMES.get(stat, stat)
	if actual == 0:
		return "%s : %s ne peut pas %s davantage !" % [target.get_name(), lbl, "monter" if delta > 0 else "baisser"]
	if actual > 0:
		return "%s : %s monte !" % [target.get_name(), lbl]
	return "%s : %s baisse !" % [target.get_name(), lbl]
