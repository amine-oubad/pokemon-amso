extends "res://scripts/overworld/MapRenderer.gd"
## ARENE DE CELADOPOLE — type Plante. Championne : Erika.
## Layout 320x240, tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# -- Floor (forest-like dark grass) --
	fill("grass_dark", 0, 0, tw, th)

	# -- Gym walls (grass type) --
	fill("gym_wall_grass", 0, 0, tw, 1)
	fill("gym_wall_grass", 0, 0, 1, th)
	fill("gym_wall_grass", tw - 1, 0, 1, th)
	fill("gym_wall_grass", 0, th - 1, 9, 1)
	fill("gym_wall_grass", 11, th - 1, 9, 1)

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Decorative flower patches --
	fill("flowers_red", 2, 5, 3, 2)
	fill("flowers_yellow", 15, 5, 3, 2)
	fill("flowers_blue", 2, 9, 3, 2)
	fill("flowers_red", 15, 9, 3, 2)

	# -- Platform / estrade --
	fill("gym_wall_grass", 6, 1, 8, 1)
	fill("grass_dark", 6, 2, 8, 2)

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities --
	add_npc(Vector2(120, 192), "sign_celadopole_gym", Color(0.30, 0.60, 0.25))
	add_trainer(Vector2(144, 160), "celadopole_trainer_1", Color(0.25, 0.55, 0.20))
	add_trainer(Vector2(176, 112), "celadopole_trainer_2", Color(0.20, 0.50, 0.18))
	add_trainer(Vector2(160, 48), "gym_leader_erika", Color(0.30, 0.75, 0.30))

	# -- Exit south -> Celadopole --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/Celadopole.tscn", Vector2(256, 76))
