#!/usr/bin/env python3
"""Pack per-frame enemy walk PNGs into horizontal sprite sheets for Godot."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "assets" / "raw" / "enemies_anim"
OUT_DIR = ROOT / "assets" / "sprites" / "enemies"

# enemy_{id}_anim_walk_32 -> game id
FOLDER_MAP = {
    "enemy_skitter_anim_walk_32": "skitter",
    "enemy_mite_anim_walk_32": "mite",
    "enemy_chitin_anim_walk_32": "chitin",
    "enemy_borer_anim_walk_32": "borer",
    "enemy_scarab_anim_walk_32": "scarab",
}

DEFAULT_FRAME_MS = 100
FRAME_SIZE = 32


def _frame_sort_key(path: Path) -> tuple:
    match = re.search(r"(\d+)", path.stem)
    return (int(match.group(1)) if match else 0, path.name)


def extract_folder(src_dir: Path, enemy_id: str) -> tuple[int, int, int, int]:
    frames_paths = sorted(src_dir.glob("frame_*.png"), key=_frame_sort_key)
    if not frames_paths:
        raise RuntimeError(f"No frame_*.png in {src_dir}")

    frames: list[Image.Image] = []
    for path in frames_paths:
        img = Image.open(path).convert("RGBA")
        if img.size != (FRAME_SIZE, FRAME_SIZE):
            img = img.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.NEAREST)
        frames.append(img)

    w, h = FRAME_SIZE, FRAME_SIZE
    sheet = Image.new("RGBA", (w * len(frames), h))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * w, 0))

    dest = OUT_DIR / enemy_id
    dest.mkdir(parents=True, exist_ok=True)
    sheet.save(dest / "walk_sheet.png")
    frames[0].save(dest / "static.png")
    (dest / "walk.meta.txt").write_text(
        f"frames={len(frames)}\nwidth={w}\nheight={h}\nframe_ms={DEFAULT_FRAME_MS}\n",
        encoding="utf-8",
    )
    return w, h, len(frames), DEFAULT_FRAME_MS


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for folder_name, enemy_id in FOLDER_MAP.items():
        src = RAW_DIR / folder_name
        if not src.is_dir():
            print(f"skip missing {src}")
            continue
        w, h, n, ms = extract_folder(src, enemy_id)
        print(f"{enemy_id}: {n} frames @ {w}x{h} ({ms}ms) -> {OUT_DIR / enemy_id}")


if __name__ == "__main__":
    main()
