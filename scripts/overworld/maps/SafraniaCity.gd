extends "res://scripts/overworld/MapRenderer.gd"
## SAFRANIA — ville du 6e Gym (type Psy). Championne : Morgane.
## Layout 320x240 : ville mystique, Centre Pokemon, Pokemart, Arene.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — grass base
	fill("grass_mid", 0, 0, 20, 15)

	# Paths
	path_h(0, 6, 20, 2)           # Est-ouest principal (y=96..128)
	path_v(9, 0, 2, 15)           # Nord-sud

	# Mystical psy_floor zones
	fill("psy_floor", 13, 10, 6, 4)
	fill("psy_floor", 1, 1, 5, 4)

	# Buildings (tile coords)
	pokecenter(1, 8, 5, 3)        # Centre Pokemon at (16,136) -> tile (1,8)
	pokemart(1, 12, 5, 2)         # Pokemart at (16,200) -> tile (1,12)
	gym_building(12, 0, 7, 4, "psychic")  # Arene at (200,8) -> tile (12,0)

	# Tree borders (decorative edges)
	tree_border(0, 0, 1, 6)       # Bord gauche haut
	tree_border(0, 14, 20, 1)     # Bord bas
	tree_border(19, 0, 1, 6)      # Bord droit haut
	tree_border(19, 8, 1, 6)      # Bord droit bas

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 184.0), "safrania_nurse", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(56.0, 230.0), "", Color(0.30, 0.65, 0.30), "open_shop", "safrania_shop")
	add_npc(Vector2(120.0, 200.0), "guide_safrania", Color(0.60, 0.40, 0.75))

	# Signs (pixel positions)
	add_sign(Vector2(144.0, 200.0), "sign_safrania_city")
	add_sign(Vector2(200.0, 68.0), "sign_safrania_gym")

	# Transitions (pixel positions)
	# Ouest -> Route 6
	add_transition(Vector2(-8.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route6.tscn", Vector2(464.0, 120.0))
	# Entree Arene
	add_transition(Vector2(256.0, 64.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/SafraniaGym.tscn", Vector2(160.0, 208.0))
	# Est -> Route 7
	add_transition(Vector2(328.0, 120.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route7.tscn", Vector2(16.0, 120.0))

	# Border walls
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(24.0, 120.0)
