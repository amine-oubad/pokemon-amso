extends "res://scripts/overworld/MapRenderer.gd"
## ARENE DE CRAMOIS'ILE — type Feu. Champion : Blaine.
## Layout 320x240, tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# -- Floor (lava / fire theme) --
	fill("lava", 0, 0, tw, th)

	# -- Gym walls (fire type) --
	fill("gym_wall_fire", 0, 0, tw, 1)
	fill("gym_wall_fire", 0, 0, 1, th)
	fill("gym_wall_fire", tw - 1, 0, 1, th)
	fill("gym_wall_fire", 0, th - 1, 9, 1)
	fill("gym_wall_fire", 11, th - 1, 9, 1)

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Platform / estrade --
	fill("gym_wall_fire", 6, 1, 8, 1)
	fill("lava", 6, 2, 8, 2)

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities --
	add_trainer(Vector2(144, 160), "cramoisile_trainer_1", Color(0.70, 0.30, 0.15))
	add_trainer(Vector2(176, 112), "cramoisile_trainer_2", Color(0.65, 0.25, 0.12))
	add_trainer(Vector2(160, 48), "gym_leader_blaine", Color(0.90, 0.40, 0.10))

	# -- Exit south -> CramoisIle --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/CramoisIle.tscn", Vector2(256, 76))
