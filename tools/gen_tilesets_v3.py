#!/usr/bin/env python3
"""Generate 6 biome tilesets (256x256, 16x16 tiles, 16 cols x 16 rows).
Clean pixel art — NO noise, NO random. Every pixel placed intentionally.
Style reference: Pokemon FireRed/Emerald/Unbound overworld tiles.
"""
from PIL import Image, ImageDraw
import os

OUT = "assets/tilesets"
os.makedirs(OUT, exist_ok=True)

def h(hex_str):
    """Hex string to RGB tuple."""
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def darker(c, n=30):
    return (max(0,c[0]-n), max(0,c[1]-n), max(0,c[2]-n))

def lighter(c, n=30):
    return (min(255,c[0]+n), min(255,c[1]+n), min(255,c[2]+n))

def mix(c1, c2, t=0.5):
    return tuple(int(c1[i]*(1-t)+c2[i]*t) for i in range(3))

class TileCanvas:
    """Helper to draw into a 256x256 tileset image."""
    def __init__(self):
        self.img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))

    def px(self, x, y, c, a=255):
        if 0 <= x < 256 and 0 <= y < 256:
            if len(c) == 4:
                self.img.putpixel((x, y), c)
            else:
                self.img.putpixel((x, y), (*c, a))

    def rect(self, x, y, w, h_val, c):
        for py in range(y, y + h_val):
            for px_val in range(x, x + w):
                self.px(px_val, py, c)

    def hline(self, x, y, w, c):
        for i in range(w): self.px(x + i, y, c)

    def vline(self, x, y, h_val, c):
        for i in range(h_val): self.px(x, y + i, c)

    def tile_origin(self, col, row):
        return col * 16, row * 16

    def fill_tile(self, col, row, c):
        tx, ty = self.tile_origin(col, row)
        self.rect(tx, ty, 16, 16, c)

    def save(self, name):
        self.img.save(os.path.join(OUT, name))
        print(f"  {name} saved")

# =====================================================================
#  TILE DRAWING PRIMITIVES
# =====================================================================

def draw_flat_ground(tc, col, row, c1, c2=None):
    """Flat ground with subtle 2-color checkerboard pattern."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, c1)
    if c2:
        for py in range(0, 16, 2):
            for px in range(0, 16, 2):
                off = (py // 2) % 2
                tc.px(tx + px + off, ty + py, c2)

def draw_path_tile(tc, col, row, c1, c2):
    """Clean dirt/stone path."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, c1)
    # Subtle horizontal grain
    for py in range(0, 16, 3):
        tc.hline(tx + 1, ty + py, 14, c2)

def draw_path_edge(tc, col, row, path_c, ground_c, side):
    """Path tile with grass edge on one side."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, path_c)
    if side == "top":
        tc.rect(tx, ty, 16, 3, ground_c)
        tc.hline(tx, ty + 3, 16, mix(path_c, ground_c))
    elif side == "bottom":
        tc.rect(tx, ty + 13, 16, 3, ground_c)
        tc.hline(tx, ty + 12, 16, mix(path_c, ground_c))
    elif side == "left":
        tc.rect(tx, ty, 3, 16, ground_c)
        tc.vline(tx + 3, ty, 16, mix(path_c, ground_c))
    elif side == "right":
        tc.rect(tx + 13, ty, 3, 16, ground_c)
        tc.vline(tx + 12, ty, 16, mix(path_c, ground_c))

def draw_path_corner(tc, col, row, path_c, ground_c, corner):
    """Path tile with grass corner."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, path_c)
    if "top" in corner:
        tc.rect(tx, ty, 16, 3, ground_c)
    if "bottom" in corner:
        tc.rect(tx, ty + 13, 16, 3, ground_c)
    if "left" in corner:
        tc.rect(tx, ty, 3, 16, ground_c)
    if "right" in corner:
        tc.rect(tx + 13, ty, 3, 16, ground_c)

def draw_water_tile(tc, col, row, c1, c2, highlight, frame=0):
    """Water with checkerboard pattern and highlight streaks."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, c1)
    # Checkerboard
    for py in range(0, 16, 2):
        for px in range(0, 16, 2):
            off = ((py // 2) + frame) % 2
            tc.px(tx + px + off, ty + py, c2)
    # Highlight streaks (horizontal, fixed positions)
    hy = (4 + frame * 6) % 14
    tc.hline(tx + 3, ty + hy, 5, highlight)
    tc.hline(tx + 10, ty + (hy + 8) % 14, 4, highlight)

def draw_water_edge(tc, col, row, water_c, ground_c, side):
    """Water tile with ground edge."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, water_c)
    edge_c = mix(water_c, ground_c, 0.4)
    if side == "top":
        tc.rect(tx, ty, 16, 4, ground_c)
        tc.hline(tx, ty + 4, 16, edge_c)
        # Wavy edge
        for px in range(0, 16, 4):
            tc.px(tx + px + 1, ty + 3, edge_c)
    elif side == "bottom":
        tc.rect(tx, ty + 12, 16, 4, ground_c)
        tc.hline(tx, ty + 11, 16, edge_c)
    elif side == "left":
        tc.rect(tx, ty, 4, 16, ground_c)
        tc.vline(tx + 4, ty, 16, edge_c)
    elif side == "right":
        tc.rect(tx + 12, ty, 4, 16, ground_c)
        tc.vline(tx + 11, ty, 16, edge_c)

def draw_tall_grass(tc, col, row, ground_c, grass_c, grass_light):
    """Tall grass with V-shaped blades."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    # 4 grass blade clusters
    positions = [(2, 14), (6, 13), (10, 14), (14, 13)]
    for bx, by in positions:
        # V-shaped blade
        for i in range(6):
            tc.px(tx + bx - i // 2, ty + by - i, grass_c)
            tc.px(tx + bx + i // 2, ty + by - i, grass_c)
        # Light tip
        tc.px(tx + bx - 2, ty + by - 5, grass_light)
        tc.px(tx + bx + 2, ty + by - 5, grass_light)
    # Fill base
    tc.rect(tx, ty + 12, 16, 4, mix(ground_c, grass_c, 0.3))

def draw_tree_canopy_tl(tc, col, row, dark, mid, light, outline):
    """Top-left quadrant of a 2x2 tree. Round canopy."""
    tx, ty = tc.tile_origin(col, row)
    # Round canopy shape (right half of circle)
    for py in range(16):
        for px in range(16):
            # Distance from center (center is at x=16, y=12 of the 2x2 tree = right-bottom of this tile)
            dx = px - 15
            dy = py - 11
            dist = (dx * dx / 225 + dy * dy / 144)  # normalized ellipse
            if dist < 0.6:
                tc.px(tx + px, ty + py, light)
            elif dist < 0.85:
                tc.px(tx + px, ty + py, mid)
            elif dist < 1.0:
                tc.px(tx + px, ty + py, dark)
            elif dist < 1.12:
                tc.px(tx + px, ty + py, outline)

def draw_tree_canopy_tr(tc, col, row, dark, mid, light, outline):
    """Top-right quadrant of a 2x2 tree."""
    tx, ty = tc.tile_origin(col, row)
    for py in range(16):
        for px in range(16):
            dx = px - 0
            dy = py - 11
            dist = (dx * dx / 225 + dy * dy / 144)
            if dist < 0.6:
                tc.px(tx + px, ty + py, light)
            elif dist < 0.85:
                tc.px(tx + px, ty + py, mid)
            elif dist < 1.0:
                tc.px(tx + px, ty + py, dark)
            elif dist < 1.12:
                tc.px(tx + px, ty + py, outline)

def draw_tree_trunk_bl(tc, col, row, dark, mid, light, outline, trunk_c, trunk_dark, ground_c):
    """Bottom-left of tree: lower canopy + trunk."""
    tx, ty = tc.tile_origin(col, row)
    # Ground base
    tc.rect(tx, ty, 16, 16, ground_c)
    # Lower canopy (upper portion)
    for py in range(10):
        for px in range(16):
            dx = px - 15
            dy = py + 5  # offset from canopy center
            dist = (dx * dx / 225 + (dy * dy) / 144)
            if dist < 0.85:
                tc.px(tx + px, ty + py, mid)
            elif dist < 1.0:
                tc.px(tx + px, ty + py, dark)
            elif dist < 1.12:
                tc.px(tx + px, ty + py, outline)
    # Trunk (right side of this tile, connects to BR)
    tc.rect(tx + 13, ty + 6, 3, 10, trunk_c)
    tc.vline(tx + 12, ty + 6, 10, trunk_dark)

def draw_tree_trunk_br(tc, col, row, dark, mid, light, outline, trunk_c, trunk_dark, ground_c):
    """Bottom-right of tree: lower canopy + trunk."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    # Lower canopy
    for py in range(10):
        for px in range(16):
            dx = px - 0
            dy = py + 5
            dist = (dx * dx / 225 + (dy * dy) / 144)
            if dist < 0.85:
                tc.px(tx + px, ty + py, mid)
            elif dist < 1.0:
                tc.px(tx + px, ty + py, dark)
            elif dist < 1.12:
                tc.px(tx + px, ty + py, outline)
    # Trunk (left side)
    tc.rect(tx, ty + 6, 3, 10, trunk_c)
    tc.vline(tx + 3, ty + 6, 10, trunk_dark)

def draw_rock(tc, col, row, base, highlight, shadow, outline):
    """Rock with rounded shape."""
    tx, ty = tc.tile_origin(col, row)
    # Elliptical rock shape
    for py in range(16):
        for px in range(16):
            dx = px - 7.5
            dy = py - 8.5
            dist = dx*dx/49 + dy*dy/36
            if dist < 0.5:
                tc.px(tx+px, ty+py, highlight)
            elif dist < 0.8:
                tc.px(tx+px, ty+py, base)
            elif dist < 1.0:
                tc.px(tx+px, ty+py, shadow)
            elif dist < 1.15:
                tc.px(tx+px, ty+py, outline)

def draw_flowers(tc, col, row, ground_c, flower_c, stem_c=None):
    """Flowers on ground."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    positions = [(3,4),(8,3),(13,5),(5,9),(10,10),(2,13),(8,14),(14,12)]
    for fx, fy in positions:
        tc.px(tx+fx, ty+fy, flower_c)
        tc.px(tx+fx+1, ty+fy, flower_c)
        tc.px(tx+fx, ty+fy+1, flower_c)
        if stem_c:
            tc.px(tx+fx, ty+fy+2, stem_c)

def draw_fence_h(tc, col, row, ground_c, fence_c, fence_dark):
    """Horizontal fence."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    tc.hline(tx, ty+5, 16, fence_c)
    tc.hline(tx, ty+6, 16, fence_dark)
    tc.hline(tx, ty+10, 16, fence_c)
    tc.hline(tx, ty+11, 16, fence_dark)

def draw_fence_v(tc, col, row, ground_c, fence_c, fence_dark):
    """Vertical fence."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    tc.vline(tx+7, ty, 16, fence_c)
    tc.vline(tx+8, ty, 16, fence_dark)

def draw_fence_post(tc, col, row, ground_c, fence_c, fence_dark):
    """Fence post (intersection)."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    tc.hline(tx, ty+5, 16, fence_c)
    tc.hline(tx, ty+6, 16, fence_dark)
    tc.hline(tx, ty+10, 16, fence_c)
    tc.hline(tx, ty+11, 16, fence_dark)
    tc.rect(tx+6, ty+3, 4, 11, fence_c)
    tc.vline(tx+10, ty+3, 11, fence_dark)

def draw_sign(tc, col, row, ground_c, wood_c, wood_dark, board_c):
    """Signpost."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    # Post
    tc.rect(tx+7, ty+8, 2, 8, wood_dark)
    # Board
    tc.rect(tx+3, ty+2, 10, 7, wood_c)
    tc.rect(tx+4, ty+3, 8, 5, board_c)
    # Outline
    tc.hline(tx+3, ty+1, 10, wood_dark)
    tc.hline(tx+3, ty+9, 10, wood_dark)

def draw_stairs(tc, col, row, c1, c2, c3):
    """Stairs tile."""
    tx, ty = tc.tile_origin(col, row)
    for i in range(4):
        y = ty + i * 4
        colors = [c1, c2, c3, c2]
        tc.rect(tx, y, 16, 4, colors[i])
        tc.hline(tx, y, 16, darker(colors[i], 15))

def draw_building_roof(tc, col, row, w_tiles, roof_c, roof_edge):
    """Building roof (spans w_tiles). Triangular/pointed shape."""
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, roof_c)
        # Bottom edge shadow
        tc.hline(tx, ty + 14, 16, roof_edge)
        tc.hline(tx, ty + 15, 16, darker(roof_edge))
        # Top: peaked roof effect
        if t == 0:
            # Left edge slope
            for py in range(12):
                tc.px(tx + py // 2, ty + py, roof_edge)
        elif t == w_tiles - 1:
            # Right edge slope
            for py in range(12):
                tc.px(tx + 15 - py // 2, ty + py, roof_edge)

def draw_building_wall(tc, col, row, w_tiles, wall_c, shadow_c, window_c=None, door_col=None, door_tile=None):
    """Building wall (spans w_tiles). Can include door and windows."""
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, wall_c)
        # Top shadow (under roof)
        tc.hline(tx, ty, 16, shadow_c)
        tc.hline(tx, ty + 1, 16, shadow_c)

        if door_tile is not None and t == door_tile:
            # Door
            dc = door_col or h("#6B4D26")
            tc.rect(tx + 4, ty + 4, 8, 12, dc)
            tc.rect(tx + 5, ty + 5, 6, 10, darker(dc))
            # Doorknob
            tc.px(tx + 9, ty + 10, lighter(dc, 40))
        elif window_c and t != door_tile:
            # Window
            tc.rect(tx + 4, ty + 4, 8, 6, window_c)
            tc.rect(tx + 5, ty + 5, 6, 4, lighter(window_c, 20))
            # Window frame cross
            tc.hline(tx + 4, ty + 7, 8, darker(window_c, 20))
            tc.vline(tx + 8, ty + 4, 6, darker(window_c, 20))

def draw_pokecenter_roof(tc, col, row, w_tiles):
    """PokeCenter red roof with white cross."""
    roof_c = h("#CC3333")
    roof_edge = h("#992222")
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, roof_c)
        tc.hline(tx, ty + 14, 16, roof_edge)
        tc.hline(tx, ty + 15, 16, darker(roof_edge))
    # White cross in center
    cx = (col + w_tiles // 2) * 16
    cy = row * 16
    # Vertical bar
    tc.rect(cx + 6, cy + 3, 4, 10, (255, 255, 255))
    # Horizontal bar
    tc.rect(cx + 3, cy + 6, 10, 4, (255, 255, 255))

def draw_pokecenter_wall(tc, col, row, w_tiles):
    """PokeCenter white wall with door."""
    wall_c = (240, 238, 232)
    shadow_c = (210, 205, 198)
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, wall_c)
        tc.hline(tx, ty, 16, shadow_c)
        tc.hline(tx, ty + 1, 16, shadow_c)
    # Door in center
    dt = w_tiles // 2
    tx = (col + dt) * 16
    ty = row * 16
    tc.rect(tx + 2, ty + 3, 12, 13, h("#884422"))
    tc.rect(tx + 3, ty + 4, 10, 11, h("#773311"))
    # Glass panels
    tc.rect(tx + 4, ty + 5, 4, 6, (180, 210, 230))
    tc.rect(tx + 9, ty + 5, 4, 6, (180, 210, 230))

def draw_pokemart_roof(tc, col, row, w_tiles):
    """PokeMart blue roof with white P."""
    roof_c = h("#3366AA")
    roof_edge = h("#224488")
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, roof_c)
        tc.hline(tx, ty + 14, 16, roof_edge)
        tc.hline(tx, ty + 15, 16, darker(roof_edge))
    # "P" letter in center
    cx = (col + w_tiles // 2) * 16
    cy = row * 16
    # P shape
    tc.rect(cx + 5, cy + 3, 2, 10, (255, 255, 255))  # vertical bar
    tc.rect(cx + 7, cy + 3, 4, 2, (255, 255, 255))    # top horizontal
    tc.rect(cx + 10, cy + 4, 2, 3, (255, 255, 255))   # right side
    tc.rect(cx + 7, cy + 7, 4, 2, (255, 255, 255))    # middle horizontal

def draw_pokemart_wall(tc, col, row, w_tiles):
    """PokeMart light wall with door."""
    wall_c = (232, 232, 222)
    shadow_c = (205, 205, 195)
    for t in range(w_tiles):
        tx, ty = tc.tile_origin(col + t, row)
        tc.rect(tx, ty, 16, 16, wall_c)
        tc.hline(tx, ty, 16, shadow_c)
        tc.hline(tx, ty + 1, 16, shadow_c)
    dt = w_tiles // 2
    tx = (col + dt) * 16
    ty = row * 16
    tc.rect(tx + 2, ty + 3, 12, 13, h("#884422"))
    tc.rect(tx + 3, ty + 4, 10, 11, h("#773311"))
    tc.rect(tx + 4, ty + 5, 4, 6, (180, 210, 230))
    tc.rect(tx + 9, ty + 5, 4, 6, (180, 210, 230))

def draw_floor_tile(tc, col, row, c1, c2=None):
    """Interior floor tile."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, c1)
    if c2:
        # Grid pattern
        tc.hline(tx, ty, 16, c2)
        tc.hline(tx, ty + 15, 16, c2)
        tc.vline(tx, ty, 16, c2)
        tc.vline(tx + 15, ty, 16, c2)

def draw_door_tile(tc, col, row, door_c):
    """Standalone door tile."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, door_c)
    tc.rect(tx + 1, ty + 1, 14, 14, darker(door_c))
    tc.rect(tx + 2, ty + 2, 5, 10, lighter(door_c, 15))
    tc.rect(tx + 9, ty + 2, 5, 10, lighter(door_c, 15))
    tc.px(tx + 12, ty + 8, lighter(door_c, 40))

def draw_window_tile(tc, col, row, frame_c, glass_c):
    """Standalone window tile."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, frame_c)
    tc.rect(tx + 2, ty + 2, 12, 12, glass_c)
    tc.rect(tx + 3, ty + 3, 10, 10, lighter(glass_c, 15))
    # Cross
    tc.hline(tx + 2, ty + 8, 12, frame_c)
    tc.vline(tx + 8, ty + 2, 12, frame_c)

def draw_black_tile(tc, col, row):
    """Solid black tile for borders."""
    tc.fill_tile(col, row, (8, 8, 16))

def draw_bush(tc, col, row, ground_c, bush_c, bush_light):
    """Small bush."""
    tx, ty = tc.tile_origin(col, row)
    tc.rect(tx, ty, 16, 16, ground_c)
    # Round bush shape
    for py in range(3, 14):
        for px in range(2, 14):
            dx = px - 8
            dy = py - 9
            dist = dx*dx/36 + dy*dy/25
            if dist < 0.5:
                tc.px(tx+px, ty+py, bush_light)
            elif dist < 0.85:
                tc.px(tx+px, ty+py, bush_c)
            elif dist < 1.0:
                tc.px(tx+px, ty+py, darker(bush_c, 20))

# =====================================================================
#  BIOME GENERATION
# =====================================================================

def generate_biome(name, pal):
    """Generate a complete 256x256 tileset for a biome."""
    tc = TileCanvas()
    p = pal

    # === ROW 0: Ground + Path + Edges + Corners ===
    draw_flat_ground(tc, 0, 0, p['ground1'], p['ground2'])
    draw_flat_ground(tc, 1, 0, p['ground2'], p['ground1'])
    draw_flat_ground(tc, 2, 0, p['ground1'], p.get('ground3', p['ground2']))
    draw_flat_ground(tc, 3, 0, p['ground2'], p.get('ground3', p['ground1']))
    draw_path_tile(tc, 4, 0, p['path1'], p['path2'])
    draw_path_tile(tc, 5, 0, p['path2'], p['path1'])
    draw_path_tile(tc, 6, 0, p['path1'], p.get('path3', p['path2']))
    draw_path_edge(tc, 7, 0, p['path1'], p['ground1'], "top")
    draw_path_edge(tc, 8, 0, p['path1'], p['ground1'], "bottom")
    draw_path_edge(tc, 9, 0, p['path1'], p['ground1'], "left")
    draw_path_edge(tc, 10, 0, p['path1'], p['ground1'], "right")
    draw_path_corner(tc, 11, 0, p['path1'], p['ground1'], "top-left")
    draw_path_corner(tc, 12, 0, p['path1'], p['ground1'], "top-right")
    draw_path_corner(tc, 13, 0, p['path1'], p['ground1'], "bottom-left")
    draw_path_corner(tc, 14, 0, p['path1'], p['ground1'], "bottom-right")
    # Water edge top
    tx, ty = tc.tile_origin(15, 0)
    tc.rect(tx, ty, 16, 8, p['ground1'])
    tc.rect(tx, ty + 8, 16, 8, p['water1'])
    tc.hline(tx, ty + 8, 16, mix(p['water1'], p['ground1'], 0.5))

    # === ROW 1: Water + Tall Grass + Special ===
    draw_water_tile(tc, 0, 1, p['water1'], p['water2'], p.get('water_hi', lighter(p['water1'], 40)), 0)
    draw_water_tile(tc, 1, 1, p['water1'], p['water2'], p.get('water_hi', lighter(p['water1'], 40)), 1)
    draw_water_edge(tc, 2, 1, p['water1'], p['ground1'], "top")
    draw_water_edge(tc, 3, 1, p['water1'], p['ground1'], "bottom")
    draw_water_edge(tc, 4, 1, p['water1'], p['ground1'], "left")
    draw_water_edge(tc, 5, 1, p['water1'], p['ground1'], "right")
    draw_tall_grass(tc, 6, 1, p['ground1'], p['tall_grass'], p.get('tall_grass_light', lighter(p['tall_grass'], 20)))
    draw_tall_grass(tc, 7, 1, p['ground2'], p['tall_grass'], p.get('tall_grass_light', lighter(p['tall_grass'], 20)))
    draw_stairs(tc, 8, 1, p['path1'], p['path2'], darker(p['path1']))
    # Ledge
    tx, ty = tc.tile_origin(9, 1)
    tc.rect(tx, ty, 16, 12, p['ground1'])
    tc.rect(tx, ty+12, 16, 4, darker(p['ground1'], 35))
    tc.hline(tx, ty+11, 16, darker(p['ground1'], 20))
    # Bridge
    tx, ty = tc.tile_origin(10, 1)
    tc.rect(tx, ty, 16, 16, p['water1'])
    tc.rect(tx+2, ty, 12, 16, p.get('fence_c', p['path1']))
    tc.rect(tx+3, ty+1, 10, 14, p['path1'])
    # Sign
    draw_sign(tc, 11, 1, p['ground1'], p.get('fence_c', p['path2']), darker(p.get('fence_c', p['path2'])), (230, 220, 200))
    # Deep water
    dw = darker(p['water1'], 30)
    draw_water_tile(tc, 12, 1, dw, darker(p['water2'], 30), p.get('water_hi', lighter(p['water1'], 20)), 0)
    # Black border
    draw_black_tile(tc, 13, 1)
    draw_black_tile(tc, 14, 1)
    draw_black_tile(tc, 15, 1)

    # === ROW 2-3: Trees (2x2) ===
    outline = p.get('tree_outline', darker(p['canopy_dark'], 20))
    draw_tree_canopy_tl(tc, 0, 2, p['canopy_dark'], p['canopy_mid'], p['canopy_light'], outline)
    draw_tree_canopy_tr(tc, 1, 2, p['canopy_dark'], p['canopy_mid'], p['canopy_light'], outline)
    draw_tree_trunk_bl(tc, 0, 3, p['canopy_dark'], p['canopy_mid'], p['canopy_light'], outline,
                       p['trunk'], darker(p['trunk']), p['ground1'])
    draw_tree_trunk_br(tc, 1, 3, p['canopy_dark'], p['canopy_mid'], p['canopy_light'], outline,
                       p['trunk'], darker(p['trunk']), p['ground1'])
    # Tree variant B
    c2_dark = darker(p['canopy_dark'], 10)
    c2_mid = darker(p['canopy_mid'], 10)
    c2_light = mix(p['canopy_light'], p['canopy_mid'])
    draw_tree_canopy_tl(tc, 2, 2, c2_dark, c2_mid, c2_light, outline)
    draw_tree_canopy_tr(tc, 3, 2, c2_dark, c2_mid, c2_light, outline)
    draw_tree_trunk_bl(tc, 2, 3, c2_dark, c2_mid, c2_light, outline,
                       p['trunk'], darker(p['trunk']), p['ground1'])
    draw_tree_trunk_br(tc, 3, 3, c2_dark, c2_mid, c2_light, outline,
                       p['trunk'], darker(p['trunk']), p['ground1'])

    # Rocks
    draw_rock(tc, 4, 2, p.get('rock', (128,128,120)), p.get('rock_hi', (160,160,150)),
              darker(p.get('rock', (128,128,120))), darker(p.get('rock', (128,128,120)), 40))
    draw_rock(tc, 5, 2, darker(p.get('rock', (128,128,120)), 15),
              p.get('rock', (128,128,120)),
              darker(p.get('rock', (128,128,120)), 30),
              darker(p.get('rock', (128,128,120)), 50))

    # Flowers
    if p.get('flower1'):
        draw_flowers(tc, 6, 2, p['ground1'], p['flower1'], darker(p.get('tall_grass', p['ground1']), 10))
    if p.get('flower2'):
        draw_flowers(tc, 7, 2, p['ground1'], p['flower2'], darker(p.get('tall_grass', p['ground1']), 10))
    if p.get('flower3'):
        draw_flowers(tc, 8, 2, p['ground1'], p['flower3'], darker(p.get('tall_grass', p['ground1']), 10))

    # Fences
    fc = p.get('fence_c', p['path2'])
    fd = darker(fc)
    draw_fence_h(tc, 9, 2, p['ground1'], fc, fd)
    draw_fence_v(tc, 10, 2, p['ground1'], fc, fd)
    draw_fence_post(tc, 11, 2, p['ground1'], fc, fd)

    # Bush
    draw_bush(tc, 12, 2, p['ground1'], p.get('bush', p['canopy_mid']),
              p.get('bush_light', p['canopy_light']))

    # === ROW 4-5: House (4 wide × 2 tall) ===
    house_roof = p.get('house_roof', h("#CC4444"))
    house_wall = p.get('house_wall', (215, 208, 195))
    draw_building_roof(tc, 0, 4, 4, house_roof, darker(house_roof))
    draw_building_wall(tc, 0, 5, 4, house_wall, darker(house_wall, 20),
                       window_c=(170, 200, 230), door_col=h("#7A5A2A"), door_tile=1)

    # === ROW 6-7: PokeCenter (4 wide × 2 tall) + PokeMart (4 wide × 2 tall) ===
    draw_pokecenter_roof(tc, 0, 6, 4)
    draw_pokecenter_wall(tc, 0, 7, 4)
    draw_pokemart_roof(tc, 4, 6, 4)
    draw_pokemart_wall(tc, 4, 7, 4)

    # === ROW 8-9: Gym types (8 types, toit+mur, 2 tiles each) ===
    gym_types = [
        ("rock", h("#8C7A5C"), h("#736140")),
        ("water", h("#4488CC"), h("#336699")),
        ("electric", h("#CCAA33"), h("#AA8826")),
        ("grass", h("#55AA44"), h("#448833")),
        ("poison", h("#9944AA"), h("#773388")),
        ("psychic", h("#CC5599"), h("#AA3377")),
        ("fire", h("#CC4422"), h("#AA3318")),
        ("ground", h("#AA8844"), h("#886633")),
    ]
    for i, (gtype, groof, gwall) in enumerate(gym_types):
        gc = i * 2
        # Roof
        tx, ty = tc.tile_origin(gc, 8)
        tc.rect(tx, ty, 32, 16, groof)
        tc.hline(tx, ty+14, 32, darker(groof))
        tc.hline(tx, ty+15, 32, darker(groof, 40))
        # Badge symbol (white diamond)
        tc.px(tx+15, ty+4, (255,255,255))
        tc.px(tx+14, ty+5, (255,255,255)); tc.px(tx+16, ty+5, (255,255,255))
        tc.px(tx+13, ty+6, (255,255,255)); tc.px(tx+17, ty+6, (255,255,255))
        tc.px(tx+14, ty+7, (255,255,255)); tc.px(tx+16, ty+7, (255,255,255))
        tc.px(tx+15, ty+8, (255,255,255))
        # Wall
        tx, ty = tc.tile_origin(gc, 9)
        tc.rect(tx, ty, 32, 16, gwall)
        tc.hline(tx, ty, 32, darker(gwall, 15))
        tc.hline(tx, ty+1, 32, darker(gwall, 10))
        # Door
        tc.rect(tx+12, ty+4, 8, 12, darker(gwall, 30))
        tc.rect(tx+13, ty+5, 6, 10, darker(gwall, 40))

    # === ROW 10: Floor tiles ===
    floor_colors = [
        (h("#B8AFA3"), h("#A89F93")),  # wood
        (h("#999999"), h("#888888")),  # stone
        (h("#C8C0B0"), h("#B8B0A0")),  # marble
        (h("#8888AA"), h("#787898")),  # purple
    ]
    for i, (fc1, fc2) in enumerate(floor_colors):
        draw_floor_tile(tc, i, 10, fc1)
        draw_floor_tile(tc, i + 4, 10, fc1, fc2)

    # === ROW 11: Interior elements ===
    draw_door_tile(tc, 0, 11, h("#7A5A2A"))
    draw_window_tile(tc, 1, 11, h("#6B5A4A"), (170, 200, 230))
    draw_stairs(tc, 2, 11, h("#B8AFA3"), h("#A89F93"), h("#988F83"))
    # Table
    tx, ty = tc.tile_origin(3, 11)
    tc.rect(tx, ty, 16, 16, floor_colors[0][0])
    tc.rect(tx+2, ty+6, 12, 4, h("#8B6914"))
    tc.rect(tx+3, ty+10, 2, 5, h("#6B4D12"))
    tc.rect(tx+11, ty+10, 2, 5, h("#6B4D12"))
    # Bookshelf
    tx, ty = tc.tile_origin(4, 11)
    tc.rect(tx, ty, 16, 16, floor_colors[0][0])
    tc.rect(tx+1, ty+1, 14, 14, h("#6B4D26"))
    for shelf_y in [3, 7, 11]:
        tc.hline(tx+2, ty+shelf_y, 12, h("#594026"))
        # Books (colored rectangles)
        for bx in range(3, 13, 3):
            bc = [(180,60,60),(60,100,180),(60,140,60),(180,160,60)][(bx//3)%4]
            tc.rect(tx+bx, ty+shelf_y-2, 2, 2, bc)

    tc.save(f"{name}.png")

# =====================================================================
#  BIOME PALETTES
# =====================================================================

BIOMES = {
    "grass": {
        "ground1": h("#4D8F38"), "ground2": h("#478534"), "ground3": h("#52943D"),
        "path1": h("#998055"), "path2": h("#947A4D"), "path3": h("#9E8559"),
        "water1": h("#1F87E6"), "water2": h("#2E94EB"), "water_hi": h("#80C8FF"),
        "tall_grass": h("#2E6619"), "tall_grass_light": h("#3D7A26"),
        "trunk": h("#6B4D26"), "canopy_dark": h("#1F5C14"), "canopy_mid": h("#2E7A1E"), "canopy_light": h("#4DA633"),
        "rock": h("#808070"), "rock_hi": h("#A0A090"),
        "flower1": h("#D94D59"), "flower2": h("#E6BF33"), "flower3": h("#994DCC"),
        "fence_c": h("#C8B898"), "bush": h("#2E7A1E"), "bush_light": h("#4DA633"),
        "house_roof": h("#CC4444"), "house_wall": (215, 208, 195),
    },
    "forest": {
        "ground1": h("#26611A"), "ground2": h("#215914"), "ground3": h("#2B661E"),
        "path1": h("#736140"), "path2": h("#6B5938"), "path3": h("#7A6B47"),
        "water1": h("#1A7ACC"), "water2": h("#2688D9"), "water_hi": h("#60B0F0"),
        "tall_grass": h("#1A4D0F"), "tall_grass_light": h("#266619"),
        "trunk": h("#594026"), "canopy_dark": h("#1F6B14"), "canopy_mid": h("#2B8C1E"), "canopy_light": h("#338C26"),
        "rock": h("#5A5A50"), "rock_hi": h("#7A7A6E"),
        "flower1": h("#D9D933"), "flower2": h("#CCCC26"), "flower3": h("#E6E640"),
        "fence_c": h("#7A6B47"), "bush": h("#1F6B14"), "bush_light": h("#2B8C1E"),
        "house_roof": h("#5C8A3E"), "house_wall": (140, 122, 92),
    },
    "city": {
        "ground1": h("#8C8C80"), "ground2": h("#858578"), "ground3": h("#94947E"),
        "path1": h("#A6A194"), "path2": h("#9E998C"), "path3": h("#ADA89C"),
        "water1": h("#1F87E6"), "water2": h("#2E94EB"), "water_hi": h("#80C8FF"),
        "tall_grass": h("#4D8F38"), "tall_grass_light": h("#5CA044"),
        "trunk": h("#6B4D26"), "canopy_dark": h("#336B26"), "canopy_mid": h("#3D8030"), "canopy_light": h("#4D9933"),
        "rock": h("#999990"), "rock_hi": h("#B0B0A8"),
        "flower1": h("#E64D4D"), "flower2": h("#E6BF33"), "flower3": h("#4D8CF2"),
        "fence_c": h("#B8B0A0"), "bush": h("#3D8030"), "bush_light": h("#4D9933"),
        "house_roof": h("#4477AA"), "house_wall": (191, 184, 173),
    },
    "cave": {
        "ground1": h("#4D4752"), "ground2": h("#47424D"), "ground3": h("#524D57"),
        "path1": h("#5C5766"), "path2": h("#575261"), "path3": h("#615C6B"),
        "water1": h("#1A5C99"), "water2": h("#2668A6"), "water_hi": h("#4088C0"),
        "tall_grass": h("#3D4738"), "tall_grass_light": h("#4D5748"),
        "trunk": h("#473D33"), "canopy_dark": h("#3D3833"), "canopy_mid": h("#4D4842"), "canopy_light": h("#524D47"),
        "rock": h("#66615A"), "rock_hi": h("#807A72"),
        "fence_c": h("#524D47"), "bush": h("#3D4738"), "bush_light": h("#4D5748"),
        "house_roof": h("#47424D"), "house_wall": (56, 51, 64),
    },
    "snow": {
        "ground1": h("#E6EBF2"), "ground2": h("#E0E6ED"), "ground3": h("#EBEDF5"),
        "path1": h("#CCD1D9"), "path2": h("#C7CCD4"), "path3": h("#D1D6DE"),
        "water1": h("#B3E0F2"), "water2": h("#A6D9EB"), "water_hi": h("#D0F0FF"),
        "tall_grass": h("#C7D9C2"), "tall_grass_light": h("#D4E6CF"),
        "trunk": h("#7A6B5C"), "canopy_dark": h("#4D7A4D"), "canopy_mid": h("#5C8C5C"), "canopy_light": h("#6B996B"),
        "rock": h("#B0B8C0"), "rock_hi": h("#D0D8E0"),
        "flower1": h("#6699CC"), "flower2": h("#7AAAD4"), "flower3": h("#5588BB"),
        "fence_c": h("#C0C8D0"), "bush": h("#5C8C5C"), "bush_light": h("#6B996B"),
        "house_roof": h("#7A8899"), "house_wall": (212, 217, 224),
    },
    "beach": {
        "ground1": h("#EBD9A6"), "ground2": h("#E6D199"), "ground3": h("#F0DEAD"),
        "path1": h("#C7B880"), "path2": h("#C2B37A"), "path3": h("#CCB885"),
        "water1": h("#1F99D9"), "water2": h("#2EA6E0"), "water_hi": h("#70D0FF"),
        "tall_grass": h("#8CB84D"), "tall_grass_light": h("#9CCC5C"),
        "trunk": h("#8C6B3D"), "canopy_dark": h("#33993D"), "canopy_mid": h("#40AD48"), "canopy_light": h("#4DB84D"),
        "rock": h("#C7B88C"), "rock_hi": h("#DDD0A8"),
        "flower1": h("#FF8C66"), "flower2": h("#FFB84D"), "flower3": h("#FF6680"),
        "fence_c": h("#D9CC9E"), "bush": h("#40AD48"), "bush_light": h("#4DB84D"),
        "house_roof": h("#E6A64D"), "house_wall": (240, 230, 204),
    },
}

# =====================================================================
#  MAIN
# =====================================================================

if __name__ == "__main__":
    print("Generating 6 biome tilesets (v3 — clean pixel art)...")
    for biome_name, palette in BIOMES.items():
        generate_biome(biome_name, palette)
    print("Done!")
