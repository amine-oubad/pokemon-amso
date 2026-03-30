#!/usr/bin/env python3
"""Generate 10 overworld character spritesheets (48x128, 16x32 frames, 3 cols x 4 rows)."""
from PIL import Image, ImageDraw
import os

OUT = "assets/sprites/overworld"
os.makedirs(OUT, exist_ok=True)

def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def draw_character(filename, skin, hair, top, bottom, shoes, accessory=None, hat=None, extra_fn=None):
    """
    Draw a 48x128 spritesheet with 3 frames x 4 directions.
    Each frame is 16x32: 16 wide, 32 tall (head + body).
    Directions: down(y=0), left(y=32), right(y=64), up(y=96)
    Frames: idle(x=0), walk1(x=16), walk2(x=32)
    """
    img = Image.new("RGBA", (48, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    skin_dark = (max(0, skin[0]-30), max(0, skin[1]-30), max(0, skin[2]-25))
    hair_dark = (max(0, hair[0]-25), max(0, hair[1]-25), max(0, hair[2]-25))
    top_dark = (max(0, top[0]-30), max(0, top[1]-30), max(0, top[2]-30))
    bottom_dark = (max(0, bottom[0]-25), max(0, bottom[1]-25), max(0, bottom[2]-25))

    directions = ["down", "left", "right", "up"]

    for dir_idx, direction in enumerate(directions):
        for frame in range(3):
            fx = frame * 16
            fy = dir_idx * 32

            # Walk animation offset
            leg_offset = 0
            arm_offset = 0
            if frame == 1:
                leg_offset = 1
                arm_offset = -1
            elif frame == 2:
                leg_offset = -1
                arm_offset = 1

            # === HEAD (top 14 pixels) ===
            # Hair base
            if direction == "down":
                # Face visible
                draw.rectangle([fx+4, fy+1, fx+11, fy+4], fill=(*hair, 255))  # hair top
                draw.rectangle([fx+3, fy+2, fx+12, fy+3], fill=(*hair, 255))  # hair sides
                draw.rectangle([fx+5, fy+4, fx+10, fy+10], fill=(*skin, 255))  # face
                draw.rectangle([fx+4, fy+5, fx+11, fy+9], fill=(*skin, 255))  # face wider
                # Eyes
                draw.point((fx+6, fy+6), fill=(20, 20, 30, 255))
                draw.point((fx+9, fy+6), fill=(20, 20, 30, 255))
                # Mouth
                draw.point((fx+7, fy+8), fill=(*skin_dark, 255))
                draw.point((fx+8, fy+8), fill=(*skin_dark, 255))
                if hat:
                    draw.rectangle([fx+3, fy+0, fx+12, fy+3], fill=(*hat, 255))
                    draw.rectangle([fx+2, fy+2, fx+13, fy+3], fill=(*hat, 255))  # brim

            elif direction == "up":
                # Back of head
                draw.rectangle([fx+4, fy+1, fx+11, fy+10], fill=(*hair, 255))
                draw.rectangle([fx+3, fy+3, fx+12, fy+8], fill=(*hair, 255))
                # Neck
                draw.rectangle([fx+6, fy+10, fx+9, fy+11], fill=(*skin, 255))
                if hat:
                    draw.rectangle([fx+3, fy+0, fx+12, fy+3], fill=(*hat, 255))

            elif direction == "left":
                # Side view left
                draw.rectangle([fx+5, fy+1, fx+10, fy+4], fill=(*hair, 255))
                draw.rectangle([fx+4, fy+2, fx+10, fy+4], fill=(*hair, 255))
                draw.rectangle([fx+5, fy+4, fx+9, fy+10], fill=(*skin, 255))
                draw.rectangle([fx+4, fy+5, fx+9, fy+9], fill=(*skin, 255))
                draw.point((fx+5, fy+6), fill=(20, 20, 30, 255))  # eye
                # Hair on side
                draw.rectangle([fx+8, fy+2, fx+10, fy+7], fill=(*hair, 255))
                if hat:
                    draw.rectangle([fx+3, fy+0, fx+10, fy+3], fill=(*hat, 255))

            elif direction == "right":
                draw.rectangle([fx+5, fy+1, fx+10, fy+4], fill=(*hair, 255))
                draw.rectangle([fx+5, fy+2, fx+11, fy+4], fill=(*hair, 255))
                draw.rectangle([fx+6, fy+4, fx+10, fy+10], fill=(*skin, 255))
                draw.rectangle([fx+6, fy+5, fx+11, fy+9], fill=(*skin, 255))
                draw.point((fx+10, fy+6), fill=(20, 20, 30, 255))
                draw.rectangle([fx+5, fy+2, fx+7, fy+7], fill=(*hair, 255))
                if hat:
                    draw.rectangle([fx+5, fy+0, fx+12, fy+3], fill=(*hat, 255))

            # === BODY (pixels 11-22) ===
            body_y = fy + 11

            if direction in ["down", "up"]:
                # Torso
                draw.rectangle([fx+4, body_y, fx+11, body_y+6], fill=(*top, 255))
                draw.rectangle([fx+5, body_y, fx+10, body_y+7], fill=(*top, 255))
                # Arms
                draw.rectangle([fx+3, body_y+1+arm_offset, fx+4, body_y+5+arm_offset], fill=(*top, 255))
                draw.rectangle([fx+11, body_y+1-arm_offset, fx+12, body_y+5-arm_offset], fill=(*top, 255))
                # Arm skin (hands)
                draw.point((fx+3, body_y+5+arm_offset), fill=(*skin, 255))
                draw.point((fx+12, body_y+5-arm_offset), fill=(*skin, 255))
                # Shadow/detail on torso
                if direction == "down":
                    draw.line([(fx+5, body_y+2), (fx+10, body_y+2)], fill=(*top_dark, 255))

            elif direction == "left":
                draw.rectangle([fx+5, body_y, fx+9, body_y+7], fill=(*top, 255))
                draw.rectangle([fx+4, body_y+1+arm_offset, fx+5, body_y+5+arm_offset], fill=(*top, 255))
                draw.point((fx+4, body_y+5+arm_offset), fill=(*skin, 255))

            elif direction == "right":
                draw.rectangle([fx+6, body_y, fx+10, body_y+7], fill=(*top, 255))
                draw.rectangle([fx+10, body_y+1-arm_offset, fx+11, body_y+5-arm_offset], fill=(*top, 255))
                draw.point((fx+11, body_y+5-arm_offset), fill=(*skin, 255))

            # === LEGS (pixels 18-28) ===
            legs_y = body_y + 7

            if direction in ["down", "up"]:
                # Left leg
                draw.rectangle([fx+5, legs_y, fx+7, legs_y+5+leg_offset], fill=(*bottom, 255))
                # Right leg
                draw.rectangle([fx+8, legs_y, fx+10, legs_y+5-leg_offset], fill=(*bottom, 255))
                # Shoes
                draw.rectangle([fx+5, legs_y+5+leg_offset, fx+7, legs_y+6+leg_offset], fill=(*shoes, 255))
                draw.rectangle([fx+8, legs_y+5-leg_offset, fx+10, legs_y+6-leg_offset], fill=(*shoes, 255))
            elif direction == "left":
                draw.rectangle([fx+5, legs_y, fx+7, legs_y+5+leg_offset], fill=(*bottom, 255))
                draw.rectangle([fx+6, legs_y, fx+8, legs_y+5-leg_offset], fill=(*bottom_dark, 255))
                draw.rectangle([fx+4, legs_y+5+leg_offset, fx+7, legs_y+6+leg_offset], fill=(*shoes, 255))
            elif direction == "right":
                draw.rectangle([fx+8, legs_y, fx+10, legs_y+5-leg_offset], fill=(*bottom, 255))
                draw.rectangle([fx+7, legs_y, fx+9, legs_y+5+leg_offset], fill=(*bottom_dark, 255))
                draw.rectangle([fx+8, legs_y+5-leg_offset, fx+11, legs_y+6-leg_offset], fill=(*shoes, 255))

            # Extra drawing (accessories etc.)
            if extra_fn:
                extra_fn(draw, img, fx, fy, direction, frame, accessory)

    img.save(os.path.join(OUT, filename))
    print(f"  {filename} saved (48x128)")

# --- Extra drawing functions for specific characters ---

def nurse_cross(draw, img, fx, fy, direction, frame, acc):
    """Draw nurse cross on cap."""
    if direction == "down":
        draw.point((fx+7, fy+1), fill=(220, 40, 40, 255))
        draw.point((fx+8, fy+1), fill=(220, 40, 40, 255))
        draw.point((fx+7, fy+2), fill=(220, 40, 40, 255))
        draw.point((fx+8, fy+2), fill=(220, 40, 40, 255))
        draw.point((fx+6, fy+1), fill=(220, 40, 40, 255))
        draw.point((fx+9, fy+1), fill=(220, 40, 40, 255))

def bug_net(draw, img, fx, fy, direction, frame, acc):
    """Draw bug net."""
    if direction in ["left", "right"]:
        nx = fx + (2 if direction == "left" else 12)
        draw.line([(nx, fy+8), (nx, fy+20)], fill=(120, 100, 70, 255))
        draw.ellipse([nx-2, fy+5, nx+2, fy+9], outline=(100, 160, 80, 200))

# === CHARACTER DEFINITIONS ===

characters = [
    ("player.png",
     hex2rgb("#E8C8A0"), hex2rgb("#2A2A2A"), hex2rgb("#333333"),
     hex2rgb("#1565C0"), hex2rgb("#444444"), None, hex2rgb("#E53935")),

    ("rival.png",
     hex2rgb("#E8C8A0"), hex2rgb("#1E88E5"), hex2rgb("#78909C"),
     hex2rgb("#37474F"), hex2rgb("#555555"), None, None),

    ("nurse.png",
     hex2rgb("#F0D0B0"), hex2rgb("#FF8AAE"), hex2rgb("#F48FB1"),
     hex2rgb("#F48FB1"), hex2rgb("#FFFFFF"), None, hex2rgb("#FFFFFF")),

    ("shopkeeper.png",
     hex2rgb("#D4A574"), hex2rgb("#5D4037"), hex2rgb("#FFFFFF"),
     hex2rgb("#3E2723"), hex2rgb("#555555"), None, hex2rgb("#4CAF50")),

    ("youngster.png",
     hex2rgb("#E8C8A0"), hex2rgb("#8D6E63"), hex2rgb("#42A5F5"),
     hex2rgb("#D7CCC8"), hex2rgb("#666666"), None, None),

    ("lass.png",
     hex2rgb("#F0D0B0"), hex2rgb("#FF7043"), hex2rgb("#FFFFFF"),
     hex2rgb("#EF5350"), hex2rgb("#AB47BC"), None, None),

    ("bug_catcher.png",
     hex2rgb("#E8C8A0"), hex2rgb("#6D4C41"), hex2rgb("#8BC34A"),
     hex2rgb("#795548"), hex2rgb("#555555"), None, hex2rgb("#CDDC39")),

    ("gym_leader_pierre.png",
     hex2rgb("#C8A882"), hex2rgb("#5D4037"), hex2rgb("#795548"),
     hex2rgb("#4E342E"), hex2rgb("#3E2723"), None, None),

    ("gym_leader_flora.png",
     hex2rgb("#F0D0B0"), hex2rgb("#388E3C"), hex2rgb("#66BB6A"),
     hex2rgb("#2E7D32"), hex2rgb("#1B5E20"), None, None),

    ("prof_oak.png",
     hex2rgb("#E0C8A0"), hex2rgb("#9E9E9E"), hex2rgb("#FFFFFF"),
     hex2rgb("#5D4037"), hex2rgb("#444444"), None, None),
]

extra_fns = {
    "nurse.png": nurse_cross,
    "bug_catcher.png": bug_net,
}

for args in characters:
    fn = args[0]
    extra = extra_fns.get(fn)
    # Unpack: filename, skin, hair, top, bottom, shoes, accessory, hat
    filename = args[0]
    skin = args[1]
    hair = args[2]
    top_c = args[3]
    bottom_c = args[4]
    shoes_c = args[5]
    acc = args[6] if len(args) > 6 else None
    hat_c = args[7] if len(args) > 7 else None
    draw_character(filename, skin, hair, top_c, bottom_c, shoes_c, acc, hat_c, extra)

# Add shopkeeper apron
print("Done: 10 overworld spritesheets generated")
