extends Node
## Chargeur de sprites Pokémon — charge les sprites front/back/artwork depuis assets/.
## Autoload singleton. Cache les textures en mémoire.

const SPRITE_DIR := "res://assets/sprites/pokemon"

var _cache := {}  # "front_001" -> ImageTexture

## Charge le sprite front d'un Pokémon (pour le combat — ennemi)
func get_front(pokemon_id: String) -> Texture2D:
	return _load_sprite("front", pokemon_id)

## Charge le sprite back d'un Pokémon (pour le combat — joueur)
func get_back(pokemon_id: String) -> Texture2D:
	return _load_sprite("back", pokemon_id)

## Charge l'artwork officiel HD (pour résumé, pokédex, starter select)
func get_artwork(pokemon_id: String) -> Texture2D:
	return _load_sprite("artwork", pokemon_id)

## Charge un sprite de type donné. Retourne null si non trouvé.
func _load_sprite(folder: String, pokemon_id: String) -> Texture2D:
	var key := "%s_%s" % [folder, pokemon_id]
	if _cache.has(key):
		return _cache[key]

	var path := "%s/%s/%s.png" % [SPRITE_DIR, folder, pokemon_id]
	if not ResourceLoader.exists(path):
		return null

	var tex: Texture2D = load(path)
	_cache[key] = tex
	return tex

## Crée un TextureRect prêt à l'emploi avec le sprite.
## Retourne un ColorRect fallback si le sprite n'existe pas.
func make_sprite(pokemon_id: String, folder: String, size: Vector2) -> Control:
	var tex := _load_sprite(folder, pokemon_id)
	if tex != null:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = size
		tr.size = size
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		return tr
	# Fallback — carré coloré avec "?" text
	var fb := ColorRect.new()
	fb.size = size
	fb.custom_minimum_size = size
	fb.color = Color(0.3, 0.3, 0.4, 0.6)
	var lbl := Label.new()
	lbl.text = "?" + pokemon_id
	lbl.position = Vector2(2, 2)
	lbl.add_theme_font_size_override("font_size", 7)
	fb.add_child(lbl)
	return fb

## Crée un Sprite2D (Node2D) au lieu d'un TextureRect (Control).
## Plus fiable dans un CanvasLayer car pas affecté par le layout system.
func make_sprite2d(pokemon_id: String, folder: String, target_size: float) -> Node2D:
	var tex := _load_sprite(folder, pokemon_id)
	if tex != null:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# Mettre à l'échelle pour atteindre target_size
		var tex_size: float = max(tex.get_width(), tex.get_height())
		if tex_size > 0:
			var sc: float = target_size / tex_size
			spr.scale = Vector2(sc, sc)
		spr.centered = false
		return spr
	# Fallback — carré coloré avec ID
	var node := Node2D.new()
	var cr := ColorRect.new()
	cr.size = Vector2(target_size, target_size)
	cr.color = Color(0.8, 0.2, 0.2, 0.7)
	node.add_child(cr)
	var lbl := Label.new()
	lbl.text = "?" + pokemon_id
	lbl.position = Vector2(4, 4)
	lbl.add_theme_font_size_override("font_size", 8)
	node.add_child(lbl)
	return node

## Précharge tous les sprites en arrière-plan (optionnel)
func preload_all() -> void:
	for sid: String in GameData.pokemon_data.keys():
		_load_sprite("front", sid)
		_load_sprite("back", sid)
