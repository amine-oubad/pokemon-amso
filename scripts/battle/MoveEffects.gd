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
		"lower_target_speed":    return _change_stat(defender, "speed",    -1)
		"lower_target_accuracy": return _change_stat(defender, "accuracy", -1)

		# ── Hausses de stats de l'attaquant ───────────────────────────────────
		"raise_self_def":   return _change_stat(attacker, "def",    1)
		"raise_self_spatk": return _change_stat(attacker, "sp_atk", 1)

		# ── Effets spéciaux (Phase 3+) ────────────────────────────────────────
		"flinch", "high_crit", "two_turn", "fixed_damage_40", "leech_seed":
			return ""  # TODO Phase 3

	return ""

# ── Vérification de statut en début de tour ───────────────────────────────────

## Vérifie si un Pokémon peut agir ce tour.
## Retourne { can_move: bool, message: String }
static func check_can_move(pkmn: PokemonInstance) -> Dictionary:
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
	                 "sp_def":"Déf. Spé", "speed":"Vitesse", "accuracy":"Précision" }
	var lbl: String = NAMES.get(stat, stat)
	if actual == 0:
		return "%s : %s ne peut pas %s davantage !" % [target.get_name(), lbl, "monter" if delta > 0 else "baisser"]
	if actual > 0:
		return "%s : %s monte !" % [target.get_name(), lbl]
	return "%s : %s baisse !" % [target.get_name(), lbl]
