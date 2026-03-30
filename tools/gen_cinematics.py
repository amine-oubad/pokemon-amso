#!/usr/bin/env python3
"""Generate cinematic assets: transitions, gym intros, story frames, mega evo frames."""
from PIL import Image, ImageDraw
import random, os, math

W, H = 320, 240

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

def noise_fill(draw, x, y, w, h, base, variance=8):
    for py in range(y, y+h):
        for px in range(x, x+w):
            r = max(0, min(255, base[0] + random.randint(-variance, variance)))
            g = max(0, min(255, base[1] + random.randint(-variance, variance)))
            b = max(0, min(255, base[2] + random.randint(-variance, variance)))
            draw.point((px, py), fill=(r, g, b, 255))

# =================================================================
# TRANSITIONS
# =================================================================
TRANS_DIR = "assets/cinematics/transitions"
os.makedirs(TRANS_DIR, exist_ok=True)

def gen_wild_encounter():
    """Wild battle transition: 6 horizontal bands closing + white flash overlay."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Flash white with fade
    draw.rectangle([0, 0, W-1, H-1], fill=(255, 255, 255, 180))
    # 6 horizontal black bands (partially closed)
    band_h = H // 6
    for i in range(6):
        y = i * band_h
        close_pct = 0.6  # 60% closed
        bw = int(W * close_pct / 2)
        if i % 2 == 0:
            draw.rectangle([0, y, bw, y + band_h - 1], fill=(0, 0, 0, 255))
            draw.rectangle([W - bw, y, W-1, y + band_h - 1], fill=(0, 0, 0, 255))
        else:
            draw.rectangle([0, y, bw + 20, y + band_h - 1], fill=(0, 0, 0, 255))
            draw.rectangle([W - bw - 20, y, W-1, y + band_h - 1], fill=(0, 0, 0, 255))
    # Pokeball silhouette in center
    cx, cy = W//2, H//2
    draw.ellipse([cx-20, cy-20, cx+20, cy+20], outline=(255, 255, 255, 200), width=2)
    draw.line([(cx-20, cy), (cx+20, cy)], fill=(255, 255, 255, 200), width=2)
    draw.ellipse([cx-5, cy-5, cx+5, cy+5], outline=(255, 255, 255, 200), width=2)
    img.save(os.path.join(TRANS_DIR, "wild_encounter_01.png"))
    print("  wild_encounter_01.png saved")

def gen_trainer_encounter():
    """Trainer battle: two diagonal bands + VS text area."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    # Diagonal split
    # Left side (player) - dark blue
    pts_left = [(0, 0), (W//2 + 30, 0), (W//2 - 30, H), (0, H)]
    draw.polygon(pts_left, fill=(20, 30, 60, 255))
    # Right side (enemy) - dark red
    pts_right = [(W//2 + 30, 0), (W, 0), (W, H), (W//2 - 30, H)]
    draw.polygon(pts_right, fill=(60, 20, 20, 255))
    # VS circle in center
    cx, cy = W//2, H//2
    draw.ellipse([cx-25, cy-25, cx+25, cy+25], fill=(200, 170, 50, 255))
    draw.ellipse([cx-22, cy-22, cx+22, cy+22], fill=(180, 150, 40, 255))
    # V and S letters (simple pixel art)
    # V
    for i in range(8):
        draw.point((cx-8+i, cy-6+abs(i-4)), fill=(255, 255, 255, 255))
        draw.point((cx-8+i, cy-5+abs(i-4)), fill=(255, 255, 255, 255))
    # S - simplified
    draw.rectangle([cx+2, cy-7, cx+9, cy-5], fill=(255, 255, 255, 255))
    draw.rectangle([cx+2, cy-5, cx+4, cy-1], fill=(255, 255, 255, 255))
    draw.rectangle([cx+2, cy-2, cx+9, cy+0], fill=(255, 255, 255, 255))
    draw.rectangle([cx+7, cy+0, cx+9, cy+4], fill=(255, 255, 255, 255))
    draw.rectangle([cx+2, cy+4, cx+9, cy+6], fill=(255, 255, 255, 255))
    # Light streaks
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        ex = cx + int(math.cos(rad) * 40)
        ey = cy + int(math.sin(rad) * 40)
        draw.line([(cx + int(math.cos(rad)*28), cy + int(math.sin(rad)*28)),
                   (ex, ey)], fill=(255, 220, 100, 100), width=1)
    img.save(os.path.join(TRANS_DIR, "trainer_encounter_01.png"))
    print("  trainer_encounter_01.png saved")

def gen_gym_encounter():
    """Gym battle: golden flash + badge silhouette."""
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    gold = hex2rgb("#F5C632")
    # Radial golden glow from center
    cx, cy = W//2, H//2
    for r in range(120, 0, -1):
        alpha = int(180 * (1 - r/120))
        t = r / 120
        c = lerp_color(gold, (0, 0, 0), t * 0.8)
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(*c, alpha))
    # Badge octagon
    badge_pts = []
    for i in range(8):
        angle = math.radians(i * 45 - 22.5)
        bx = cx + int(math.cos(angle) * 30)
        by = cy + int(math.sin(angle) * 30)
        badge_pts.append((bx, by))
    draw.polygon(badge_pts, fill=(*gold, 220), outline=(255, 240, 180, 255))
    # Inner badge detail
    inner_pts = []
    for i in range(8):
        angle = math.radians(i * 45 - 22.5)
        bx = cx + int(math.cos(angle) * 18)
        by = cy + int(math.sin(angle) * 18)
        inner_pts.append((bx, by))
    draw.polygon(inner_pts, fill=(200, 160, 40, 230))
    # Star in center
    for angle in range(0, 360, 72):
        rad = math.radians(angle)
        sx = cx + int(math.cos(rad) * 10)
        sy = cy + int(math.sin(rad) * 10)
        draw.line([(cx, cy), (sx, sy)], fill=(255, 255, 220, 255), width=2)
    img.save(os.path.join(TRANS_DIR, "gym_encounter_01.png"))
    print("  gym_encounter_01.png saved")

gen_wild_encounter()
gen_trainer_encounter()
gen_gym_encounter()

# =================================================================
# GYM INTROS (1 portrait per leader, 320x240)
# =================================================================
GYM_DIR = "assets/cinematics/gym_intros"
os.makedirs(GYM_DIR, exist_ok=True)

leaders = [
    ("pierre", "Pierre", "Badge Roche", hex2rgb("#795548"), hex2rgb("#8D6E63"), hex2rgb("#5D4037")),
    ("flora", "Flora", "Badge Plante", hex2rgb("#66BB6A"), hex2rgb("#81C784"), hex2rgb("#388E3C")),
    ("ondine", "Ondine", "Badge Cascade", hex2rgb("#42A5F5"), hex2rgb("#64B5F6"), hex2rgb("#1E88E5")),
    ("major_bob", "Major Bob", "Badge Foudre", hex2rgb("#FDD835"), hex2rgb("#FFEE58"), hex2rgb("#F9A825")),
    ("erika", "Erika", "Badge Prisme", hex2rgb("#AB47BC"), hex2rgb("#CE93D8"), hex2rgb("#7B1FA2")),
    ("koga", "Koga", "Badge Ame", hex2rgb("#7E57C2"), hex2rgb("#9575CD"), hex2rgb("#512DA8")),
    ("auguste", "Auguste", "Badge Volcan", hex2rgb("#EF5350"), hex2rgb("#E57373"), hex2rgb("#C62828")),
    ("giovanni", "Giovanni", "Badge Terre", hex2rgb("#8D6E63"), hex2rgb("#A1887F"), hex2rgb("#4E342E")),
]

for lid, lname, badge, main_c, light_c, dark_c in leaders:
    random.seed(42 + hash(lid))
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # Background: dark gradient with type color accent
    draw_gradient(draw, 0, 0, W, H, (15, 12, 25), dark_c)

    # Vertical light streaks
    for _ in range(12):
        sx = random.randint(0, W-1)
        sw = random.randint(2, 8)
        sa = random.randint(20, 60)
        draw.rectangle([sx, 0, sx+sw, H-1], fill=(*light_c, sa))

    # Leader silhouette (large centered figure)
    cx, cy = W//2, H//2 - 10
    # Body
    draw.rectangle([cx-25, cy+10, cx+25, cy+80], fill=(*dark_c, 200))
    # Shoulders
    draw.rectangle([cx-35, cy+15, cx+35, cy+30], fill=(*main_c, 200))
    # Head
    draw.ellipse([cx-18, cy-25, cx+18, cy+12], fill=(*light_c, 200))
    # Face shadow
    draw.ellipse([cx-14, cy-20, cx+14, cy+8], fill=(*main_c, 180))
    # Eyes (glowing)
    draw.rectangle([cx-10, cy-8, cx-5, cy-4], fill=(255, 255, 255, 220))
    draw.rectangle([cx+5, cy-8, cx+10, cy-4], fill=(255, 255, 255, 220))
    draw.point((cx-8, cy-6), fill=(*dark_c, 255))
    draw.point((cx+7, cy-6), fill=(*dark_c, 255))

    # Badge icon (bottom right)
    bx, by = W - 40, H - 40
    badge_pts = []
    for i in range(8):
        angle = math.radians(i * 45 - 22.5)
        px_b = bx + int(math.cos(angle) * 15)
        py_b = by + int(math.sin(angle) * 15)
        badge_pts.append((px_b, py_b))
    draw.polygon(badge_pts, fill=(*main_c, 230), outline=(*light_c, 255))

    # Gold text area at bottom
    gold = hex2rgb("#F5C632")
    draw.rectangle([0, H-35, W-1, H-1], fill=(0, 0, 0, 180))
    draw.line([(0, H-35), (W-1, H-35)], fill=(*gold, 200), width=2)
    # Simulated text: name line (pixel blocks)
    name_x = 15
    for i, ch in enumerate(lname):
        # Each "character" is a 5x7 block
        draw.rectangle([name_x + i*7, H-28, name_x + i*7 + 5, H-21], fill=(*gold, 230))
    # Badge subtitle
    for i, ch in enumerate(badge):
        draw.rectangle([name_x + i*5, H-16, name_x + i*5 + 3, H-11], fill=(200, 200, 210, 180))

    img.save(os.path.join(GYM_DIR, f"{lid}_intro.png"))
    print(f"  {lid}_intro.png saved")

print(f"Done: {len(leaders)} gym intros generated")

# =================================================================
# STORY FRAMES (intro sequence: 5 frames)
# =================================================================
STORY_DIR = "assets/cinematics/story"
os.makedirs(STORY_DIR, exist_ok=True)

def gen_story_intro():
    """5 intro story frames."""
    frames = [
        ("Noir total + titre", (0, 0, 0), "title"),
        ("Monde Pokemon - prairie", hex2rgb("#4D9438"), "world"),
        ("Professeur Chen - labo", hex2rgb("#C0B8A0"), "professor"),
        ("Trois starters", hex2rgb("#F5F0E0"), "starters"),
        ("Route 1 - aventure", hex2rgb("#73B3F2"), "adventure"),
    ]

    for i, (desc, bg, ftype) in enumerate(frames):
        random.seed(42 + i)
        bg_rgba = (bg[0], bg[1], bg[2], 255) if isinstance(bg, tuple) else (bg, bg, bg, 255)
        img = Image.new("RGBA", (W, H), bg_rgba)
        draw = ImageDraw.Draw(img)

        if ftype == "title":
            # Title screen: dark with logo area
            draw_gradient(draw, 0, 0, W, H, (5, 5, 15), (15, 15, 40))
            # Stars
            for _ in range(40):
                sx, sy = random.randint(0, W-1), random.randint(0, H//2)
                sa = random.randint(100, 255)
                draw.point((sx, sy), fill=(255, 255, 255, sa))
            # Title block (gold)
            gold = hex2rgb("#F5C632")
            ty = H//3
            draw.rectangle([40, ty-15, W-40, ty+15], fill=(*gold, 220))
            draw.rectangle([42, ty-13, W-42, ty+13], fill=(20, 20, 40, 255))
            # "POKEMON AMSO" simulated
            for j in range(12):
                draw.rectangle([55 + j*18, ty-8, 55 + j*18 + 14, ty+8], fill=(*gold, 200))
            # Tagline area
            for j in range(15):
                draw.rectangle([70 + j*12, ty+30, 70 + j*12 + 8, ty+38], fill=(180, 180, 200, 150))

        elif ftype == "world":
            # World overview: green field + sky
            draw_gradient(draw, 0, 0, W, H//2, hex2rgb("#73B3F2"), hex2rgb("#A0D0F0"))
            noise_fill(draw, 0, H//2, W, H//2, bg, 10)
            # Distant mountains
            for mx in range(0, W, 3):
                mh = int(30 * math.sin(mx * 0.02) + 25 * math.sin(mx * 0.05 + 1))
                mh = max(5, mh)
                mc = lerp_color(hex2rgb("#6090B0"), hex2rgb("#80A0C0"), (mx % 50) / 50)
                draw.line([(mx, H//2 - mh), (mx, H//2)], fill=(*mc, 180))
            # Pokemon silhouettes
            for px_s, py_s, pr in [(80, 160, 12), (200, 150, 15), (260, 170, 10)]:
                draw.ellipse([px_s-pr, py_s-pr, px_s+pr, py_s+pr], fill=(40, 80, 40, 150))

        elif ftype == "professor":
            # Lab interior
            draw_gradient(draw, 0, 0, W, H, hex2rgb("#D0C8B0"), hex2rgb("#A09880"))
            # Lab equipment (tables, shelves)
            draw.rectangle([0, H-60, W-1, H-1], fill=(100, 90, 75, 255))  # floor
            draw.rectangle([20, H//2, 80, H-60], fill=(140, 130, 115, 255))  # table
            draw.rectangle([200, H//2-20, 280, H-60], fill=(120, 110, 95, 255))  # shelf
            # Books on shelf
            for bx in range(205, 275, 8):
                bc = random.choice([(180, 50, 50), (50, 100, 180), (50, 150, 80), (180, 150, 50)])
                draw.rectangle([bx, H//2-15, bx+6, H//2+10], fill=(*bc, 255))
            # Professor silhouette (center)
            cx_p, cy_p = W//2, H//2 + 10
            draw.ellipse([cx_p-12, cy_p-30, cx_p+12, cy_p-5], fill=(200, 195, 190, 250))  # head
            draw.rectangle([cx_p-18, cy_p-5, cx_p+18, cy_p+40], fill=(240, 240, 235, 250))  # coat

        elif ftype == "starters":
            # Three starters on display
            draw_gradient(draw, 0, 0, W, H, hex2rgb("#F8F4E8"), hex2rgb("#E8E0D0"))
            # Three pokeballs
            positions = [(80, H//2+20), (160, H//2+20), (240, H//2+20)]
            starter_colors = [hex2rgb("#4CAF50"), hex2rgb("#F44336"), hex2rgb("#2196F3")]
            for (px_s, py_s), sc in zip(positions, starter_colors):
                # Pedestal
                draw.rectangle([px_s-20, py_s+15, px_s+20, py_s+25], fill=(180, 175, 165, 255))
                # Pokeball
                draw.ellipse([px_s-12, py_s-12, px_s+12, py_s+12], fill=(220, 50, 50, 255))
                draw.rectangle([px_s-12, py_s-1, px_s+12, py_s+1], fill=(30, 30, 30, 255))
                draw.ellipse([px_s-12, py_s, px_s+12, py_s+12], fill=(220, 220, 220, 255))
                draw.ellipse([px_s-4, py_s-4, px_s+4, py_s+4], fill=(30, 30, 30, 255))
                draw.ellipse([px_s-2, py_s-2, px_s+2, py_s+2], fill=(255, 255, 255, 255))
                # Glow
                draw.ellipse([px_s-18, py_s-18, px_s+18, py_s+18], outline=(*sc, 100))
            # "Choose your partner" text area
            for j in range(20):
                draw.rectangle([60 + j*10, 30, 60 + j*10 + 7, 40], fill=(80, 70, 60, 180))

        elif ftype == "adventure":
            # Route 1: sky + path leading away
            draw_gradient(draw, 0, 0, W, H*2//3, hex2rgb("#73B3F2"), hex2rgb("#A8D8F0"))
            noise_fill(draw, 0, H*2//3, W, H//3, hex2rgb("#4D9438"), 10)
            # Path (perspective)
            for py_a in range(H*2//3, H):
                t = (py_a - H*2//3) / (H//3)
                pw = int(20 + t * 60)  # wider at bottom
                pc = lerp_color(hex2rgb("#B8A070"), hex2rgb("#A09060"), t)
                draw.rectangle([W//2-pw//2, py_a, W//2+pw//2, py_a], fill=(*pc, 255))
            # Player silhouette walking away
            px_p, py_p = W//2, H*2//3 + 10
            draw.rectangle([px_p-4, py_p-12, px_p+4, py_p], fill=(30, 30, 40, 200))
            draw.ellipse([px_p-3, py_p-17, px_p+3, py_p-11], fill=(200, 180, 160, 200))
            # Red cap
            draw.rectangle([px_p-3, py_p-18, px_p+3, py_p-15], fill=(220, 50, 50, 200))

        img.save(os.path.join(STORY_DIR, f"intro_{i+1:02d}.png"))
        print(f"  intro_{i+1:02d}.png saved")

gen_story_intro()
print("Done: 5 story frames generated")

# =================================================================
# MEGA EVOLUTION (Charizard X: 8 frames 320x240)
# =================================================================
MEGA_DIR = "assets/cinematics/mega_evolutions"
os.makedirs(MEGA_DIR, exist_ok=True)

def gen_mega_charizard_x():
    """8 frames of mega evolution sequence for Charizard (006_mega_x)."""
    for frame_i in range(1, 9):
        random.seed(42 + frame_i)
        img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
        draw = ImageDraw.Draw(img)

        progress = frame_i / 8.0  # 0.125 to 1.0
        cx, cy = W//2, H//2

        if frame_i <= 2:
            # Frames 1-2: Pokemon centered + mega stone glow begins
            draw_gradient(draw, 0, 0, W, H, (10, 5, 20), (20, 10, 35))
            # Pokemon silhouette
            draw.ellipse([cx-25, cy-20, cx+25, cy+25], fill=(60, 40, 30, 250))
            draw.polygon([(cx-15, cy-20), (cx, cy-35), (cx+15, cy-20)], fill=(60, 40, 30, 250))  # head crest
            # Mega stone glow
            glow_r = int(10 + progress * 30)
            glow_a = int(50 + progress * 100)
            gold = hex2rgb("#F5C632")
            draw.ellipse([cx-glow_r, cy+35-glow_r//2, cx+glow_r, cy+35+glow_r//2],
                        fill=(*gold, glow_a))

        elif frame_i <= 4:
            # Frames 3-4: Energy swirl
            draw_gradient(draw, 0, 0, W, H, (20, 10, 40), (40, 15, 60))
            # Energy rays
            for angle in range(0, 360, 15):
                rad = math.radians(angle + frame_i * 20)
                ray_len = 60 + random.randint(0, 40)
                ex = cx + int(math.cos(rad) * ray_len)
                ey = cy + int(math.sin(rad) * ray_len)
                rc = random.choice([(255, 200, 50), (255, 150, 30), (255, 100, 20)])
                draw.line([(cx, cy), (ex, ey)], fill=(*rc, 150), width=2)
            # Pokemon silhouette growing
            scale = 1.0 + (progress - 0.25) * 1.5
            r = int(25 * scale)
            draw.ellipse([cx-r, cy-int(r*0.8), cx+r, cy+r], fill=(40, 20, 20, 220))

        elif frame_i <= 6:
            # Frames 5-6: Transformation flash
            flash_intensity = 255 if frame_i == 5 else 180
            draw.rectangle([0, 0, W-1, H-1], fill=(255, 255, 255, flash_intensity))
            # Blue flames (Charizard X)
            for _ in range(30):
                fx_f = random.randint(cx-50, cx+50)
                fy_f = random.randint(cy-40, cy+40)
                fs = random.randint(3, 10)
                fc = random.choice([(40, 100, 255), (60, 140, 255), (20, 80, 220)])
                draw.ellipse([fx_f-fs, fy_f-fs, fx_f+fs, fy_f+fs], fill=(*fc, 200))
            # New form silhouette
            draw.ellipse([cx-30, cy-25, cx+30, cy+30], fill=(30, 30, 50, 200))
            # Wings
            draw.polygon([(cx-30, cy), (cx-60, cy-30), (cx-45, cy+10)], fill=(30, 30, 50, 180))
            draw.polygon([(cx+30, cy), (cx+60, cy-30), (cx+45, cy+10)], fill=(30, 30, 50, 180))

        else:
            # Frames 7-8: New form revealed + text
            draw_gradient(draw, 0, 0, W, H, (10, 15, 40), (20, 25, 60))
            # Blue aura
            for r in range(60, 0, -2):
                a = int(80 * (1 - r/60))
                draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(40, 100, 255, a))
            # Mega Charizard X silhouette
            # Body
            draw.ellipse([cx-28, cy-20, cx+28, cy+28], fill=(30, 30, 50, 250))
            # Wings
            draw.polygon([(cx-28, cy-5), (cx-65, cy-35), (cx-50, cy+15)], fill=(35, 35, 55, 240))
            draw.polygon([(cx+28, cy-5), (cx+65, cy-35), (cx+50, cy+15)], fill=(35, 35, 55, 240))
            # Head
            draw.ellipse([cx-15, cy-30, cx+15, cy-10], fill=(30, 30, 50, 250))
            # Blue flames from mouth
            for _ in range(10):
                ffx = cx + random.randint(-5, 5)
                ffy = cy - 25 + random.randint(-8, -2)
                draw.ellipse([ffx-3, ffy-3, ffx+3, ffy+3], fill=(60, 140, 255, 200))
            # Eyes
            draw.rectangle([cx-10, cy-24, cx-6, cy-20], fill=(255, 50, 50, 255))
            draw.rectangle([cx+6, cy-24, cx+10, cy-20], fill=(255, 50, 50, 255))
            # "MEGA EVOLUTION" text area (frame 8 only)
            if frame_i == 8:
                gold = hex2rgb("#F5C632")
                draw.rectangle([40, H-45, W-40, H-20], fill=(0, 0, 0, 180))
                draw.rectangle([42, H-43, W-42, H-22], outline=(*gold, 200))
                for j in range(14):
                    draw.rectangle([55 + j*16, H-38, 55 + j*16 + 12, H-27], fill=(*gold, 220))

        img.save(os.path.join(MEGA_DIR, f"006_mega_x_{frame_i:02d}.png"))
        print(f"  006_mega_x_{frame_i:02d}.png saved")

gen_mega_charizard_x()
print("Done: 8 mega evolution frames generated")
print("\n=== ALL CINEMATICS COMPLETE ===")
