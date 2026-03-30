extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 5 — Route entre Carmin-sur-Mer et Celadopole.

func get_player_spawn() -> Vector2:
	return Vector2(24, 120)

func build_map() -> void:
	MAP_W = 480; MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 30
	var th := MAP_H / TILE_SIZE  # 15

	# Ground — grass base
	fill("grass_light", 0, 0, tw, th)

	# Central horizontal path (y=104..136 -> tiles 6..8, 2 tiles high)
	path_h(0, 6, tw, 3)

	# Tall grass zones (4 patches on sides of path)
	# Left patches: px(48,0) 180x104 -> tiles (3,0) 11x6
	fill("tall_grass", 3, 0, 11, 6)
	# Left bottom: px(48,136) 180x104 -> tiles (3,9) 11x7
	fill("tall_grass", 3, 9, 11, 7)
	# Right patches: px(270,0) 160x104 -> tiles (16,0) 10x6
	fill("tall_grass", 16, 0, 10, 6)
	# Right bottom: px(270,136) 160x104 -> tiles (16,9) 10x7
	fill("tall_grass", 16, 9, 10, 7)

	# Trainers (positions in pixels)
	add_trainer(Vector2(160, 120), "route5_youngster", Color(0.60, 0.45, 0.25))
	add_trainer(Vector2(340, 120), "route5_beauty", Color(0.90, 0.45, 0.55))
	add_trainer(Vector2(240, 120), "rival_route5", Color(0.20, 0.30, 0.80))

	# Encounter zones
	add_encounter_zone(Vector2(138, 120), Vector2(180, 240), "route5", "grass_01", 0.15)
	add_encounter_zone(Vector2(350, 120), Vector2(160, 240), "route5", "grass_02", 0.15)

	# Sign
	add_sign(Vector2(48, 120), "sign_route5")

	# Transitions
	# West -> CarminCity
	add_transition(Vector2(-8, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/CarminCity.tscn", Vector2(304, 112))
	# East -> Celadopole
	add_transition(Vector2(488, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/Celadopole.tscn", Vector2(16, 120))

	add_border_walls()
