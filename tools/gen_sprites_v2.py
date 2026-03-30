#!/usr/bin/env python3
"""Generate overworld character spritesheets (48x128, 16x32 frames, 3 cols x 4 rows).
Clean pixel art with distinct silhouettes — GBA Pokemon style.
Each character has: head (8-10px), torso (6-8px), legs (8-10px), feet (2px).
"""
from PIL import Image
import os

OUT = "assets/sprites/overworld"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    return tuple(int(h.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))

def put(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), (*c, 255))

def fill(img, x, y, w, h, c):
    for py in range(y, y+h):
        for px in range(x, x+w):
            put(img, px, py, c)

def draw_char(filename, palette):
    """
    palette = {skin, skin_dark, hair, hat (optional), top, top_dark, bottom, bottom_dark, shoes, outline}
    Layout: 48x128 = 3 frames x 4 directions, 16x32 each
    Directions: 0=down, 1=left, 2=right, 3=up
    """
    img = Image.new("RGBA", (48, 128), (0, 0, 0, 0))
    P = palette
    outline = P.get('outline', (30, 25, 35))

    for dir_idx in range(4):
        for frame in range(3):
            fx = frame * 16
            fy = dir_idx * 32

            # Animation: walk cycle leg/arm offsets
            walk_phase = 0  # 0=idle, 1=step_left, 2=step_right
            if frame == 1: walk_phase = 1
            elif frame == 2: walk_phase = 2

            leg_l_dy = -1 if walk_phase == 1 else (1 if walk_phase == 2 else 0)
            leg_r_dy = 1 if walk_phase == 1 else (-1 if walk_phase == 2 else 0)

            if dir_idx == 0:  # DOWN — face visible
                # === HEAD (y+4 to y+14) ===
                # Hair top
                fill(img, fx+4, fy+4, 8, 3, P['hair'])
                fill(img, fx+3, fy+5, 10, 2, P['hair'])
                # Hat (over hair)
                if P.get('hat'):
                    fill(img, fx+3, fy+3, 10, 3, P['hat'])
                    fill(img, fx+2, fy+5, 12, 2, P['hat'])  # brim
                # Face
                fill(img, fx+4, fy+7, 8, 5, P['skin'])
                fill(img, fx+5, fy+6, 6, 1, P['skin'])
                # Eyes
                put(img, fx+5, fy+9, outline)
                put(img, fx+6, fy+9, outline)
                put(img, fx+9, fy+9, outline)
                put(img, fx+10, fy+9, outline)
                # Mouth
                put(img, fx+7, fy+11, P['skin_dark'])
                put(img, fx+8, fy+11, P['skin_dark'])
                # === BODY (y+12 to y+22) ===
                fill(img, fx+4, fy+12, 8, 7, P['top'])
                fill(img, fx+5, fy+13, 6, 5, P['top'])
                # Arms
                fill(img, fx+3, fy+13, 1, 5, P['top'])
                fill(img, fx+12, fy+13, 1, 5, P['top'])
                # Arm offset for walk
                if walk_phase == 1:
                    put(img, fx+3, fy+12, P['top'])
                    put(img, fx+12, fy+14, P['top'])
                elif walk_phase == 2:
                    put(img, fx+3, fy+14, P['top'])
                    put(img, fx+12, fy+12, P['top'])
                # Hands (skin)
                put(img, fx+3, fy+18, P['skin'])
                put(img, fx+12, fy+18, P['skin'])
                # Top detail
                fill(img, fx+5, fy+13, 6, 1, P['top_dark'])
                # === LEGS (y+19 to y+27) ===
                fill(img, fx+5, fy+19, 3, 7+leg_l_dy, P['bottom'])
                fill(img, fx+8, fy+19, 3, 7+leg_r_dy, P['bottom'])
                # Leg shadow
                fill(img, fx+5, fy+19, 1, 5, P['bottom_dark'])
                fill(img, fx+10, fy+19, 1, 5, P['bottom_dark'])
                # === SHOES ===
                fill(img, fx+4, fy+26+leg_l_dy, 4, 2, P['shoes'])
                fill(img, fx+8, fy+26+leg_r_dy, 4, 2, P['shoes'])
                # Outline bottom
                for ox in range(4, 12):
                    oy = fy+28+max(leg_l_dy, leg_r_dy)
                    if oy < fy+32:
                        put(img, fx+ox, min(oy, fy+31), outline)

            elif dir_idx == 3:  # UP — back view
                # Hair (covers whole head from behind)
                fill(img, fx+4, fy+4, 8, 8, P['hair'])
                fill(img, fx+3, fy+5, 10, 6, P['hair'])
                if P.get('hat'):
                    fill(img, fx+3, fy+3, 10, 4, P['hat'])
                # Neck
                fill(img, fx+6, fy+12, 4, 1, P['skin'])
                # Body
                fill(img, fx+4, fy+12, 8, 7, P['top'])
                fill(img, fx+3, fy+13, 1, 5, P['top'])
                fill(img, fx+12, fy+13, 1, 5, P['top'])
                fill(img, fx+5, fy+14, 6, 4, P['top_dark'])
                # Legs
                fill(img, fx+5, fy+19, 3, 7+leg_l_dy, P['bottom'])
                fill(img, fx+8, fy+19, 3, 7+leg_r_dy, P['bottom'])
                # Shoes
                fill(img, fx+4, fy+26+leg_l_dy, 4, 2, P['shoes'])
                fill(img, fx+8, fy+26+leg_r_dy, 4, 2, P['shoes'])

            elif dir_idx == 1:  # LEFT
                # Hair side
                fill(img, fx+5, fy+4, 6, 3, P['hair'])
                fill(img, fx+4, fy+5, 7, 4, P['hair'])
                if P.get('hat'):
                    fill(img, fx+3, fy+3, 8, 3, P['hat'])
                # Face (partial)
                fill(img, fx+4, fy+7, 5, 5, P['skin'])
                fill(img, fx+5, fy+6, 4, 1, P['skin'])
                put(img, fx+4, fy+9, outline)  # eye
                put(img, fx+5, fy+9, outline)
                # Hair cover on right side
                fill(img, fx+8, fy+5, 3, 5, P['hair'])
                # Body (narrower from side)
                fill(img, fx+5, fy+12, 6, 7, P['top'])
                fill(img, fx+4, fy+13, 1, 5, P['top'])
                put(img, fx+4, fy+18, P['skin'])  # hand
                # Walk arm offset
                if walk_phase == 1:
                    put(img, fx+4, fy+12, P['top'])
                elif walk_phase == 2:
                    put(img, fx+4, fy+14, P['top'])
                # Legs
                fill(img, fx+5, fy+19, 3, 7+leg_l_dy, P['bottom'])
                fill(img, fx+7, fy+19, 3, 7+leg_r_dy, P['bottom_dark'])
                # Shoes
                fill(img, fx+4, fy+26+leg_l_dy, 4, 2, P['shoes'])
                fill(img, fx+6, fy+26+leg_r_dy, 4, 2, P['shoes'])

            elif dir_idx == 2:  # RIGHT (mirror of left)
                # Hair side
                fill(img, fx+5, fy+4, 6, 3, P['hair'])
                fill(img, fx+5, fy+5, 7, 4, P['hair'])
                if P.get('hat'):
                    fill(img, fx+5, fy+3, 8, 3, P['hat'])
                # Face
                fill(img, fx+7, fy+7, 5, 5, P['skin'])
                fill(img, fx+7, fy+6, 4, 1, P['skin'])
                put(img, fx+10, fy+9, outline)
                put(img, fx+11, fy+9, outline)
                # Hair left
                fill(img, fx+5, fy+5, 3, 5, P['hair'])
                # Body
                fill(img, fx+5, fy+12, 6, 7, P['top'])
                fill(img, fx+11, fy+13, 1, 5, P['top'])
                put(img, fx+11, fy+18, P['skin'])
                # Walk arm offset
                if walk_phase == 1:
                    put(img, fx+11, fy+14, P['top'])
                elif walk_phase == 2:
                    put(img, fx+11, fy+12, P['top'])
                # Legs
                fill(img, fx+6, fy+19, 3, 7+leg_l_dy, P['bottom_dark'])
                fill(img, fx+8, fy+19, 3, 7+leg_r_dy, P['bottom'])
                # Shoes
                fill(img, fx+6, fy+26+leg_l_dy, 4, 2, P['shoes'])
                fill(img, fx+8, fy+26+leg_r_dy, 4, 2, P['shoes'])

    img.save(os.path.join(OUT, filename))
    print(f"  {filename} saved (48x128)")

# === CHARACTER DEFINITIONS ===
CHARACTERS = [
    ("player.png", {
        "skin": hex2rgb("#F0C8A0"), "skin_dark": hex2rgb("#D0A880"),
        "hair": hex2rgb("#282828"), "hat": hex2rgb("#E03030"),
        "top": hex2rgb("#303030"), "top_dark": hex2rgb("#202020"),
        "bottom": hex2rgb("#2060B0"), "bottom_dark": hex2rgb("#184890"),
        "shoes": hex2rgb("#404040"), "outline": hex2rgb("#201818"),
    }),
    ("rival.png", {
        "skin": hex2rgb("#F0C8A0"), "skin_dark": hex2rgb("#D0A880"),
        "hair": hex2rgb("#2870C0"), "hat": None,
        "top": hex2rgb("#607080"), "top_dark": hex2rgb("#485868"),
        "bottom": hex2rgb("#384048"), "bottom_dark": hex2rgb("#283038"),
        "shoes": hex2rgb("#484848"), "outline": hex2rgb("#201818"),
    }),
    ("nurse.png", {
        "skin": hex2rgb("#F8D8C0"), "skin_dark": hex2rgb("#E0B8A0"),
        "hair": hex2rgb("#F088A8"), "hat": hex2rgb("#FFFFFF"),
        "top": hex2rgb("#F098B0"), "top_dark": hex2rgb("#D87898"),
        "bottom": hex2rgb("#F098B0"), "bottom_dark": hex2rgb("#D87898"),
        "shoes": hex2rgb("#FFFFFF"), "outline": hex2rgb("#201818"),
    }),
    ("shopkeeper.png", {
        "skin": hex2rgb("#D8A878"), "skin_dark": hex2rgb("#B88858"),
        "hair": hex2rgb("#503828"), "hat": hex2rgb("#48A050"),
        "top": hex2rgb("#F0F0F0"), "top_dark": hex2rgb("#D0D0D0"),
        "bottom": hex2rgb("#382818"), "bottom_dark": hex2rgb("#282010"),
        "shoes": hex2rgb("#484848"), "outline": hex2rgb("#201818"),
    }),
    ("youngster.png", {
        "skin": hex2rgb("#F0C8A0"), "skin_dark": hex2rgb("#D0A880"),
        "hair": hex2rgb("#886048"), "hat": None,
        "top": hex2rgb("#50A0E0"), "top_dark": hex2rgb("#3880C0"),
        "bottom": hex2rgb("#D0C0A8"), "bottom_dark": hex2rgb("#B0A088"),
        "shoes": hex2rgb("#585858"), "outline": hex2rgb("#201818"),
    }),
    ("lass.png", {
        "skin": hex2rgb("#F8D8C0"), "skin_dark": hex2rgb("#E0B8A0"),
        "hair": hex2rgb("#E06030"), "hat": None,
        "top": hex2rgb("#F0F0F0"), "top_dark": hex2rgb("#D8D8D8"),
        "bottom": hex2rgb("#E04040"), "bottom_dark": hex2rgb("#C03030"),
        "shoes": hex2rgb("#A048B0"), "outline": hex2rgb("#201818"),
    }),
    ("bug_catcher.png", {
        "skin": hex2rgb("#F0C8A0"), "skin_dark": hex2rgb("#D0A880"),
        "hair": hex2rgb("#604838"), "hat": hex2rgb("#C8D830"),
        "top": hex2rgb("#90C040"), "top_dark": hex2rgb("#78A030"),
        "bottom": hex2rgb("#785838"), "bottom_dark": hex2rgb("#604028"),
        "shoes": hex2rgb("#484838"), "outline": hex2rgb("#201818"),
    }),
    ("gym_leader_pierre.png", {
        "skin": hex2rgb("#C8A080"), "skin_dark": hex2rgb("#A88060"),
        "hair": hex2rgb("#503828"), "hat": None,
        "top": hex2rgb("#806040"), "top_dark": hex2rgb("#604830"),
        "bottom": hex2rgb("#483018"), "bottom_dark": hex2rgb("#382010"),
        "shoes": hex2rgb("#382818"), "outline": hex2rgb("#181010"),
    }),
    ("gym_leader_flora.png", {
        "skin": hex2rgb("#F8D8C0"), "skin_dark": hex2rgb("#E0B8A0"),
        "hair": hex2rgb("#388030"), "hat": None,
        "top": hex2rgb("#60B860"), "top_dark": hex2rgb("#489848"),
        "bottom": hex2rgb("#287828"), "bottom_dark": hex2rgb("#206020"),
        "shoes": hex2rgb("#185818"), "outline": hex2rgb("#101808"),
    }),
    ("prof_oak.png", {
        "skin": hex2rgb("#E0C098"), "skin_dark": hex2rgb("#C0A078"),
        "hair": hex2rgb("#989898"), "hat": None,
        "top": hex2rgb("#F0F0F0"), "top_dark": hex2rgb("#D0D0D0"),
        "bottom": hex2rgb("#584838"), "bottom_dark": hex2rgb("#403828"),
        "shoes": hex2rgb("#383030"), "outline": hex2rgb("#201818"),
    }),
]

for filename, palette in CHARACTERS:
    draw_char(filename, palette)

print("Done: 10 overworld spritesheets generated")
