#!/usr/bin/env python3
"""Extract structure idle GIFs into horizontal PNG sprite sheets for Godot."""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageSequence

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
OUT_DIR = ASSETS / "sprites" / "structures"

# Legacy filenames at assets/ root -> canonical structure id
GIF_MAP = {
    "acid_spitter_idle_animation.gif": "spitter",
    "crusher_idle_animation.gif": "crusher",
    "needle_idle_animation.gif": "needle",
    "gland_idle_animation.gif": "gland",
    "mine_idle_animation.gif": "mine",
}

FRAME_MS = 500


def extract_gif(src: Path, dest_dir: Path, copy_source: bool = True) -> tuple[int, int, int]:
    dest_dir.mkdir(parents=True, exist_ok=True)
    if copy_source and src.resolve() != (dest_dir / "idle.gif").resolve():
        shutil.copy2(src, dest_dir / "idle.gif")

    image = Image.open(src)
    frames = [frame.convert("RGBA") for frame in ImageSequence.Iterator(image)]
    if not frames:
        raise RuntimeError(f"No frames in {src}")

    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h))
    for i, frame in enumerate(frames):
        if frame.size != (w, h):
            frame = frame.resize((w, h), Image.Resampling.NEAREST)
        sheet.paste(frame, (i * w, 0))

    sheet_path = dest_dir / "idle_sheet.png"
    sheet.save(sheet_path)
    meta_path = dest_dir / "idle.meta.txt"
    meta_path.write_text(
        f"frames={len(frames)}\nwidth={w}\nheight={h}\nframe_ms={FRAME_MS}\n",
        encoding="utf-8",
    )
    return w, h, len(frames)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for gif_name, structure_id in GIF_MAP.items():
        dest = OUT_DIR / structure_id
        src = ASSETS / gif_name
        if not src.exists():
            src = dest / "idle.gif"
        if not src.exists():
            print(f"skip missing {structure_id}")
            continue
        w, h, n = extract_gif(src, dest, copy_source=src.name != "idle.gif")
        print(f"{structure_id}: {n} frames @ {w}x{h} -> {dest}")
        legacy = ASSETS / gif_name
        if legacy.exists():
            legacy.unlink()


if __name__ == "__main__":
    main()
