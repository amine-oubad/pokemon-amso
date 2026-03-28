extends Node2D
## ROUTE 1 — entre Bourg-Palette et Jadielle City.
## Layout 320×240 : herbes hautes gauche/droite, chemin central, dresseurs.

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
	_build_hm_blocks()
	_build_transitions()
	_spawn_player(Vector2(160.0, 32.0))
	_connect_signals()

# ── Construction ────────────────────────────────────────────────────────────────

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.22, 0.50, 0.15))

func _build_path() -> void:
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.60, 0.50, 0.33))

func _build_decorations() -> void:
	# Herbes hautes (visuelles)
	_rect(Vector2(16.0, 32.0), Vector2(112.0, 96.0), Color(0.15, 0.40, 0.10))
	_rect(Vector2(192.0, 112.0), Vector2(112.0, 96.0), Color(0.15, 0.40, 0.10))
	# Petits arbres décoratifs
	_rect(Vector2(0.0, 0.0), Vector2(16.0, 32.0), Color(0.10, 0.35, 0.08))
	_rect(Vector2(304.0, 0.0), Vector2(16.0, 32.0), Color(0.10, 0.35, 0.08))
	_rect(Vector2(0.0, 208.0), Vector2(48.0, 32.0), Color(0.10, 0.35, 0.08))
	_rect(Vector2(272.0, 208.0), Vector2(48.0, 32.0), Color(0.10, 0.35, 0.08))
	# Indicateurs directionnels
	var lbl_s := Label.new()
	lbl_s.text = "↓ Bourg-Palette"
	lbl_s.position = Vector2(80.0, 222.0)
	lbl_s.add_theme_font_size_override("font_size", 6)
	lbl_s.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl_s)
	var lbl_n := Label.new()
	lbl_n.text = "↑ Jadielle City"
	lbl_n.position = Vector2(80.0, 4.0)
	lbl_n.add_theme_font_size_override("font_size", 6)
	lbl_n.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl_n)

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	# Haut — trou pour chemin nord vers Jadielle (x=144-176)
	_wall(Vector2(72.0, -8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, -8.0), Vector2(144.0, 16.0))
	# Bas — trou pour chemin sud vers Bourg-Palette
	_wall(Vector2(72.0, MAP_H + 8.0), Vector2(144.0, 16.0))
	_wall(Vector2(248.0, MAP_H + 8.0), Vector2(144.0, 16.0))

func _build_encounter_zones() -> void:
	_encounter_zone(Vector2(72.0, 80.0), Vector2(112.0, 96.0), "route1", "grass_01", 0.15)
	_encounter_zone(Vector2(248.0, 160.0), Vector2(112.0, 96.0), "route1", "grass_02", 0.15)

func _build_trainers() -> void:
	# Gamin Thomas — sur le chemin
	_trainer(Vector2(160.0, 160.0), "route1_youngster", Color(0.50, 0.60, 0.30))
	# Fillette Marie — près des herbes
	_trainer(Vector2(192.0, 96.0), "route1_lass", Color(0.70, 0.40, 0.50))
	# NPC guide (non-combattant)
	_npc(Vector2(80.0, 176.0), "route1_trainer", "", "", Color(0.60, 0.30, 0.60))

func _build_signs() -> void:
	_sign(Vector2(128.0, 32.0), "sign_route1_grass")
	_sign(Vector2(176.0, 16.0), "sign_jadielle")

func _build_hm_blocks() -> void:
	# Arbre coupable bloquant un raccourci (est de la route)
	_hm_block(Vector2(256.0, 48.0), "cut", "hm_block_cut", "hm_block_cut_ok", "route1_cut_tree")

func _build_transitions() -> void:
	# Sortie sud → Bourg-Palette
	_transition(Vector2(160.0, MAP_H + 8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/PalletTown.tscn", Vector2(160.0, 16.0))
	# Sortie nord → Jadielle City
	_transition(Vector2(160.0, -8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160.0, 224.0))

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
	GameState.return_to_scene = "res://scenes/overworld/maps/Route1.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/Route1.tscn"
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

func _sign(pos: Vector2, dialogue_key: String) -> void:
	var s := Sign.new()
	s.position = pos
	s.dialogue_key = dialogue_key
	add_child(s)

func _encounter_zone(center: Vector2, shape_size: Vector2, map_id: String, zone_id: String, rate: float) -> void:
	var zone := WildEncounterZone.new()
	zone.position = center
	zone.map_id = map_id
	zone.zone_id = zone_id
	zone.encounter_rate = rate
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = shape_size
	cs.shape = rs
	zone.add_child(cs)
	add_child(zone)

func _hm_block(pos: Vector2, hm_id: String, block_key: String, clear_key: String, flag_id: String) -> void:
	var block := HMBlock.new()
	block.position = pos
	block.hm_id = hm_id
	block.block_dialogue_key = block_key
	block.clear_dialogue_key = clear_key
	block.flag_id = flag_id
	add_child(block)

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
