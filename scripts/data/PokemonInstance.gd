class_name PokemonInstance
extends RefCounted
## Instance d'un Pokemon en equipe ou en combat.
## Creer via PokemonInstance.create("025", 5) ou PokemonInstance.from_encounter(data).


# -- Identite -------------------------------------------------------------
var pokemon_id: String = ""
var nickname: String   = ""
var level: int         = 1
var exp: int           = 0

# -- HP -------------------------------------------------------------------
var current_hp: int = 0
var max_hp: int     = 0

# -- Stats calculees (permanentes) ----------------------------------------
var stats: Dictionary = {
	"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0
}

# -- Modificateurs de stats (combat uniquement, remis a 0 apres) ----------
var stat_stages: Dictionary = {
	"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0,
	"speed": 0, "accuracy": 0, "evasion": 0
}

# -- Moves (max 4 MoveInstance) -------------------------------------------
var moves: Array = []

# -- Statut ---------------------------------------------------------------
var status: String = ""
var status_turns: int = 0

# -- Nature ---------------------------------------------------------------
var nature: String = ""

# -- IVs et EVs -----------------------------------------------------------
var ivs: Dictionary = {}
var evs: Dictionary = {"hp": 0, "atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0}

# -- Ability & Item -------------------------------------------------------
var ability: String    = ""
var held_item: String  = ""
var gender: String     = "M"

# -- Donnees de base (cache) ----------------------------------------------
var _base_data: Dictionary = {}

# -- Battle meta (flinch, leech_seed, protect, charging, etc.) ------------
var _meta: Dictionary = {}

func has_bmeta(key: String) -> bool:
	return _meta.has(key)

func set_bmeta(key: String, value: Variant) -> void:
	_meta[key] = value

func get_bmeta(key: String, default: Variant = null) -> Variant:
	return _meta.get(key, default)

func remove_bmeta(key: String) -> void:
	_meta.erase(key)

# =========================================================================
#  NATURES (25 natures)
# =========================================================================

## {nature_name: {plus: stat_boosted, minus: stat_lowered}}
## 5 natures neutres n'ont pas de plus/minus.
const NATURES := {
	"hardy":   {},
	"lonely":  {"plus": "atk",    "minus": "def"},
	"brave":   {"plus": "atk",    "minus": "speed"},
	"adamant": {"plus": "atk",    "minus": "sp_atk"},
	"naughty": {"plus": "atk",    "minus": "sp_def"},
	"bold":    {"plus": "def",    "minus": "atk"},
	"docile":  {},
	"relaxed": {"plus": "def",    "minus": "speed"},
	"impish":  {"plus": "def",    "minus": "sp_atk"},
	"lax":     {"plus": "def",    "minus": "sp_def"},
	"timid":   {"plus": "speed",  "minus": "atk"},
	"hasty":   {"plus": "speed",  "minus": "def"},
	"serious": {},
	"jolly":   {"plus": "speed",  "minus": "sp_atk"},
	"naive":   {"plus": "speed",  "minus": "sp_def"},
	"modest":  {"plus": "sp_atk", "minus": "atk"},
	"mild":    {"plus": "sp_atk", "minus": "def"},
	"quiet":   {"plus": "sp_atk", "minus": "speed"},
	"bashful": {},
	"rash":    {"plus": "sp_atk", "minus": "sp_def"},
	"calm":    {"plus": "sp_def", "minus": "atk"},
	"gentle":  {"plus": "sp_def", "minus": "def"},
	"sassy":   {"plus": "sp_def", "minus": "speed"},
	"quirky":  {},
	"careful": {"plus": "sp_def", "minus": "sp_atk"},
}

const NATURE_NAMES_FR := {
	"hardy": "Hardi", "lonely": "Solo", "brave": "Brave", "adamant": "Rigide",
	"naughty": "Mauvais", "bold": "Assure", "docile": "Docile", "relaxed": "Relax",
	"impish": "Malin", "lax": "Lache", "timid": "Timide", "hasty": "Presse",
	"serious": "Serieux", "jolly": "Jovial", "naive": "Naif", "modest": "Modeste",
	"mild": "Doux", "quiet": "Discret", "bashful": "Pudique", "rash": "Foufou",
	"calm": "Calme", "gentle": "Gentil", "sassy": "Malpoli", "quirky": "Bizarre",
	"careful": "Prudent",
}

func get_nature_name() -> String:
	return NATURE_NAMES_FR.get(nature, nature.capitalize())

## Multiplicateur de nature pour une stat donnee (1.0, 1.1 ou 0.9).
func get_nature_multiplier(stat: String) -> float:
	var n: Dictionary = NATURES.get(nature, {})
	if n.is_empty():
		return 1.0
	if n.get("plus", "") == stat:
		return 1.1
	if n.get("minus", "") == stat:
		return 0.9
	return 1.0

# =========================================================================
#  CONSTRUCTEURS
# =========================================================================

static func create(p_id: String, p_level: int) :
	var inst = (load("res://scripts/data/PokemonInstance.gd") as GDScript).new()
	inst.pokemon_id = p_id
	inst.level      = clampi(p_level, 1, 100)
	inst._base_data = GameData.pokemon_data.get(p_id, {})
	if inst._base_data.is_empty():
		push_error("[PokemonInstance] ID introuvable : " + p_id)
		inst.nickname = p_id
		inst.max_hp = 1
		inst.current_hp = 1
		return inst
	inst.nickname = inst._base_data.get("name", p_id)
	inst.ability  = inst._base_data.get("ability", "")
	inst.exp      = inst._exp_for_level(inst.level)
	inst._generate_ivs()
	inst._generate_nature()
	inst._calculate_stats()
	inst._learn_levelup_moves()
	return inst

static func create_with_details(p_id: String, p_level: int, p_nature: String = "",
		p_ability: String = "", p_held_item: String = "",
		p_evs: Dictionary = {}, p_moves: Array = []) :
	var inst = (load("res://scripts/data/PokemonInstance.gd") as GDScript).create(p_id, p_level)
	if p_nature != "":
		inst.nature = p_nature
	if p_ability != "":
		inst.ability = p_ability
	if p_held_item != "":
		inst.held_item = p_held_item
	if not p_evs.is_empty():
		inst.evs = p_evs
	inst._calculate_stats()
	if not p_moves.is_empty():
		inst.moves.clear()
		for mid: String in p_moves:
			inst.moves.append(MoveInstance.create(mid))
	return inst

static func from_encounter(enc: Dictionary) :
	var min_lv: int = enc.get("level_min", 2)
	var max_lv: int = enc.get("level_max", 5)
	var lvl := randi_range(min_lv, max_lv)
	var enc_id: String = enc.get("id", "025")
	return (load("res://scripts/data/PokemonInstance.gd") as GDScript).create(enc_id, lvl)

# =========================================================================
#  XP et Level-up
# =========================================================================

func _exp_for_level(lv: int) -> int:
	return lv * lv * lv

func exp_to_next_level() -> int:
	if level >= 100:
		return 0
	return _exp_for_level(level + 1) - exp

func gain_exp(amount: int) -> Dictionary:
	var result := { "levels_gained": 0, "new_moves": [], "evolution": "" }
	if level >= 100:
		return result
	exp += amount
	while level < 100 and exp >= _exp_for_level(level + 1):
		_do_level_up(result)
	result.evolution = check_evolution()
	return result

func _do_level_up(result: Dictionary) -> void:
	level += 1
	result.levels_gained += 1
	var old_max_hp := max_hp
	_calculate_stats()
	current_hp += max_hp - old_max_hp
	var levelup: Array = _base_data.get("levelup_moves", [])
	for entry: Dictionary in levelup:
		if entry.get("level", 99) == level:
			var move_id: String = entry.get("move", "")
			if move_id != "" and not _has_move(move_id):
				result.new_moves.append(move_id)

func _has_move(move_id: String) -> bool:
	for mv: MoveInstance in moves:
		if mv.move_id == move_id:
			return true
	return false

func learn_move(move_id: String, replace_idx: int = -1) -> bool:
	if _has_move(move_id):
		return false
	if moves.size() < 4:
		moves.append(MoveInstance.create(move_id))
		return true
	if replace_idx >= 0 and replace_idx < moves.size():
		moves[replace_idx] = MoveInstance.create(move_id)
		return true
	return false

# =========================================================================
#  Evolution
# =========================================================================

func check_evolution() -> String:
	var evolutions: Array = _base_data.get("evolutions", [])
	for evo: Dictionary in evolutions:
		if evo.get("method", "") == "level" and level >= evo.get("level", 999):
			var target_id: String = evo.get("into", "")
			if target_id != "" and GameData.pokemon_data.has(target_id):
				return target_id
	return ""

func evolve(target_id: String) -> void:
	var had_custom_nickname: bool = (nickname != str(_base_data.get("name", "")))
	pokemon_id = target_id
	_base_data = GameData.pokemon_data.get(target_id, _base_data)
	ability = _base_data.get("ability", ability)
	if not had_custom_nickname:
		nickname = _base_data.get("name", target_id)
	_calculate_stats()
	var levelup: Array = _base_data.get("levelup_moves", [])
	for entry: Dictionary in levelup:
		if entry.get("level", 99) <= level:
			var move_id: String = entry.get("move", "")
			if move_id != "" and not _has_move(move_id) and moves.size() < 4:
				moves.append(MoveInstance.create(move_id))

# =========================================================================
#  Calcul des stats (formule Gen 3 avec Nature + EVs)
# =========================================================================

func _generate_ivs() -> void:
	if ivs.is_empty():
		for s: String in ["hp", "atk", "def", "sp_atk", "sp_def", "speed"]:
			ivs[s] = randi_range(0, 31)

func _generate_nature() -> void:
	if nature == "":
		var keys := NATURES.keys()
		nature = keys[randi() % keys.size()]

func _calculate_stats() -> void:
	var base: Dictionary = _base_data.get("base_stats", {})
	var old_max := max_hp

	# HP = floor((2*Base + IV + floor(EV/4)) * Level / 100) + Level + 10
	var hp_iv: int = ivs.get("hp", 15)
	var hp_ev: int = evs.get("hp", 0)
	max_hp = int((2 * base.get("hp", 45) + hp_iv + int(hp_ev / 4.0)) * level / 100.0) + level + 10
	if old_max == 0:
		current_hp = max_hp

	# Other stats = floor((floor((2*Base + IV + floor(EV/4)) * Level / 100) + 5) * Nature)
	for s: String in ["atk", "def", "sp_atk", "sp_def", "speed"]:
		var iv: int = ivs.get(s, 15)
		var ev: int = evs.get(s, 0)
		var raw := int((2 * base.get(s, 50) + iv + int(ev / 4.0)) * level / 100.0) + 5
		stats[s] = int(raw * get_nature_multiplier(s))

# =========================================================================
#  Moves appris au niveau courant
# =========================================================================

func _learn_levelup_moves() -> void:
	var levelup: Array = _base_data.get("levelup_moves", [])
	var learnable: Array = []
	for entry: Dictionary in levelup:
		if entry.get("level", 99) <= level:
			learnable.append(entry.get("move", ""))
	var start: int = max(0, learnable.size() - 4)
	moves.clear()
	for i in range(start, learnable.size()):
		moves.append(MoveInstance.create(learnable[i]))

# =========================================================================
#  EVs management
# =========================================================================

const MAX_TOTAL_EVS := 510
const MAX_SINGLE_EV := 252

func add_evs(stat: String, amount: int) -> int:
	var total := 0
	for s: String in evs:
		total += int(evs[s])
	var remaining := MAX_TOTAL_EVS - total
	var stat_remaining: int = MAX_SINGLE_EV - int(evs.get(stat, 0))
	var actual: int = mini(amount, mini(remaining, stat_remaining))
	if actual > 0:
		evs[stat] = evs.get(stat, 0) + actual
	return actual

## Applique les EVs gagnes apres avoir battu un Pokemon.
func gain_evs_from(fainted_pkmn: PokemonInstance) -> void:
	var ev_yield: Dictionary = fainted_pkmn._base_data.get("ev_yield", {})
	for stat: String in ev_yield:
		add_evs(stat, int(ev_yield[stat]))

# =========================================================================
#  Accesseurs
# =========================================================================

func get_name() -> String:
	if nickname != "" and nickname != _base_data.get("name", ""):
		return nickname
	return _base_data.get("name", pokemon_id)

func get_types() -> Array:
	# Color Change override
	if has_meta("override_types"):
		return get_meta("override_types")
	return _base_data.get("types", ["Normal"])

func get_catch_rate() -> int:
	return _base_data.get("catch_rate", 45)

func get_base_exp_yield() -> int:
	return _base_data.get("base_exp_yield", 64)

func get_effective_stat(stat_name: String) -> int:
	var base_val: int = stats.get(stat_name, 1)
	var stage: int    = stat_stages.get(stat_name, 0)

	# Stage multiplier
	var mult := 1.0
	if stage > 0:
		mult = (2.0 + stage) / 2.0
	elif stage < 0:
		mult = 2.0 / (2.0 - stage)

	var result: int = max(1, int(base_val * mult))

	# Ability modifiers
	match ability:
		"huge_power", "pure_power":
			if stat_name == "atk": result *= 2
		"hustle":
			if stat_name == "atk": result = int(result * 1.5)
		"guts":
			if stat_name == "atk" and status != "": result = int(result * 1.5)
		"marvel_scale":
			if stat_name == "def" and status != "": result = int(result * 1.5)

	# Held item stat modifiers
	if held_item != "":
		var _hie: GDScript = load("res://scripts/battle/HeldItemEffects.gd")
		result = int(result * _hie.get_stat_multiplier(self, stat_name))

	# Paralysis halves Speed (Gen 3)
	if stat_name == "speed" and status == "paralyze":
		# Guts doesn't prevent the speed drop from paralysis
		result = maxi(1, int(result * 0.5))

	# Burn halves Attack (unless Guts)
	if stat_name == "atk" and status == "burn" and ability != "guts":
		result = maxi(1, int(result * 0.5))

	return maxi(1, result)

func get_ability_name() -> String:
	var _ae: GDScript = load("res://scripts/battle/AbilityEffects.gd")
	return _ae.get_ability_name(ability)

func get_held_item_name() -> String:
	var _hie2: GDScript = load("res://scripts/battle/HeldItemEffects.gd")
	return _hie2.get_item_name(held_item)

# =========================================================================
#  Etat en combat
# =========================================================================

func is_fainted() -> bool:
	return current_hp <= 0

func take_damage(amount: int) -> int:
	var actual := mini(amount, current_hp)
	current_hp -= actual
	return actual

func heal(amount: int) -> int:
	var actual := mini(amount, max_hp - current_hp)
	current_hp += actual
	return actual

func full_heal() -> void:
	current_hp = max_hp
	status = ""
	status_turns = 0
	for mv: MoveInstance in moves:
		mv.restore_pp()

func modify_stat_stage(stat_name: String, delta: int) -> int:
	# Check ability prevention for drops
	var _ae2: GDScript = load("res://scripts/battle/AbilityEffects.gd")
	if delta < 0 and _ae2.prevents_stat_drop(self, stat_name):
		return 0
	var old: int = stat_stages.get(stat_name, 0)
	stat_stages[stat_name] = clampi(old + delta, -6, 6)
	return stat_stages[stat_name] - old

func reset_stat_stages() -> void:
	for k: String in stat_stages:
		stat_stages[k] = 0

func clear_battle_meta() -> void:
	_meta.clear()

# =========================================================================
#  Serialisation (sauvegarde)
# =========================================================================

func to_dict() -> Dictionary:
	var move_dicts: Array = []
	for mv: MoveInstance in moves:
		move_dicts.append(mv.to_dict())
	return {
		"pokemon_id": pokemon_id,
		"nickname":   nickname,
		"level":      level,
		"exp":        exp,
		"current_hp": current_hp,
		"status":     status,
		"held_item":  held_item,
		"ability":    ability,
		"nature":     nature,
		"moves":      move_dicts,
		"ivs":        ivs,
		"evs":        evs,
	}

static func from_dict(d: Dictionary) :
	var inst = (load("res://scripts/data/PokemonInstance.gd") as GDScript).new()
	inst.pokemon_id = d.get("pokemon_id", "001")
	inst.level = d.get("level", 1)
	inst._base_data = GameData.pokemon_data.get(inst.pokemon_id, {})
	inst.nickname = d.get("nickname", inst._base_data.get("name", inst.pokemon_id))
	inst.ability = d.get("ability", inst._base_data.get("ability", ""))
	inst.held_item = d.get("held_item", "")
	inst.nature = d.get("nature", "")
	inst.exp = d.get("exp", 0)

	# Restore IVs
	var saved_ivs: Dictionary = d.get("ivs", {})
	if not saved_ivs.is_empty():
		inst.ivs = saved_ivs
	else:
		inst._generate_ivs()

	# Restore EVs
	var saved_evs: Dictionary = d.get("evs", {})
	if not saved_evs.is_empty():
		inst.evs = saved_evs

	if inst.nature == "":
		inst._generate_nature()

	inst._calculate_stats()
	inst.current_hp = d.get("current_hp", inst.max_hp)
	inst.status = d.get("status", "")

	inst.moves.clear()
	var saved_moves: Array = d.get("moves", [])
	for md: Dictionary in saved_moves:
		inst.moves.append(MoveInstance.from_dict(md))

	# If no moves loaded, learn default
	if inst.moves.is_empty():
		inst._learn_levelup_moves()

	return inst
