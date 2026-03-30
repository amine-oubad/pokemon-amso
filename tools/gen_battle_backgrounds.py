#!/usr/bin/env python3
"""Generate 8 battle backgrounds (320x140 PNG) with gradient sky + textured ground."""
from PIL import Image, ImageDraw
import random, os

OUT = "assets/sprites/battle/backgrounds"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_gradient(draw, x, y, w, h, top_color, bottom_color):
    for row in range(h):
        t = row / max(1, h - 1)
        c = lerp_color(top_color, bottom_color, t)
        draw.line([(x, y + row), (x + w - 1, y + row)], fill=(*c, 255))

def noise_band(draw, y_start, y_end, w, base_color, variance=8):
    for py in range(y_start, y_end):
        for px in range(w):
            r = max(0, min(255, base_color[0] + random.randint(-variance, variance)))
            g = max(0, min(255, base_color[1] + random.randint(-variance, variance)))
            b = max(0, min(255, base_color[2] + random.randint(-variance, variance)))
            draw.point((px, py), fill=(r, g, b, 255))

TERRAINS = {
    "grass": {
        "sky_top": hex2rgb("#73B3F2"),
        "sky_bottom": hex2rgb("#4D9438"),
        "ground": hex2rgb("#598C33"),
        "sky_height": 80,
        "details": "grass_blades",
    },
    "cave": {
        "sky_top": hex2rgb("#1E1A2E"),
        "sky_bottom": hex2rgb("#33303F"),
        "ground": hex2rgb("#4D4752"),
        "sky_height": 80,
        "details": "stalactites",
    },
    "water": {
        "sky_top": hex2rgb("#73B3F2"),
        "sky_bottom": hex2rgb("#2680D9"),
        "ground": hex2rgb("#338CD9"),
        "sky_height": 80,
        "details": "waves",
    },
    "indoor": {
        "sky_top": hex2rgb("#4D4759"),
        "sky_bottom": hex2rgb("#4D4759"),
        "ground": hex2rgb("#736B61"),
        "sky_height": 70,
        "details": "tiles",
    },
    "snow": {
        "sky_top": hex2rgb("#BFD1EB"),
        "sky_bottom": hex2rgb("#E0E6F2"),
        "ground": hex2rgb("#EBEDF5"),
        "sky_height": 80,
        "details": "snow_sparkle",
    },
    "sand": {
        "sky_top": hex2rgb("#CCB373"),
        "sky_bottom": hex2rgb("#E6CC8C"),
        "ground": hex2rgb("#E0C780"),
        "sky_height": 75,
        "details": "dunes",
    },
    "volcano": {
        "sky_top": hex2rgb("#591A14"),
        "sky_bottom": hex2rgb("#8C2E1A"),
        "ground": hex2rgb("#66331E"),
        "sky_height": 80,
        "details": "lava",
    },
    "forest": {
        "sky_top": hex2rgb("#337329"),
        "sky_bottom": hex2rgb("#1E591A"),
        "ground": hex2rgb("#2E661E"),
        "sky_height": 80,
        "details": "leaves",
    },
}

W, H = 320, 140

for name, t in TERRAINS.items():
    random.seed(42 + hash(name))
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    sky_h = t["sky_height"]
    ground_h = H - sky_h

    # Sky gradient
    draw_gradient(draw, 0, 0, W, sky_h, t["sky_top"], t["sky_bottom"])

    # Ground base with noise
    noise_band(draw, sky_h, H, W, t["ground"], 6)

    # Horizon line (slightly darker)
    horizon_c = lerp_color(t["sky_bottom"], t["ground"], 0.5)
    draw.line([(0, sky_h), (W-1, sky_h)], fill=(*horizon_c, 255))
    draw.line([(0, sky_h+1), (W-1, sky_h+1)], fill=(*horizon_c, 200))

    # === DETAILS ===
    details = t["details"]

    if details == "grass_blades":
        for _ in range(120):
            gx = random.randint(0, W-1)
            gy = random.randint(sky_h+5, H-5)
            gh = random.randint(3, 8)
            shade = random.randint(-20, 20)
            gc = (max(0,min(255, 70+shade)), max(0,min(255, 160+shade)), max(0,min(255, 50+shade)))
            draw.line([(gx, gy), (gx+random.randint(-2,2), gy-gh)], fill=(*gc, 200))
        # A few flower dots
        for _ in range(15):
            fx, fy = random.randint(0, W-1), random.randint(sky_h+10, H-3)
            fc = random.choice([(220, 80, 80), (240, 200, 50), (180, 100, 220)])
            draw.point((fx, fy), fill=(*fc, 255))

    elif details == "stalactites":
        for _ in range(25):
            sx = random.randint(0, W-1)
            sl = random.randint(8, 25)
            sc = lerp_color(t["sky_top"], (60, 55, 70), random.random()*0.5)
            for sy in range(sl):
                w_at = max(1, int((1 - sy/sl) * 4))
                draw.line([(sx-w_at//2, sy), (sx+w_at//2, sy)], fill=(*sc, 200))
        # Glowing crystals
        for _ in range(8):
            cx, cy = random.randint(10, W-10), random.randint(sky_h+5, H-10)
            cc = random.choice([(100, 180, 255), (180, 100, 255), (100, 255, 180)])
            draw.rectangle([cx-1, cy-1, cx+1, cy+1], fill=(*cc, 180))
            draw.point((cx, cy), fill=(255, 255, 255, 200))

    elif details == "waves":
        for wy in range(sky_h+3, H, 6):
            for wx in range(0, W, 12):
                offset = (wy * 3) % 8
                wc = (min(255, t["ground"][0]+30), min(255, t["ground"][1]+30), min(255, t["ground"][2]+30))
                draw.line([(wx+offset, wy), (wx+offset+5, wy)], fill=(*wc, 150))
        # Foam at horizon
        for fx in range(0, W, 4):
            if random.random() < 0.4:
                draw.point((fx, sky_h+2), fill=(220, 230, 240, 180))
                draw.point((fx+1, sky_h+2), fill=(220, 230, 240, 150))

    elif details == "tiles":
        # Floor grid
        for ty in range(sky_h, H, 16):
            draw.line([(0, ty), (W-1, ty)], fill=(100, 95, 85, 100))
        for tx in range(0, W, 16):
            draw.line([(tx, sky_h), (tx, H-1)], fill=(100, 95, 85, 100))
        # Wall at top
        wall_c = hex2rgb("#403847")
        draw_gradient(draw, 0, 0, W, sky_h, wall_c, (wall_c[0]+20, wall_c[1]+20, wall_c[2]+20))
        # Wall bricks
        for by in range(0, sky_h, 10):
            offset = 12 if (by // 10) % 2 else 0
            for bx in range(offset, W, 24):
                draw.line([(bx, by), (bx, by+9)], fill=(max(0,wall_c[0]-10), max(0,wall_c[1]-10), max(0,wall_c[2]-10), 80))

    elif details == "snow_sparkle":
        for _ in range(40):
            sx, sy = random.randint(0, W-1), random.randint(sky_h+2, H-2)
            draw.point((sx, sy), fill=(255, 255, 255, 200))
        # Distant snowy mountains in sky
        peaks = [(40, 30), (100, 20), (160, 35), (220, 25), (280, 30)]
        for px_c, ph in peaks:
            for mx in range(-20, 21):
                mh = max(0, ph - abs(mx))
                mc = lerp_color(hex2rgb("#D0D8E8"), hex2rgb("#E8ECF2"), abs(mx)/20)
                draw.line([(px_c+mx, sky_h-1), (px_c+mx, sky_h-1-mh)], fill=(*mc, 180))

    elif details == "dunes":
        for dy in range(sky_h+5, H, 10):
            amplitude = random.randint(2, 5)
            phase = random.random() * 6.28
            dune_c = (min(255, t["ground"][0]+15), min(255, t["ground"][1]+15), min(255, t["ground"][2]+10))
            for dx in range(W):
                import math
                offset = int(amplitude * math.sin(dx * 0.05 + phase))
                if 0 <= dy + offset < H:
                    draw.point((dx, dy + offset), fill=(*dune_c, 150))

    elif details == "lava":
        # Lava cracks in ground
        for _ in range(20):
            lx = random.randint(0, W-1)
            ly = random.randint(sky_h+5, H-5)
            llen = random.randint(10, 40)
            for i in range(llen):
                px_l = lx + i + random.randint(-1, 1)
                py_l = ly + random.randint(-1, 1)
                if 0 <= px_l < W and 0 <= py_l < H:
                    lc = random.choice([(255, 100, 20), (255, 150, 30), (255, 60, 10)])
                    draw.point((px_l, py_l), fill=(*lc, 220))
        # Embers in sky
        for _ in range(15):
            ex, ey = random.randint(0, W-1), random.randint(5, sky_h-5)
            ec = random.choice([(255, 140, 40), (255, 200, 60)])
            draw.point((ex, ey), fill=(*ec, 150))

    elif details == "leaves":
        # Leaf particles
        for _ in range(30):
            lx, ly = random.randint(0, W-1), random.randint(5, sky_h+20)
            lc = random.choice([(60, 140, 40), (80, 160, 50), (50, 120, 30)])
            draw.rectangle([lx, ly, lx+2, ly+1], fill=(*lc, 180))
        # Moss on ground
        for _ in range(60):
            mx, my = random.randint(0, W-1), random.randint(sky_h+2, H-2)
            mc = (max(0, t["ground"][0]+random.randint(-10,20)),
                  max(0, min(255, t["ground"][1]+random.randint(0,30))),
                  max(0, t["ground"][2]+random.randint(-10,10)))
            draw.point((mx, my), fill=(*mc, 200))
        # Tree silhouettes in sky
        for tx_pos in [30, 90, 170, 250, 300]:
            th = random.randint(20, 40)
            tw = random.randint(15, 25)
            tc = lerp_color(t["sky_top"], (15, 40, 12), 0.6)
            # Trunk
            draw.rectangle([tx_pos-1, sky_h-th, tx_pos+1, sky_h], fill=(*tc, 150))
            # Canopy
            draw.ellipse([tx_pos-tw//2, sky_h-th-tw//2, tx_pos+tw//2, sky_h-th+tw//3], fill=(*tc, 130))

    # === PLATFORM LINES (battle positions) ===
    # Player platform (left, lower)
    plat_y = H - 20
    plat_c = lerp_color(t["ground"], (0,0,0), 0.2)
    draw.ellipse([20, plat_y-3, 120, plat_y+8], fill=(*plat_c, 120))
    # Enemy platform (right, upper)
    eplat_y = sky_h + 15
    draw.ellipse([190, eplat_y-3, 300, eplat_y+8], fill=(*plat_c, 100))

    img.save(os.path.join(OUT, f"{name}.png"))
    print(f"  {name}.png saved (320x140)")

print("Done: 8 battle backgrounds generated")
