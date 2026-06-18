# Game Design — Beneath the Roots

> Source of truth for mechanics. Do not add features not listed here without updating this doc.

## Core fantasy

You are the colony mind. Queue ant births, dig chambers, assign soldiers to biological defenses, and feed the queen — simultaneously — before swarms reach her chamber.

## Tone

Grim survival. Desaturated underground palette. Wet, organic violence. Queen HP is the only lose condition.

## Screen layout

| Panel | Width | Role |
|-------|-------|------|
| HUD | Full width (960px), 56px top | Stitch-style bar: biomass, wave + countdown ring, ant counts, HP/satiety bars |
| Macro | 880px (960 − 80px rail) | Side-view **tilemap** (32px tiles, scrollable): sky/surface, tunnels, towers, enemies |
| Colony rail | 80px (always visible) | Satiety strip, G/B/S counts, vertical nursery queue icons |
| Colony drawer | 365px (overlay, toggled) | Feed, queue editing, colony counts; **M** or tab to toggle |

### Macro map conventions (32px grid)

| Anchor | Position |
|--------|----------|
| Sky band | Top 1–2 rows (non-walkable) |
| Cave entrance / spawn | **Top-left**, surface boundary (sky meets grass) |
| Citadel breach zone | **Bottom-right** 3×3 tiles |
| Enemies | A* pathfind on walkable tunnel tiles (static grid in Sprint 01; dynamic dig in Sprint 03) |
| Camera | WASD pans the macro view; map larger than panel — path length unchanged in tile count |

Macro entity sprites render at native size (`scale 1,1`). Colony status is **icons + numbers** on the right rail; expanded drawer is UI-only (no nursery illustration in v1). Breach feedback pulses the rail; drawer does not auto-open.

Macro (strategy map) and colony panel show the **same colony** — macro for defense, rail/drawer for nursery management.

## Timing model

**Continuous play with scheduled waves:**

- **No build/wave lockout:** Dig, build, nursery, and colony management work at all times until win/lose.
- **Wave schedule:** First wave begins after `WAVE_INTERVAL` (40s). Each time a wave **starts spawning**, the timer for the **next** wave resets immediately — you do not wait for the current wave to be cleared.
- **Overlapping waves:** Enemies from multiple waves can be on the map at once; clear bonuses still apply per wave when that wave's spawns are done and all its bugs are dead.
- **Invasion pressure:** Queen satiety decays while enemies are active (on map or still spawning). Auto-feed still applies under pressure.
- **Auto-feed:** When satiety < 50% during an invasion, colony auto-feeds at 50% efficiency if biomass is available.

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
| Builder | Dig rock beside tunnels (1 builder + 15 biomass, 4s) → new tunnel tile |
| Soldier | Assigned to towers for DPS/fire rate |

**Nursery queue:** 5 slots on colony rail (clickable) and drawer. Click to cycle G/B/S. Queen spawns every 10s (faster when well-fed). Toggle drawer with **M** or the rail tab.

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

Player uses **Dig** and **Build** tools on the macro map (toolbar + keys 1–6). Select a structure type, then click the map. Hover shows a green/red footprint preview.

| Structure | Footprint | Placement | Cost | Behavior |
|-----------|-----------|-----------|------|----------|
| Acid Spitter | 2×2 | Rock, adjacent to tunnel | 40 | Single-target ranged acid |
| Crusher sac | 2×2 | Rock, adjacent to tunnel | 50 | Short range AoE splash |
| Needle gallery | 2×2 | Rock, adjacent to tunnel | 45 | Pierce through 3 enemies |
| Pheromone gland | 2×2 | Rock, adjacent to tunnel | 35 | Aura: +25% dmg, +20% fire rate to nearby towers |
| Fungal mine | 1×1 | Tunnel tile | 25 | Path trap, 40 dmg, 1 use/wave, rearms on build phase |

**Dig:** Click rock 4-way adjacent to an existing tunnel → 4s dig → **tunnel** tile. Opens new routes; enemies **repath immediately** when dig completes (including during waves).

**Tower soldiers:** 2 base slots, +1 per upgrade tier (max 4). +/- via tower click menu (any footprint tile).

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
