extends CanvasLayer
## HUD overworld moderne — argent, HP du 1er Pokemon, badges.
## Layer 5 (derriere tous les menus).

var _money_label: Label
var _hp_bar:       ColorRect
var _hp_bar_bg:    ColorRect
var _badge_label:  Label
var _panel:        ColorRect
var _panel_border: ColorRect
var _pkmn_icon:    Control

const C_BG     := Color(0.08, 0.08, 0.16, 0.88)
const C_BORDER := Color(0.22, 0.25, 0.38, 0.80)
const C_TEXT   := Color(0.90, 0.90, 0.95)
const C_GOLD   := Color(0.96, 0.80, 0.22)
const C_ACCENT := Color(0.30, 0.55, 0.95)

func _ready() -> void:
	layer = 5
	_build_panel()
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.badge_earned.connect(_on_badge_earned)

func _build_panel() -> void:
	# Border
	_panel_border = ColorRect.new()
	_panel_border.position = Vector2(1, 1)
	_panel_border.size     = Vector2(112, 34)
	_panel_border.color    = C_BORDER
	add_child(_panel_border)

	# Background
	_panel = ColorRect.new()
	_panel.position = Vector2(2, 2)
	_panel.size     = Vector2(110, 32)
	_panel.color    = C_BG
	add_child(_panel)

	# Accent line left
	var accent := ColorRect.new()
	accent.position = Vector2(2, 2)
	accent.size     = Vector2(2, 32)
	accent.color    = C_ACCENT
	add_child(accent)

	# Pokemon mini icon
	_pkmn_icon = Control.new()
	_pkmn_icon.position = Vector2(6, 4)
	_pkmn_icon.size = Vector2(16, 16)
	add_child(_pkmn_icon)

	# Money
	_money_label = Label.new()
	_money_label.position = Vector2(24, 3)
	_money_label.add_theme_font_size_override("font_size", 7)
	_money_label.add_theme_color_override("font_color", C_GOLD)
	add_child(_money_label)

	# Badges
	_badge_label = Label.new()
	_badge_label.position = Vector2(76, 3)
	_badge_label.add_theme_font_size_override("font_size", 6)
	_badge_label.add_theme_color_override("font_color", C_ACCENT)
	add_child(_badge_label)

	# HP bar background
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color    = Color(0.06, 0.06, 0.12)
	_hp_bar_bg.size     = Vector2(86, 5)
	_hp_bar_bg.position = Vector2(24, 16)
	add_child(_hp_bar_bg)

	# HP bar fill
	_hp_bar = ColorRect.new()
	_hp_bar.color    = Color(0.2, 0.85, 0.4)
	_hp_bar.size     = Vector2(86, 5)
	_hp_bar.position = Vector2(24, 16)
	add_child(_hp_bar)

	# HP text
	var hp_text := Label.new()
	hp_text.position = Vector2(24, 22)
	hp_text.add_theme_font_size_override("font_size", 5)
	hp_text.add_theme_color_override("font_color", Color(0.55, 0.55, 0.68))
	hp_text.name = "HPText"
	add_child(hp_text)

	_refresh()

func _refresh() -> void:
	_money_label.text = "$%d" % GameState.money
	_badge_label.text = "%dB" % GameState.badges.size()

	# Update pokemon icon
	for c in _pkmn_icon.get_children():
		c.queue_free()
	if not GameState.team.is_empty():
		var poke: PokemonInstance = GameState.team[0]
		var icon := SpriteLoader.make_sprite(poke.pokemon_id, "front", Vector2(14, 14))
		_pkmn_icon.add_child(icon)

	if GameState.team.is_empty():
		_hp_bar.size.x = 0
		return

	var poke: PokemonInstance = GameState.team[0]
	var ratio: float = float(poke.current_hp) / float(poke.max_hp) if poke.max_hp > 0 else 0.0
	_hp_bar.size.x = 86.0 * clamp(ratio, 0.0, 1.0)
	if ratio > 0.5:
		_hp_bar.color = Color(0.2, 0.85, 0.4)
	elif ratio > 0.25:
		_hp_bar.color = Color(0.95, 0.75, 0.1)
	else:
		_hp_bar.color = Color(0.95, 0.22, 0.15)

	# HP text
	var hp_node: Label = get_node_or_null("HPText")
	if hp_node:
		hp_node.text = "%d/%d" % [poke.current_hp, poke.max_hp]

var _dirty := true

func mark_dirty() -> void:
	_dirty = true

func _process(_delta: float) -> void:
	if _panel.visible and _dirty:
		_dirty = false
		_refresh()

func _on_battle_started(_enemy_data: Dictionary, _is_trainer: bool) -> void:
	_panel.hide()
	_panel_border.hide()

func _on_battle_ended(_result: String) -> void:
	_panel.show()
	_panel_border.show()
	mark_dirty()

func _on_badge_earned(_badge_id: String) -> void:
	mark_dirty()
