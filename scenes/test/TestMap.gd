extends Node2D

const TILE: int = 16

func _ready() -> void:
	# Fond vert simple
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.56, 0.22)
	bg.size = Vector2(320, 240)
	add_child(bg)

	# Joueur = carré bleu
	var player := ColorRect.new()
	player.color = Color(0.2, 0.4, 0.9)
	player.size = Vector2(14, 14)
	player.position = Vector2(10 * TILE + 1, 7 * TILE + 1)
	player.name = "Player"
	add_child(player)

	print("[TestMap] Ready — player at ", player.position)

var _moving: bool = false
var _player_tile: Vector2i = Vector2i(10, 7)

func _process(_delta: float) -> void:
	if _moving:
		return
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("move_up"):    dir = Vector2i(0, -1)
	elif Input.is_action_pressed("move_down"):  dir = Vector2i(0, 1)
	elif Input.is_action_pressed("move_left"):  dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("move_right"): dir = Vector2i(1, 0)
	if dir == Vector2i.ZERO:
		return
	var target: Vector2i = _player_tile + dir
	if target.x < 0 or target.x >= 20 or target.y < 0 or target.y >= 15:
		return
	_player_tile = target
	_moving = true
	var player_node: ColorRect = $Player
	var dest := Vector2(target.x * TILE + 1, target.y * TILE + 1)
	var tw: Tween = create_tween()
	tw.tween_property(player_node, "position", dest, 0.12)
	tw.finished.connect(func() -> void: _moving = false)
