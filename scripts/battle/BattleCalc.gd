class_name BattleCalc
## Calculs purs du systeme de combat Gen 3-9.
## Integre abilities, held items, natures, ecrans, meteo, terrain.
## Toutes les fonctions sont statiques.

# -- Degats ---------------------------------------------------------------

static func calculate_damage(
	attacker: PokemonInstance,
	defender: PokemonInstance,
	move: MoveInstance,
	field: BattleField = null
) -> Dictionary:
	var result := {
		"damage": 0, "critical": false, "effectiveness": 1.0,
		"stab": false, "hits": 1, "blocked": false, "block_message": ""
	}

	var move_type: String = move.get_type()
	var move_cat: String = move.get_category()

	# -- -ate ability type change --
	if attacker.ability in ["pixilate", "refrigerate", "aerilate", "galvanize"] and move_type == "Normal":
		match attacker.ability:
			"pixilate":    move_type = "Fairy"
			"refrigerate": move_type = "Ice"
			"aerilate":    move_type = "Flying"
			"galvanize":   move_type = "Electric"

	# -- Ability immunity check --
	if field != null:
		var immunity := AbilityEffects.on_before_hit(
			defender, attacker, move_type, move_cat, field)
		if immunity.blocked:
			result.blocked = true
			result.block_message = immunity.message
			if immunity.heal > 0:
				defender.heal(immunity.heal)
			return result

	# -- Fixed-damage moves --
	if move.get_effect() == "fixed_damage_level":
		var type_eff: float = GameData.get_total_effectiveness(move_type, defender.get_types())
		result.effectiveness = type_eff
		result.damage = attacker.level if type_eff > 0.0 else 0
		return result

	var power: int = move.get_power()
	if power == 0:
		return result  # Status move

	# -- Power modifiers --
	# Facade doubles when statused
	if move.get_effect() == "facade" and attacker.status != "":
		power *= 2

	# Knock Off boost when defender has item
	if move.get_effect() == "knock_off" and defender.held_item != "":
		power = int(power * 1.5)

	# Acrobatics doubles when no item
	if move.move_id == "acrobatics" and attacker.held_item == "":
		power *= 2

	# Weather Ball doubles in weather + changes type
	if move.move_id == "weather_ball" and field != null:
		if field.weather != BattleField.Weather.NONE:
			power *= 2
			match field.weather:
				BattleField.Weather.RAIN:      move_type = "Water"
				BattleField.Weather.SUN:       move_type = "Fire"
				BattleField.Weather.SANDSTORM: move_type = "Rock"
				BattleField.Weather.HAIL:      move_type = "Ice"

	# Terrain Pulse
	if move.move_id == "terrain_pulse" and field != null:
		if field.terrain != BattleField.Terrain.NONE:
			power *= 2
			match field.terrain:
				BattleField.Terrain.ELECTRIC: move_type = "Electric"
				BattleField.Terrain.GRASSY:   move_type = "Grass"
				BattleField.Terrain.PSYCHIC:  move_type = "Psychic"
				BattleField.Terrain.MISTY:    move_type = "Fairy"

	# Stored Power / Power Trip (20 + 20 per stat boost)
	if move.move_id in ["stored_power", "power_trip"]:
		var boosts := 0
		for s in attacker.stat_stages:
			if attacker.stat_stages[s] > 0:
				boosts += attacker.stat_stages[s]
		power = 20 + 20 * boosts

	# Low Kick / Grass Knot (weight-based, approximated)
	if move.move_id in ["low_kick", "grass_knot"]:
		power = 80  # Simplified — would need weight data

	# Eruption / Water Spout (150 * currentHP / maxHP)
	if move.move_id in ["eruption", "water_spout"]:
		power = maxi(1, int(150.0 * attacker.current_hp / attacker.max_hp))

	# Reversal / Flail (higher when lower HP)
	if move.move_id in ["reversal", "flail"]:
		var hp_pct := float(attacker.current_hp) / float(attacker.max_hp)
		if hp_pct <= 0.0417: power = 200
		elif hp_pct <= 0.1042: power = 150
		elif hp_pct <= 0.2083: power = 100
		elif hp_pct <= 0.3542: power = 80
		elif hp_pct <= 0.6875: power = 40
		else: power = 20

	# Gyro Ball (25 * target_speed / user_speed)
	if move.move_id == "gyro_ball":
		var usr_spd: int = maxi(1, attacker.get_effective_stat("speed"))
		var tgt_spd: int = maxi(1, defender.get_effective_stat("speed"))
		power = mini(150, maxi(1, int(25.0 * tgt_spd / usr_spd)))

	# Electro Ball (faster = more powerful)
	if move.move_id == "electro_ball":
		var usr_spd: int = maxi(1, attacker.get_effective_stat("speed"))
		var tgt_spd: int = maxi(1, defender.get_effective_stat("speed"))
		var ratio := float(usr_spd) / float(tgt_spd)
		if ratio >= 4.0: power = 150
		elif ratio >= 3.0: power = 120
		elif ratio >= 2.0: power = 80
		elif ratio >= 1.0: power = 60
		else: power = 40

	# Avalanche / Revenge (doubles if hit first)
	if move.move_id in ["avalanche", "revenge"]:
		if attacker.has_bmeta("was_hit_this_turn"):
			power *= 2

	# -- Stat selection --
	var atk_val: int
	var def_val: int

	# Unaware: ignore stat changes
	var ignore_atk_stages := AbilityEffects.ignores_stat_changes(defender)
	var ignore_def_stages := AbilityEffects.ignores_stat_changes(attacker)

	if move_cat == "physical":
		atk_val = attacker.get_effective_stat("atk") if not ignore_atk_stages else attacker.stats.get("atk", 1)
		def_val = defender.get_effective_stat("def") if not ignore_def_stages else defender.stats.get("def", 1)
	else:
		atk_val = attacker.get_effective_stat("sp_atk") if not ignore_atk_stages else attacker.stats.get("sp_atk", 1)
		def_val = defender.get_effective_stat("sp_def") if not ignore_def_stages else defender.stats.get("sp_def", 1)

	# Psyshock / Psystrike / Secret Sword: special attack vs physical defense
	if move.move_id in ["psyshock", "psystrike", "secret_sword"]:
		def_val = defender.get_effective_stat("def") if not ignore_def_stages else defender.stats.get("def", 1)

	# -- Gen 3+ damage formula --
	var base: int = int(int(int(2.0 * attacker.level / 5.0 + 2.0) * power * atk_val / def_val) / 50.0) + 2

	# -- Critical hit --
	var crit_stage := 0
	if move.get_effect() == "high_crit":
		crit_stage += 1
	if attacker.has_bmeta("focus_energy"):
		crit_stage += 2
	crit_stage += HeldItemEffects.get_crit_stage_bonus(attacker)

	if AbilityEffects.prevents_critical(defender):
		crit_stage = -99
	# Lucky Chant prevents crits
	if defender.has_bmeta("lucky_chant") and defender.get_bmeta("lucky_chant") > 0:
		crit_stage = -99

	var crit_rates := [1.0/24.0, 1.0/8.0, 1.0/2.0, 1.0, 1.0]  # Gen 7+ rates
	var crit_rate: float = 0.0 if crit_stage < 0 else crit_rates[mini(crit_stage, 4)]
	var is_crit: bool = randf() < crit_rate
	if is_crit:
		base = int(base * 1.5)
		result.critical = true

	# -- Burn reduces physical damage (unless Guts) --
	if attacker.status == "burn" and move_cat == "physical" and attacker.ability != "guts":
		base = int(base * 0.5)

	# -- STAB --
	var has_stab: bool = move_type in attacker.get_types()
	var stab_mult := 1.5 if has_stab else 1.0
	# Adaptability makes STAB 2.0 (handled in ability damage mult as ratio)
	result.stab = has_stab

	# -- Type effectiveness --
	var type_eff: float = GameData.get_total_effectiveness(move_type, defender.get_types())
	result.effectiveness = type_eff

	# Grounded check for Electric Terrain (prevents sleep)
	# Misty Terrain halves Dragon damage
	if field != null and field.terrain == BattleField.Terrain.MISTY and move_type == "Dragon":
		type_eff *= 0.5
		result.effectiveness = type_eff

	# -- Weather multiplier --
	var weather_mult := 1.0
	if field != null:
		weather_mult = field.get_weather_multiplier(move_type)

	# -- Ability damage multiplier --
	var ability_mult := 1.0
	if field != null:
		ability_mult = AbilityEffects.get_damage_multiplier(
			attacker, defender, move_type, move_cat, field)

	# -- Held item damage multiplier --
	var item_mult := HeldItemEffects.get_damage_multiplier(
		attacker, move_type, move_cat, type_eff)

	# -- Random factor 85%-100% --
	var rng := randf_range(0.85, 1.0)

	# -- Final calculation --
	var final_dmg := int(base * stab_mult * type_eff * weather_mult * ability_mult * item_mult * rng)
	result.damage = max(1 if type_eff > 0.0 else 0, final_dmg)

	# -- Multi-hit moves --
	var effect: String = move.get_effect()
	match effect:
		"multi_hit_2":
			result.hits = 2
		"multi_hit_2_5":
			if attacker.ability == "skill_link":
				result.hits = 5
			else:
				var roll := randf()
				if roll < 0.35:   result.hits = 2
				elif roll < 0.70: result.hits = 3
				elif roll < 0.85: result.hits = 4
				else:             result.hits = 5
		"multi_hit_3":
			result.hits = 3
		"multi_hit_4_5":
			if attacker.ability == "skill_link":
				result.hits = 5
			else:
				result.hits = randi_range(4, 5)
		"triple_kick":
			result.hits = 3
			# Each hit increases power (handled via separate damage per hit)

	return result

# -- Screen reduction -----------------------------------------------------

static func apply_screen_reduction(damage: int, field: BattleField, side: String, category: String, is_crit: bool) -> int:
	if is_crit or field == null:
		return damage
	var mult := field.get_screen_multiplier(side, category)
	return maxi(1, int(damage * mult))

# -- Survival check -------------------------------------------------------

static func check_survival(defender: PokemonInstance, damage: int) -> Dictionary:
	var result := {"survived": false, "final_damage": damage, "messages": []}

	# Sturdy
	if AbilityEffects.check_sturdy(defender, damage):
		result.survived = true
		result.final_damage = defender.current_hp - 1
		result.messages.append("%s tient bon grace a Fermete !" % defender.get_name())
		return result

	# Focus Sash / Focus Band
	var item_surv := HeldItemEffects.check_survival(defender, damage)
	if item_surv.survived:
		result.survived = true
		result.final_damage = defender.current_hp - 1
		result.messages.append(item_surv.message)
		if item_surv.consume:
			HeldItemEffects.consume_item(defender)
		return result

	return result

# -- XP ------------------------------------------------------------------

static func calculate_exp_gain(fainted: PokemonInstance, _winner_level: int) -> int:
	var base_exp: int = fainted.get_base_exp_yield()
	var gained := int(base_exp * fainted.level / 7.0)
	return max(1, gained)

# -- Capture --------------------------------------------------------------

static func try_catch(target: PokemonInstance, ball_bonus: float = 1.0) -> bool:
	var catch_rate: int = target.get_catch_rate()
	var a: float = (3.0 * target.max_hp - 2.0 * target.current_hp) * catch_rate * ball_bonus / (3.0 * target.max_hp)
	a = clampf(a, 0.0, 255.0)
	var status_mult := 1.0
	if target.status in ["sleep", "freeze"]:
		status_mult = 2.0
	elif target.status in ["burn", "paralyze", "poison", "bad_poison"]:
		status_mult = 1.5
	a = minf(a * status_mult, 255.0)
	var p: float = pow(a / 255.0, 0.25)
	return randf() < p

# -- Accuracy -------------------------------------------------------------

static func accuracy_check(
	move: MoveInstance,
	attacker: PokemonInstance,
	defender: PokemonInstance
) -> bool:
	var acc: int = move.get_accuracy()
	if acc == 0:
		return true  # Never-miss move

	var acc_stage: int  = attacker.stat_stages.get("accuracy", 0)
	var eva_stage: int  = defender.stat_stages.get("evasion", 0)

	# Unaware ignores evasion boosts
	if AbilityEffects.ignores_stat_changes(attacker):
		eva_stage = 0

	var net_stage: int  = clampi(acc_stage - eva_stage, -6, 6)

	var mult := 1.0
	if net_stage > 0:
		mult = (3.0 + net_stage) / 3.0
	elif net_stage < 0:
		mult = 3.0 / (3.0 - net_stage)

	# Compound Eyes (+30%)
	if attacker.ability == "compound_eyes":
		mult *= 1.3

	# Hustle (-20% accuracy on physical)
	if attacker.ability == "hustle" and move.get_category() == "physical":
		mult *= 0.8

	# Victory Star (+10%)
	if attacker.ability == "victory_star":
		mult *= 1.1

	# Held item accuracy modifier
	mult *= HeldItemEffects.get_accuracy_multiplier(attacker)

	# Gravity (+67% accuracy, handled via field if implemented)

	return randf() * 100.0 < acc * mult

# -- Effective speed with ability/weather ---------------------------------

static func get_effective_speed(pkmn: PokemonInstance, field: BattleField = null) -> int:
	var spd: int = pkmn.get_effective_stat("speed")
	if field != null:
		spd = int(spd * AbilityEffects.get_speed_multiplier(pkmn, field))
	# Paralysis halves speed (Gen 7+: 50%)
	if pkmn.status == "paralyze" and pkmn.ability != "quick_feet":
		spd = int(spd * 0.5)
	return spd

# -- Recoil calculation ---------------------------------------------------

static func calculate_recoil(damage_dealt: int, recoil_fraction: float) -> int:
	return maxi(1, int(damage_dealt * recoil_fraction))

# -- Drain calculation ----------------------------------------------------

static func calculate_drain(damage_dealt: int, drain_fraction: float) -> int:
	return maxi(1, int(damage_dealt * drain_fraction))
