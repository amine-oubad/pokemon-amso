class_name Sign
extends StaticBody2D
## Panneau lisible — utilise un sprite du tileset.

var dialogue_key: String = ""

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12.0, 14.0)
	shape.shape = rs
	add_child(shape)

	# Use sign tile from tileset atlas
	var tex = load("res://assets/tiles/tileset.png")
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.region_enabled = true
		# Sign tile at col=13, row=2 (13*16=208, 2*16=32)
		spr.region_rect = Rect2(208, 32, 16, 16)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.offset = Vector2(0, -4)
		add_child(spr)
	else:
		# Fallback
		var board := ColorRect.new()
		board.color = Color(0.88, 0.80, 0.55)
		board.size = Vector2(14.0, 10.0)
		board.position = Vector2(-7.0, -12.0)
		add_child(board)

func interact() -> void:
	var lines: Array = GameData.dialogues_data.get(dialogue_key, ["..."])
	DialogueManager.start_dialogue(lines)
