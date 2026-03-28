extends Node2D
## FORÊT DE JADE (Viridian Forest) — zone dense entre Route 2 et Argenta City.
## Layout 320×320 (plus grand) : arbres denses, 2 zones d'herbes, dresseurs insectes.

const MAP_W := 320
const MAP_H := 320
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_decorations()
	_build_borders()
	_build_encounter_zones()
	_build_trainers()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(160.0, 288.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.12, 0.35, 0.08))

func _build_decorations() -> void:
	# Chemin sinueux
	_rect(Vector2(144, 240), Vector2(32, 80), Color(0.45, 0.38, 0.22))
	_rect(Vector2(80, 160), Vector2(96, 32), Color(0.45, 0.38, 0.22))
	_rect(Vector2(80, 80), Vector2(32, 112), Color(0.45, 0.38, 0.22))
	_rect(Vector2(80, 80), Vector2(128, 32), Color(0.45, 0.38, 0.22))
	_rect(Vector2(176, 0), Vector2(32, 112), Color(0.45, 0.38, 0.22))
	# Arbres denses (obstacles visuels)
	for x in range(0, MAP_W, 48):
		_rect(Vector2(x, 0), Vector2(16, 16), Color(0.08, 0.28, 0.05))
		_rect(Vector2(x, MAP_H - 16), Vector2(16, 16), Color(0.08, 0.28, 0.05))
	# Herbes hautes visuelles
	_rect(Vector2(192.0, 160.0), Vector2(96.0, 96.0), Color(0.10, 0.30, 0.06))
	_rect(Vector2(16.0, 200.0), Vector2(96.0, 64.0), Color(0.10, 0.30, 0.06))
	# Label
	var title := Label.new()
	title.text = "FORÊT DE JADE"
	title.position = Vector2(110.0, 4.0)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color(0.70, 0.90, 0.50))
	add_child(title)

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	# Haut — trou pour sortie nord
	_wall(Vector2(88.0, -8.0), Vector2(176.0, 16.0))
	_wall(Vector2(264.0, -8.0), Vector2(112.0, 16.0))
	# Bas — trou pour sortie sud
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_encounter_zones() -> void:
	_encounter_zone(Vector2(240.0, 208.0), Vector2(96.0, 96.0), "viridian_forest", "forest_01", 0.20)
	_encounter_zone(Vector2(64.0, 232.0), Vector2(96.0, 64.0), "viridian_forest", "forest_02", 0.20)

func _build_trainers() -> void:
	_trainer(Vector2(128.0, 192.0), "forest_bug1", Color(0.35, 0.55, 0.20))
	_trainer(Vector2(96.0, 112.0), "forest_bug2", Color(0.30, 0.50, 0.18))
	_trainer(Vector2(192.0, 64.0), "forest_bug3", Color(0.40, 0.60, 0.25))

func _build_signs() -> void:
	_sign(Vector2(128.0, 288.0), "sign_forest_south")
	_sign(Vector2(208.0, 32.0), "sign_forest_north")

func _build_transitions() -> void:
	# Sud → Route 2
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/Route2.tscn", Vector2(160.0, 16.0))
	# Nord → Argenta City
	_transition(Vector2(192.0, -8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ArgentaCity.tscn", Vector2(160.0, 224.0))

func _spawn_player(default_pos: Vector2) -> void:
	var scene := preload("res://scenes/overworld/entities/Player.tscn")
	var player := scene.instantiate()
	if GameState.pending_spawn_position != Vector2.ZERO:
		player.position = GameState.pending_spawn_position
		GameState.pending_spawn_position = Vector2.ZERO
	else:
		player.position = default_pos
	add_child(player)
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0; cam.limit_top = 0; cam.limit_right = MAP_W; cam.limit_bottom = MAP_H

func _connect_signals() -> void:
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene = "res://scenes/overworld/maps/ViridianForest.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/ViridianForest.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new(); r.position = pos; r.size = size; r.color = color; add_child(r)
func _wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.position = center
	var shape := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = size; shape.shape = rs
	body.add_child(shape); add_child(body)
func _trainer(pos: Vector2, trainer_id: String, color: Color) -> void:
	var t := Trainer.new(); t.position = pos; t.trainer_id = trainer_id; t.npc_color = color; add_child(t)
func _sign(pos: Vector2, dialogue_key: String) -> void:
	var s := Sign.new(); s.position = pos; s.dialogue_key = dialogue_key; add_child(s)
func _encounter_zone(center: Vector2, shape_size: Vector2, map_id: String, zone_id: String, rate: float) -> void:
	var zone := WildEncounterZone.new(); zone.position = center; zone.map_id = map_id; zone.zone_id = zone_id; zone.encounter_rate = rate
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	zone.add_child(cs); add_child(zone)
func _transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var t := MapTransition.new(); t.position = center; t.target_scene = target; t.spawn_position = spawn
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	t.add_child(cs); add_child(t)
