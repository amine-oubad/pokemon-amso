extends Node2D
## Ligue Pokémon — gère les 5 combats séquentiels (4 Elite + Champion).
## Charge le prochain combat et redirige vers BattleScene.

const LEAGUE_ORDER: Array = [
	"elite4_lorelei", "elite4_bruno", "elite4_agatha", "elite4_peter", "rival_champion"
]

func _ready() -> void:
	# Déterminer le prochain adversaire
	var league_idx: int = GameState.flags.get("league_battle_idx", 0)

	if league_idx >= LEAGUE_ORDER.size():
		# Tous vaincus → victoire !
		_show_victory()
		return

	# Vérifier si le joueur a encore des Pokémon en vie
	if GameState.get_first_alive() == null:
		# Défaite → retour au Plateau Indigo
		GameState.flags["league_battle_idx"] = 0
		GameState.set_flag("league_started", false)
		GameState.return_to_scene = "res://scenes/overworld/maps/IndigoPlateau.tscn"
		GameOverScreen.show_game_over()
		return

	var trainer_id: String = LEAGUE_ORDER[league_idx]
	var tdata: Dictionary = GameData.trainers_data.get(trainer_id, {})

	# Préparer le combat
	GameState.pending_battle = {
		"is_trainer": true,
		"trainer_id": trainer_id,
		"trainer_name": tdata.get("name", "???"),
		"trainer_team": tdata.get("team", []),
		"reward_money": tdata.get("reward_money", 0),
		"badge_id": tdata.get("badge_id", ""),
		"is_gym_leader": tdata.get("is_gym_leader", false),
		"dialogue_before": tdata.get("dialogue_before", ""),
		"dialogue_after": tdata.get("dialogue_after", ""),
	}

	# Incrémenter l'index pour le prochain retour
	GameState.flags["league_battle_idx"] = league_idx + 1

	# return_to_scene pointe vers cette scène pour revenir entre les combats
	GameState.return_to_scene = "res://scenes/battle/LeagueArena.tscn"

	# Afficher le dialogue avant combat, puis lancer le combat
	var dialogue_key: String = tdata.get("dialogue_before", "")
	if dialogue_key != "":
		# Petit délai pour laisser la scène se charger
		await get_tree().create_timer(0.3).timeout
		# Fond sombre
		var bg := ColorRect.new()
		bg.color = Color(0.05, 0.05, 0.10, 0.95)
		bg.position = Vector2.ZERO
		bg.size = Vector2(320, 240)
		add_child(bg)
		var title := Label.new()
		title.text = "%s vous défie !" % tdata.get("name", "???")
		title.position = Vector2(60, 100)
		title.add_theme_font_size_override("font_size", 8)
		title.add_theme_color_override("font_color", Color.YELLOW)
		add_child(title)
		await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_file("res://scenes/battle/BattleScene.tscn")

func _show_victory() -> void:
	# Réinitialiser l'état de la ligue
	GameState.flags["league_battle_idx"] = 0
	GameState.set_flag("league_started", false)
	GameState.set_flag("league_champion", true)

	# Écran de victoire
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.02, 0.10)
	bg.position = Vector2.ZERO
	bg.size = Vector2(320, 240)
	add_child(bg)

	var lines: Array = GameData.dialogues_data.get("league_victory", ["Félicitations !"])
	var y := 40
	for line in lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.position = Vector2(40, y)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color.YELLOW if y == 40 else Color.WHITE)
		add_child(lbl)
		y += 24

	var hint := Label.new()
	hint.text = "Appuyez sur Z pour continuer..."
	hint.position = Vector2(60, 210)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.get_flag("league_champion") and event.is_action_pressed("ui_accept"):
		GameState.return_to_scene = "res://scenes/overworld/maps/IndigoPlateau.tscn"
		GameState.pending_spawn_position = Vector2(160.0, 120.0)
		get_tree().change_scene_to_file(GameState.return_to_scene)
		get_viewport().set_input_as_handled()
