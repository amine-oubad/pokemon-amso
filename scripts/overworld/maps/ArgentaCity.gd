extends "res://scripts/overworld/MapRenderer.gd"
## ARGENTA CITY — ville du deuxieme Gym (type Roche).
## Layout 320x240 : Centre Pokemon, Pokemart, Arene, Musee.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — grass base
	fill("grass_mid", 0, 0, 20, 15)

	# Paths
	path_v(9, 0, 2, 15)           # Nord-sud
	path_h(5, 3, 10, 1)           # Est-ouest vers l'Arene

	# Buildings (tile coords)
	pokecenter(1, 6, 5, 3)        # Centre Pokemon (gauche)
	pokemart(14, 6, 5, 3)         # Pokemart (droite)
	gym_building(7, 0, 6, 4, "rock")   # Arene (nord, type Roche)
	house(1, 0, 5, 3, "roof_green", "wall_gray")  # Musee (80x40 -> 5x3 approx)

	# Tree borders
	tree_border(0, 0, 1, 15)      # Bord gauche
	tree_border(19, 0, 1, 3)      # Bord droit haut (au-dessus du gap Route 3)
	tree_border(19, 6, 1, 9)      # Bord droit bas (en-dessous du gap Route 3)

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 164.0), "argenta_nurse", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(264.0, 164.0), "", Color(0.30, 0.65, 0.30), "open_shop", "argenta_shop")
	add_npc(Vector2(240.0, 208.0), "guide_argenta", Color(0.55, 0.50, 0.65))

	# Signs (pixel positions)
	add_sign(Vector2(112.0, 208.0), "sign_argenta_city")
	add_sign(Vector2(112.0, 64.0), "sign_argenta_gym")

	# Conditional rival trainer
	if GameState.has_badge("boulder_badge") and not GameState.has_badge("cascade_badge"):
		add_trainer(Vector2(160.0, 80.0), "rival_argenta", Color(0.20, 0.20, 0.65))

	# Transitions (pixel positions)
	# Sud -> Foret de Jade
	add_transition(Vector2(160.0, 248.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/ViridianForest.tscn", Vector2(192.0, 16.0))
	# Entree Arene
	add_transition(Vector2(160.0, 60.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/ArgentaGym.tscn", Vector2(160.0, 208.0))
	# Est -> Route 3
	add_transition(Vector2(328.0, 64.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route3.tscn", Vector2(24.0, 64.0))

	# Border walls
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(160.0, 208.0)
