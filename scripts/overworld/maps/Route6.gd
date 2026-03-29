extends Node2D
## ROUTE 6 — Route entre Céladopole et Safrania.
## Layout 480×240 avec deux zones d'herbe.

const MAP_W := 480
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_grass()
	_build_encounter_zones()
	_build_borders()
	_build_trainers()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(24.0, 120.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.22, 0.38, 0.28))

func _build_path() -> void:
	_rect(Vector2(0, 104), Vector2(MAP_W, 32), Color(0.50, 0.42, 0.30))

func _build_grass() -> void:
	_rect(Vector2(48, 0), Vector2(160, 104), Color(0.18, 0.35, 0.20))
	_rect(Vector2(48, 136), Vector2(160, 104), Color(0.18, 0.35, 0.20))
	_rect(Vector2(270, 0), Vector2(160, 104), Color(0.15, 0.30, 0.18))
	_rect(Vector2(270, 136), Vector2(160, 104), Color(0.15, 0.30, 0.18))
	_grass_label(Vector2(90, 30), "~HERBES~")
	_grass_label(Vector2(310, 30), "~HERBES~")

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	_wall(Vector2(MAP_W * 0.5, MAP_H + 8.0), Vector2(MAP_W + 16.0, 16.0))

func _build_trainers() -> void:
	_trainer(Vector2(160.0, 120.0), "route6_psychic",    Color(0.60, 0.30, 0.70))
	_trainer(Vector2(340.0, 120.0), "route6_channeler",  Color(0.50, 0.25, 0.60))
	# Rival Bleu — avant Safrania
	_trainer(Vector2(430.0, 120.0), "rival_safrania",    Color(0.20, 0.30, 0.80))

func _build_signs() -> void:
	_sign(Vector2(48.0, 120.0), "sign_route6")

func _build_transitions() -> void:
	# Ouest → Céladopole
	_transition(Vector2(-8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Celadopole.tscn", Vector2(304.0, 120.0))
	# Est → Safrania
	_transition(Vector2(MAP_W + 8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/SafraniaCity.tscn", Vector2(16.0, 120.0))

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

func _build_encounter_zones() -> void:
	_encounter_zone(Vector2(128.0, 120.0), Vector2(160.0, 240.0), "route6", "grass_01", 0.15)
	_encounter_zone(Vector2(350.0, 120.0), Vector2(160.0, 240.0), "route6", "grass_02", 0.15)

func _connect_signals() -> void:
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle   = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene  = "res://scenes/overworld/maps/Route6.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/Route6.tscn"
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
func _transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var t := MapTransition.new(); t.position = center; t.target_scene = target; t.spawn_position = spawn
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	t.add_child(cs); add_child(t)
func _encounter_zone(center: Vector2, shape_size: Vector2, map_id: String, zone_id: String, rate: float) -> void:
	var zone := WildEncounterZone.new(); zone.position = center; zone.map_id = map_id; zone.zone_id = zone_id; zone.encounter_rate = rate
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	zone.add_child(cs); add_child(zone)
func _grass_label(pos: Vector2, text: String) -> void:
	var lbl := Label.new(); lbl.text = text; lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 5)
	lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8, 0.7))
	add_child(lbl)
