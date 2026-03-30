#!/usr/bin/env python3
"""Generate 8 battle backgrounds (320x140) with proper GBA-style terrain.
Style: Pokemon Unbound — clean gradients, distinct terrain layers, battle platforms.
"""
from PIL import Image, ImageDraw
import os, math

OUT = "assets/sprites/battle/backgrounds"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    return tuple(int(h.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))

def lerp(c1, c2, t):
    return tuple(int(c1[i]+(c2[i]-c1[i])*t) for i in range(3))

def gradient_h(draw, x, y, w, h, c1, c2):
    for row in range(h):
        t = row / max(1, h-1)
        c = lerp(c1, c2, t)
        draw.line([(x, y+row), (x+w-1, y+row)], fill=(*c, 255))

def draw_platform(draw, cx, cy, rw, rh, c1, c2, outline):
    """Draw an elliptical battle platform with shading."""
    for dy in range(-rh, rh+1):
        t = abs(dy) / max(1, rh)
        half_w = int(rw * math.sqrt(max(0, 1 - (dy/max(1,rh))**2)))
        if half_w <= 0: continue
        c = lerp(c1, c2, t)
        draw.line([(cx-half_w, cy+dy), (cx+half_w, cy+dy)], fill=(*c, 255))
    # Outline
    for angle_deg in range(0, 360, 2):
        rad = math.radians(angle_deg)
        ox = cx + int(rw * math.cos(rad))
        oy = cy + int(rh * math.sin(rad))
        draw.point((ox, oy), fill=(*outline, 255))

W, H = 320, 140

TERRAINS = {
    "grass": {
        "sky_top": hex2rgb("#78B8F0"), "sky_bot": hex2rgb("#A8D8F0"),
        "ground_top": hex2rgb("#58A838"), "ground_mid": hex2rgb("#48982C"),
        "ground_bot": hex2rgb("#3C8824"),
        "plat1": hex2rgb("#68B848"), "plat2": hex2rgb("#488828"),
        "plat_outline": hex2rgb("#306818"),
        "detail": "grass_blades",
    },
    "forest": {
        "sky_top": hex2rgb("#285828"), "sky_bot": hex2rgb("#184018"),
        "ground_top": hex2rgb("#2E6E20"), "ground_mid": hex2rgb("#245E18"),
        "ground_bot": hex2rgb("#1C4E12"),
        "plat1": hex2rgb("#387828"), "plat2": hex2rgb("#245018"),
        "plat_outline": hex2rgb("#183810"),
        "detail": "leaves",
    },
    "cave": {
        "sky_top": hex2rgb("#181420"), "sky_bot": hex2rgb("#282030"),
        "ground_top": hex2rgb("#484050"), "ground_mid": hex2rgb("#3C3444"),
        "ground_bot": hex2rgb("#302838"),
        "plat1": hex2rgb("#585060"), "plat2": hex2rgb("#383040"),
        "plat_outline": hex2rgb("#282030"),
        "detail": "stalactites",
    },
    "water": {
        "sky_top": hex2rgb("#78B8F0"), "sky_bot": hex2rgb("#58A0E0"),
        "ground_top": hex2rgb("#3090D8"), "ground_mid": hex2rgb("#2878C0"),
        "ground_bot": hex2rgb("#2068A8"),
        "plat1": hex2rgb("#48A8E8"), "plat2": hex2rgb("#2878B8"),
        "plat_outline": hex2rgb("#186090"),
        "detail": "waves",
    },
    "indoor": {
        "sky_top": hex2rgb("#484050"), "sky_bot": hex2rgb("#383040"),
        "ground_top": hex2rgb("#988878"), "ground_mid": hex2rgb("#887868"),
        "ground_bot": hex2rgb("#786858"),
        "plat1": hex2rgb("#A89888"), "plat2": hex2rgb("#887060"),
        "plat_outline": hex2rgb("#685848"),
        "detail": "floor_tiles",
    },
    "snow": {
        "sky_top": hex2rgb("#B8D0E8"), "sky_bot": hex2rgb("#D0E0F0"),
        "ground_top": hex2rgb("#E8EDF5"), "ground_mid": hex2rgb("#DDE3ED"),
        "ground_bot": hex2rgb("#D0D8E5"),
        "plat1": hex2rgb("#F0F2F8"), "plat2": hex2rgb("#C8D0D8"),
        "plat_outline": hex2rgb("#A0A8B8"),
        "detail": "snow_sparkle",
    },
    "sand": {
        "sky_top": hex2rgb("#D8C080"), "sky_bot": hex2rgb("#E8D8A0"),
        "ground_top": hex2rgb("#E0C880"), "ground_mid": hex2rgb("#D8C070"),
        "ground_bot": hex2rgb("#C8B060"),
        "plat1": hex2rgb("#E8D898"), "plat2": hex2rgb("#C8B068"),
        "plat_outline": hex2rgb("#A89848"),
        "detail": "dunes",
    },
    "volcano": {
        "sky_top": hex2rgb("#401810"), "sky_bot": hex2rgb("#682818"),
        "ground_top": hex2rgb("#583020"), "ground_mid": hex2rgb("#482818"),
        "ground_bot": hex2rgb("#382010"),
        "plat1": hex2rgb("#684030"), "plat2": hex2rgb("#483020"),
        "plat_outline": hex2rgb("#302010"),
        "detail": "lava_cracks",
    },
}

for name, t in TERRAINS.items():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    sky_h = 75
    # Sky gradient
    gradient_h(draw, 0, 0, W, sky_h, t["sky_top"], t["sky_bot"])

    # Ground layers
    ground_h = H - sky_h
    gradient_h(draw, 0, sky_h, W, ground_h//2, t["ground_top"], t["ground_mid"])
    gradient_h(draw, 0, sky_h+ground_h//2, W, ground_h-ground_h//2, t["ground_mid"], t["ground_bot"])

    # Horizon line (slightly blended)
    horizon = lerp(t["sky_bot"], t["ground_top"], 0.5)
    draw.line([(0, sky_h-1), (W-1, sky_h-1)], fill=(*horizon, 255))
    draw.line([(0, sky_h), (W-1, sky_h)], fill=(*t["ground_top"], 255))

    # === TERRAIN DETAILS ===
    detail = t["detail"]

    if detail == "grass_blades":
        # Small grass tufts on ground
        for gx in range(5, W, 18):
            for gy in [sky_h+8, sky_h+20, sky_h+35, sky_h+50]:
                c = lerp(t["ground_top"], (100, 200, 80), 0.3)
                draw.line([(gx, gy), (gx-1, gy-4)], fill=(*c, 180))
                draw.line([(gx+2, gy), (gx+3, gy-3)], fill=(*c, 160))
        # Distant hills in sky
        for hx in range(W):
            hh = int(12 * math.sin(hx*0.02) + 8 * math.sin(hx*0.05+1))
            hh = max(2, hh)
            hc = lerp(t["sky_bot"], t["ground_top"], 0.4)
            draw.line([(hx, sky_h-hh), (hx, sky_h-1)], fill=(*hc, 100))

    elif detail == "leaves":
        # Leaf particles in air
        for lx in range(10, W, 25):
            for ly in range(10, sky_h, 20):
                lc = lerp(t["sky_top"], (60, 140, 40), 0.5)
                draw.rectangle([lx, ly, lx+2, ly+1], fill=(*lc, 140))
        # Moss patches on ground
        for mx in range(0, W, 12):
            my = sky_h + 5 + (mx % 7) * 3
            mc = lerp(t["ground_top"], (40, 100, 30), 0.3)
            draw.point((mx, my), fill=(*mc, 200))
            draw.point((mx+1, my), fill=(*mc, 180))
        # Tree silhouettes
        for tree_x in [30, 80, 200, 270]:
            th = 30 + (tree_x % 15)
            tc = lerp(t["sky_top"], (10, 30, 8), 0.6)
            draw.line([(tree_x, sky_h-1), (tree_x, sky_h-th)], fill=(*tc, 120), width=2)
            draw.ellipse([tree_x-12, sky_h-th-15, tree_x+12, sky_h-th+5], fill=(*tc, 100))

    elif detail == "stalactites":
        # Stalactites from ceiling
        for sx in range(15, W, 30):
            sl = 10 + (sx % 20)
            sc = lerp(t["sky_top"], (50, 45, 60), 0.5)
            for sy in range(sl):
                w = max(1, int((1 - sy/sl) * 3))
                draw.line([(sx-w, sy), (sx+w, sy)], fill=(*sc, 180))
        # Crystal glows
        for cx, cy in [(50, sky_h+20), (180, sky_h+10), (280, sky_h+30)]:
            cc = (80, 140, 220)
            draw.rectangle([cx-1, cy-1, cx+1, cy+1], fill=(*cc, 160))
            draw.point((cx, cy), fill=(180, 220, 255, 200))

    elif detail == "waves":
        # Wave lines across water surface
        for wy in range(sky_h+4, H, 6):
            for wx in range(0, W, 14):
                off = (wy * 3) % 8
                wc = lerp(t["ground_top"], (100, 180, 255), 0.3)
                draw.line([(wx+off, wy), (wx+off+6, wy)], fill=(*wc, 120))
        # Foam at horizon
        for fx in range(0, W, 3):
            if (fx % 5) < 3:
                draw.point((fx, sky_h+1), fill=(200, 220, 240, 150))

    elif detail == "floor_tiles":
        # Wall at top (brick pattern)
        wall = lerp(t["sky_top"], t["sky_bot"], 0.5)
        for by in range(0, sky_h, 8):
            off = 6 if (by//8) % 2 else 0
            for bx in range(off, W, 12):
                draw.line([(bx, by), (bx, by+7)], fill=(*lerp(wall, (0,0,0), 0.15), 80))
            draw.line([(0, by), (W-1, by)], fill=(*lerp(wall, (0,0,0), 0.1), 60))
        # Floor grid
        for gy in range(sky_h, H, 16):
            draw.line([(0, gy), (W-1, gy)], fill=(*lerp(t["ground_mid"], (0,0,0), 0.15), 80))
        for gx in range(0, W, 16):
            draw.line([(gx, sky_h), (gx, H-1)], fill=(*lerp(t["ground_mid"], (0,0,0), 0.1), 60))

    elif detail == "snow_sparkle":
        # Snow sparkle dots
        import random
        random.seed(42)
        for _ in range(30):
            sx, sy = random.randint(0, W-1), random.randint(sky_h+3, H-3)
            draw.point((sx, sy), fill=(255, 255, 255, 180))
        # Mountain silhouettes
        for px in range(W):
            mh = int(25 * math.sin(px*0.015) + 15 * math.sin(px*0.04+2))
            mh = max(3, mh)
            mc = lerp(t["sky_bot"], (200, 210, 225), 0.5)
            draw.line([(px, sky_h-mh), (px, sky_h-1)], fill=(*mc, 130))

    elif detail == "dunes":
        # Sand dune waves
        for dy in range(sky_h+5, H, 10):
            for dx in range(W):
                offset = int(3 * math.sin(dx*0.04 + dy*0.3))
                ny = dy + offset
                if sky_h <= ny < H:
                    dc = lerp(t["ground_top"], (240, 220, 160), 0.15)
                    draw.point((dx, ny), fill=(*dc, 100))

    elif detail == "lava_cracks":
        # Lava cracks in ground
        import random
        random.seed(42)
        for _ in range(15):
            lx = random.randint(10, W-10)
            ly = random.randint(sky_h+10, H-10)
            for i in range(random.randint(15, 35)):
                px = lx + i + random.randint(-1, 1)
                py = ly + random.randint(-1, 1)
                if 0 <= px < W and sky_h <= py < H:
                    lc = (255, random.randint(60, 160), random.randint(10, 40))
                    draw.point((px, py), fill=(*lc, 200))
        # Embers
        for _ in range(10):
            ex, ey = random.randint(0, W-1), random.randint(5, sky_h-5)
            draw.point((ex, ey), fill=(255, 140, 40, 130))

    # === BATTLE PLATFORMS ===
    # Enemy platform (right, upper)
    draw_platform(draw, 235, sky_h+18, 50, 8, t["plat1"], t["plat2"], t["plat_outline"])
    # Player platform (left, lower)
    draw_platform(draw, 85, H-18, 55, 10, t["plat1"], t["plat2"], t["plat_outline"])

    img.save(os.path.join(OUT, f"{name}.png"))
    print(f"  {name}.png saved (320x140)")

print("Done: 8 battle backgrounds generated")
