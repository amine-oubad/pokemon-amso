extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 7 — Route entre Safrania et Parmanie (Fuchsia).

func get_player_spawn() -> Vector2:
	return Vector2(24, 120)

func build_map() -> void:
	MAP_W = 480; MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 30
	var th := MAP_H / TILE_SIZE  # 15

	# Ground — grass base
	fill("grass_light", 0, 0, tw, th)

	# Central horizontal path
	path_h(0, 6, tw, 3)

	# Tall grass zones (4 patches on sides of path)
	fill("tall_grass", 3, 0, 10, 6)
	fill("tall_grass", 3, 9, 10, 7)
	fill("tall_grass", 16, 0, 10, 6)
	fill("tall_grass", 16, 9, 10, 7)

	# Trainers
	add_trainer(Vector2(160, 120), "route7_juggler", Color(0.60, 0.50, 0.20))
	add_trainer(Vector2(340, 120), "route7_tamer", Color(0.70, 0.35, 0.25))
	add_trainer(Vector2(430, 120), "rival_fuchsia", Color(0.20, 0.30, 0.80))

	# Encounter zones
	add_encounter_zone(Vector2(128, 120), Vector2(160, 240), "route7", "grass_01", 0.15)
	add_encounter_zone(Vector2(350, 120), Vector2(160, 240), "route7", "grass_02", 0.15)

	# Sign
	add_sign(Vector2(48, 120), "route7_sign1")

	# Transitions
	# West -> SafraniaCity
	add_transition(Vector2(-8, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/SafraniaCity.tscn", Vector2(304, 120))
	# East -> FuchsiaCity
	add_transition(Vector2(488, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/FuchsiaCity.tscn", Vector2(16, 120))

	add_border_walls()
