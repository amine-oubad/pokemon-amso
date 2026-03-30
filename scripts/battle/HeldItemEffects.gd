class_name HeldItemEffects
## Effets des objets tenus en combat.
## Fonctions statiques appelees a differents moments.

# -- Donnees des objets tenus --------------------------------------------

const HELD_ITEM_DATA := {
	# --- Recovery ---
	"leftovers":    {"name": "Restes",          "desc": "Regagne 1/16 PV par tour."},
	"black_sludge": {"name": "Boue Noire",      "desc": "Regagne PV (Poison), blesse les autres."},
	"shell_bell":   {"name": "Grelot Coque",    "desc": "Regagne 1/8 des degats infliges."},

	# --- Type boosters ---
	"charcoal":     {"name": "Charbon",         "desc": "Booste les attaques Feu de 20%."},
	"mystic_water": {"name": "Eau Mystique",    "desc": "Booste les attaques Eau de 20%."},
	"miracle_seed": {"name": "Graine Miracle",  "desc": "Booste les attaques Plante de 20%."},
	"magnet":       {"name": "Aimant",          "desc": "Booste les attaques Electrik de 20%."},
	"twisted_spoon":{"name": "Cuillere Tordue", "desc": "Booste les attaques Psy de 20%."},
	"never_melt_ice":{"name":"Glace Eternelle", "desc": "Booste les attaques Glace de 20%."},
	"dragon_fang":  {"name": "Croc Dragon",     "desc": "Booste les attaques Dragon de 20%."},
	"black_belt":   {"name": "Ceinture Noire",  "desc": "Booste les attaques Combat de 20%."},
	"poison_barb":  {"name": "Pic Venin",       "desc": "Booste les attaques Poison de 20%."},
	"soft_sand":    {"name": "Sable Doux",       "desc": "Booste les attaques Sol de 20%."},
	"sharp_beak":   {"name": "Bec Pointu",      "desc": "Booste les attaques Vol de 20%."},
	"silver_powder":{"name": "Poudre Argentee", "desc": "Booste les attaques Insecte de 20%."},
	"hard_stone":   {"name": "Pierre Dure",     "desc": "Booste les attaques Roche de 20%."},
	"spell_tag":    {"name": "Rune Sort",       "desc": "Booste les attaques Spectre de 20%."},
	"metal_coat":   {"name": "Peau Metal",      "desc": "Booste les attaques Acier de 20%."},
	"silk_scarf":   {"name": "Mouchoir Soie",   "desc": "Booste les attaques Normal de 20%."},
	"black_glasses":{"name": "Lunettes Noires", "desc": "Booste les attaques Tenebres de 20%."},

	# --- Choice items ---
	"choice_band":  {"name": "Bandeau Choix",   "desc": "Multiplie l'Attaque x1.5 mais bloque un move."},
	"choice_specs": {"name": "Lunettes Choix",  "desc": "Multiplie l'Atq. Spe x1.5 mais bloque un move."},
	"choice_scarf": {"name": "Echarpe Choix",   "desc": "Multiplie la Vitesse x1.5 mais bloque un move."},

	# --- Survival ---
	"focus_sash":   {"name": "Ceinture Force",  "desc": "Survit a un coup fatal avec 1 PV (1 fois, PV max)."},
	"focus_band":   {"name": "Bandeau",         "desc": "10% de chance de survivre a un coup fatal."},

	# --- Berries ---
	"oran_berry":   {"name": "Baie Oran",       "desc": "Restaure 10 PV quand PV < 50%."},
	"sitrus_berry": {"name": "Baie Sitrus",     "desc": "Restaure 25% PV quand PV < 50%."},
	"lum_berry":    {"name": "Baie Prine",      "desc": "Soigne tout statut (1 fois)."},
	"chesto_berry": {"name": "Baie Maron",      "desc": "Soigne le sommeil (1 fois)."},
	"rawst_berry":  {"name": "Baie Fraive",     "desc": "Soigne la brulure (1 fois)."},
	"pecha_berry":  {"name": "Baie Pecha",      "desc": "Soigne le poison (1 fois)."},
	"cheri_berry":  {"name": "Baie Ceriz",      "desc": "Soigne la paralysie (1 fois)."},
	"aspear_berry": {"name": "Baie Willia",     "desc": "Soigne le gel (1 fois)."},
	"liechi_berry": {"name": "Baie Lichii",     "desc": "Booste Attaque quand PV < 25%."},
	"petaya_berry": {"name": "Baie Pitaye",     "desc": "Booste Atq. Spe quand PV < 25%."},
	"salac_berry":  {"name": "Baie Sailak",     "desc": "Booste Vitesse quand PV < 25%."},

	# --- Battle items ---
	"life_orb":     {"name": "Orbe Vie",        "desc": "Booste les attaques de 30% mais perd 10% PV."},
	"expert_belt":  {"name": "Ceinture Pro",    "desc": "Booste les attaques super efficaces de 20%."},
	"kings_rock":   {"name": "Roche Royale",    "desc": "10% de chance de faire tressaillir."},
	"wide_lens":    {"name": "Loupe",           "desc": "Augmente la precision de 10%."},
	"scope_lens":   {"name": "Lentilscope",     "desc": "Augmente le taux critique."},
	"muscle_band":  {"name": "Bandeau Muscle",  "desc": "Booste les attaques physiques de 10%."},
	"wise_glasses": {"name": "Lunettes Sages",  "desc": "Booste les attaques speciales de 10%."},
	"eviolite":     {"name": "Evoluroc",        "desc": "Booste Def et Def.Spe de 50% si pas evo finale."},
	"assault_vest": {"name": "Veste Assaut",    "desc": "Booste Def.Spe de 50% mais empeche statut moves."},
	"rocky_helmet": {"name": "Casque Brut",     "desc": "Blesse l'attaquant au contact (1/6 PV max)."},
	"light_clay":   {"name": "Argile Lumiere",  "desc": "Les ecrans durent 8 tours au lieu de 5."},
	"heat_rock":    {"name": "Roche Chaude",    "desc": "Le soleil dure 8 tours au lieu de 5."},
	"damp_rock":    {"name": "Roche Humide",    "desc": "La pluie dure 8 tours au lieu de 5."},
	"smooth_rock":  {"name": "Roche Lisse",     "desc": "Tempete de sable dure 8 tours."},
	"icy_rock":     {"name": "Roche Glacee",    "desc": "La grele dure 8 tours."},

	# --- Gen 4+ items ---
	"toxic_orb":    {"name": "Orbe Toxique",    "desc": "Empoisonne le porteur en fin de tour."},
	"flame_orb":    {"name": "Orbe Flamme",     "desc": "Brule le porteur en fin de tour."},
	"iron_ball":    {"name": "Balle de Fer",    "desc": "Divise la Vitesse par 2."},
	"lagging_tail": {"name": "Queue Trainante", "desc": "Le porteur agit en dernier."},
	"quick_claw":   {"name": "Griffe Rapide",   "desc": "20% de chance d'agir en premier."},
	"red_card":     {"name": "Carton Rouge",    "desc": "Force l'adversaire a changer apres un coup."},
	"air_balloon":  {"name": "Ballon",          "desc": "Immunise Sol (detruit apres un coup)."},
	"absorb_bulb":  {"name": "Bulbe",           "desc": "Booste Atq Spe quand touche par Eau (1 fois)."},
	"cell_battery": {"name": "Pile",            "desc": "Booste Atq quand touche par Electrik (1 fois)."},
	"weakness_policy":{"name":"Mouchoir Blanc", "desc": "Booste Atq et Atq Spe apres un coup super efficace."},
	"safety_goggles":{"name":"Lunettes Filtre", "desc": "Immunise aux attaques poudre et degats meteo."},
	"protective_pads":{"name":"Protege-Pattes", "desc": "Ignore les effets de contact du defenseur."},
	"heavy_duty_boots":{"name":"Bottes de Plomb","desc":"Ignore les entry hazards."},
	"terrain_extender":{"name":"Generateur",    "desc": "Les terrains durent 8 tours."},
	"throat_spray":  {"name": "Spray Gorge",    "desc": "Booste Atq Spe apres une attaque sonore."},
	"blunder_policy":{"name":"Maladresse",      "desc": "Booste Vitesse x2 apres un rate."},
	"room_service":  {"name": "Service en Salle","desc":"Baisse Vitesse en Trick Room."},
	"loaded_dice":   {"name": "De Pipe",        "desc": "Multi-hit touche 4-5 fois minimum."},
	"covert_cloak":  {"name": "Cape Discrete",  "desc": "Immunise aux effets secondaires."},
	"clear_amulet":  {"name": "Amulette Pure",  "desc": "Empeche les baisses de stats."},
	"mirror_herb":   {"name": "Herbe Miroir",   "desc": "Copie les boosts de stats de l'adversaire (1 fois)."},
	"booster_energy":{"name":"Energie Booster", "desc": "Active Protosynthese ou Champ Quantique."},
	"punching_glove":{"name":"Gant de Boxe",    "desc": "Booste les attaques poing de 10%, retire contact."},
}

## Mapping type -> item boosters
const TYPE_BOOSTERS := {
	"Fire": "charcoal", "Water": "mystic_water", "Grass": "miracle_seed",
	"Electric": "magnet", "Psychic": "twisted_spoon", "Ice": "never_melt_ice",
	"Dragon": "dragon_fang", "Fighting": "black_belt", "Poison": "poison_barb",
	"Ground": "soft_sand", "Flying": "sharp_beak", "Bug": "silver_powder",
	"Rock": "hard_stone", "Ghost": "spell_tag", "Steel": "metal_coat",
	"Normal": "silk_scarf", "Dark": "black_glasses",
}

## Nom affichable.
static func get_item_name(item_id: String) -> String:
	return HELD_ITEM_DATA.get(item_id, {}).get("name", item_id)

# =========================================================================
#  HOOKS
# =========================================================================

# -- Multiplicateur de degats (attaquant) ---------------------------------

static func get_damage_multiplier(attacker, move_type: String, move_category: String, effectiveness: float) -> float:
	var item: String = attacker.held_item
	var mult := 1.0

	# Type boosters (+20%)
	var booster: String = TYPE_BOOSTERS.get(move_type, "")
	if item == booster and booster != "":
		mult *= 1.2

	# Choice items
	match item:
		"choice_band":
			if move_category == "physical": mult *= 1.5
		"choice_specs":
			if move_category == "special": mult *= 1.5

	# Life Orb (+30%)
	if item == "life_orb":
		mult *= 1.3

	# Expert Belt (+20% on super effective)
	if item == "expert_belt" and effectiveness > 1.0:
		mult *= 1.2

	# Muscle Band / Wise Glasses (+10%)
	if item == "muscle_band" and move_category == "physical":
		mult *= 1.1
	if item == "wise_glasses" and move_category == "special":
		mult *= 1.1

	# Punching Glove (+10% punch moves)
	if item == "punching_glove":
		var move_id: String = attacker.get_meta("current_move_id", "")
		if MoveEffects.is_punch_move(move_id):
			mult *= 1.1

	return mult

# -- Multiplicateur de stat -----------------------------------------------

static func get_stat_multiplier(pkmn, stat: String) -> float:
	var item: String = pkmn.held_item
	var mult := 1.0

	match item:
		"choice_band":
			if stat == "atk": mult *= 1.5
		"choice_specs":
			if stat == "sp_atk": mult *= 1.5
		"choice_scarf":
			if stat == "speed": mult *= 1.5
		"eviolite":
			# TODO: check if pkmn can still evolve
			if stat in ["def", "sp_def"]: mult *= 1.5
		"assault_vest":
			if stat == "sp_def": mult *= 1.5
		"iron_ball":
			if stat == "speed": mult *= 0.5

	return mult

# -- Apres avoir inflige des degats (attaquant) ----------------------------

## Retourne {message, self_damage, self_heal}
static func on_after_attacking(attacker, damage_dealt: int) -> Dictionary:
	var item: String = attacker.held_item
	var result := {"message": "", "self_damage": 0, "self_heal": 0}

	match item:
		"life_orb":
			var recoil := maxi(1, int(attacker.max_hp / 10.0))
			result.self_damage = recoil
			result.message = "%s perd des PV a cause de l'Orbe Vie !" % attacker.get_name()

		"shell_bell":
			var heal := maxi(1, int(damage_dealt / 8.0))
			result.self_heal = heal
			result.message = "%s regagne des PV avec Grelot Coque !" % attacker.get_name()

	return result

# -- Apres avoir ete touche (defenseur, contact) --------------------------

static func on_after_hit_contact(attacker, defender) -> String:
	if attacker.is_fainted():
		return ""
	var item: String = defender.held_item

	match item:
		"rocky_helmet":
			var dmg := maxi(1, int(attacker.max_hp / 6.0))
			attacker.take_damage(dmg)
			return "Casque Brut de %s blesse %s !" % [defender.get_name(), attacker.get_name()]

		"kings_rock":
			# This is actually on the attacker, handled via flinch chance
			pass

	return ""

# -- Survie a un coup fatal -----------------------------------------------

## Retourne true si l'objet sauve le Pokemon. Modifie current_hp a 1.
static func check_survival(pkmn, damage: int) -> Dictionary:
	var item: String = pkmn.held_item
	var result := {"survived": false, "message": "", "consume": false}

	match item:
		"focus_sash":
			if pkmn.current_hp == pkmn.max_hp and damage >= pkmn.current_hp:
				result.survived = true
				result.consume = true
				result.message = "%s tient bon grace a Ceinture Force !" % pkmn.get_name()

		"focus_band":
			if damage >= pkmn.current_hp and randf() < 0.10:
				result.survived = true
				result.message = "%s tient bon grace au Bandeau !" % pkmn.get_name()

	return result

# -- Fin de tour ----------------------------------------------------------

## Retourne un Array de {message, consume}
static func on_end_of_turn(pkmn) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var item: String = pkmn.held_item

	if pkmn.is_fainted() or item == "":
		return effects

	match item:
		"leftovers":
			if pkmn.current_hp < pkmn.max_hp:
				var heal := maxi(1, int(pkmn.max_hp / 16.0))
				pkmn.heal(heal)
				effects.append({"message": "%s regagne des PV avec les Restes !" % pkmn.get_name()})

		"black_sludge":
			if "Poison" in pkmn.get_types():
				if pkmn.current_hp < pkmn.max_hp:
					var heal := maxi(1, int(pkmn.max_hp / 16.0))
					pkmn.heal(heal)
					effects.append({"message": "%s regagne des PV avec la Boue Noire !" % pkmn.get_name()})
			else:
				var dmg := maxi(1, int(pkmn.max_hp / 8.0))
				pkmn.take_damage(dmg)
				effects.append({"message": "%s perd des PV a cause de la Boue Noire !" % pkmn.get_name()})

		"toxic_orb":
			if pkmn.status == "":
				pkmn.status = "bad_poison"
				pkmn.status_turns = 0
				effects.append({"message": "%s est empoisonne par l'Orbe Toxique !" % pkmn.get_name()})

		"flame_orb":
			if pkmn.status == "":
				var types := pkmn.get_types()
				if "Fire" not in types:
					pkmn.status = "burn"
					effects.append({"message": "%s est brule par l'Orbe Flamme !" % pkmn.get_name()})

	return effects

# -- Check berry trigger (apres degats ou fin de tour) --------------------

## Retourne {message, consume} si une baie s'active.
static func check_berry(pkmn) -> Dictionary:
	var item: String = pkmn.held_item
	var result := {"message": "", "consume": false}

	if pkmn.is_fainted() or item == "":
		return result

	var hp_ratio := float(pkmn.current_hp) / float(pkmn.max_hp)

	match item:
		"oran_berry":
			if hp_ratio < 0.50:
				pkmn.heal(10)
				result.message = "%s mange sa Baie Oran et regagne des PV !" % pkmn.get_name()
				result.consume = true

		"sitrus_berry":
			if hp_ratio < 0.50:
				var heal := int(pkmn.max_hp / 4.0)
				pkmn.heal(heal)
				result.message = "%s mange sa Baie Sitrus et regagne des PV !" % pkmn.get_name()
				result.consume = true

		"lum_berry":
			if pkmn.status != "":
				pkmn.status = ""
				pkmn.status_turns = 0
				result.message = "%s mange sa Baie Prine et soigne son statut !" % pkmn.get_name()
				result.consume = true

		"chesto_berry":
			if pkmn.status == "sleep":
				pkmn.status = ""
				pkmn.status_turns = 0
				result.message = "%s mange sa Baie Maron et se reveille !" % pkmn.get_name()
				result.consume = true

		"rawst_berry":
			if pkmn.status == "burn":
				pkmn.status = ""
				result.message = "%s mange sa Baie Fraive et soigne sa brulure !" % pkmn.get_name()
				result.consume = true

		"pecha_berry":
			if pkmn.status in ["poison", "bad_poison"]:
				pkmn.status = ""
				pkmn.status_turns = 0
				result.message = "%s mange sa Baie Pecha et soigne le poison !" % pkmn.get_name()
				result.consume = true

		"cheri_berry":
			if pkmn.status == "paralyze":
				pkmn.status = ""
				result.message = "%s mange sa Baie Ceriz et soigne sa paralysie !" % pkmn.get_name()
				result.consume = true

		"aspear_berry":
			if pkmn.status == "freeze":
				pkmn.status = ""
				result.message = "%s mange sa Baie Willia et degele !" % pkmn.get_name()
				result.consume = true

		"liechi_berry":
			if hp_ratio < 0.25:
				pkmn.modify_stat_stage("atk", 1)
				result.message = "%s mange sa Baie Lichii !\nSon Attaque monte !" % pkmn.get_name()
				result.consume = true

		"petaya_berry":
			if hp_ratio < 0.25:
				pkmn.modify_stat_stage("sp_atk", 1)
				result.message = "%s mange sa Baie Pitaye !\nSon Atq. Spe. monte !" % pkmn.get_name()
				result.consume = true

		"salac_berry":
			if hp_ratio < 0.25:
				pkmn.modify_stat_stage("speed", 1)
				result.message = "%s mange sa Baie Sailak !\nSa Vitesse monte !" % pkmn.get_name()
				result.consume = true

	return result

# -- Consume item (remove from pokemon) -----------------------------------

static func consume_item(pkmn) -> void:
	pkmn.set_meta("consumed_item", pkmn.held_item)
	pkmn.held_item = ""

# -- After being hit (defender, any move) ----------------------------------

## Called after the defender takes a super-effective hit. Returns messages.
static func on_after_hit(defender, effectiveness: float) -> Array[String]:
	var msgs: Array[String] = []
	var item: String = defender.held_item
	if item == "" or defender.is_fainted():
		return msgs

	# Weakness Policy: +2 Atk, +2 SpAtk on super effective hit
	if item == "weakness_policy" and effectiveness > 1.0:
		defender.modify_stat_stage("atk", 2)
		defender.modify_stat_stage("sp_atk", 2)
		msgs.append("%s active son Mouchoir Blanc !\nAtq et Atq Spe montent enormement !" % defender.get_name())
		consume_item(defender)

	# Air Balloon pops on any hit
	if item == "air_balloon":
		msgs.append("Le Ballon de %s eclate !" % defender.get_name())
		consume_item(defender)

	# Absorb Bulb: +1 SpAtk when hit by Water
	if item == "absorb_bulb":
		var move_type: String = defender.get_meta("hit_by_type", "")
		if move_type == "Water":
			defender.modify_stat_stage("sp_atk", 1)
			msgs.append("%s active son Bulbe !" % defender.get_name())
			consume_item(defender)

	# Cell Battery: +1 Atk when hit by Electric
	if item == "cell_battery":
		var move_type: String = defender.get_meta("hit_by_type", "")
		if move_type == "Electric":
			defender.modify_stat_stage("atk", 1)
			msgs.append("%s active sa Pile !" % defender.get_name())
			consume_item(defender)

	return msgs

# -- Heavy-Duty Boots check -----------------------------------------------

static func ignores_hazards(pkmn) -> bool:
	return pkmn.held_item == "heavy_duty_boots"

# -- Safety Goggles check -------------------------------------------------

static func has_safety_goggles(pkmn) -> bool:
	return pkmn.held_item == "safety_goggles"

# -- Air Balloon ground immunity ------------------------------------------

static func has_air_balloon(pkmn) -> bool:
	return pkmn.held_item == "air_balloon"

# -- Covert Cloak (blocks secondary effects) ------------------------------

static func has_covert_cloak(pkmn) -> bool:
	return pkmn.held_item == "covert_cloak"

# -- Clear Amulet (prevents stat drops) -----------------------------------

static func has_clear_amulet(pkmn) -> bool:
	return pkmn.held_item == "clear_amulet"

# -- Precision modifier ---------------------------------------------------

static func get_accuracy_multiplier(attacker) -> float:
	match attacker.held_item:
		"wide_lens": return 1.1
	return 1.0

# -- Crit rate modifier ---------------------------------------------------

static func get_crit_stage_bonus(attacker) -> int:
	match attacker.held_item:
		"scope_lens": return 1
		"razor_claw": return 1
	return 0

# -- Loaded Dice: minimum 4 hits on multi-hit moves ----------------------

static func has_loaded_dice(pkmn) -> bool:
	return pkmn.held_item == "loaded_dice"

# -- Quick Claw: 20% chance to go first ----------------------------------

static func check_quick_claw(pkmn) -> bool:
	return pkmn.held_item == "quick_claw" and randf() < 0.20

# -- Choice lock check ----------------------------------------------------

## Retourne true si le Pokemon est verrouille sur un move par un objet Choice.
static func is_choice_locked(pkmn) -> bool:
	return pkmn.held_item in ["choice_band", "choice_specs", "choice_scarf"]

# -- Weather duration modifier --------------------------------------------

static func get_weather_duration(pkmn, base_turns: int) -> int:
	match pkmn.held_item:
		"heat_rock":   return 8
		"damp_rock":   return 8
		"smooth_rock": return 8
		"icy_rock":    return 8
	return base_turns

# -- Screen duration modifier ---------------------------------------------

static func get_screen_duration(pkmn, base_turns: int) -> int:
	if pkmn.held_item == "light_clay":
		return 8
	return base_turns
