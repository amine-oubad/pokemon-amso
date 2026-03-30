#!/usr/bin/env python3
"""Generate 8 battle backgrounds (320x140) with proper GBA Pokemon style.
Clean gradients, battle platforms, terrain details. No random noise.
"""
from PIL import Image, ImageDraw
import os, math

OUT = "assets/sprites/battle/backgrounds"
os.makedirs(OUT, exist_ok=True)

def h(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

def lerp(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

W, H = 320, 140
SKY_H = 75

def draw_gradient(draw, x, y, w, hv, c1, c2):
    """Vertical gradient fill."""
    for row in range(hv):
        t = row / max(1, hv - 1)
        c = lerp(c1, c2, t)
        draw.line([(x, y + row), (x + w - 1, y + row)], fill=(*c, 255))

def draw_platform(draw, cx, cy, rx, ry, c_top, c_bot, outline_c):
    """Elliptical battle platform with gradient shading."""
    for dy in range(-ry, ry + 1):
        t = (dy + ry) / max(1, 2 * ry)
        half_w = int(rx * math.sqrt(max(0, 1 - (dy / max(1, ry)) ** 2)))
        if half_w <= 0:
            continue
        c = lerp(c_top, c_bot, t)
        draw.line([(cx - half_w, cy + dy), (cx + half_w, cy + dy)], fill=(*c, 255))
    # Outline
    for angle in range(0, 360, 1):
        rad = math.radians(angle)
        ox = cx + int(rx * math.cos(rad))
        oy = cy + int(ry * math.sin(rad))
        if 0 <= ox < W and 0 <= oy < H:
            draw.point((ox, oy), fill=(*outline_c, 255))

TERRAINS = {
    "grass": {
        "sky_top": h("#78B8F0"), "sky_bot": h("#A8D8F0"),
        "gnd_top": h("#58A838"), "gnd_mid": h("#48982C"), "gnd_bot": h("#3C8824"),
        "plat_top": h("#68B848"), "plat_bot": h("#488828"), "plat_line": h("#306818"),
        "horizon": h("#4D9438"),
        "detail": "grass",
    },
    "forest": {
        "sky_top": h("#285828"), "sky_bot": h("#3A7030"),
        "gnd_top": h("#2E6620"), "gnd_mid": h("#245818"), "gnd_bot": h("#1C4C12"),
        "plat_top": h("#3A7828"), "plat_bot": h("#285C1C"), "plat_line": h("#1C4410"),
        "horizon": h("#2A6020"),
        "detail": "forest",
    },
    "cave": {
        "sky_top": h("#1E1A2E"), "sky_bot": h("#2A2640"),
        "gnd_top": h("#4D4752"), "gnd_mid": h("#443F4A"), "gnd_bot": h("#3A3542"),
        "plat_top": h("#5A5460"), "plat_bot": h("#484250"), "plat_line": h("#333040"),
        "horizon": h("#3D384A"),
        "detail": "cave",
    },
    "water": {
        "sky_top": h("#78B8F0"), "sky_bot": h("#90C8F0"),
        "gnd_top": h("#3090D8"), "gnd_mid": h("#2680C8"), "gnd_bot": h("#1C70B8"),
        "plat_top": h("#40A0E0"), "plat_bot": h("#2880C0"), "plat_line": h("#1C68A0"),
        "horizon": h("#2888D0"),
        "detail": "water",
    },
    "indoor": {
        "sky_top": h("#4D4759"), "sky_bot": h("#4D4759"),
        "gnd_top": h("#6B6560"), "gnd_mid": h("#605A55"), "gnd_bot": h("#554F4A"),
        "plat_top": h("#787068"), "plat_bot": h("#605850"), "plat_line": h("#484038"),
        "horizon": h("#585250"),
        "detail": "indoor",
    },
    "snow": {
        "sky_top": h("#BFD1EB"), "sky_bot": h("#D8E4F2"),
        "gnd_top": h("#E8ECF2"), "gnd_mid": h("#DDE2E8"), "gnd_bot": h("#D0D5DC"),
        "plat_top": h("#F0F2F5"), "plat_bot": h("#D8DCE2"), "plat_line": h("#B0B8C0"),
        "horizon": h("#C8D0D8"),
        "detail": "snow",
    },
    "sand": {
        "sky_top": h("#C8A860"), "sky_bot": h("#D8BC78"),
        "gnd_top": h("#E0C880"), "gnd_mid": h("#D4BA70"), "gnd_bot": h("#C8AE64"),
        "plat_top": h("#E8D090"), "plat_bot": h("#D0B870"), "plat_line": h("#B09850"),
        "horizon": h("#D0BC70"),
        "detail": "sand",
    },
    "volcano": {
        "sky_top": h("#401010"), "sky_bot": h("#602018"),
        "gnd_top": h("#5A2A18"), "gnd_mid": h("#4C2010"), "gnd_bot": h("#3E180C"),
        "plat_top": h("#6A3420"), "plat_bot": h("#502818"), "plat_line": h("#381810"),
        "horizon": h("#4A2214"),
        "detail": "volcano",
    },
}

def add_details(draw, img, terrain_type, gnd_top_c, gnd_mid_c):
    """Add terrain-specific details to the ground area."""
    if terrain_type == "grass":
        # Grass blades on ground
        blade_c = lerp(gnd_top_c, (100, 200, 80), 0.3)
        blade_dark = lerp(gnd_top_c, (60, 140, 40), 0.2)
        for bx in range(8, W, 20):
            by = SKY_H + 8
            draw.line([(bx, by + 10), (bx - 2, by + 2)], fill=(*blade_c, 255))
            draw.line([(bx + 1, by + 10), (bx + 3, by + 2)], fill=(*blade_dark, 255))
        for bx in range(18, W, 25):
            by = SKY_H + 30
            draw.line([(bx, by + 8), (bx - 1, by + 1)], fill=(*blade_c, 200))

    elif terrain_type == "forest":
        # Tree silhouettes in background (sky area)
        tree_c = lerp(h("#1A4810"), h("#285020"), 0.5)
        for tx in [30, 90, 160, 230, 290]:
            # Simple triangle tree
            for ty in range(20, 70):
                w = max(1, (ty - 20) // 3)
                draw.line([(tx - w, ty), (tx + w, ty)], fill=(*tree_c, 150))
        # Leaf particles on ground
        leaf_c = h("#3D8030")
        for lx in range(15, W, 30):
            img.putpixel((lx, SKY_H + 15), (*leaf_c, 255))
            img.putpixel((lx + 1, SKY_H + 16), (*leaf_c, 255))

    elif terrain_type == "cave":
        # Stalactites hanging from top
        stal_c = h("#5A5460")
        stal_hi = h("#6A6470")
        for sx in [25, 65, 110, 165, 210, 260, 305]:
            length = (sx * 7 + 13) % 20 + 10
            for sy in range(length):
                w = max(1, 3 - sy // 8)
                draw.line([(sx - w, sy), (sx + w, sy)], fill=(*stal_c, 255))
            draw.point((sx, 2), fill=(*stal_hi, 255))
        # Crystal glows
        for cx in [80, 200, 280]:
            cy = SKY_H + 20 + (cx % 15)
            img.putpixel((cx, cy), (120, 140, 200, 255))
            img.putpixel((cx + 1, cy), (100, 120, 180, 255))

    elif terrain_type == "water":
        # Wave lines on water surface
        wave_c = h("#50B0E8")
        for wy in range(SKY_H + 5, H, 12):
            for wx in range(0, W, 3):
                offset = (wy * 3 + wx) % 8
                if offset < 2:
                    draw.point((wx, wy), fill=(*wave_c, 200))
        # Foam highlights
        foam_c = (200, 230, 255)
        for fx in range(10, W, 40):
            fy = SKY_H + 8 + (fx % 10)
            draw.line([(fx, fy), (fx + 4, fy)], fill=(*foam_c, 150))

    elif terrain_type == "indoor":
        # Floor tile grid
        tile_line = h("#585250")
        for gx in range(0, W, 16):
            draw.line([(gx, SKY_H), (gx, H - 1)], fill=(*tile_line, 100))
        for gy in range(SKY_H, H, 16):
            draw.line([(0, gy), (W - 1, gy)], fill=(*tile_line, 100))

    elif terrain_type == "snow":
        # Sparkle dots
        for sx in range(12, W, 18):
            sy = SKY_H + 5 + (sx * 3) % 50
            if sy < H:
                img.putpixel((sx, sy), (255, 255, 255, 200))
        # Mountain silhouettes in sky
        mtn_c = h("#C0C8D4")
        for mx in range(0, W, 2):
            my = 30 + int(15 * math.sin(mx * 0.02) + 8 * math.sin(mx * 0.05))
            draw.line([(mx, my), (mx, SKY_H)], fill=(*mtn_c, 80))

    elif terrain_type == "sand":
        # Dune wave pattern
        dune_c = lerp(gnd_top_c, (200, 180, 120), 0.3)
        for dy in range(SKY_H + 5, H, 8):
            for dx in range(0, W, 2):
                offset = int(3 * math.sin(dx * 0.05 + dy * 0.1))
                if abs(offset) < 1:
                    draw.point((dx, dy + offset), fill=(*dune_c, 150))

    elif terrain_type == "volcano":
        # Lava cracks in ground
        lava_c = h("#E05020")
        lava_glow = h("#FF8040")
        for lx in range(20, W, 40):
            ly = SKY_H + 10 + (lx * 7) % 40
            if ly < H - 5:
                draw.line([(lx, ly), (lx + 8, ly + 3)], fill=(*lava_c, 255))
                draw.line([(lx + 1, ly - 1), (lx + 7, ly + 2)], fill=(*lava_glow, 180))
        # Embers floating up
        for ex in range(15, W, 35):
            ey = 10 + (ex * 3) % 60
            img.putpixel((ex, ey), (255, 140, 60, 200))


def generate_background(name, cfg):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # Sky gradient
    draw_gradient(draw, 0, 0, W, SKY_H, cfg["sky_top"], cfg["sky_bot"])

    # Horizon line
    draw.line([(0, SKY_H), (W - 1, SKY_H)], fill=(*cfg["horizon"], 255))

    # Ground: 3-band gradient
    gnd_h = H - SKY_H - 1
    band = gnd_h // 3
    draw_gradient(draw, 0, SKY_H + 1, W, band, cfg["gnd_top"], cfg["gnd_mid"])
    draw_gradient(draw, 0, SKY_H + 1 + band, W, band, cfg["gnd_mid"], cfg["gnd_bot"])
    draw_gradient(draw, 0, SKY_H + 1 + band * 2, W, gnd_h - band * 2, cfg["gnd_bot"], cfg["gnd_bot"])

    # Terrain details
    add_details(draw, img, cfg["detail"], cfg["gnd_top"], cfg["gnd_mid"])

    # Enemy platform (upper right)
    draw_platform(draw, 220, SKY_H + 18, 48, 10, cfg["plat_top"], cfg["plat_bot"], cfg["plat_line"])

    # Player platform (lower left)
    draw_platform(draw, 100, H - 18, 54, 12, cfg["plat_top"], cfg["plat_bot"], cfg["plat_line"])

    img.save(os.path.join(OUT, f"{name}.png"))
    print(f"  {name}.png saved")


if __name__ == "__main__":
    print("Generating 8 battle backgrounds (v3 - GBA style)...")
    for name, cfg in TERRAINS.items():
        generate_background(name, cfg)
    print("Done!")
