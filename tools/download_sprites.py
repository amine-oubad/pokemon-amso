#!/usr/bin/env python3
"""
Download Pokemon sprites from PokeAPI GitHub repository.
Usage: python tools/download_sprites.py

Downloads front, back, and official artwork for Pokemon #1-151.
Sprites are saved to assets/sprites/pokemon/{front,back,artwork}/.
"""

import os
import urllib.request
import sys
import time

BASE = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon"
ARTWORK = f"{BASE}/other/official-artwork"
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES_DIR = os.path.join(PROJECT_DIR, "assets", "sprites", "pokemon")

DIRS = {
    "front":   BASE,           # {id}.png — 96x96 pixel sprites
    "back":    f"{BASE}/back", # {id}.png — back sprites
    "artwork": ARTWORK,        # {id}.png — official artwork (HD)
}

def download(url: str, dest: str) -> bool:
    if os.path.exists(dest):
        return True  # Already downloaded
    try:
        urllib.request.urlretrieve(url, dest)
        return True
    except Exception as e:
        print(f"  FAIL: {url} -> {e}")
        return False

def main():
    total = 151
    for folder, base_url in DIRS.items():
        out_dir = os.path.join(SPRITES_DIR, folder)
        os.makedirs(out_dir, exist_ok=True)
        print(f"\n{'='*50}")
        print(f"Downloading {folder} sprites...")
        print(f"{'='*50}")
        ok = 0
        for pid in range(1, total + 1):
            url = f"{base_url}/{pid}.png"
            dest = os.path.join(out_dir, f"{pid:03d}.png")
            sys.stdout.write(f"\r  [{pid:3d}/{total}] {folder}/{pid:03d}.png")
            sys.stdout.flush()
            if download(url, dest):
                ok += 1
            time.sleep(0.05)  # Be nice to GitHub
        print(f"\n  Done: {ok}/{total} downloaded.")

    print(f"\n{'='*50}")
    print("All sprites downloaded!")
    print(f"Location: {SPRITES_DIR}")
    print(f"{'='*50}")

if __name__ == "__main__":
    main()
