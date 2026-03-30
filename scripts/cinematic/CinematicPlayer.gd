extends CanvasLayer
## Pipeline 3 — Lecteur de cinematiques.
## Gere les transitions overworld→combat, mega evolutions, story cutscenes,
## et entrees de champions d'arene.
## Autoload singleton (layer 90).
##
## Usage :
##   CinematicPlayer.play_transition("wild_battle")
##   CinematicPlayer.play_sequence("mega_charizard_x")
##   CinematicPlayer.play_story("intro", ["Bienvenue...", "Le monde..."])
##   CinematicPlayer.play_gym_intro("pierre", "Badge Roche")

signal cinematic_finished

const FADE_SPEED := 0.4

var _playing: bool = false
var _overlay: ColorRect
var _image_rect: TextureRect
var _text_label: Label
var _skip_label: Label
var _particles: GPUParticles2D

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func is_playing() -> bool:
	return _playing

func _build_ui() -> void:
	# Fond noir
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(_overlay)

	# Image centrale
	_image_rect = TextureRect.new()
	_image_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_image_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_image_rect.modulate.a = 0.0
	add_child(_image_rect)

	# Texte (bas de l'ecran)
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_text_label.offset_top = -50
	_text_label.offset_left = 16
	_text_label.offset_right = -16
	_text_label.offset_bottom = -8
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", 10)
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	_text_label.modulate.a = 0.0
	add_child(_text_label)

	# Indication skip
	_skip_label = Label.new()
	_skip_label.text = "[Z] Passer"
	_skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_label.offset_left = -70
	_skip_label.offset_top = -16
	_skip_label.offset_right = -4
	_skip_label.offset_bottom = -2
	_skip_label.add_theme_font_size_override("font_size", 6)
	_skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(_skip_label)

var _skip_requested := false

func _input(event: InputEvent) -> void:
	if not _playing:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_skip_requested = true
		get_viewport().set_input_as_handled()

# ══════════════════════════════════════════════════════════════════════════════
#  TRANSITIONS OVERWORLD → COMBAT
# ══════════════════════════════════════════════════════════════════════════════

## Transition visuelle avant un combat (wild, trainer, gym).
func play_transition(transition_type: String) -> void:
	_playing = true
	_skip_requested = false
	visible = true
	get_tree().paused = true

	match transition_type:
		"wild_battle":
			await _transition_wild()
		"trainer_battle":
			await _transition_trainer()
		"gym_battle":
			await _transition_gym()
		_:
			await _transition_wild()

	visible = false
	_playing = false
	get_tree().paused = false
	cinematic_finished.emit()

func _transition_wild() -> void:
	# Flash blanc rapide + bandes noires qui se ferment
	_overlay.color = Color(1.0, 1.0, 1.0, 0.0)

	# Essayer de charger une image de transition custom
	var tex := _try_load_image("res://assets/cinematics/transitions/wild_encounter_01.png")

	# Flash
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_overlay, "color:a", 1.0, 0.08)
	tw.tween_property(_overlay, "color:a", 0.0, 0.1)
	tw.tween_property(_overlay, "color:a", 1.0, 0.06)
	tw.tween_property(_overlay, "color:a", 0.0, 0.08)
	await tw.finished

	if _skip_requested: return

	if tex:
		_image_rect.texture = tex
		var tw2 := create_tween()
		tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw2.tween_property(_image_rect, "modulate:a", 1.0, 0.2)
		await tw2.finished
		await _wait_or_skip(0.5)
		var tw3 := create_tween()
		tw3.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw3.tween_property(_image_rect, "modulate:a", 0.0, 0.3)
		await tw3.finished
	else:
		# Transition procedurale : bandes horizontales
		_overlay.color = Color.BLACK
		_overlay.color.a = 0.0
		var bands: Array[ColorRect] = []
		for i in range(6):
			var band := ColorRect.new()
			band.size = Vector2(320, 0)
			band.position = Vector2(0, i * 40)
			band.color = Color.BLACK
			add_child(band)
			bands.append(band)

		var btw := create_tween().set_parallel(true)
		btw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		for band in bands:
			btw.tween_property(band, "size:y", 40.0, 0.3)
		await btw.finished

		await _wait_or_skip(0.2)

		for band in bands:
			band.queue_free()

func _transition_trainer() -> void:
	# Zoom + split screen horizontal
	_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

	# Bande superieure descend, bande inferieure monte
	var top_band := ColorRect.new()
	top_band.position = Vector2(0, -120)
	top_band.size = Vector2(320, 120)
	top_band.color = Color.BLACK
	add_child(top_band)

	var bot_band := ColorRect.new()
	bot_band.position = Vector2(0, 240)
	bot_band.size = Vector2(320, 120)
	bot_band.color = Color.BLACK
	add_child(bot_band)

	var tw := create_tween().set_parallel(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(top_band, "position:y", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(bot_band, "position:y", 120.0, 0.4).set_ease(Tween.EASE_OUT)
	await tw.finished

	if not _skip_requested:
		# Texte "VS" au centre
		_text_label.text = "VS"
		_text_label.set_anchors_preset(Control.PRESET_CENTER)
		_text_label.add_theme_font_size_override("font_size", 18)
		_text_label.add_theme_color_override("font_color", Color(0.96, 0.77, 0.19))
		var ttw := create_tween()
		ttw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		ttw.tween_property(_text_label, "modulate:a", 1.0, 0.2)
		await ttw.finished

		await _wait_or_skip(0.6)

	_text_label.modulate.a = 0.0
	_text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_text_label.add_theme_font_size_override("font_size", 10)
	_text_label.add_theme_color_override("font_color", Color.WHITE)
	top_band.queue_free()
	bot_band.queue_free()

func _transition_gym() -> void:
	# Effet dramatique : flash dore + fondu noir
	_overlay.color = Color(0.96, 0.77, 0.19, 0.0)

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_overlay, "color:a", 0.8, 0.3)
	tw.tween_property(_overlay, "color", Color(0, 0, 0, 1.0), 0.4)
	await tw.finished

	if not _skip_requested:
		await _wait_or_skip(0.3)

	_overlay.color.a = 0.0

# ══════════════════════════════════════════════════════════════════════════════
#  MEGA EVOLUTIONS
# ══════════════════════════════════════════════════════════════════════════════

## Joue la cinematique de mega evolution.
## pokemon_id : l'ID du Pokemon (ex: "006" pour Dracaufeu)
## mega_form : "x" ou "y" ou "" pour la forme standard
func play_mega_evolution(pokemon_id: String, mega_form: String = "") -> void:
	_playing = true
	_skip_requested = false
	visible = true
	get_tree().paused = true

	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

	# Chercher les frames de cinematique
	var folder := "res://assets/cinematics/mega_evolutions/"
	var base_name := "%s_mega_%s" % [pokemon_id, mega_form] if mega_form != "" else "%s_mega" % pokemon_id
	var frames: Array[Texture2D] = []

	for i in range(1, 9):
		var path := "%s%s_%02d.png" % [folder, base_name, i]
		var tex := _try_load_image(path)
		if tex:
			frames.append(tex)

	if frames.size() > 0:
		# Jouer les frames generees par Kimi
		await _play_image_sequence(frames, 0.4)
	else:
		# Animation procedurale de mega evolution
		await _procedural_mega_evolution(pokemon_id)

	_overlay.color.a = 0.0
	_image_rect.modulate.a = 0.0
	visible = false
	_playing = false
	get_tree().paused = false
	cinematic_finished.emit()

func _procedural_mega_evolution(pokemon_id: String) -> void:
	# Afficher le sprite du Pokemon
	var tex := SpriteLoader.get_front(pokemon_id)
	if tex:
		_image_rect.texture = tex
	_image_rect.modulate = Color(1, 1, 1, 0)

	# Fade in du Pokemon
	var tw1 := create_tween()
	tw1.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw1.tween_property(_image_rect, "modulate:a", 1.0, 0.5)
	await tw1.finished

	if _skip_requested: return

	# Texte
	_text_label.text = "L'energie Mega se dechaine !"
	var ttw := create_tween()
	ttw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ttw.tween_property(_text_label, "modulate:a", 1.0, 0.3)
	await ttw.finished

	await _wait_or_skip(1.0)
	if _skip_requested: return

	# Flash de transformation
	_overlay.color = Color(0.96, 0.77, 0.19, 0.0)
	var tw2 := create_tween()
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(_overlay, "color:a", 1.0, 0.3)
	await tw2.finished

	await _wait_or_skip(0.5)
	if _skip_requested: return

	# Pulsation
	for i in range(3):
		if _skip_requested: break
		_overlay.color = Color(1.0, 1.0, 1.0, 0.8)
		await _wait_or_skip(0.1)
		_overlay.color = Color(0.96, 0.77, 0.19, 0.6)
		await _wait_or_skip(0.1)

	_text_label.text = "MEGA EVOLUTION !"
	_text_label.add_theme_color_override("font_color", Color(0.96, 0.77, 0.19))

	await _wait_or_skip(1.5)

	# Fade out
	var tw3 := create_tween().set_parallel(true)
	tw3.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw3.tween_property(_overlay, "color:a", 0.0, 0.5)
	tw3.tween_property(_image_rect, "modulate:a", 0.0, 0.5)
	tw3.tween_property(_text_label, "modulate:a", 0.0, 0.5)
	await tw3.finished

	_text_label.add_theme_color_override("font_color", Color.WHITE)

# ══════════════════════════════════════════════════════════════════════════════
#  STORY SEQUENCES (illustrations + texte)
# ══════════════════════════════════════════════════════════════════════════════

## Joue une sequence narrative avec images et texte.
## sequence_id : identifiant du dossier dans assets/cinematics/story/
## texts : tableau de textes a afficher (un par image ou en surplus)
func play_story(sequence_id: String, texts: Array = []) -> void:
	_playing = true
	_skip_requested = false
	visible = true
	get_tree().paused = true

	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

	# Charger les images de la sequence
	var folder := "res://assets/cinematics/story/"
	var frames: Array[Texture2D] = []
	for i in range(1, 20):
		var path := "%s%s_%02d.png" % [folder, sequence_id, i]
		var tex := _try_load_image(path)
		if tex:
			frames.append(tex)
		else:
			break

	# Jouer chaque frame avec son texte
	for i in range(max(frames.size(), texts.size())):
		if _skip_requested: break

		# Image
		if i < frames.size():
			_image_rect.texture = frames[i]
			var itw := create_tween()
			itw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			itw.tween_property(_image_rect, "modulate:a", 1.0, 0.5)
			await itw.finished

		# Texte
		if i < texts.size():
			_text_label.text = texts[i]
			var ttw := create_tween()
			ttw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			ttw.tween_property(_text_label, "modulate:a", 1.0, 0.3)
			await ttw.finished

		# Attendre action joueur ou timeout
		_skip_requested = false
		await _wait_or_skip(4.0)

		# Transition entre frames
		if not _skip_requested:
			var ftw := create_tween().set_parallel(true)
			ftw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			ftw.tween_property(_image_rect, "modulate:a", 0.0, 0.3)
			ftw.tween_property(_text_label, "modulate:a", 0.0, 0.3)
			await ftw.finished

	# Fade out final
	_image_rect.modulate.a = 0.0
	_text_label.modulate.a = 0.0
	visible = false
	_playing = false
	get_tree().paused = false
	cinematic_finished.emit()

# ══════════════════════════════════════════════════════════════════════════════
#  GYM INTROS (portrait du champion)
# ══════════════════════════════════════════════════════════════════════════════

## Affiche l'intro d'un champion d'arene.
func play_gym_intro(leader_id: String, badge_name: String, leader_name: String = "") -> void:
	_playing = true
	_skip_requested = false
	visible = true
	get_tree().paused = true

	_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

	# Chercher le portrait du champion
	var portrait := _try_load_image("res://assets/cinematics/gym_intros/%s_intro.png" % leader_id)

	if portrait:
		_image_rect.texture = portrait
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_image_rect, "modulate:a", 1.0, 0.5)
		await tw.finished
	else:
		# Fond dramatique procedural
		_overlay.color = Color(0.15, 0.10, 0.25, 1.0)

	# Texte du champion
	if leader_name == "":
		leader_name = leader_id.capitalize()
	_text_label.text = "%s\nChampion d'Arene — %s" % [leader_name, badge_name]
	_text_label.add_theme_color_override("font_color", Color(0.96, 0.77, 0.19))
	var ttw := create_tween()
	ttw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ttw.tween_property(_text_label, "modulate:a", 1.0, 0.4)
	await ttw.finished

	await _wait_or_skip(2.5)

	# Fade out
	var ftw := create_tween().set_parallel(true)
	ftw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ftw.tween_property(_image_rect, "modulate:a", 0.0, 0.4)
	ftw.tween_property(_text_label, "modulate:a", 0.0, 0.4)
	ftw.tween_property(_overlay, "color:a", 0.0, 0.4)
	await ftw.finished

	_text_label.add_theme_color_override("font_color", Color.WHITE)
	visible = false
	_playing = false
	get_tree().paused = false
	cinematic_finished.emit()

# ══════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _try_load_image(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _play_image_sequence(frames: Array[Texture2D], hold_time: float = 0.5) -> void:
	for i in range(frames.size()):
		if _skip_requested: break
		_image_rect.texture = frames[i]

		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_image_rect, "modulate:a", 1.0, 0.2)
		await tw.finished

		await _wait_or_skip(hold_time)
		if _skip_requested: break

		if i < frames.size() - 1:
			var tw2 := create_tween()
			tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw2.tween_property(_image_rect, "modulate:a", 0.0, 0.15)
			await tw2.finished

func _wait_or_skip(duration: float) -> void:
	_skip_requested = false
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(func(): pass)  # Keep reference alive
	while timer.time_left > 0.0:
		if _skip_requested:
			return
		await get_tree().process_frame
