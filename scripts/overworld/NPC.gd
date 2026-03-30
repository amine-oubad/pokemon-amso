class_name NPC
extends CharacterBody2D
## PNJ interactable -- dialogue, soin d'equipe ou boutique.
## Sprite anime depuis assets/sprites/characters/.

const CHAR_DIR := "res://assets/sprites/characters/"

var dialogue_key:   String  = ""
var special_action: String  = ""   # "heal_team" | "open_shop" | "open_pc" | "start_league" | ""
var shop_id:        String  = ""
var npc_color:      Color   = Color(0.40, 0.45, 0.80)
var sprite_id:      String  = ""   # e.g. "nurse", "shopkeeper", "guide", "prof"

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _resolve_sprite_id() -> String:
	if sprite_id != "":
		return sprite_id
	# Auto-detect from special_action or dialogue_key
	if special_action == "heal_team":
		return "nurse"
	if special_action == "open_shop":
		return "shopkeeper"
	if special_action == "start_league":
		return "guard"
	if dialogue_key.find("prof") >= 0 or dialogue_key.find("oak") >= 0:
		return "prof"
	return "guide"

func _build_visual() -> void:
	# Hitbox
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12.0, 14.0)
	shape.shape = rs
	add_child(shape)

	# Sprite
	var sid := _resolve_sprite_id()
	var tex_path := CHAR_DIR + sid + ".png"
	var tex: Texture2D = load(tex_path) if ResourceLoader.exists(tex_path) else null
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.hframes = 3
		spr.vframes = 4
		spr.frame = 0  # down idle
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.offset = Vector2(0, -4)
		add_child(spr)
	else:
		# Fallback colored rect
		var body := ColorRect.new()
		body.color = npc_color
		body.size = Vector2(12.0, 14.0)
		body.position = Vector2(-6.0, -7.0)
		add_child(body)

func interact() -> void:
	match special_action:
		"heal_team":
			GameState.heal_team()
			var lines: Array = GameData.dialogues_data.get(
				dialogue_key, ["Vos Pokemon sont soignes !"]
			)
			DialogueManager.start_dialogue(lines)
		"open_shop":
			ShopMenu.open_shop(shop_id)
		"open_pc":
			PCBoxScreen.open_pc()
		"start_league":
			if GameState.badges.size() >= 8:
				var lines: Array = GameData.dialogues_data.get("indigo_gate_npc", ["Bonne chance !"])
				DialogueManager.start_dialogue(lines)
				await DialogueManager.dialogue_finished
				GameState.set_flag("league_started", true)
				GameState.flags["league_battle_idx"] = 0
				GameState.return_to_scene = "res://scenes/overworld/maps/IndigoPlateau.tscn"
				get_tree().change_scene_to_file("res://scenes/battle/LeagueArena.tscn")
			else:
				var lines: Array = GameData.dialogues_data.get("indigo_gate_blocked", ["Il te faut 8 badges."])
				DialogueManager.start_dialogue(lines)
		_:
			var lines: Array = GameData.dialogues_data.get(dialogue_key, ["..."])
			DialogueManager.start_dialogue(lines)
