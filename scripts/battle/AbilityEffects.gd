class_name AbilityEffects
## Systeme de talents (abilities) Gen 3-9.
## Fonctions statiques appelees a differents moments du combat.
## Les donnees detaillees sont chargees depuis data/abilities.json via GameData.

# -- Fallback data (used if abilities.json not loaded yet) -----------------

const ABILITY_NAMES := {
	# Starters
	"overgrow": "Engrais", "blaze": "Brasier", "torrent": "Torrent", "swarm": "Essaim",
	# Contact
	"static": "Statik", "poison_point": "Point Poison", "flame_body": "Corps Ardent",
	"cute_charm": "Joli Sourire", "rough_skin": "Peau Dure", "iron_barbs": "Epines Fer",
	"effect_spore": "Effet Spore", "gooey": "Poisseux", "wandering_spirit": "Corps Errant",
	# Type immunities
	"levitate": "Levitation", "flash_fire": "Torche", "water_absorb": "Absorb Eau",
	"volt_absorb": "Absorb Volt", "lightning_rod": "Paratonnerre", "storm_drain": "Lavabo",
	"motor_drive": "Motorise", "sap_sipper": "Herbivore", "dry_skin": "Peau Seche",
	"thick_fat": "Isograisse", "heatproof": "Ignifuge",
	# Stat boosters
	"huge_power": "Coloforce", "pure_power": "Force Pure", "speed_boost": "Turbo",
	"intimidate": "Intimidation", "guts": "Cran", "marvel_scale": "Ecaille Spe.",
	"hustle": "Agitation", "compound_eyes": "Oeil Compose",
	"adaptability": "Adaptabilite", "technician": "Technicien",
	"skill_link": "Multi-Coups", "sheer_force": "Sans Limite",
	"analytic": "Analyste", "tinted_lens": "Lentiteintee",
	"iron_fist": "Poing de Fer", "strong_jaw": "Machoire Forte",
	"mega_launcher": "Mega Blaster", "reckless": "Temerite",
	"tough_claws": "Griffe Dure", "pixilate": "Peau Feerique",
	"refrigerate": "Peau Gelee", "aerilate": "Peau Celeste",
	"galvanize": "Peau Electrik", "normalize": "Normalise",
	# Weather starters
	"drizzle": "Crachin", "drought": "Secheresse",
	"sand_stream": "Sable Volant", "snow_warning": "Alerte Neige",
	"desolate_land": "Terre Finale", "primordial_sea": "Mer Primaire",
	"delta_stream": "Souffle Delta",
	# Weather speed
	"swift_swim": "Glissade", "chlorophyll": "Chlorophylle",
	"sand_rush": "Baigne Sable", "slush_rush": "Chasse-Neige",
	# Weather abilities
	"sand_force": "Force Sable", "solar_power": "Force Soleil",
	"rain_dish": "Cuvette", "ice_body": "Corps Gel",
	# Status prevention
	"immunity": "Immunite", "limber": "Echauffement",
	"insomnia": "Insomnia", "vital_spirit": "Esprit Vital",
	"magma_armor": "Armure Magma", "water_veil": "Voile Eau",
	"own_tempo": "Tempo Perso", "inner_focus": "Attention",
	"oblivious": "Benet", "leaf_guard": "Feuille Garde",
	"overcoat": "Envelocape", "sweet_veil": "Doux Voile",
	# Stat drop prevention
	"clear_body": "Corps Sain", "white_smoke": "Ecran Fumee",
	"hyper_cutter": "Hyper Cutter", "keen_eye": "Regard Vif",
	"full_metal_body": "Metalprotection", "defiant": "Defaitiste",
	"competitive": "Battant", "contrary": "Esprit Contraire",
	"simple": "Simple",
	# Recovery
	"shed_skin": "Mue", "natural_cure": "Medic Nature",
	"regenerator": "Regeneration", "poison_heal": "Soin Poison",
	# Battle utility
	"sturdy": "Fermete", "pressure": "Pression",
	"trace": "Calque", "synchronize": "Synchro",
	"color_change": "Metamorph", "wonder_guard": "Garde Mystik",
	"soundproof": "Anti-Bruit", "bulletproof": "Pare-Balles",
	"arena_trap": "Piege", "shadow_tag": "Marque Ombre",
	"magnet_pull": "Magnepied",
	"battle_armor": "Armurbaston", "shell_armor": "Coque Armure",
	"mold_breaker": "Brise Moule", "teravolt": "Teravolt", "turboblaze": "Turbobrasier",
	"unaware": "Inconscient", "magic_guard": "Garde Magik",
	"magic_bounce": "Miroir Magik", "prankster": "Farceur",
	"protean": "Protean", "libero": "Libero",
	# Terrain setters
	"electric_surge": "Champ Electrique", "grassy_surge": "Champ Herbu",
	"psychic_surge": "Champ Psychique", "misty_surge": "Champ Brumeux",
	# Gen 7+
	"disguise": "Deguisement", "ice_face": "Tete de Gel",
	"multiscale": "Multiécaille", "shadow_shield": "Bouclier Spectral",
	"fur_coat": "Toison Epaisse", "ice_scales": "Ecailles Glacees",
	"filter": "Filtre", "solid_rock": "Solide Roc",
	"prism_armor": "Prisme-Armure",
	"beast_boost": "Boost Chimere", "soul_heart": "Animacoeur",
	"neuroforce": "Neuroforce", "download": "Telechargement",
	"intrepid_sword": "Epee Indomptable", "dauntless_shield": "Bouclier Inflexible",
	# Gen 8
	"gorilla_tactics": "Politique Gorille", "unseen_fist": "Poing Invisible",
	"punk_rock": "Punk Rock", "steam_engine": "Machine a Vapeur",
	"cotton_down": "Duvet de Coton",
	# Gen 9
	"protosynthesis": "Paleo-Activation", "quark_drive": "Champ Quantique",
	"supreme_overlord": "Suzerain", "orichalcum_pulse": "Pouls du Prisme",
	"hadron_engine": "Moteur Hadron", "wind_rider": "Aero-Surf",
	"guard_dog": "Chien de Garde", "good_as_gold": "Corps en Or",
	"earth_eater": "Geo-Absorption", "wind_power": "Dynamo Eolienne",
	"seed_sower": "Propagation", "thermal_exchange": "Echange Thermique",
	"zero_to_hero": "Metamorphose", "commander": "Commandement",
	"electromorphosis": "Dynamo",
}

## Nom affichable d'un talent.
static func get_ability_name(ability_id: String) -> String:
	# Try loaded data first, fall back to const
	if GameData.abilities_data.has(ability_id):
		return GameData.abilities_data[ability_id].get("name_fr", GameData.abilities_data[ability_id].get("name", ability_id))
	return ABILITY_NAMES.get(ability_id, ability_id)

# =========================================================================
#  HOOKS — called at different battle moments
# =========================================================================

# -- Switch-in ------------------------------------------------------------

static func on_switch_in(pkmn, opponent, field: BattleField) -> Array[String]:
	var msgs: Array[String] = []
	var ab: String = pkmn.ability

	match ab:
		# --- Intimidate ---
		"intimidate":
			if not prevents_stat_drop(opponent, "atk"):
				var actual := opponent.modify_stat_stage("atk", -1)
				if actual != 0:
					msgs.append("%s intimide %s !\nL'Attaque de %s baisse !" % [
						pkmn.get_name(), opponent.get_name(), opponent.get_name()])
			else:
				msgs.append("%s a Intimidation, mais %s est protege !" % [pkmn.get_name(), opponent.get_name()])
			# Defiant / Competitive trigger
			if opponent.ability == "defiant":
				opponent.modify_stat_stage("atk", 2)
				msgs.append("%s : Defaitiste booste son Attaque !" % opponent.get_name())
			elif opponent.ability == "competitive":
				opponent.modify_stat_stage("sp_atk", 2)
				msgs.append("%s : Battant booste son Atq. Spe !" % opponent.get_name())

		# --- Weather setters ---
		"drizzle":
			field.set_weather(BattleField.Weather.RAIN, 999, "drizzle")
			msgs.append("%s invoque la pluie !" % pkmn.get_name())
		"drought":
			field.set_weather(BattleField.Weather.SUN, 999, "drought")
			msgs.append("%s invoque le soleil !" % pkmn.get_name())
		"sand_stream":
			field.set_weather(BattleField.Weather.SANDSTORM, 999, "sand_stream")
			msgs.append("%s declenche une tempete de sable !" % pkmn.get_name())
		"snow_warning":
			field.set_weather(BattleField.Weather.HAIL, 999, "snow_warning")
			msgs.append("%s declenche la grele !" % pkmn.get_name())
		"desolate_land":
			field.set_weather(BattleField.Weather.SUN, 999, "desolate_land")
			msgs.append("Le soleil brule intensement !")
		"primordial_sea":
			field.set_weather(BattleField.Weather.RAIN, 999, "primordial_sea")
			msgs.append("Une pluie torrentielle commence !")

		# --- Terrain setters ---
		"electric_surge":
			msgs.append(field.set_terrain(BattleField.Terrain.ELECTRIC, 5))
		"grassy_surge":
			msgs.append(field.set_terrain(BattleField.Terrain.GRASSY, 5))
		"psychic_surge":
			msgs.append(field.set_terrain(BattleField.Terrain.PSYCHIC, 5))
		"misty_surge":
			msgs.append(field.set_terrain(BattleField.Terrain.MISTY, 5))

		# --- Orichalcum Pulse (Sun + Atk boost) ---
		"orichalcum_pulse":
			field.set_weather(BattleField.Weather.SUN, 999, "orichalcum_pulse")
			msgs.append("Le soleil brille intensement !")
		# --- Hadron Engine (Electric Terrain + SpAtk boost) ---
		"hadron_engine":
			msgs.append(field.set_terrain(BattleField.Terrain.ELECTRIC, 5))

		# --- Trace ---
		"trace":
			if opponent.ability != "" and opponent.ability != "trace":
				var old_ab := opponent.ability
				pkmn.ability = opponent.ability
				msgs.append("%s copie %s de %s !" % [
					pkmn.get_name(), get_ability_name(old_ab), opponent.get_name()])

		# --- Download ---
		"download":
			var def_val := opponent.get_effective_stat("def")
			var spdef_val := opponent.get_effective_stat("sp_def")
			if def_val < spdef_val:
				pkmn.modify_stat_stage("atk", 1)
				msgs.append("%s : Telechargement booste son Attaque !" % pkmn.get_name())
			else:
				pkmn.modify_stat_stage("sp_atk", 1)
				msgs.append("%s : Telechargement booste son Atq. Spe !" % pkmn.get_name())

		# --- Intrepid Sword / Dauntless Shield ---
		"intrepid_sword":
			pkmn.modify_stat_stage("atk", 1)
			msgs.append("%s : Epee Indomptable booste son Attaque !" % pkmn.get_name())
		"dauntless_shield":
			pkmn.modify_stat_stage("def", 1)
			msgs.append("%s : Bouclier Inflexible booste sa Defense !" % pkmn.get_name())

		# --- Pressure ---
		"pressure":
			msgs.append("%s exerce une pression !" % pkmn.get_name())

		# --- Mold Breaker / Teravolt / Turboblaze ---
		"mold_breaker":
			msgs.append("%s brise le moule !" % pkmn.get_name())
		"teravolt":
			msgs.append("%s irradie de Teravolt !" % pkmn.get_name())
		"turboblaze":
			msgs.append("%s irradie de Turbobrasier !" % pkmn.get_name())

		# --- Protosynthesis (Gen 9) ---
		"protosynthesis":
			if field.weather == BattleField.Weather.SUN:
				msgs.append("%s : son talent s'active au soleil !" % pkmn.get_name())

		# --- Quark Drive (Gen 9) ---
		"quark_drive":
			if field.terrain == BattleField.Terrain.ELECTRIC:
				msgs.append("%s : son talent s'active sur le terrain !" % pkmn.get_name())

		# --- Seed Sower (Gen 9) ---
		"seed_sower":
			pass  # Triggers on being hit

		# --- Disguise (Mimikyu) ---
		"disguise":
			if not pkmn.has_meta("disguise_broken"):
				pkmn.set_meta("disguise_active", true)

		# --- Ice Face ---
		"ice_face":
			if not pkmn.has_meta("ice_face_broken"):
				pkmn.set_meta("ice_face_active", true)

		# --- Guard Dog ---
		"guard_dog":
			pass  # Prevents Intimidate and forced switches

	return msgs

# -- Switch-out -----------------------------------------------------------

static func on_switch_out(pkmn) -> void:
	match pkmn.ability:
		"natural_cure":
			pkmn.status = ""
			pkmn.status_turns = 0
		"regenerator":
			pkmn.heal(int(pkmn.max_hp / 3.0))

# -- Before hit (immunity / absorption) -----------------------------------

static func on_before_hit(
	defender, attacker, move_type: String, move_category: String,
	field: BattleField
) -> Dictionary:
	var ab: String = defender.ability
	var result := {"blocked": false, "message": "", "heal": 0}

	# Mold Breaker family ignores defensive abilities
	if attacker.ability in ["mold_breaker", "teravolt", "turboblaze"]:
		# Only bypasses specific defensive abilities
		if ab in ["levitate", "flash_fire", "water_absorb", "volt_absorb",
				  "lightning_rod", "storm_drain", "motor_drive", "sap_sipper",
				  "dry_skin", "wonder_guard", "soundproof", "bulletproof",
				  "thick_fat", "heatproof", "multiscale", "shadow_shield",
				  "fur_coat", "ice_scales", "filter", "solid_rock", "prism_armor",
				  "disguise", "ice_face"]:
			return result

	match ab:
		"levitate":
			if move_type == "Ground":
				result.blocked = true
				result.message = "%s evite l'attaque grace a Levitation !" % defender.get_name()

		"flash_fire":
			if move_type == "Fire":
				result.blocked = true
				defender.set_meta("flash_fire_boost", true)
				result.message = "%s absorbe l'attaque Feu !\nSes attaques Feu sont boostees !" % defender.get_name()

		"water_absorb":
			if move_type == "Water":
				result.blocked = true
				result.heal = int(defender.max_hp / 4.0)
				result.message = "%s absorbe l'attaque Eau et regagne des PV !" % defender.get_name()

		"volt_absorb":
			if move_type == "Electric":
				result.blocked = true
				result.heal = int(defender.max_hp / 4.0)
				result.message = "%s absorbe l'attaque Electrik et regagne des PV !" % defender.get_name()

		"lightning_rod":
			if move_type == "Electric":
				result.blocked = true
				defender.modify_stat_stage("sp_atk", 1)
				result.message = "%s attire l'electricite !\nSon Atq. Spe. monte !" % defender.get_name()

		"storm_drain":
			if move_type == "Water":
				result.blocked = true
				defender.modify_stat_stage("sp_atk", 1)
				result.message = "%s attire l'eau !\nSon Atq. Spe. monte !" % defender.get_name()

		"motor_drive":
			if move_type == "Electric":
				result.blocked = true
				defender.modify_stat_stage("speed", 1)
				result.message = "%s absorbe l'electricite !\nSa Vitesse monte !" % defender.get_name()

		"sap_sipper":
			if move_type == "Grass":
				result.blocked = true
				defender.modify_stat_stage("atk", 1)
				result.message = "%s absorbe l'attaque Plante !\nSon Attaque monte !" % defender.get_name()

		"dry_skin":
			if move_type == "Water":
				result.blocked = true
				result.heal = int(defender.max_hp / 4.0)
				result.message = "%s absorbe l'eau et regagne des PV !" % defender.get_name()

		"earth_eater":
			if move_type == "Ground":
				result.blocked = true
				result.heal = int(defender.max_hp / 4.0)
				result.message = "%s absorbe l'attaque Sol !" % defender.get_name()

		"wonder_guard":
			var eff := GameData.get_total_effectiveness(move_type, defender.get_types())
			if eff <= 1.0:
				result.blocked = true
				result.message = "Garde Mystik protege %s !" % defender.get_name()

		"soundproof":
			if MoveEffects.is_sound_move(attacker.get_meta("current_move_id", "")):
				result.blocked = true
				result.message = "%s est protege par Anti-Bruit !" % defender.get_name()

		"bulletproof":
			if MoveEffects.is_bullet_move(attacker.get_meta("current_move_id", "")):
				result.blocked = true
				result.message = "%s est protege par Pare-Balles !" % defender.get_name()

		"good_as_gold":
			if move_category == "status":
				result.blocked = true
				result.message = "%s est protege par Corps en Or !" % defender.get_name()

		"wind_rider":
			if MoveEffects.is_wind_move(attacker.get_meta("current_move_id", "")):
				result.blocked = true
				defender.modify_stat_stage("atk", 1)
				result.message = "%s absorbe le vent !\nSon Attaque monte !" % defender.get_name()

		# Disguise (Mimikyu) — first hit blocked
		"disguise":
			if defender.has_meta("disguise_active") and move_category != "status":
				result.blocked = true
				defender.remove_meta("disguise_active")
				defender.set_meta("disguise_broken", true)
				var dmg := maxi(1, int(defender.max_hp / 8.0))
				defender.take_damage(dmg)
				result.message = "%s : le Deguisement absorbe l'attaque !" % defender.get_name()

		# Ice Face — blocks first physical hit
		"ice_face":
			if defender.has_meta("ice_face_active") and move_category == "physical":
				result.blocked = true
				defender.remove_meta("ice_face_active")
				defender.set_meta("ice_face_broken", true)
				result.message = "%s : Tete de Gel absorbe l'attaque !" % defender.get_name()

	return result

# -- Damage multiplier ---------------------------------------------------

static func get_damage_multiplier(
	attacker, defender, move_type: String, move_category: String,
	field: BattleField
) -> float:
	var mult := 1.0
	var a_ab: String = attacker.ability
	var d_ab: String = defender.ability
	var move_id: String = attacker.get_meta("current_move_id", "")

	# === ATTACKER ABILITIES ===

	# Overgrow/Blaze/Torrent/Swarm — 1.5x when HP < 1/3
	var low_hp := attacker.current_hp <= int(attacker.max_hp / 3.0)
	match a_ab:
		"overgrow":  if low_hp and move_type == "Grass": mult *= 1.5
		"blaze":     if low_hp and move_type == "Fire":  mult *= 1.5
		"torrent":   if low_hp and move_type == "Water": mult *= 1.5
		"swarm":     if low_hp and move_type == "Bug":   mult *= 1.5

	# Flash Fire boost
	if a_ab == "flash_fire" and move_type == "Fire" and attacker.has_meta("flash_fire_boost"):
		mult *= 1.5

	# Guts
	if a_ab == "guts" and attacker.status != "" and move_category == "physical":
		mult *= 1.5

	# Adaptability — STAB becomes 2x instead of 1.5x
	if a_ab == "adaptability" and move_type in attacker.get_types():
		mult *= (2.0 / 1.5)  # Adjusts STAB from 1.5 to 2.0

	# Technician — moves with base power <= 60 get 1.5x
	if a_ab == "technician":
		var mdata := GameData.moves_data.get(move_id, {})
		if mdata.get("power", 0) > 0 and mdata.get("power", 0) <= 60:
			mult *= 1.5

	# Skill Link — handled in BattleCalc (forces max hits)

	# Sheer Force — 1.3x but removes secondary effects
	if a_ab == "sheer_force":
		var mdata := GameData.moves_data.get(move_id, {})
		var eff_chance: int = mdata.get("effect_chance", 0)
		if eff_chance > 0 and eff_chance < 100:
			mult *= 1.3

	# Iron Fist — punch moves get 1.2x
	if a_ab == "iron_fist" and MoveEffects.is_punch_move(move_id):
		mult *= 1.2

	# Strong Jaw — bite moves get 1.5x
	if a_ab == "strong_jaw" and MoveEffects.is_bite_move(move_id):
		mult *= 1.5

	# Mega Launcher — pulse/aura moves get 1.5x
	if a_ab == "mega_launcher" and MoveEffects.is_pulse_move(move_id):
		mult *= 1.5

	# Reckless — recoil moves get 1.2x
	if a_ab == "reckless" and MoveEffects.has_move_flag(move_id, "recoil"):
		mult *= 1.2

	# Tough Claws — contact moves get 1.3x
	if a_ab == "tough_claws" and MoveEffects.is_contact_move(move_id):
		mult *= 1.3

	# Punk Rock — sound moves get 1.3x
	if a_ab == "punk_rock" and MoveEffects.is_sound_move(move_id):
		mult *= 1.3

	# Tinted Lens — not very effective moves become 2x
	if a_ab == "tinted_lens":
		var eff := GameData.get_total_effectiveness(move_type, defender.get_types())
		if eff < 1.0:
			mult *= 2.0

	# Neuroforce — super effective moves get 1.25x
	if a_ab == "neuroforce":
		var eff := GameData.get_total_effectiveness(move_type, defender.get_types())
		if eff > 1.0:
			mult *= 1.25

	# Analytic — 1.3x if moving last
	if a_ab == "analytic" and attacker.has_meta("moved_last"):
		mult *= 1.3

	# Sand Force — 1.3x to Rock/Ground/Steel in Sandstorm
	if a_ab == "sand_force" and field.weather == BattleField.Weather.SANDSTORM:
		if move_type in ["Rock", "Ground", "Steel"]:
			mult *= 1.3

	# Solar Power — 1.5x SpAtk in Sun (physical handled in stat calc)
	if a_ab == "solar_power" and field.weather == BattleField.Weather.SUN and move_category == "special":
		mult *= 1.5

	# Protosynthesis / Quark Drive — 1.3x to highest stat
	if a_ab == "protosynthesis" and field.weather == BattleField.Weather.SUN:
		mult *= 1.3
	if a_ab == "quark_drive" and field.terrain == BattleField.Terrain.ELECTRIC:
		mult *= 1.3

	# Supreme Overlord — boost based on fainted allies
	if a_ab == "supreme_overlord":
		var fainted_count := 0
		for p in GameState.team:
			if p.is_fainted():
				fainted_count += 1
		mult *= 1.0 + 0.1 * fainted_count

	# Gorilla Tactics — 1.5x physical
	if a_ab == "gorilla_tactics" and move_category == "physical":
		mult *= 1.5

	# -ate abilities (Pixilate, Refrigerate, Aerilate, Galvanize)
	if a_ab in ["pixilate", "refrigerate", "aerilate", "galvanize"]:
		mult *= 1.2  # Normal moves become typed + 1.2x boost

	# === DEFENDER ABILITIES ===

	if d_ab == "thick_fat":
		if move_type in ["Fire", "Ice"]: mult *= 0.5

	if d_ab == "heatproof":
		if move_type == "Fire": mult *= 0.5

	if d_ab == "dry_skin":
		if move_type == "Fire": mult *= 1.25

	# Multiscale / Shadow Shield — halve damage at full HP
	if d_ab in ["multiscale", "shadow_shield"]:
		if defender.current_hp == defender.max_hp:
			mult *= 0.5

	# Fur Coat — halve physical damage
	if d_ab == "fur_coat" and move_category == "physical":
		mult *= 0.5

	# Ice Scales — halve special damage
	if d_ab == "ice_scales" and move_category == "special":
		mult *= 0.5

	# Filter / Solid Rock / Prism Armor — reduce super effective by 25%
	if d_ab in ["filter", "solid_rock", "prism_armor"]:
		var eff := GameData.get_total_effectiveness(move_type, defender.get_types())
		if eff > 1.0:
			mult *= 0.75

	# Punk Rock — reduces sound damage taken by 50%
	if d_ab == "punk_rock" and MoveEffects.is_sound_move(move_id):
		mult *= 0.5

	# Fluffy — halves contact damage, doubles Fire damage
	if d_ab == "fluffy":
		if MoveEffects.is_contact_move(move_id):
			mult *= 0.5
		if move_type == "Fire":
			mult *= 2.0

	# Thermal Exchange — immune to burn, Attack boost from Fire
	if d_ab == "thermal_exchange" and move_type == "Fire":
		defender.modify_stat_stage("atk", 1)

	# === TERRAIN BOOST ===
	if field != null:
		mult *= field.get_terrain_boost(move_type)

	return mult

# -- After contact --------------------------------------------------------

static func on_after_contact(attacker, defender) -> String:
	if attacker.is_fainted():
		return ""
	var d_ab: String = defender.ability

	# Unseen Fist bypasses protect, handled in TurnManager

	match d_ab:
		"static":
			if randf() < 0.30 and attacker.status == "":
				var types := attacker.get_types()
				if "Electric" not in types:
					attacker.status = "paralyze"
					return "Statik de %s paralyse %s !" % [defender.get_name(), attacker.get_name()]

		"poison_point":
			if randf() < 0.30 and attacker.status == "":
				var types := attacker.get_types()
				if "Poison" not in types and "Steel" not in types:
					attacker.status = "poison"
					return "Point Poison de %s empoisonne %s !" % [defender.get_name(), attacker.get_name()]

		"flame_body":
			if randf() < 0.30 and attacker.status == "":
				var types := attacker.get_types()
				if "Fire" not in types:
					attacker.status = "burn"
					return "Corps Ardent de %s brule %s !" % [defender.get_name(), attacker.get_name()]

		"rough_skin", "iron_barbs":
			var dmg := maxi(1, int(attacker.max_hp / 8.0))
			attacker.take_damage(dmg)
			return "%s de %s blesse %s !" % [get_ability_name(d_ab), defender.get_name(), attacker.get_name()]

		"effect_spore":
			if randf() < 0.30 and attacker.status == "":
				var types := attacker.get_types()
				if "Grass" not in types:
					var roll := randf()
					if roll < 0.33:
						attacker.status = "sleep"
						attacker.status_turns = randi_range(1, 3)
						return "Effet Spore endort %s !" % attacker.get_name()
					elif roll < 0.66:
						attacker.status = "paralyze"
						return "Effet Spore paralyse %s !" % attacker.get_name()
					else:
						attacker.status = "poison"
						return "Effet Spore empoisonne %s !" % attacker.get_name()

		"gooey", "tangling_hair":
			attacker.modify_stat_stage("speed", -1)
			return "%s de %s ralentit %s !" % [get_ability_name(d_ab), defender.get_name(), attacker.get_name()]

		"cotton_down":
			attacker.modify_stat_stage("speed", -1)
			return "Duvet de Coton de %s ralentit %s !" % [defender.get_name(), attacker.get_name()]

		"wandering_spirit":
			var temp := attacker.ability
			attacker.ability = defender.ability
			defender.ability = temp
			return "%s et %s echangent leurs talents !" % [defender.get_name(), attacker.get_name()]

		"cute_charm":
			if randf() < 0.30:
				if not attacker.has_meta("attracted"):
					attacker.set_meta("attracted", true)
					return "Joli Sourire de %s seduit %s !" % [defender.get_name(), attacker.get_name()]

		"seed_sower":
			if field != null:
				return field.set_terrain(BattleField.Terrain.GRASSY, 5)

		"electromorphosis":
			defender.set_meta("charge_boost", true)
			return "%s se charge d'electricite !" % defender.get_name()

		"wind_power":
			if MoveEffects.is_wind_move(attacker.get_meta("current_move_id", "")):
				defender.set_meta("charge_boost", true)
				return "%s se charge grace au vent !" % defender.get_name()

		"steam_engine":
			if attacker.get_meta("current_move_type", "") in ["Fire", "Water"]:
				defender.modify_stat_stage("speed", 6)
				return "%s : Machine a Vapeur maximise sa Vitesse !" % defender.get_name()

	return ""

# -- End of turn ----------------------------------------------------------

static func on_end_of_turn(pkmn, field: BattleField) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	var ab: String = pkmn.ability

	if pkmn.is_fainted():
		return effects

	match ab:
		"speed_boost":
			var actual := pkmn.modify_stat_stage("speed", 1)
			if actual != 0:
				effects.append({"message": "%s : Turbo booste sa Vitesse !" % pkmn.get_name()})

		"shed_skin":
			if pkmn.status != "" and randf() < 0.33:
				pkmn.status = ""
				pkmn.status_turns = 0
				effects.append({"message": "%s mue et soigne son statut !" % pkmn.get_name()})

		"poison_heal":
			if pkmn.status in ["poison", "bad_poison"]:
				var heal_amt := int(pkmn.max_hp / 8.0)
				pkmn.heal(heal_amt)
				effects.append({"message": "%s regagne des PV grace a Soin Poison !" % pkmn.get_name()})
				effects.append({"skip_status_damage": true})

		"rain_dish":
			if field.weather == BattleField.Weather.RAIN:
				var heal_amt := int(pkmn.max_hp / 16.0)
				pkmn.heal(heal_amt)
				effects.append({"message": "%s regagne des PV sous la pluie !" % pkmn.get_name()})

		"ice_body":
			if field.weather == BattleField.Weather.HAIL:
				var heal_amt := int(pkmn.max_hp / 16.0)
				pkmn.heal(heal_amt)
				effects.append({"message": "%s regagne des PV sous la grele !" % pkmn.get_name()})

		"dry_skin":
			if field.weather == BattleField.Weather.RAIN:
				var heal_amt := int(pkmn.max_hp / 8.0)
				pkmn.heal(heal_amt)
				effects.append({"message": "%s regagne des PV sous la pluie !" % pkmn.get_name()})
			elif field.weather == BattleField.Weather.SUN:
				var dmg := int(pkmn.max_hp / 8.0)
				pkmn.take_damage(dmg)
				effects.append({"message": "%s perd des PV sous le soleil !" % pkmn.get_name()})

		"solar_power":
			if field.weather == BattleField.Weather.SUN:
				var dmg := int(pkmn.max_hp / 8.0)
				pkmn.take_damage(dmg)
				effects.append({"message": "%s perd des PV a cause de Force Soleil !" % pkmn.get_name()})

		"magic_guard":
			# Prevents all indirect damage — mark to skip status/weather damage
			effects.append({"skip_status_damage": true})

		"moody":
			# Raise random stat +2, lower random stat -1
			var stats := ["atk", "def", "sp_atk", "sp_def", "speed"]
			var raise_stat: String = stats[randi() % stats.size()]
			pkmn.modify_stat_stage(raise_stat, 2)
			var lower_stat: String = stats[randi() % stats.size()]
			while lower_stat == raise_stat:
				lower_stat = stats[randi() % stats.size()]
			pkmn.modify_stat_stage(lower_stat, -1)
			effects.append({"message": "%s : Lunatique modifie ses stats !" % pkmn.get_name()})

		"bad_dreams":
			# Damages sleeping opponent — handled externally
			pass

		"harvest":
			if pkmn.has_meta("consumed_item"):
				var consumed: String = pkmn.get_meta("consumed_item")
				if consumed.ends_with("_berry"):
					var trigger := randf() < 0.5
					if field.weather == BattleField.Weather.SUN:
						trigger = true
					if trigger:
						pkmn.held_item = consumed
						pkmn.remove_meta("consumed_item")
						effects.append({"message": "%s recupere sa baie !" % pkmn.get_name()})

		# Ice Face regeneration in hail
		"ice_face":
			if pkmn.has_meta("ice_face_broken") and field.weather == BattleField.Weather.HAIL:
				pkmn.remove_meta("ice_face_broken")
				pkmn.set_meta("ice_face_active", true)
				effects.append({"message": "%s : Tete de Gel se reforme !" % pkmn.get_name()})

	return effects

# -- Status prevention ----------------------------------------------------

static func prevents_status(pkmn, status: String) -> bool:
	var ab: String = pkmn.ability
	match ab:
		"immunity":
			if status in ["poison", "bad_poison"]: return true
		"limber":
			if status == "paralyze": return true
		"insomnia", "vital_spirit":
			if status == "sleep": return true
		"magma_armor":
			if status == "freeze": return true
		"water_veil":
			if status == "burn": return true
		"own_tempo":
			if status == "confuse": return true
		"inner_focus":
			if status == "flinch": return true
		"oblivious":
			if status in ["attract", "confuse", "flinch"]: return true
		"leaf_guard":
			# Prevents status in Sun
			if pkmn.has_meta("_field_ref"):
				pass  # Would need field reference
			return false
		"overcoat":
			if status in ["sleep", "poison"]: return true  # Prevents powder moves
		"sweet_veil":
			if status == "sleep": return true
		"comatose":
			return true  # Prevents all status (always asleep mechanically)
		"shields_down":
			if pkmn.current_hp > int(pkmn.max_hp / 2.0): return true
		"thermal_exchange":
			if status == "burn": return true
		"good_as_gold":
			return true  # Status moves don't work on it
	return false

# -- Stat drop prevention ------------------------------------------------

static func prevents_stat_drop(pkmn, stat: String) -> bool:
	var ab: String = pkmn.ability
	match ab:
		"clear_body", "white_smoke", "full_metal_body":
			return true
		"hyper_cutter":
			if stat == "atk": return true
		"keen_eye":
			if stat == "accuracy": return true
		"big_pecks":
			if stat == "def": return true
		"guard_dog":
			return true  # Prevents Intimidate
	return false

# -- Stat change modification (Contrary, Simple, Defiant, Competitive) ----

static func modify_stat_change(pkmn, stat: String, delta: int) -> int:
	var ab: String = pkmn.ability
	match ab:
		"contrary":
			return -delta
		"simple":
			return delta * 2
	return delta

# -- After stat is lowered (Defiant, Competitive) -------------------------

static func on_stat_lowered(pkmn, stat: String) -> String:
	var ab: String = pkmn.ability
	match ab:
		"defiant":
			pkmn.modify_stat_stage("atk", 2)
			return "%s : Defaitiste booste son Attaque !" % pkmn.get_name()
		"competitive":
			pkmn.modify_stat_stage("sp_atk", 2)
			return "%s : Battant booste son Atq. Spe !" % pkmn.get_name()
	return ""

# -- Critical hit prevention ----------------------------------------------

static func prevents_critical(defender) -> bool:
	return defender.ability in ["battle_armor", "shell_armor"]

# -- Sturdy ----------------------------------------------------------------

static func check_sturdy(defender, damage: int) -> bool:
	if defender.ability != "sturdy":
		return false
	return defender.current_hp == defender.max_hp and damage >= defender.current_hp

# -- Synchronize -----------------------------------------------------------

static func check_synchronize(pkmn, opponent, status: String) -> String:
	if pkmn.ability != "synchronize":
		return ""
	if status not in ["burn", "paralyze", "poison"]:
		return ""
	if opponent.status != "":
		return ""
	var types := opponent.get_types()
	match status:
		"burn":     if "Fire" in types: return ""
		"paralyze": if "Electric" in types: return ""
		"poison":   if "Poison" in types or "Steel" in types: return ""
	opponent.status = status
	return "Synchro de %s inflige le meme statut a %s !" % [pkmn.get_name(), opponent.get_name()]

# -- Color Change ----------------------------------------------------------

static func check_color_change(defender, move_type: String) -> String:
	if defender.ability != "color_change":
		return ""
	if defender.is_fainted():
		return ""
	var current_types := defender.get_types()
	if current_types.size() == 1 and current_types[0] == move_type:
		return ""
	defender.set_meta("override_types", [move_type])
	return "%s change de type en %s !" % [defender.get_name(), move_type]

# -- Speed multiplier ------------------------------------------------------

static func get_speed_multiplier(pkmn, field: BattleField) -> float:
	var ab: String = pkmn.ability
	match ab:
		"swift_swim":
			if field.weather == BattleField.Weather.RAIN: return 2.0
		"chlorophyll":
			if field.weather == BattleField.Weather.SUN: return 2.0
		"sand_rush":
			if field.weather == BattleField.Weather.SANDSTORM: return 2.0
		"slush_rush":
			if field.weather == BattleField.Weather.HAIL: return 2.0
		"unburden":
			if pkmn.has_meta("consumed_item"): return 2.0
		"quick_feet":
			if pkmn.status != "": return 1.5
		"surge_surfer":
			if field.terrain == BattleField.Terrain.ELECTRIC: return 2.0
	return 1.0

# -- Prevents fleeing ------------------------------------------------------

static func prevents_flee(enemy) -> bool:
	return enemy.ability in ["arena_trap", "shadow_tag", "magnet_pull"]

# -- Weather damage immunity -----------------------------------------------

static func is_immune_to_weather_damage(pkmn, weather: BattleField.Weather) -> bool:
	var ab: String = pkmn.ability
	if ab == "magic_guard":
		return true
	match weather:
		BattleField.Weather.SANDSTORM:
			if ab in ["sand_rush", "sand_force", "overcoat"]: return true
		BattleField.Weather.HAIL:
			if ab in ["slush_rush", "ice_body", "overcoat"]: return true
	return false

# -- Pressure --------------------------------------------------------------

static func check_pressure(defender) -> bool:
	return defender.ability == "pressure"

# -- Move type modification (-ate abilities, Protean/Libero) ---------------

static func get_modified_move_type(attacker, move_type: String, move_id: String) -> String:
	var ab: String = attacker.ability
	if move_type == "Normal":
		match ab:
			"pixilate":    return "Fairy"
			"refrigerate": return "Ice"
			"aerilate":    return "Flying"
			"galvanize":   return "Electric"
			"normalize":   return "Normal"  # Already Normal

	# Protean / Libero — change type before attacking
	if ab in ["protean", "libero"]:
		if not attacker.has_meta("protean_used"):
			attacker.set_meta("override_types", [move_type])
			attacker.set_meta("protean_used", true)

	return move_type

# -- Sheer Force check (suppresses secondary effects) ---------------------

static func suppresses_secondary_effects(attacker) -> bool:
	return attacker.ability == "sheer_force"

# -- Unaware (ignore stat changes) ----------------------------------------

static func ignores_stat_changes(pkmn) -> bool:
	return pkmn.ability == "unaware"

# -- Magic Bounce (reflects status moves) ----------------------------------

static func has_magic_bounce(defender) -> bool:
	return defender.ability == "magic_bounce"

# -- Prankster (priority +1 for status moves) -----------------------------

static func get_priority_modifier(attacker, move_category: String) -> int:
	if attacker.ability == "prankster" and move_category == "status":
		return 1
	if attacker.ability == "gale_wings":
		# Gen 7+: only at full HP
		if attacker.current_hp == attacker.max_hp:
			var move_type: String = attacker.get_meta("current_move_type", "")
			if move_type == "Flying":
				return 1
	return 0

# -- Beast Boost / Soul Heart / Moxie (on KO) -----------------------------

static func on_faint_opponent(attacker) -> String:
	var ab: String = attacker.ability
	match ab:
		"moxie":
			attacker.modify_stat_stage("atk", 1)
			return "%s : Impudence booste son Attaque !" % attacker.get_name()
		"beast_boost":
			# Raise highest stat
			var best_stat := "atk"
			var best_val := 0
			for s in ["atk", "def", "sp_atk", "sp_def", "speed"]:
				if attacker.stats[s] > best_val:
					best_val = attacker.stats[s]
					best_stat = s
			attacker.modify_stat_stage(best_stat, 1)
			return "%s : Boost Chimere augmente ses stats !" % attacker.get_name()
		"soul_heart":
			attacker.modify_stat_stage("sp_atk", 1)
			return "%s : Animacoeur booste son Atq. Spe !" % attacker.get_name()
		"chilling_neigh":
			attacker.modify_stat_stage("atk", 1)
			return "%s : son talent booste son Attaque !" % attacker.get_name()
		"grim_neigh":
			attacker.modify_stat_stage("sp_atk", 1)
			return "%s : son talent booste son Atq. Spe !" % attacker.get_name()
		"as_one_glastrier", "as_one_spectrier":
			attacker.modify_stat_stage("atk" if "glastrier" in ab else "sp_atk", 1)
			return "%s : son talent booste ses stats !" % attacker.get_name()
	return ""
