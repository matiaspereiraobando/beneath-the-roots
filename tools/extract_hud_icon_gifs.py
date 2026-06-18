#!/usr/bin/env python3
"""Extract HUD icon GIFs into horizontal PNG sprite sheets for Godot."""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageSequence

ROOT = Path(__file__).resolve().parents[1]
HUD_DIR = ROOT / "assets" / "sprites" / "ui" / "hud"

# GIF filename at assets root or hud dir -> kind prefix (matches SpritePaths.hud_icon)
HUD_ANIM_MAP = {
    "biomass_icon_32_anim.gif": "biomass",
    "health_icon_32_anim.gif": "health",
    "satiety_icon_32_anim.gif": "satiety",
    "builders_icon_32_anim.gif": "builders",
    "gatherers_icon_32_anim.gif": "gatherers",
    "soldiers_icon_32_anim.gif": "soldiers",
}


def extract_gif(src: Path, kind: str) -> tuple[int, int, int, int]:
    HUD_DIR.mkdir(parents=True, exist_ok=True)
    dest_gif = HUD_DIR / f"{kind}_icon_32_anim.gif"
    if src.resolve() != dest_gif.resolve():
        shutil.copy2(src, dest_gif)

    image = Image.open(src)
    frame_ms = int(image.info.get("duration", 150))
    frames = [frame.convert("RGBA") for frame in ImageSequence.Iterator(image)]
    if not frames:
        raise RuntimeError(f"No frames in {src}")

    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h))
    for i, frame in enumerate(frames):
        if frame.size != (w, h):
            frame = frame.resize((w, h), Image.Resampling.NEAREST)
        sheet.paste(frame, (i * w, 0))

    sheet_path = HUD_DIR / f"{kind}_icon_32_anim_sheet.png"
    sheet.save(sheet_path)
    meta_path = HUD_DIR / f"{kind}_icon_32_anim.meta.txt"
    meta_path.write_text(
        f"frames={len(frames)}\nwidth={w}\nheight={h}\nframe_ms={frame_ms}\n",
        encoding="utf-8",
    )
    return w, h, len(frames), frame_ms


def main() -> None:
    HUD_DIR.mkdir(parents=True, exist_ok=True)
    for gif_name, kind in HUD_ANIM_MAP.items():
        src = ROOT / "assets" / gif_name
        if not src.exists():
            src = HUD_DIR / gif_name
        if not src.exists():
            src = HUD_DIR / f"{kind}_icon_32_anim.gif"
        if not src.exists():
            print(f"skip missing {kind}")
            continue
        w, h, n, ms = extract_gif(src, kind)
        print(f"{kind}: {n} frames @ {w}x{h}, {ms}ms -> {HUD_DIR}")
        legacy = ROOT / "assets" / gif_name
        if legacy.exists() and legacy.resolve() != (HUD_DIR / f"{kind}_icon_32_anim.gif").resolve():
            legacy.unlink()


if __name__ == "__main__":
    main()
