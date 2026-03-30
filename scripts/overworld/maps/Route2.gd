extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 2 — entre Jadielle City et la Foret de Jade.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320; MAP_H = 240
	var tw := MAP_W / TILE_SIZE
	var th := MAP_H / TILE_SIZE

	# Ground — green grass base
	fill("grass_light", 0, 0, tw, th)

	# Central vertical dirt path (144px-176px → tiles 9-11, width 2)
	path_v(9, 0, 2, th)

	# Tall grass zones (visual)
	fill("tall_grass", 1, 3, 7, 5)   # left patch  (16,48 → 112x80)
	fill("tall_grass", 12, 6, 7, 5)  # right patch (192,96 → 112x80)

	# Corner trees
	tree_border(0, 0, 1, 3)    # top-left
	tree_border(19, 0, 1, 3)   # top-right
	tree_border(0, 13, 3, 2)   # bottom-left
	tree_border(17, 13, 3, 2)  # bottom-right

	# ── Entities (pixel coords) ─────────────────────────────────────

	# Trainers
	add_trainer(Vector2(160, 128), "route2_bug_catcher", Color(0.40, 0.60, 0.20))
	add_trainer(Vector2(192, 64), "route2_lass", Color(0.70, 0.45, 0.55))

	# Signs
	add_sign(Vector2(128, 208), "sign_route2_south")
	add_sign(Vector2(128, 32), "sign_route2_north")

	# Encounter zones
	add_encounter_zone(Vector2(72, 88), Vector2(112, 80), "route2", "grass_01", 0.15)
	add_encounter_zone(Vector2(248, 136), Vector2(112, 80), "route2", "grass_02", 0.15)

	# Transitions
	add_transition(Vector2(160, 248), Vector2(32, 24),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160, 16))
	add_transition(Vector2(160, -8), Vector2(32, 24),
		"res://scenes/overworld/maps/ViridianForest.tscn", Vector2(160, 208))

	add_border_walls()
