# Game Design — Beneath the Roots

> Source of truth for mechanics. Do not add features not listed here without updating this doc.

## Core fantasy

You are the colony mind. Queue ant births, dig chambers, assign soldiers to biological defenses, and feed the queen — simultaneously — before swarms reach her chamber.

## Tone

Grim survival. Desaturated underground palette. Wet, organic violence. Queen HP is the only lose condition.

## Screen layout

| Panel | Width | Role |
|-------|-------|------|
| HUD | Full width, 48px top | Biomass, wave, phase, queen HP, satiety |
| Macro (left) | 68% | Side-view **tilemap** (32px tiles, scrollable): sky/surface, tunnels, towers, enemies |
| Micro (right) | 32% | **Cross-section nursery**: illustrated tunnel map, queen chamber, path-patrolling ants |

### Macro map conventions (32px grid)

| Anchor | Position |
|--------|----------|
| Sky band | Top 1–2 rows (non-walkable) |
| Cave entrance / spawn | **Top-left**, surface boundary (sky meets grass) |
| Citadel breach zone | **Bottom-right** 3×3 tiles |
| Enemies | A* pathfind on walkable tunnel tiles (static grid in Sprint 01; dynamic dig in Sprint 03) |
| Camera | WASD pans the macro view; map larger than panel — path length unchanged in tile count |

Macro entity sprites render at native size (`scale 1,1`). Micro nursery uses a **256×256 side-cutaway illustration** scaled to the SubViewport; ants are side-view silhouettes on `Path2D` patrol routes.

Macro (top-down strategy map) and micro (cross-section ant farm) show the **same colony** from different viewpoints.

## Timing model

**Soft phases with light simultaneous pressure (B + A):**

- **Build phase:** 40 seconds. Dig, build, manage nursery. Mines rearm.
- **Wave phase:** Enemies spawn and path to queen. Queen satiety decays (4/sec). Player should feed every ~20–30s.
- **Auto-feed:** When satiety < 50%, colony auto-feeds at 50% efficiency if biomass available.

## Economy

**Single currency: Biomass**

| Source | Amount |
|--------|--------|
| Enemy kills | 8–40 per enemy (by type) |
| Gatherer deposits | 3 biomass / 2 sec per active deposit |
| Wave clear bonus | 15–50 per wave |

## Ant types (abstract counts)

| Type | Role |
|------|------|
| Gatherer | Auto-ticks deposits → biomass |
| Builder | Dig soft-earth tiles (costs 1 builder + 15 biomass) |
| Soldier | Assigned to towers for DPS/fire rate |

**Nursery queue:** 5 slots on micro panel. Click to cycle G/B/S. Queen spawns every 10s (faster when well-fed).

## Queen

| Stat | Value |
|------|-------|
| HP | 100–150 per level |
| Satiety max | 100 |
| Feed cost | 15 biomass |
| Feed restore | 35 satiety |
| Well-fed threshold | 70+ → 35% faster spawn |
| Starve threshold | <30 → 65% tower fire rate |

## Structures (macro)

| Structure | Cost | Behavior |
|-----------|------|----------|
| Acid Spitter | 40 | Single-target ranged acid |
| Crusher sac | 50 | Short range AoE splash |
| Needle gallery | 45 | Pierce through 3 enemies |
| Pheromone gland | 35 | Aura: +25% dmg, +20% fire rate to nearby towers |
| Fungal mine | 25 | Path trap, 40 dmg, 1 use/wave, rearms on build phase |

**Dig:** Soft-earth tiles → 4s dig → build node. Pre-dug nodes on level start.

**Tower soldiers:** 2 base slots, +1 per upgrade tier (max 4). +/- via tower click menu.

**Upgrades:** 2 tiers (30 / 60 biomass). +range, +damage, +slots.

## Enemies

| Type | HP | Speed | Damage | Reward |
|------|-----|-------|--------|--------|
| Skitter | 30 | 55 | 8 | 8 |
| Chitin | 80 | 30 | 15 | 15 |
| Scarab | 200 | 22 | 25 | 40 |

## Levels

| # | ID | Waves | Teaching |
|---|-----|-------|----------|
| 1 | level1_breach | 6 | Queue, feed, dig, spitter, soldiers |
| 2 | level2_fork | 6 | Fork path, crusher, mines |
| 3 | level3_depth | 6 | Long path, needle, gland, boss wave |

Level 0 (`level0_test`) is dev-only with 3 waves.

## Win / lose

- **Win:** Survive all waves
- **Lose:** Queen HP reaches 0
