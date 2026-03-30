#!/usr/bin/env python3
"""Generate a pixel art tileset atlas for Pokemon AMSO (16x16 tiles, GBC style)."""

from PIL import Image, ImageDraw
import os

TILE = 16
COLS = 16  # tiles per row
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "tiles")

# ── Palette (Pokemon GBC/GBA inspired) ──────────────────────────
# Greens
GRASS_LIGHT   = (104, 196, 104)
GRASS_MID     = (72, 168, 72)
GRASS_DARK    = (48, 136, 48)
GRASS_SHADOW  = (32, 104, 32)
TALL_GRASS_A  = (40, 152, 56)
TALL_GRASS_B  = (64, 184, 72)
TALL_GRASS_TIP= (88, 208, 96)

# Path/Dirt
DIRT_LIGHT    = (216, 184, 136)
DIRT_MID      = (192, 160, 112)
DIRT_DARK     = (168, 136, 96)
DIRT_EDGE     = (144, 120, 80)

# Sand
SAND_LIGHT    = (240, 224, 176)
SAND_MID      = (224, 208, 160)
SAND_DARK     = (200, 184, 136)

# Water
WATER_LIGHT   = (104, 176, 248)
WATER_MID     = (56, 144, 248)
WATER_DARK    = (32, 112, 216)
WATER_DEEP    = (24, 80, 176)
WATER_SHINE   = (160, 216, 255)

# Trees
TREE_CANOPY_L = (48, 120, 48)
TREE_CANOPY   = (32, 96, 32)
TREE_CANOPY_D = (24, 72, 24)
TREE_TRUNK    = (136, 96, 48)
TREE_TRUNK_D  = (104, 72, 32)

# Buildings
WALL_GRAY     = (192, 192, 200)
WALL_GRAY_D   = (152, 152, 168)
ROOF_RED      = (200, 56, 48)
ROOF_RED_D    = (160, 40, 32)
ROOF_BLUE     = (56, 96, 200)
ROOF_BLUE_D   = (40, 72, 160)
DOOR_BROWN    = (160, 112, 48)
DOOR_BROWN_L  = (192, 144, 72)
WINDOW_CYAN   = (136, 216, 240)
WINDOW_FRAME  = (96, 96, 112)

# Misc
FENCE_WOOD    = (176, 136, 80)
FENCE_WOOD_D  = (136, 104, 56)
SIGN_BOARD    = (224, 200, 144)
SIGN_POST     = (136, 96, 48)
ROCK_LIGHT    = (168, 168, 176)
ROCK_MID      = (136, 136, 148)
ROCK_DARK     = (104, 104, 120)
FLOWER_RED    = (232, 72, 72)
FLOWER_BLUE   = (88, 128, 232)
FLOWER_YELLOW = (248, 216, 64)
FLOWER_STEM   = (56, 144, 56)

# Gym/Indoor
GYM_FLOOR_L   = (200, 192, 176)
GYM_FLOOR_D   = (176, 168, 152)
GYM_WALL      = (144, 136, 120)

# Borders
BORDER_BLACK  = (8, 8, 16)
BORDER_DARK   = (24, 24, 40)

# Lava
LAVA_LIGHT    = (248, 128, 48)
LAVA_MID      = (216, 80, 24)
LAVA_DARK     = (168, 48, 16)

# Psychic
PSY_LIGHT     = (176, 120, 216)
PSY_MID       = (136, 80, 184)

# Poison
POISON_LIGHT  = (160, 96, 192)
POISON_MID    = (120, 56, 152)

# Electric
ELEC_LIGHT    = (248, 224, 80)
ELEC_MID      = (224, 192, 48)

# Ice/Water gym
ICE_LIGHT     = (192, 232, 248)
ICE_MID       = (144, 200, 232)

# ── Tile drawing functions ───────────────────────────────────────

def draw_grass_light(d, x, y):
    """Light grass base tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_LIGHT)
    # Subtle texture dots
    for px, py in [(2,3),(7,1),(12,5),(4,10),(9,13),(14,8),(1,14),(10,7)]:
        d.point((x+px, y+py), fill=GRASS_MID)

def draw_grass_mid(d, x, y):
    """Medium grass tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    for px, py in [(3,2),(8,6),(13,1),(1,9),(6,12),(11,14),(5,5),(14,10)]:
        d.point((x+px, y+py), fill=GRASS_DARK)
    for px, py in [(0,4),(7,11),(12,3)]:
        d.point((x+px, y+py), fill=GRASS_LIGHT)

def draw_grass_dark(d, x, y):
    """Dark grass / forest floor."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_DARK)
    for px, py in [(2,1),(7,5),(12,9),(4,13),(9,3),(14,11),(1,7),(10,15)]:
        d.point((x+px, y+py), fill=GRASS_SHADOW)
    for px, py in [(5,8),(11,2)]:
        d.point((x+px, y+py), fill=GRASS_MID)

def draw_grass_flowers(d, x, y):
    """Grass with flower decorations."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_LIGHT)
    # Stems
    for px, py in [(3,7),(3,8),(10,5),(10,6)]:
        d.point((x+px, y+py), fill=FLOWER_STEM)
    # Flowers
    d.point((x+3, y+6), fill=FLOWER_RED)
    d.point((x+2, y+6), fill=FLOWER_RED)
    d.point((x+4, y+6), fill=FLOWER_RED)
    d.point((x+3, y+5), fill=FLOWER_RED)
    d.point((x+10, y+4), fill=FLOWER_YELLOW)
    d.point((x+9, y+4), fill=FLOWER_YELLOW)
    d.point((x+11, y+4), fill=FLOWER_YELLOW)
    d.point((x+10, y+3), fill=FLOWER_YELLOW)
    # Texture
    for px, py in [(7,2),(13,10),(1,13)]:
        d.point((x+px, y+py), fill=GRASS_MID)

def draw_tall_grass(d, x, y):
    """Encounter tall grass tile."""
    d.rectangle([x, y, x+15, y+15], fill=TALL_GRASS_A)
    # Grass blades pattern
    for col in range(0, 16, 3):
        d.line([(x+col, y+15), (x+col+1, y+6)], fill=TALL_GRASS_B, width=1)
        d.line([(x+col+1, y+15), (x+col+2, y+8)], fill=TALL_GRASS_TIP, width=1)
    # Tips
    for col in range(0, 16, 3):
        d.point((x+col+1, y+5), fill=TALL_GRASS_TIP)
        d.point((x+col+2, y+7), fill=TALL_GRASS_B)

def draw_dirt_path(d, x, y):
    """Dirt/path center tile."""
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    # Subtle texture
    for px, py in [(2,3),(7,1),(12,8),(4,12),(9,5),(14,14),(1,9),(8,11)]:
        d.point((x+px, y+py), fill=DIRT_LIGHT)
    for px, py in [(5,7),(11,2),(3,14),(13,10)]:
        d.point((x+px, y+py), fill=DIRT_DARK)

def draw_dirt_edge_top(d, x, y):
    """Dirt path with grass edge on top."""
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x, y, x+15, y+2], fill=GRASS_MID)
    d.line([(x, y+3), (x+15, y+3)], fill=DIRT_EDGE)
    for px in range(0, 16, 4):
        d.point((x+px, y+3), fill=GRASS_DARK)

def draw_dirt_edge_bottom(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x, y+13, x+15, y+15], fill=GRASS_MID)
    d.line([(x, y+12), (x+15, y+12)], fill=DIRT_EDGE)
    for px in range(0, 16, 4):
        d.point((x+px+2, y+12), fill=GRASS_DARK)

def draw_dirt_edge_left(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x, y, x+2, y+15], fill=GRASS_MID)
    d.line([(x+3, y), (x+3, y+15)], fill=DIRT_EDGE)

def draw_dirt_edge_right(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x+13, y, x+15, y+15], fill=GRASS_MID)
    d.line([(x+12, y), (x+12, y+15)], fill=DIRT_EDGE)

def draw_dirt_corner_tl(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x, y, x+2, y+15], fill=GRASS_MID)
    d.rectangle([x, y, x+15, y+2], fill=GRASS_MID)
    d.line([(x+3, y+3), (x+15, y+3)], fill=DIRT_EDGE)
    d.line([(x+3, y+3), (x+3, y+15)], fill=DIRT_EDGE)

def draw_dirt_corner_tr(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x+13, y, x+15, y+15], fill=GRASS_MID)
    d.rectangle([x, y, x+15, y+2], fill=GRASS_MID)
    d.line([(x, y+3), (x+12, y+3)], fill=DIRT_EDGE)
    d.line([(x+12, y+3), (x+12, y+15)], fill=DIRT_EDGE)

def draw_dirt_corner_bl(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x, y, x+2, y+15], fill=GRASS_MID)
    d.rectangle([x, y+13, x+15, y+15], fill=GRASS_MID)
    d.line([(x+3, y), (x+3, y+12)], fill=DIRT_EDGE)
    d.line([(x+3, y+12), (x+15, y+12)], fill=DIRT_EDGE)

def draw_dirt_corner_br(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=DIRT_MID)
    d.rectangle([x+13, y, x+15, y+15], fill=GRASS_MID)
    d.rectangle([x, y+13, x+15, y+15], fill=GRASS_MID)
    d.line([(x, y+12), (x+12, y+12)], fill=DIRT_EDGE)
    d.line([(x+12, y), (x+12, y+12)], fill=DIRT_EDGE)

def draw_water(d, x, y):
    """Water tile with wave pattern."""
    d.rectangle([x, y, x+15, y+15], fill=WATER_MID)
    # Waves
    for row in range(0, 16, 4):
        for col in range(0, 16, 6):
            offset = (row // 4) * 3
            cx = (col + offset) % 16
            d.line([(x+cx, y+row), (x+min(cx+3,15), y+row)], fill=WATER_LIGHT)
    # Shine
    d.point((x+4, y+2), fill=WATER_SHINE)
    d.point((x+5, y+2), fill=WATER_SHINE)
    d.point((x+12, y+10), fill=WATER_SHINE)

def draw_water_edge_top(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=WATER_MID)
    d.rectangle([x, y, x+15, y+2], fill=SAND_MID)
    d.line([(x, y+3), (x+15, y+3)], fill=WATER_DARK)
    for col in range(0, 16, 6):
        d.line([(x+col, y+8), (x+col+3, y+8)], fill=WATER_LIGHT)

def draw_water_deep(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=WATER_DEEP)
    for row in range(0, 16, 5):
        for col in range(0, 16, 7):
            d.line([(x+col, y+row), (x+min(col+2,15), y+row)], fill=WATER_DARK)

def draw_sand(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=SAND_MID)
    for px, py in [(3,2),(8,7),(13,4),(1,11),(6,14),(11,9),(5,1),(14,13)]:
        d.point((x+px, y+py), fill=SAND_LIGHT)
    for px, py in [(2,8),(9,12),(14,1)]:
        d.point((x+px, y+py), fill=SAND_DARK)

def draw_tree_canopy_tl(d, x, y):
    """Tree canopy top-left quadrant."""
    d.rectangle([x, y, x+15, y+15], fill=(0,0,0,0))
    # Round canopy shape
    d.rectangle([x+4, y+4, x+15, y+15], fill=TREE_CANOPY)
    d.rectangle([x+8, y+2, x+15, y+15], fill=TREE_CANOPY)
    d.rectangle([x+6, y+3, x+15, y+15], fill=TREE_CANOPY)
    # Highlight
    d.rectangle([x+8, y+4, x+13, y+8], fill=TREE_CANOPY_L)
    # Shadow
    d.rectangle([x+4, y+12, x+8, y+15], fill=TREE_CANOPY_D)

def draw_tree_canopy_tr(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=(0,0,0,0))
    d.rectangle([x, y+4, x+11, y+15], fill=TREE_CANOPY)
    d.rectangle([x, y+2, x+7, y+15], fill=TREE_CANOPY)
    d.rectangle([x, y+3, x+9, y+15], fill=TREE_CANOPY)
    d.rectangle([x+2, y+4, x+7, y+8], fill=TREE_CANOPY_L)
    d.rectangle([x+7, y+12, x+11, y+15], fill=TREE_CANOPY_D)

def draw_tree_canopy_bl(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=(0,0,0,0))
    d.rectangle([x+4, y, x+15, y+11], fill=TREE_CANOPY)
    d.rectangle([x+6, y, x+15, y+12], fill=TREE_CANOPY)
    d.rectangle([x+2, y, x+15, y+8], fill=TREE_CANOPY)
    d.rectangle([x+4, y+2, x+10, y+6], fill=TREE_CANOPY_D)

def draw_tree_canopy_br(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=(0,0,0,0))
    d.rectangle([x, y, x+11, y+11], fill=TREE_CANOPY)
    d.rectangle([x, y, x+9, y+12], fill=TREE_CANOPY)
    d.rectangle([x, y, x+13, y+8], fill=TREE_CANOPY)
    d.rectangle([x+5, y+2, x+11, y+6], fill=TREE_CANOPY_D)

def draw_tree_trunk(d, x, y):
    """Tree trunk (bottom center of a 2-wide tree)."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    # Trunk
    d.rectangle([x+4, y, x+11, y+12], fill=TREE_TRUNK)
    d.rectangle([x+4, y, x+6, y+12], fill=TREE_TRUNK_D)
    # Roots
    d.rectangle([x+2, y+10, x+4, y+13], fill=TREE_TRUNK_D)
    d.rectangle([x+11, y+10, x+13, y+13], fill=TREE_TRUNK_D)
    # Ground
    d.rectangle([x, y+13, x+15, y+15], fill=GRASS_MID)

def draw_tree_full(d, x, y):
    """Compact 1-tile tree (for dense forests)."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_DARK)
    # Canopy
    d.ellipse([x+1, y+0, x+14, y+10], fill=TREE_CANOPY)
    d.ellipse([x+2, y+1, x+12, y+8], fill=TREE_CANOPY_L)
    # Trunk
    d.rectangle([x+6, y+10, x+9, y+15], fill=TREE_TRUNK)
    d.rectangle([x+6, y+10, x+7, y+15], fill=TREE_TRUNK_D)

def draw_wall_gray(d, x, y):
    """Building wall - gray."""
    d.rectangle([x, y, x+15, y+15], fill=WALL_GRAY)
    # Brick pattern
    for row in range(0, 16, 4):
        d.line([(x, y+row), (x+15, y+row)], fill=WALL_GRAY_D)
        offset = 8 if (row // 4) % 2 else 0
        for col in range(offset, 16, 8):
            d.line([(x+col, y+row), (x+col, y+row+3)], fill=WALL_GRAY_D)

def draw_wall_red(d, x, y):
    """Pokemon Center wall."""
    d.rectangle([x, y, x+15, y+15], fill=(232, 184, 176))
    for row in range(0, 16, 4):
        d.line([(x, y+row), (x+15, y+row)], fill=(208, 152, 144))
        offset = 8 if (row // 4) % 2 else 0
        for col in range(offset, 16, 8):
            d.line([(x+col, y+row), (x+col, y+row+3)], fill=(208, 152, 144))

def draw_wall_blue(d, x, y):
    """Pokemart wall."""
    d.rectangle([x, y, x+15, y+15], fill=(176, 192, 232))
    for row in range(0, 16, 4):
        d.line([(x, y+row), (x+15, y+row)], fill=(144, 160, 208))
        offset = 8 if (row // 4) % 2 else 0
        for col in range(offset, 16, 8):
            d.line([(x+col, y+row), (x+col, y+row+3)], fill=(144, 160, 208))

def draw_roof_red(d, x, y):
    """Pokemon Center roof."""
    d.rectangle([x, y, x+15, y+15], fill=ROOF_RED)
    d.line([(x, y+15), (x+15, y+15)], fill=ROOF_RED_D)
    d.line([(x, y+14), (x+15, y+14)], fill=ROOF_RED_D)
    # Shingle pattern
    for row in range(0, 14, 4):
        offset = 4 if (row // 4) % 2 else 0
        for col in range(offset, 16, 8):
            d.arc([x+col, y+row, x+col+7, y+row+4], 0, 180, fill=(224, 80, 72))

def draw_roof_blue(d, x, y):
    """Pokemart roof."""
    d.rectangle([x, y, x+15, y+15], fill=ROOF_BLUE)
    d.line([(x, y+15), (x+15, y+15)], fill=ROOF_BLUE_D)
    d.line([(x, y+14), (x+15, y+14)], fill=ROOF_BLUE_D)
    for row in range(0, 14, 4):
        offset = 4 if (row // 4) % 2 else 0
        for col in range(offset, 16, 8):
            d.arc([x+col, y+row, x+col+7, y+row+4], 0, 180, fill=(80, 120, 224))

def draw_roof_green(d, x, y):
    """House roof - green."""
    base = (96, 160, 80)
    dark = (72, 128, 56)
    d.rectangle([x, y, x+15, y+15], fill=base)
    d.line([(x, y+15), (x+15, y+15)], fill=dark)
    d.line([(x, y+14), (x+15, y+14)], fill=dark)

def draw_door(d, x, y):
    """Building door tile."""
    d.rectangle([x, y, x+15, y+15], fill=WALL_GRAY)
    # Door frame
    d.rectangle([x+3, y+2, x+12, y+15], fill=DOOR_BROWN)
    d.rectangle([x+4, y+3, x+11, y+15], fill=DOOR_BROWN_L)
    # Handle
    d.point((x+9, y+9), fill=(200, 176, 80))
    d.point((x+9, y+10), fill=(200, 176, 80))
    # Top frame
    d.line([(x+3, y+2), (x+12, y+2)], fill=TREE_TRUNK_D)

def draw_window(d, x, y):
    """Building window tile."""
    d.rectangle([x, y, x+15, y+15], fill=WALL_GRAY)
    # Window frame
    d.rectangle([x+3, y+3, x+12, y+12], fill=WINDOW_FRAME)
    # Glass
    d.rectangle([x+4, y+4, x+7, y+7], fill=WINDOW_CYAN)
    d.rectangle([x+8, y+4, x+11, y+7], fill=WINDOW_CYAN)
    d.rectangle([x+4, y+8, x+7, y+11], fill=(112, 192, 224))
    d.rectangle([x+8, y+8, x+11, y+11], fill=(112, 192, 224))
    # Cross frame
    d.line([(x+3, y+7), (x+12, y+7)], fill=WINDOW_FRAME)
    d.line([(x+7, y+3), (x+7, y+12)], fill=WINDOW_FRAME)

def draw_sign_tile(d, x, y):
    """Sign post tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    # Post
    d.rectangle([x+7, y+8, x+8, y+15], fill=SIGN_POST)
    # Board
    d.rectangle([x+2, y+2, x+13, y+9], fill=SIGN_BOARD)
    d.rectangle([x+2, y+2, x+13, y+3], fill=FENCE_WOOD_D)
    d.rectangle([x+2, y+8, x+13, y+9], fill=FENCE_WOOD_D)
    # Text line
    d.line([(x+4, y+5), (x+11, y+5)], fill=TREE_TRUNK_D)
    d.line([(x+5, y+7), (x+10, y+7)], fill=TREE_TRUNK_D)

def draw_fence_h(d, x, y):
    """Horizontal fence tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    d.rectangle([x, y+5, x+15, y+7], fill=FENCE_WOOD)
    d.rectangle([x, y+10, x+15, y+12], fill=FENCE_WOOD)
    d.line([(x, y+5), (x+15, y+5)], fill=FENCE_WOOD_D)
    d.line([(x, y+10), (x+15, y+10)], fill=FENCE_WOOD_D)

def draw_fence_v(d, x, y):
    """Vertical fence tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    d.rectangle([x+6, y, x+9, y+15], fill=FENCE_WOOD)
    d.line([(x+6, y), (x+6, y+15)], fill=FENCE_WOOD_D)

def draw_fence_post(d, x, y):
    """Fence post tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    d.rectangle([x+5, y+3, x+10, y+12], fill=FENCE_WOOD)
    d.rectangle([x+4, y+2, x+11, y+4], fill=FENCE_WOOD_D)
    d.rectangle([x+5, y+3, x+7, y+12], fill=FENCE_WOOD_D)

def draw_rock(d, x, y):
    """Rock/boulder tile."""
    d.rectangle([x, y, x+15, y+15], fill=GRASS_MID)
    # Rock shape
    pts = [(4,12),(2,8),(3,5),(6,3),(10,3),(13,5),(14,8),(12,12)]
    d.polygon([(x+px, y+py) for px,py in pts], fill=ROCK_MID)
    # Highlight
    d.polygon([(x+5,y+5),(x+6,y+4),(x+10,y+4),(x+12,y+6),(x+10,y+7),(x+5,y+7)], fill=ROCK_LIGHT)
    # Shadow
    d.polygon([(x+4,y+11),(x+3,y+9),(x+5,y+10),(x+11,y+10),(x+13,y+9),(x+12,y+11)], fill=ROCK_DARK)

def draw_border(d, x, y):
    """Black border/void tile."""
    d.rectangle([x, y, x+15, y+15], fill=BORDER_BLACK)

def draw_border_dark(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=BORDER_DARK)

def draw_cliff_face(d, x, y):
    """Cliff face (vertical wall)."""
    d.rectangle([x, y, x+15, y+15], fill=(120, 112, 96))
    for row in range(0, 16, 3):
        d.line([(x, y+row), (x+15, y+row)], fill=(96, 88, 72))
    d.line([(x, y), (x+15, y)], fill=(80, 72, 56))

def draw_cliff_top(d, x, y):
    """Top of cliff (grass above, cliff edge)."""
    d.rectangle([x, y, x+15, y+9], fill=GRASS_MID)
    d.rectangle([x, y+10, x+15, y+15], fill=(120, 112, 96))
    d.line([(x, y+10), (x+15, y+10)], fill=(80, 72, 56))

def draw_gym_floor(d, x, y):
    """Gym floor tile."""
    d.rectangle([x, y, x+15, y+15], fill=GYM_FLOOR_L)
    d.rectangle([x, y, x+7, y+7], fill=GYM_FLOOR_D)
    d.rectangle([x+8, y+8, x+15, y+15], fill=GYM_FLOOR_D)
    d.line([(x, y), (x+15, y)], fill=GYM_WALL)
    d.line([(x, y), (x, y+15)], fill=GYM_WALL)

def draw_gym_wall(d, x, y):
    """Gym wall tile."""
    d.rectangle([x, y, x+15, y+15], fill=GYM_WALL)
    d.line([(x, y), (x+15, y)], fill=(120, 112, 96))
    d.line([(x, y+15), (x+15, y+15)], fill=(168, 160, 144))

def draw_pokecenter_cross(d, x, y):
    """Pokemon Center cross symbol on roof."""
    d.rectangle([x, y, x+15, y+15], fill=ROOF_RED)
    # White cross
    d.rectangle([x+6, y+2, x+9, y+13], fill=(255, 255, 255))
    d.rectangle([x+3, y+5, x+12, y+10], fill=(255, 255, 255))

def draw_pokemart_p(d, x, y):
    """Pokemart 'P' symbol on roof."""
    d.rectangle([x, y, x+15, y+15], fill=ROOF_BLUE)
    # P shape
    d.rectangle([x+4, y+3, x+6, y+12], fill=(255, 255, 255))
    d.rectangle([x+6, y+3, x+11, y+4], fill=(255, 255, 255))
    d.rectangle([x+10, y+4, x+11, y+7], fill=(255, 255, 255))
    d.rectangle([x+6, y+7, x+11, y+8], fill=(255, 255, 255))

def draw_flower_garden_red(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=GRASS_LIGHT)
    for fx, fy in [(2,3),(6,7),(10,2),(14,6),(3,11),(8,13),(12,10),(1,7)]:
        d.point((x+fx, y+fy), fill=FLOWER_RED)
        d.point((x+fx, y+fy+1), fill=FLOWER_STEM)

def draw_flower_garden_blue(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=GRASS_LIGHT)
    for fx, fy in [(2,3),(6,7),(10,2),(14,6),(3,11),(8,13),(12,10),(1,7)]:
        d.point((x+fx, y+fy), fill=FLOWER_BLUE)
        d.point((x+fx, y+fy+1), fill=FLOWER_STEM)

def draw_flower_garden_yellow(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=GRASS_LIGHT)
    for fx, fy in [(2,3),(6,7),(10,2),(14,6),(3,11),(8,13),(12,10),(1,7)]:
        d.point((x+fx, y+fy), fill=FLOWER_YELLOW)
        d.point((x+fx, y+fy+1), fill=FLOWER_STEM)

def draw_lava(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=LAVA_MID)
    for row in range(0, 16, 5):
        for col in range(0, 16, 6):
            d.line([(x+col, y+row), (x+min(col+3,15), y+row)], fill=LAVA_LIGHT)
    d.point((x+3, y+8), fill=LAVA_DARK)
    d.point((x+11, y+3), fill=LAVA_DARK)

def draw_psy_floor(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=PSY_LIGHT)
    d.rectangle([x, y, x+7, y+7], fill=PSY_MID)
    d.rectangle([x+8, y+8, x+15, y+15], fill=PSY_MID)

def draw_poison_floor(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=POISON_LIGHT)
    d.rectangle([x, y, x+7, y+7], fill=POISON_MID)
    d.rectangle([x+8, y+8, x+15, y+15], fill=POISON_MID)

def draw_electric_floor(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=ELEC_LIGHT)
    # Lightning bolt pattern
    d.line([(x+7, y+2), (x+5, y+7)], fill=ELEC_MID)
    d.line([(x+5, y+7), (x+9, y+7)], fill=ELEC_MID)
    d.line([(x+9, y+7), (x+6, y+13)], fill=ELEC_MID)

def draw_ice_floor(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=ICE_LIGHT)
    d.rectangle([x, y, x+7, y+7], fill=ICE_MID)
    d.rectangle([x+8, y+8, x+15, y+15], fill=ICE_MID)

def draw_gym_badge_podium(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=GYM_FLOOR_L)
    # Podium
    d.rectangle([x+3, y+4, x+12, y+12], fill=(176, 152, 96))
    d.rectangle([x+4, y+5, x+11, y+11], fill=(208, 184, 120))
    # Badge symbol
    d.rectangle([x+6, y+6, x+9, y+9], fill=(248, 216, 64))

def draw_stairs_up(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=GYM_FLOOR_L)
    for i in range(4):
        shade = 160 + i * 20
        d.rectangle([x, y+i*4, x+15, y+i*4+3], fill=(shade, shade-8, shade-16))

def draw_bridge_h(d, x, y):
    d.rectangle([x, y, x+15, y+15], fill=WATER_MID)
    d.rectangle([x, y+4, x+15, y+11], fill=FENCE_WOOD)
    d.line([(x, y+4), (x+15, y+4)], fill=FENCE_WOOD_D)
    d.line([(x, y+11), (x+15, y+11)], fill=FENCE_WOOD_D)

def draw_roof_gym_generic(d, x, y, color):
    d.rectangle([x, y, x+15, y+15], fill=color)
    darker = tuple(max(0, c-40) for c in color)
    d.line([(x, y+15), (x+15, y+15)], fill=darker)
    d.line([(x, y+14), (x+15, y+14)], fill=darker)

def draw_wall_gym_generic(d, x, y, color):
    d.rectangle([x, y, x+15, y+15], fill=color)
    darker = tuple(max(0, c-40) for c in color)
    for row in range(0, 16, 4):
        d.line([(x, y+row), (x+15, y+row)], fill=darker)

# Gym type colors
GYM_COLORS = {
    "rock":     (160, 128, 80),
    "water":    (80, 144, 216),
    "electric": (224, 200, 64),
    "grass":    (80, 176, 80),
    "psychic":  (192, 112, 200),
    "poison":   (152, 80, 184),
    "fire":     (224, 112, 48),
    "ground":   (176, 144, 88),
}

# ── Atlas tile layout (col, row) → draw function ────────────────
# Row 0: Base terrain
# Row 1: Path edges & corners
# Row 2: Nature (trees, rocks, flowers)
# Row 3: Buildings (walls, roofs, doors, windows)
# Row 4: Special tiles (gym, signs, fences, borders)
# Row 5: Gym-type floors & themed tiles
# Row 6: More building variants

TILE_MAP = [
    # Row 0: Base terrain
    (draw_grass_light, "grass_light"),
    (draw_grass_mid, "grass_mid"),
    (draw_grass_dark, "grass_dark"),
    (draw_grass_flowers, "grass_flowers"),
    (draw_tall_grass, "tall_grass"),
    (draw_dirt_path, "dirt_path"),
    (draw_sand, "sand"),
    (draw_water, "water"),
    (draw_water_edge_top, "water_edge_top"),
    (draw_water_deep, "water_deep"),
    (draw_lava, "lava"),
    (draw_psy_floor, "psy_floor"),
    (draw_poison_floor, "poison_floor"),
    (draw_electric_floor, "electric_floor"),
    (draw_ice_floor, "ice_floor"),
    (draw_border, "border_black"),

    # Row 1: Path edges
    (draw_dirt_edge_top, "dirt_edge_top"),
    (draw_dirt_edge_bottom, "dirt_edge_bottom"),
    (draw_dirt_edge_left, "dirt_edge_left"),
    (draw_dirt_edge_right, "dirt_edge_right"),
    (draw_dirt_corner_tl, "dirt_corner_tl"),
    (draw_dirt_corner_tr, "dirt_corner_tr"),
    (draw_dirt_corner_bl, "dirt_corner_bl"),
    (draw_dirt_corner_br, "dirt_corner_br"),
    (draw_cliff_face, "cliff_face"),
    (draw_cliff_top, "cliff_top"),
    (draw_bridge_h, "bridge_h"),
    (draw_stairs_up, "stairs"),
    (draw_border_dark, "border_dark"),
    (None, "empty"),
    (None, "empty"),
    (None, "empty"),

    # Row 2: Nature
    (draw_tree_canopy_tl, "tree_tl"),
    (draw_tree_canopy_tr, "tree_tr"),
    (draw_tree_canopy_bl, "tree_bl"),
    (draw_tree_canopy_br, "tree_br"),
    (draw_tree_trunk, "tree_trunk"),
    (draw_tree_full, "tree_full"),
    (draw_rock, "rock"),
    (draw_flower_garden_red, "flowers_red"),
    (draw_flower_garden_blue, "flowers_blue"),
    (draw_flower_garden_yellow, "flowers_yellow"),
    (draw_fence_h, "fence_h"),
    (draw_fence_v, "fence_v"),
    (draw_fence_post, "fence_post"),
    (draw_sign_tile, "sign"),
    (None, "empty"),
    (None, "empty"),

    # Row 3: Buildings
    (draw_wall_gray, "wall_gray"),
    (draw_wall_red, "wall_red"),
    (draw_wall_blue, "wall_blue"),
    (draw_roof_red, "roof_red"),
    (draw_roof_blue, "roof_blue"),
    (draw_roof_green, "roof_green"),
    (draw_door, "door"),
    (draw_window, "window"),
    (draw_pokecenter_cross, "pokecenter_cross"),
    (draw_pokemart_p, "pokemart_p"),
    (draw_gym_floor, "gym_floor"),
    (draw_gym_wall, "gym_wall"),
    (draw_gym_badge_podium, "badge_podium"),
    (None, "empty"),
    (None, "empty"),
    (None, "empty"),

    # Row 4: Gym-typed tiles (roof, wall, floor for each gym type)
]

# Add gym type tiles
for gtype, color in GYM_COLORS.items():
    # Create closure-bound functions
    def make_roof(c):
        return lambda d, x, y: draw_roof_gym_generic(d, x, y, c)
    def make_wall(c):
        lighter = tuple(min(255, v+60) for v in c)
        return lambda d, x, y: draw_wall_gym_generic(d, x, y, lighter)
    TILE_MAP.append((make_roof(color), f"gym_roof_{gtype}"))
    TILE_MAP.append((make_wall(color), f"gym_wall_{gtype}"))


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    n_tiles = len(TILE_MAP)
    rows = (n_tiles + COLS - 1) // COLS
    width = COLS * TILE
    height = rows * TILE

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    tile_index = {}
    idx = 0
    for func, name in TILE_MAP:
        if name == "empty" or func is None:
            idx += 1
            continue
        col = idx % COLS
        row = idx // COLS
        x = col * TILE
        y = row * TILE
        func(draw, x, y)
        tile_index[name] = {"col": col, "row": row, "idx": idx}
        idx += 1

    # Save atlas
    atlas_path = os.path.join(OUTPUT_DIR, "tileset.png")
    img.save(atlas_path)
    print(f"Tileset saved: {atlas_path} ({width}x{height}, {len(tile_index)} tiles)")

    # Save tile index as GDScript constants
    gd_path = os.path.join(OUTPUT_DIR, "tile_index.gd")
    with open(gd_path, "w", encoding="utf-8") as f:
        f.write("## Auto-generated tile index — do not edit manually.\n")
        f.write("## Maps atlas coords (col, row) for each tile name.\n\n")
        f.write("const TILES := {\n")
        for name, info in sorted(tile_index.items()):
            f.write(f'\t"{name}": Vector2i({info["col"]}, {info["row"]}),\n')
        f.write("}\n")

    print(f"Tile index saved: {gd_path} ({len(tile_index)} entries)")

    # Also generate a visual reference
    ref_path = os.path.join(OUTPUT_DIR, "tile_reference.txt")
    with open(ref_path, "w", encoding="utf-8") as f:
        f.write("TILE REFERENCE\n")
        f.write(f"Atlas: {COLS} columns, {rows} rows, {TILE}x{TILE}px tiles\n\n")
        for name, info in sorted(tile_index.items()):
            f.write(f"  {name:24s} → col={info['col']:2d}, row={info['row']:2d} (idx={info['idx']})\n")

    print(f"Reference saved: {ref_path}")


if __name__ == "__main__":
    main()
