class_name HMBlock
extends StaticBody2D
## Obstacle de progression nécessitant une CS (HM) pour passer.
## Ex : arbre coupable (Cut), rocher poussable (Strength).

var hm_id: String = "cut"
var block_dialogue_key: String = "hm_block_cut"
var clear_dialogue_key: String = "hm_block_cut_ok"
var flag_id: String = ""  # Flag unique pour se souvenir que l'obstacle est dégagé

func _ready() -> void:
	add_to_group("interactable")
	# Vérifier si l'obstacle est déjà dégagé
	if flag_id != "" and GameState.get_flag(flag_id):
		queue_free()
		return
	_build_visual()

func _build_visual() -> void:
	# Collision
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16.0, 16.0)
	shape.shape = rs
	add_child(shape)

	match hm_id:
		"cut":
			# Petit arbre
			var trunk := ColorRect.new()
			trunk.color = Color(0.45, 0.28, 0.10)
			trunk.size = Vector2(4.0, 8.0)
			trunk.position = Vector2(-2.0, 0.0)
			add_child(trunk)

			var canopy := ColorRect.new()
			canopy.color = Color(0.20, 0.50, 0.15)
			canopy.size = Vector2(14.0, 12.0)
			canopy.position = Vector2(-7.0, -10.0)
			add_child(canopy)
		_:
			# Rocher générique
			var rock := ColorRect.new()
			rock.color = Color(0.50, 0.45, 0.40)
			rock.size = Vector2(14.0, 12.0)
			rock.position = Vector2(-7.0, -6.0)
			add_child(rock)

func interact() -> void:
	if GameState.can_use_hm(hm_id):
		var lines: Array = GameData.dialogues_data.get(clear_dialogue_key, ["L'obstacle est dégagé !"])
		DialogueManager.start_dialogue(lines)
		if flag_id != "":
			GameState.set_flag(flag_id)
		await DialogueManager.dialogue_finished
		queue_free()
	else:
		var lines: Array = GameData.dialogues_data.get(block_dialogue_key, ["Quelque chose bloque le chemin..."])
		DialogueManager.start_dialogue(lines)
