# Sprint 03 — Colony Systems

**Status:** done

## Goal

Macro interaction set: dig soft earth into build nodes, dynamic pathfinding refresh, and all structure types (Spitter, Crusher, Needle, Gland, Fungal mine). Gate on `level0_test`; levels 1–3 deferred to Sprint 04.

## Tasks

- [x] `SOFT_EARTH` cell type + atlas index 7 + `softEarthTiles` / `preDugNodes` in level loader
- [x] Dig jobs (builder + 15 biomass, 4s) → `BUILD` tile
- [x] `pathfinding.rebuild()` + terrain `refresh_region` on dig complete
- [x] `place_tower(type)` + `TOWER_STATS` combat dispatch
- [x] Fungal mines on tunnel tiles (trigger once/wave, rearm on BUILD)
- [x] Build-mode hotkeys 1–5 in macro view
- [x] Extend `level0_test.json` with soft earth + pre-dug node
- [x] Docs + gate

## Deferred (Sprint 04)

- Tower upgrades (2 tiers)
- Deposit-based gatherer income
- `level1_breach` / `level2_fork` / `level3_depth`
- Web export

## Gate

1. F5 → **Dev Test Level**
2. Queue a builder; click brown soft-earth tile → dig starts (−15 biomass, ~4s)
3. Dig completes → green build ring; builder returns
4. Keys **1–4** select tower type; click build tile to place
5. Key **5** + tunnel click places mine; mine triggers once per wave; rearms next BUILD
6. Crusher splashes, Needle pierces, Gland buffs nearby towers
7. Wave spawns after dig without pathfinding errors

## Files touched

`scripts/data/macro_tiles.gd`, `level_loader.gd`, `game_tuning.gd`, `game_state.gd`, `colony_system.gd`, `pathfinding.gd`, `combat_system.gd`, `macro_world.gd`, `macro_terrain_painter.gd`, `macro_tileset.gd`, `data/levels/level0_test.json`, `project.godot`, `scripts/game.gd`

## Enemy repath policy

New spawns use refreshed A* after dig. Enemies already on path keep their current route.
