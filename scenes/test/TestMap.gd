extends Node2D
## Map de test 20x15 — TileMapLayer + Player séparé + collisions Dictionary.

const TILE: int = 16
const W: int = 20
const H: int = 15

## Atlas coords dans grass.png (col, row)
const GRASS: Vector2i   = Vector2i(0, 0)
const GRASS2: Vector2i  = Vector2i(1, 0)
const GRASS3: Vector2i  = Vector2i(3, 0)  # herbe fleurie
const PATH: Vector2i    = Vector2i(4, 0)
const TREE: Vector2i    = Vector2i(0, 2)   # arbre (1 tile pour simplifier)
const ROCK: Vector2i    = Vector2i(3, 3)   # rocher

var _blocked: Dictionary = {}

func _ready() -> void:
	var tilemap := _create_tilemap()
	add_child(tilemap)
	_fill_map(tilemap)
	_spawn_player()

func _create_tilemap() -> TileMapLayer:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/grass.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(atlas, 0)
	var tm := TileMapLayer.new()
	tm.tile_set = ts
	tm.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return tm

func _fill_map(tm: TileMapLayer) -> void:
	# 1. Sol d'herbe partout
	for y in H:
		for x in W:
			var v: Vector2i = GRASS
			if (x + y) % 5 == 0: v = GRASS2
			if (x * 3 + y * 7) % 11 == 0: v = GRASS3
			tm.set_cell(Vector2i(x, y), 0, v)

	# 2. Bordure d'arbres — tout le tour, passage nord col 9-10
	for x in W:
		if x < 9 or x > 10:
			_wall(tm, x, 0)
		_wall(tm, x, H - 1)
	for y in range(1, H - 1):
		_wall(tm, 0, y)
		_wall(tm, W - 1, y)

	# 3. Obstacles au milieu
	# Bloc arbres 2x2 gauche
	_wall(tm, 5, 5); _wall(tm, 6, 5)
	_wall(tm, 5, 6); _wall(tm, 6, 6)
	# Bloc arbres 2x2 droite
	_wall(tm, 13, 5); _wall(tm, 14, 5)
	_wall(tm, 13, 6); _wall(tm, 14, 6)
	# Ligne horizontale
	for x in range(7, 13):
		_wall(tm, x, 10)
	# Rochers isolés
	_rock(tm, 3, 3)
	_rock(tm, 16, 3)
	_rock(tm, 8, 8)

	# 4. Chemin vertical au centre
	for y in range(1, H - 1):
		tm.set_cell(Vector2i(9, y), 0, PATH)
		tm.set_cell(Vector2i(10, y), 0, PATH)

## Place un arbre et le bloque
func _wall(tm: TileMapLayer, x: int, y: int) -> void:
	tm.set_cell(Vector2i(x, y), 0, TREE)
	_blocked[Vector2i(x, y)] = true

## Place un rocher et le bloque
func _rock(tm: TileMapLayer, x: int, y: int) -> void:
	tm.set_cell(Vector2i(x, y), 0, ROCK)
	_blocked[Vector2i(x, y)] = true

func _spawn_player() -> void:
	var scr: GDScript = load("res://scripts/overworld/Player.gd")
	var p := Node2D.new()
	p.set_script(scr)
	p.name = "Player"
	add_child(p)
	p.blocked = _blocked
	p.map_rect = Rect2i(0, 0, W, H)
	p.set_tile_pos(Vector2i(10, 7))
	# Caméra
	var cam := Camera2D.new()
	p.add_child(cam)
