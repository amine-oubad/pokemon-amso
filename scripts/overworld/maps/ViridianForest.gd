extends "res://scripts/overworld/MapRenderer.gd"
## FORET DE JADE (Viridian Forest) — zone dense entre Route 2 et Argenta City.
## Layout 320x320 (taller), tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 288)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 320
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 20

	# -- Base ground (dark grass) --
	fill("grass_dark", 0, 0, tw, th)

	# -- Dense tree borders --
	# Top border (leave gap at col 11-13 for north exit)
	tree_border(0, 0, 11, 2)
	tree_border(14, 0, 6, 2)
	# Bottom border (leave gap at col 9-11 for south exit)
	tree_border(0, th - 2, 9, 2)
	tree_border(12, th - 2, 8, 2)
	# Left border
	tree_border(0, 2, 2, th - 4)
	# Right border
	tree_border(tw - 2, 2, 2, th - 4)

	# -- Interior tree clusters (maze walls) --
	tree_border(4, 4, 4, 3)
	tree_border(12, 4, 4, 2)
	tree_border(4, 9, 2, 4)
	tree_border(10, 8, 2, 3)
	tree_border(14, 8, 2, 4)
	tree_border(6, 14, 4, 2)

	# -- Winding dirt paths --
	# South vertical path (entrance)
	path_v(9, 15, 2, 5)
	# Horizontal branch west
	path_h(4, 13, 7, 2)
	# Vertical segment west side
	path_v(4, 7, 2, 6)
	# Horizontal branch north
	path_h(4, 5, 8, 2)
	# Vertical segment to north exit
	path_v(11, 2, 2, 5)

	# -- Tall grass encounter patches --
	fill("tall_grass", 13, 11, 4, 4)
	fill("tall_grass", 2, 13, 4, 3)

	# -- Border walls --
	add_border_walls()

	# -- Trainers (bug catchers) --
	add_trainer(Vector2(128, 192), "forest_bug1", Color(0.35, 0.55, 0.20))
	add_trainer(Vector2(96, 112), "forest_bug2", Color(0.30, 0.50, 0.18))
	add_trainer(Vector2(192, 64), "forest_bug3", Color(0.40, 0.60, 0.25))

	# -- Encounter zones --
	add_encounter_zone(
		Vector2(240, 208), Vector2(96, 96),
		"viridian_forest", "forest_01", 0.20)
	add_encounter_zone(
		Vector2(64, 232), Vector2(96, 64),
		"viridian_forest", "forest_02", 0.20)

	# -- Signs --
	add_sign(Vector2(128, 288), "sign_forest_south")
	add_sign(Vector2(208, 32), "sign_forest_north")

	# -- Transitions --
	# South -> Route 2
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/Route2.tscn", Vector2(160, 16))
	# North -> Argenta City
	add_transition(
		Vector2(192, -8), Vector2(32, 24),
		"res://scenes/overworld/maps/ArgentaCity.tscn", Vector2(160, 224))
