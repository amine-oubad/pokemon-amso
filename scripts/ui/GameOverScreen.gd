extends CanvasLayer
## Ecran Game Over — style moderne.
## Soigne l'equipe et respawn au dernier Centre Pokemon.
## Layer 38.

var _bg:       ColorRect
var _msg_lbl:  Label
var _btn:      Button
var _visible_flag := false

const C_BG    := Color(0.04, 0.04, 0.10)
const C_RED   := Color(0.85, 0.18, 0.15)
const C_TEXT  := Color(0.90, 0.90, 0.95)
const C_TEXT2 := Color(0.50, 0.50, 0.62)

func _ready() -> void:
	layer = 38
	_build_ui()
	_hide()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = C_BG
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	# Red accent lines
	var top_line := ColorRect.new()
	top_line.color = C_RED
	top_line.position = Vector2(0, 0)
	top_line.size = Vector2(320, 2)
	add_child(top_line)

	var bot_line := ColorRect.new()
	bot_line.color = C_RED
	bot_line.position = Vector2(0, 238)
	bot_line.size = Vector2(320, 2)
	add_child(bot_line)

	# Fainted pokemon icon (Pikachu)
	var icon := SpriteLoader.make_sprite("025", "front", Vector2(48, 48))
	icon.position = Vector2(136, 30)
	icon.modulate = Color(0.5, 0.5, 0.5, 0.7)
	add_child(icon)

	_msg_lbl = Label.new()
	_msg_lbl.text     = "Tous vos Pokemon\nsont K.O. ..."
	_msg_lbl.position = Vector2(80, 86)
	_msg_lbl.add_theme_font_size_override("font_size", 11)
	_msg_lbl.add_theme_color_override("font_color", C_RED)
	add_child(_msg_lbl)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.18, 0.18, 0.28)
	sep.position = Vector2(60, 120)
	sep.size = Vector2(200, 1)
	add_child(sep)

	var sub := Label.new()
	sub.text     = "Vous perdez connaissance et etes ramene\nau Centre Pokemon le plus proche..."
	sub.position = Vector2(34, 130)
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", C_TEXT2)
	add_child(sub)

	_btn = Button.new()
	_btn.text     = "CONTINUER"
	_btn.position = Vector2(110, 172)
	_btn.size     = Vector2(100, 26)
	_btn.add_theme_font_size_override("font_size", 9)
	_btn.pressed.connect(_on_continue)
	add_child(_btn)

func show_game_over() -> void:
	_visible_flag = true
	for child in get_children():
		if child is CanvasItem:
			child.show()

func _hide() -> void:
	_visible_flag = false
	for child in get_children():
		if child is CanvasItem:
			child.hide()

func is_active() -> bool:
	return _visible_flag

func _on_continue() -> void:
	GameState.heal_team()
	var lost := int(GameState.money * 0.5)
	GameState.money -= lost
	GameState.pending_spawn_position = Vector2.ZERO
	_hide()
	GameState.pending_battle = {}
	EventBus.battle_ended.emit("lose")
	get_tree().change_scene_to_file(GameState.return_to_scene)

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	get_viewport().set_input_as_handled()
