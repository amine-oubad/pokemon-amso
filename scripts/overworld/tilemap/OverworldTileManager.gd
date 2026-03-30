extends Node
## Pipeline 1 — Gestionnaire de TileMap pour l'overworld.
## Remplace les ColorRect proceduraux par un systeme TileMap Godot 4.
## Autoload singleton.
##
## Usage dans un script de map :
##   var tilemap := OverworldTileManager.create_tilemap("grass")
##   OverworldTileManager.paint_rect(tilemap, Rect2i(0, 0, 20, 15), "grass_base")
##   add_child(tilemap)

const TILE_SIZE := 16

# ── Palettes de biome ─────────────────────────────────────────────────────────
# Chaque biome definit ses couleurs de tiles en attendant les assets PNG.
# Quand les tilesets PNG seront prets, on remplace par des atlas textures.
const BIOME_PALETTES := {
	"grass": {
		"ground":      [Color(0.30, 0.56, 0.22), Color(0.28, 0.52, 0.20), Color(0.32, 0.58, 0.24), Color(0.26, 0.50, 0.18)],
		"path":        [Color(0.60, 0.50, 0.33), Color(0.58, 0.48, 0.30), Color(0.62, 0.52, 0.35)],
		"tall_grass":  [Color(0.18, 0.40, 0.10), Color(0.20, 0.42, 0.12)],
		"water":       [Color(0.12, 0.53, 0.90), Color(0.18, 0.58, 0.92)],
		"flower":      [Color(0.85, 0.30, 0.35), Color(0.90, 0.75, 0.20), Color(0.60, 0.30, 0.80)],
	},
	"forest": {
		"ground":      [Color(0.15, 0.38, 0.10), Color(0.13, 0.35, 0.08), Color(0.17, 0.40, 0.12)],
		"path":        [Color(0.45, 0.38, 0.25), Color(0.42, 0.35, 0.22)],
		"tall_grass":  [Color(0.10, 0.30, 0.05), Color(0.12, 0.32, 0.07)],
		"tree_trunk":  [Color(0.35, 0.25, 0.15)],
		"tree_canopy": [Color(0.12, 0.42, 0.08), Color(0.10, 0.38, 0.06), Color(0.14, 0.44, 0.10)],
	},
	"city": {
		"ground":      [Color(0.55, 0.55, 0.50), Color(0.52, 0.52, 0.47)],
		"path":        [Color(0.65, 0.63, 0.58), Color(0.62, 0.60, 0.55)],
		"building":    [Color(0.75, 0.72, 0.68)],
	},
	"cave": {
		"ground":      [Color(0.30, 0.28, 0.32), Color(0.28, 0.26, 0.30)],
		"wall":        [Color(0.22, 0.20, 0.25), Color(0.20, 0.18, 0.22)],
		"rock":        [Color(0.40, 0.38, 0.35)],
	},
	"snow": {
		"ground":      [Color(0.90, 0.92, 0.95), Color(0.88, 0.90, 0.93)],
		"path":        [Color(0.80, 0.82, 0.85), Color(0.78, 0.80, 0.83)],
		"ice":         [Color(0.70, 0.88, 0.95), Color(0.65, 0.85, 0.92)],
	},
	"beach": {
		"ground":      [Color(0.92, 0.85, 0.65), Color(0.90, 0.82, 0.60)],
		"water":       [Color(0.12, 0.60, 0.85), Color(0.18, 0.65, 0.88)],
		"wet_sand":    [Color(0.78, 0.72, 0.50)],
	},
}

# ── Cache de TileSets ─────────────────────────────────────────────────────────
var _tileset_cache := {}

func _ready() -> void:
	print("[OverworldTileManager] Pret — %d biomes disponibles" % BIOME_PALETTES.size())

# ── Creation de TileMap ───────────────────────────────────────────────────────

## Cree un TileMap avec un TileSet procedural pour le biome donne.
## Plus tard, quand les assets PNG seront prets, on chargera les atlas ici.
func create_tilemap(biome: String) -> TileMap:
	var tm := TileMap.new()
	tm.tile_set = _get_or_create_tileset(biome)
	return tm

## Peint une zone rectangulaire avec un type de tile.
func paint_rect(tm: TileMap, rect: Rect2i, tile_type: String, layer: int = 0) -> void:
	var source_id := _get_source_id(tm.tile_set, tile_type)
	if source_id < 0:
		return
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			# Utiliser une variation aleatoire pour eviter la repetition
			var atlas_x := randi() % _get_tile_count(tm.tile_set, source_id)
			tm.set_cell(layer, Vector2i(x, y), source_id, Vector2i(atlas_x, 0))

## Peint une seule tile.
func paint_tile(tm: TileMap, pos: Vector2i, tile_type: String, layer: int = 0) -> void:
	var source_id := _get_source_id(tm.tile_set, tile_type)
	if source_id < 0:
		return
	var atlas_x := randi() % _get_tile_count(tm.tile_set, source_id)
	tm.set_cell(layer, pos, source_id, Vector2i(atlas_x, 0))

# ── TileSet PNG (quand les assets seront prets) ──────────────────────────────

## Charge un tileset depuis un fichier PNG atlas.
## Appeler cette methode quand les tilesets Canva/Aseprite seront prets.
func load_tileset_from_png(biome: String, png_path: String, columns: int = 16) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	if ResourceLoader.exists(png_path):
		var tex: Texture2D = load(png_path)
		var source := TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

		# Creer les tiles de l'atlas
		var tex_width := int(tex.get_width()) / TILE_SIZE
		var tex_height := int(tex.get_height()) / TILE_SIZE
		for y in range(tex_height):
			for x in range(tex_width):
				source.create_tile(Vector2i(x, y))

		ts.add_source(source)
		_tileset_cache[biome + "_png"] = ts
		print("[OverworldTileManager] Tileset PNG charge : %s (%dx%d tiles)" % [biome, tex_width, tex_height])

	return ts

# ── Creation de TileSet procedural ────────────────────────────────────────────

func _get_or_create_tileset(biome: String) -> TileSet:
	if _tileset_cache.has(biome):
		return _tileset_cache[biome]

	# Verifier d'abord si un tileset PNG existe
	var png_path := "res://assets/tilesets/%s.png" % biome
	if ResourceLoader.exists(png_path):
		return load_tileset_from_png(biome, png_path)

	# Sinon, creer un tileset procedural (colorRect-based)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var palette: Dictionary = BIOME_PALETTES.get(biome, BIOME_PALETTES["grass"])
	var source_id := 0

	for tile_type in palette:
		var colors: Array = palette[tile_type]
		# Creer une image procedural pour ce type de tile
		var img := Image.create(TILE_SIZE * colors.size(), TILE_SIZE, false, Image.FORMAT_RGBA8)
		for i in range(colors.size()):
			var col: Color = colors[i]
			var x_off := i * TILE_SIZE
			# Remplir le tile de base
			for px in range(TILE_SIZE):
				for py in range(TILE_SIZE):
					img.set_pixel(x_off + px, py, col)
			# Ajouter du bruit subtil pour la profondeur
			for _n in range(12):
				var nx := x_off + randi() % TILE_SIZE
				var ny := randi() % TILE_SIZE
				var base_col := img.get_pixel(nx, ny)
				var noise_col := base_col.darkened(randf_range(0.02, 0.08))
				img.set_pixel(nx, ny, noise_col)

		var tex := ImageTexture.create_from_image(img)
		var source := TileSetAtlasSource.new()
		source.texture = tex
		source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
		for i in range(colors.size()):
			source.create_tile(Vector2i(i, 0))

		ts.add_source(source, source_id)
		# Stocker le mapping type -> source_id dans les metadonnees
		ts.set_bmeta("src_%s" % tile_type, source_id)
		ts.set_bmeta("count_%s" % tile_type, colors.size())
		source_id += 1

	_tileset_cache[biome] = ts
	return ts

func _get_source_id(ts: TileSet, tile_type: String) -> int:
	var key := "src_%s" % tile_type
	if ts.has_bmeta(key):
		return ts.get_bmeta(key)
	return -1

func _get_tile_count(ts: TileSet, source_id: int) -> int:
	# Chercher le count correspondant
	for key in ["ground", "path", "tall_grass", "water", "flower", "tree_trunk",
				"tree_canopy", "building", "wall", "rock", "ice", "wet_sand"]:
		if ts.has_bmeta("src_%s" % key) and ts.get_bmeta("src_%s" % key) == source_id:
			if ts.has_bmeta("count_%s" % key):
				return ts.get_bmeta("count_%s" % key)
	return 1

# ── Parallax Background ──────────────────────────────────────────────────────

## Cree un ParallaxBackground avec des couches de profondeur.
func create_parallax(biome: String) -> ParallaxBackground:
	var pb := ParallaxBackground.new()

	# Couche 1 — ciel (mouvement tres lent)
	var sky_layer := ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.1, 0.1)
	var sky_colors := _get_sky_colors(biome)
	var sky_rect := ColorRect.new()
	sky_rect.size = Vector2(640, 480)
	sky_rect.position = Vector2(-160, -120)
	sky_rect.color = sky_colors[0]
	sky_layer.add_child(sky_rect)
	pb.add_child(sky_layer)

	# Couche 2 — montagnes/arbres lointains (mouvement lent)
	var far_layer := ParallaxLayer.new()
	far_layer.motion_scale = Vector2(0.3, 0.3)
	var far_elements := _create_far_layer(biome)
	far_layer.add_child(far_elements)
	pb.add_child(far_layer)

	return pb

func _get_sky_colors(biome: String) -> Array:
	match biome:
		"cave":  return [Color(0.08, 0.06, 0.12)]
		"snow":  return [Color(0.75, 0.82, 0.90)]
		_:       return [Color(0.45, 0.70, 0.95)]

func _create_far_layer(biome: String) -> Control:
	var container := Control.new()
	match biome:
		"grass", "city":
			# Collines vertes lointaines
			for i in range(8):
				var hill := ColorRect.new()
				hill.size = Vector2(randi_range(60, 120), randi_range(20, 40))
				hill.position = Vector2(i * 80 - 160, 180 - hill.size.y)
				hill.color = Color(0.25, 0.50, 0.20, 0.5)
				container.add_child(hill)
		"forest":
			# Arbres sombres lointains
			for i in range(12):
				var tree := ColorRect.new()
				tree.size = Vector2(randi_range(16, 24), randi_range(40, 60))
				tree.position = Vector2(i * 55 - 160, 180 - tree.size.y)
				tree.color = Color(0.08, 0.25, 0.05, 0.6)
				container.add_child(tree)
		"snow":
			# Montagnes enneigees
			for i in range(5):
				var mtn := ColorRect.new()
				mtn.size = Vector2(randi_range(80, 140), randi_range(50, 80))
				mtn.position = Vector2(i * 130 - 160, 180 - mtn.size.y)
				mtn.color = Color(0.80, 0.82, 0.88, 0.4)
				container.add_child(mtn)
	return container

# ── Cycle jour/nuit ───────────────────────────────────────────────────────────

## Cree un CanvasModulate pour le cycle jour/nuit.
## Le script appelant doit appeler update_day_night() dans _process().
func create_day_night_modulate() -> CanvasModulate:
	var cm := CanvasModulate.new()
	cm.color = Color.WHITE  # midi par defaut
	return cm

## Met a jour la teinte selon l'heure du jeu (0.0 = minuit, 12.0 = midi, 24.0 = minuit).
func update_day_night(cm: CanvasModulate, game_hour: float) -> void:
	var color: Color
	if game_hour < 5.0:
		# Nuit profonde
		color = Color(0.25, 0.25, 0.45)
	elif game_hour < 7.0:
		# Aube
		var t := (game_hour - 5.0) / 2.0
		color = Color(0.25, 0.25, 0.45).lerp(Color(0.95, 0.80, 0.70), t)
	elif game_hour < 10.0:
		# Matin
		var t := (game_hour - 7.0) / 3.0
		color = Color(0.95, 0.80, 0.70).lerp(Color.WHITE, t)
	elif game_hour < 17.0:
		# Journee
		color = Color.WHITE
	elif game_hour < 19.0:
		# Coucher de soleil
		var t := (game_hour - 17.0) / 2.0
		color = Color.WHITE.lerp(Color(1.0, 0.75, 0.55), t)
	elif game_hour < 21.0:
		# Crepuscule
		var t := (game_hour - 19.0) / 2.0
		color = Color(1.0, 0.75, 0.55).lerp(Color(0.35, 0.30, 0.50), t)
	else:
		# Nuit
		var t := (game_hour - 21.0) / 3.0
		color = Color(0.35, 0.30, 0.50).lerp(Color(0.25, 0.25, 0.45), t)

	cm.color = color

# ── Weather Particles ─────────────────────────────────────────────────────────

## Cree un systeme de particules meteo.
func create_weather(weather_type: String) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.z_index = 100

	var mat := ParticleProcessMaterial.new()

	match weather_type:
		"rain":
			particles.amount = 80
			particles.lifetime = 0.8
			mat.direction = Vector3(0.1, 1.0, 0.0)
			mat.initial_velocity_min = 200.0
			mat.initial_velocity_max = 280.0
			mat.gravity = Vector3(20.0, 500.0, 0.0)
			mat.scale_min = 0.3
			mat.scale_max = 0.5
			mat.color = Color(0.6, 0.7, 0.9, 0.5)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(200.0, 10.0, 0.0)
			particles.position = Vector2(160, -20)

		"snow":
			particles.amount = 40
			particles.lifetime = 3.0
			mat.direction = Vector3(0.0, 1.0, 0.0)
			mat.initial_velocity_min = 20.0
			mat.initial_velocity_max = 40.0
			mat.gravity = Vector3(0.0, 30.0, 0.0)
			mat.scale_min = 0.4
			mat.scale_max = 0.8
			mat.color = Color(0.95, 0.95, 1.0, 0.7)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(200.0, 10.0, 0.0)
			particles.position = Vector2(160, -20)

		"leaves":
			particles.amount = 15
			particles.lifetime = 4.0
			mat.direction = Vector3(1.0, 1.0, 0.0)
			mat.initial_velocity_min = 15.0
			mat.initial_velocity_max = 30.0
			mat.gravity = Vector3(10.0, 15.0, 0.0)
			mat.angular_velocity_min = -90.0
			mat.angular_velocity_max = 90.0
			mat.scale_min = 0.5
			mat.scale_max = 1.0
			mat.color = Color(0.35, 0.60, 0.15, 0.6)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(200.0, 10.0, 0.0)
			particles.position = Vector2(0, -20)

		"fog":
			particles.amount = 8
			particles.lifetime = 6.0
			mat.direction = Vector3(1.0, 0.0, 0.0)
			mat.initial_velocity_min = 5.0
			mat.initial_velocity_max = 12.0
			mat.gravity = Vector3.ZERO
			mat.scale_min = 8.0
			mat.scale_max = 14.0
			mat.color = Color(0.85, 0.85, 0.90, 0.15)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(200.0, 140.0, 0.0)
			particles.position = Vector2(160, 120)

		"sandstorm":
			particles.amount = 60
			particles.lifetime = 1.5
			mat.direction = Vector3(1.0, 0.2, 0.0)
			mat.initial_velocity_min = 100.0
			mat.initial_velocity_max = 160.0
			mat.gravity = Vector3(50.0, 20.0, 0.0)
			mat.scale_min = 0.3
			mat.scale_max = 0.6
			mat.color = Color(0.85, 0.75, 0.50, 0.4)
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(10.0, 140.0, 0.0)
			particles.position = Vector2(-20, 120)

	particles.process_material = mat
	return particles

# ── Shadow overlay ────────────────────────────────────────────────────────────

## Cree un sprite d'ombre sous un objet (arbre, batiment).
func create_shadow(size: Vector2, opacity: float = 0.25) -> ColorRect:
	var shadow := ColorRect.new()
	shadow.size = size
	shadow.color = Color(0.0, 0.0, 0.0, opacity)
	shadow.z_index = -1
	return shadow
