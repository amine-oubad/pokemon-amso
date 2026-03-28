extends CanvasLayer
## Écran titre — Nouvelle Partie / Continuer.
## Layer 40 (au-dessus de tout). Affiché au lancement.

var _bg:          ColorRect
var _title_lbl:   Label
var _btn_new:     Button
var _btn_continue: Button
var _visible_flag := true

func _ready() -> void:
	layer = 40
	_build_ui()
	# Vérifier si une sauvegarde existe
	_btn_continue.visible = SaveManager.has_save(0)

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = Color(0.04, 0.04, 0.12)
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	# Logo / titre
	_title_lbl = Label.new()
	_title_lbl.text     = "POKÉMON AMSO"
	_title_lbl.position = Vector2(60, 32)
	_title_lbl.add_theme_font_size_override("font_size", 16)
	_title_lbl.add_theme_color_override("font_color", Color(0.96, 0.77, 0.18))
	add_child(_title_lbl)

	# Sous-titre
	var sub := Label.new()
	sub.text     = "Fan-game Godot 4"
	sub.position = Vector2(100, 58)
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.65))
	add_child(sub)

	# Décoration — rectangle Pokéball
	var ball_outer := ColorRect.new()
	ball_outer.position = Vector2(138, 78)
	ball_outer.size     = Vector2(44, 44)
	ball_outer.color    = Color(0.85, 0.20, 0.18)
	add_child(ball_outer)
	var ball_inner := ColorRect.new()
	ball_inner.position = Vector2(143, 98)
	ball_inner.size     = Vector2(34, 24)
	ball_inner.color    = Color.WHITE
	add_child(ball_inner)
	var ball_center := ColorRect.new()
	ball_center.position = Vector2(154, 95)
	ball_center.size     = Vector2(12, 12)
	ball_center.color    = Color(0.2, 0.2, 0.25)
	add_child(ball_center)

	# Bouton "Nouvelle Partie"
	_btn_new = Button.new()
	_btn_new.text     = "NOUVELLE PARTIE"
	_btn_new.position = Vector2(90, 140)
	_btn_new.size     = Vector2(140, 24)
	_btn_new.add_theme_font_size_override("font_size", 9)
	_btn_new.pressed.connect(_on_new_game)
	add_child(_btn_new)

	# Bouton "Continuer"
	_btn_continue = Button.new()
	_btn_continue.text     = "CONTINUER"
	_btn_continue.position = Vector2(90, 172)
	_btn_continue.size     = Vector2(140, 24)
	_btn_continue.add_theme_font_size_override("font_size", 9)
	_btn_continue.pressed.connect(_on_continue)
	add_child(_btn_continue)

	# Crédits
	var credits := Label.new()
	credits.text     = "amine-oubad/pokemon-amso"
	credits.position = Vector2(80, 220)
	credits.add_theme_font_size_override("font_size", 6)
	credits.add_theme_color_override("font_color", Color(0.35, 0.35, 0.50))
	add_child(credits)

func _on_new_game() -> void:
	_hide_title()

func _on_continue() -> void:
	SaveManager.load_game(0)
	_hide_title()

func _hide_title() -> void:
	_visible_flag = false
	_bg.hide()
	_title_lbl.hide()
	_btn_new.hide()
	_btn_continue.hide()
	# Cacher tous les enfants
	for child in get_children():
		if child is CanvasItem:
			child.hide()

func is_active() -> bool:
	return _visible_flag

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	# Bloquer tout input pendant l'écran titre
	get_viewport().set_input_as_handled()
