extends "res://scripts/overworld/MapRenderer.gd"
## AZURIA CITY — ville du troisieme Gym (type Eau).
## Layout 320x240 : Centre Pokemon, Pokemart, Arene, bord du Lac Azur.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — grass base
	fill("grass_mid", 0, 0, 20, 15)

	# Water zone — east side (Lac Azur)
	fill("water_edge_top", 14, 0, 1, 15)  # Transition edge
	fill("water", 15, 0, 5, 15)           # Deep water area

	# Paths
	path_h(0, 3, 20, 2)           # Chemin est-ouest

	# Buildings (tile coords)
	pokecenter(1, 6, 5, 3)        # Centre Pokemon
	pokemart(1, 10, 5, 3)         # Pokemart
	gym_building(7, 0, 6, 4, "water")  # Arene (type Eau)

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 160.0), "azuria_nurse", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(56.0, 220.0), "", Color(0.30, 0.65, 0.30), "open_shop", "azuria_shop")
	add_npc(Vector2(200.0, 208.0), "guide_azuria", Color(0.40, 0.60, 0.90))

	# Signs (pixel positions)
	add_sign(Vector2(112.0, 208.0), "sign_azuria_city")
	add_sign(Vector2(112.0, 64.0), "sign_azuria_gym")

	# Transitions (pixel positions)
	# Ouest -> Route 3
	add_transition(Vector2(-8.0, 64.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route3.tscn", Vector2(464.0, 64.0))
	# Entree Arene
	add_transition(Vector2(168.0, 60.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/AzuriaGym.tscn", Vector2(160.0, 208.0))
	# Est -> Route 4
	add_transition(Vector2(328.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route4.tscn", Vector2(16.0, 120.0))

	# Border walls
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(24.0, 64.0)
