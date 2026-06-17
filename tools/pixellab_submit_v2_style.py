#!/usr/bin/env python3
"""Queue native 64px sprite v2 jobs with style refs resized to 64x64 (output matches ref size)."""
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STYLE_64 = ROOT / "tools" / "_pixellab_style_64.json"
JOBS = ROOT / "tools" / "_pixellab_job_ids.json"
MCP = "https://api.pixellab.ai/mcp"

PALETTE = (
    "Beneath the Roots grim underground ant colony. "
    "Desaturated brown chitin #3d2e22, tunnels #2a1f18, acid green #6aff4a, queen purple #6b2d5c. "
    "Chunky readable pixels, high contrast silhouette, dark outline, crisp not blurry."
)


def mcp(tool: str, args: dict) -> dict:
    token = os.environ.get("PIXELLAB_API_TOKEN") or os.environ.get("PIXELLAB_API_KEY")
    if not token:
        raise SystemExit("Set PIXELLAB_API_TOKEN for style-locked submits.")
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
    return json.loads(text)


def main() -> None:
    style = json.loads(STYLE_64.read_text())
    jobs = json.loads(JOBS.read_text()) if JOBS.exists() else {}
    cmd = sys.argv[1] if len(sys.argv) > 1 else "gatherer_style"

    if cmd == "gatherer_style" and "gatherer_v2_style" not in jobs:
        jobs["gatherer_v2_style"] = mcp(
            "create_1_direction_object",
            {
                "description": f"{PALETTE} Top-down gatherer worker ant, single character centered.",
                "view": "top-down",
                "style_images": style,
            },
        )
    JOBS.write_text(json.dumps(jobs, indent=2))
    print("saved", cmd, jobs.get("gatherer_v2_style", jobs))


if __name__ == "__main__":
    main()
