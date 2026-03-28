class_name NPC
extends CharacterBody2D
## PNJ interactable — dialogue, soin d'équipe ou boutique.
## Créer avec NPC.new(), configurer les vars, puis add_child().
## Doit être dans le groupe "interactable" (ajouté dans _ready).

var dialogue_key:   String  = ""
var special_action: String  = ""   # "heal_team" | "open_shop" | "open_pc" | ""
var shop_id:        String  = ""
var npc_color:      Color   = Color(0.40, 0.45, 0.80)

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Hitbox (12×14, centrée)
	var shape := CollisionShape2D.new()
	var rs    := RectangleShape2D.new()
	rs.size   = Vector2(12.0, 14.0)
	shape.shape = rs
	add_child(shape)

	# Corps
	var body      := ColorRect.new()
	body.color     = npc_color
	body.size      = Vector2(12.0, 10.0)
	body.position  = Vector2(-6.0, -5.0)
	add_child(body)

	# Tête
	var head      := ColorRect.new()
	head.color     = Color(0.90, 0.76, 0.60)
	head.size      = Vector2(10.0, 10.0)
	head.position  = Vector2(-5.0, -14.0)
	add_child(head)

# ── Interaction ─────────────────────────────────────────────────────────────────

func interact() -> void:
	match special_action:
		"heal_team":
			GameState.heal_team()
			var lines: Array = GameData.dialogues_data.get(
				dialogue_key, ["Vos Pokémon sont soignés !"]
			)
			DialogueManager.start_dialogue(lines)
		"open_shop":
			ShopMenu.open_shop(shop_id)
		"open_pc":
			PCBoxScreen.open_pc()
		_:
			var lines: Array = GameData.dialogues_data.get(dialogue_key, ["..."])
			DialogueManager.start_dialogue(lines)
