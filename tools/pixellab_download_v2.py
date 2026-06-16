#!/usr/bin/env python3
"""Download completed v2 PixelLab objects into assets/sprites/v2/."""
import json
import urllib.request
import zipfile
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOBS = ROOT / "tools" / "_pixellab_job_ids.json"
V2 = ROOT / "assets" / "sprites" / "v2"
UI_V2 = ROOT / "assets" / "sprites" / "ui" / "v2"


def download_object(object_id: str, dest: Path) -> None:
    data = urllib.request.urlopen(
        f"https://api.pixellab.ai/mcp/objects/{object_id}/download", timeout=120
    ).read()
    if data[:2] == b"PK":
        z = zipfile.ZipFile(io.BytesIO(data))
        idle = "rotations/unknown.png"
        if idle in z.namelist():
            dest.write_bytes(z.read(idle))
            return
        pngs = [n for n in z.namelist() if n.endswith(".png")]
        if pngs:
            dest.write_bytes(z.read(pngs[0]))
            return
    dest.write_bytes(data)


def main() -> None:
    jobs = json.loads(JOBS.read_text())
    v2 = jobs.get("sprites_v2", {})
    mapping = {
        "gatherer": V2 / "gatherer.png",
        "builder": V2 / "builder.png",
        "soldier": V2 / "soldier_micro.png",
        "queen_micro": V2 / "queen_micro.png",
    }
    V2.mkdir(parents=True, exist_ok=True)
    for key, dest in mapping.items():
        entry = v2.get(key, {})
        oid = entry.get("selected_object_id") or entry.get("object_id")
        if oid:
            download_object(oid, dest)
            print("saved", dest)

    ui = v2.get("ui_icons", {})
    selected = ui.get("selected", {})
    UI_V2.mkdir(parents=True, exist_ok=True)
    for name, oid in selected.items():
        if oid:
            download_object(oid, UI_V2 / name)
            print("saved", UI_V2 / name)


if __name__ == "__main__":
    main()
