extends "res://scripts/overworld/MapRenderer.gd"
## JADIELLE CITY — ville avec l'Arene Pokemon.
## Layout 320x240 : Centre Pokemon, Pokemart, Arene au nord.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — grass base
	fill("grass_mid", 0, 0, 20, 15)

	# Paths
	path_v(9, 0, 2, 15)           # Nord-sud
	path_h(6, 3, 8, 1)            # Est-ouest vers l'Arene
	path_h(11, 6, 9, 2)           # Est vers Route 2

	# Buildings (tile coords)
	pokecenter(1, 6, 5, 3)        # Centre Pokemon (gauche)
	pokemart(14, 6, 5, 3)         # Pokemart (droite)
	gym_building(7, 0, 6, 4, "ground")  # Arene (nord)

	# Tree borders (decorative edges)
	tree_border(0, 0, 1, 15)      # Bord gauche
	tree_border(19, 0, 1, 5)      # Bord droit haut (au-dessus du gap Route 2)
	tree_border(19, 9, 1, 6)      # Bord droit bas (en-dessous du gap Route 2)

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 164.0), "jadielle_nurse", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(264.0, 164.0), "", Color(0.30, 0.65, 0.30), "open_shop", "jadielle_shop")
	add_npc(Vector2(80.0, 208.0), "guide_jadielle", Color(0.50, 0.50, 0.85))

	# Signs (pixel positions)
	add_sign(Vector2(112.0, 208.0), "sign_jadielle_city")
	add_sign(Vector2(112.0, 64.0), "sign_gym_entry")
	add_sign(Vector2(288.0, 128.0), "sign_route2_entry")

	# Transitions (pixel positions)
	# Sortie sud -> Route 1
	add_transition(Vector2(160.0, 248.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/Route1.tscn", Vector2(160.0, 32.0))
	# Entree Arene -> interieur
	add_transition(Vector2(160.0, 60.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/ViridianGym.tscn", Vector2(160.0, 208.0))
	# Sortie est -> Route 2
	add_transition(Vector2(328.0, 112.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route2.tscn", Vector2(160.0, 224.0))

	# Border walls with gaps for transitions
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(160.0, 208.0)
