class_name Sign
extends StaticBody2D
## Panneau lisible (Z face au panneau).
## Créer avec Sign.new(), assigner dialogue_key, puis add_child().

var dialogue_key: String = ""

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Hitbox
	var shape   := CollisionShape2D.new()
	var rs      := RectangleShape2D.new()
	rs.size     = Vector2(12.0, 14.0)
	shape.shape = rs
	add_child(shape)

	# Poteau
	var post      := ColorRect.new()
	post.color     = Color(0.50, 0.33, 0.10)
	post.size      = Vector2(4.0, 14.0)
	post.position  = Vector2(-2.0, -7.0)
	add_child(post)

	# Planche
	var board      := ColorRect.new()
	board.color     = Color(0.88, 0.80, 0.55)
	board.size      = Vector2(14.0, 10.0)
	board.position  = Vector2(-7.0, -16.0)
	add_child(board)

	# Texte indicatif sur la planche
	var lbl      := Label.new()
	lbl.text      = "!"
	lbl.position  = Vector2(-2.0, -16.0)
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", Color(0.20, 0.10, 0.05))
	add_child(lbl)

# ── Interaction ─────────────────────────────────────────────────────────────────

func interact() -> void:
	var lines: Array = GameData.dialogues_data.get(dialogue_key, ["..."])
	DialogueManager.start_dialogue(lines)
