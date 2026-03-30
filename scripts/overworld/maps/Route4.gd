extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 4 — Route entre Azuria City et Carmin-sur-Mer.

func get_player_spawn() -> Vector2:
	return Vector2(24, 120)

func build_map() -> void:
	MAP_W = 480; MAP_H = 240
	var tw := MAP_W / TILE_SIZE
	var th := MAP_H / TILE_SIZE

	# Ground — green grass base
	fill("grass_light", 0, 0, tw, th)

	# Horizontal path through center (y=96-128 → tiles 6-8, height 2)
	path_h(0, 6, tw, 2)

	# Vertical path on east side going south (432-480px → tiles 27-30)
	path_v(27, 0, 3, th)

	# Grass decoration zones (4 quadrants)
	fill("tall_grass", 3, 0, 10, 6)    # west-top   (48,0   → 160x96)
	fill("tall_grass", 3, 8, 10, 7)    # west-bot   (48,128 → 160x112)
	fill("tall_grass", 16, 0, 10, 6)   # east-top   (256,0  → 160x96)
	fill("tall_grass", 16, 8, 10, 7)   # east-bot   (256,128 → 160x112)

	# ── Entities (pixel coords) ─────────────────────────────────────

	# Trainers
	add_trainer(Vector2(160, 112), "route4_hiker", Color(0.55, 0.40, 0.25))
	add_trainer(Vector2(320, 112), "route4_lass", Color(0.85, 0.50, 0.60))
	add_trainer(Vector2(420, 112), "rival_carmin", Color(0.20, 0.30, 0.80))

	# Sign
	add_sign(Vector2(48, 112), "sign_route4")

	# Encounter zones
	add_encounter_zone(Vector2(128, 120), Vector2(160, 240), "route4", "grass_01", 0.15)
	add_encounter_zone(Vector2(336, 120), Vector2(160, 240), "route4", "grass_02", 0.15)

	# Transitions
	add_transition(Vector2(-8, 120), Vector2(24, 32),
		"res://scenes/overworld/maps/AzuriaCity.tscn", Vector2(296, 120))
	add_transition(Vector2(456, 248), Vector2(48, 24),
		"res://scenes/overworld/maps/CarminCity.tscn", Vector2(160, 16))

	add_border_walls()
