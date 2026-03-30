extends "res://scripts/overworld/MapRenderer.gd"
## ARENE DE JADIELLE — type Sol. Champion : Pierre.
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

	# -- Gym walls (top, left, right edges) --
	fill("gym_wall_ground", 0, 0, tw, 1)   # top wall
	fill("gym_wall_ground", 0, 0, 1, th)    # left wall
	fill("gym_wall_ground", tw - 1, 0, 1, th) # right wall
	fill("gym_wall_ground", 0, th - 1, 9, 1)  # bottom-left wall
	fill("gym_wall_ground", 11, th - 1, 9, 1) # bottom-right wall

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Platform / estrade for the leader --
	fill("gym_wall_ground", 6, 1, 8, 1)  # estrade back wall
	fill("gym_floor", 6, 2, 8, 2)        # estrade floor

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities (positions in pixels) --
	# Guide NPC
	add_npc(Vector2(120, 192), "gym_guide", Color(0.55, 0.55, 0.75))

	# Gym trainer
	add_trainer(Vector2(160, 128), "gym_trainer_1", Color(0.65, 0.35, 0.20))

	# Leader Pierre
	add_trainer(Vector2(160, 48), "gym_leader_pierre", Color(0.50, 0.40, 0.30))

	# -- Exit south -> ViridianCity --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160, 72))
