extends Node
## Singleton — charge toutes les données JSON au démarrage.
## Accès : GameData.pokemon_data["001"]
##         GameData.moves_data["tackle"]
##         GameData.get_type_effectiveness("Fire", "Grass") → 2.0
##         GameData.pick_encounter("test_map", "grass_01") → { id, level_min, level_max, weight }

var pokemon_data: Dictionary   = {}
var moves_data: Dictionary     = {}
var type_chart: Dictionary     = {}
var items_data: Dictionary     = {}
var encounters_data: Dictionary = {}  # { map_id: { zone_id: [ {...}, ... ] } }

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	pokemon_data = _load_json("res://data/pokemon.json")
	moves_data   = _load_json("res://data/moves.json")
	type_chart   = _load_json("res://data/type_chart.json")
	items_data   = _load_json("res://data/items.json")
	_load_encounters()

	print("[GameData] %d pokémon | %d moves | %d types | %d items | %d maps encounters" % [
		pokemon_data.size(), moves_data.size(),
		type_chart.size(), items_data.size(), encounters_data.size()
	])

func _load_encounters() -> void:
	var path := "res://data/encounters/"
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("[GameData] Dossier encounters/ introuvable")
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".json"):
			var map_id := fname.replace(".json", "")
			encounters_data[map_id] = _load_json(path + fname)
		fname = dir.get_next()

# ── API publique ───────────────────────────────────────────────────────────────

## Multiplicateur de type : attaquant → défenseur (valeur manquante = 1.0 neutre).
func get_type_effectiveness(attacking: String, defending: String) -> float:
	if type_chart.has(attacking) and type_chart[attacking].has(defending):
		return float(type_chart[attacking][defending])
	return 1.0

## Efficacité totale contre un Pokémon à double type.
func get_total_effectiveness(attacking: String, defending_types: Array) -> float:
	var total := 1.0
	for def_type in defending_types:
		total *= get_type_effectiveness(attacking, def_type)
	return total

## Tire un Pokémon aléatoire dans la table de rencontres (weighted random).
func pick_encounter(map_id: String, zone_id: String) -> Dictionary:
	var map_enc: Dictionary = encounters_data.get(map_id, {})
	var zone: Array         = map_enc.get(zone_id, [])
	if zone.is_empty():
		return {}
	var total := 0
	for entry in zone:
		total += entry.get("weight", 10)
	var roll := randi() % total
	var cumul := 0
	for entry in zone:
		cumul += entry.get("weight", 10)
		if roll < cumul:
			return entry
	return zone[-1]

# ── Chargement interne ────────────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[GameData] Fichier introuvable : " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("[GameData] Erreur JSON dans %s (ligne %d) : %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return {}
	return json.data
