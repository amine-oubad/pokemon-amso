class_name HMBlock
extends StaticBody2D
## Obstacle HM — utilise des sprites du tileset (arbre ou rocher).

var hm_id: String = "cut"
var block_dialogue_key: String = "hm_block_cut"
var clear_dialogue_key: String = "hm_block_cut_ok"
var flag_id: String = ""

func _ready() -> void:
	add_to_group("interactable")
	if flag_id != "" and GameState.get_flag(flag_id):
		queue_free()
		return
	_build_visual()

func _build_visual() -> void:
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16.0, 16.0)
	shape.shape = rs
	add_child(shape)

	# Use tileset sprite
	var tex: Texture2D = load("res://assets/tiles/tileset.png")
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.region_enabled = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		match hm_id:
			"cut":
				# tree_full tile at col=5, row=2 (5*16=80, 2*16=32)
				spr.region_rect = Rect2(80, 32, 16, 16)
			_:
				# rock tile at col=6, row=2 (6*16=96, 2*16=32)
				spr.region_rect = Rect2(96, 32, 16, 16)
		add_child(spr)
	else:
		match hm_id:
			"cut":
				var canopy := ColorRect.new()
				canopy.color = Color(0.20, 0.50, 0.15)
				canopy.size = Vector2(14.0, 14.0)
				canopy.position = Vector2(-7.0, -7.0)
				add_child(canopy)
			_:
				var rock := ColorRect.new()
				rock.color = Color(0.50, 0.45, 0.40)
				rock.size = Vector2(14.0, 12.0)
				rock.position = Vector2(-7.0, -6.0)
				add_child(rock)

func interact() -> void:
	if GameState.can_use_hm(hm_id):
		var lines: Array = GameData.dialogues_data.get(clear_dialogue_key, ["L'obstacle est degage !"])
		DialogueManager.start_dialogue(lines)
		if flag_id != "":
			GameState.set_flag(flag_id)
		await DialogueManager.dialogue_finished
		queue_free()
	else:
		var lines: Array = GameData.dialogues_data.get(block_dialogue_key, ["Quelque chose bloque le chemin..."])
		DialogueManager.start_dialogue(lines)
