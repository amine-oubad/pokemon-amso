extends "res://scripts/overworld/MapRenderer.gd"
## ROUTE 1 — entre Bourg-Palette et Jadielle City.

func get_player_spawn() -> Vector2:
	return Vector2(160, 32)

func build_map() -> void:
	MAP_W = 320; MAP_H = 240
	var tw := MAP_W / TILE_SIZE
	var th := MAP_H / TILE_SIZE

	# Ground — green grass base
	fill("grass_light", 0, 0, tw, th)

	# Central vertical dirt path (144px-176px → tiles 9-11, width 2)
	path_v(9, 0, 2, th)

	# Tall grass zones (visual)
	fill("tall_grass", 1, 2, 7, 6)   # left patch  (16,32 → 112x96)
	fill("tall_grass", 12, 7, 7, 6)  # right patch (192,112 → 112x96)

	# Corner trees
	tree_border(0, 0, 1, 2)    # top-left
	tree_border(19, 0, 1, 2)   # top-right
	tree_border(0, 13, 3, 2)   # bottom-left
	tree_border(17, 13, 3, 2)  # bottom-right

	# ── Entities (pixel coords) ─────────────────────────────────────

	# Trainers
	add_trainer(Vector2(160, 160), "route1_youngster", Color(0.50, 0.60, 0.30))
	add_trainer(Vector2(192, 96), "route1_lass", Color(0.70, 0.40, 0.50))

	# NPC guide
	add_npc(Vector2(80, 176), "route1_trainer", Color(0.60, 0.30, 0.60))

	# Encounter zones
	add_encounter_zone(Vector2(72, 80), Vector2(112, 96), "route1", "grass_01", 0.15)
	add_encounter_zone(Vector2(248, 160), Vector2(112, 96), "route1", "grass_02", 0.15)

	# HM block — cut tree
	add_hm_block(Vector2(256, 48), "cut", "hm_block_cut", "hm_block_cut_ok", "route1_cut_tree")

	# Signs
	add_sign(Vector2(128, 32), "sign_route1_grass")
	add_sign(Vector2(176, 16), "sign_jadielle")

	# Transitions
	add_transition(Vector2(160, 248), Vector2(32, 24),
		"res://scenes/overworld/maps/PalletTown.tscn", Vector2(160, 16))
	add_transition(Vector2(160, -8), Vector2(32, 24),
		"res://scenes/overworld/maps/ViridianCity.tscn", Vector2(160, 224))

	add_border_walls()
