extends CanvasLayer
## Écran Game Over — affiché quand toute l'équipe est KO.
## Soigne l'équipe et respawn au dernier Centre Pokémon.
## Layer 38.

var _bg:       ColorRect
var _msg_lbl:  Label
var _btn:      Button
var _visible_flag := false

func _ready() -> void:
	layer = 38
	_build_ui()
	_hide()

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color    = Color(0.02, 0.02, 0.08, 0.96)
	_bg.position = Vector2.ZERO
	_bg.size     = Vector2(320, 240)
	add_child(_bg)

	_msg_lbl = Label.new()
	_msg_lbl.text     = "Tous vos Pokémon\nsont K.O. ..."
	_msg_lbl.position = Vector2(60, 60)
	_msg_lbl.add_theme_font_size_override("font_size", 12)
	_msg_lbl.add_theme_color_override("font_color", Color(0.90, 0.25, 0.20))
	add_child(_msg_lbl)

	var sub := Label.new()
	sub.text     = "Vous perdez connaissance et êtes ramené\nau Centre Pokémon le plus proche..."
	sub.position = Vector2(30, 120)
	sub.add_theme_font_size_override("font_size", 7)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(sub)

	_btn = Button.new()
	_btn.text     = "CONTINUER"
	_btn.position = Vector2(110, 170)
	_btn.size     = Vector2(100, 24)
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
	# Soigner l'équipe
	GameState.heal_team()
	# Perte d'argent (50%)
	var lost := int(GameState.money * 0.5)
	GameState.money -= lost
	# Respawn au Centre Pokémon de la dernière ville visitée
	GameState.pending_spawn_position = Vector2.ZERO
	_hide()
	GameState.pending_battle = {}
	EventBus.battle_ended.emit("lose")
	get_tree().change_scene_to_file(GameState.return_to_scene)

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	get_viewport().set_input_as_handled()
