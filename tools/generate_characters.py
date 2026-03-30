#!/usr/bin/env python3
"""Generate pixel art character spritesheets for Pokemon AMSO.
Each character: 4 directions × 3 frames (idle, walk1, walk2) = 12 frames.
Frame size: 16×16 pixels.
Spritesheet: 48×64 (3 cols × 4 rows).
"""

from PIL import Image, ImageDraw
import os

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "sprites", "characters")
FRAME_W, FRAME_H = 16, 16

# ── Color palettes ───────────────────────────────────────────────

SKIN = (248, 208, 168)
SKIN_DARK = (216, 168, 128)

# Character definitions: (name, hair_color, shirt_color, pants_color, shoe_color)
CHARACTERS = {
    # Player
    "player": ((40, 40, 48), (56, 120, 216), (40, 56, 96), (80, 64, 48)),
    # NPCs
    "nurse": ((232, 96, 128), (248, 248, 248), (248, 200, 200), (248, 120, 120)),
    "shopkeeper": ((56, 120, 56), (96, 176, 96), (80, 80, 96), (72, 56, 40)),
    "prof": ((200, 184, 168), (248, 240, 224), (144, 128, 104), (96, 80, 56)),
    "guide": ((88, 72, 56), (120, 120, 176), (72, 72, 104), (64, 48, 32)),
    # Trainers
    "youngster": ((88, 72, 48), (248, 176, 56), (96, 80, 56), (80, 64, 48)),
    "lass": ((160, 80, 56), (248, 120, 152), (120, 56, 80), (88, 56, 40)),
    "bugcatcher": ((72, 96, 48), (168, 200, 120), (96, 112, 72), (72, 56, 40)),
    "hiker": ((120, 88, 56), (168, 136, 88), (112, 88, 56), (96, 72, 48)),
    "beauty": ((216, 176, 80), (200, 80, 120), (160, 56, 88), (120, 48, 64)),
    "psychic": ((128, 80, 176), (176, 120, 216), (104, 64, 144), (80, 48, 112)),
    "swimmer": ((56, 96, 168), (64, 160, 224), (56, 128, 192), (48, 88, 144)),
    "juggler": ((200, 56, 56), (248, 200, 56), (176, 40, 40), (96, 32, 32)),
    "tamer": ((56, 48, 40), (168, 56, 48), (88, 40, 32), (56, 40, 32)),
    "channeler": ((88, 56, 120), (144, 104, 176), (96, 64, 128), (72, 48, 96)),
    # Gym leaders
    "leader_rock": ((120, 96, 64), (160, 128, 80), (112, 88, 56), (88, 72, 48)),
    "leader_water": ((48, 128, 200), (96, 192, 248), (48, 112, 176), (40, 80, 136)),
    "leader_electric": ((248, 216, 56), (248, 200, 80), (176, 144, 40), (128, 104, 32)),
    "leader_grass": ((56, 160, 72), (120, 208, 120), (48, 128, 56), (40, 96, 40)),
    "leader_psychic": ((200, 120, 224), (224, 160, 248), (160, 80, 192), (120, 56, 152)),
    "leader_poison": ((136, 56, 176), (168, 88, 208), (112, 40, 144), (88, 32, 112)),
    "leader_fire": ((248, 120, 40), (248, 168, 80), (200, 88, 24), (152, 64, 16)),
    "leader_ground": ((168, 136, 88), (200, 168, 112), (136, 104, 64), (104, 80, 48)),
    # Rival
    "rival": ((56, 48, 120), (96, 80, 168), (56, 48, 112), (48, 40, 88)),
    # League gate
    "guard": ((56, 56, 72), (128, 128, 152), (72, 72, 96), (56, 56, 72)),
}


def draw_character(draw_ctx, x, y, direction, frame, hair_col, shirt_col, pants_col, shoe_col):
    """Draw a 16×16 character frame.
    direction: 0=down, 1=up, 2=left, 3=right
    frame: 0=idle, 1=walk_left, 2=walk_right
    """
    d = draw_ctx
    # Leg animation offset
    leg_shift = 0
    if frame == 1:
        leg_shift = -1
    elif frame == 2:
        leg_shift = 1

    # Body sway for walk frames
    body_x = x + 4
    if frame == 1:
        body_x = x + 3
    elif frame == 2:
        body_x = x + 5

    # ── Hair / Head ──
    # Head is 8×7 pixels at top
    head_x = body_x
    head_y = y + 1

    # Hair (top of head)
    d.rectangle([head_x, head_y, head_x + 7, head_y + 2], fill=hair_col)

    # Face
    d.rectangle([head_x, head_y + 3, head_x + 7, head_y + 6], fill=SKIN)

    # Face features based on direction
    if direction == 0:  # Down - facing camera
        # Eyes
        d.point((head_x + 2, head_y + 4), fill=(40, 40, 56))
        d.point((head_x + 5, head_y + 4), fill=(40, 40, 56))
        # Hair bangs
        d.point((head_x, head_y + 3), fill=hair_col)
        d.point((head_x + 7, head_y + 3), fill=hair_col)
    elif direction == 1:  # Up - back of head
        d.rectangle([head_x, head_y + 3, head_x + 7, head_y + 6], fill=hair_col)
        # Slight skin peek at bottom
        d.rectangle([head_x + 1, head_y + 6, head_x + 6, head_y + 6], fill=SKIN_DARK)
    elif direction == 2:  # Left
        d.point((head_x + 1, head_y + 4), fill=(40, 40, 56))
        d.rectangle([head_x + 5, head_y + 3, head_x + 7, head_y + 6], fill=hair_col)
    elif direction == 3:  # Right
        d.point((head_x + 6, head_y + 4), fill=(40, 40, 56))
        d.rectangle([head_x, head_y + 3, head_x + 2, head_y + 6], fill=hair_col)

    # ── Torso ──
    torso_y = y + 8
    d.rectangle([body_x + 1, torso_y, body_x + 6, torso_y + 3], fill=shirt_col)
    # Arms
    if frame == 0:
        d.rectangle([body_x, torso_y, body_x, torso_y + 2], fill=shirt_col)
        d.rectangle([body_x + 7, torso_y, body_x + 7, torso_y + 2], fill=shirt_col)
        # Hands
        d.point((body_x, torso_y + 3), fill=SKIN)
        d.point((body_x + 7, torso_y + 3), fill=SKIN)
    elif frame == 1:
        d.point((body_x - 1, torso_y + 1), fill=shirt_col)
        d.rectangle([body_x + 7, torso_y, body_x + 7, torso_y + 2], fill=shirt_col)
        d.point((body_x - 1, torso_y + 2), fill=SKIN)
        d.point((body_x + 7, torso_y + 3), fill=SKIN)
    else:
        d.rectangle([body_x, torso_y, body_x, torso_y + 2], fill=shirt_col)
        d.point((body_x + 8, torso_y + 1), fill=shirt_col)
        d.point((body_x, torso_y + 3), fill=SKIN)
        d.point((body_x + 8, torso_y + 2), fill=SKIN)

    # ── Legs ──
    leg_y = y + 12
    if frame == 0:  # Idle - legs together
        d.rectangle([body_x + 2, leg_y, body_x + 3, leg_y + 2], fill=pants_col)
        d.rectangle([body_x + 4, leg_y, body_x + 5, leg_y + 2], fill=pants_col)
        # Shoes
        d.rectangle([body_x + 2, leg_y + 3, body_x + 3, leg_y + 3], fill=shoe_col)
        d.rectangle([body_x + 4, leg_y + 3, body_x + 5, leg_y + 3], fill=shoe_col)
    elif frame == 1:  # Walk - left leg forward
        d.rectangle([body_x + 1 + leg_shift, leg_y, body_x + 2 + leg_shift, leg_y + 2], fill=pants_col)
        d.rectangle([body_x + 4, leg_y, body_x + 5, leg_y + 1], fill=pants_col)
        d.rectangle([body_x + 1 + leg_shift, leg_y + 3, body_x + 2 + leg_shift, leg_y + 3], fill=shoe_col)
        d.rectangle([body_x + 4, leg_y + 2, body_x + 5, leg_y + 2], fill=shoe_col)
    else:  # Walk - right leg forward
        d.rectangle([body_x + 2, leg_y, body_x + 3, leg_y + 1], fill=pants_col)
        d.rectangle([body_x + 4 + leg_shift, leg_y, body_x + 5 + leg_shift, leg_y + 2], fill=pants_col)
        d.rectangle([body_x + 2, leg_y + 2, body_x + 3, leg_y + 2], fill=shoe_col)
        d.rectangle([body_x + 4 + leg_shift, leg_y + 3, body_x + 5 + leg_shift, leg_y + 3], fill=shoe_col)


def generate_spritesheet(name, colors):
    """Generate a 48×64 spritesheet (3 frames × 4 directions)."""
    hair, shirt, pants, shoes = colors
    img = Image.new("RGBA", (FRAME_W * 3, FRAME_H * 4), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    for direction in range(4):  # down, up, left, right
        for frame in range(3):  # idle, walk1, walk2
            fx = frame * FRAME_W
            fy = direction * FRAME_H
            draw_character(d, fx, fy, direction, frame, hair, shirt, pants, shoes)

    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    img.save(path)
    return path


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    count = 0
    for name, colors in CHARACTERS.items():
        path = generate_spritesheet(name, colors)
        count += 1

    print(f"Generated {count} character spritesheets in {OUTPUT_DIR}")

    # Generate a reference file
    ref_path = os.path.join(OUTPUT_DIR, "characters.txt")
    with open(ref_path, "w") as f:
        f.write("CHARACTER SPRITESHEETS\n")
        f.write(f"Frame size: {FRAME_W}x{FRAME_H}\n")
        f.write(f"Layout: 3 columns (idle, walk1, walk2) x 4 rows (down, up, left, right)\n\n")
        for name in sorted(CHARACTERS.keys()):
            f.write(f"  {name}.png\n")
    print(f"Reference: {ref_path}")


if __name__ == "__main__":
    main()
