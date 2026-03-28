extends CanvasLayer
## Écran de sélection du Pokémon de départ.
## S'affiche automatiquement si l'équipe du joueur est vide.
## Usage : StarterSelect.show_selection() — appelé par la map de départ.

signal starter_chosen

const FONT_SIZE := 8
const STARTERS := [
	{"id": "001", "name": "Bulbasaur", "type": "Grass/Poison", "color": Color(0.30, 0.75, 0.30)},
	{"id": "004", "name": "Charmander", "type": "Fire", "color": Color(0.90, 0.35, 0.10)},
	{"id": "007", "name": "Squirtle", "type": "Water", "color": Color(0.25, 0.55, 0.95)},
]

var _active: bool = false
var _selected: int = 0
var _confirmed: bool = false
var _buttons: Array = []
var _desc_label: Label
var _confirm_panel: Control
var _confirm_yes: Button
var _confirm_no: Button

func _ready() -> void:
	layer = 30
	visible = false
	set_process_input(false)

func show_selection() -> void:
	if _active:
		return
	_active = true
	_selected = 0
	_confirmed = false
	visible = true
	set_process_input(true)
	_build_ui()

func _build_ui() -> void:
	# Clear previous
	for c in get_children():
		c.queue_free()
	_buttons.clear()

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "Professeur Chen"
	title.position = Vector2(80, 10)
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choisis ton premier Pokémon !"
	subtitle.position = Vector2(52, 28)
	subtitle.add_theme_font_size_override("font_size", FONT_SIZE)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	add_child(subtitle)

	# Starter cards
	for i in range(STARTERS.size()):
		var s := STARTERS[i]
		var card_x := 12 + i * 102
		var card := _build_card(Vector2(card_x, 52), s, i)
		add_child(card)

	# Description
	_desc_label = Label.new()
	_desc_label.position = Vector2(12, 180)
	_desc_label.size = Vector2(296, 30)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_desc_label.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	add_child(_desc_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "← → Choisir   Z Confirmer"
	hint.position = Vector2(72, 222)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	add_child(hint)

	# Confirm dialog (hidden)
	_confirm_panel = Control.new()
	_confirm_panel.visible = false
	add_child(_confirm_panel)

	var cpanel_bg := ColorRect.new()
	cpanel_bg.color = Color(0.0, 0.0, 0.0, 0.80)
	cpanel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.add_child(cpanel_bg)

	var cbox := ColorRect.new()
	cbox.color = Color(0.10, 0.10, 0.20)
	cbox.position = Vector2(60, 80)
	cbox.size = Vector2(200, 80)
	_confirm_panel.add_child(cbox)

	var cborder := ColorRect.new()
	cborder.color = Color.WHITE
	cborder.position = Vector2(58, 78)
	cborder.size = Vector2(204, 84)
	_confirm_panel.add_child(cborder)
	cborder.z_index = -1
	cbox.z_index = 0

	var ctext := Label.new()
	ctext.position = Vector2(68, 88)
	ctext.size = Vector2(184, 20)
	ctext.add_theme_font_size_override("font_size", FONT_SIZE)
	ctext.add_theme_color_override("font_color", Color.WHITE)
	_confirm_panel.add_child(ctext)
	ctext.name = "ConfirmText"

	_confirm_yes = Button.new()
	_confirm_yes.text = "OUI"
	_confirm_yes.position = Vector2(90, 120)
	_confirm_yes.size = Vector2(50, 20)
	_confirm_yes.add_theme_font_size_override("font_size", FONT_SIZE)
	_confirm_yes.pressed.connect(_on_confirm_yes)
	_confirm_panel.add_child(_confirm_yes)

	_confirm_no = Button.new()
	_confirm_no.text = "NON"
	_confirm_no.position = Vector2(170, 120)
	_confirm_no.size = Vector2(50, 20)
	_confirm_no.add_theme_font_size_override("font_size", FONT_SIZE)
	_confirm_no.pressed.connect(_on_confirm_no)
	_confirm_panel.add_child(_confirm_no)

	_refresh()

func _build_card(pos: Vector2, starter: Dictionary, idx: int) -> Control:
	var card := Control.new()
	card.position = pos
	card.size = Vector2(96, 120)

	# Background
	var bg := ColorRect.new()
	bg.size = Vector2(96, 120)
	bg.color = Color(0.12, 0.12, 0.22)
	bg.name = "CardBG"
	card.add_child(bg)

	# Border
	var border := ColorRect.new()
	border.position = Vector2(-1, -1)
	border.size = Vector2(98, 122)
	border.color = Color(0.30, 0.30, 0.40)
	border.name = "CardBorder"
	border.z_index = -1
	card.add_child(border)

	# Pokemon color block (sprite placeholder)
	var sprite_bg := ColorRect.new()
	sprite_bg.position = Vector2(24, 12)
	sprite_bg.size = Vector2(48, 48)
	sprite_bg.color = starter.color
	card.add_child(sprite_bg)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = starter.name
	name_lbl.position = Vector2(4, 68)
	name_lbl.size = Vector2(88, 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(name_lbl)

	# Type
	var type_lbl := Label.new()
	type_lbl.text = starter.type
	type_lbl.position = Vector2(4, 84)
	type_lbl.size = Vector2(88, 14)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 7)
	type_lbl.add_theme_color_override("font_color", starter.color)
	card.add_child(type_lbl)

	# Level
	var lvl_lbl := Label.new()
	lvl_lbl.text = "Lv. 5"
	lvl_lbl.position = Vector2(4, 98)
	lvl_lbl.size = Vector2(88, 14)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 7)
	lvl_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.60))
	card.add_child(lvl_lbl)

	# Button overlay
	var btn := Button.new()
	btn.position = Vector2.ZERO
	btn.size = Vector2(96, 120)
	btn.modulate.a = 0.0
	var i := idx
	btn.pressed.connect(func() -> void: _on_card_pressed(i))
	card.add_child(btn)
	_buttons.append(card)

	return card

func _refresh() -> void:
	for i in range(_buttons.size()):
		var card: Control = _buttons[i]
		var bg: ColorRect = card.get_node("CardBG")
		var border: ColorRect = card.get_node("CardBorder")
		if i == _selected:
			bg.color = Color(0.18, 0.18, 0.35)
			border.color = Color.YELLOW
		else:
			bg.color = Color(0.12, 0.12, 0.22)
			border.color = Color(0.30, 0.30, 0.40)

	var s := STARTERS[_selected]
	var pdata: Dictionary = GameData.pokemon_data.get(s.id, {})
	var base: Dictionary = pdata.get("base_stats", {})
	_desc_label.text = "%s — PV:%d ATK:%d DEF:%d SP.ATK:%d SP.DEF:%d VIT:%d" % [
		s.name, base.get("hp", 0), base.get("atk", 0), base.get("def", 0),
		base.get("sp_atk", 0), base.get("sp_def", 0), base.get("speed", 0)
	]

func _on_card_pressed(idx: int) -> void:
	_selected = idx
	_refresh()
	_show_confirm()

func _show_confirm() -> void:
	_confirmed = true
	_confirm_panel.visible = true
	var ctext: Label = _confirm_panel.get_node("ConfirmText")
	ctext.text = "Choisir %s ?" % STARTERS[_selected].name
	_confirm_yes.grab_focus()

func _on_confirm_yes() -> void:
	var s := STARTERS[_selected]
	var starter := PokemonInstance.create(s.id, 5)
	GameState.team.append(starter)
	GameState.register_seen(s.id)
	GameState.register_caught(s.id)
	GameState.set_flag("starter_chosen")
	_close()

func _on_confirm_no() -> void:
	_confirmed = false
	_confirm_panel.visible = false

func _close() -> void:
	_active = false
	visible = false
	set_process_input(false)
	starter_chosen.emit()

func _input(event: InputEvent) -> void:
	if not _active:
		return

	if _confirmed:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_on_confirm_no()
		return

	if event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		_selected = max(0, _selected - 1)
		_refresh()
	elif event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		_selected = mini(STARTERS.size() - 1, _selected + 1)
		_refresh()
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_show_confirm()
