extends CanvasLayer
## HUD overworld — affiche argent, HP du 1er Pokémon, badges obtenus.
## Layer 5 (derrière tous les menus).

var _money_label: Label
var _hp_bar:       ColorRect
var _hp_bar_bg:    ColorRect
var _badge_label:  Label
var _panel:        PanelContainer

func _ready() -> void:
	layer = 5
	_build_panel()
	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.badge_earned.connect(_on_badge_earned)

# ── Construction ────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.position = Vector2(2, 2)
	_panel.size     = Vector2(100, 28)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)

	# Ligne 1 : argent + badges
	var hbox1 := HBoxContainer.new()
	vbox.add_child(hbox1)

	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 6)
	_money_label.add_theme_color_override("font_color", Color.YELLOW)
	hbox1.add_child(_money_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox1.add_child(spacer)

	_badge_label = Label.new()
	_badge_label.add_theme_font_size_override("font_size", 6)
	_badge_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	hbox1.add_child(_badge_label)

	# Ligne 2 : barre HP
	var hp_container := Control.new()
	hp_container.custom_minimum_size = Vector2(96, 6)
	vbox.add_child(hp_container)

	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color    = Color(0.3, 0.0, 0.0)
	_hp_bar_bg.size     = Vector2(96, 6)
	_hp_bar_bg.position = Vector2.ZERO
	hp_container.add_child(_hp_bar_bg)

	_hp_bar = ColorRect.new()
	_hp_bar.color    = Color(0.2, 0.8, 0.2)
	_hp_bar.size     = Vector2(96, 6)
	_hp_bar.position = Vector2.ZERO
	hp_container.add_child(_hp_bar)

	_refresh()

# ── Refresh ──────────────────────────────────────────────────────────────────

func _refresh() -> void:
	_money_label.text = "$%d" % GameState.money

	var badge_count: int = GameState.badges.size()
	_badge_label.text = "🏅%d" % badge_count

	if GameState.team.is_empty():
		_hp_bar.size.x = 0
		return

	var poke = GameState.team[0]
	var ratio: float = float(poke.current_hp) / float(poke.max_hp) if poke.max_hp > 0 else 0.0
	_hp_bar.size.x = 96.0 * clamp(ratio, 0.0, 1.0)
	if ratio > 0.5:
		_hp_bar.color = Color(0.2, 0.8, 0.2)
	elif ratio > 0.25:
		_hp_bar.color = Color(0.9, 0.75, 0.1)
	else:
		_hp_bar.color = Color(0.9, 0.15, 0.15)

func _process(_delta: float) -> void:
	if _panel.visible:
		_refresh()

# ── Signaux ──────────────────────────────────────────────────────────────────

func _on_battle_started(_enemy_data: Dictionary, _is_trainer: bool) -> void:
	_panel.hide()

func _on_battle_ended(_result: String) -> void:
	_panel.show()
	_refresh()

func _on_badge_earned(_badge_id: String) -> void:
	_refresh()
