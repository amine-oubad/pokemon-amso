class_name Player
extends CharacterBody2D
## Joueur overworld — déplacement grille (tile par tile), style Pokémon.
##
## Contrôles : ZQSD ou Flèches directionnelles (configurés dans project.godot)
## Tile size : 16px — doit correspondre à la TileMap de la scène.

const TILE_SIZE: int = 16
const WALK_SPEED: float = 128.0  # px/sec → 1 tile en 0.125s (ajustable)

# ── État de déplacement ────────────────────────────────────────────────────────
var _moving: bool = false
var _move_from: Vector2 = Vector2.ZERO
var _move_to: Vector2 = Vector2.ZERO
var _move_progress: float = 0.0  # 0.0 → 1.0

# ── Direction courante ─────────────────────────────────────────────────────────
enum Dir { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }
var facing: Dir = Dir.DOWN

# ── Vecteurs de direction ──────────────────────────────────────────────────────
const DIR_VECTORS: Dictionary = {
	Dir.DOWN:  Vector2.DOWN,
	Dir.UP:    Vector2.UP,
	Dir.LEFT:  Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT,
}

func _ready() -> void:
	# Aligner sur la grille au démarrage (important si la position dans l'éditeur n'est pas pile sur un tile)
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	_move_from = position
	_move_to = position

func _physics_process(delta: float) -> void:
	if _moving:
		_tick_movement(delta)
	else:
		_poll_input()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not TitleScreen.is_active() and not DialogueManager.is_active() and not ShopMenu.is_active() and not PCBoxScreen.is_active():
			PauseMenu.show_menu() if not PauseMenu.is_active() else PauseMenu.hide_menu()
			get_viewport().set_input_as_handled()
		return
	if _moving:
		return
	if event.is_action_pressed("ui_accept"):
		_try_interact()

# ── Input ──────────────────────────────────────────────────────────────────────

func _poll_input() -> void:
	var dir_vec := _read_direction()
	if dir_vec == Vector2.ZERO:
		return

	_update_facing(dir_vec)

	# Tester la collision AVANT de commencer le mouvement
	# move_and_collide avec test_only=true ne déplace pas réellement le personnage
	var collision := move_and_collide(dir_vec * TILE_SIZE, true)
	if collision != null:
		return  # Mur ou obstacle — on ne bouge pas

	# Lancer le déplacement fluide vers la tile suivante
	_move_from = position
	_move_to = position + dir_vec * TILE_SIZE
	_move_progress = 0.0
	_moving = true

func _read_direction() -> Vector2:
	if Input.is_action_pressed("move_up"):    return Vector2.UP
	if Input.is_action_pressed("move_down"):  return Vector2.DOWN
	if Input.is_action_pressed("move_left"):  return Vector2.LEFT
	if Input.is_action_pressed("move_right"): return Vector2.RIGHT
	return Vector2.ZERO

func _update_facing(dir_vec: Vector2) -> void:
	if   dir_vec == Vector2.DOWN:  facing = Dir.DOWN
	elif dir_vec == Vector2.UP:    facing = Dir.UP
	elif dir_vec == Vector2.LEFT:  facing = Dir.LEFT
	elif dir_vec == Vector2.RIGHT: facing = Dir.RIGHT

# ── Interaction ────────────────────────────────────────────────────────────────

func _try_interact() -> void:
	# La tile devant le joueur
	var check_pos := position + DIR_VECTORS[facing] * TILE_SIZE
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.position.distance_to(check_pos) < 8.0:
			node.interact()
			return

# ── Mouvement ──────────────────────────────────────────────────────────────────

func _tick_movement(delta: float) -> void:
	# Avancer la progression (0.0 → 1.0) à vitesse constante
	_move_progress += delta * WALK_SPEED / TILE_SIZE

	if _move_progress >= 1.0:
		# Arrivé à destination — snapper exactement sur la grille
		position = _move_to
		_moving = false
		_move_progress = 0.0
		EventBus.player_stepped.emit(position)
	else:
		# Interpolation linéaire entre les deux tiles
		position = _move_from.lerp(_move_to, _move_progress)
