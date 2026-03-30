class_name Player
extends CharacterBody2D
## Joueur overworld -- deplacement grille (tile par tile), style Pokemon.
## Sprite anime 4 directions x 3 frames.

const TILE_SIZE: int = 16
const WALK_SPEED: float = 128.0
const SPRITE_PATH := "res://assets/sprites/characters/player.png"

var _moving: bool = false
var _move_from: Vector2 = Vector2.ZERO
var _move_to: Vector2 = Vector2.ZERO
var _move_progress: float = 0.0

enum Dir { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }
var facing: Dir = Dir.DOWN

var _sprite: Sprite2D
var _anim_timer: float = 0.0
var _walk_frame: int = 0

const DIR_VECTORS: Dictionary = {
	Dir.DOWN:  Vector2.DOWN,
	Dir.UP:    Vector2.UP,
	Dir.LEFT:  Vector2.LEFT,
	Dir.RIGHT: Vector2.RIGHT,
}

func _ready() -> void:
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	_move_from = position
	_move_to = position
	_setup_sprite()

func _setup_sprite() -> void:
	# Remove old Polygon2D body if present
	var old_body = get_node_or_null("Body")
	if old_body:
		old_body.queue_free()

	_sprite = Sprite2D.new()
	_sprite.name = "CharSprite"
	var tex = load(SPRITE_PATH)
	if tex:
		_sprite.texture = tex
		_sprite.hframes = 3
		_sprite.vframes = 4
		_sprite.frame = 0  # down idle
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.offset = Vector2(0, -4)
	add_child(_sprite)
	_update_sprite_frame()

func _update_sprite_frame() -> void:
	if not _sprite or not _sprite.texture:
		return
	# Row = direction (down=0, up=1, left=2, right=3)
	# Col = frame (0=idle, 1=walk1, 2=walk2)
	var col := 0 if not _moving else (1 if _walk_frame == 0 else 2)
	_sprite.frame = int(facing) * 3 + col

func _physics_process(delta: float) -> void:
	if _moving:
		_tick_movement(delta)
		# Walk animation
		_anim_timer += delta
		if _anim_timer >= 0.12:
			_anim_timer = 0.0
			_walk_frame = (_walk_frame + 1) % 2
			_update_sprite_frame()
	else:
		_poll_input()

func _is_any_menu_active() -> bool:
	return (PauseMenu.is_active() or DialogueManager.is_active()
		or ShopMenu.is_active() or PCBoxScreen.is_active()
		or TitleScreen.is_active() or StarterSelect.is_active()
		or PokemonSummary.is_active() or GameOverScreen.is_active())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not _is_any_menu_active():
			PauseMenu.show_menu() if not PauseMenu.is_active() else PauseMenu.hide_menu()
			get_viewport().set_input_as_handled()
		return
	if _moving:
		return
	if _is_any_menu_active():
		return
	if event.is_action_pressed("ui_accept"):
		_try_interact()

func _poll_input() -> void:
	if _is_any_menu_active():
		return
	var dir_vec := _read_direction()
	if dir_vec == Vector2.ZERO:
		return

	_update_facing(dir_vec)
	_update_sprite_frame()

	var collision := move_and_collide(dir_vec * TILE_SIZE, true)
	if collision != null:
		return

	_move_from = position
	_move_to = position + dir_vec * TILE_SIZE
	_move_progress = 0.0
	_moving = true
	_walk_frame = 0
	_anim_timer = 0.0

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

func _try_interact() -> void:
	var check_pos := position + DIR_VECTORS[facing] * TILE_SIZE
	for node in get_tree().get_nodes_in_group("interactable"):
		if node.position.distance_to(check_pos) < 8.0:
			node.interact()
			return

func _tick_movement(delta: float) -> void:
	_move_progress += delta * WALK_SPEED / TILE_SIZE

	if _move_progress >= 1.0:
		position = _move_to
		_moving = false
		_move_progress = 0.0
		_update_sprite_frame()
		EventBus.player_stepped.emit(position)
	else:
		position = _move_from.lerp(_move_to, _move_progress)
