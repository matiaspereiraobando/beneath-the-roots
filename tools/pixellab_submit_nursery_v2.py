#!/usr/bin/env python3
"""Queue micro nursery v2 PixelLab jobs (background + side ants)."""
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JOBS = ROOT / "tools" / "_pixellab_job_ids.json"
MCP = "https://api.pixellab.ai/mcp"
BG = ROOT / "assets" / "micro" / "nursery_background.png"

PALETTE = (
    "Beneath the Roots grim underground ant colony. "
    "Desaturated brown chitin #3d2e22, tunnels #2a1f18, acid green #6aff4a, queen purple #6b2d5c. "
    "Chunky readable pixels, high contrast, dark outline."
)


def mcp(tool: str, args: dict) -> dict:
    token = os.environ.get("PIXELLAB_API_TOKEN") or os.environ.get("PIXELLAB_API_KEY")
    if not token:
        raise SystemExit("Set PIXELLAB_API_TOKEN to submit nursery v2 jobs.")
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": tool, "arguments": args}}
    ).encode()
    req = urllib.request.Request(
        MCP,
        data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        body = json.loads(resp.read().decode())
    text = body["result"]["content"][0]["text"]
    return json.loads(text) if text.strip().startswith("{") else {"raw": text}


def submit_background() -> dict:
    b64 = base64.b64encode(BG.read_bytes()).decode("ascii")
    return mcp(
        "create_map_object",
        {
            "description": (
                f"{PALETTE} Nursery cross-section pixel art. Vertical central tunnel spine, "
                "two egg chambers left with white larvae, food storage right, wooden scaffold, "
                "orange dirt floors, dark blue-grey rock walls, queen chamber at bottom. No ants."
            ),
            "width": 256,
            "height": 256,
            "view": "side",
            "background_image": json.dumps({"type": "base64", "base64": b64}),
            "inpainting": json.dumps({"type": "rectangle", "fraction": 0.92}),
        },
    )


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "background"
    jobs = json.loads(JOBS.read_text()) if JOBS.exists() else {}
    micro = jobs.setdefault("micro_nursery_v2", {})

    if cmd == "background" and "background" not in micro:
        result = submit_background()
        micro["background"] = {
            "object_id": result.get("id") or result.get("object_id"),
            "status": result.get("status", "queued"),
            "output": "assets/micro/nursery_background_v2.png",
            "size": "256x256",
            "raw": result.get("raw"),
        }
        print("background", micro["background"])

    JOBS.write_text(json.dumps(jobs, indent=2))
    print("saved", JOBS)


if __name__ == "__main__":
    main()
