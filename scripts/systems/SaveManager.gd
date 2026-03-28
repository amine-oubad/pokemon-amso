extends Node
## Sauvegarde et chargement de partie — 3 slots, format JSON.
## Usage : SaveManager.save(0)  |  SaveManager.load_slot(0)  |  SaveManager.has_save(0)

const SAVE_DIR  := "user://saves/"
const SAVE_EXT  := ".json"
const NUM_SLOTS := 3

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

# ── API publique ───────────────────────────────────────────────────────────────

func save(slot: int) -> bool:
	assert(slot >= 0 and slot < NUM_SLOTS, "Slot invalide : %d" % slot)
	var data := _build_save_data()
	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Écriture impossible : " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveManager] Sauvegarde → slot %d" % slot)
	EventBus.save_requested.emit()
	return true

func load_slot(slot: int) -> bool:
	assert(slot >= 0 and slot < NUM_SLOTS, "Slot invalide : %d" % slot)
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] Slot %d vide." % slot)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("[SaveManager] Parsing impossible — slot %d" % slot)
		return false
	_apply_save_data(json.data)
	print("[SaveManager] Chargement ← slot %d" % slot)
	return true

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func get_save_info(slot: int) -> Dictionary:
	## Retourne les métadonnées d'une sauvegarde sans tout charger.
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	file.close()
	var d: Dictionary = json.data
	return {
		"player_name": d.get("player_name", "?"),
		"badges":      d.get("badges", []).size(),
		"timestamp":   d.get("timestamp", 0),
		"team_size":   d.get("team", []).size(),
	}

func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveManager] Slot %d supprimé." % slot)

# ── Sérialisation ──────────────────────────────────────────────────────────────

func _build_save_data() -> Dictionary:
	var team_data: Array = []
	for pkmn in GameState.team:
		team_data.append(pkmn.to_dict())
	var pc_data: Array = []
	for pkmn in GameState.pc_boxes:
		pc_data.append(pkmn.to_dict())
	return {
		"version":            2,
		"timestamp":          Time.get_unix_time_from_system(),
		"player_name":        GameState.player_name,
		"money":              GameState.money,
		"badges":             GameState.badges,
		"flags":              GameState.flags,
		"bag":                GameState.bag,
		"defeated_trainers":  GameState.defeated_trainers,
		"pokedex_seen":       GameState.pokedex_seen,
		"pokedex_caught":     GameState.pokedex_caught,
		"team":               team_data,
		"pc_boxes":           pc_data,
		"return_to_scene":    GameState.return_to_scene,
		"spawn_position":     [GameState.pending_spawn_position.x, GameState.pending_spawn_position.y],
	}

func _apply_save_data(d: Dictionary) -> void:
	GameState.player_name       = d.get("player_name",       "RED")
	GameState.money             = d.get("money",             3000)
	GameState.badges            = d.get("badges",            [])
	GameState.flags             = d.get("flags",             {})
	GameState.bag               = d.get("bag",               {})
	GameState.defeated_trainers = d.get("defeated_trainers", [])
	GameState.pokedex_seen      = d.get("pokedex_seen",      [])
	GameState.pokedex_caught    = d.get("pokedex_caught",    [])
	GameState.team.clear()
	for td in d.get("team", []):
		GameState.team.append(PokemonInstance.from_dict(td))
	GameState.pc_boxes.clear()
	for pd in d.get("pc_boxes", []):
		GameState.pc_boxes.append(PokemonInstance.from_dict(pd))
	GameState.return_to_scene = d.get("return_to_scene", "res://scenes/overworld/maps/PalletTown.tscn")
	var sp: Array = d.get("spawn_position", [0, 0])
	if sp.size() >= 2:
		GameState.pending_spawn_position = Vector2(sp[0], sp[1])
	else:
		GameState.pending_spawn_position = Vector2.ZERO

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d" % slot + SAVE_EXT
