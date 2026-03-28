class_name Trainer
extends CharacterBody2D
## Dresseur sur la map — déclenche un combat trainer quand interagi.
## Une fois vaincu, affiche un dialogue de défaite au lieu de se battre.

var trainer_id: String = ""
var npc_color: Color = Color(0.60, 0.30, 0.60)

func _ready() -> void:
	add_to_group("interactable")
	_build_visual()

func _build_visual() -> void:
	# Hitbox
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12.0, 14.0)
	shape.shape = rs
	add_child(shape)

	# Corps
	var body := ColorRect.new()
	body.color = npc_color
	body.size = Vector2(12.0, 10.0)
	body.position = Vector2(-6.0, -5.0)
	add_child(body)

	# Tête
	var head := ColorRect.new()
	head.color = Color(0.90, 0.76, 0.60)
	head.size = Vector2(10.0, 10.0)
	head.position = Vector2(-5.0, -14.0)
	add_child(head)

	# Indicateur dresseur (!)
	var icon := Label.new()
	icon.text = "!"
	icon.position = Vector2(-3.0, -22.0)
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
		var lines: Array = GameData.dialogues_data.get(after_key, ["Tu m'as déjà battu !"])
		DialogueManager.start_dialogue(lines)
		return

	# Dialogue avant combat
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
	}
	EventBus.trainer_battle_started.emit(trainer_id)
