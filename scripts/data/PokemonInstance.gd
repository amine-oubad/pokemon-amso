class_name PokemonInstance
extends RefCounted
## Instance d'un Pokémon en équipe ou en combat.
## Créer via PokemonInstance.create("025", 5) ou PokemonInstance.from_encounter(data).

# ── Identité ──────────────────────────────────────────────────────────────────
var pokemon_id: String = ""
var nickname: String   = ""
var level: int         = 1
var exp: int           = 0

# ── HP ────────────────────────────────────────────────────────────────────────
var current_hp: int = 0
var max_hp: int     = 0

# ── Stats calculées (permanentes) ─────────────────────────────────────────────
var stats: Dictionary = {
	"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0, "speed": 0
}

# ── Modificateurs de stats (combat uniquement, remis à 0 après) ───────────────
var stat_stages: Dictionary = {
	"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0,
	"speed": 0, "accuracy": 0, "evasion": 0
}

# ── Moves (max 4 MoveInstance) ────────────────────────────────────────────────
var moves: Array = []

# ── Statut ────────────────────────────────────────────────────────────────────
var status: String = ""
var status_turns: int = 0

# ── Divers ────────────────────────────────────────────────────────────────────
var ability: String    = ""
var held_item: String  = ""
var gender: String     = "M"

var _base_data: Dictionary = {}
var ivs: Dictionary = {}  # IVs individuels par stat

# ── Constructeurs ─────────────────────────────────────────────────────────────

static func create(p_id: String, p_level: int) -> PokemonInstance:
	var inst := PokemonInstance.new()
	inst.pokemon_id = p_id
	inst.level      = clampi(p_level, 1, 100)
	inst._base_data = GameData.pokemon_data.get(p_id, {})
	if inst._base_data.is_empty():
		push_error("[PokemonInstance] ID introuvable : " + p_id)
		return inst
	inst.nickname = inst._base_data.get("name", p_id)
	inst.ability  = inst._base_data.get("ability", "")
	inst.exp      = inst._exp_for_level(inst.level)
	inst._generate_ivs()
	inst._calculate_stats()
	inst._learn_levelup_moves()
	return inst

static func from_encounter(enc: Dictionary) -> PokemonInstance:
	var lvl := randi_range(enc.get("level_min", 2), enc.get("level_max", 5))
	return PokemonInstance.create(enc.get("id", "025"), lvl)

# ── XP et Level-up ───────────────────────────────────────────────────────────

## XP nécessaire pour atteindre un niveau (courbe Medium Fast — Gen 3).
func _exp_for_level(lv: int) -> int:
	return lv * lv * lv

## XP restante pour le prochain niveau.
func exp_to_next_level() -> int:
	if level >= 100:
		return 0
	return _exp_for_level(level + 1) - exp

## Ajoute de l'XP et retourne les infos de level-up.
## Retourne : { "levels_gained": int, "new_moves": [move_id, ...], "evolution": "" | pokemon_id }
func gain_exp(amount: int) -> Dictionary:
	var result := { "levels_gained": 0, "new_moves": [], "evolution": "" }
	if level >= 100:
		return result
	exp += amount
	while level < 100 and exp >= _exp_for_level(level + 1):
		_do_level_up(result)
	# Vérifier évolution
	result.evolution = check_evolution()
	return result

func _do_level_up(result: Dictionary) -> void:
	level += 1
	result.levels_gained += 1
	var old_max_hp := max_hp
	_calculate_stats()
	# Soigner la différence de PV max gagnée
	current_hp += max_hp - old_max_hp
	# Vérifier les moves appris à ce niveau
	var levelup: Array = _base_data.get("levelup_moves", [])
	for entry in levelup:
		if entry.get("level", 99) == level:
			var move_id: String = entry.get("move", "")
			if move_id != "" and not _has_move(move_id):
				result.new_moves.append(move_id)

func _has_move(move_id: String) -> bool:
	for mv in moves:
		if mv.move_id == move_id:
			return true
	return false

## Apprend un nouveau move. Si < 4 moves, l'ajoute directement.
## Sinon, remplace le move à l'index donné. Retourne true si appris.
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

# ── Évolution ─────────────────────────────────────────────────────────────────

## Vérifie si le Pokémon peut évoluer (par niveau). Retourne l'ID cible ou "".
func check_evolution() -> String:
	var evolutions: Array = _base_data.get("evolutions", [])
	for evo in evolutions:
		if evo.get("method", "") == "level" and level >= evo.get("level", 999):
			# Support both "into" and "target" keys for evolution target
			var target_id: String = evo.get("into", evo.get("target", ""))
			if target_id != "" and GameData.pokemon_data.has(target_id):
				return target_id
	return ""

## Effectue l'évolution vers un nouveau Pokémon.
func evolve(target_id: String) -> void:
	var old_name := get_name()
	var had_custom_nickname := nickname != _base_data.get("name", "")
	pokemon_id = target_id
	_base_data = GameData.pokemon_data.get(target_id, _base_data)
	ability = _base_data.get("ability", ability)
	# Garder le surnom seulement s'il était personnalisé
	if not had_custom_nickname:
		nickname = _base_data.get("name", target_id)
	_calculate_stats()
	# Apprendre les moves de la forme évoluée au niveau courant
	var levelup: Array = _base_data.get("levelup_moves", [])
	for entry in levelup:
		if entry.get("level", 99) <= level:
			var move_id: String = entry.get("move", "")
			if move_id != "" and not _has_move(move_id) and moves.size() < 4:
				moves.append(MoveInstance.create(move_id))

# ── Calcul des stats (formule Gen 3) ──────────────────────────────────────────

func _generate_ivs() -> void:
	if ivs.is_empty():
		for s in ["hp", "atk", "def", "sp_atk", "sp_def", "speed"]:
			ivs[s] = randi_range(0, 31)

func _calculate_stats() -> void:
	var base: Dictionary = _base_data.get("base_stats", {})
	var old_max := max_hp
	var hp_iv: int = ivs.get("hp", 15)
	max_hp = int((2 * base.get("hp", 45) + hp_iv) * level / 100.0) + level + 10
	if old_max == 0:
		current_hp = max_hp  # première initialisation
	for s in ["atk", "def", "sp_atk", "sp_def", "speed"]:
		var iv: int = ivs.get(s, 15)
		stats[s] = int((2 * base.get(s, 50) + iv) * level / 100.0) + 5

# ── Moves appris au niveau courant ────────────────────────────────────────────

func _learn_levelup_moves() -> void:
	var levelup: Array = _base_data.get("levelup_moves", [])
	var learnable: Array = []
	for entry in levelup:
		if entry.get("level", 99) <= level:
			learnable.append(entry.get("move", ""))
	var start := max(0, learnable.size() - 4)
	moves.clear()
	for i in range(start, learnable.size()):
		moves.append(MoveInstance.create(learnable[i]))

# ── Accesseurs ────────────────────────────────────────────────────────────────

func get_name() -> String:
	if nickname != "" and nickname != _base_data.get("name", ""):
		return nickname
	return _base_data.get("name", pokemon_id)

func get_types() -> Array:
	return _base_data.get("types", ["Normal"])

func get_catch_rate() -> int:
	return _base_data.get("catch_rate", 45)

func get_base_exp_yield() -> int:
	return _base_data.get("base_exp_yield", 64)

func get_effective_stat(stat_name: String) -> int:
	var base_val: int = stats.get(stat_name, 1)
	var stage: int    = stat_stages.get(stat_name, 0)
	var mult := 1.0
	if stage > 0:
		mult = (2.0 + stage) / 2.0
	elif stage < 0:
		mult = 2.0 / (2.0 - stage)
	return max(1, int(base_val * mult))

# ── État en combat ────────────────────────────────────────────────────────────

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
	for mv in moves:
		mv.restore_pp()

func modify_stat_stage(stat_name: String, delta: int) -> int:
	var old: int = stat_stages.get(stat_name, 0)
	stat_stages[stat_name] = clampi(old + delta, -6, 6)
	return stat_stages[stat_name] - old

func reset_stat_stages() -> void:
	for k in stat_stages:
		stat_stages[k] = 0

# ── Sérialisation (sauvegarde) ────────────────────────────────────────────────

func to_dict() -> Dictionary:
	var move_dicts := []
	for mv in moves:
		move_dicts.append(mv.to_dict())
	return {
		"pokemon_id": pokemon_id,
		"nickname":   nickname,
		"level":      level,
		"exp":        exp,
		"current_hp": current_hp,
		"status":     status,
		"held_item":  held_item,
		"moves":      move_dicts,
		"ivs":        ivs
	}

static func from_dict(d: Dictionary) -> PokemonInstance:
	var inst := PokemonInstance.create(d.get("pokemon_id", "001"), d.get("level", 1))
	# Restaurer les IVs sauvegardés (sinon garder ceux générés par create)
	var saved_ivs: Dictionary = d.get("ivs", {})
	if not saved_ivs.is_empty():
		inst.ivs = saved_ivs
		inst._calculate_stats()
	inst.nickname   = d.get("nickname", inst.nickname)
	inst.exp        = d.get("exp", 0)
	inst.current_hp = d.get("current_hp", inst.max_hp)
	inst.status     = d.get("status", "")
	inst.held_item  = d.get("held_item", "")
	inst.moves.clear()
	for md in d.get("moves", []):
		inst.moves.append(MoveInstance.from_dict(md))
	return inst
