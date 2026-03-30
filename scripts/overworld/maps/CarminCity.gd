extends "res://scripts/overworld/MapRenderer.gd"
## CARMIN-SUR-MER — ville du 4e Gym (type Electrique). Champion : Major Bob.
## Layout 320x240 : port, Centre Pokemon, Pokemart, Arene.

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240

	# Ground — grass base
	fill("grass_mid", 0, 0, 20, 15)

	# Water port area at bottom
	fill("sand", 0, 12, 20, 1)            # Quai / dock
	fill("water", 0, 13, 20, 2)           # Eau du port

	# Paths
	path_h(0, 6, 20, 2)           # Chemin est-ouest
	path_v(9, 0, 2, 15)           # Chemin nord-sud

	# Buildings (tile coords)
	pokecenter(1, 8, 5, 3)        # Centre Pokemon
	pokemart(14, 8, 5, 3)         # Pokemart
	gym_building(1, 1, 7, 4, "electric")  # Arene (type Electrique)

	# NPCs (pixel positions)
	add_npc(Vector2(56.0, 176.0), "carmin_nurse", Color(0.90, 0.70, 0.70), "heal_team")
	add_npc(Vector2(264.0, 176.0), "", Color(0.30, 0.65, 0.30), "open_shop", "carmin_shop")
	add_npc(Vector2(200.0, 100.0), "guide_carmin", Color(0.80, 0.70, 0.25))

	# Signs (pixel positions)
	add_sign(Vector2(144.0, 188.0), "sign_carmin_city")
	add_sign(Vector2(16.0, 76.0), "sign_carmin_gym")

	# Transitions (pixel positions)
	# Nord -> Route 4
	add_transition(Vector2(160.0, -8.0), Vector2(32.0, 24.0),
		"res://scenes/overworld/maps/Route4.tscn", Vector2(456.0, 224.0))
	# Entree Arene
	add_transition(Vector2(72.0, 72.0), Vector2(12.0, 8.0),
		"res://scenes/overworld/maps/CarminGym.tscn", Vector2(160.0, 208.0))
	# Est -> Route 5
	add_transition(Vector2(328.0, 112.0), Vector2(24.0, 32.0),
		"res://scenes/overworld/maps/Route5.tscn", Vector2(16.0, 120.0))

	# Border walls
	add_border_walls()

func get_player_spawn() -> Vector2:
	return Vector2(160.0, 24.0)
