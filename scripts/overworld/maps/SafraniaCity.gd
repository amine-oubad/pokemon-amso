extends Node2D
## SAFRANIA — ville du 6e Gym (type Psy). Championne : Morgane.
## Layout 320×240 : ville mystique, Centre Pokémon, Pokémart, Arène.

const MAP_W := 320
const MAP_H := 240
const TILE  := 16

func _ready() -> void:
	_build_ground()
	_build_path()
	_build_decor()
	_build_buildings()
	_build_borders()
	_build_npcs()
	_build_signs()
	_build_transitions()
	_spawn_player(Vector2(24.0, 120.0))
	_connect_signals()

func _build_ground() -> void:
	_rect(Vector2.ZERO, Vector2(MAP_W, MAP_H), Color(0.28, 0.22, 0.38))

func _build_path() -> void:
	_rect(Vector2(0, 104), Vector2(MAP_W, 32), Color(0.48, 0.40, 0.52))
	_rect(Vector2(144, 0), Vector2(32, MAP_H), Color(0.48, 0.40, 0.52))

func _build_decor() -> void:
	# Zones mystiques (violet)
	_rect(Vector2(200, 160), Vector2(100, 60), Color(0.35, 0.18, 0.50, 0.5))
	_rect(Vector2(16, 16), Vector2(80, 60), Color(0.35, 0.18, 0.50, 0.5))

func _build_buildings() -> void:
	_building(Vector2(16.0, 136.0), Vector2(80.0, 48.0), Color(0.85, 0.20, 0.18), "CENTRE\nPOKÉMON")
	_building(Vector2(16.0, 200.0), Vector2(80.0, 36.0), Color(0.20, 0.35, 0.85), "POKÉMART")
	_building(Vector2(200.0, 8.0), Vector2(112.0, 56.0), Color(0.55, 0.25, 0.70), "ARÈNE DE\nSAFRANIA")

func _build_borders() -> void:
	_wall(Vector2(-8.0, MAP_H * 0.5), Vector2(16.0, MAP_H + 16.0))
	# Est wall — gap at y=96-136 for Route 7
	_wall(Vector2(MAP_W + 8.0, 48.0), Vector2(16.0, 96.0))
	_wall(Vector2(MAP_W + 8.0, 192.0), Vector2(16.0, 96.0))
	_wall(Vector2(MAP_W * 0.5, -8.0), Vector2(MAP_W + 16.0, 16.0))
	_wall(Vector2(MAP_W * 0.5, MAP_H + 8.0), Vector2(MAP_W + 16.0, 16.0))

func _build_npcs() -> void:
	_npc(Vector2(56.0, 184.0), "safrania_nurse",  "heal_team", "",              Color(0.90, 0.70, 0.70))
	_npc(Vector2(56.0, 230.0), "", "open_shop", "safrania_shop",                Color(0.30, 0.65, 0.30))
	_npc(Vector2(120.0, 200.0), "guide_safrania",  "",          "",             Color(0.60, 0.40, 0.75))

func _build_signs() -> void:
	_sign(Vector2(144.0, 200.0), "sign_safrania_city")
	_sign(Vector2(200.0, 68.0),  "sign_safrania_gym")

func _build_transitions() -> void:
	# Ouest → Route 6
	_transition(Vector2(-8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route6.tscn", Vector2(464.0, 120.0))
	# Est → Route 7
	_transition(Vector2(MAP_W + 8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route7.tscn", Vector2(16.0, 120.0))
	# Entrée Arène
	_transition(Vector2(256.0, 64.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/SafraniaGym.tscn", Vector2(160.0, 208.0))

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
	GameState.pending_battle  = { "enemy_data": enemy_data, "is_trainer": is_trainer }
	GameState.return_to_scene = "res://scenes/overworld/maps/SafraniaCity.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _on_trainer_battle(_trainer_id: String) -> void:
	GameState.return_to_scene = "res://scenes/overworld/maps/SafraniaCity.tscn"
	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new(); r.position = pos; r.size = size; r.color = color; add_child(r)
func _wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.position = center
	var shape := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = size; shape.shape = rs
	body.add_child(shape); add_child(body)
func _building(pos: Vector2, size: Vector2, color: Color, label: String) -> void:
	_rect(pos, size, color); _rect(pos, Vector2(size.x, 8.0), color.darkened(0.35))
	_rect(pos + Vector2(size.x * 0.5 - 6.0, size.y - 14.0), Vector2(12.0, 14.0), color.lightened(0.25))
	var lbl := Label.new(); lbl.text = label; lbl.position = pos + Vector2(3.0, size.y * 0.3)
	lbl.size = Vector2(size.x - 6.0, size.y); lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 6); lbl.add_theme_color_override("font_color", Color.WHITE)
	add_child(lbl); _wall(pos + size * 0.5, size)
func _npc(pos: Vector2, dialogue_key: String, special_action: String, shop_id: String, color: Color) -> void:
	var npc := NPC.new(); npc.position = pos; npc.dialogue_key = dialogue_key
	npc.special_action = special_action; npc.shop_id = shop_id; npc.npc_color = color; add_child(npc)
func _sign(pos: Vector2, dialogue_key: String) -> void:
	var s := Sign.new(); s.position = pos; s.dialogue_key = dialogue_key; add_child(s)
func _transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var t := MapTransition.new(); t.position = center; t.target_scene = target; t.spawn_position = spawn
	var cs := CollisionShape2D.new(); var rs := RectangleShape2D.new(); rs.size = shape_size; cs.shape = rs
	t.add_child(cs); add_child(t)
