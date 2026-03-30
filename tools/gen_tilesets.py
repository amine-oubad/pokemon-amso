#!/usr/bin/env python3
"""Generate 6 biome tilesets (256x256 PNG, 16x16 tiles, 16 cols x 16 rows)."""
from PIL import Image, ImageDraw
import random, os

OUT = "assets/tilesets"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def noise_fill(draw, x, y, w, h, base, variance=12):
    """Fill rect with slight per-pixel noise around base color."""
    for py in range(y, y+h):
        for px in range(x, x+w):
            r = max(0, min(255, base[0] + random.randint(-variance, variance)))
            g = max(0, min(255, base[1] + random.randint(-variance, variance)))
            b = max(0, min(255, base[2] + random.randint(-variance, variance)))
            draw.point((px, py), fill=(r, g, b, 255))

def draw_tile(draw, col, row, base_color, variance=10):
    """Fill a 16x16 tile with noisy color."""
    x, y = col * 16, row * 16
    noise_fill(draw, x, y, 16, 16, base_color, variance)

def draw_border_tile(draw, col, row, inner, outer, sides):
    """Draw tile with border on specified sides."""
    x, y = col * 16, row * 16
    noise_fill(draw, x, y, 16, 16, inner, 8)
    if "top" in sides:
        noise_fill(draw, x, y, 16, 3, outer, 6)
    if "bottom" in sides:
        noise_fill(draw, x, y+13, 16, 3, outer, 6)
    if "left" in sides:
        noise_fill(draw, x, y, 3, 16, outer, 6)
    if "right" in sides:
        noise_fill(draw, x+13, y, 3, 16, outer, 6)

def draw_tree(draw, col, row, trunk, canopy_dark, canopy_light):
    """Draw a 2x2 tree (top-left origin). TL=canopy, TR=canopy, BL=trunk+canopy, BR=trunk+canopy."""
    x, y = col * 16, row * 16
    # Top canopy (2 tiles wide)
    noise_fill(draw, x, y, 32, 16, canopy_dark, 10)
    # Lighter center
    noise_fill(draw, x+6, y+2, 20, 12, canopy_light, 8)
    # Highlight dots
    for _ in range(8):
        dx, dy = random.randint(4, 27), random.randint(1, 13)
        c = (min(255, canopy_light[0]+20), min(255, canopy_light[1]+20), canopy_light[2])
        draw.point((x+dx, y+dy), fill=(*c, 255))
    # Bottom: trunk + lower canopy
    noise_fill(draw, x, y+16, 32, 16, canopy_dark, 10)
    # Trunk in center
    noise_fill(draw, x+12, y+16, 8, 16, trunk, 8)
    # Trunk detail
    darker = (max(0, trunk[0]-20), max(0, trunk[1]-20), max(0, trunk[2]-20))
    draw.line([(x+14, y+18), (x+14, y+31)], fill=(*darker, 255))

def draw_building_top(draw, col, row, roof, wall, door_col=None):
    """Draw building tiles: roof on top row, wall+window on bottom."""
    x, y = col * 16, row * 16
    # Roof
    noise_fill(draw, x, y, 32, 16, roof, 8)
    # Roof edge
    darker = (max(0, roof[0]-30), max(0, roof[1]-30), max(0, roof[2]-30))
    noise_fill(draw, x, y+13, 32, 3, darker, 5)
    # Wall
    noise_fill(draw, x, y+16, 32, 16, wall, 6)
    # Window
    draw.rectangle([x+3, y+20, x+8, y+26], fill=(180, 210, 240, 255))
    draw.rectangle([x+4, y+21, x+7, y+25], fill=(140, 190, 230, 255))
    # Door or second window
    if door_col:
        draw.rectangle([x+20, y+22, x+27, y+31], fill=(*door_col, 255))
        draw.rectangle([x+21, y+23, x+26, y+30], fill=(max(0,door_col[0]-30), max(0,door_col[1]-30), max(0,door_col[2]-30), 255))
    else:
        draw.rectangle([x+22, y+20, x+27, y+26], fill=(180, 210, 240, 255))
        draw.rectangle([x+23, y+21, x+26, y+25], fill=(140, 190, 230, 255))

def draw_water_tile(draw, col, row, water_base, frame=0):
    x, y = col * 16, row * 16
    noise_fill(draw, x, y, 16, 16, water_base, 10)
    # Wave highlights
    offset = frame * 3
    for wy in range(0, 16, 4):
        wx = (wy * 2 + offset) % 14
        lighter = (min(255, water_base[0]+40), min(255, water_base[1]+40), min(255, water_base[2]+40))
        draw.line([(x+wx, y+wy), (x+wx+3, y+wy)], fill=(*lighter, 200))

def draw_flowers(draw, col, row, ground, colors):
    x, y = col * 16, row * 16
    noise_fill(draw, x, y, 16, 16, ground, 8)
    for _ in range(5):
        fx, fy = random.randint(1, 14), random.randint(1, 14)
        c = random.choice(colors)
        draw.point((x+fx, y+fy), fill=(*c, 255))
        draw.point((x+fx+1, y+fy), fill=(*c, 255))
        draw.point((x+fx, y+fy+1), fill=(*c, 255))

def draw_rock(draw, col, row, base, highlight):
    x, y = col * 16, row * 16
    noise_fill(draw, x, y, 16, 16, (0,0,0,0) if True else base, 0)
    # Draw rock shape
    pts = [(x+3,y+14), (x+1,y+10), (x+2,y+5), (x+5,y+2), (x+10,y+1),
           (x+13,y+3), (x+14,y+7), (x+14,y+12), (x+11,y+14)]
    draw.polygon(pts, fill=(*base, 255))
    # Highlight
    draw.polygon([(x+5,y+4), (x+9,y+3), (x+11,y+5), (x+8,y+7)], fill=(*highlight, 255))

# ============================================================
# BIOME DEFINITIONS
# ============================================================

BIOMES = {
    "grass": {
        "ground": [hex2rgb("#4D8F38"), hex2rgb("#478534"), hex2rgb("#52943D"), hex2rgb("#42802E")],
        "path": [hex2rgb("#998055"), hex2rgb("#947A4D"), hex2rgb("#9E8559")],
        "water": [hex2rgb("#1F87E6"), hex2rgb("#2E94EB")],
        "tall_grass": [hex2rgb("#2E6619"), hex2rgb("#33691E")],
        "flowers": [hex2rgb("#D94D59"), hex2rgb("#E6BF33"), hex2rgb("#994DCC")],
        "tree_trunk": hex2rgb("#6B4D26"),
        "tree_canopy_dark": hex2rgb("#2B6619"),
        "tree_canopy_light": hex2rgb("#4D9933"),
        "roof": hex2rgb("#CC4444"),
        "wall": hex2rgb("#D9CCB8"),
        "door": hex2rgb("#8B6914"),
        "rock": hex2rgb("#808070"),
        "rock_hi": hex2rgb("#A0A090"),
        "fence": hex2rgb("#C8B898"),
    },
    "forest": {
        "ground": [hex2rgb("#26611A"), hex2rgb("#215914"), hex2rgb("#2B661E"), hex2rgb("#1E5212")],
        "path": [hex2rgb("#736140"), hex2rgb("#6B5938"), hex2rgb("#7A6B47")],
        "water": [hex2rgb("#1A7ACC"), hex2rgb("#2688D9")],
        "tall_grass": [hex2rgb("#1A4D0F"), hex2rgb("#1F5212")],
        "flowers": [hex2rgb("#D9D933"), hex2rgb("#CCCC26"), hex2rgb("#E6E640")],
        "tree_trunk": hex2rgb("#594026"),
        "tree_canopy_dark": hex2rgb("#1F6B14"),
        "tree_canopy_light": hex2rgb("#338C26"),
        "roof": hex2rgb("#5C8A3E"),
        "wall": hex2rgb("#8C7A5C"),
        "door": hex2rgb("#6B4D26"),
        "rock": hex2rgb("#5A5A50"),
        "rock_hi": hex2rgb("#7A7A6E"),
        "fence": hex2rgb("#7A6B47"),
    },
    "city": {
        "ground": [hex2rgb("#8C8C80"), hex2rgb("#858578"), hex2rgb("#94947E"), hex2rgb("#7E7E72")],
        "path": [hex2rgb("#A6A194"), hex2rgb("#9E998C"), hex2rgb("#ADA89C")],
        "water": [hex2rgb("#1F87E6"), hex2rgb("#2E94EB")],
        "tall_grass": [hex2rgb("#4D8F38"), hex2rgb("#478534")],
        "flowers": [hex2rgb("#E64D4D"), hex2rgb("#E6BF33"), hex2rgb("#4D8CF2")],
        "tree_trunk": hex2rgb("#6B4D26"),
        "tree_canopy_dark": hex2rgb("#336B26"),
        "tree_canopy_light": hex2rgb("#4D9933"),
        "roof": hex2rgb("#4477AA"),
        "wall": hex2rgb("#BFB8AD"),
        "door": hex2rgb("#8B6914"),
        "rock": hex2rgb("#999990"),
        "rock_hi": hex2rgb("#B0B0A8"),
        "fence": hex2rgb("#B8B0A0"),
    },
    "cave": {
        "ground": [hex2rgb("#4D4752"), hex2rgb("#47424D"), hex2rgb("#524D57"), hex2rgb("#403B47")],
        "path": [hex2rgb("#5C5766"), hex2rgb("#575261"), hex2rgb("#615C6B")],
        "water": [hex2rgb("#1A5C99"), hex2rgb("#2668A6")],
        "tall_grass": [hex2rgb("#3D4738"), hex2rgb("#384233")],
        "flowers": [],
        "tree_trunk": hex2rgb("#473D33"),
        "tree_canopy_dark": hex2rgb("#3D3833"),
        "tree_canopy_light": hex2rgb("#524D47"),
        "roof": hex2rgb("#47424D"),
        "wall": hex2rgb("#383340"),
        "door": hex2rgb("#33303D"),
        "rock": hex2rgb("#66615A"),
        "rock_hi": hex2rgb("#807A72"),
        "fence": hex2rgb("#524D47"),
    },
    "snow": {
        "ground": [hex2rgb("#E6EBF2"), hex2rgb("#E0E6ED"), hex2rgb("#EBEDF5"), hex2rgb("#DDE3EB")],
        "path": [hex2rgb("#CCD1D9"), hex2rgb("#C7CCD4"), hex2rgb("#D1D6DE")],
        "water": [hex2rgb("#B3E0F2"), hex2rgb("#A6D9EB")],
        "tall_grass": [hex2rgb("#C7D9C2"), hex2rgb("#BFD1BA")],
        "flowers": [hex2rgb("#6699CC"), hex2rgb("#7AAAD4"), hex2rgb("#5588BB")],
        "tree_trunk": hex2rgb("#7A6B5C"),
        "tree_canopy_dark": hex2rgb("#4D7A4D"),
        "tree_canopy_light": hex2rgb("#6B996B"),
        "roof": hex2rgb("#7A8899"),
        "wall": hex2rgb("#D4D9E0"),
        "door": hex2rgb("#8C7A5C"),
        "rock": hex2rgb("#B0B8C0"),
        "rock_hi": hex2rgb("#D0D8E0"),
        "fence": hex2rgb("#C0C8D0"),
    },
    "beach": {
        "ground": [hex2rgb("#EBD9A6"), hex2rgb("#E6D199"), hex2rgb("#F0DEAD"), hex2rgb("#E0CC94")],
        "path": [hex2rgb("#C7B880"), hex2rgb("#C2B37A"), hex2rgb("#CCB885")],
        "water": [hex2rgb("#1F99D9"), hex2rgb("#2EA6E0")],
        "tall_grass": [hex2rgb("#8CB84D"), hex2rgb("#80AD42")],
        "flowers": [hex2rgb("#FF8C66"), hex2rgb("#FFB84D"), hex2rgb("#FF6680")],
        "tree_trunk": hex2rgb("#8C6B3D"),
        "tree_canopy_dark": hex2rgb("#33993D"),
        "tree_canopy_light": hex2rgb("#4DB84D"),
        "roof": hex2rgb("#E6A64D"),
        "wall": hex2rgb("#F0E6CC"),
        "door": hex2rgb("#A6803D"),
        "rock": hex2rgb("#C7B88C"),
        "rock_hi": hex2rgb("#DDD0A8"),
        "fence": hex2rgb("#D9CC9E"),
    },
}

for biome_name, pal in BIOMES.items():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    random.seed(42 + hash(biome_name))

    # Row 0: 4 ground variants + 3 path variants + 2 path edges + 4 path corners + water edge top + 2 extra
    for i, c in enumerate(pal["ground"]):
        draw_tile(draw, i, 0, c, 8)
    for i, c in enumerate(pal["path"]):
        draw_tile(draw, 4 + i, 0, c, 6)
    # Path edges
    draw_border_tile(draw, 7, 0, pal["path"][0], pal["ground"][0], ["top"])
    draw_border_tile(draw, 8, 0, pal["path"][0], pal["ground"][0], ["bottom"])
    draw_border_tile(draw, 9, 0, pal["path"][0], pal["ground"][0], ["left"])
    draw_border_tile(draw, 10, 0, pal["path"][0], pal["ground"][0], ["right"])
    # Path corners
    draw_border_tile(draw, 11, 0, pal["path"][0], pal["ground"][0], ["top", "left"])
    draw_border_tile(draw, 12, 0, pal["path"][0], pal["ground"][0], ["top", "right"])
    draw_border_tile(draw, 13, 0, pal["path"][0], pal["ground"][0], ["bottom", "left"])
    draw_border_tile(draw, 14, 0, pal["path"][0], pal["ground"][0], ["bottom", "right"])
    # Water edge top
    x, y = 15*16, 0
    noise_fill(draw, x, y, 16, 8, pal["ground"][0], 8)
    noise_fill(draw, x, y+8, 16, 8, pal["water"][0], 10)

    # Row 1: 2 water frames + 2 water edges + 2 tall grass + 2 water corners + misc
    draw_water_tile(draw, 0, 1, pal["water"][0], 0)
    draw_water_tile(draw, 1, 1, pal["water"][1], 1)
    # Water edges
    x, y = 2*16, 16
    noise_fill(draw, x, y, 16, 8, pal["water"][0], 10)
    noise_fill(draw, x, y+8, 16, 8, pal["ground"][0], 8)
    x, y = 3*16, 16
    noise_fill(draw, x, y, 8, 16, pal["water"][0], 10)
    noise_fill(draw, x+8, y, 8, 16, pal["ground"][0], 8)
    # Tall grass
    for i in range(2):
        tg = pal["tall_grass"][i % len(pal["tall_grass"])]
        x, y = (4+i)*16, 16
        noise_fill(draw, x, y, 16, 16, pal["ground"][0], 8)
        for gx in range(0, 16, 3):
            gh = random.randint(5, 10)
            gc = (max(0, tg[0]+random.randint(-15,15)), max(0, tg[1]+random.randint(-15,15)), max(0, tg[2]+random.randint(-15,15)))
            draw.line([(x+gx, y+15), (x+gx+1, y+15-gh)], fill=(*gc, 255))
            draw.line([(x+gx+1, y+15), (x+gx+2, y+15-gh+2)], fill=(*gc, 230))
    # Water corners
    for i in range(4):
        cx, cy = (6+i)*16, 16
        noise_fill(draw, cx, cy, 16, 16, pal["water"][0], 10)
        sides = [["top","left"], ["top","right"], ["bottom","left"], ["bottom","right"]][i]
        sx = cx if "left" in sides else cx+8
        sy = cy if "top" in sides else cy+8
        noise_fill(draw, sx, sy, 8, 8, pal["ground"][0], 8)
    # Stairs
    x, y = 10*16, 16
    for sy in range(0, 16, 4):
        shade = max(0, pal["path"][0][0] - sy*3)
        c = (shade, max(0, pal["path"][0][1] - sy*3), max(0, pal["path"][0][2] - sy*3))
        noise_fill(draw, x, y+sy, 16, 4, c, 5)
    # Ledge
    x, y = 11*16, 16
    noise_fill(draw, x, y, 16, 12, pal["ground"][0], 8)
    darker = (max(0,pal["ground"][0][0]-40), max(0,pal["ground"][0][1]-40), max(0,pal["ground"][0][2]-40))
    noise_fill(draw, x, y+12, 16, 4, darker, 6)
    # Deep water
    dw = (max(0,pal["water"][0][0]-30), max(0,pal["water"][0][1]-30), max(0,pal["water"][0][2]-20))
    draw_water_tile(draw, 12, 1, dw, 0)
    # Bridge
    x, y = 13*16, 16
    noise_fill(draw, x, y, 16, 16, pal["fence"], 6)
    noise_fill(draw, x+2, y+2, 12, 12, pal["path"][0], 8)
    # Sign
    x, y = 14*16, 16
    noise_fill(draw, x, y, 16, 16, pal["ground"][0], 8)
    draw.rectangle([x+3, y+3, x+12, y+12], fill=(*pal["fence"], 255))
    draw.rectangle([x+4, y+4, x+11, y+8], fill=(220, 210, 190, 255))
    draw.line([(x+7, y+12), (x+7, y+15)], fill=(*pal["tree_trunk"], 255))
    draw.line([(x+8, y+12), (x+8, y+15)], fill=(*pal["tree_trunk"], 255))
    # Black border
    draw_tile(draw, 15, 1, (8, 8, 16), 2)

    # Row 2-3: Tree (2x2) + Rocks + Flowers + Fence
    draw_tree(draw, 0, 2, pal["tree_trunk"], pal["tree_canopy_dark"], pal["tree_canopy_light"])
    # Second tree variant
    draw_tree(draw, 2, 2, pal["tree_trunk"],
              (max(0,pal["tree_canopy_dark"][0]-10), max(0,pal["tree_canopy_dark"][1]-10), max(0,pal["tree_canopy_dark"][2]-10)),
              (min(255,pal["tree_canopy_light"][0]+10), min(255,pal["tree_canopy_light"][1]+10), pal["tree_canopy_light"][2]))
    # Rocks
    draw_rock(draw, 4, 2, pal["rock"], pal["rock_hi"])
    draw_rock(draw, 5, 2, (max(0,pal["rock"][0]-15), max(0,pal["rock"][1]-15), max(0,pal["rock"][2]-15)), pal["rock"])
    # Small rock
    x, y = 6*16, 2*16
    noise_fill(draw, x, y, 16, 16, (0,0,0), 0)
    img.putpixel((x,y), (0,0,0,0))  # transparent base
    for py in range(y, y+16):
        for px in range(x, x+16):
            img.putpixel((px, py), (0, 0, 0, 0))
    pts = [(x+5,y+13), (x+3,y+9), (x+5,y+6), (x+8,y+5), (x+11,y+6), (x+12,y+9), (x+10,y+13)]
    draw.polygon(pts, fill=(*pal["rock"], 255))
    # Flowers
    if pal["flowers"]:
        draw_flowers(draw, 7, 2, pal["ground"][0], pal["flowers"])
        draw_flowers(draw, 8, 2, pal["ground"][0], [pal["flowers"][0]])
        draw_flowers(draw, 9, 2, pal["ground"][0], [pal["flowers"][1]] if len(pal["flowers"])>1 else pal["flowers"])
    # Fence
    x, y = 10*16, 2*16
    noise_fill(draw, x, y, 16, 16, pal["ground"][0], 8)
    draw.rectangle([x, y+4, x+15, y+6], fill=(*pal["fence"], 255))
    draw.rectangle([x, y+10, x+15, y+12], fill=(*pal["fence"], 255))
    # Fence post
    x, y = 11*16, 2*16
    noise_fill(draw, x, y, 16, 16, pal["ground"][0], 8)
    draw.rectangle([x+6, y+2, x+9, y+14], fill=(*pal["fence"], 255))
    draw.rectangle([x, y+4, x+15, y+6], fill=(*pal["fence"], 255))
    draw.rectangle([x, y+10, x+15, y+12], fill=(*pal["fence"], 255))
    # Fence vertical
    x, y = 12*16, 2*16
    noise_fill(draw, x, y, 16, 16, pal["ground"][0], 8)
    draw.rectangle([x+6, y, x+9, y+15], fill=(*pal["fence"], 255))

    # Row 3 continuation: more decorative tiles
    # Crate
    x, y = 4*16, 3*16
    draw.rectangle([x+1, y+1, x+14, y+14], fill=(*pal["fence"], 255))
    darker_f = (max(0,pal["fence"][0]-30), max(0,pal["fence"][1]-30), max(0,pal["fence"][2]-30))
    draw.rectangle([x+2, y+2, x+13, y+13], fill=(*darker_f, 255))
    draw.line([(x+2, y+2), (x+13, y+13)], fill=(*pal["fence"], 200))
    draw.line([(x+13, y+2), (x+2, y+13)], fill=(*pal["fence"], 200))

    # Row 4-5: Buildings
    draw_building_top(draw, 0, 4, pal["roof"], pal["wall"], pal["door"])
    # Second building (different roof)
    alt_roof = (min(255,pal["roof"][0]+40), min(255,pal["roof"][1]+20), pal["roof"][2])
    draw_building_top(draw, 2, 4, alt_roof, pal["wall"])
    # Pokecenter-style
    x, y = 4*16, 4*16
    noise_fill(draw, x, y, 32, 16, (200, 60, 60), 8)  # Red roof
    noise_fill(draw, x, y+16, 32, 16, (240, 235, 230), 5)  # White wall
    # Red cross
    draw.rectangle([x+13, y+19, x+18, y+28], fill=(220, 50, 50, 255))
    draw.rectangle([x+10, y+22, x+21, y+25], fill=(220, 50, 50, 255))
    # Door
    draw.rectangle([x+5, y+24, x+10, y+31], fill=(100, 80, 60, 255))
    # Pokemart-style
    x, y = 6*16, 4*16
    noise_fill(draw, x, y, 32, 16, (60, 100, 180), 8)  # Blue roof
    noise_fill(draw, x, y+16, 32, 16, (235, 235, 225), 5)  # Wall
    # P sign
    draw.rectangle([x+12, y+19, x+19, y+28], fill=(60, 100, 180, 255))
    draw.text((x+13, y+19), "P", fill=(255, 255, 255, 255)) if False else None
    # Door
    draw.rectangle([x+5, y+24, x+10, y+31], fill=(100, 80, 60, 255))

    # Gym roof/wall tiles (rows 6-7)
    gym_colors = [
        ("rock", hex2rgb("#8C7A5C"), hex2rgb("#736140")),
        ("water", hex2rgb("#4488CC"), hex2rgb("#336699")),
        ("electric", hex2rgb("#CCAA33"), hex2rgb("#AA8826")),
        ("grass", hex2rgb("#55AA44"), hex2rgb("#448833")),
        ("poison", hex2rgb("#9944AA"), hex2rgb("#773388")),
        ("psychic", hex2rgb("#CC5599"), hex2rgb("#AA3377")),
        ("fire", hex2rgb("#CC4422"), hex2rgb("#AA3318")),
        ("ground", hex2rgb("#AA8844"), hex2rgb("#886633")),
    ]
    for i, (gtype, roof_c, wall_c) in enumerate(gym_colors):
        col = (i % 8) * 2
        row_base = 6 + (i // 8) * 2
        x, y = col * 16, row_base * 16
        # Roof
        noise_fill(draw, x, y, 32, 16, roof_c, 8)
        # Gym symbol
        draw.rectangle([x+11, y+3, x+20, y+12], fill=(255, 255, 255, 180))
        # Wall
        noise_fill(draw, x, y+16, 32, 16, wall_c, 6)
        # Gym door
        draw.rectangle([x+12, y+22, x+19, y+31], fill=(60, 50, 40, 255))

    # Rows 8-9: Floor tiles
    floor_colors = [
        hex2rgb("#B8AFA3"),  # wooden
        hex2rgb("#999999"),  # stone
        hex2rgb("#C8C0B0"),  # marble
        hex2rgb("#8888AA"),  # purple
    ]
    for i, fc in enumerate(floor_colors):
        draw_tile(draw, i, 8, fc, 5)
        # Bordered version
        draw_border_tile(draw, i+4, 8, fc, (max(0,fc[0]-30), max(0,fc[1]-30), max(0,fc[2]-30)), ["top","bottom","left","right"])

    # Save
    img.save(os.path.join(OUT, f"{biome_name}.png"))
    print(f"  {biome_name}.png saved (256x256)")

print("Done: 6 tilesets generated")
