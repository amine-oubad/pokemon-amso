extends Node2D
## JADIELLE CITY — ville avec l'Arène Pokémon.
## Layout 320×240 : Centre Pokémon, Pokémart, Arène au nord.

const MAP_W := 320
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_buildings()
	_build_borders()
	_build_npcs()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(160.0, 208.0))
	_connect_signals()

# ── Construction ────────────────────────────────────────────────────────────────

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.28, 0.55, 0.22))

func _build_path() -> void:
	# Chemin nord-sud
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.60, 0.50, 0.33))
	# Chemin est-ouest vers l'Arène
	_rect(Vector2(100, 56), Vector2(120, 16), Color(0.60, 0.50, 0.33))
	# Chemin est vers Route 2
	_rect(Vector2(176, 96), Vector2(144, 32), Color(0.60, 0.50, 0.33))

func _build_buildings() -> void:
	# Centre Pokémon (rouge, gauche)
	_building(Vector2(16.0, 100.0), Vector2(80.0, 48.0), Color(0.85, 0.20, 0.18), "CENTRE\nPOKÉMON")
	# Pokémart (bleu, droite)
	_building(Vector2(224.0, 100.0), Vector2(80.0, 48.0), Color(0.20, 0.35, 0.85), "POKÉMART")
	# Arène (vert sombre, nord)
	_building(Vector2(112.0, 4.0), Vector2(96.0, 56.0), Color(0.35, 0.55, 0.25), "ARÈNE\nPOKÉMON")

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	# Droite — deux segments, trou pour sortie est vers Route 2 (y=96-128)
	_wall(Vector2(MAP_W + 8.0, 44.0), Vector2(16.0, 88.0))
	_wall(Vector2(MAP_W + 8.0, 176.0), Vector2(16.0, 128.0))
	# Haut — mur complet
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	# Bas — trou pour chemin sud (Route 1)
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_npcs() -> void:
	# Infirmière
	_npc(Vector2(56.0, 164.0), "jadielle_nurse", "heal_team", "", Color(0.90, 0.70, 0.70))
	# Vendeur
	_npc(Vector2(264.0, 164.0), "", "open_shop", "jadielle_shop", Color(0.30, 0.65, 0.30))
	# Guide
	_npc(Vector2(80.0, 208.0), "guide_jadielle", "", "", Color(0.50, 0.50, 0.85))

func _build_signs() -> void:
	_sign(Vector2(112.0, 208.0), "sign_jadielle_city")
	_sign(Vector2(112.0, 64.0), "sign_gym_entry")
	_sign(Vector2(288.0, 128.0), "sign_route2_entry")

func _build_transitions() -> void:
	# Sortie sud → Route 1
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/Route1.tscn", Vector2(160.0, 32.0))
	# Entrée Arène → intérieur
	_transition(Vector2(160.0, 60.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/ViridianGym.tscn", Vector2(160.0, 208.0))
	# Sortie est → Route 2
	_transition(Vector2(MAP_W + 8.0, 112.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route2.tscn", Vector2(160.0, 224.0))

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
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene = "res://scenes/overworld/maps/ViridianCity.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/ViridianCity.tscn"
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

func _building(pos: Vector2, size: Vector2, color: Color, label: String) -> void:
	_rect(pos, size, color)
	_rect(pos, Vector2(size.x, 8.0), color.darkened(0.35))
	_rect(pos + Vector2(size.x * 0.5 - 6.0, size.y - 14.0), Vector2(12.0, 14.0), color.lightened(0.25))
	var lbl := Label.new()
	lbl.text = label
	lbl.position = pos + Vector2(3.0, size.y * 0.3)
	lbl.size = Vector2(size.x - 6.0, size.y)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl)
	_wall(pos + size * 0.5, size)

func _npc(pos: Vector2, dialogue_key: String, special_action: String, shop_id: String, color: Color) -> void:
	var npc := NPC.new()
	npc.position = pos
	npc.dialogue_key = dialogue_key
	npc.special_action = special_action
	npc.shop_id = shop_id
	npc.npc_color = color
	add_child(npc)

func _sign(pos: Vector2, dialogue_key: String) -> void:
	var s := Sign.new()
	s.position = pos
	s.dialogue_key = dialogue_key
	add_child(s)

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
