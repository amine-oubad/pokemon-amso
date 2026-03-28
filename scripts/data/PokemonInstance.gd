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
## Valeurs : -6 à +6. Multiplicateurs Gen 3 : stage>0 → (2+stage)/2 ; stage<0 → 2/(2-stage)
var stat_stages: Dictionary = {
	"atk": 0, "def": 0, "sp_atk": 0, "sp_def": 0,
	"speed": 0, "accuracy": 0, "evasion": 0
}

# ── Moves (max 4 MoveInstance) ────────────────────────────────────────────────
var moves: Array = []

# ── Statut (Phase 2) ──────────────────────────────────────────────────────────
var status: String = ""        # "burn" | "paralyze" | "sleep" | "freeze" | "poison" | "bad_poison"
var status_turns: int = 0

# ── Divers ────────────────────────────────────────────────────────────────────
var ability: String    = ""
var held_item: String  = ""
var gender: String     = "M"

var _base_data: Dictionary = {}

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
	inst._calculate_stats()
	inst._learn_levelup_moves()
	return inst

## Crée un Pokémon sauvage depuis une entrée d'encounter table.
static func from_encounter(enc: Dictionary) -> PokemonInstance:
	var lvl := randi_range(
		enc.get("level_min", 2),
		enc.get("level_max", 5)
	)
	return PokemonInstance.create(enc.get("id", "025"), lvl)

# ── Calcul des stats (formule Gen 3) ──────────────────────────────────────────
## IV fixe à 15 (valeur moyenne), EVs = 0 pour les sauvages.
## HP  : floor((2*base + iv) * level / 100) + level + 10
## Stat: floor((2*base + iv) * level / 100) + 5
func _calculate_stats() -> void:
	var base: Dictionary = _base_data.get("base_stats", {})
	const IV := 15

	max_hp = int((2 * base.get("hp", 45) + IV) * level / 100.0) + level + 10
	current_hp = max_hp

	for s in ["atk", "def", "sp_atk", "sp_def", "speed"]:
		stats[s] = int((2 * base.get(s, 50) + IV) * level / 100.0) + 5

# ── Moves appris au niveau courant ────────────────────────────────────────────
func _learn_levelup_moves() -> void:
	var levelup: Array = _base_data.get("levelup_moves", [])
	var learnable: Array = []
	for entry in levelup:
		if entry.get("level", 99) <= level:
			learnable.append(entry.get("move", ""))
	# Garde les 4 derniers moves apprenables
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

## Stat effective avec modificateurs de stage appliqués.
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
	return stat_stages[stat_name] - old  # changement réel appliqué

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
		"moves":      move_dicts
	}

static func from_dict(d: Dictionary) -> PokemonInstance:
	var inst := PokemonInstance.create(d.get("pokemon_id", "001"), d.get("level", 1))
	inst.nickname   = d.get("nickname", inst.nickname)
	inst.exp        = d.get("exp", 0)
	inst.current_hp = d.get("current_hp", inst.max_hp)
	inst.status     = d.get("status", "")
	inst.held_item  = d.get("held_item", "")
	inst.moves.clear()
	for md in d.get("moves", []):
		inst.moves.append(MoveInstance.from_dict(md))
	return inst
