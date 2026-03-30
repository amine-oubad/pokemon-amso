class_name WildEncounterZone
extends Area2D
## Zone d'herbes hautes — déclenche des rencontres sauvages au fil des pas.
##
## Placer ce nœud dans la scène de map avec :
##   - un CollisionShape2D enfant qui définit la zone
##   - map_id et zone_id correspondant à data/encounters/<map_id>.json

@export var map_id: String   = "test_map"
@export var zone_id: String  = "grass_01"
@export_range(0.0, 1.0) var encounter_rate: float = 0.15  # chance par pas

var _player_inside: bool = false

func _ready() -> void:
	add_to_group("wild_encounter")
	# Détecter entrée / sortie du joueur dans la zone
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Vérifier à chaque pas si une rencontre se déclenche
	EventBus.player_stepped.connect(_on_player_stepped)

func _on_body_entered(body: Node2D) -> void:
	if body.get_script() and body.get_script().get_global_name() == &"Player":
		_player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.get_script() and body.get_script().get_global_name() == &"Player":
		_player_inside = false

func _on_player_stepped(_world_pos: Vector2) -> void:
	if not _player_inside:
		return
	# Repousse : décrémenter et bloquer les rencontres
	if GameState.is_repel_active():
		GameState.tick_repel()
		return
	if randf() > encounter_rate:
		return
	_trigger_encounter()

func _trigger_encounter() -> void:
	var enemy_data: Dictionary = GameData.pick_encounter(map_id, zone_id)
	if enemy_data.is_empty():
		push_warning("[WildEncounterZone] Aucune donnée pour %s / %s" % [map_id, zone_id])
		return
	EventBus.battle_started.emit(enemy_data, false)
