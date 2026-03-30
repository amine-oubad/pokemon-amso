extends CanvasLayer
## Ecran de selection du Pokemon de depart — style moderne.
## S'affiche automatiquement si l'equipe du joueur est vide.

signal starter_chosen

const FONT_SIZE := 8
const C_BG      := Color(0.06, 0.06, 0.14)
const C_PANEL   := Color(0.12, 0.14, 0.24)
const C_BORDER  := Color(0.25, 0.28, 0.42)
const C_SELECT  := Color(0.30, 0.55, 0.95)
const C_TEXT    := Color(0.90, 0.90, 0.95)
const C_TEXT2   := Color(0.55, 0.55, 0.68)
const C_GOLD    := Color(0.96, 0.80, 0.22)

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

func is_active() -> bool:
	return _active

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
	for c in get_children():
		c.queue_free()
	_buttons.clear()

	# Background
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Accent line
	var accent := ColorRect.new()
	accent.color = C_SELECT
	accent.position = Vector2(0, 0)
	accent.size = Vector2(320, 2)
	add_child(accent)

	# Title
	var title := Label.new()
	title.text = "Professeur Chen"
	title.position = Vector2(90, 8)
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", C_GOLD)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choisis ton premier Pokemon !"
	subtitle.position = Vector2(64, 24)
	subtitle.add_theme_font_size_override("font_size", FONT_SIZE)
	subtitle.add_theme_color_override("font_color", C_TEXT2)
	add_child(subtitle)

	# Separator
	var sep := ColorRect.new()
	sep.color = Color(0.18, 0.20, 0.32)
	sep.position = Vector2(20, 38)
	sep.size = Vector2(280, 1)
	add_child(sep)

	# Starter cards
	for i in range(STARTERS.size()):
		var s: Dictionary = STARTERS[i]
		var card_x := 8 + i * 104
		var card := _build_card(Vector2(card_x, 46), s, i)
		add_child(card)

	# Description
	_desc_label = Label.new()
	_desc_label.position = Vector2(10, 184)
	_desc_label.size = Vector2(300, 30)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_desc_label.add_theme_color_override("font_color", C_TEXT2)
	add_child(_desc_label)

	# Controls hint
	var hint := Label.new()
	hint.text = "[Q] [D] Choisir   [E] Confirmer"
	hint.position = Vector2(72, 226)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.48))
	add_child(hint)

	# Confirm dialog (hidden)
	_confirm_panel = Control.new()
	_confirm_panel.visible = false
	add_child(_confirm_panel)

	var cpanel_bg := ColorRect.new()
	cpanel_bg.color = Color(0.0, 0.0, 0.0, 0.85)
	cpanel_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_panel.add_child(cpanel_bg)

	var cbox := ColorRect.new()
	cbox.color = C_PANEL
	cbox.position = Vector2(60, 80)
	cbox.size = Vector2(200, 80)
	_confirm_panel.add_child(cbox)

	var cborder := ColorRect.new()
	cborder.color = C_SELECT
	cborder.position = Vector2(58, 78)
	cborder.size = Vector2(204, 84)
	_confirm_panel.add_child(cborder)
	cborder.z_index = -1
	cbox.z_index = 0

	var ctext := Label.new()
	ctext.position = Vector2(72, 90)
	ctext.size = Vector2(184, 20)
	ctext.add_theme_font_size_override("font_size", 9)
	ctext.add_theme_color_override("font_color", C_TEXT)
	_confirm_panel.add_child(ctext)
	ctext.name = "ConfirmText"

	_confirm_yes = Button.new()
	_confirm_yes.text = "OUI"
	_confirm_yes.position = Vector2(90, 120)
	_confirm_yes.size = Vector2(50, 22)
	_confirm_yes.add_theme_font_size_override("font_size", 9)
	_confirm_yes.pressed.connect(_on_confirm_yes)
	_confirm_panel.add_child(_confirm_yes)

	_confirm_no = Button.new()
	_confirm_no.text = "NON"
	_confirm_no.position = Vector2(170, 120)
	_confirm_no.size = Vector2(50, 22)
	_confirm_no.add_theme_font_size_override("font_size", 9)
	_confirm_no.pressed.connect(_on_confirm_no)
	_confirm_panel.add_child(_confirm_no)

	_refresh()

func _build_card(pos: Vector2, starter: Dictionary, idx: int) -> Control:
	var card := Control.new()
	card.position = pos
	card.size = Vector2(100, 130)

	# Card background
	var bg := ColorRect.new()
	bg.size = Vector2(100, 130)
	bg.color = C_PANEL
	bg.name = "CardBG"
	card.add_child(bg)

	# Card border
	var border := ColorRect.new()
	border.position = Vector2(-1, -1)
	border.size = Vector2(102, 132)
	border.color = C_BORDER
	border.name = "CardBorder"
	border.z_index = -1
	card.add_child(border)

	# Pokemon artwork sprite
	var sprite := SpriteLoader.make_sprite(starter.id, "artwork", Vector2(64, 64))
	sprite.position = Vector2(18, 6)
	sprite.name = "Sprite"
	card.add_child(sprite)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = starter.name
	name_lbl.position = Vector2(4, 74)
	name_lbl.size = Vector2(92, 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	card.add_child(name_lbl)

	# Type badge
	var type_bg := ColorRect.new()
	type_bg.position = Vector2(20, 92)
	type_bg.size = Vector2(60, 12)
	type_bg.color = starter.color.darkened(0.3)
	card.add_child(type_bg)
	var type_lbl := Label.new()
	type_lbl.text = starter.type.to_upper()
	type_lbl.position = Vector2(22, 91)
	type_lbl.size = Vector2(56, 12)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 5)
	type_lbl.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(type_lbl)

	# Level
	var lvl_lbl := Label.new()
	lvl_lbl.text = "Lv. 5"
	lvl_lbl.position = Vector2(4, 108)
	lvl_lbl.size = Vector2(92, 14)
	lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_lbl.add_theme_font_size_override("font_size", 7)
	lvl_lbl.add_theme_color_override("font_color", C_TEXT2)
	card.add_child(lvl_lbl)

	# Button overlay
	var btn := Button.new()
	btn.position = Vector2.ZERO
	btn.size = Vector2(100, 130)
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
			bg.color = Color(0.16, 0.20, 0.38)
			border.color = C_SELECT
		else:
			bg.color = C_PANEL
			border.color = C_BORDER

	var s: Dictionary = STARTERS[_selected]
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
	var s: Dictionary = STARTERS[_selected]
	var starter = (load("res://scripts/data/PokemonInstance.gd") as GDScript).create(s.id, 5)
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
