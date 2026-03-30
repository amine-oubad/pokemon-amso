extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 3 — Route herbee entre Argenta et Azuria.

func get_player_spawn() -> Vector2:
	return Vector2(24, 64)

func build_map() -> void:
	MAP_W = 480; MAP_H = 240
	var tw := MAP_W / TILE_SIZE
	var th := MAP_H / TILE_SIZE

	# Ground — green grass base
	fill("grass_light", 0, 0, tw, th)

	# Horizontal dirt path (y=48-80 → tiles 3-5, height 2)
	path_h(0, 3, tw, 2)

	# Grass decoration zones
	fill("tall_grass", 3, 0, 10, 3)   # west-top   (48,0   → 160x48)
	fill("tall_grass", 3, 5, 10, 5)   # west-bot   (48,80  → 160x80)
	fill("tall_grass", 16, 0, 10, 3)  # east-top   (256,0  → 160x48)
	fill("tall_grass", 16, 5, 10, 6)  # east-bot   (256,80 → 160x100)

	# Lake area — east side (380,100 → 100x140)
	fill("water", 24, 6, 6, 9)        # approximate lake area

	# ── Entities (pixel coords) ─────────────────────────────────────

	# Trainers
	add_trainer(Vector2(160, 64), "route3_youngster", Color(0.65, 0.50, 0.25))
	add_trainer(Vector2(288, 64), "route3_lass", Color(0.90, 0.55, 0.65))

	# Signs
	add_sign(Vector2(48, 64), "sign_route3")
	add_sign(Vector2(392, 128), "sign_lake")

	# Encounter zones
	add_encounter_zone(Vector2(128, 80), Vector2(160, 160), "route3", "grass_01", 0.15)
	add_encounter_zone(Vector2(336, 90), Vector2(160, 180), "route3", "grass_02", 0.15)

	# Transitions
	add_transition(Vector2(-8, 64), Vector2(24, 32),
		"res://scenes/overworld/maps/ArgentaCity.tscn", Vector2(300, 64))
	add_transition(Vector2(488, 64), Vector2(24, 32),
		"res://scenes/overworld/maps/AzuriaCity.tscn", Vector2(16, 64))

	add_border_walls()
