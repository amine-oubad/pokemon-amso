extends "res://scripts/overworld/MapRenderer.gd"
## ARENE D'ARGENTA — type Roche. Champion : Flora.
## Layout 320x240, tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# -- Floor --
	fill("gym_floor", 0, 0, tw, th)

	# -- Gym walls (rock type) --
	fill("gym_wall_rock", 0, 0, tw, 1)
	fill("gym_wall_rock", 0, 0, 1, th)
	fill("gym_wall_rock", tw - 1, 0, 1, th)
	fill("gym_wall_rock", 0, th - 1, 9, 1)
	fill("gym_wall_rock", 11, th - 1, 9, 1)

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Platform / estrade --
	fill("gym_wall_rock", 6, 1, 8, 1)
	fill("gym_floor", 6, 2, 8, 2)

	# -- Decorative rocks on sides --
	rocks(2, 3, 2, 6)
	rocks(16, 3, 2, 6)

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities --
	add_npc(Vector2(120, 192), "argenta_gym_guide", Color(0.55, 0.55, 0.75))
	add_trainer(Vector2(144, 144), "argenta_trainer_1", Color(0.55, 0.40, 0.25))
	add_trainer(Vector2(176, 96), "argenta_trainer_2", Color(0.60, 0.45, 0.30))
	add_trainer(Vector2(160, 48), "gym_leader_flora", Color(0.65, 0.50, 0.35))

	# -- Exit south -> ArgentaCity --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/ArgentaCity.tscn", Vector2(160, 72))
