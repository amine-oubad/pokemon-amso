extends "res://scripts/overworld/MapRenderer.gd"
## ARENE DE SAFRANIA — type Psy. Championne : Morgane.
## Layout 320x240, tilemap-based.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320
	MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# -- Floor (psychic theme) --
	fill("psy_floor", 0, 0, tw, th)

	# -- Gym walls (psychic type) --
	fill("gym_wall_psychic", 0, 0, tw, 1)
	fill("gym_wall_psychic", 0, 0, 1, th)
	fill("gym_wall_psychic", tw - 1, 0, 1, th)
	fill("gym_wall_psychic", 0, th - 1, 9, 1)
	fill("gym_wall_psychic", 11, th - 1, 9, 1)

	# -- Central path --
	path_v(9, 0, 2, th)

	# -- Platform / estrade --
	fill("gym_wall_psychic", 6, 1, 8, 1)
	fill("psy_floor", 6, 2, 8, 2)

	# -- Badge podium --
	put("badge_podium", 10, 2)

	# -- Border walls --
	add_border_walls()

	# -- Entities --
	add_npc(Vector2(120, 192), "sign_safrania_gym", Color(0.55, 0.35, 0.70))
	add_trainer(Vector2(144, 160), "safrania_trainer_1", Color(0.50, 0.30, 0.65))
	add_trainer(Vector2(176, 112), "safrania_trainer_2", Color(0.45, 0.25, 0.60))
	add_trainer(Vector2(160, 48), "gym_leader_morgane", Color(0.70, 0.40, 0.90))

	# -- Exit south -> SafraniaCity --
	add_transition(
		Vector2(160, MAP_H + 8), Vector2(32, 24),
		"res://scenes/overworld/maps/SafraniaCity.tscn", Vector2(256, 76))
