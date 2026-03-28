extends Node2D
## ROUTE 2 — entre Jadielle City et la Forêt de Jade.
## Layout 320×240 : herbes, chemin central, dresseurs.

const MAP_W := 320
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_decorations()
	_build_borders()
	_build_encounter_zones()
	_build_trainers()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(160.0, 208.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.22, 0.48, 0.15))

func _build_path() -> void:
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.58, 0.48, 0.30))

func _build_decorations() -> void:
	_rect(Vector2(16.0, 48.0), Vector2(112.0, 80.0), Color(0.15, 0.38, 0.10))
	_rect(Vector2(192.0, 96.0), Vector2(112.0, 80.0), Color(0.15, 0.38, 0.10))
	_rect(Vector2(0.0, 0.0), Vector2(16.0, 48.0), Color(0.10, 0.32, 0.08))
	_rect(Vector2(304.0, 0.0), Vector2(16.0, 48.0), Color(0.10, 0.32, 0.08))
	_rect(Vector2(0.0, 208.0), Vector2(48.0, 32.0), Color(0.10, 0.32, 0.08))
	_rect(Vector2(272.0, 208.0), Vector2(48.0, 32.0), Color(0.10, 0.32, 0.08))
	var lbl_s := Label.new()
	lbl_s.text = "↓ Jadielle City"
	lbl_s.position = Vector2(80.0, 222.0)
	lbl_s.add_theme_font_size_override("font_size", 6)
	lbl_s.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl_s)
	var lbl_n := Label.new()
	lbl_n.text = "↑ Forêt de Jade"
	lbl_n.position = Vector2(80.0, 4.0)
	lbl_n.add_theme_font_size_override("font_size", 6)
	lbl_n.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl_n)

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(72.0, -8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, -8.0), Vector2(144.0, 16.0))
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_encounter_zones() -> void:
	_encounter_zone(Vector2(72.0, 88.0), Vector2(112.0, 80.0), "route2", "grass_01", 0.15)
	_encounter_zone(Vector2(248.0, 136.0), Vector2(112.0, 80.0), "route2", "grass_02", 0.15)

func _build_trainers() -> void:
	_trainer(Vector2(160.0, 128.0), "route2_bug_catcher", Color(0.40, 0.60, 0.20))
	_trainer(Vector2(192.0, 64.0), "route2_lass", Color(0.70, 0.45, 0.55))

func _build_signs() -> void:
	_sign(Vector2(128.0, 208.0), "sign_route2_south")
	_sign(Vector2(128.0, 32.0), "sign_route2_north")

func _build_transitions() -> void:
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160.0, 16.0))
	_transition(Vector2(160.0, -8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ViridianForest.tscn", Vector2(160.0, 208.0))

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
	GameState.return_to_scene = "res://scenes/overworld/maps/Route2.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/Route2.tscn"
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
