extends CanvasLayer
## Gestionnaire de dialogues — affiche des boîtes de texte NPC/panneaux.
## Usage : DialogueManager.start_dialogue(["Ligne 1", "Ligne 2"])
## Bloque l'input player via _input tant qu'un dialogue est actif.

signal dialogue_finished

const FONT_SIZE := 8

var _active: bool = false
var _lines: Array = []
var _current_line: int = 0

var _box: ColorRect
var _text_label: Label
var _arrow: Label

func _ready() -> void:
	layer = 20
	visible = false
	_build_ui()
	set_process_input(false)

func _build_ui() -> void:
	# Outer frame
	_box = ColorRect.new()
	_box.color = Color(0.08, 0.08, 0.16, 0.95)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_top    = -58
	_box.offset_bottom = -2
	_box.offset_left   = 4
	_box.offset_right  = -4
	add_child(_box)

	# Border
	var border := ColorRect.new()
	border.color = Color(0.22, 0.25, 0.38)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left   = -1
	border.offset_top    = -1
	border.offset_right  = 1
	border.offset_bottom = 1
	border.z_index = -1
	_box.add_child(border)

	# Left accent bar
	var accent := ColorRect.new()
	accent.color = Color(0.30, 0.55, 0.95)
	accent.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	accent.offset_left  = 0
	accent.offset_right = 3
	_box.add_child(accent)

	# Text label
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left   = 10
	_text_label.offset_top    = 6
	_text_label.offset_right  = -16
	_text_label.offset_bottom = -6
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_text_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.96))
	_box.add_child(_text_label)

	# Continue arrow
	_arrow = Label.new()
	_arrow.text = "v"
	_arrow.add_theme_font_size_override("font_size", FONT_SIZE)
	_arrow.add_theme_color_override("font_color", Color(0.30, 0.55, 0.95))
	_arrow.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_arrow.offset_left   = -12
	_arrow.offset_top    = -14
	_arrow.offset_right  = -4
	_arrow.offset_bottom = -4
	_box.add_child(_arrow)

# ── API publique ────────────────────────────────────────────────────────────────

func start_dialogue(lines: Array) -> void:
	if _active:
		return
	_lines        = lines
	_current_line = 0
	_active       = true
	visible       = true
	set_process_input(true)
	_show_line()

func is_active() -> bool:
	return _active

# ── Logique interne ─────────────────────────────────────────────────────────────

func _show_line() -> void:
	if _current_line >= _lines.size():
		_close()
		return
	_text_label.text = _lines[_current_line]
	_arrow.visible   = _current_line < _lines.size() - 1

func _close() -> void:
	_active       = false
	visible       = false
	_lines        = []
	_current_line = 0
	set_process_input(false)
	dialogue_finished.emit()
	EventBus.dialogue_finished.emit()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_current_line += 1
		_show_line()
