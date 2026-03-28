extends Node
## Singleton — charge toutes les données JSON au démarrage.
## Accès : GameData.pokemon_data["001"]
##         GameData.moves_data["tackle"]
##         GameData.get_type_effectiveness("Fire", "Grass") → 2.0

var pokemon_data: Dictionary = {}
var moves_data: Dictionary = {}
var type_chart: Dictionary = {}
var items_data: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	pokemon_data = _load_json("res://data/pokemon.json")
	moves_data   = _load_json("res://data/moves.json")
	type_chart   = _load_json("res://data/type_chart.json")

	print("[GameData] %d pokemon | %d moves | %d types chargés" % [
		pokemon_data.size(), moves_data.size(), type_chart.size()
	])

## Renvoie le multiplicateur d'efficacité de type.
## Convention : type_chart[attaquant][défenseur] = multiplicateur
## Valeurs possibles : 0.0 (immunité), 0.5 (peu efficace), 1.0 (normal), 2.0 (super efficace)
func get_type_effectiveness(attacking: String, defending: String) -> float:
	if type_chart.has(attacking) and type_chart[attacking].has(defending):
		return float(type_chart[attacking][defending])
	return 1.0

## Calcule l'efficacité totale contre un Pokémon à double type.
func get_total_effectiveness(attacking: String, defending_types: Array) -> float:
	var total := 1.0
	for def_type in defending_types:
		total *= get_type_effectiveness(attacking, def_type)
	return total

# ── Chargement ─────────────────────────────────────────────────────────────────

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
