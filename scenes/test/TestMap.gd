extends Node2D
## Map de test — 20x15 tiles avec bordure de murs et obstacles.
## Construit le TileMapLayer et le joueur au runtime.

const TILE: int = 16
const MAP_W: int = 20  # tiles
const MAP_H: int = 15  # tiles

# Index des tiles dans le tileset grass.png (col, row dans l'atlas 16x16)
# Row 0: herbe variantes + chemin + eau
const GRASS_ATLAS: Vector2i = Vector2i(0, 0)   # herbe claire
const GRASS2_ATLAS: Vector2i = Vector2i(1, 0)  # herbe moyenne
const PATH_ATLAS: Vector2i = Vector2i(4, 0)    # chemin
# Row 2: arbres (haut-gauche du 2x2)
const TREE_TL: Vector2i = Vector2i(0, 2)
const TREE_TR: Vector2i = Vector2i(1, 2)
const TREE_BL: Vector2i = Vector2i(0, 3)
const TREE_BR: Vector2i = Vector2i(1, 3)

var _tilemap: TileMapLayer
var _player_scene: PackedScene

func _ready() -> void:
	_setup_tilemap()
	_build_map()
	_spawn_player()

func _setup_tilemap() -> void:
	# Créer le TileSet depuis l'atlas grass.png
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE, TILE)

	# Ajouter l'atlas source
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/tilesets/grass.png")
	atlas.texture_region_size = Vector2i(TILE, TILE)
	tileset.add_source(atlas, 0)

	# Créer les atlas coords — Godot 4.6 les crée automatiquement
	# On doit juste configurer la physique pour les tiles bloquantes

	# Physics layer 0 = collision
	tileset.add_physics_layer()

	# Marquer les tiles d'arbre comme bloquantes (ajouter un polygon de collision)
	for tree_coord in [TREE_TL, TREE_TR, TREE_BL, TREE_BR]:
		_make_tile_solid(atlas, tree_coord)

	# Créer le TileMapLayer
	_tilemap = TileMapLayer.new()
	_tilemap.name = "TileMapLayer"
	_tilemap.tile_set = tileset
	_tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_tilemap)

func _make_tile_solid(atlas: TileSetAtlasSource, coord: Vector2i) -> void:
	# Vérifier que le tile existe dans l'atlas
	if not atlas.has_tile(coord):
		atlas.create_tile(coord)
	var tile_data: TileData = atlas.get_tile_data(coord, 0)
	if tile_data == null:
		return
	# Ajouter un polygone de collision carré (tout le tile)
	tile_data.add_collision_polygon(0)
	var half: float = TILE / 2.0
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)
	]))

func _build_map() -> void:
	# Remplir tout d'herbe
	for y in MAP_H:
		for x in MAP_W:
			var grass_variant: Vector2i = GRASS_ATLAS if (x + y) % 3 != 0 else GRASS2_ATLAS
			_tilemap.set_cell(Vector2i(x, y), 0, grass_variant)

	# Bordure d'arbres — tout le tour sauf un passage au nord (col 9-10)
	for x in MAP_W:
		# Haut — avec passage au milieu
		if x < 9 or x > 10:
			_tilemap.set_cell(Vector2i(x, 0), 0, TREE_TL)
		# Bas
		_tilemap.set_cell(Vector2i(x, MAP_H - 1), 0, TREE_BL)
	for y in MAP_H:
		# Gauche
		_tilemap.set_cell(Vector2i(0, y), 0, TREE_TL)
		# Droite
		_tilemap.set_cell(Vector2i(MAP_W - 1, y), 0, TREE_TR)

	# Quelques obstacles au milieu pour tester les collisions
	# Bloc d'arbres 2x2 au centre-gauche
	_tilemap.set_cell(Vector2i(5, 6), 0, TREE_TL)
	_tilemap.set_cell(Vector2i(6, 6), 0, TREE_TR)
	_tilemap.set_cell(Vector2i(5, 7), 0, TREE_BL)
	_tilemap.set_cell(Vector2i(6, 7), 0, TREE_BR)

	# Bloc d'arbres 2x2 au centre-droite
	_tilemap.set_cell(Vector2i(13, 6), 0, TREE_TL)
	_tilemap.set_cell(Vector2i(14, 6), 0, TREE_TR)
	_tilemap.set_cell(Vector2i(13, 7), 0, TREE_BL)
	_tilemap.set_cell(Vector2i(14, 7), 0, TREE_BR)

	# Ligne d'arbres horizontale
	for x in range(8, 12):
		_tilemap.set_cell(Vector2i(x, 10), 0, TREE_TL)

	# Chemin vertical au centre
	for y in range(1, MAP_H - 1):
		_tilemap.set_cell(Vector2i(9, y), 0, PATH_ATLAS)
		_tilemap.set_cell(Vector2i(10, y), 0, PATH_ATLAS)

func _spawn_player() -> void:
	var player_script: GDScript = load("res://scripts/overworld/Player.gd")
	var player := Node2D.new()
	player.set_script(player_script)
	player.name = "Player"
	add_child(player)
	# Donner la référence du tilemap au joueur
	player.tile_map = _tilemap
	# Position de départ : centre de la map
	player.set_tile_pos(Vector2i(10, 7))

	# Caméra qui suit le joueur
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	player.add_child(cam)
