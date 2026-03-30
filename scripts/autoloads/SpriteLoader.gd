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

## Précharge tous les sprites en arrière-plan (optionnel)
func preload_all() -> void:
	for sid: String in GameData.pokemon_data.keys():
		_load_sprite("front", sid)
		_load_sprite("back", sid)
