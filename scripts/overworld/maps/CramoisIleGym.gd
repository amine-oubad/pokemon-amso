extends Node2D
## ARÈNE DE CRAMOIS'ÎLE — type Feu. Champion : Blaine.
## Layout 320×240 : salle volcanique.

const MAP_W := 320
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_arena()
	_build_borders()
	_build_trainers()
	_build_transitions()
	_spawn_player(Vector2(160.0, 208.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.25, 0.08, 0.05))
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.30, 0.12, 0.08))

func _build_arena() -> void:
	# Pools de lave
	_rect(Vector2(16, 80), Vector2(112, 80), Color(0.40, 0.10, 0.05))
	_rect(Vector2(192, 80), Vector2(112, 80), Color(0.40, 0.10, 0.05))
	_wall(Vector2(72, 120), Vector2(112, 80))
	_wall(Vector2(248, 120), Vector2(112, 80))
	# Lave ardente
	_rect(Vector2(40, 100), Vector2(24, 24), Color(0.90, 0.35, 0.10, 0.7))
	_rect(Vector2(240, 100), Vector2(24, 24), Color(0.90, 0.35, 0.10, 0.7))

	_rect(Vector2(100, 16), Vector2(120, 56), Color(0.50, 0.15, 0.08))
	_rect(Vector2(100, 16), Vector2(120, 8), Color(0.38, 0.10, 0.05))

	var title := Label.new()
	title.text     = "ARÈNE CRAMOIS'ÎLE"
	title.position = Vector2(104, 4)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color(1.0, 0.60, 0.20))
	add_child(title)

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_trainers() -> void:
	_trainer(Vector2(144.0, 160.0), "cramoisile_trainer_1", Color(0.70, 0.30, 0.15))
	_trainer(Vector2(176.0, 112.0), "cramoisile_trainer_2", Color(0.65, 0.25, 0.12))
	_trainer(Vector2(160.0, 48.0),  "gym_leader_blaine",    Color(0.90, 0.40, 0.10))

func _build_transitions() -> void:
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/CramoisIle.tscn", Vector2(256.0, 76.0))

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
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/CramoisIleGym.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new(); r.position = pos; r.size = size; r.color = color; add_child(r)
func _wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.position = center
	var shape := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = size; shape.shape = rs
	body.add_child(shape); add_child(body)
func _trainer(pos: Vector2, trainer_id: String, color: Color) -> void:
	var t := Trainer.new(); t.position = pos; t.trainer_id = trainer_id; t.npc_color = color; add_child(t)
func _transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var t := MapTransition.new(); t.position = center; t.target_scene = target; t.spawn_position = spawn
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	t.add_child(cs); add_child(t)
