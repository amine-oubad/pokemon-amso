extends "res://scripts/overworld/MapRenderer.gd"
## Bourg Palette — ville de départ.

func get_player_spawn() -> Vector2:
	return Vector2(160, 208)

func build_map() -> void:
	MAP_W = 320; MAP_H = 240
	var tw := MAP_W / TILE_SIZE  # 20
	var th := MAP_H / TILE_SIZE  # 15

	# Ground — grass base
	fill("grass_light", 0, 0, tw, th)
	fill("grass_flowers", 8, 8, 4, 3)

	# Main path (vertical center)
	path_v(9, 0, 2, th)
	# Horizontal paths to buildings
	path_h(1, 4, 9, 2)
	path_h(10, 4, 9, 2)
	path_h(1, 8, 4, 2)

	# Buildings
	pokecenter(1, 1, 6, 3)
	pokemart(13, 1, 6, 3)
	house(1, 6, 3, 3)

	# Tree borders
	tree_border(0, 0, 1, th)
	tree_border(tw - 1, 0, 1, th)
	tree_border(0, 0, tw, 1)
	fill("grass_light", 9, 0, 2, 1)

	# Decorative trees
	tree_2x2(14, 8)
	tree_2x2(4, 12)

	# Fences
	fill("fence_h", 6, 11, 4, 1)

	# NPCs
	add_npc(Vector2(72, 84), "nurse_pallet", Color(0.95, 0.40, 0.40), "heal_team")
	add_npc(Vector2(248, 84), "shop_pallet", Color(0.30, 0.65, 0.30), "open_shop", "pallet_shop")
	add_npc(Vector2(56, 160), "prof_oak_after", Color(0.85, 0.75, 0.55))
	add_npc(Vector2(240, 160), "guide_pallet", Color(0.55, 0.55, 0.80))

	# Signs
	add_sign(Vector2(112, 208), "sign_pallet_town")
	add_sign(Vector2(128, 32), "sign_route1_entry")

	# Transition north → Route 1
	add_transition(Vector2(160, -8), Vector2(32, 24),
		"res://scenes/overworld/maps/Route1.tscn", Vector2(160, 224))

	add_border_walls()
