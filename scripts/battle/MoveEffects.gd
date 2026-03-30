class_name MoveEffects
## Effets secondaires des moves et gestion des statuts.
## Couvre Gen 1 a Gen 9. Toutes les fonctions sont statiques.

const AbilityEffects = preload("res://scripts/battle/AbilityEffects.gd")
const HeldItemEffects = preload("res://scripts/battle/HeldItemEffects.gd")
const BattleField = preload("res://scripts/battle/BattleField.gd")
const BattleCalc = preload("res://scripts/battle/BattleCalc.gd")
const MoveInstance = preload("res://scripts/data/MoveInstance.gd")
const PokemonInstance = preload("res://scripts/data/PokemonInstance.gd")
# -- Infos statut ---------------------------------------------------------
const STATUS_ABBR := {
	"burn":      "BRU", "paralyze":  "PAR", "sleep":     "SOM",
	"freeze":    "GEL", "poison":    "PSN", "bad_poison":"PSN",
}
const STATUS_COLOR := {
	"burn":       Color(0.90, 0.30, 0.10), "paralyze":   Color(0.90, 0.80, 0.10),
	"sleep":      Color(0.40, 0.40, 0.60), "freeze":     Color(0.45, 0.75, 0.90),
	"poison":     Color(0.60, 0.20, 0.70), "bad_poison": Color(0.45, 0.08, 0.55),
}

# -- Move flag checks (flags-based, reads from move data) -----------------

static func is_contact_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "contact" in flags

static func is_sound_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "sound" in flags

static func is_punch_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "punch" in flags

static func is_bite_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "bite" in flags

static func is_bullet_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "bullet" in flags

static func is_pulse_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "pulse" in flags

static func is_slice_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "slice" in flags

static func is_wind_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "wind" in flags

static func is_powder_move(move_id: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return "powder" in flags

static func has_move_flag(move_id: String, flag: String) -> bool:
	var mdata: Dictionary = GameData.moves_data.get(move_id, {})
	var flags: Array = mdata.get("flags", [])
	return flag in flags

# =========================================================================
#  Application de l'effet secondaire d'un move
# =========================================================================

static func apply_move_effect(
	move: MoveInstance,
	attacker: PokemonInstance,
	defender: PokemonInstance,
	damage_dealt: int = 0,
	field: BattleField = null
) -> Array[String]:
	var effect: String = move.get_effect()
	if effect == "":
		return []
	var chance: int = move.get_effect_chance()
	if chance < 100 and randf() * 100.0 > chance:
		return []

	var msgs: Array[String] = []

	match effect:
		# =============================================================
		#  STATUS CONDITIONS
		# =============================================================
		"burn":            msgs.append_array(_try_status(defender, "burn", attacker))
		"paralyze":        msgs.append_array(_try_status(defender, "paralyze", attacker))
		"poison":          msgs.append_array(_try_status(defender, "poison", attacker))
		"bad_poison":      msgs.append_array(_try_status(defender, "bad_poison", attacker))
		"sleep":           msgs.append_array(_try_status(defender, "sleep", attacker))
		"freeze":          msgs.append_array(_try_status(defender, "freeze", attacker))

		# Tri Attack (equal chance burn/freeze/paralyze)
		"tri_attack":
			var roll := randf()
			if roll < 0.33:
				msgs.append_array(_try_status(defender, "paralyze", attacker))
			elif roll < 0.66:
				msgs.append_array(_try_status(defender, "burn", attacker))
			else:
				msgs.append_array(_try_status(defender, "freeze", attacker))

		# =============================================================
		#  STAT CHANGES — TARGET (lower)
		# =============================================================
		"lower_target_atk":         msgs.append(_change_stat(defender, "atk",      -1))
		"lower_target_def":         msgs.append(_change_stat(defender, "def",      -1))
		"lower_target_spatk":       msgs.append(_change_stat(defender, "sp_atk",   -1))
		"lower_target_spdef":       msgs.append(_change_stat(defender, "sp_def",   -1))
		"lower_target_speed":       msgs.append(_change_stat(defender, "speed",    -1))
		"lower_target_accuracy":    msgs.append(_change_stat(defender, "accuracy", -1))
		"lower_target_evasion":     msgs.append(_change_stat(defender, "evasion",  -1))
		"lower_target_atk_2":       msgs.append(_change_stat(defender, "atk",      -2))
		"lower_target_def_2":       msgs.append(_change_stat(defender, "def",      -2))
		"lower_target_spatk_2":     msgs.append(_change_stat(defender, "sp_atk",   -2))
		"lower_target_spdef_2":     msgs.append(_change_stat(defender, "sp_def",   -2))
		"lower_target_speed_2":     msgs.append(_change_stat(defender, "speed",    -2))
		"lower_target_accuracy_2":  msgs.append(_change_stat(defender, "accuracy", -2))
		"lower_target_evasion_2":   msgs.append(_change_stat(defender, "evasion",  -2))

		# Close Combat / Superpower : lower self def + sp_def / atk + def
		"lower_self_def_spdef":
			msgs.append(_change_stat(attacker, "def", -1))
			msgs.append(_change_stat(attacker, "sp_def", -1))
		"lower_self_atk_def":
			msgs.append(_change_stat(attacker, "atk", -1))
			msgs.append(_change_stat(attacker, "def", -1))
		"lower_self_spatk_2":
			msgs.append(_change_stat(attacker, "sp_atk", -2))
		"lower_self_spdef_2":
			msgs.append(_change_stat(attacker, "sp_def", -2))
		"lower_self_speed":
			msgs.append(_change_stat(attacker, "speed", -1))

		# V-Create (lower Def, SpDef, Speed)
		"lower_self_def_spdef_speed":
			msgs.append(_change_stat(attacker, "def", -1))
			msgs.append(_change_stat(attacker, "sp_def", -1))
			msgs.append(_change_stat(attacker, "speed", -1))

		# =============================================================
		#  STAT CHANGES — SELF (raise)
		# =============================================================
		"raise_self_atk":        msgs.append(_change_stat(attacker, "atk",     1))
		"raise_self_def":        msgs.append(_change_stat(attacker, "def",     1))
		"raise_self_spatk":      msgs.append(_change_stat(attacker, "sp_atk",  1))
		"raise_self_spdef":      msgs.append(_change_stat(attacker, "sp_def",  1))
		"raise_self_speed":      msgs.append(_change_stat(attacker, "speed",   1))
		"raise_self_evasion":    msgs.append(_change_stat(attacker, "evasion", 1))
		"raise_self_accuracy":   msgs.append(_change_stat(attacker, "accuracy",1))
		"raise_self_atk_2":      msgs.append(_change_stat(attacker, "atk",     2))
		"raise_self_def_2":      msgs.append(_change_stat(attacker, "def",     2))
		"raise_self_spatk_2":    msgs.append(_change_stat(attacker, "sp_atk",  2))
		"raise_self_spdef_2":    msgs.append(_change_stat(attacker, "sp_def",  2))
		"raise_self_speed_2":    msgs.append(_change_stat(attacker, "speed",   2))
		"raise_self_atk_3":      msgs.append(_change_stat(attacker, "atk",     3))
		"raise_self_spatk_3":    msgs.append(_change_stat(attacker, "sp_atk",  3))

		# =============================================================
		#  COMBO STAT BOOSTS (setup moves)
		# =============================================================
		"bulk_up":  # +1 ATK, +1 DEF
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "def", 1))
		"calm_mind":  # +1 SP_ATK, +1 SP_DEF
			msgs.append(_change_stat(attacker, "sp_atk", 1))
			msgs.append(_change_stat(attacker, "sp_def", 1))
		"dragon_dance":  # +1 ATK, +1 SPEED
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "speed", 1))
		"quiver_dance":  # +1 SP_ATK, +1 SP_DEF, +1 SPEED
			msgs.append(_change_stat(attacker, "sp_atk", 1))
			msgs.append(_change_stat(attacker, "sp_def", 1))
			msgs.append(_change_stat(attacker, "speed", 1))
		"shell_smash":  # +2 ATK, +2 SP_ATK, +2 SPEED, -1 DEF, -1 SP_DEF
			msgs.append(_change_stat(attacker, "atk", 2))
			msgs.append(_change_stat(attacker, "sp_atk", 2))
			msgs.append(_change_stat(attacker, "speed", 2))
			msgs.append(_change_stat(attacker, "def", -1))
			msgs.append(_change_stat(attacker, "sp_def", -1))
		"coil":  # +1 ATK, +1 DEF, +1 ACC
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "def", 1))
			msgs.append(_change_stat(attacker, "accuracy", 1))
		"shift_gear":  # +1 ATK, +2 SPEED
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "speed", 2))
		"cotton_guard":  # +3 DEF
			msgs.append(_change_stat(attacker, "def", 3))
		"autotomize":  # +2 SPEED
			msgs.append(_change_stat(attacker, "speed", 2))
		"geomancy":  # +2 SP_ATK, +2 SP_DEF, +2 SPEED
			msgs.append(_change_stat(attacker, "sp_atk", 2))
			msgs.append(_change_stat(attacker, "sp_def", 2))
			msgs.append(_change_stat(attacker, "speed", 2))
		"work_up":  # +1 ATK, +1 SP_ATK
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "sp_atk", 1))
		"hone_claws":  # +1 ATK, +1 ACC
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "accuracy", 1))
		"iron_defense":  # +2 DEF
			msgs.append(_change_stat(attacker, "def", 2))
		"amnesia":  # +2 SP_DEF
			msgs.append(_change_stat(attacker, "sp_def", 2))
		"rock_polish":  # +2 SPEED
			msgs.append(_change_stat(attacker, "speed", 2))
		"no_retreat":  # +1 all stats, can't switch
			msgs.append(_change_stat(attacker, "atk", 1))
			msgs.append(_change_stat(attacker, "def", 1))
			msgs.append(_change_stat(attacker, "sp_atk", 1))
			msgs.append(_change_stat(attacker, "sp_def", 1))
			msgs.append(_change_stat(attacker, "speed", 1))
			attacker.set_bmeta("no_retreat", true)
		"growth":
			if field != null and field.weather == BattleField.Weather.SUN:
				msgs.append(_change_stat(attacker, "atk", 2))
				msgs.append(_change_stat(attacker, "sp_atk", 2))
			else:
				msgs.append(_change_stat(attacker, "atk", 1))
				msgs.append(_change_stat(attacker, "sp_atk", 1))
		"acupressure":  # +2 random stat
			var stats := ["atk", "def", "sp_atk", "sp_def", "speed", "accuracy", "evasion"]
			var rand_stat: String = stats[randi() % stats.size()]
			msgs.append(_change_stat(attacker, rand_stat, 2))

		# Opponent combo drops
		"tickle":
			msgs.append(_change_stat(defender, "atk", -1))
			msgs.append(_change_stat(defender, "def", -1))
		"charm":
			msgs.append(_change_stat(defender, "atk", -2))
		"feather_dance":
			msgs.append(_change_stat(defender, "atk", -2))
		"screech":
			msgs.append(_change_stat(defender, "def", -2))
		"fake_tears":
			msgs.append(_change_stat(defender, "sp_def", -2))
		"metal_sound":
			msgs.append(_change_stat(defender, "sp_def", -2))
		"scary_face":
			msgs.append(_change_stat(defender, "speed", -2))
		"sweet_scent":
			msgs.append(_change_stat(defender, "evasion", -2))
		"captivate":
			msgs.append(_change_stat(defender, "sp_atk", -2))
		"noble_roar":
			msgs.append(_change_stat(defender, "atk", -1))
			msgs.append(_change_stat(defender, "sp_atk", -1))
		"parting_shot":
			msgs.append(_change_stat(defender, "atk", -1))
			msgs.append(_change_stat(defender, "sp_atk", -1))

		# =============================================================
		#  BELLY DRUM — maximize ATK at 50% HP cost
		# =============================================================
		"belly_drum":
			if attacker.current_hp <= int(attacker.max_hp / 2.0):
				msgs.append("Mais cela echoue !")
			else:
				attacker.take_damage(int(attacker.max_hp / 2.0))
				attacker.stat_stages["atk"] = 6
				msgs.append("%s maximise son Attaque !" % attacker.get_name())

		# Filler Arm (Gen 9) — same as Belly Drum but uses fist
		"fillet_away":
			if attacker.current_hp <= int(attacker.max_hp / 2.0):
				msgs.append("Mais cela echoue !")
			else:
				attacker.take_damage(int(attacker.max_hp / 2.0))
				msgs.append(_change_stat(attacker, "atk", 2))
				msgs.append(_change_stat(attacker, "sp_atk", 2))
				msgs.append(_change_stat(attacker, "speed", 2))

		# =============================================================
		#  CURSE — Ghost vs non-Ghost
		# =============================================================
		"curse":
			if "Ghost" in attacker.get_types():
				var dmg := int(attacker.max_hp / 2.0)
				attacker.take_damage(dmg)
				defender.set_bmeta("cursed", true)
				msgs.append("%s se maudit pour maudire %s !" % [attacker.get_name(), defender.get_name()])
			else:
				msgs.append(_change_stat(attacker, "atk", 1))
				msgs.append(_change_stat(attacker, "def", 1))
				msgs.append(_change_stat(attacker, "speed", -1))

		# =============================================================
		#  FLINCH
		# =============================================================
		"flinch":
			if not AbilityEffects.prevents_status(defender, "flinch"):
				defender.set_bmeta("flinch", true)

		# High crit — handled in BattleCalc
		"high_crit":
			pass

		# =============================================================
		#  CONFUSION
		# =============================================================
		"confuse":
			if AbilityEffects.prevents_status(defender, "confuse"):
				msgs.append("%s est protege par %s !" % [defender.get_name(), defender.get_ability_name()])
			elif defender.has_bmeta("confused"):
				msgs.append("%s est deja confus !" % defender.get_name())
			else:
				defender.set_bmeta("confused", randi_range(2, 5))
				msgs.append("%s est confus !" % defender.get_name())

		"confuse_self":  # Outrage, Petal Dance, Thrash
			if not attacker.has_bmeta("confused"):
				attacker.set_bmeta("confused", randi_range(2, 3))
				msgs.append("%s est confus par la fatigue !" % attacker.get_name())

		# Flatter / Swagger
		"swagger":
			msgs.append(_change_stat(defender, "atk", 2))
			if not defender.has_bmeta("confused"):
				defender.set_bmeta("confused", randi_range(2, 5))
				msgs.append("%s est confus !" % defender.get_name())
		"flatter":
			msgs.append(_change_stat(defender, "sp_atk", 1))
			if not defender.has_bmeta("confused"):
				defender.set_bmeta("confused", randi_range(2, 5))
				msgs.append("%s est confus !" % defender.get_name())

		# =============================================================
		#  HEALING
		# =============================================================
		"heal_half":
			var heal_amt := int(attacker.max_hp / 2.0)
			var actual := attacker.heal(heal_amt)
			if actual == 0:
				msgs.append("%s a deja tous ses PV !" % attacker.get_name())
			else:
				msgs.append("%s recupere des PV !" % attacker.get_name())

		"heal_two_thirds":
			var heal_amt := int(attacker.max_hp * 2.0 / 3.0)
			var actual := attacker.heal(heal_amt)
			if actual == 0:
				msgs.append("%s a deja tous ses PV !" % attacker.get_name())
			else:
				msgs.append("%s recupere des PV !" % attacker.get_name())

		"rest":
			if attacker.current_hp == attacker.max_hp:
				msgs.append("Mais cela echoue !")
			else:
				attacker.heal(attacker.max_hp)
				attacker.status = "sleep"
				attacker.status_turns = 2
				msgs.append("%s se repose et recupere tous ses PV !" % attacker.get_name())

		# Shore Up (heal more in sand)
		"shore_up":
			var ratio := 0.5
			if field != null and field.weather == BattleField.Weather.SANDSTORM:
				ratio = 2.0 / 3.0
			var actual := attacker.heal(int(attacker.max_hp * ratio))
			msgs.append("%s recupere des PV !" % attacker.get_name() if actual > 0 else "Mais cela echoue !")

		# Moonlight/Morning Sun/Synthesis (weather-dependent)
		"heal_weather":
			var ratio := 0.5
			if field != null:
				match field.weather:
					BattleField.Weather.SUN: ratio = 2.0 / 3.0
					BattleField.Weather.RAIN, BattleField.Weather.SANDSTORM, BattleField.Weather.HAIL: ratio = 0.25
			var actual := attacker.heal(int(attacker.max_hp * ratio))
			msgs.append("%s recupere des PV !" % attacker.get_name() if actual > 0 else "Mais cela echoue !")

		# Strength Sap (heal = target's Atk, then lower target's Atk)
		"strength_sap":
			var target_atk := defender.get_effective_stat("atk")
			attacker.heal(target_atk)
			msgs.append("%s absorbe la force de %s !" % [attacker.get_name(), defender.get_name()])
			msgs.append(_change_stat(defender, "atk", -1))

		# =============================================================
		#  SELF-FAINT (Explosion, Self-Destruct, Memento, etc.)
		# =============================================================
		"self_faint":
			attacker.take_damage(attacker.current_hp)
			msgs.append("%s se sacrifie !" % attacker.get_name())

		"memento":
			attacker.take_damage(attacker.current_hp)
			msgs.append(_change_stat(defender, "atk", -2))
			msgs.append(_change_stat(defender, "sp_atk", -2))

		"healing_wish":
			attacker.take_damage(attacker.current_hp)
			attacker.set_bmeta("healing_wish", true)
			msgs.append("%s utilise Voeu Soin !" % attacker.get_name())

		"lunar_dance":
			attacker.take_damage(attacker.current_hp)
			attacker.set_bmeta("lunar_dance", true)
			msgs.append("%s utilise Danse Lunaire !" % attacker.get_name())

		"final_gambit":
			var dmg := attacker.current_hp
			attacker.take_damage(attacker.current_hp)
			defender.take_damage(dmg)
			msgs.append("%s se sacrifie et inflige %d degats !" % [attacker.get_name(), dmg])

		# =============================================================
		#  RECOIL
		# =============================================================
		"recoil_quarter":
			var recoil := BattleCalc.calculate_recoil(damage_dealt, 0.25)
			attacker.take_damage(recoil)
			msgs.append("%s subit le contrecoup !" % attacker.get_name())
		"recoil_third":
			var recoil := BattleCalc.calculate_recoil(damage_dealt, 1.0/3.0)
			attacker.take_damage(recoil)
			msgs.append("%s subit le contrecoup !" % attacker.get_name())
		"recoil_half":
			var recoil := BattleCalc.calculate_recoil(damage_dealt, 0.5)
			attacker.take_damage(recoil)
			msgs.append("%s subit le contrecoup !" % attacker.get_name())

		# =============================================================
		#  DRAIN
		# =============================================================
		"drain_half":
			var drain := BattleCalc.calculate_drain(damage_dealt, 0.5)
			attacker.heal(drain)
			msgs.append("%s absorbe de l'energie !" % attacker.get_name())
		"drain_quarter":
			var drain := BattleCalc.calculate_drain(damage_dealt, 0.25)
			attacker.heal(drain)
			msgs.append("%s absorbe de l'energie !" % attacker.get_name())
		"drain_three_quarter":
			var drain := BattleCalc.calculate_drain(damage_dealt, 0.75)
			attacker.heal(drain)
			msgs.append("%s absorbe de l'energie !" % attacker.get_name())

		# =============================================================
		#  MULTI-HIT (handled in BattleCalc)
		# =============================================================
		"multi_hit_2", "multi_hit_2_5", "multi_hit_3", "multi_hit_4_5":
			pass  # Hit count determined in BattleCalc

		# Triple Kick / Triple Axel (3 hits, power increases)
		"triple_kick":
			pass  # Handled in BattleCalc

		# =============================================================
		#  ENTRY HAZARDS
		# =============================================================
		"stealth_rock":
			if field != null:
				msgs.append(field.add_hazard("enemy", "stealth_rock"))
		"spikes":
			if field != null:
				msgs.append(field.add_hazard("enemy", "spikes"))
		"toxic_spikes":
			if field != null:
				msgs.append(field.add_hazard("enemy", "toxic_spikes"))
		"sticky_web":
			if field != null:
				msgs.append(field.add_hazard("enemy", "sticky_web"))

		# =============================================================
		#  HAZARD REMOVAL
		# =============================================================
		"rapid_spin":
			if field != null:
				msgs.append(field.clear_hazards("player"))
				# Gen 8+: Rapid Spin raises Speed +1
				msgs.append(_change_stat(attacker, "speed", 1))
		"defog":
			if field != null:
				msgs.append(field.clear_hazards("player"))
				msgs.append(field.clear_hazards("enemy"))
				# Also removes screens
				for scr in ["reflect", "light_screen", "aurora_veil"]:
					field.screens["enemy"][scr] = 0
				msgs.append(_change_stat(defender, "evasion", -1))
		"court_change":
			if field != null:
				var tmp_p: Dictionary = field.hazards["player"].duplicate()
				field.hazards["player"] = field.hazards["enemy"].duplicate()
				field.hazards["enemy"] = tmp_p
				var tmp_sp: Dictionary = field.screens["player"].duplicate()
				field.screens["player"] = field.screens["enemy"].duplicate()
				field.screens["enemy"] = tmp_sp
				msgs.append("Les pieges sont echanges !")

		# =============================================================
		#  SCREENS
		# =============================================================
		"reflect":
			if field != null:
				var dur := HeldItemEffects.get_screen_duration(attacker, 5)
				msgs.append(field.set_screen("player", "reflect", dur))
		"light_screen":
			if field != null:
				var dur := HeldItemEffects.get_screen_duration(attacker, 5)
				msgs.append(field.set_screen("player", "light_screen", dur))
		"aurora_veil":
			if field != null:
				if field.weather == BattleField.Weather.HAIL:
					var dur := HeldItemEffects.get_screen_duration(attacker, 5)
					msgs.append(field.set_screen("player", "aurora_veil", dur))
				else:
					msgs.append("Mais cela echoue !")

		# =============================================================
		#  WEATHER
		# =============================================================
		"rain_dance":
			if field != null:
				var dur := HeldItemEffects.get_weather_duration(attacker, 5)
				msgs.append(field.set_weather(BattleField.Weather.RAIN, dur))
		"sunny_day":
			if field != null:
				var dur := HeldItemEffects.get_weather_duration(attacker, 5)
				msgs.append(field.set_weather(BattleField.Weather.SUN, dur))
		"sandstorm":
			if field != null:
				var dur := HeldItemEffects.get_weather_duration(attacker, 5)
				msgs.append(field.set_weather(BattleField.Weather.SANDSTORM, dur))
		"hail":
			if field != null:
				var dur := HeldItemEffects.get_weather_duration(attacker, 5)
				msgs.append(field.set_weather(BattleField.Weather.HAIL, dur))

		# =============================================================
		#  TERRAIN
		# =============================================================
		"electric_terrain":
			if field != null:
				msgs.append(field.set_terrain(BattleField.Terrain.ELECTRIC, 5))
		"grassy_terrain":
			if field != null:
				msgs.append(field.set_terrain(BattleField.Terrain.GRASSY, 5))
		"psychic_terrain":
			if field != null:
				msgs.append(field.set_terrain(BattleField.Terrain.PSYCHIC, 5))
		"misty_terrain":
			if field != null:
				msgs.append(field.set_terrain(BattleField.Terrain.MISTY, 5))

		# =============================================================
		#  TRICK ROOM / TAILWIND
		# =============================================================
		"trick_room":
			if field != null:
				msgs.append(field.set_trick_room(5))
		"tailwind":
			if field != null:
				msgs.append(field.set_tailwind("player", 4))

		# =============================================================
		#  PROTECT variants
		# =============================================================
		"protect":
			var consecutive: int = attacker.get_bmeta("protect_consecutive", 0)
			var success_rate := 1.0 / pow(3.0, consecutive)
			if randf() < success_rate:
				attacker.set_bmeta("protect", true)
				attacker.set_bmeta("protect_consecutive", consecutive + 1)
				msgs.append("%s se protege !" % attacker.get_name())
			else:
				attacker.set_bmeta("protect_consecutive", 0)
				msgs.append("Mais cela echoue !")

		"king_shield":
			var consecutive: int = attacker.get_bmeta("protect_consecutive", 0)
			var success_rate := 1.0 / pow(3.0, consecutive)
			if randf() < success_rate:
				attacker.set_bmeta("protect", true)
				attacker.set_bmeta("king_shield", true)
				attacker.set_bmeta("protect_consecutive", consecutive + 1)
				msgs.append("%s se protege avec le Bouclier Royal !" % attacker.get_name())
			else:
				attacker.set_bmeta("protect_consecutive", 0)
				msgs.append("Mais cela echoue !")

		"baneful_bunker":
			var consecutive: int = attacker.get_bmeta("protect_consecutive", 0)
			var success_rate := 1.0 / pow(3.0, consecutive)
			if randf() < success_rate:
				attacker.set_bmeta("protect", true)
				attacker.set_bmeta("baneful_bunker", true)
				attacker.set_bmeta("protect_consecutive", consecutive + 1)
				msgs.append("%s se protege avec le Blockhaus !" % attacker.get_name())
			else:
				attacker.set_bmeta("protect_consecutive", 0)
				msgs.append("Mais cela echoue !")

		"spiky_shield":
			var consecutive: int = attacker.get_bmeta("protect_consecutive", 0)
			var success_rate := 1.0 / pow(3.0, consecutive)
			if randf() < success_rate:
				attacker.set_bmeta("protect", true)
				attacker.set_bmeta("spiky_shield", true)
				attacker.set_bmeta("protect_consecutive", consecutive + 1)
				msgs.append("%s se protege avec le Bouclier Piquant !" % attacker.get_name())
			else:
				attacker.set_bmeta("protect_consecutive", 0)
				msgs.append("Mais cela echoue !")

		# =============================================================
		#  TRAPPING / BINDING
		# =============================================================
		"trap":
			if not defender.has_bmeta("trapped"):
				defender.set_bmeta("trapped", randi_range(4, 5))
				defender.set_bmeta("trap_source", attacker)
				msgs.append("%s est pris au piege !" % defender.get_name())

		# =============================================================
		#  LEECH SEED
		# =============================================================
		"leech_seed":
			if "Grass" in defender.get_types():
				msgs.append("Ca n'affecte pas %s..." % defender.get_name())
			elif defender.has_bmeta("leech_seed"):
				msgs.append("%s est deja parasite !" % defender.get_name())
			else:
				defender.set_bmeta("leech_seed", true)
				defender.set_bmeta("leech_seed_source", attacker)
				msgs.append("%s est parasite !" % defender.get_name())

		# =============================================================
		#  FOCUS ENERGY
		# =============================================================
		"focus_energy":
			if attacker.has_bmeta("focus_energy"):
				msgs.append("Mais cela echoue !")
			else:
				attacker.set_bmeta("focus_energy", true)
				msgs.append("%s se concentre !" % attacker.get_name())

		# =============================================================
		#  FIXED DAMAGE
		# =============================================================
		"fixed_damage_20":
			defender.take_damage(20)
			msgs.append("%s subit 20 points de degats fixes !" % defender.get_name())
		"fixed_damage_40":
			defender.take_damage(40)
			msgs.append("%s subit 40 points de degats fixes !" % defender.get_name())
		"fixed_damage_level":
			pass  # Handled in BattleCalc

		# Counter / Mirror Coat
		"counter":
			pass  # Handled in TurnManager
		"mirror_coat":
			pass  # Handled in TurnManager

		# =============================================================
		#  VOLATILE STATUS
		# =============================================================
		"disable":
			if defender.has_bmeta("disabled_move"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("disabled_move", "")
				defender.set_bmeta("disable_turns", randi_range(4, 7))
				msgs.append("La capacite de %s est desactivee !" % defender.get_name())

		"encore":
			if defender.has_bmeta("encored"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("encored", true)
				defender.set_bmeta("encore_turns", randi_range(3, 6))
				msgs.append("%s est oblige de repeter sa capacite !" % defender.get_name())

		"taunt":
			if defender.has_bmeta("taunted"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("taunted", true)
				defender.set_bmeta("taunt_turns", 3)
				msgs.append("%s ne peut plus utiliser de capacites de statut !" % defender.get_name())

		"torment":
			if defender.has_bmeta("tormented"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("tormented", true)
				msgs.append("%s ne peut plus utiliser la meme capacite 2 fois !" % defender.get_name())

		"heal_block":
			if defender.has_bmeta("heal_blocked"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("heal_blocked", true)
				defender.set_bmeta("heal_block_turns", 5)
				msgs.append("%s ne peut plus se soigner !" % defender.get_name())

		"embargo":
			if defender.has_bmeta("embargo"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("embargo", true)
				defender.set_bmeta("embargo_turns", 5)
				msgs.append("%s ne peut plus utiliser d'objets !" % defender.get_name())

		# =============================================================
		#  SUBSTITUTE
		# =============================================================
		"substitute":
			if attacker.current_hp <= int(attacker.max_hp / 4.0):
				msgs.append("Mais cela echoue ! (PV insuffisants)")
			elif attacker.has_bmeta("substitute_hp"):
				msgs.append("Mais cela echoue ! (Clone deja actif)")
			else:
				var sub_hp := int(attacker.max_hp / 4.0)
				attacker.take_damage(sub_hp)
				attacker.set_bmeta("substitute_hp", sub_hp)
				msgs.append("%s cree un clone !" % attacker.get_name())

		# =============================================================
		#  ITEM MANIPULATION
		# =============================================================
		"trick":
			var temp: String = attacker.held_item
			attacker.held_item = defender.held_item
			defender.held_item = temp
			msgs.append("%s echange son objet avec %s !" % [attacker.get_name(), defender.get_name()])

		"knock_off":
			if defender.held_item != "":
				var item_name := HeldItemEffects.get_item_name(defender.held_item)
				defender.held_item = ""
				msgs.append("%s fait tomber %s de %s !" % [attacker.get_name(), item_name, defender.get_name()])

		"thief":
			if attacker.held_item == "" and defender.held_item != "":
				var item_name := HeldItemEffects.get_item_name(defender.held_item)
				attacker.held_item = defender.held_item
				defender.held_item = ""
				msgs.append("%s vole %s de %s !" % [attacker.get_name(), item_name, defender.get_name()])

		"bestow":
			if attacker.held_item != "" and defender.held_item == "":
				var item_name := HeldItemEffects.get_item_name(attacker.held_item)
				defender.held_item = attacker.held_item
				attacker.held_item = ""
				msgs.append("%s donne %s a %s !" % [attacker.get_name(), item_name, defender.get_name()])

		"recycle":
			if attacker.has_bmeta("consumed_item"):
				attacker.held_item = attacker.get_bmeta("consumed_item")
				attacker.remove_bmeta("consumed_item")
				var item_name := HeldItemEffects.get_item_name(attacker.held_item)
				msgs.append("%s recupere son %s !" % [attacker.get_name(), item_name])
			else:
				msgs.append("Mais cela echoue !")

		# =============================================================
		#  TWO-TURN / BATON PASS / FORCE SWITCH
		# =============================================================
		"two_turn":
			pass  # Handled in TurnManager
		"baton_pass":
			pass  # Handled in TurnManager
		"facade":
			pass  # Power doubled in damage calc

		"force_switch":
			pass  # Handled in TurnManager
		"u_turn":
			pass  # Handled in TurnManager (pivot move: deal damage then switch)

		# =============================================================
		#  WISH / PAIN SPLIT / PERISH SONG
		# =============================================================
		"wish":
			attacker.set_bmeta("wish_turns", 1)
			attacker.set_bmeta("wish_hp", int(attacker.max_hp / 2.0))
			msgs.append("%s fait un voeu !" % attacker.get_name())

		"pain_split":
			var avg := int((attacker.current_hp + defender.current_hp) / 2.0)
			attacker.current_hp = mini(avg, attacker.max_hp)
			defender.current_hp = mini(avg, defender.max_hp)
			msgs.append("Les PV de %s et %s sont partages !" % [attacker.get_name(), defender.get_name()])

		"perish_song":
			if not attacker.has_bmeta("perish_count"):
				attacker.set_bmeta("perish_count", 3)
			if not defender.has_bmeta("perish_count"):
				defender.set_bmeta("perish_count", 3)
			msgs.append("Tous les Pokemon entendent le requiem !")

		"destiny_bond":
			attacker.set_bmeta("destiny_bond", true)
			msgs.append("%s lie son destin !" % attacker.get_name())

		"grudge":
			attacker.set_bmeta("grudge", true)
			msgs.append("%s lance une rancune !" % attacker.get_name())

		# =============================================================
		#  ABILITY / TYPE MANIPULATION
		# =============================================================
		"skill_swap":
			var temp: String = attacker.ability
			attacker.ability = defender.ability
			defender.ability = temp
			msgs.append("%s echange son talent avec %s !" % [attacker.get_name(), defender.get_name()])

		"role_play":
			attacker.ability = defender.ability
			msgs.append("%s copie %s !" % [attacker.get_name(), AbilityEffects.get_ability_name(defender.ability)])

		"gastro_acid":
			defender.set_bmeta("ability_suppressed", true)
			msgs.append("Le talent de %s est supprime !" % defender.get_name())

		"soak":
			defender.set_bmeta("override_types", ["Water"])
			msgs.append("%s devient de type Eau !" % defender.get_name())

		"forest_curse":
			var types := defender.get_types()
			if "Grass" not in types:
				types.append("Grass")
				defender.set_bmeta("override_types", types)
				msgs.append("%s gagne le type Plante !" % defender.get_name())

		"trick_or_treat":
			var types := defender.get_types()
			if "Ghost" not in types:
				types.append("Ghost")
				defender.set_bmeta("override_types", types)
				msgs.append("%s gagne le type Spectre !" % defender.get_name())

		# =============================================================
		#  MISCELLANEOUS
		# =============================================================
		"attract":
			if defender.has_bmeta("attracted"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("attracted", true)
				msgs.append("%s est seduit !" % defender.get_name())

		"yawn":
			if defender.status != "" or defender.has_bmeta("yawn"):
				msgs.append("Mais cela echoue !")
			else:
				defender.set_bmeta("yawn", 1)
				msgs.append("%s baille... %s a sommeil !" % [attacker.get_name(), defender.get_name()])

		"transform":
			msgs.append("%s se transforme en %s !" % [attacker.get_name(), defender.get_name()])
			# Copy stats, types, moves (simplified)
			attacker.set_bmeta("transformed", true)
			attacker.set_bmeta("override_types", defender.get_types())

		"mimic":
			if defender.has_bmeta("last_move_used"):
				var mimicked: String = defender.get_bmeta("last_move_used")
				msgs.append("%s copie %s !" % [attacker.get_name(), mimicked])

		"spite":
			if defender.has_bmeta("last_move_used"):
				# Reduce PP of last used move by 4
				for mv in defender.moves:
					if mv.move_id == defender.get_bmeta("last_move_used"):
						mv.current_pp = maxi(0, mv.current_pp - 4)
						msgs.append("%s perd 4 PP !" % mv.get_name())
						break

		"conversion":
			# Change type to first move's type
			if attacker.moves.size() > 0:
				var new_type: String = attacker.moves[0].get_type()
				attacker.set_bmeta("override_types", [new_type])
				msgs.append("%s change de type en %s !" % [attacker.get_name(), new_type])

		"conversion_2":
			# Change to type that resists last hit
			pass

		"stockpile":
			var count: int = attacker.get_bmeta("stockpile", 0)
			if count >= 3:
				msgs.append("Mais cela echoue !")
			else:
				attacker.set_bmeta("stockpile", count + 1)
				msgs.append(_change_stat(attacker, "def", 1))
				msgs.append(_change_stat(attacker, "sp_def", 1))

		"spit_up":
			var count: int = attacker.get_bmeta("stockpile", 0)
			if count == 0:
				msgs.append("Mais cela echoue !")
			else:
				attacker.set_bmeta("stockpile", 0)

		"swallow":
			var count: int = attacker.get_bmeta("stockpile", 0)
			if count == 0:
				msgs.append("Mais cela echoue !")
			else:
				var ratios := [0.0, 0.25, 0.5, 1.0]
				attacker.heal(int(attacker.max_hp * ratios[count]))
				attacker.set_bmeta("stockpile", 0)
				msgs.append("%s recupere des PV !" % attacker.get_name())

		"power_trick":
			var tmp: int = attacker.stats["atk"]
			attacker.stats["atk"] = attacker.stats["def"]
			attacker.stats["def"] = tmp
			msgs.append("%s echange Attaque et Defense !" % attacker.get_name())

		"power_split":
			var avg_atk := int((attacker.stats["atk"] + defender.stats["atk"]) / 2.0)
			var avg_spatk := int((attacker.stats["sp_atk"] + defender.stats["sp_atk"]) / 2.0)
			attacker.stats["atk"] = avg_atk; defender.stats["atk"] = avg_atk
			attacker.stats["sp_atk"] = avg_spatk; defender.stats["sp_atk"] = avg_spatk
			msgs.append("Les stats offensives sont partagees !")

		"guard_split":
			var avg_def := int((attacker.stats["def"] + defender.stats["def"]) / 2.0)
			var avg_spdef := int((attacker.stats["sp_def"] + defender.stats["sp_def"]) / 2.0)
			attacker.stats["def"] = avg_def; defender.stats["def"] = avg_def
			attacker.stats["sp_def"] = avg_spdef; defender.stats["sp_def"] = avg_spdef
			msgs.append("Les stats defensives sont partagees !")

		"lucky_chant":
			attacker.set_bmeta("lucky_chant", 5)
			msgs.append("Porte-Bonheur protege l'equipe des coups critiques !")

		"aqua_ring":
			attacker.set_bmeta("aqua_ring", true)
			msgs.append("%s s'entoure d'un voile d'eau !" % attacker.get_name())

		"ingrain":
			attacker.set_bmeta("ingrain", true)
			msgs.append("%s plante ses racines !" % attacker.get_name())

		"magic_coat":
			attacker.set_bmeta("magic_coat", true)
			msgs.append("%s dresse un Miroir Magik !" % attacker.get_name())

		"imprison":
			attacker.set_bmeta("imprison", true)
			msgs.append("%s utilise Possessif !" % attacker.get_name())

		"heal_bell":
			msgs.append("Un son de cloche guerit toute l'equipe !")
			for pkmn in GameState.team:
				pkmn.status = ""
				pkmn.status_turns = 0

		"aromatherapy":
			msgs.append("Un doux parfum guerit toute l'equipe !")
			for pkmn in GameState.team:
				pkmn.status = ""
				pkmn.status_turns = 0

		"psych_up":
			for stat in ["atk", "def", "sp_atk", "sp_def", "speed", "accuracy", "evasion"]:
				attacker.stat_stages[stat] = defender.stat_stages.get(stat, 0)
			msgs.append("%s copie les changements de stats de %s !" % [attacker.get_name(), defender.get_name()])

		"haze":
			for stat in ["atk", "def", "sp_atk", "sp_def", "speed", "accuracy", "evasion"]:
				attacker.stat_stages[stat] = 0
				defender.stat_stages[stat] = 0
			msgs.append("Toutes les modifications de stats sont annulees !")

		"topsy_turvy":
			for stat in defender.stat_stages:
				defender.stat_stages[stat] = -defender.stat_stages[stat]
			msgs.append("Les changements de stats de %s sont inverses !" % defender.get_name())

	# Filter empty messages
	return msgs.filter(func(m: String) -> bool: return m != "")

# =========================================================================
#  Status check at turn start
# =========================================================================

static func check_can_move(pkmn: PokemonInstance) -> Dictionary:
	# Flinch
	if pkmn.has_bmeta("flinch") and pkmn.get_bmeta("flinch"):
		pkmn.set_bmeta("flinch", false)
		return { "can_move": false, "message": "%s a tressailli !\nIl ne peut pas attaquer !" % pkmn.get_name() }

	# Attract
	if pkmn.has_bmeta("attracted"):
		if randf() < 0.5:
			return { "can_move": false, "message": "%s est amoureux !\nIl ne peut pas attaquer !" % pkmn.get_name() }

	# Confusion
	if pkmn.has_bmeta("confused"):
		var turns_left: int = pkmn.get_bmeta("confused")
		if turns_left <= 0:
			pkmn.remove_bmeta("confused")
		else:
			pkmn.set_bmeta("confused", turns_left - 1)
			if randf() < 0.33:
				var self_dmg := maxi(1, int(pkmn.max_hp / 8.0))
				pkmn.take_damage(self_dmg)
				return { "can_move": false, "message": "%s est confus !\nIl se blesse dans sa confusion !" % pkmn.get_name() }

	match pkmn.status:
		"paralyze":
			if randf() < 0.25:
				return { "can_move": false, "message": "%s est paralyse !\nIl ne peut pas bouger !" % pkmn.get_name() }
		"sleep":
			if pkmn.status_turns > 0:
				pkmn.status_turns -= 1
				if pkmn.status_turns == 0:
					pkmn.status = ""
					return { "can_move": true, "message": "%s se reveille !" % pkmn.get_name() }
				return { "can_move": false, "message": "%s dort profondement..." % pkmn.get_name() }
		"freeze":
			if randf() < 0.20:
				pkmn.status = ""
				return { "can_move": true, "message": "%s degele !" % pkmn.get_name() }
			return { "can_move": false, "message": "%s est gele !\nIl ne peut pas bouger !" % pkmn.get_name() }

	return { "can_move": true, "message": "" }

# =========================================================================
#  End-of-turn effects
# =========================================================================

static func apply_end_of_turn(pkmn: PokemonInstance, field: BattleField = null) -> Array[String]:
	var msgs: Array[String] = []
	if pkmn.is_fainted():
		return msgs

	# -- Ability EOT effects --
	if field != null:
		var ab_effects := AbilityEffects.on_end_of_turn(pkmn, field)
		var skip_status_dmg := false
		for eff in ab_effects:
			if eff.has("message") and eff.message != "":
				msgs.append(eff.message)
			if eff.has("skip_status_damage"):
				skip_status_dmg = true

		if not skip_status_dmg:
			msgs.append_array(_apply_status_damage(pkmn))
	else:
		msgs.append_array(_apply_status_damage(pkmn))

	if pkmn.is_fainted():
		return msgs

	# -- Leech Seed --
	if pkmn.has_bmeta("leech_seed") and pkmn.get_bmeta("leech_seed"):
		var seed_dmg := maxi(1, int(pkmn.max_hp / 8.0))
		var actual := pkmn.take_damage(seed_dmg)
		var seeder = pkmn.get_bmeta("leech_seed_source") if pkmn.has_bmeta("leech_seed_source") else null
		if seeder is PokemonInstance and not seeder.is_fainted():
			seeder.heal(actual)
		msgs.append("%s est draine par Vampigraine !" % pkmn.get_name())

	# -- Trap damage (Wrap, Bind, etc.) --
	if pkmn.has_bmeta("trapped"):
		var turns: int = pkmn.get_bmeta("trapped")
		if turns > 0:
			var trap_dmg := maxi(1, int(pkmn.max_hp / 16.0))
			pkmn.take_damage(trap_dmg)
			pkmn.set_bmeta("trapped", turns - 1)
			msgs.append("%s est pris au piege et perd des PV !" % pkmn.get_name())
		else:
			pkmn.remove_bmeta("trapped")
			msgs.append("%s se libere du piege !" % pkmn.get_name())

	# -- Curse damage (Ghost) --
	if pkmn.has_bmeta("cursed"):
		var curse_dmg := maxi(1, int(pkmn.max_hp / 4.0))
		pkmn.take_damage(curse_dmg)
		msgs.append("%s est affecte par la malediction !" % pkmn.get_name())

	# -- Perish Song --
	if pkmn.has_bmeta("perish_count"):
		var count: int = pkmn.get_bmeta("perish_count")
		msgs.append("%s : compte a rebours : %d !" % [pkmn.get_name(), count])
		if count <= 0:
			pkmn.take_damage(pkmn.current_hp)
			msgs.append("%s tombe a cause du requiem !" % pkmn.get_name())
		else:
			pkmn.set_bmeta("perish_count", count - 1)

	# -- Wish fulfillment --
	if pkmn.has_bmeta("wish_turns"):
		var wt: int = pkmn.get_bmeta("wish_turns")
		if wt <= 0:
			var wish_hp: int = pkmn.get_bmeta("wish_hp", 0)
			pkmn.heal(wish_hp)
			pkmn.remove_bmeta("wish_turns")
			pkmn.remove_bmeta("wish_hp")
			msgs.append("Le voeu de %s se realise !" % pkmn.get_name())
		else:
			pkmn.set_bmeta("wish_turns", wt - 1)

	# -- Yawn (sleeps next turn) --
	if pkmn.has_bmeta("yawn"):
		var yt: int = pkmn.get_bmeta("yawn")
		if yt <= 0:
			pkmn.remove_bmeta("yawn")
			if pkmn.status == "":
				pkmn.status = "sleep"
				pkmn.status_turns = randi_range(1, 3)
				msgs.append("%s s'endort a cause du baillement !" % pkmn.get_name())
		else:
			pkmn.set_bmeta("yawn", yt - 1)

	# -- Aqua Ring --
	if pkmn.has_bmeta("aqua_ring"):
		var heal := maxi(1, int(pkmn.max_hp / 16.0))
		pkmn.heal(heal)
		msgs.append("%s recupere des PV grace au voile d'eau !" % pkmn.get_name())

	# -- Ingrain --
	if pkmn.has_bmeta("ingrain"):
		var heal := maxi(1, int(pkmn.max_hp / 16.0))
		pkmn.heal(heal)
		msgs.append("%s recupere des PV grace a ses racines !" % pkmn.get_name())

	# -- Grassy Terrain healing --
	if field != null and field.terrain == BattleField.Terrain.GRASSY:
		var heal := maxi(1, int(pkmn.max_hp / 16.0))
		pkmn.heal(heal)
		msgs.append("%s recupere des PV grace a l'herbe !" % pkmn.get_name())

	# -- Held item EOT --
	var item_effects := HeldItemEffects.on_end_of_turn(pkmn)
	for eff in item_effects:
		if eff.has("message") and eff.message != "":
			msgs.append(eff.message)
		if eff.has("consume") and eff.consume:
			HeldItemEffects.consume_item(pkmn)

	# -- Berry check --
	var berry := HeldItemEffects.check_berry(pkmn)
	if berry.message != "":
		msgs.append(berry.message)
		if berry.consume:
			HeldItemEffects.consume_item(pkmn)

	# -- Weather damage --
	if field != null:
		if not AbilityEffects.is_immune_to_weather_damage(pkmn, field.weather):
			var wd := field.get_weather_damage(pkmn)
			if not wd.is_empty():
				pkmn.take_damage(wd.damage)
				msgs.append(wd.message)

	# -- Volatile status countdowns --
	_tick_volatile(pkmn, "taunted", "taunt_turns")
	_tick_volatile(pkmn, "encored", "encore_turns")
	_tick_volatile(pkmn, "heal_blocked", "heal_block_turns")
	_tick_volatile(pkmn, "embargo", "embargo_turns")

	if pkmn.has_bmeta("disabled_move"):
		var dt: int = pkmn.get_bmeta("disable_turns", 0)
		if dt <= 1:
			pkmn.remove_bmeta("disabled_move")
			pkmn.remove_bmeta("disable_turns")
		else:
			pkmn.set_bmeta("disable_turns", dt - 1)

	return msgs.filter(func(m: String) -> bool: return m != "")

# -- Volatile status countdown helper ------------------------------------

static func _tick_volatile(pkmn: PokemonInstance, flag_key: String, turns_key: String) -> void:
	if pkmn.has_bmeta(flag_key):
		var t: int = pkmn.get_bmeta(turns_key, 0)
		if t <= 1:
			pkmn.remove_bmeta(flag_key)
			pkmn.remove_bmeta(turns_key)
		else:
			pkmn.set_bmeta(turns_key, t - 1)

# -- Status damage -------------------------------------------------------

static func _apply_status_damage(pkmn: PokemonInstance) -> Array[String]:
	var msgs: Array[String] = []
	match pkmn.status:
		"burn":
			var dmg := maxi(1, int(pkmn.max_hp / 16.0))  # Gen 7+: 1/16
			pkmn.take_damage(dmg)
			msgs.append("%s souffre de sa brulure !" % pkmn.get_name())
		"poison":
			var dmg := maxi(1, int(pkmn.max_hp / 8.0))
			pkmn.take_damage(dmg)
			msgs.append("%s souffre du poison !" % pkmn.get_name())
		"bad_poison":
			pkmn.status_turns += 1
			var dmg := maxi(1, int(pkmn.max_hp * pkmn.status_turns / 16.0))
			pkmn.take_damage(dmg)
			msgs.append("%s souffre du poison violent !" % pkmn.get_name())
	return msgs

# =========================================================================
#  Helpers
# =========================================================================

static func _try_status(target: PokemonInstance, status: String, attacker: PokemonInstance = null) -> Array[String]:
	var msgs: Array[String] = []

	if target.status != "":
		return msgs

	# Substitute blocks status
	if target.has_bmeta("substitute_hp"):
		return msgs

	# Ability prevention
	if AbilityEffects.prevents_status(target, status):
		msgs.append("%s est protege par %s !" % [target.get_name(), target.get_ability_name()])
		return msgs

	# Type immunities
	var types := target.get_types()
	match status:
		"burn":     if "Fire"     in types: return msgs
		"paralyze": if "Electric" in types: return msgs
		"freeze":   if "Ice"      in types: return msgs
		"poison", "bad_poison":
			if "Poison" in types or "Steel" in types: return msgs

	target.status = status
	if status == "sleep":
		target.status_turns = randi_range(1, 3)
	elif status == "bad_poison":
		target.status_turns = 0

	match status:
		"burn":       msgs.append("%s est brule !" % target.get_name())
		"paralyze":   msgs.append("%s est paralyse !" % target.get_name())
		"sleep":      msgs.append("%s s'endort !" % target.get_name())
		"freeze":     msgs.append("%s est gele !" % target.get_name())
		"poison":     msgs.append("%s est empoisonne !" % target.get_name())
		"bad_poison": msgs.append("%s est gravement empoisonne !" % target.get_name())

	# Synchronize
	if attacker != null:
		var sync_msg := AbilityEffects.check_synchronize(target, attacker, status)
		if sync_msg != "":
			msgs.append(sync_msg)

	# Berry check for status cure
	var berry := HeldItemEffects.check_berry(target)
	if berry.message != "":
		msgs.append(berry.message)
		if berry.consume:
			HeldItemEffects.consume_item(target)

	return msgs

static func _change_stat(target: PokemonInstance, stat: String, delta: int) -> String:
	var actual := target.modify_stat_stage(stat, delta)
	const NAMES := { "atk":"Attaque", "def":"Defense", "sp_atk":"Atq. Spe",
	                 "sp_def":"Def. Spe", "speed":"Vitesse", "accuracy":"Precision",
	                 "evasion":"Esquive" }
	var lbl: String = NAMES.get(stat, stat)
	if actual == 0:
		if delta < 0 and AbilityEffects.prevents_stat_drop(target, stat):
			return "%s : %s est protege par %s !" % [target.get_name(), lbl, target.get_ability_name()]
		return "%s : %s ne peut pas %s davantage !" % [target.get_name(), lbl, "monter" if delta > 0 else "baisser"]
	var intensity := ""
	if abs(actual) >= 2:
		intensity = " enormement" if abs(actual) >= 3 else " beaucoup"
	if actual > 0:
		return "%s : %s monte%s !" % [target.get_name(), lbl, intensity]
	return "%s : %s baisse%s !" % [target.get_name(), lbl, intensity]
