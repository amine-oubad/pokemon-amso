class_name Trainer
extends CharacterBody2D
## Dresseur sur la map -- declenche un combat trainer quand interagi.
## Sprite anime + indicateur "!" rouge au-dessus.

const CHAR_DIR := "res://assets/sprites/characters/"

var trainer_id: String = ""
var npc_color: Color = Color(0.60, 0.30, 0.60)
var sprite_id: String = ""  # e.g. "youngster", "lass", "bugcatcher", etc.

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _resolve_sprite_id() -> String:
	if sprite_id != "":
		return sprite_id
	# Auto-detect from trainer_id
	if trainer_id.find("youngster") >= 0: return "youngster"
	if trainer_id.find("lass") >= 0: return "lass"
	if trainer_id.find("bug") >= 0 or trainer_id.find("forest") >= 0: return "bugcatcher"
	if trainer_id.find("hiker") >= 0: return "hiker"
	if trainer_id.find("beauty") >= 0: return "beauty"
	if trainer_id.find("psychic") >= 0: return "psychic"
	if trainer_id.find("swimmer") >= 0: return "swimmer"
	if trainer_id.find("juggler") >= 0: return "juggler"
	if trainer_id.find("tamer") >= 0: return "tamer"
	if trainer_id.find("channeler") >= 0: return "channeler"
	if trainer_id.find("rival") >= 0: return "rival"
	# Gym leaders
	if trainer_id.find("pierre") >= 0 or trainer_id.find("flora") >= 0: return "leader_rock"
	if trainer_id.find("ondine") >= 0: return "leader_water"
	if trainer_id.find("bob") >= 0: return "leader_electric"
	if trainer_id.find("erika") >= 0: return "leader_grass"
	if trainer_id.find("morgane") >= 0: return "leader_psychic"
	if trainer_id.find("koga") >= 0: return "leader_poison"
	if trainer_id.find("blaine") >= 0: return "leader_fire"
	# Gym trainers
	if trainer_id.find("gym_trainer") >= 0 or trainer_id.find("_trainer_") >= 0: return "youngster"
	return "youngster"

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
	var tex = load(tex_path) if ResourceLoader.exists(tex_path) else null
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
		var body := ColorRect.new()
		body.color = npc_color
		body.size = Vector2(12.0, 14.0)
		body.position = Vector2(-6.0, -7.0)
		add_child(body)

	# Trainer indicator "!"
	var icon := Label.new()
	icon.text = "!"
	icon.position = Vector2(-3.0, -16.0)
	icon.add_theme_font_size_override("font_size", 7)
	icon.add_theme_color_override("font_color", Color.RED)
	add_child(icon)

func interact() -> void:
	var tdata: Dictionary = GameData.trainers_data.get(trainer_id, {})
	if tdata.is_empty():
		DialogueManager.start_dialogue(["..."])
		return

	if GameState.is_trainer_defeated(trainer_id):
		var after_key: String = tdata.get("dialogue_after", "")
		var lines: Array = GameData.dialogues_data.get(after_key, ["Tu m'as deja battu !"])
		DialogueManager.start_dialogue(lines)
		return

	var before_key: String = tdata.get("dialogue_before", "")
	var lines: Array = GameData.dialogues_data.get(before_key, ["En garde !"])
	DialogueManager.start_dialogue(lines)
	await DialogueManager.dialogue_finished
	_start_battle(tdata)

func _start_battle(tdata: Dictionary) -> void:
	var team_data: Array = tdata.get("team", [])
	if team_data.is_empty():
		return

	var first := team_data[0]
	GameState.pending_battle = {
		"enemy_data": first,
		"is_trainer": true,
		"trainer_id": trainer_id,
		"trainer_name": tdata.get("name", "Dresseur"),
		"trainer_team": team_data,
		"reward_money": tdata.get("reward_money", 100),
		"badge_id": tdata.get("badge_id", ""),
		"is_gym_leader": tdata.get("is_gym_leader", false),
		"dialogue_after": tdata.get("dialogue_after", ""),
	}
	EventBus.trainer_battle_started.emit(trainer_id)
