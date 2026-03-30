extends "res://scripts/overworld/MapRenderer.gd"
## ARENE D'AZURIA — type Eau. Championne : Ondine.
## Layout 320x240, tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# -- Floor (icy/watery theme) --
	fill("ice_floor", 0, 0, tw, th)

	# -- Gym walls (water type) --
	fill("gym_wall_water", 0, 0, tw, 1)
	fill("gym_wall_water", 0, 0, 1, th)
	fill("gym_wall_water", tw - 1, 0, 1, th)
	fill("gym_wall_water", 0, th - 1, 9, 1)
	fill("gym_wall_water", 11, th - 1, 9, 1)

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Water pools on sides --
	fill("water", 2, 5, 5, 5)
	fill("water", 13, 5, 5, 5)

	# -- Platform / estrade --
	fill("gym_wall_water", 6, 1, 8, 1)
	fill("ice_floor", 6, 2, 8, 2)

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities --
	add_npc(Vector2(120, 192), "sign_azuria_gym", Color(0.35, 0.55, 0.85))
	add_trainer(Vector2(144, 160), "azuria_trainer_1", Color(0.30, 0.55, 0.80))
	add_trainer(Vector2(176, 112), "azuria_trainer_2", Color(0.25, 0.50, 0.75))
	add_trainer(Vector2(160, 48), "gym_leader_ondine", Color(0.10, 0.65, 0.85))

	# -- Exit south -> AzuriaCity --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/AzuriaCity.tscn", Vector2(168, 72))
