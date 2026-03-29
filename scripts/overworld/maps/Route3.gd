extends Node2D
## ROUTE 3 — Route herbée entre Argenta et Azuria.
## Layout 480×240 (plus large pour deux zones d'herbe).

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
	_spawn_player(Vector2(24.0, 64.0))
	_connect_signals()

# ── Construction ─────────────────────────────────────────────────────────────

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.25, 0.55, 0.18))

func _build_path() -> void:
	# Chemin central est-ouest
	_rect(Vector2(0, 48), Vector2(MAP_W, 32), Color(0.60, 0.50, 0.33))

func _build_grass() -> void:
	# Zone herbes 1 — ouest (Rattata/Roucoul/Rondoudou/Psykokwak)
	_rect(Vector2(48, 0), Vector2(160, 48), Color(0.18, 0.48, 0.12))
	_rect(Vector2(48, 80), Vector2(160, 80), Color(0.18, 0.48, 0.12))
	# Zone herbes 2 — est (Rondoudou/Psykokwak/Pikachu)
	_rect(Vector2(256, 0), Vector2(160, 48), Color(0.15, 0.42, 0.10))
	_rect(Vector2(256, 80), Vector2(160, 100), Color(0.15, 0.42, 0.10))
	# Marque visuelle HERBES
	_grass_label(Vector2(80, 14), "~HERBES~")
	_grass_label(Vector2(288, 14), "~HERBES~")
	# Lac Azur (décoratif, coin est)
	_rect(Vector2(380, 100), Vector2(100, 140), Color(0.20, 0.50, 0.85))
	_grass_label(Vector2(392, 148), "LAC\nAZUR")

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	_wall(Vector2(MAP_W * 0.5, MAP_H + 8.0), Vector2(MAP_W + 16.0, 16.0))

func _build_trainers() -> void:
	_trainer(Vector2(160.0, 64.0), "route3_youngster", Color(0.65, 0.50, 0.25))
	_trainer(Vector2(288.0, 64.0), "route3_lass",      Color(0.90, 0.55, 0.65))

func _build_signs() -> void:
	_sign(Vector2(48.0, 64.0),  "sign_route3")
	_sign(Vector2(392.0, 128.0), "sign_lake")

func _build_transitions() -> void:
	# Ouest → Argenta City
	_transition(Vector2(-8.0, 64.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/ArgentaCity.tscn", Vector2(300.0, 64.0))
	# Est → Azuria City
	_transition(Vector2(MAP_W + 8.0, 64.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/AzuriaCity.tscn", Vector2(16.0, 64.0))

# ── Spawn ─────────────────────────────────────────────────────────────────────

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
	_encounter_zone(Vector2(128.0, 80.0), Vector2(160.0, 160.0), "route3", "grass_01", 0.15)
	_encounter_zone(Vector2(336.0, 90.0), Vector2(160.0, 180.0), "route3", "grass_02", 0.15)

func _connect_signals() -> void:
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.trainer_battle_started.connect(_on_trainer_battle)

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle   = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene  = "res://scenes/overworld/maps/Route3.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/Route3.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────

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
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 5)
	lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8, 0.7))
	add_child(lbl)
