extends Node2D
## Script de la map de test — écoute les signaux de combat.

func _ready() -> void:
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_battle_ended(_result: String) -> void:
	pass  # BattleScene retourne directement ici — rien à faire
