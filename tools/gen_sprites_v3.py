#!/usr/bin/env python3
"""Generate 10 overworld character spritesheets (48x128, 16x32 per frame, 3 cols x 4 rows).
Clean pixel art with dark outline, rounded heads, distinct silhouettes.
Style: Pokemon FireRed/Emerald overworld NPCs.
"""
from PIL import Image
import os

OUT = "assets/sprites/overworld"
os.makedirs(OUT, exist_ok=True)

def h(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))

OUTLINE = h("#1E1A28")

class SpriteSheet:
    def __init__(self):
        self.img = Image.new("RGBA", (48, 128), (0, 0, 0, 0))

    def px(self, x, y, c):
        if 0 <= x < 48 and 0 <= y < 128:
            self.img.putpixel((x, y), (*c, 255))

    def rect(self, x, y, w, hv, c):
        for py in range(y, y + hv):
            for px in range(x, x + w):
                self.px(px, py, c)

    def save(self, name):
        self.img.save(os.path.join(OUT, name))
        print(f"  {name} saved")


def draw_outlined_head(ss, fx, fy, skin, hair, eyes, hat=None, direction="down"):
    """Draw a rounded head with outline. fy is the frame top-left y."""
    o = OUTLINE

    if direction == "down":
        # Hair top (rounded)
        ss.px(fx+6, fy+2, o); ss.px(fx+7, fy+2, hair); ss.px(fx+8, fy+2, hair); ss.px(fx+9, fy+2, o)
        ss.px(fx+5, fy+3, o); ss.px(fx+6, fy+3, hair); ss.px(fx+7, fy+3, hair); ss.px(fx+8, fy+3, hair); ss.px(fx+9, fy+3, hair); ss.px(fx+10, fy+3, o)
        # Face rows
        for row in range(4, 7):
            ss.px(fx+4, fy+row, o)
            for col in range(5, 11):
                ss.px(fx+col, fy+row, skin)
            ss.px(fx+11, fy+row, o)
        # Eyes at row 6
        ss.px(fx+6, fy+6, eyes); ss.px(fx+9, fy+6, eyes)
        # Mouth area
        ss.px(fx+4, fy+7, o)
        for col in range(5, 11):
            ss.px(fx+col, fy+7, skin)
        ss.px(fx+11, fy+7, o)
        # Mouth
        ss.px(fx+7, fy+8, (max(0,skin[0]-25), max(0,skin[1]-25), max(0,skin[2]-20)))
        ss.px(fx+8, fy+8, (max(0,skin[0]-25), max(0,skin[1]-25), max(0,skin[2]-20)))
        # Chin
        ss.px(fx+4, fy+8, o)
        for col in range(5, 11):
            ss.px(fx+col, fy+8, skin)
        ss.px(fx+11, fy+8, o)
        # Chin bottom
        ss.px(fx+5, fy+9, o); ss.px(fx+6, fy+9, skin); ss.px(fx+7, fy+9, skin)
        ss.px(fx+8, fy+9, skin); ss.px(fx+9, fy+9, skin); ss.px(fx+10, fy+9, o)
        # Hat override
        if hat:
            ss.px(fx+5, fy+1, o); ss.px(fx+6, fy+1, hat); ss.px(fx+7, fy+1, hat); ss.px(fx+8, fy+1, hat); ss.px(fx+9, fy+1, hat); ss.px(fx+10, fy+1, o)
            ss.px(fx+4, fy+2, o); ss.px(fx+5, fy+2, hat); ss.px(fx+6, fy+2, hat); ss.px(fx+7, fy+2, hat); ss.px(fx+8, fy+2, hat); ss.px(fx+9, fy+2, hat); ss.px(fx+10, fy+2, hat); ss.px(fx+11, fy+2, o)
            ss.px(fx+5, fy+3, o); ss.px(fx+6, fy+3, hat); ss.px(fx+7, fy+3, hat); ss.px(fx+8, fy+3, hat); ss.px(fx+9, fy+3, hat); ss.px(fx+10, fy+3, o)

    elif direction == "up":
        # Full hair back
        ss.px(fx+6, fy+2, o); ss.px(fx+7, fy+2, hair); ss.px(fx+8, fy+2, hair); ss.px(fx+9, fy+2, o)
        for row in range(3, 9):
            ss.px(fx+4 if row > 3 else 5, fy+row, o)
            for col in range(5 if row <=3 else 5, 11 if row <=3 else 11):
                ss.px(fx+col, fy+row, hair)
            ss.px(fx+11 if row > 3 else 10, fy+row, o)
        ss.px(fx+5, fy+9, o); ss.px(fx+6, fy+9, skin); ss.px(fx+7, fy+9, skin)
        ss.px(fx+8, fy+9, skin); ss.px(fx+9, fy+9, skin); ss.px(fx+10, fy+9, o)
        if hat:
            for row in range(1, 4):
                ss.px(fx+4, fy+row, o)
                for col in range(5, 11):
                    ss.px(fx+col, fy+row, hat)
                ss.px(fx+11, fy+row, o)

    elif direction == "left":
        ss.px(fx+6, fy+2, o); ss.px(fx+7, fy+2, hair); ss.px(fx+8, fy+2, hair); ss.px(fx+9, fy+2, o)
        ss.px(fx+5, fy+3, o); ss.px(fx+6, fy+3, hair); ss.px(fx+7, fy+3, hair); ss.px(fx+8, fy+3, hair); ss.px(fx+9, fy+3, o)
        for row in range(4, 8):
            ss.px(fx+4, fy+row, o)
            ss.px(fx+5, fy+row, skin); ss.px(fx+6, fy+row, skin); ss.px(fx+7, fy+row, skin)
            ss.px(fx+8, fy+row, hair); ss.px(fx+9, fy+row, o)
        ss.px(fx+5, fy+6, eyes)  # eye
        ss.px(fx+5, fy+8, o); ss.px(fx+6, fy+8, skin); ss.px(fx+7, fy+8, skin); ss.px(fx+8, fy+8, o)
        ss.px(fx+6, fy+9, o); ss.px(fx+7, fy+9, skin); ss.px(fx+8, fy+9, o)
        if hat:
            ss.px(fx+4, fy+1, o); ss.px(fx+5, fy+1, hat); ss.px(fx+6, fy+1, hat); ss.px(fx+7, fy+1, hat); ss.px(fx+8, fy+1, hat); ss.px(fx+9, fy+1, o)
            ss.px(fx+3, fy+2, o); ss.px(fx+4, fy+2, hat); ss.px(fx+5, fy+2, hat); ss.px(fx+6, fy+2, hat); ss.px(fx+7, fy+2, hat); ss.px(fx+8, fy+2, hat); ss.px(fx+9, fy+2, o)

    elif direction == "right":
        ss.px(fx+6, fy+2, o); ss.px(fx+7, fy+2, hair); ss.px(fx+8, fy+2, hair); ss.px(fx+9, fy+2, o)
        ss.px(fx+6, fy+3, o); ss.px(fx+7, fy+3, hair); ss.px(fx+8, fy+3, hair); ss.px(fx+9, fy+3, hair); ss.px(fx+10, fy+3, o)
        for row in range(4, 8):
            ss.px(fx+6, fy+row, o)
            ss.px(fx+7, fy+row, hair); ss.px(fx+8, fy+row, skin)
            ss.px(fx+9, fy+row, skin); ss.px(fx+10, fy+row, skin); ss.px(fx+11, fy+row, o)
        ss.px(fx+10, fy+6, eyes)  # eye
        ss.px(fx+7, fy+8, o); ss.px(fx+8, fy+8, skin); ss.px(fx+9, fy+8, skin); ss.px(fx+10, fy+8, o)
        ss.px(fx+7, fy+9, o); ss.px(fx+8, fy+9, skin); ss.px(fx+9, fy+9, o)
        if hat:
            ss.px(fx+6, fy+1, o); ss.px(fx+7, fy+1, hat); ss.px(fx+8, fy+1, hat); ss.px(fx+9, fy+1, hat); ss.px(fx+10, fy+1, hat); ss.px(fx+11, fy+1, o)
            ss.px(fx+6, fy+2, o); ss.px(fx+7, fy+2, hat); ss.px(fx+8, fy+2, hat); ss.px(fx+9, fy+2, hat); ss.px(fx+10, fy+2, hat); ss.px(fx+11, fy+2, hat); ss.px(fx+12, fy+2, o)


def draw_body(ss, fx, fy, top_c, top_dark, bottom_c, shoes_c, direction, walk_phase):
    """Draw torso + legs + feet. fy = frame top (body starts at fy+10)."""
    o = OUTLINE
    by = fy + 10  # body start

    # Neck
    ss.px(fx+7, by, (200, 170, 140)); ss.px(fx+8, by, (200, 170, 140))

    leg_l = 0
    leg_r = 0
    if walk_phase == 1:
        leg_l = -1; leg_r = 1
    elif walk_phase == 2:
        leg_l = 1; leg_r = -1

    if direction in ["down", "up"]:
        # Torso
        ss.px(fx+4, by+1, o)
        for col in range(5, 11): ss.px(fx+col, by+1, top_c)
        ss.px(fx+11, by+1, o)
        for row in range(2, 8):
            ss.px(fx+3, by+row, o)
            ss.px(fx+4, by+row, top_c)
            for col in range(5, 11): ss.px(fx+col, by+row, top_c)
            ss.px(fx+11, by+row, top_c)
            ss.px(fx+12, by+row, o)
        # Shadow on torso
        if direction == "down":
            for col in range(5, 11): ss.px(fx+col, by+2, top_dark)
        # Hands
        ss.px(fx+3, by+7, o); ss.px(fx+12, by+7, o)

        # Belt/waist
        ss.px(fx+4, by+8, o)
        for col in range(5, 11): ss.px(fx+col, by+8, bottom_c)
        ss.px(fx+11, by+8, o)

        # Legs
        # Left leg
        ll_y = by + 9 + leg_l
        ss.px(fx+4, ll_y, o); ss.px(fx+5, ll_y, bottom_c); ss.px(fx+6, ll_y, bottom_c); ss.px(fx+7, ll_y, o)
        ss.px(fx+4, ll_y+1, o); ss.px(fx+5, ll_y+1, bottom_c); ss.px(fx+6, ll_y+1, bottom_c); ss.px(fx+7, ll_y+1, o)
        ss.px(fx+4, ll_y+2, o); ss.px(fx+5, ll_y+2, bottom_c); ss.px(fx+6, ll_y+2, bottom_c); ss.px(fx+7, ll_y+2, o)
        # Left shoe
        ss.px(fx+4, ll_y+3, o); ss.px(fx+5, ll_y+3, shoes_c); ss.px(fx+6, ll_y+3, shoes_c); ss.px(fx+7, ll_y+3, o)
        ss.px(fx+5, ll_y+4, o); ss.px(fx+6, ll_y+4, o)

        # Right leg
        rl_y = by + 9 + leg_r
        ss.px(fx+8, rl_y, o); ss.px(fx+9, rl_y, bottom_c); ss.px(fx+10, rl_y, bottom_c); ss.px(fx+11, rl_y, o)
        ss.px(fx+8, rl_y+1, o); ss.px(fx+9, rl_y+1, bottom_c); ss.px(fx+10, rl_y+1, bottom_c); ss.px(fx+11, rl_y+1, o)
        ss.px(fx+8, rl_y+2, o); ss.px(fx+9, rl_y+2, bottom_c); ss.px(fx+10, rl_y+2, bottom_c); ss.px(fx+11, rl_y+2, o)
        # Right shoe
        ss.px(fx+8, rl_y+3, o); ss.px(fx+9, rl_y+3, shoes_c); ss.px(fx+10, rl_y+3, shoes_c); ss.px(fx+11, rl_y+3, o)
        ss.px(fx+9, rl_y+4, o); ss.px(fx+10, rl_y+4, o)

    elif direction == "left":
        # Torso (narrower, offset left)
        for row in range(1, 8):
            ss.px(fx+4, by+row, o)
            for col in range(5, 10): ss.px(fx+col, by+row, top_c)
            ss.px(fx+10, by+row, o)
        # Arm
        ss.px(fx+4, by+6, o); ss.px(fx+4, by+7, o)
        # Legs
        ll_y = by + 8
        ss.px(fx+5, ll_y+leg_l, o); ss.px(fx+6, ll_y+leg_l, bottom_c); ss.px(fx+7, ll_y+leg_l, bottom_c); ss.px(fx+8, ll_y+leg_l, o)
        ss.px(fx+5, ll_y+1+leg_l, o); ss.px(fx+6, ll_y+1+leg_l, bottom_c); ss.px(fx+7, ll_y+1+leg_l, bottom_c); ss.px(fx+8, ll_y+1+leg_l, o)
        ss.px(fx+5, ll_y+2+leg_l, o); ss.px(fx+6, ll_y+2+leg_l, bottom_c); ss.px(fx+7, ll_y+2+leg_l, bottom_c); ss.px(fx+8, ll_y+2+leg_l, o)
        # Shoe
        ss.px(fx+4, ll_y+3+leg_l, o); ss.px(fx+5, ll_y+3+leg_l, shoes_c); ss.px(fx+6, ll_y+3+leg_l, shoes_c); ss.px(fx+7, ll_y+3+leg_l, o)

    elif direction == "right":
        for row in range(1, 8):
            ss.px(fx+5, by+row, o)
            for col in range(6, 11): ss.px(fx+col, by+row, top_c)
            ss.px(fx+11, by+row, o)
        ss.px(fx+11, by+6, o); ss.px(fx+11, by+7, o)
        # Legs
        ll_y = by + 8
        ss.px(fx+7, ll_y+leg_r, o); ss.px(fx+8, ll_y+leg_r, bottom_c); ss.px(fx+9, ll_y+leg_r, bottom_c); ss.px(fx+10, ll_y+leg_r, o)
        ss.px(fx+7, ll_y+1+leg_r, o); ss.px(fx+8, ll_y+1+leg_r, bottom_c); ss.px(fx+9, ll_y+1+leg_r, bottom_c); ss.px(fx+10, ll_y+1+leg_r, o)
        ss.px(fx+7, ll_y+2+leg_r, o); ss.px(fx+8, ll_y+2+leg_r, bottom_c); ss.px(fx+9, ll_y+2+leg_r, bottom_c); ss.px(fx+10, ll_y+2+leg_r, o)
        ss.px(fx+8, ll_y+3+leg_r, o); ss.px(fx+9, ll_y+3+leg_r, shoes_c); ss.px(fx+10, ll_y+3+leg_r, shoes_c); ss.px(fx+11, ll_y+3+leg_r, o)


def generate_character(filename, skin, hair, top_c, bottom_c, shoes_c, hat=None, extra_fn=None):
    """Generate a full 48x128 spritesheet."""
    ss = SpriteSheet()
    eyes = h("#1A1A2A")
    top_dark = (max(0,top_c[0]-30), max(0,top_c[1]-30), max(0,top_c[2]-30))
    directions = ["down", "left", "right", "up"]

    for dir_idx, direction in enumerate(directions):
        for frame in range(3):
            fx = frame * 16
            fy = dir_idx * 32
            walk_phase = frame  # 0=idle, 1=step_left, 2=step_right

            draw_outlined_head(ss, fx, fy, skin, hair, eyes, hat, direction)
            draw_body(ss, fx, fy, top_c, top_dark, bottom_c, shoes_c, direction, walk_phase)

            if extra_fn:
                extra_fn(ss, fx, fy, direction, frame)

    ss.save(filename)


# === EXTRA DRAWING FUNCTIONS ===

def nurse_cross(ss, fx, fy, direction, frame):
    if direction == "down":
        ss.px(fx+7, fy+1, (220, 40, 40))
        ss.px(fx+8, fy+1, (220, 40, 40))
        ss.px(fx+6, fy+2, (220, 40, 40))
        ss.px(fx+9, fy+2, (220, 40, 40))

def bug_net(ss, fx, fy, direction, frame):
    if direction in ["left", "right"]:
        nx = fx + (3 if direction == "left" else 12)
        for dy in range(10, 18):
            ss.px(nx, fy + dy, (120, 100, 60))

# === CHARACTER DEFINITIONS ===

CHARACTERS = [
    ("player.png",     h("#E8C8A0"), h("#2A2A2A"), h("#333333"), h("#1565C0"), h("#444444"), h("#E53935"), None),
    ("rival.png",      h("#E8C8A0"), h("#1E88E5"), h("#78909C"), h("#37474F"), h("#555555"), None, None),
    ("nurse.png",      h("#F0D0B0"), h("#FF8AAE"), h("#F48FB1"), h("#F48FB1"), h("#FFFFFF"), h("#FFFFFF"), nurse_cross),
    ("shopkeeper.png", h("#D4A574"), h("#5D4037"), h("#4CAF50"), h("#3E2723"), h("#555555"), h("#4CAF50"), None),
    ("youngster.png",  h("#E8C8A0"), h("#8D6E63"), h("#42A5F5"), h("#D7CCC8"), h("#666666"), None, None),
    ("lass.png",       h("#F0D0B0"), h("#FF7043"), h("#FFFFFF"), h("#EF5350"), h("#AB47BC"), None, None),
    ("bug_catcher.png",h("#E8C8A0"), h("#6D4C41"), h("#8BC34A"), h("#795548"), h("#555555"), h("#CDDC39"), bug_net),
    ("gym_leader_pierre.png", h("#C8A882"), h("#5D4037"), h("#795548"), h("#4E342E"), h("#3E2723"), None, None),
    ("gym_leader_flora.png",  h("#F0D0B0"), h("#388E3C"), h("#66BB6A"), h("#2E7D32"), h("#1B5E20"), None, None),
    ("prof_oak.png",   h("#E0C8A0"), h("#9E9E9E"), h("#FFFFFF"), h("#5D4037"), h("#444444"), None, None),
]

if __name__ == "__main__":
    print("Generating 10 overworld spritesheets (v3 - clean pixel art)...")
    for args in CHARACTERS:
        filename, skin, hair, top, bottom, shoes, hat_or_extra1, extra_or_none = args
        # Determine hat vs extra_fn
        hat = None
        extra = None
        if callable(hat_or_extra1):
            extra = hat_or_extra1
        elif hat_or_extra1:
            hat = hat_or_extra1
        if callable(extra_or_none):
            extra = extra_or_none
        generate_character(filename, skin, hair, top, bottom, shoes, hat, extra)
    print("Done!")
