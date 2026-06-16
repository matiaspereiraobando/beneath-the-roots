#!/usr/bin/env python3
"""Submit PixelLab MCP jobs using style refs. Requires PIXELLAB_API_TOKEN env var."""
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STYLE_PATH = ROOT / "tools" / "_pixellab_style_images.json"
JOBS_PATH = ROOT / "tools" / "_pixellab_job_ids.json"
MCP_URL = "https://api.pixellab.ai/mcp"


def mcp_call(tool: str, arguments: dict) -> dict:
    token = os.environ.get("PIXELLAB_API_TOKEN") or os.environ.get("PIXELLAB_API_KEY")
    if not token:
        raise SystemExit("Set PIXELLAB_API_TOKEN to your PixelLab MCP bearer token.")
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": tool, "arguments": arguments}}
    ).encode()
    req = urllib.request.Request(
        MCP_URL,
        data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        body = json.loads(resp.read().decode())
    if "error" in body:
        raise RuntimeError(body["error"])
    content = body.get("result", {}).get("content", [])
    text = content[0].get("text", "") if content else json.dumps(body)
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text}


def load_style_images() -> list:
    return json.loads(STYLE_PATH.read_text())


def main() -> None:
    style_images = load_style_images()
    jobs: dict = {}
    if JOBS_PATH.exists():
        jobs = json.loads(JOBS_PATH.read_text())

    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd in ("all", "tiles_pro") and "tiles_pro" not in jobs:
        jobs["tiles_pro"] = mcp_call(
            "create_tiles_pro",
            {
                "description": (
                    "1). dark chitin underground floor tile "
                    "2). rough chitin wall border tile "
                    "3). nursery green floor with egg sacs "
                    "4). armory floor with weapon racks "
                    "5). queen chamber purple organic floor "
                    "6). corridor stone floor"
                ),
                "tile_type": "square_topdown",
                "tile_size": 16,
                "tile_view": "high top-down",
                "style_images": style_images,
            },
        )
        print("tiles_pro", jobs["tiles_pro"])

    if cmd in ("all", "gatherer") and "gatherer" not in jobs:
        jobs["gatherer"] = mcp_call(
            "create_1_direction_object",
            {
                "description": "small red gatherer worker ant top-down pixel art",
                "size": 16,
                "view": "top-down",
                "style_images": style_images,
            },
        )
        print("gatherer", jobs["gatherer"])

    if cmd in ("all", "builder") and "builder" not in jobs:
        jobs["builder"] = mcp_call(
            "create_1_direction_object",
            {
                "description": "small builder ant carrying dirt clump top-down pixel art",
                "size": 16,
                "view": "top-down",
                "style_images": style_images,
            },
        )
        print("builder", jobs["builder"])

    if cmd in ("all", "soldier") and "soldier" not in jobs:
        jobs["soldier"] = mcp_call(
            "create_1_direction_object",
            {
                "description": "small soldier ant darker chitin mandibles top-down pixel art",
                "size": 16,
                "view": "top-down",
                "style_images": style_images,
            },
        )
        print("soldier", jobs["soldier"])

    if cmd in ("all", "queen_micro") and "queen_micro" not in jobs:
        jobs["queen_micro"] = mcp_call(
            "create_1_direction_object",
            {
                "description": "large purple grub queen ant top-down pixel art",
                "size": 32,
                "view": "top-down",
                "style_images": style_images,
            },
        )
        print("queen_micro", jobs["queen_micro"])

    if cmd in ("all", "ui_icons") and "ui_icons" not in jobs:
        jobs["ui_icons"] = mcp_call(
            "create_1_direction_object",
            {
                "description": "pixel UI icons for ant colony game",
                "size": 32,
                "view": "top-down",
                "style_images": style_images,
                "item_descriptions": [
                    "gatherer ant icon letter G",
                    "builder ant icon letter B",
                    "soldier ant icon letter S",
                    "organic meat feed icon",
                    "biomass pile icon",
                    "satiety droplet icon",
                    "empty nursery slot frame",
                    "filled nursery slot frame",
                ],
            },
        )
        print("ui_icons", jobs["ui_icons"])

    JOBS_PATH.write_text(json.dumps(jobs, indent=2))
    print("saved", JOBS_PATH)


if __name__ == "__main__":
    main()
