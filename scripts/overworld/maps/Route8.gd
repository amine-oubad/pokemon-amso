extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 8 — Route entre Parmanie et Cramois'Ile.

func get_player_spawn() -> Vector2:
	return Vector2(24, 120)

func build_map() -> void:
	MAP_W = 480; MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 30
	var th := MAP_H / TILE_SIZE  # 15

	# Ground — grass base
	fill("grass_light", 0, 0, tw, th)

	# Water-themed west half: grass_dark
	fill("grass_dark", 0, 0, tw / 2, th)

	# Fire-themed east half: sand
	fill("sand", tw / 2, 0, tw / 2, th)

	# Central horizontal path
	path_h(0, 6, tw, 3)

	# Tall grass zones (4 patches on sides of path)
	fill("tall_grass", 3, 0, 10, 6)
	fill("tall_grass", 3, 9, 10, 7)
	fill("tall_grass", 16, 0, 10, 6)
	fill("tall_grass", 16, 9, 10, 7)

	# Trainers
	add_trainer(Vector2(160, 120), "route8_hiker", Color(0.55, 0.40, 0.30))
	add_trainer(Vector2(340, 120), "route8_swimmer", Color(0.30, 0.50, 0.70))

	# Encounter zones
	add_encounter_zone(Vector2(128, 120), Vector2(160, 240), "route8", "grass_01", 0.15)
	add_encounter_zone(Vector2(350, 120), Vector2(160, 240), "route8", "grass_02", 0.15)

	# Sign
	add_sign(Vector2(48, 120), "route8_sign1")

	# Transitions
	# West -> FuchsiaCity
	add_transition(Vector2(-8, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/FuchsiaCity.tscn", Vector2(304, 120))
	# East -> CramoisIle
	add_transition(Vector2(488, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/CramoisIle.tscn", Vector2(16, 120))

	add_border_walls()
