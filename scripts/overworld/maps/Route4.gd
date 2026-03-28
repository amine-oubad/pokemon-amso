extends Node2D
## ROUTE 4 — Route entre Azuria City et Carmin-sur-Mer.
## Layout 480×240 avec deux zones d'herbe.

const MAP_W := 480
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_grass()
	_build_borders()
	_build_trainers()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(24.0, 120.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.28, 0.52, 0.20))

func _build_path() -> void:
	# Chemin nord-sud puis est-ouest
	_rect(Vector2(0, 96), Vector2(MAP_W, 32), Color(0.58, 0.48, 0.30))
	_rect(Vector2(MAP_W - 48, 0), Vector2(48, MAP_H), Color(0.58, 0.48, 0.30))

func _build_grass() -> void:
	_rect(Vector2(48, 0), Vector2(160, 96), Color(0.18, 0.46, 0.12))
	_rect(Vector2(48, 128), Vector2(160, 112), Color(0.18, 0.46, 0.12))
	_rect(Vector2(256, 0), Vector2(160, 96), Color(0.15, 0.40, 0.10))
	_rect(Vector2(256, 128), Vector2(160, 112), Color(0.15, 0.40, 0.10))
	_grass_label(Vector2(90, 30), "~HERBES~")
	_grass_label(Vector2(300, 30), "~HERBES~")

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W + 8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	_wall(Vector2(MAP_W * 0.5, MAP_H + 8.0), Vector2(MAP_W + 16.0, 16.0))

func _build_trainers() -> void:
	_trainer(Vector2(160.0, 112.0), "route4_hiker",  Color(0.55, 0.40, 0.25))
	_trainer(Vector2(320.0, 112.0), "route4_lass",   Color(0.85, 0.50, 0.60))
	# Rival Bleu — avant Carmin
	_trainer(Vector2(420.0, 112.0), "rival_carmin",   Color(0.20, 0.30, 0.80))

func _build_signs() -> void:
	_sign(Vector2(48.0, 112.0), "sign_route4")

func _build_transitions() -> void:
	# Ouest → Azuria City
	_transition(Vector2(-8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/AzuriaCity.tscn", Vector2(296.0, 120.0))
	# Sud → Carmin-sur-Mer
	_transition(Vector2(MAP_W - 24.0, MAP_H + 8.0), Vector2(48.0, 24.0),
		"res://scenes/overworld/maps/CarminCity.tscn", Vector2(160.0, 16.0))

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
	EventBus.player_stepped.connect(_on_player_stepped)

func _on_player_stepped(world_pos: Vector2) -> void:
	var zone := _get_grass_zone(world_pos)
	if zone == "": return
	if randf() > 0.15: return
	var encounters: Array = GameData.encounters_data.get("route4", {}).get(zone, [])
	if encounters.is_empty(): return
	var chosen: Dictionary = _weighted_pick(encounters)
	if chosen.is_empty(): return
	var level := randi_range(int(chosen.get("level_min", 3)), int(chosen.get("level_max", 5)))
	var pokemon := PokemonInstance.create_wild(chosen["id"], level)
	GameState.pending_battle = { "enemy_data": pokemon.to_dict(), "is_trainer": false }
	EventBus.battle_started.emit(pokemon.to_dict(), false)

func _get_grass_zone(pos: Vector2) -> String:
	if pos.x >= 48 and pos.x <= 208:
		if pos.y <= 96 or pos.y >= 128: return "grass_01"
	if pos.x >= 256 and pos.x <= 416:
		if pos.y <= 96 or pos.y >= 128: return "grass_02"
	return ""

func _weighted_pick(list: Array) -> Dictionary:
	var total := 0
	for e in list: total += int(e.get("weight", 1))
	var roll := randi_range(1, total)
	var acc  := 0
	for e in list:
		acc += int(e.get("weight", 1))
		if roll <= acc: return e
	return list[-1]

func _on_battle_started(enemy_data: Dictionary, is_trainer: bool) -> void:
	GameState.pending_battle   = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene  = "res://scenes/overworld/maps/Route4.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/Route4.tscn"
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
func _grass_label(pos: Vector2, text: String) -> void:
	var lbl := Label.new(); lbl.text = text; lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 5)
	lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8, 0.7))
	add_child(lbl)
