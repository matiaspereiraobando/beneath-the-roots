# Sprint 02 — Dual Screen

**Status:** done

## Goal

Micro citadel becomes a live colony sim alongside macro TD: nursery queue, queen feeding, satiety decay, gatherer income, and wandering ant visuals. Art from PixelLab using `assets/raw/style_refs/` style lock.

## Tasks

- [x] Encode style refs for PixelLab (`tools/_pixellab_style_images.json`)
- [x] Queue PixelLab jobs (citadel tiles, ants, queen, UI icons)
- [x] `colony_system.gd` + GameState nursery/satiety/feed/spawn
- [x] Nursery UI + feed button in `micro_panel`
- [x] `citadel_tileset.gd` + `citadel_interior.png`
- [x] Ant wander layer + queen sprite in `citadel_world`
- [x] HUD stat icons + starve fire-rate penalty
- [x] Docs + gate

## Gate

1. F5 → **Dev Test Level**
2. Click nursery slots — cycle G / B / S
3. ~10s spawn from first queued slot; counts update
4. **Feed** costs 15 biomass, +35 satiety
5. Satiety decays during wave; auto-feed below 50%
6. Below 30% satiety — spitter fires slower
7. Gatherers add biomass every 2s
8. Soldier spawns increase assignable pool
9. Citadel shows tile art + moving ants
10. HUD shows biomass/satiety/soldier icons

## Out of scope

Dig, extra towers, levels 1–3 (Sprint 03–04).
