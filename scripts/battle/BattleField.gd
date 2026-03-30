class_name BattleField
extends RefCounted
## Etat du terrain de combat : meteo, ecrans, hazards, terrain.
## Objet partage entre tous les composants du systeme de combat.

# -- Meteo ---------------------------------------------------------------
enum Weather { NONE, RAIN, SUN, SANDSTORM, HAIL }

var weather: Weather = Weather.NONE
var weather_turns: int = 0
var weather_source: String = ""  # ability id that set permanent weather

func set_weather(w: Weather, turns: int = 5, source: String = "") -> String:
	weather = w
	weather_turns = turns
	weather_source = source
	match w:
		Weather.RAIN:      return "Il commence a pleuvoir !"
		Weather.SUN:       return "Le soleil brille intensement !"
		Weather.SANDSTORM: return "Une tempete de sable se leve !"
		Weather.HAIL:      return "Il commence a greler !"
		_:                 return ""

func tick_weather() -> String:
	if weather == Weather.NONE:
		return ""
	# Permanent weather from abilities doesn't count down
	if weather_source != "":
		return ""
	weather_turns -= 1
	if weather_turns <= 0:
		var msg := ""
		match weather:
			Weather.RAIN:      msg = "La pluie s'arrete."
			Weather.SUN:       msg = "Le soleil redevient normal."
			Weather.SANDSTORM: msg = "La tempete de sable se calme."
			Weather.HAIL:      msg = "La grele s'arrete."
		weather = Weather.NONE
		weather_source = ""
		return msg
	return ""

func get_weather_multiplier(move_type: String) -> float:
	match weather:
		Weather.RAIN:
			if move_type == "Water": return 1.5
			if move_type == "Fire":  return 0.5
		Weather.SUN:
			if move_type == "Fire":  return 1.5
			if move_type == "Water": return 0.5
	return 1.0

## Degats de meteo en fin de tour. Retourne {damage, message} ou null.
func get_weather_damage(pkmn) -> Dictionary:
	var types: Array = pkmn.get_types()
	match weather:
		Weather.SANDSTORM:
			if "Rock" in types or "Ground" in types or "Steel" in types:
				return {}
			# Ability immunities handled externally
			var dmg := maxi(1, int(pkmn.max_hp / 16.0))
			return {"damage": dmg, "message": "%s souffre de la tempete de sable !" % pkmn.get_name()}
		Weather.HAIL:
			if "Ice" in types:
				return {}
			var dmg := maxi(1, int(pkmn.max_hp / 16.0))
			return {"damage": dmg, "message": "%s souffre de la grele !" % pkmn.get_name()}
	return {}

# -- Ecrans (par camp) ---------------------------------------------------
# "player" or "enemy"
var screens: Dictionary = {
	"player": {"reflect": 0, "light_screen": 0, "aurora_veil": 0},
	"enemy":  {"reflect": 0, "light_screen": 0, "aurora_veil": 0},
}

func set_screen(side: String, screen_type: String, turns: int = 5) -> String:
	if screens[side][screen_type] > 0:
		return "Mais cela echoue !"
	screens[side][screen_type] = turns
	match screen_type:
		"reflect":      return "Mur Lumiere protege l'equipe !"
		"light_screen": return "Protection se met en place !"
		"aurora_veil":  return "Voile Aurore protege l'equipe !"
	return ""

func tick_screens() -> Array[String]:
	var messages: Array[String] = []
	for side in ["player", "enemy"]:
		for scr in screens[side]:
			if screens[side][scr] > 0:
				screens[side][scr] -= 1
				if screens[side][scr] == 0:
					var side_name := "allie" if side == "player" else "ennemi"
					match scr:
						"reflect":      messages.append("Mur Lumiere du camp %s se dissipe !" % side_name)
						"light_screen": messages.append("Protection du camp %s se dissipe !" % side_name)
						"aurora_veil":  messages.append("Voile Aurore du camp %s se dissipe !" % side_name)
	return messages

func get_screen_multiplier(side: String, category: String) -> float:
	var s: Dictionary = screens[side]
	if s.get("aurora_veil", 0) > 0:
		return 0.5
	match category:
		"physical":
			if s.get("reflect", 0) > 0: return 0.5
		"special":
			if s.get("light_screen", 0) > 0: return 0.5
	return 1.0

# -- Hazards (par camp) --------------------------------------------------
var hazards: Dictionary = {
	"player": {"stealth_rock": false, "spikes": 0, "toxic_spikes": 0, "sticky_web": false},
	"enemy":  {"stealth_rock": false, "spikes": 0, "toxic_spikes": 0, "sticky_web": false},
}

# -- Trick Room / Tailwind (par camp) ------------------------------------
var trick_room_turns: int = 0
var tailwind: Dictionary = {"player": 0, "enemy": 0}

func add_hazard(side: String, hazard_type: String) -> String:
	match hazard_type:
		"stealth_rock":
			if hazards[side]["stealth_rock"]:
				return "Mais cela echoue !"
			hazards[side]["stealth_rock"] = true
			return "Des pierres pointues levitent autour du camp !"
		"spikes":
			if hazards[side]["spikes"] >= 3:
				return "Mais cela echoue !"
			hazards[side]["spikes"] += 1
			return "Des picots se repandent autour du camp !"
		"toxic_spikes":
			if hazards[side]["toxic_spikes"] >= 2:
				return "Mais cela echoue !"
			hazards[side]["toxic_spikes"] += 1
			return "Des pics empoisonnes se repandent !"
		"sticky_web":
			if hazards[side]["sticky_web"]:
				return "Mais cela echoue !"
			hazards[side]["sticky_web"] = true
			return "Une toile gluante se repand !"
	return ""

## Applique les hazards lors d'un switch-in. Retourne les messages.
func apply_entry_hazards(side: String, pkmn) -> Array[String]:
	var msgs: Array[String] = []
	var types: Array = pkmn.get_types()

	# Stealth Rock — degats selon efficacite type Roche
	if hazards[side]["stealth_rock"]:
		var eff: float = GameData.get_total_effectiveness("Rock", types)
		var dmg := maxi(1, int(pkmn.max_hp * eff / 8.0))
		pkmn.take_damage(dmg)
		msgs.append("%s est blesse par les pierres pointues !" % pkmn.get_name())

	# Spikes — 1/8, 1/6, 1/4 selon le nombre de couches
	if hazards[side]["spikes"] > 0 and "Flying" not in types:
		var fractions := [0.0, 1.0/8.0, 1.0/6.0, 1.0/4.0]
		var dmg := maxi(1, int(pkmn.max_hp * fractions[hazards[side]["spikes"]]))
		pkmn.take_damage(dmg)
		msgs.append("%s est blesse par les picots !" % pkmn.get_name())

	# Toxic Spikes — empoisonne (1 couche = poison, 2 couches = bad_poison)
	if hazards[side]["toxic_spikes"] > 0:
		if "Flying" in types:
			pass  # Immun (vol)
		elif "Poison" in types:
			hazards[side]["toxic_spikes"] = 0
			msgs.append("Les pics empoisonnes sont absorbes !")
		elif "Steel" in types:
			pass  # Immun (acier)
		elif pkmn.status == "":
			if hazards[side]["toxic_spikes"] >= 2:
				pkmn.status = "bad_poison"
				pkmn.status_turns = 0
				msgs.append("%s est gravement empoisonne par les pics !" % pkmn.get_name())
			else:
				pkmn.status = "poison"
				msgs.append("%s est empoisonne par les pics !" % pkmn.get_name())

	# Sticky Web — baisse vitesse
	if hazards[side]["sticky_web"] and "Flying" not in types:
		pkmn.modify_stat_stage("speed", -1)
		msgs.append("%s est pris dans la toile gluante !\nSa Vitesse baisse !" % pkmn.get_name())

	return msgs

func clear_hazards(side: String) -> String:
	var had := hazards[side]["stealth_rock"] or hazards[side]["spikes"] > 0 or hazards[side]["toxic_spikes"] > 0 or hazards[side]["sticky_web"]
	hazards[side] = {"stealth_rock": false, "spikes": 0, "toxic_spikes": 0, "sticky_web": false}
	if had:
		return "Les hazards sont dissipes !"
	return "Mais cela echoue !"

# -- Terrain (Gen 7+) ----------------------------------------------------
enum Terrain { NONE, ELECTRIC, GRASSY, PSYCHIC, MISTY }
var terrain: Terrain = Terrain.NONE
var terrain_turns: int = 0

func set_terrain(t: Terrain, turns: int = 5) -> String:
	terrain = t
	terrain_turns = turns
	match t:
		Terrain.ELECTRIC: return "Le terrain se charge d'electricite !"
		Terrain.GRASSY:   return "De l'herbe pousse sur le terrain !"
		Terrain.PSYCHIC:  return "Le terrain devient bizarre !"
		Terrain.MISTY:    return "Une brume recouvre le terrain !"
		_:                return ""

func tick_terrain() -> String:
	if terrain == Terrain.NONE:
		return ""
	terrain_turns -= 1
	if terrain_turns <= 0:
		var msg := ""
		match terrain:
			Terrain.ELECTRIC: msg = "Le champ electrique se dissipe."
			Terrain.GRASSY:   msg = "L'herbe disparait du terrain."
			Terrain.PSYCHIC:  msg = "Le terrain psychique se dissipe."
			Terrain.MISTY:    msg = "La brume se dissipe."
		terrain = Terrain.NONE
		return msg
	return ""

func get_terrain_boost(move_type: String) -> float:
	match terrain:
		Terrain.ELECTRIC: if move_type == "Electric": return 1.3
		Terrain.GRASSY:   if move_type == "Grass":    return 1.3
		Terrain.PSYCHIC:  if move_type == "Psychic":  return 1.3
	return 1.0

func terrain_prevents_status(status: String) -> bool:
	if terrain == Terrain.MISTY and status in ["burn", "paralyze", "sleep", "freeze", "poison", "bad_poison", "confuse"]:
		return true
	if terrain == Terrain.ELECTRIC and status == "sleep":
		return true
	return false

# -- Trick Room -----------------------------------------------------------

func set_trick_room(turns: int = 5) -> String:
	if trick_room_turns > 0:
		trick_room_turns = 0
		return "Les dimensions redeviennent normales !"
	trick_room_turns = turns
	return "Les dimensions sont deformees !"

func tick_trick_room() -> String:
	if trick_room_turns <= 0: return ""
	trick_room_turns -= 1
	if trick_room_turns <= 0:
		return "Les dimensions redeviennent normales !"
	return ""

func is_trick_room() -> bool:
	return trick_room_turns > 0

# -- Tailwind -------------------------------------------------------------

func set_tailwind(side: String, turns: int = 4) -> String:
	tailwind[side] = turns
	return "Un vent arriere souffle !"

func tick_tailwind() -> Array[String]:
	var msgs: Array[String] = []
	for side in ["player", "enemy"]:
		if tailwind[side] > 0:
			tailwind[side] -= 1
			if tailwind[side] <= 0:
				var side_name := "allie" if side == "player" else "ennemi"
				msgs.append("Le vent arriere du camp %s se calme !" % side_name)
	return msgs

func has_tailwind(side: String) -> bool:
	return tailwind[side] > 0

# -- Reset complet --------------------------------------------------------
func reset() -> void:
	weather = Weather.NONE
	weather_turns = 0
	weather_source = ""
	terrain = Terrain.NONE
	terrain_turns = 0
	trick_room_turns = 0
	for side in ["player", "enemy"]:
		screens[side] = {"reflect": 0, "light_screen": 0, "aurora_veil": 0}
		hazards[side] = {"stealth_rock": false, "spikes": 0, "toxic_spikes": 0, "sticky_web": false}
		tailwind[side] = 0
