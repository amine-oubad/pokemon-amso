extends CanvasLayer
## Ecran titre moderne — Nouvelle Partie / Continuer.
## Layer 40 (au-dessus de tout). Affiché au lancement.

var _bg:          ColorRect
var _title_lbl:   Label
var _btn_new:     Button
var _btn_continue: Button
var _visible_flag := true

const C_BG     := Color(0.06, 0.06, 0.14)
const C_PANEL  := Color(0.10, 0.12, 0.22)
const C_ACCENT := Color(0.30, 0.55, 0.95)
const C_GOLD   := Color(0.96, 0.80, 0.22)
const C_TEXT   := Color(0.90, 0.90, 0.95)
const C_TEXT2  := Color(0.50, 0.50, 0.65)

func _ready() -> void:
	layer = 40
	_build_ui()
	var has_any_save := false
	for i in SaveManager.NUM_SLOTS:
		if SaveManager.has_save(i):
			has_any_save = true; break
	_btn_continue.visible = has_any_save

func _build_ui() -> void:
	# Background
	_bg = ColorRect.new()
	_bg.color    = C_BG
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	# Subtle top gradient
	var grad_top := ColorRect.new()
	grad_top.color    = Color(0.12, 0.10, 0.25, 0.6)
	grad_top.position = Vector2.ZERO
	grad_top.size     = Vector2(320, 80)
	add_child(grad_top)

	# Accent line top
	var accent_line := ColorRect.new()
	accent_line.color    = C_ACCENT
	accent_line.position = Vector2(0, 0)
	accent_line.size     = Vector2(320, 2)
	add_child(accent_line)

	# Pokemon artwork (Pikachu as mascot)
	var mascot := SpriteLoader.make_sprite("025", "artwork", Vector2(72, 72))
	mascot.position = Vector2(124, 16)
	add_child(mascot)

	# Title
	_title_lbl = Label.new()
	_title_lbl.text     = "POKEMON AMSO"
	_title_lbl.position = Vector2(72, 94)
	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", C_GOLD)
	add_child(_title_lbl)

	# Subtitle
	var sub := Label.new()
	sub.text     = "Fan-game Godot 4"
	sub.position = Vector2(112, 114)
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", C_TEXT2)
	add_child(sub)

	# Separator
	var sep := ColorRect.new()
	sep.color    = Color(0.20, 0.22, 0.35)
	sep.position = Vector2(80, 128)
	sep.size     = Vector2(160, 1)
	add_child(sep)

	# Button "Nouvelle Partie"
	_btn_new = Button.new()
	_btn_new.text     = "NOUVELLE PARTIE"
	_btn_new.position = Vector2(90, 142)
	_btn_new.size     = Vector2(140, 26)
	_btn_new.add_theme_font_size_override("font_size", 9)
	_btn_new.pressed.connect(_on_new_game)
	add_child(_btn_new)

	# Button "Continuer"
	_btn_continue = Button.new()
	_btn_continue.text     = "CONTINUER"
	_btn_continue.position = Vector2(90, 174)
	_btn_continue.size     = Vector2(140, 26)
	_btn_continue.add_theme_font_size_override("font_size", 9)
	_btn_continue.pressed.connect(_on_continue)
	add_child(_btn_continue)

	# Accent line bottom
	var accent_bot := ColorRect.new()
	accent_bot.color    = C_ACCENT
	accent_bot.position = Vector2(0, 238)
	accent_bot.size     = Vector2(320, 2)
	add_child(accent_bot)

	# Credits
	var credits := Label.new()
	credits.text     = "amine-oubad/pokemon-amso"
	credits.position = Vector2(88, 222)
	credits.add_theme_font_size_override("font_size", 6)
	credits.add_theme_color_override("font_color", C_TEXT2)
	add_child(credits)

func _on_new_game() -> void:
	_hide_title()
	# Show starter selection if player has no Pokemon
	if GameState.team.is_empty():
		StarterSelect.show_selection()

func _on_continue() -> void:
	# Load the most recent save across all slots
	var best_slot := -1
	var best_time := 0
	for i in SaveManager.NUM_SLOTS:
		if SaveManager.has_save(i):
			var info: Dictionary = SaveManager.get_save_info(i)
			var t: int = info.get("timestamp", 0)
			if t > best_time:
				best_time = t
				best_slot = i
	if best_slot < 0:
		return  # No valid save found
	SaveManager.load_slot(best_slot)
	_hide_title()

func _hide_title() -> void:
	_visible_flag = false
	for child in get_children():
		if child is CanvasItem:
			child.hide()

func is_active() -> bool:
	return _visible_flag

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	get_viewport().set_input_as_handled()
