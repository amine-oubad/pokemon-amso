extends Node2D
## Joueur overworld — déplacement grille strict comme Pokémon GBA.
## Pas de physics body : les collisions sont vérifiées via le TileMapLayer.

const TILE: int = 16
const MOVE_DURATION: float = 0.12  # durée du tween en secondes

enum Dir { DOWN, UP, LEFT, RIGHT }

## Référence au TileMapLayer de la map (assignée par la map)
var tile_map: TileMapLayer = null

## Position en coordonnées tile (pas pixels)
var tile_pos: Vector2i = Vector2i.ZERO

## Direction actuelle du joueur
var facing: Dir = Dir.DOWN

## Vrai pendant le mouvement (bloque les inputs)
var _moving: bool = false

## Visuel placeholder
var _visual: ColorRect

## Vecteurs de direction
const DIR_VEC: Dictionary = {
	Dir.DOWN:  Vector2i(0, 1),
	Dir.UP:    Vector2i(0, -1),
	Dir.LEFT:  Vector2i(-1, 0),
	Dir.RIGHT: Vector2i(1, 0),
}

func _ready() -> void:
	# Carré coloré 14x14 centré dans le tile (1px de marge)
	_visual = ColorRect.new()
	_visual.color = Color(0.2, 0.4, 0.9)
	_visual.size = Vector2(14, 14)
	_visual.position = Vector2(1, 1)
	add_child(_visual)
	# Synchroniser la position pixel avec la position tile
	_snap_to_grid()

## Place le joueur à la position tile donnée
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

	# Toujours tourner le joueur dans la direction
	facing = dir

	# Vérifier si la destination est libre
	var target: Vector2i = tile_pos + DIR_VEC[dir]
	if _is_blocked(target):
		return

	# Lancer le mouvement
	_move_to(target)

## Vérifie si une tile est bloquée (mur, obstacle, hors map)
func _is_blocked(target: Vector2i) -> bool:
	if tile_map == null:
		return true
	# Hors des limites de la map
	var used: Rect2i = tile_map.get_used_rect()
	if not used.has_point(target):
		return true
	# Vérifier si la tile a une physique layer (collision)
	var cell_data: TileData = tile_map.get_cell_tile_data(target)
	if cell_data == null:
		return true  # Pas de tile = bloqué
	# Si la tile a un physics layer 0, c'est un mur
	if cell_data.get_collision_polygons_count(0) > 0:
		return true
	return false

## Déplace le joueur vers la tile cible avec un tween
func _move_to(target: Vector2i) -> void:
	_moving = true
	tile_pos = target
	var dest: Vector2 = Vector2(target.x * TILE, target.y * TILE)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", dest, MOVE_DURATION)
	tween.finished.connect(_on_move_done)

func _on_move_done() -> void:
	_moving = false
	_snap_to_grid()  # Alignement parfait
