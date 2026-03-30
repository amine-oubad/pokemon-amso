extends Node2D
## Map de test — 20x15 tiles, bordure d'arbres, obstacles au milieu.

const TILE: int = 16
const MAP_W: int = 20
const MAP_H: int = 15

# Atlas coords dans grass.png (16x16 tiles, 16 colonnes)
const GRASS: Vector2i  = Vector2i(0, 0)
const GRASS2: Vector2i = Vector2i(1, 0)
const PATH: Vector2i   = Vector2i(4, 0)
const TREE_TL: Vector2i = Vector2i(0, 2)
const TREE_TR: Vector2i = Vector2i(1, 2)
const TREE_BL: Vector2i = Vector2i(0, 3)
const TREE_BR: Vector2i = Vector2i(1, 3)

var _tilemap: TileMapLayer
var _blocked: Dictionary = {}  # Vector2i → true

func _ready() -> void:
	_setup_tilemap()
	_build_map()
	_spawn_player()

func _setup_tilemap() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/grass.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(atlas, 0)

	_tilemap = TileMapLayer.new()
	_tilemap.name = "Ground"
	_tilemap.tile_set = tileset
	_tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_tilemap)

func _build_map() -> void:
	# Sol d'herbe partout
	for y in MAP_H:
		for x in MAP_W:
			var variant: Vector2i = GRASS if (x + y) % 3 != 0 else GRASS2
			_tilemap.set_cell(Vector2i(x, y), 0, variant)

	# Bordure d'arbres (avec passage nord col 9-10)
	for x in MAP_W:
		if x < 9 or x > 10:
			_set_tree(x, 0)
		_set_tree(x, MAP_H - 1)
	for y in range(1, MAP_H - 1):
		_set_tree(0, y)
		_set_tree(MAP_W - 1, y)

	# Obstacles — blocs 2x2 d'arbres
	_set_tree(5, 6); _set_tree(6, 6)
	_set_tree(5, 7); _set_tree(6, 7)
	_set_tree(13, 6); _set_tree(14, 6)
	_set_tree(13, 7); _set_tree(14, 7)

	# Ligne horizontale d'arbres
	for x in range(8, 12):
		_set_tree(x, 10)

	# Chemin vertical au centre
	for y in range(1, MAP_H - 1):
		_tilemap.set_cell(Vector2i(9, y), 0, PATH)
		_tilemap.set_cell(Vector2i(10, y), 0, PATH)

## Place un arbre et le marque comme bloqué
func _set_tree(x: int, y: int) -> void:
	_tilemap.set_cell(Vector2i(x, y), 0, TREE_TL)
	_blocked[Vector2i(x, y)] = true

func _spawn_player() -> void:
	var player_script: GDScript = load("res://scripts/overworld/Player.gd")
	var player := Node2D.new()
	player.set_script(player_script)
	player.name = "Player"
	add_child(player)

	# Passer les données de collision au joueur
	player.blocked_tiles = _blocked
	player.map_rect = Rect2i(0, 0, MAP_W, MAP_H)
	player.set_tile_pos(Vector2i(10, 7))

	# Caméra
	var cam := Camera2D.new()
	player.add_child(cam)
