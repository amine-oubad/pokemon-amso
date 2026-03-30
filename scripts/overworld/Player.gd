extends Node2D
## Joueur overworld — déplacement grille strict comme Pokémon GBA.
## Les collisions sont gérées par un Dictionary de tiles bloquées (pas de physics).

const TILE: int = 16
const MOVE_DURATION: float = 0.12

enum Dir { DOWN, UP, LEFT, RIGHT }

## Dictionnaire des tiles bloquées — clé = Vector2i, valeur = true
## Rempli par la map via blocked_tiles[pos] = true
var blocked_tiles: Dictionary = {}

## Limites de la map en tiles
var map_rect: Rect2i = Rect2i(0, 0, 20, 15)

## Position courante en tiles
var tile_pos: Vector2i = Vector2i.ZERO

## Direction actuelle
var facing: Dir = Dir.DOWN

## Vrai pendant le déplacement
var _moving: bool = false

## Visuel placeholder
var _visual: ColorRect

const DIR_VEC: Dictionary = {
	Dir.DOWN:  Vector2i(0, 1),
	Dir.UP:    Vector2i(0, -1),
	Dir.LEFT:  Vector2i(-1, 0),
	Dir.RIGHT: Vector2i(1, 0),
}

func _ready() -> void:
	_visual = ColorRect.new()
	_visual.color = Color(0.2, 0.4, 0.9)
	_visual.size = Vector2(14, 14)
	_visual.position = Vector2(1, 1)
	add_child(_visual)
	_snap_to_grid()

func set_tile_pos(tp: Vector2i) -> void:
	tile_pos = tp
	_snap_to_grid()

func _snap_to_grid() -> void:
	position = Vector2(tile_pos.x * TILE, tile_pos.y * TILE)

func _process(_delta: float) -> void:
	if _moving:
		return
	_poll_input()

func _poll_input() -> void:
	var dir: Dir = Dir.DOWN
	var pressed: bool = false

	if Input.is_action_pressed("move_up"):
		dir = Dir.UP; pressed = true
	elif Input.is_action_pressed("move_down"):
		dir = Dir.DOWN; pressed = true
	elif Input.is_action_pressed("move_left"):
		dir = Dir.LEFT; pressed = true
	elif Input.is_action_pressed("move_right"):
		dir = Dir.RIGHT; pressed = true

	if not pressed:
		return

	facing = dir

	var target: Vector2i = tile_pos + DIR_VEC[dir]

	# Bloqué si hors map ou tile dans le dictionnaire
	if not map_rect.has_point(target) or blocked_tiles.has(target):
		return

	_move_to(target)

func _move_to(target: Vector2i) -> void:
	_moving = true
	tile_pos = target
	var dest: Vector2 = Vector2(target.x * TILE, target.y * TILE)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", dest, MOVE_DURATION)
	tween.finished.connect(_on_move_done)

func _on_move_done() -> void:
	_moving = false
	_snap_to_grid()
