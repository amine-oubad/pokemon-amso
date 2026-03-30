#!/usr/bin/env python3
"""Generate 6 biome tilesets with clean pixel art (no noise, proper shapes).
Each tileset is 256x256 (16 cols x 16 rows of 16x16 tiles).
Style: GBA Pokemon (Unbound/Radical Red) — clean outlines, limited palette, recognizable shapes.
"""
from PIL import Image, ImageDraw
import os

OUT = "assets/tilesets"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    return tuple(int(h.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))

def put(img, x, y, c, a=255):
    """Set a single pixel."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), (*c, a))

def fill(img, x, y, w, h, c, a=255):
    """Fill a rectangle."""
    draw = ImageDraw.Draw(img)
    draw.rectangle([x, y, x+w-1, y+h-1], fill=(*c, a))

def hline(img, x, y, w, c):
    for i in range(w): put(img, x+i, y, c)

def vline(img, x, y, h, c):
    for i in range(h): put(img, x, y+i, c)

# =====================================================================
# TILE DRAWING FUNCTIONS — clean pixel art
# =====================================================================

def draw_grass(img, tx, ty, c1, c2, c3=None):
    """Flat grass tile with subtle 2-color dither pattern."""
    fill(img, tx, ty, 16, 16, c1)
    # Subtle texture dots
    for py in range(0, 16, 4):
        for px in range(0, 16, 4):
            offset = (py // 4) % 2 * 2
            put(img, tx + px + offset, ty + py, c2)
    if c3:
        put(img, tx+3, ty+7, c3)
        put(img, tx+11, ty+3, c3)
        put(img, tx+7, ty+13, c3)

def draw_path(img, tx, ty, c1, c2, edge=None):
    """Dirt/stone path tile with optional edge."""
    fill(img, tx, ty, 16, 16, c1)
    # Subtle stone/gravel texture
    for py in range(0, 16, 3):
        for px in range(1, 16, 5):
            put(img, tx+px, ty+py, c2)
    # Edge highlight
    if edge == 'top': hline(img, tx, ty, 16, c2); hline(img, tx, ty+1, 16, c2)
    elif edge == 'bottom': hline(img, tx, ty+14, 16, c2); hline(img, tx, ty+15, 16, c2)
    elif edge == 'left': vline(img, tx, ty, 16, c2); vline(img, tx+1, ty, 16, c2)
    elif edge == 'right': vline(img, tx+14, ty, 16, c2); vline(img, tx+15, ty, 16, c2)

def draw_tall_grass(img, tx, ty, ground, dark, light):
    """Tall grass with visible blade shapes."""
    fill(img, tx, ty, 16, 16, ground)
    # Draw distinct grass blades
    blades = [(2,5),(5,3),(8,6),(11,4),(14,5),(3,10),(7,9),(10,11),(13,8)]
    for bx, bh in blades:
        for i in range(bh):
            c = light if i < bh//2 else dark
            put(img, tx+bx, ty+15-i, c)
            if i > 0: put(img, tx+bx-1, ty+15-i+1, c)

def draw_water(img, tx, ty, c1, c2, highlight, frame=0):
    """Water tile with wave pattern."""
    fill(img, tx, ty, 16, 16, c1)
    # Wave lines
    for wy in range(2, 16, 4):
        off = frame * 2
        for wx in range(16):
            wave_y = wy + (1 if (wx + off) % 6 < 3 else 0)
            if 0 <= wave_y < 16:
                put(img, tx+wx, ty+wave_y, c2)
    # Highlights
    put(img, tx+3+frame, ty+1, highlight)
    put(img, tx+4+frame, ty+1, highlight)
    put(img, tx+10-frame, ty+9, highlight)
    put(img, tx+11-frame, ty+9, highlight)

def draw_tree_top(img, tx, ty, canopy_dark, canopy_mid, canopy_light):
    """Tree top canopy (16x16) — round bushy shape with shading."""
    # Shape: rounded top
    rows = [
        (5, 11),   # y=0:  ....XXXXXXX.....
        (3, 13),   # y=1:  ...XXXXXXXXXX...
        (2, 14),   # y=2
        (1, 15),   # y=3
        (1, 15),   # y=4
        (0, 16),   # y=5
        (0, 16),   # y=6
        (0, 16),   # y=7
        (0, 16),   # y=8
        (1, 15),   # y=9
        (1, 15),   # y=10
        (2, 14),   # y=11
        (2, 14),   # y=12
        (3, 13),   # y=13
        (4, 12),   # y=14
        (5, 11),   # y=15
    ]
    for y, (x1, x2) in enumerate(rows):
        for x in range(x1, x2):
            # Shading: left+top = light, right+bottom = dark
            if x < x1 + (x2-x1)//3 or y < 4:
                c = canopy_light
            elif x > x2 - (x2-x1)//3 or y > 12:
                c = canopy_dark
            else:
                c = canopy_mid
            put(img, tx+x, ty+y, c)
    # Outline (1px darker)
    outline = (max(0,canopy_dark[0]-30), max(0,canopy_dark[1]-30), max(0,canopy_dark[2]-20))
    for y, (x1, x2) in enumerate(rows):
        put(img, tx+x1, ty+y, outline)
        put(img, tx+x2-1, ty+y, outline)
    for x in range(rows[0][0], rows[0][1]): put(img, tx+x, ty, outline)
    for x in range(rows[-1][0], rows[-1][1]): put(img, tx+x, ty+15, outline)

def draw_tree_trunk(img, tx, ty, trunk, trunk_dark, ground):
    """Tree trunk (16x16) — bottom part with trunk + canopy overhang."""
    fill(img, tx, ty, 16, 16, ground)
    # Trunk (centered, 4px wide)
    fill(img, tx+6, ty, 4, 16, trunk)
    fill(img, tx+7, ty, 2, 16, trunk_dark)  # shadow
    # Canopy overhang at top
    canopy = (max(0,trunk[0]-10), trunk[1]+30, max(0,trunk[2]-10))
    fill(img, tx+2, ty, 12, 5, canopy)
    fill(img, tx+1, ty+1, 14, 3, canopy)

def draw_rock(img, tx, ty, base, light, dark, ground):
    """Rock obstacle — rounded boulder shape."""
    fill(img, tx, ty, 16, 16, ground)
    # Rock shape
    rows = [(5,11),(3,13),(2,14),(2,14),(1,15),(1,15),(1,15),(1,15),
            (2,14),(2,14),(3,13),(4,12)]
    for i, (x1, x2) in enumerate(rows):
        y = ty + 2 + i
        for x in range(x1, x2):
            if x < x1+2 or i < 3: c = light
            elif x > x2-3 or i > 8: c = dark
            else: c = base
            put(img, tx+x, y, c)
    # Outline
    outline = (max(0,dark[0]-20), max(0,dark[1]-20), max(0,dark[2]-20))
    for i, (x1, x2) in enumerate(rows):
        put(img, tx+x1, ty+2+i, outline)
        put(img, tx+x2-1, ty+2+i, outline)

def draw_flower(img, tx, ty, ground, petal, center):
    """Ground tile with small flower."""
    fill(img, tx, ty, 16, 16, ground)
    # Flower at center
    put(img, tx+7, ty+6, petal); put(img, tx+9, ty+6, petal)
    put(img, tx+6, ty+7, petal); put(img, tx+8, ty+7, center); put(img, tx+10, ty+7, petal)
    put(img, tx+7, ty+8, petal); put(img, tx+9, ty+8, petal)
    # Stem
    put(img, tx+8, ty+9, (40, 100, 40))
    put(img, tx+8, ty+10, (40, 100, 40))
    # Second smaller flower
    put(img, tx+3, ty+12, petal)
    put(img, tx+2, ty+13, petal); put(img, tx+3, ty+13, center); put(img, tx+4, ty+13, petal)
    put(img, tx+3, ty+14, (40, 100, 40))

def draw_fence_h(img, tx, ty, wood, dark, ground):
    """Horizontal fence."""
    fill(img, tx, ty, 16, 16, ground)
    fill(img, tx, ty+5, 16, 2, wood)    # top rail
    fill(img, tx, ty+10, 16, 2, wood)   # bottom rail
    fill(img, tx, ty+5, 16, 1, dark)    # shadow
    fill(img, tx, ty+10, 16, 1, dark)

def draw_sign(img, tx, ty, wood, board, ground):
    """Signpost."""
    fill(img, tx, ty, 16, 16, ground)
    # Post
    fill(img, tx+7, ty+8, 2, 8, wood)
    # Board
    fill(img, tx+3, ty+2, 10, 7, board)
    # Border
    outline = (max(0,wood[0]-30), max(0,wood[1]-30), max(0,wood[2]-20))
    hline(img, tx+3, ty+2, 10, outline)
    hline(img, tx+3, ty+8, 10, outline)
    vline(img, tx+3, ty+2, 7, outline)
    vline(img, tx+12, ty+2, 7, outline)
    # Text lines
    hline(img, tx+5, ty+4, 6, outline)
    hline(img, tx+5, ty+6, 4, outline)

def draw_building_roof(img, tx, ty, roof_c, roof_dark):
    """Building roof tile (top section)."""
    fill(img, tx, ty, 16, 16, roof_c)
    # Roof shading (lighter top, darker bottom)
    fill(img, tx, ty, 16, 3, (min(255,roof_c[0]+20), min(255,roof_c[1]+20), min(255,roof_c[2]+20)))
    fill(img, tx, ty+12, 16, 4, roof_dark)
    # Tile pattern
    for x in range(0, 16, 4):
        vline(img, tx+x, ty+4, 8, roof_dark)

def draw_wall(img, tx, ty, wall_c, wall_dark):
    """Building wall tile."""
    fill(img, tx, ty, 16, 16, wall_c)
    # Brick pattern
    for y in range(0, 16, 4):
        hline(img, tx, ty+y, 16, wall_dark)
        offset = 4 if (y//4) % 2 else 0
        for x in range(offset, 16, 8):
            vline(img, tx+x, ty+y, 4, wall_dark)

def draw_door(img, tx, ty, wall_c, door_c, door_dark):
    """Door tile on a wall."""
    fill(img, tx, ty, 16, 16, wall_c)
    # Door frame
    fill(img, tx+4, ty+2, 8, 14, door_c)
    fill(img, tx+5, ty+3, 6, 13, door_dark)
    # Handle
    put(img, tx+10, ty+9, (200, 180, 100))
    # Top frame
    hline(img, tx+4, ty+2, 8, (max(0,door_c[0]-30), max(0,door_c[1]-30), max(0,door_c[2]-20)))

def draw_window(img, tx, ty, wall_c, glass_c, frame_c):
    """Window tile on a wall."""
    fill(img, tx, ty, 16, 16, wall_c)
    # Window frame
    fill(img, tx+3, ty+3, 10, 10, frame_c)
    fill(img, tx+4, ty+4, 8, 8, glass_c)
    # Cross pane
    hline(img, tx+4, ty+8, 8, frame_c)
    vline(img, tx+8, ty+4, 8, frame_c)
    # Highlight
    put(img, tx+5, ty+5, (min(255,glass_c[0]+40), min(255,glass_c[1]+40), min(255,glass_c[2]+40)))

def draw_pokecenter_icon(img, tx, ty, roof_c, roof_dark):
    """Pokecenter roof with red cross."""
    draw_building_roof(img, tx, ty, roof_c, roof_dark)
    # White cross on center
    fill(img, tx+6, ty+3, 4, 10, (255, 255, 255))
    fill(img, tx+3, ty+6, 10, 4, (255, 255, 255))
    # Red cross
    fill(img, tx+7, ty+4, 2, 8, (220, 50, 50))
    fill(img, tx+4, ty+7, 8, 2, (220, 50, 50))

def draw_mart_icon(img, tx, ty, roof_c, roof_dark):
    """PokeMart roof with P symbol."""
    draw_building_roof(img, tx, ty, roof_c, roof_dark)
    # P letter
    fill(img, tx+5, ty+3, 2, 10, (255, 255, 255))
    fill(img, tx+7, ty+3, 4, 2, (255, 255, 255))
    fill(img, tx+7, ty+7, 4, 2, (255, 255, 255))
    fill(img, tx+10, ty+4, 2, 4, (255, 255, 255))

def draw_stairs(img, tx, ty, c1, c2):
    """Stairs tile."""
    for y in range(0, 16, 4):
        shade = max(0, c1[0] - y*2), max(0, c1[1] - y*2), max(0, c1[2] - y*2)
        fill(img, tx, ty+y, 16, 3, shade)
        hline(img, tx, ty+y+3, 16, c2)

def draw_black(img, tx, ty):
    fill(img, tx, ty, 16, 16, (8, 8, 16))

# =====================================================================
# BIOME PALETTE DEFINITIONS
# =====================================================================
BIOMES = {
    "grass": {
        "ground1": hex2rgb("#5CA040"), "ground2": hex2rgb("#4E9435"), "ground3": hex2rgb("#68A84A"),
        "path1": hex2rgb("#C4A45A"), "path2": hex2rgb("#B09048"), "path_edge": hex2rgb("#5CA040"),
        "water1": hex2rgb("#3088D8"), "water2": hex2rgb("#2870B8"), "water_hi": hex2rgb("#68C0F0"),
        "tall_dark": hex2rgb("#2E6E1A"), "tall_light": hex2rgb("#48A030"),
        "tree_dark": hex2rgb("#1E5E14"), "tree_mid": hex2rgb("#2E8820"), "tree_light": hex2rgb("#48B038"),
        "trunk": hex2rgb("#785828"), "trunk_dark": hex2rgb("#604018"),
        "rock": hex2rgb("#909080"), "rock_light": hex2rgb("#B0B0A0"), "rock_dark": hex2rgb("#686860"),
        "flower_r": hex2rgb("#E04848"), "flower_y": hex2rgb("#E8D030"), "flower_b": hex2rgb("#5878D0"),
        "flower_center": hex2rgb("#F8E860"),
        "fence": hex2rgb("#C8A870"), "fence_dark": hex2rgb("#A08050"),
        "sign_wood": hex2rgb("#906830"), "sign_board": hex2rgb("#D8C8A0"),
        "roof_red": hex2rgb("#D04040"), "roof_red_dk": hex2rgb("#A03030"),
        "roof_blue": hex2rgb("#4070C0"), "roof_blue_dk": hex2rgb("#305898"),
        "roof_green": hex2rgb("#409850"), "roof_green_dk": hex2rgb("#307838"),
        "wall": hex2rgb("#E0D8C8"), "wall_dark": hex2rgb("#C0B8A8"),
        "door": hex2rgb("#906030"), "door_dark": hex2rgb("#704820"),
        "glass": hex2rgb("#90C0E0"), "frame": hex2rgb("#606068"),
    },
    "forest": {
        "ground1": hex2rgb("#2E5E20"), "ground2": hex2rgb("#265418"), "ground3": hex2rgb("#386828"),
        "path1": hex2rgb("#8A7040"), "path2": hex2rgb("#786038"), "path_edge": hex2rgb("#2E5E20"),
        "water1": hex2rgb("#205898"), "water2": hex2rgb("#184878"), "water_hi": hex2rgb("#4898C8"),
        "tall_dark": hex2rgb("#1A4A10"), "tall_light": hex2rgb("#308020"),
        "tree_dark": hex2rgb("#144E0E"), "tree_mid": hex2rgb("#1E7014"), "tree_light": hex2rgb("#389828"),
        "trunk": hex2rgb("#5E4420"), "trunk_dark": hex2rgb("#483414"),
        "rock": hex2rgb("#686860"), "rock_light": hex2rgb("#888878"), "rock_dark": hex2rgb("#484840"),
        "flower_r": hex2rgb("#D8D040"), "flower_y": hex2rgb("#C8C020"), "flower_b": hex2rgb("#A0C840"),
        "flower_center": hex2rgb("#F0E050"),
        "fence": hex2rgb("#8A7040"), "fence_dark": hex2rgb("#685830"),
        "sign_wood": hex2rgb("#6E5028"), "sign_board": hex2rgb("#C0B088"),
        "roof_red": hex2rgb("#608840"), "roof_red_dk": hex2rgb("#487030"),
        "roof_blue": hex2rgb("#608840"), "roof_blue_dk": hex2rgb("#487030"),
        "roof_green": hex2rgb("#487038"), "roof_green_dk": hex2rgb("#385828"),
        "wall": hex2rgb("#A09878"), "wall_dark": hex2rgb("#887860"),
        "door": hex2rgb("#6E4820"), "door_dark": hex2rgb("#583818"),
        "glass": hex2rgb("#70A8C8"), "frame": hex2rgb("#505048"),
    },
    "city": {
        "ground1": hex2rgb("#A0A090"), "ground2": hex2rgb("#909080"), "ground3": hex2rgb("#A8A898"),
        "path1": hex2rgb("#C0B8A8"), "path2": hex2rgb("#B0A898"), "path_edge": hex2rgb("#A0A090"),
        "water1": hex2rgb("#3088D8"), "water2": hex2rgb("#2870B8"), "water_hi": hex2rgb("#68C0F0"),
        "tall_dark": hex2rgb("#408030"), "tall_light": hex2rgb("#58A040"),
        "tree_dark": hex2rgb("#286020"), "tree_mid": hex2rgb("#389030"), "tree_light": hex2rgb("#50B048"),
        "trunk": hex2rgb("#785828"), "trunk_dark": hex2rgb("#604018"),
        "rock": hex2rgb("#A8A898"), "rock_light": hex2rgb("#C0C0B0"), "rock_dark": hex2rgb("#888878"),
        "flower_r": hex2rgb("#E04848"), "flower_y": hex2rgb("#E8D030"), "flower_b": hex2rgb("#5070D0"),
        "flower_center": hex2rgb("#F8E860"),
        "fence": hex2rgb("#C0B8A8"), "fence_dark": hex2rgb("#A09888"),
        "sign_wood": hex2rgb("#807060"), "sign_board": hex2rgb("#D8D0C0"),
        "roof_red": hex2rgb("#D04040"), "roof_red_dk": hex2rgb("#A03030"),
        "roof_blue": hex2rgb("#4070C0"), "roof_blue_dk": hex2rgb("#305898"),
        "roof_green": hex2rgb("#409850"), "roof_green_dk": hex2rgb("#307838"),
        "wall": hex2rgb("#E8E0D0"), "wall_dark": hex2rgb("#D0C8B8"),
        "door": hex2rgb("#805828"), "door_dark": hex2rgb("#604020"),
        "glass": hex2rgb("#90C0E0"), "frame": hex2rgb("#686870"),
    },
    "cave": {
        "ground1": hex2rgb("#484050"), "ground2": hex2rgb("#403848"), "ground3": hex2rgb("#504858"),
        "path1": hex2rgb("#585060"), "path2": hex2rgb("#504850"), "path_edge": hex2rgb("#484050"),
        "water1": hex2rgb("#1E4878"), "water2": hex2rgb("#183860"), "water_hi": hex2rgb("#3878A8"),
        "tall_dark": hex2rgb("#384038"), "tall_light": hex2rgb("#485048"),
        "tree_dark": hex2rgb("#383038"), "tree_mid": hex2rgb("#484048"), "tree_light": hex2rgb("#585058"),
        "trunk": hex2rgb("#483828"), "trunk_dark": hex2rgb("#382818"),
        "rock": hex2rgb("#706868"), "rock_light": hex2rgb("#908880"), "rock_dark": hex2rgb("#504848"),
        "flower_r": hex2rgb("#484050"), "flower_y": hex2rgb("#484050"), "flower_b": hex2rgb("#484050"),
        "flower_center": hex2rgb("#484050"),
        "fence": hex2rgb("#585058"), "fence_dark": hex2rgb("#403840"),
        "sign_wood": hex2rgb("#504038"), "sign_board": hex2rgb("#787068"),
        "roof_red": hex2rgb("#504858"), "roof_red_dk": hex2rgb("#403848"),
        "roof_blue": hex2rgb("#504858"), "roof_blue_dk": hex2rgb("#403848"),
        "roof_green": hex2rgb("#504858"), "roof_green_dk": hex2rgb("#403848"),
        "wall": hex2rgb("#403848"), "wall_dark": hex2rgb("#302838"),
        "door": hex2rgb("#383028"), "door_dark": hex2rgb("#282018"),
        "glass": hex2rgb("#506878"), "frame": hex2rgb("#383038"),
    },
    "snow": {
        "ground1": hex2rgb("#E8EDF5"), "ground2": hex2rgb("#DDE3ED"), "ground3": hex2rgb("#F0F2F8"),
        "path1": hex2rgb("#C8CDD8"), "path2": hex2rgb("#B8C0CC"), "path_edge": hex2rgb("#E8EDF5"),
        "water1": hex2rgb("#88C8E8"), "water2": hex2rgb("#70B8D8"), "water_hi": hex2rgb("#B0E0F8"),
        "tall_dark": hex2rgb("#90A8A0"), "tall_light": hex2rgb("#A8C0B8"),
        "tree_dark": hex2rgb("#3E6E3E"), "tree_mid": hex2rgb("#508E50"), "tree_light": hex2rgb("#68A868"),
        "trunk": hex2rgb("#786858"), "trunk_dark": hex2rgb("#605048"),
        "rock": hex2rgb("#B8C0C8"), "rock_light": hex2rgb("#D0D8E0"), "rock_dark": hex2rgb("#98A0A8"),
        "flower_r": hex2rgb("#6090C0"), "flower_y": hex2rgb("#7898C8"), "flower_b": hex2rgb("#5080B8"),
        "flower_center": hex2rgb("#A0C0E0"),
        "fence": hex2rgb("#C0C8D0"), "fence_dark": hex2rgb("#A0A8B0"),
        "sign_wood": hex2rgb("#786858"), "sign_board": hex2rgb("#D8D0C8"),
        "roof_red": hex2rgb("#7888A0"), "roof_red_dk": hex2rgb("#607088"),
        "roof_blue": hex2rgb("#6080A8"), "roof_blue_dk": hex2rgb("#486890"),
        "roof_green": hex2rgb("#608070"), "roof_green_dk": hex2rgb("#486858"),
        "wall": hex2rgb("#D8DDE5"), "wall_dark": hex2rgb("#C0C8D0"),
        "door": hex2rgb("#907858"), "door_dark": hex2rgb("#786040"),
        "glass": hex2rgb("#A0D0E8"), "frame": hex2rgb("#788090"),
    },
    "beach": {
        "ground1": hex2rgb("#E8D098"), "ground2": hex2rgb("#DECA90"), "ground3": hex2rgb("#F0D8A0"),
        "path1": hex2rgb("#C8B078"), "path2": hex2rgb("#B8A068"), "path_edge": hex2rgb("#E8D098"),
        "water1": hex2rgb("#2898D8"), "water2": hex2rgb("#2080C0"), "water_hi": hex2rgb("#60C8F0"),
        "tall_dark": hex2rgb("#78A040"), "tall_light": hex2rgb("#90B858"),
        "tree_dark": hex2rgb("#208838"), "tree_mid": hex2rgb("#30A848"), "tree_light": hex2rgb("#48C060"),
        "trunk": hex2rgb("#907040"), "trunk_dark": hex2rgb("#785830"),
        "rock": hex2rgb("#C8B890"), "rock_light": hex2rgb("#D8CCA8"), "rock_dark": hex2rgb("#A8A078"),
        "flower_r": hex2rgb("#F07050"), "flower_y": hex2rgb("#F0B040"), "flower_b": hex2rgb("#E06878"),
        "flower_center": hex2rgb("#F8E060"),
        "fence": hex2rgb("#D0C090"), "fence_dark": hex2rgb("#B0A070"),
        "sign_wood": hex2rgb("#907040"), "sign_board": hex2rgb("#E0D8C0"),
        "roof_red": hex2rgb("#D8A040"), "roof_red_dk": hex2rgb("#C09030"),
        "roof_blue": hex2rgb("#4088B8"), "roof_blue_dk": hex2rgb("#307098"),
        "roof_green": hex2rgb("#48A060"), "roof_green_dk": hex2rgb("#388848"),
        "wall": hex2rgb("#F0E8D0"), "wall_dark": hex2rgb("#D8D0B8"),
        "door": hex2rgb("#A08040"), "door_dark": hex2rgb("#886830"),
        "glass": hex2rgb("#88C8E8"), "frame": hex2rgb("#808070"),
    },
}

# =====================================================================
# BUILD EACH TILESET
# =====================================================================
for biome_name, P in BIOMES.items():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))

    # --- ROW 0: Ground variants (0-3) + Path (4-6) + Path edges (7-10) + Path corners (11-14) + border (15) ---
    draw_grass(img, 0, 0, P["ground1"], P["ground2"])         # col 0
    draw_grass(img, 16, 0, P["ground2"], P["ground1"])         # col 1
    draw_grass(img, 32, 0, P["ground3"], P["ground2"])         # col 2
    draw_grass(img, 48, 0, P["ground1"], P["ground3"], P.get("ground2"))  # col 3 (flowers hint)
    draw_tall_grass(img, 64, 0, P["ground1"], P["tall_dark"], P["tall_light"])  # col 4
    draw_path(img, 80, 0, P["path1"], P["path2"])              # col 5
    draw_path(img, 96, 0, P["path2"], P["path1"])              # col 6 (variant)
    # Path edges
    draw_path(img, 112, 0, P["path1"], P["path_edge"], 'top')    # col 7
    draw_path(img, 128, 0, P["path1"], P["path_edge"], 'bottom') # col 8
    draw_path(img, 144, 0, P["path1"], P["path_edge"], 'left')   # col 9
    draw_path(img, 160, 0, P["path1"], P["path_edge"], 'right')  # col 10
    # Path corners (simplified: path + 2 edges)
    for ci, edges in enumerate([('top','left'),('top','right'),('bottom','left'),('bottom','right')]):
        cx = (11+ci)*16
        draw_path(img, cx, 0, P["path1"], P["path2"])
        for e in edges:
            if e == 'top': hline(img, cx, 0, 16, P["path_edge"]); hline(img, cx, 1, 16, P["path_edge"])
            if e == 'bottom': hline(img, cx, 14, 16, P["path_edge"]); hline(img, cx, 15, 16, P["path_edge"])
            if e == 'left': vline(img, cx, 0, 16, P["path_edge"]); vline(img, cx+1, 0, 16, P["path_edge"])
            if e == 'right': vline(img, cx+14, 0, 16, P["path_edge"]); vline(img, cx+15, 0, 16, P["path_edge"])
    draw_black(img, 240, 0)  # col 15: black border

    # --- ROW 1: Water (0-1) + Water edges (2-5) + Tall grass anim (6-7) + Stairs (8) + Sand/Special (9-15) ---
    draw_water(img, 0, 16, P["water1"], P["water2"], P["water_hi"], 0)   # col 0
    draw_water(img, 16, 16, P["water1"], P["water2"], P["water_hi"], 1)  # col 1 (frame 2)
    # Water edges: water-to-ground transition
    for ei, edge in enumerate(['top','bottom','left','right']):
        ex = (2+ei)*16
        draw_water(img, ex, 16, P["water1"], P["water2"], P["water_hi"])
        if edge == 'top': fill(img, ex, 16, 16, 4, P["ground1"])
        elif edge == 'bottom': fill(img, ex, 28, 16, 4, P["ground1"])
        elif edge == 'left': fill(img, ex, 16, 4, 16, P["ground1"])
        elif edge == 'right': fill(img, ex+12, 16, 4, 16, P["ground1"])
    # Tall grass animation frames
    draw_tall_grass(img, 96, 16, P["ground1"], P["tall_dark"], P["tall_light"])   # col 6
    draw_tall_grass(img, 112, 16, P["ground2"], P["tall_light"], P["tall_dark"])  # col 7 (sway)
    # Stairs
    draw_stairs(img, 128, 16, P["path1"], P["path2"])  # col 8
    # Ledge
    fill(img, 144, 16, 16, 16, P["ground1"])
    fill(img, 144, 26, 16, 4, P["rock_dark"])
    fill(img, 144, 30, 16, 2, P["rock"])
    # Sign
    draw_sign(img, 160, 16, P["sign_wood"], P["sign_board"], P["ground1"])  # col 10
    # Bridge
    fill(img, 176, 16, 16, 16, P["fence"])
    fill(img, 178, 18, 12, 12, P["path1"])
    # Dark border
    fill(img, 192, 16, 16, 16, (20, 18, 30))

    # --- ROW 2-3: Trees (0-3), Rock (4-5), Flowers (6-8), Fence (9-11), Signs (12-15) ---
    draw_tree_top(img, 0, 32, P["tree_dark"], P["tree_mid"], P["tree_light"])    # col 0 row 2: tree top-left
    draw_tree_top(img, 16, 32, P["tree_dark"], P["tree_mid"], P["tree_light"])   # col 1: tree top-right (mirror)
    draw_tree_trunk(img, 0, 48, P["trunk"], P["trunk_dark"], P["ground1"])       # col 0 row 3: trunk left
    draw_tree_trunk(img, 16, 48, P["trunk"], P["trunk_dark"], P["ground1"])      # col 1 row 3: trunk right
    # Full tree (single tile)
    draw_tree_top(img, 32, 32, P["tree_dark"], P["tree_mid"], P["tree_light"])   # col 2
    draw_tree_trunk(img, 32, 48, P["trunk"], P["trunk_dark"], P["ground1"])
    # Second tree variant (darker)
    dk = lambda c: (max(0,c[0]-20), max(0,c[1]-20), max(0,c[2]-15))
    draw_tree_top(img, 48, 32, dk(P["tree_dark"]), dk(P["tree_mid"]), P["tree_mid"])
    draw_tree_trunk(img, 48, 48, dk(P["trunk"]), dk(P["trunk_dark"]), P["ground1"])
    # Rocks
    draw_rock(img, 64, 32, P["rock"], P["rock_light"], P["rock_dark"], P["ground1"])  # col 4
    draw_rock(img, 80, 32, P["rock_dark"], P["rock"], P["rock_dark"], P["ground1"])   # col 5 (dark variant)
    # Flowers
    draw_flower(img, 96, 32, P["ground1"], P["flower_r"], P["flower_center"])   # col 6
    draw_flower(img, 112, 32, P["ground1"], P["flower_y"], P["flower_center"])  # col 7
    draw_flower(img, 128, 32, P["ground1"], P["flower_b"], P["flower_center"])  # col 8
    # Fence
    draw_fence_h(img, 144, 32, P["fence"], P["fence_dark"], P["ground1"])  # col 9
    # Fence vertical
    fill(img, 160, 32, 16, 16, P["ground1"])
    fill(img, 166, 32, 2, 16, P["fence"]); fill(img, 167, 32, 1, 16, P["fence_dark"])
    # Fence post
    fill(img, 176, 32, 16, 16, P["ground1"])
    fill(img, 182, 34, 4, 12, P["fence"])
    fill(img, 176, 37, 16, 2, P["fence"]); fill(img, 176, 43, 16, 2, P["fence"])

    # --- ROW 4-5: Buildings (roof + wall tiles) ---
    # Pokecenter roof
    draw_pokecenter_icon(img, 0, 64, P["roof_red"], P["roof_red_dk"])
    draw_building_roof(img, 16, 64, P["roof_red"], P["roof_red_dk"])
    # Pokecenter wall
    draw_wall(img, 0, 80, P["wall"], P["wall_dark"])
    draw_window(img, 16, 80, P["wall"], P["glass"], P["frame"])
    draw_door(img, 32, 80, P["wall"], P["door"], P["door_dark"])
    # Pokemart roof
    draw_mart_icon(img, 48, 64, P["roof_blue"], P["roof_blue_dk"])
    draw_building_roof(img, 64, 64, P["roof_blue"], P["roof_blue_dk"])
    # Pokemart wall
    draw_wall(img, 48, 80, P["wall"], P["wall_dark"])
    draw_window(img, 64, 80, P["wall"], P["glass"], P["frame"])
    # House roof
    draw_building_roof(img, 80, 64, P["roof_green"], P["roof_green_dk"])
    draw_building_roof(img, 96, 64, P["roof_green"], P["roof_green_dk"])
    draw_wall(img, 80, 80, P["wall"], P["wall_dark"])
    draw_window(img, 96, 80, P["wall"], P["glass"], P["frame"])

    # --- ROW 6-7: Gym tiles (8 types) ---
    gym_colors = [
        (hex2rgb("#A08858"), hex2rgb("#887040")),  # rock
        (hex2rgb("#4088C0"), hex2rgb("#306898")),  # water
        (hex2rgb("#C8A830"), hex2rgb("#A89020")),  # electric
        (hex2rgb("#50A048"), hex2rgb("#388830")),  # grass
        (hex2rgb("#904098"), hex2rgb("#703078")),  # poison
        (hex2rgb("#C05090"), hex2rgb("#983870")),  # psychic
        (hex2rgb("#C04030"), hex2rgb("#982820")),  # fire
        (hex2rgb("#B09040"), hex2rgb("#907030")),  # ground
    ]
    for i, (gc, gdk) in enumerate(gym_colors):
        col = i * 2
        draw_building_roof(img, col*16, 96, gc, gdk)
        draw_wall(img, col*16, 112, gdk, (max(0,gdk[0]-20), max(0,gdk[1]-20), max(0,gdk[2]-20)))
        draw_building_roof(img, (col+1)*16, 96, gc, gdk)
        draw_door(img, (col+1)*16, 112, gdk, P["door"], P["door_dark"])

    # --- ROW 8-9: Floor tiles (interior) ---
    floor_colors = [
        (hex2rgb("#C0B8A0"), hex2rgb("#A8A088")),  # wood
        (hex2rgb("#989898"), hex2rgb("#808080")),  # stone
        (hex2rgb("#D0C8B0"), hex2rgb("#B8B098")),  # marble
        (hex2rgb("#8888A8"), hex2rgb("#707090")),  # purple
    ]
    for i, (fc, fdk) in enumerate(floor_colors):
        fill(img, i*16, 128, 16, 16, fc)
        # Grid pattern
        hline(img, i*16, 128, 16, fdk)
        hline(img, i*16, 143, 16, fdk)
        vline(img, i*16, 128, 16, fdk)
        vline(img, i*16+15, 128, 16, fdk)

    img.save(os.path.join(OUT, f"{biome_name}.png"))
    print(f"  {biome_name}.png saved (256x256)")

print("Done: 6 clean tilesets generated")
