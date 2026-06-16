#!/usr/bin/env python3
"""Poll PixelLab jobs and download completed assets for Sprint 02."""
import json
import urllib.request
import zipfile
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOBS_PATH = ROOT / "tools" / "_pixellab_job_ids.json"


def mcp_call(tool: str, arguments: dict) -> dict:
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": tool, "arguments": arguments}}
    ).encode()
    req = urllib.request.Request(
        "https://api.pixellab.ai/mcp",
        data=payload,
        headers={"Content-Type": "application/json", "Accept": "application/json, text/event-stream"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        raw = resp.read().decode()
    # SSE or JSON
    if raw.startswith("event:"):
        for line in raw.splitlines():
            if line.startswith("data: "):
                body = json.loads(line[6:])
                break
        else:
            body = {"raw": raw[:500]}
    else:
        body = json.loads(raw)
    if "error" in body:
        raise RuntimeError(body["error"])
    content = body.get("result", {}).get("content", [])
    text = content[0].get("text", "") if content else json.dumps(body)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text}


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(url, dest)
    print("saved", dest)


def download_walk_sheet(object_id: str, dest: Path) -> bool:
    data = urllib.request.urlopen(
        f"https://api.pixellab.ai/mcp/objects/{object_id}/download", timeout=120
    ).read()
    z = zipfile.ZipFile(io.BytesIO(data))
    frames = sorted(n for n in z.namelist() if "animations" in n and n.endswith(".png"))
    if not frames:
        return False
    from PIL import Image

    imgs = [Image.open(io.BytesIO(z.read(f))).convert("RGBA") for f in frames]
    w, h = imgs[0].size
    sheet = Image.new("RGBA", (w * len(imgs), h))
    for i, im in enumerate(imgs):
        sheet.paste(im, (i * w, 0))
    dest.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(dest)
    print("walk sheet", dest, sheet.size)
    return True


def main() -> None:
    jobs = json.loads(JOBS_PATH.read_text())
    tp = jobs.get("tiles_pro", {})
    if tp.get("tile_id"):
        status = mcp_call("get_tiles_pro", {"tile_id": tp["tile_id"]})
        print("tiles_pro", status.get("status", status))
        if status.get("status") == "completed":
            url = status.get("download_url") or status.get("image_url")
            if url:
                download(url, ROOT / "assets" / "tilesets" / "citadel_interior.png")

    for key, dest, walk_dest in [
        ("gatherer", ROOT / "assets/sprites/gatherer.png", ROOT / "assets/sprites/ants/gatherer_walk.png"),
        ("builder", ROOT / "assets/sprites/builder.png", ROOT / "assets/sprites/ants/builder_walk.png"),
        ("soldier", ROOT / "assets/sprites/soldier_micro.png", ROOT / "assets/sprites/ants/soldier_walk.png"),
        ("queen_micro", ROOT / "assets/sprites/queen_micro.png", None),
    ]:
        info = jobs.get(key, {})
        oid = info.get("object_id")
        if not oid:
            continue
        status = mcp_call("get_object", {"object_id": oid})
        print(key, status.get("status", status.get("raw", "")[:80]))
        if status.get("status") == "completed":
            url = status.get("download_url")
            if url:
                download(url, dest)
            if walk_dest and not walk_dest.exists():
                try:
                    download_walk_sheet(oid, walk_dest)
                except Exception as exc:
                    print("walk", key, exc)

    ui = jobs.get("ui_icons", {})
    if ui.get("object_id"):
        status = mcp_call("get_object", {"object_id": ui["object_id"]})
        print("ui_icons", status.get("status"))


if __name__ == "__main__":
    main()
