class_name MoveInstance
extends RefCounted
## Instance d'un move en équipe — conserve les PP courants.
## Créer via MoveInstance.create("tackle").

var move_id: String = ""
var current_pp: int = 0
var max_pp: int = 0

var _data: Dictionary = {}

# ── Constructeur ───────────────────────────────────────────────────────────────

static func create(p_move_id: String) -> MoveInstance:
	var inst := MoveInstance.new()
	inst.move_id = p_move_id
	inst._data = GameData.moves_data.get(p_move_id, {}) as Dictionary
	if inst._data.is_empty():
		push_error("[MoveInstance] Move introuvable : " + p_move_id)
	var base_pp: int = inst._data.get("pp", 10)
	inst.max_pp = base_pp
	inst.current_pp = base_pp
	return inst

# ── Accesseurs (lecture seule depuis les données statiques) ───────────────────

func get_name() -> String:
	return _data.get("name", move_id)

func get_type() -> String:
	return _data.get("type", "Normal")

func get_category() -> String:
	return _data.get("category", "physical")  # "physical" | "special" | "status"

func get_power() -> int:
	return _data.get("power", 0)

func get_accuracy() -> int:
	return _data.get("accuracy", 100)

func get_priority() -> int:
	return _data.get("priority", 0)

func get_effect() -> String:
	return _data.get("effect", "")

func get_effect_chance() -> int:
	return _data.get("effect_chance", 0)

func get_flags() -> Array:
	return _data.get("flags", [])

func has_flag(flag: String) -> bool:
	return flag in get_flags()

# ── État ──────────────────────────────────────────────────────────────────────

func is_usable() -> bool:
	return current_pp > 0

func use() -> void:
	current_pp = max(0, current_pp - 1)

func restore_pp(amount: int = -1) -> void:
	if amount < 0:
		current_pp = max_pp
	else:
		current_pp = min(max_pp, current_pp + amount)

func to_dict() -> Dictionary:
	return { "move_id": move_id, "current_pp": current_pp, "max_pp": max_pp }

static func from_dict(d: Dictionary) -> MoveInstance:
	var inst := MoveInstance.create(d.get("move_id", ""))
	inst.current_pp = d.get("current_pp", inst.max_pp)
	inst.max_pp     = d.get("max_pp",     inst.max_pp)
	return inst
