extends Node2D
## ARÈNE DE JADIELLE — intérieur du Gym.
## Layout 320×240 : salle avec un dresseur et le Champion Pierre.

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

# ── Construction ────────────────────────────────────────────────────────────────

func _build_ground() -> void:
	# Sol de l'arène
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.35, 0.30, 0.25))
	# Chemin central vers le Champion
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.50, 0.42, 0.30))

func _build_arena() -> void:
	# Estrade du Champion (fond)
	_rect(Vector2(100, 16), Vector2(120, 48), Color(0.40, 0.55, 0.30))
	_rect(Vector2(100, 16), Vector2(120, 8), Color(0.30, 0.45, 0.20))

	# Titre
	var title := Label.new()
	title.text = "ARÈNE DE JADIELLE"
	title.position = Vector2(100, 4)
	title.add_theme_font_size_override("font_size", 7)
	title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(title)

	# Décorations latérales (piliers)
	_rect(Vector2(80, 16), Vector2(12, MAP_H - 32), Color(0.45, 0.35, 0.25))
	_rect(Vector2(228, 16), Vector2(12, MAP_H - 32), Color(0.45, 0.35, 0.25))
	_wall(Vector2(86, MAP_H * 0.5), Vector2(12, MAP_H - 32))
	_wall(Vector2(234, MAP_H * 0.5), Vector2(12, MAP_H - 32))

	# Ligne de combat (sol plus clair)
	_rect(Vector2(100, 100), Vector2(120, 2), Color(0.65, 0.55, 0.35))

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	# Bas — trou pour la sortie
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_trainers() -> void:
	# Guide de l'arène
	_npc(Vector2(120.0, 192.0), "gym_guide", "", "", Color(0.55, 0.55, 0.75))

	# Dresseur de l'arène
	_trainer(Vector2(160.0, 128.0), "gym_trainer_1", Color(0.65, 0.35, 0.20))

	# Champion Pierre (sur l'estrade)
	_trainer(Vector2(160.0, 48.0), "gym_leader_pierre", Color(0.50, 0.40, 0.30))

func _build_transitions() -> void:
	# Sortie sud → retour à Jadielle City
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160.0, 72.0))

# ── Spawn joueur ─────────────────────────────────────────────────────────────────

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
		cam.limit_left   = 0
		cam.limit_top    = 0
		cam.limit_right  = MAP_W
		cam.limit_bottom = MAP_H

# ── Signaux ──────────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/ViridianGym.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

# ── Helpers ──────────────────────────────────────────────────────────────────────

func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos; r.size = size; r.color = color
	add_child(r)

func _wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	shape.shape = rs
	body.add_child(shape)
	add_child(body)

func _npc(pos: Vector2, dialogue_key: String, special_action: String, shop_id: String, color: Color) -> void:
	var npc := NPC.new()
	npc.position = pos
	npc.dialogue_key = dialogue_key
	npc.special_action = special_action
	npc.shop_id = shop_id
	npc.npc_color = color
	add_child(npc)

func _trainer(pos: Vector2, trainer_id: String, color: Color) -> void:
	var t := Trainer.new()
	t.position = pos
	t.trainer_id = trainer_id
	t.npc_color = color
	add_child(t)

func _transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var t := MapTransition.new()
	t.position = center
	t.target_scene = target
	t.spawn_position = spawn
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = shape_size
	cs.shape = rs
	t.add_child(cs)
	add_child(t)
