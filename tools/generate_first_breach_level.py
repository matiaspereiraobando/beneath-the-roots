#!/usr/bin/env python3
"""Generate data/levels/first_breach.json with serpentine tunnel path."""
from __future__ import annotations

import json
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "levels" / "first_breach.json"


def segment_horizontal(x0: int, x1: int, y: int) -> list[tuple[int, int]]:
    step = 1 if x1 >= x0 else -1
    return [(x, y) for x in range(x0, x1 + step, step)]


def segment_vertical(x: int, y0: int, y1: int) -> list[tuple[int, int]]:
    step = 1 if y1 >= y0 else -1
    return [(x, y) for y in range(y0, y1 + step, step)]


def build_path() -> set[tuple[int, int]]:
    segments: list[tuple[int, int]] = []
    segments += segment_vertical(2, 4, 7)
    segments += segment_horizontal(3, 30, 7)
    segments += segment_vertical(30, 8, 11)
    segments += segment_horizontal(29, 8, 11)
    segments += segment_vertical(8, 12, 15)
    segments += segment_horizontal(9, 33, 15)
    segments += segment_vertical(33, 16, 19)
    segments += segment_horizontal(32, 14, 19)
    segments += segment_horizontal(15, 37, 19)
    segments += segment_vertical(37, 20, 27)
    segments += [(38, 28), (39, 28), (38, 29), (39, 29), (38, 30), (39, 30)]
    return set(segments)


def validate_path(tunnel: set[tuple[int, int]], spawn: tuple[int, int]) -> None:
    citadel_tiles = {
        (37, 28), (38, 28), (39, 28),
        (37, 29), (38, 29), (39, 29),
        (37, 30), (38, 30), (39, 30),
    }
    walkable = tunnel | citadel_tiles | {spawn}

    q = deque([spawn])
    prev = {spawn: None}
    found = None
    while q:
        c = q.popleft()
        if c in citadel_tiles:
            found = c
            break
        x, y = c
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            n = (x + dx, y + dy)
            if n in walkable and n not in prev:
                prev[n] = c
                q.append(n)
    if found is None:
        raise RuntimeError("No path from spawn to citadel")


def main() -> None:
    tunnel = build_path()
    spawn = (2, 3)
    validate_path(tunnel, spawn)
    path_list = sorted(tunnel)

    waves = [
        {"enemies": [{"type": "skitter", "count": 8, "interval": 1.0}], "clearBonus": 15},
        {"enemies": [{"type": "skitter", "count": 12, "interval": 0.9}], "clearBonus": 15},
        {"enemies": [{"type": "skitter", "count": 16, "interval": 0.8}], "clearBonus": 15},
        {"enemies": [
            {"type": "skitter", "count": 10, "interval": 0.7},
            {"type": "mite", "count": 8, "interval": 0.5},
        ], "clearBonus": 15},
        {"enemies": [{"type": "scarab", "count": 1, "interval": 0.0}], "clearBonus": 15},
        {"enemies": [
            {"type": "skitter", "count": 14, "interval": 0.7},
            {"type": "chitin", "count": 4, "interval": 1.2},
        ], "clearBonus": 20},
        {"enemies": [
            {"type": "skitter", "count": 10, "interval": 0.7},
            {"type": "mite", "count": 10, "interval": 0.5},
            {"type": "chitin", "count": 3, "interval": 1.2},
        ], "clearBonus": 20},
        {"enemies": [
            {"type": "skitter", "count": 12, "interval": 0.7},
            {"type": "mite", "count": 6, "interval": 0.5},
            {"type": "chitin", "count": 5, "interval": 1.2},
        ], "clearBonus": 20},
        {"enemies": [
            {"type": "skitter", "count": 16, "interval": 0.7},
            {"type": "mite", "count": 8, "interval": 0.5},
            {"type": "chitin", "count": 6, "interval": 1.2},
        ], "clearBonus": 20},
        {"enemies": [{"type": "scarab", "count": 2, "interval": 1.5}], "clearBonus": 20},
        {"enemies": [
            {"type": "skitter", "count": 12, "interval": 0.7},
            {"type": "mite", "count": 8, "interval": 0.5},
            {"type": "chitin", "count": 4, "interval": 1.2},
            {"type": "borer", "count": 2, "interval": 1.5},
        ], "clearBonus": 25},
        {"enemies": [
            {"type": "skitter", "count": 14, "interval": 0.7},
            {"type": "mite", "count": 10, "interval": 0.5},
            {"type": "chitin", "count": 5, "interval": 1.2},
            {"type": "borer", "count": 3, "interval": 1.5},
        ], "clearBonus": 25},
        {"enemies": [
            {"type": "skitter", "count": 16, "interval": 0.7},
            {"type": "mite", "count": 12, "interval": 0.5},
            {"type": "chitin", "count": 6, "interval": 1.2},
            {"type": "borer", "count": 4, "interval": 1.5},
        ], "clearBonus": 25},
        {"enemies": [
            {"type": "skitter", "count": 18, "interval": 0.7},
            {"type": "mite", "count": 12, "interval": 0.5},
            {"type": "chitin", "count": 8, "interval": 1.2},
            {"type": "borer", "count": 5, "interval": 1.5},
        ], "clearBonus": 25},
        {"enemies": [{"type": "scarab", "count": 3, "interval": 1.5}], "clearBonus": 25},
        {"enemies": [
            {"type": "skitter", "count": 20, "interval": 0.6},
            {"type": "mite", "count": 14, "interval": 0.5},
            {"type": "chitin", "count": 8, "interval": 1.0},
            {"type": "borer", "count": 6, "interval": 1.2},
        ], "clearBonus": 30},
        {"enemies": [
            {"type": "skitter", "count": 22, "interval": 0.6},
            {"type": "mite", "count": 16, "interval": 0.5},
            {"type": "chitin", "count": 10, "interval": 1.0},
            {"type": "borer", "count": 6, "interval": 1.2},
        ], "clearBonus": 30},
        {"enemies": [
            {"type": "skitter", "count": 24, "interval": 0.6},
            {"type": "mite", "count": 18, "interval": 0.5},
            {"type": "chitin", "count": 10, "interval": 1.0},
            {"type": "borer", "count": 8, "interval": 1.2},
        ], "clearBonus": 30},
        {"enemies": [
            {"type": "skitter", "count": 20, "interval": 0.7},
            {"type": "mite", "count": 14, "interval": 0.5},
            {"type": "chitin", "count": 8, "interval": 1.0},
            {"type": "borer", "count": 6, "interval": 1.2},
        ], "clearBonus": 30},
        {"enemies": [{"type": "scarab", "count": 4, "interval": 2.0}], "clearBonus": 30},
    ]

    level = {
        "id": "first_breach",
        "name": "First Breach",
        "gridSize": {"cols": 40, "rows": 31},
        "spawnTile": {"x": 2, "y": 3},
        "citadelRect": {"x": 37, "y": 28, "w": 3, "h": 3},
        "startingBiomass": 80,
        "startingSoldiers": 3,
        "queenMaxHp": 100,
        "deposits": [[18, 9], [22, 17]],
        "tunnelTiles": [[x, y] for x, y in path_list],
        "waves": waves,
    }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="\n", encoding="utf-8") as f:
        json.dump(level, f, indent=2)
        f.write("\n")
    print(f"wrote {OUT} ({len(path_list)} tunnel tiles, {len(waves)} waves)")


if __name__ == "__main__":
    main()
