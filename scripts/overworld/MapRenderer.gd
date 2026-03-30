extends Node2D
## Base class for all tile-based maps.
## Provides helpers to build TileMap layers, spawn entities, etc.

const TILE_SIZE := 16
const ATLAS_PATH := "res://assets/tiles/tileset.png"

# Tile atlas coordinates (col, row) — matches tile_index.gd
const T := {
	"grass_light": Vector2i(0, 0),
	"grass_mid": Vector2i(1, 0),
	"grass_dark": Vector2i(2, 0),
	"grass_flowers": Vector2i(3, 0),
	"tall_grass": Vector2i(4, 0),
	"dirt_path": Vector2i(5, 0),
	"sand": Vector2i(6, 0),
	"water": Vector2i(7, 0),
	"water_edge_top": Vector2i(8, 0),
	"water_deep": Vector2i(9, 0),
	"lava": Vector2i(10, 0),
	"psy_floor": Vector2i(11, 0),
	"poison_floor": Vector2i(12, 0),
	"electric_floor": Vector2i(13, 0),
	"ice_floor": Vector2i(14, 0),
	"border_black": Vector2i(15, 0),
	"dirt_edge_top": Vector2i(0, 1),
	"dirt_edge_bottom": Vector2i(1, 1),
	"dirt_edge_left": Vector2i(2, 1),
	"dirt_edge_right": Vector2i(3, 1),
	"dirt_corner_tl": Vector2i(4, 1),
	"dirt_corner_tr": Vector2i(5, 1),
	"dirt_corner_bl": Vector2i(6, 1),
	"dirt_corner_br": Vector2i(7, 1),
	"cliff_face": Vector2i(8, 1),
	"cliff_top": Vector2i(9, 1),
	"bridge_h": Vector2i(10, 1),
	"stairs": Vector2i(11, 1),
	"border_dark": Vector2i(12, 1),
	"tree_tl": Vector2i(0, 2),
	"tree_tr": Vector2i(1, 2),
	"tree_bl": Vector2i(2, 2),
	"tree_br": Vector2i(3, 2),
	"tree_trunk": Vector2i(4, 2),
	"tree_full": Vector2i(5, 2),
	"rock": Vector2i(6, 2),
	"flowers_red": Vector2i(7, 2),
	"flowers_blue": Vector2i(8, 2),
	"flowers_yellow": Vector2i(9, 2),
	"fence_h": Vector2i(10, 2),
	"fence_v": Vector2i(11, 2),
	"fence_post": Vector2i(12, 2),
	"sign": Vector2i(13, 2),
	"wall_gray": Vector2i(0, 3),
	"wall_red": Vector2i(1, 3),
	"wall_blue": Vector2i(2, 3),
	"roof_red": Vector2i(3, 3),
	"roof_blue": Vector2i(4, 3),
	"roof_green": Vector2i(5, 3),
	"door": Vector2i(6, 3),
	"window": Vector2i(7, 3),
	"pokecenter_cross": Vector2i(8, 3),
	"pokemart_p": Vector2i(9, 3),
	"gym_floor": Vector2i(10, 3),
	"gym_wall": Vector2i(11, 3),
	"badge_podium": Vector2i(12, 3),
	"gym_roof_rock": Vector2i(0, 4),
	"gym_wall_rock": Vector2i(1, 4),
	"gym_roof_water": Vector2i(2, 4),
	"gym_wall_water": Vector2i(3, 4),
	"gym_roof_electric": Vector2i(4, 4),
	"gym_wall_electric": Vector2i(5, 4),
	"gym_roof_grass": Vector2i(6, 4),
	"gym_wall_grass": Vector2i(7, 4),
	"gym_roof_psychic": Vector2i(8, 4),
	"gym_wall_psychic": Vector2i(9, 4),
	"gym_roof_poison": Vector2i(10, 4),
	"gym_wall_poison": Vector2i(11, 4),
	"gym_roof_fire": Vector2i(12, 4),
	"gym_wall_fire": Vector2i(13, 4),
	"gym_roof_ground": Vector2i(14, 4),
	"gym_wall_ground": Vector2i(15, 4),
}

var _tilemap: TileMapLayer
var _overlay: TileMapLayer   # for trees / decorations above player
var _tileset: TileSet
var _player_node: CharacterBody2D

var MAP_W := 320
var MAP_H := 240

func _ready() -> void:
	_setup_tileset()
	_setup_tilemaps()
	build_map()
	_spawn_player()

# ── TileSet setup ────────────────────────────────────────────────

func _setup_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(ATLAS_PATH)
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Create all tiles in the atlas
	var tex_size := atlas.texture.get_size()
	var cols := int(tex_size.x) / TILE_SIZE
	var rows := int(tex_size.y) / TILE_SIZE
	for row in rows:
		for col in cols:
			var coords := Vector2i(col, row)
			atlas.create_tile(coords)

	_tileset.add_source(atlas, 0)

	# Physics layer for collision
	_tileset.add_physics_layer()

func _setup_tilemaps() -> void:
	_tilemap = TileMapLayer.new()
	_tilemap.name = "Ground"
	_tilemap.tile_set = _tileset
	_tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_tilemap)

	_overlay = TileMapLayer.new()
	_overlay.name = "Overlay"
	_overlay.tile_set = _tileset
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_overlay.z_index = 10
	add_child(_overlay)

# ── Override in subclass ─────────────────────────────────────────

func build_map() -> void:
	pass  # Override in each map script

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

# ── Tile placement helpers ───────────────────────────────────────

## Fill a rectangular area with a tile type (in tile coords).
func fill(tile_name: String, tx: int, ty: int, tw: int, th: int, overlay := false) -> void:
	var coords: Vector2i = T.get(tile_name, Vector2i(0, 0))
	var layer := _overlay if overlay else _tilemap
	for row in th:
		for col in tw:
			layer.set_cell(Vector2i(tx + col, ty + row), 0, coords)

## Place a single tile at tile coords.
func put(tile_name: String, tx: int, ty: int, overlay := false) -> void:
	var coords: Vector2i = T.get(tile_name, Vector2i(0, 0))
	var layer := _overlay if overlay else _tilemap
	layer.set_cell(Vector2i(tx, ty), 0, coords)

## Fill area using pixel coords (auto-converts to tile coords).
func fill_px(tile_name: String, px: float, py: float, pw: float, ph: float, overlay := false) -> void:
	var tx := int(px) / TILE_SIZE
	var ty := int(py) / TILE_SIZE
	var tw := max(1, int(pw) / TILE_SIZE)
	var th := max(1, int(ph) / TILE_SIZE)
	fill(tile_name, tx, ty, tw, th, overlay)

## Place single tile using pixel coords.
func put_px(tile_name: String, px: float, py: float, overlay := false) -> void:
	put(tile_name, int(px) / TILE_SIZE, int(py) / TILE_SIZE, overlay)

# ── Building helpers ─────────────────────────────────────────────

## Draw a Pokemon Center building (roof + wall + door + cross).
func pokecenter(tx: int, ty: int, w_tiles: int = 6, h_tiles: int = 3) -> void:
	# Roof row
	fill("roof_red", tx, ty, w_tiles, 1)
	put("pokecenter_cross", tx + w_tiles / 2, ty)
	# Wall rows
	for row in range(1, h_tiles):
		for col in w_tiles:
			if row == h_tiles - 1 and col == w_tiles / 2:
				put("door", tx + col, ty + row)
			else:
				put("wall_red", tx + col, ty + row)
	# Windows
	if w_tiles >= 4:
		put("window", tx + 1, ty + 1)
		put("window", tx + w_tiles - 2, ty + 1)
	_add_wall(tx, ty, w_tiles, h_tiles)

## Draw a Pokemart building.
func pokemart(tx: int, ty: int, w_tiles: int = 6, h_tiles: int = 3) -> void:
	fill("roof_blue", tx, ty, w_tiles, 1)
	put("pokemart_p", tx + w_tiles / 2, ty)
	for row in range(1, h_tiles):
		for col in w_tiles:
			if row == h_tiles - 1 and col == w_tiles / 2:
				put("door", tx + col, ty + row)
			else:
				put("wall_blue", tx + col, ty + row)
	if w_tiles >= 4:
		put("window", tx + 1, ty + 1)
		put("window", tx + w_tiles - 2, ty + 1)
	_add_wall(tx, ty, w_tiles, h_tiles)

## Draw a generic house.
func house(tx: int, ty: int, w_tiles: int = 3, h_tiles: int = 3, roof := "roof_green", wall := "wall_gray") -> void:
	fill(roof, tx, ty, w_tiles, 1)
	for row in range(1, h_tiles):
		for col in w_tiles:
			if row == h_tiles - 1 and col == w_tiles / 2:
				put("door", tx + col, ty + row)
			else:
				put(wall, tx + col, ty + row)
	_add_wall(tx, ty, w_tiles, h_tiles)

## Draw a gym building with typed roof/wall.
func gym_building(tx: int, ty: int, w_tiles: int = 6, h_tiles: int = 4, gym_type: String = "rock") -> void:
	var roof_tile := "gym_roof_%s" % gym_type if T.has("gym_roof_%s" % gym_type) else "roof_green"
	var wall_tile := "gym_wall_%s" % gym_type if T.has("gym_wall_%s" % gym_type) else "wall_gray"
	fill(roof_tile, tx, ty, w_tiles, 1)
	for row in range(1, h_tiles):
		for col in w_tiles:
			if row == h_tiles - 1 and col == w_tiles / 2:
				put("door", tx + col, ty + row)
			else:
				put(wall_tile, tx + col, ty + row)
	if w_tiles >= 4:
		put("window", tx + 1, ty + 1)
		put("window", tx + w_tiles - 2, ty + 1)
	_add_wall(tx, ty, w_tiles, h_tiles)

# ── Nature helpers ───────────────────────────────────────────────

## Place a 2x2 tree with canopy quadrants.
func tree_2x2(tx: int, ty: int) -> void:
	put("tree_tl", tx, ty, true)
	put("tree_tr", tx + 1, ty, true)
	put("tree_bl", tx, ty + 1, true)
	put("tree_br", tx + 1, ty + 1, true)
	_add_wall(tx, ty, 2, 2)

## Fill an area with dense single-tile trees.
func tree_border(tx: int, ty: int, tw: int, th: int) -> void:
	fill("tree_full", tx, ty, tw, th, true)
	_add_wall(tx, ty, tw, th)

## Place rocks as a wall.
func rocks(tx: int, ty: int, tw: int, th: int) -> void:
	fill("rock", tx, ty, tw, th)
	_add_wall(tx, ty, tw, th)

# ── Path helpers ─────────────────────────────────────────────────

## Draw a dirt path rectangle with proper edges.
func path_rect(tx: int, ty: int, tw: int, th: int) -> void:
	# Corners
	put("dirt_corner_tl", tx, ty)
	put("dirt_corner_tr", tx + tw - 1, ty)
	put("dirt_corner_bl", tx, ty + th - 1)
	put("dirt_corner_br", tx + tw - 1, ty + th - 1)
	# Top/bottom edges
	fill("dirt_edge_top", tx + 1, ty, tw - 2, 1)
	fill("dirt_edge_bottom", tx + 1, ty + th - 1, tw - 2, 1)
	# Left/right edges
	fill("dirt_edge_left", tx, ty + 1, 1, th - 2)
	fill("dirt_edge_right", tx + tw - 1, ty + 1, 1, th - 2)
	# Interior
	if tw > 2 and th > 2:
		fill("dirt_path", tx + 1, ty + 1, tw - 2, th - 2)

## Draw a vertical path strip (no top/bottom edges — connects to transitions).
func path_v(tx: int, ty: int, tw: int, th: int) -> void:
	fill("dirt_edge_left", tx, ty, 1, th)
	fill("dirt_edge_right", tx + tw - 1, ty, 1, th)
	if tw > 2:
		fill("dirt_path", tx + 1, ty, tw - 2, th)

## Draw a horizontal path strip.
func path_h(tx: int, ty: int, tw: int, th: int) -> void:
	fill("dirt_edge_top", tx, ty, tw, 1)
	fill("dirt_edge_bottom", tx, ty + th - 1, tw, 1)
	if th > 2:
		fill("dirt_path", tx, ty + 1, tw, th - 2)

# ── Entity helpers ───────────────────────────────────────────────

func add_npc(pos: Vector2, dialogue_key: String, npc_color: Color = Color.WHITE,
		special_action: String = "", shop_id: String = "") -> void:
	var npc_scene := preload("res://scripts/overworld/NPC.gd")
	var npc := CharacterBody2D.new()
	npc.set_script(npc_scene)
	npc.position = pos
	npc.set("dialogue_key", dialogue_key)
	npc.set("npc_color", npc_color)
	npc.set("special_action", special_action)
	npc.set("shop_id", shop_id)
	add_child(npc)

func add_trainer(pos: Vector2, trainer_id: String, npc_color: Color = Color.WHITE) -> void:
	if GameState.is_trainer_defeated(trainer_id):
		return
	var trainer_scene := preload("res://scripts/overworld/Trainer.gd")
	var trainer := CharacterBody2D.new()
	trainer.set_script(trainer_scene)
	trainer.position = pos
	trainer.set("trainer_id", trainer_id)
	trainer.set("npc_color", npc_color)
	add_child(trainer)

func add_sign(pos: Vector2, dialogue_key: String) -> void:
	var sign_scene := preload("res://scripts/overworld/Sign.gd")
	var sign_node := StaticBody2D.new()
	sign_node.set_script(sign_scene)
	sign_node.position = pos
	sign_node.set("dialogue_key", dialogue_key)
	add_child(sign_node)

func add_encounter_zone(center: Vector2, shape_size: Vector2, map_id: String,
		zone_id: String, rate: float = 0.15) -> void:
	var zone_scene := preload("res://scripts/overworld/WildEncounterZone.gd")
	var zone := Area2D.new()
	zone.set_script(zone_scene)
	zone.position = center
	zone.set("map_id", map_id)
	zone.set("zone_id", zone_id)
	zone.set("encounter_rate", rate)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = shape_size
	col.shape = rect
	zone.add_child(col)
	add_child(zone)

func add_transition(center: Vector2, shape_size: Vector2, target: String, spawn: Vector2) -> void:
	var trans_scene := preload("res://scripts/overworld/MapTransition.gd")
	var trans := Area2D.new()
	trans.set_script(trans_scene)
	trans.position = center
	trans.set("target_scene", target)
	trans.set("spawn_position", spawn)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = shape_size
	col.shape = rect
	trans.add_child(col)
	add_child(trans)

func add_hm_block(pos: Vector2, hm_id: String, block_key: String,
		clear_key: String, flag_id: String) -> void:
	if GameState.get_flag(flag_id):
		return
	var hm_scene := preload("res://scripts/overworld/HMBlock.gd")
	var block := StaticBody2D.new()
	block.set_script(hm_scene)
	block.position = pos
	block.set("hm_id", hm_id)
	block.set("block_dialogue_key", block_key)
	block.set("clear_dialogue_key", clear_key)
	block.set("flag_id", flag_id)
	add_child(block)

# ── Collision wall (invisible StaticBody2D) ──────────────────────

func _add_wall(tx: int, ty: int, tw: int, th: int) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2((tx + tw * 0.5) * TILE_SIZE, (ty + th * 0.5) * TILE_SIZE)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tw * TILE_SIZE, th * TILE_SIZE)
	col.shape = rect
	body.add_child(col)
	add_child(body)

func add_wall_px(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos + size * 0.5
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	add_child(body)

# ── Border walls (screen edges) ─────────────────────────────────

func add_border_walls() -> void:
	var tw := MAP_W / TILE_SIZE
	var th := MAP_H / TILE_SIZE
	# Top
	add_wall_px(Vector2(0, -TILE_SIZE), Vector2(MAP_W, TILE_SIZE))
	# Bottom
	add_wall_px(Vector2(0, MAP_H), Vector2(MAP_W, TILE_SIZE))
	# Left
	add_wall_px(Vector2(-TILE_SIZE, 0), Vector2(TILE_SIZE, MAP_H))
	# Right
	add_wall_px(Vector2(MAP_W, 0), Vector2(TILE_SIZE, MAP_H))

# ── Player spawn ─────────────────────────────────────────────────

func _spawn_player() -> void:
	var player_scn := preload("res://scenes/overworld/entities/Player.tscn")
	_player_node = player_scn.instantiate()
	if GameState.pending_spawn_position != Vector2.ZERO:
		_player_node.position = GameState.pending_spawn_position
		GameState.pending_spawn_position = Vector2.ZERO
	else:
		_player_node.position = get_player_spawn()
	# Camera limits
	var cam: Camera2D = _player_node.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = MAP_W
		cam.limit_bottom = MAP_H
	add_child(_player_node)
