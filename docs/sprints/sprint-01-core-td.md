# Sprint 01 — Core TD (Tilemap Foundation)

**Status:** done

## Goal

Dev Test Level: enemies enter **top-left** cave, pathfind to **bottom-right** citadel, player places Acid Spitters and assigns soldiers. Micro citadel flashes on breach.

## Tasks

- [x] Update GAME_DESIGN.md + ASSETS.md
- [x] Placeholder macro + citadel tilesets (`scripts/util/placeholder_tilesets.gd`)
- [x] Level JSON, loader, tuning, GameState expansion
- [x] Macro SubViewport + TileMap world
- [x] AStar pathfinding + wave manager
- [x] Spitter combat + soldier assign + click input
- [x] Micro top-down citadel tilemap + breach link
- [x] HUD wiring + gate

## Gate

- [x] F5 → Dev Test Level → 3 waves, spitter + soldiers, win/lose, citadel breach flashes micro

## Map conventions

- Spawn: top-left (surface / cave mouth)
- Citadel: bottom-right 3×3
- Pathfinding: static A* on walkable tiles (dig deferred to Sprint 03)

## Out of scope

Dig, dynamic A*, nursery/satiety, other towers, levels 1–3
