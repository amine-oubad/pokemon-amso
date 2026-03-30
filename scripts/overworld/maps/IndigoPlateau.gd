extends "res://scripts/overworld/MapRenderer.gd"
## PLATEAU INDIGO — lobby de la Ligue Pokemon.
## Layout 320x240 : Centre Pokemon + entree de la Ligue.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — dark grass themed base
	fill("grass_dark", 0, 0, 20, 15)

	# Paths
	path_h(0, 6, 20, 2)           # Est-ouest principal (y=96..128)
	path_v(9, 0, 2, 7)            # Nord-sud (up to the path only)

	# Buildings (tile coords)
	pokecenter(1, 8, 5, 3)        # Centre Pokemon at (16,136) -> tile (1,8)
	# League building — large house with special roof at (100,8) -> tile (6,0)
	house(6, 0, 8, 4, "roof_red", "wall_gray")

	# Tree borders (decorative edges)
	tree_border(0, 0, 1, 6)       # Bord gauche haut
	tree_border(0, 8, 1, 7)       # Bord gauche bas
	tree_border(0, 14, 20, 1)     # Bord bas
	tree_border(19, 0, 1, 15)     # Bord droit (pas de sortie est)

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 184.0), "indigo_npc1", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(200.0, 180.0), "indigo_npc2", Color(0.60, 0.60, 0.70))
	# Garde a l'entree de la Ligue
	add_npc(Vector2(160.0, 80.0), "", Color(0.80, 0.75, 0.20), "start_league")

	# Signs (pixel positions)
	add_sign(Vector2(100.0, 80.0), "indigo_sign1")

	# Transitions (pixel positions)
	# Ouest -> Cramois'Ile (retour)
	add_transition(Vector2(-8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/CramoisIle.tscn", Vector2(304.0, 120.0))

	# Border walls
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(24.0, 120.0)
