# Assets — Beneath the Roots

## Style bible

- **Tone:** Grim underground survival
- **Palette:** Desaturated browns (#3d2e22), dark tunnels (#2a1f18), acid green attacks (#6aff4a), queen purple (#6b2d5c)
- **Grid:** Macro **32px** tiles; micro nursery **256×256** illustrated background (scaled to viewport)
- **Macro view:** Side-view tilemap — [`macro_basic_tiles.png`](assets/tilesets/macro_basic_tiles.png) + [`macro_terrain_atlas.png`](assets/tilesets/macro_terrain_atlas.png), scrollable via WASD
- **Micro view:** Cross-section nursery illustration (`assets/micro/nursery_background.png`); ants patrol `Path2D` routes
- **Entities in macro:** Side-view sprites at native size (scale 1,1) on the tilemap grid

## Sprite conventions

| Asset | Size | Path |
|-------|------|------|
| Ants (macro worker, soldier) | 16×16 | `assets/sprites/` |
| Ants (micro top-down, legacy) | 64×64 native (v2) | `assets/sprites/v2/` (macro only; micro uses side silhouettes) |
| Ants (micro side-view) | 8–32px | `assets/sprites/v2/side/` or procedural [`nursery_ant_sprites.gd`](../scripts/util/nursery_ant_sprites.gd) |
| Ant walk sheets | 64×N | `assets/sprites/v2/ants/` |
| Queen (macro) | 48×48 | `assets/sprites/queen.png` |
| Queen (micro nursery) | ~28×22 placeholder | `assets/sprites/v2/side/queen_side.png` or procedural |
| Nursery background | 256×256 | `assets/micro/nursery_background.png` (v2: `nursery_background_v2.png`) |
| Enemies | 24×32 | `assets/sprites/` |
| Towers / structures | 32×32 | `assets/sprites/` |
| Tunnel tileset (legacy PNG) | 16×16 | `assets/sprites/tunnel-tileset.png` |
| Macro basic tiles | 32×32 ×16 | `assets/tilesets/macro_basic_tiles.png` |
| Macro dirt autotile atlas | 32×32 ×256 | `assets/tilesets/macro_terrain_atlas.png` |
| Citadel interior tileset | 16×16 ×6 | `assets/tilesets/citadel_interior.png` (deprecated for micro; kept on disk) |
| UI icons | 32×32 | `assets/sprites/ui/` |

## Macro terrain atlases (hand-drawn)

**Basic row** (`macro_basic_tiles.png`, 512×32) — indices 0–15:

| Index | Type |
|-------|------|
| 0 | Sky |
| 1 | Surface (half grass / half dirt) |
| 2 | Dirt (reference; map uses autotile mask 0) |
| 3 | Tunnel |
| 4 | Build rock |
| 5 | Spawn |
| 6 | Citadel |
| 7–15 | Reserved |

**Autotile grid** (`macro_terrain_atlas.png`, 512×512) — **tile index = mask** (column `mask % 16`, row `mask / 16`):

```
NW=128   N=1    NE=2
W=64     ·      E=4
SW=32    S=16   SE=8
```

- Mask counts **TUNNEL** neighbors only (8 directions).
- `#FF00FF` cells = empty slot; engine picks closest valid subset mask at runtime.
- Add new masks by painting into the atlas; rescan on load picks them up.

Loader: [`scripts/util/macro_tileset.gd`](../scripts/util/macro_tileset.gd)  
Painter: [`scripts/systems/macro_terrain_painter.gd`](../scripts/systems/macro_terrain_painter.gd)

## Citadel interior (PixelLab, Sprint 02)

**Atlas** (`citadel_interior.png`, 96×16) — indices 0–5:

| Index | Room tile |
|-------|-----------|
| 0 | Dark chitin floor |
| 1 | Wall border |
| 2 | Nursery (green eggs) |
| 3 | Armory |
| 4 | Queen chamber |
| 5 | Corridor |

Loader: [`scripts/util/citadel_tileset.gd`](../scripts/util/citadel_tileset.gd)

Style lock: all three refs in `assets/raw/style_refs/` passed as `style_images` on every PixelLab job.

Logic cell enum order (`macro_tiles.gd`) differs from basic atlas columns for spawn/citadel; the painter maps `SPAWN` → atlas 5 and `CITADEL` → atlas 6.

## How to check if PixelLab is ready

PixelLab jobs are **async** (~30s for objects, ~100s for tilesets). Status values:

| Status | Meaning | What to do |
|--------|---------|------------|
| `processing` | Still generating | Wait, then poll again |
| `review` | Multiple candidates ready | Pick one with `select_object_frames` |
| `completed` | Ready to download | Use download URL from `get_*` response |

**Poll commands** (ask the agent, or use PixelLab MCP):

```
get_sidescroller_tileset(tileset_id="...")
get_object(object_id="...")
```

**Current status (2026-06-15):**

| Asset | Job ID | Status |
|-------|--------|--------|
| Tunnel tileset | `a0f9842a-581b-4977-9289-a6ee077bcaf6` | **completed** — [download PNG](https://api.pixellab.ai/mcp/sidescroller-tilesets/a0f9842a-581b-4977-9289-a6ee077bcaf6/image) |
| Queen | `a3716da9-32c2-42ee-a26a-183d9add8933` | **review** — pick a frame (0–15), then `select_object_frames` |
| Acid spitter | `9e004905-7e70-4cad-a091-c83bf9152647` | **review** — pick a frame (0–63) |
| Worker ant | `247a7830-ee87-4469-946d-6226133eeb8f` | **review** — pick a frame |
| Skitter enemy | `c82f5116-9dad-4983-8490-ae8a3c1e8b0b` | check with `get_object` |

For `review` status: tell the agent *"pick queen frame 3"* or browse candidates via `get_object` (shows inline images).

| Asset | Tool | Job ID | Status | Local path | Manual override |
|-------|------|--------|--------|------------|-----------------|
| Tunnel tileset | create_sidescroller_tileset | `a0f9842a-581b-4977-9289-a6ee077bcaf6` | **completed** | `assets/sprites/tunnel-tileset.png` | — |
| Queen | create_1_direction_object | `2f10fb13-4f3a-49b8-99dc-66a1dd8317f7` | **completed** (picked frame 0) | `assets/sprites/queen.png` | integrated |
| Acid spitter mound | create_1_direction_object | `6a0a0bd0-92d0-4fe6-bf0b-2ffdc0d952ab` | **completed** (picked frame 12) | `assets/sprites/spitter.png` | integrated |
| Crusher sac | create_1_direction_object | _pending_ | queued | — | — |
| Worker ant | create_1_direction_object | `f30132e3-e0e7-4114-8306-3872ff890106` | **completed** (picked frame 0) | `assets/sprites/worker.png` | integrated |
| Skitter enemy | create_1_direction_object | `d73a9004-604a-4cf8-bf2f-c9c481701d96` | **completed** (picked frame 15) | `assets/sprites/skitter.png` | integrated |

### Sprint 02 — micro citadel + UI (style refs)

| Asset | Tool | Job ID | Status | Local path |
|-------|------|--------|--------|------------|
| Citadel 6-pack | create_tiles_pro | `d018220a-082e-48e6-9795-508cdf357cb0` | **completed** | `assets/tilesets/citadel_interior.png` |
| Gatherer ant | create_1_direction_object | `558b724f-1c15-46d7-a960-c7959e5af3ba` | **completed** + walk | `assets/sprites/gatherer.png`, `ants/gatherer_walk.png` |
| Builder ant | create_1_direction_object | `f2622b34-5aa8-49dc-be8e-97be2eeb517b` | **completed** + walk | `assets/sprites/builder.png`, `ants/builder_walk.png` |
| Soldier ant (micro) | create_1_direction_object | `2d3a0bdd-25c9-42c0-bbba-de6211bacda2` | **completed** + walk | `assets/sprites/soldier_micro.png`, `ants/soldier_walk.png` |
| Queen (micro) | create_1_direction_object | `4235e5f9-5a89-4360-9534-e6694076d1f7` | **completed** | `assets/sprites/queen_micro.png` |
| UI icons (8) | create_1_direction_object batch | see `tools/_pixellab_job_ids.json` | **completed** | `assets/sprites/ui/*.png` |

Download: `https://api.pixellab.ai/mcp/objects/{object_id}/download` (zip includes walk frames).

### Sprite v2 batch (native 64×64, in progress)

Queued to fix muddy downscaled look from legacy 16px assets. Each job returns **16 review candidates** — pick the crispest frame.

| Asset | Job ID | Output |
|-------|--------|--------|
| Gatherer | `ebf44a05-9689-41d8-b7fa-74d10dfd3a89` | `assets/sprites/v2/gatherer.png` |
| Builder | `0b99a2f8-2639-41bb-9e29-3ebb5cdfde96` | `assets/sprites/v2/builder.png` |
| Soldier | `2e64ae34-ab4b-48ad-a22d-154ad35d42ca` | `assets/sprites/v2/soldier_micro.png` |
| Queen micro | `0056ebe1-a3e7-4dce-b167-cbf8add03b86` | `assets/sprites/v2/queen_micro.png` |
| UI icons (8) | `50e01605-d57a-48ec-af4c-087642a60f01` | `assets/sprites/ui/v2/` |

Loader prefers `v2/` paths automatically (`scripts/util/sprite_paths.gd`). Micro nursery uses illustrated background + side-view patrol sprites (`SpritePaths.micro_background()`, `micro_ant_sprite()`).

### Micro nursery (cross-section)

| Asset | Source | Path |
|-------|--------|------|
| Background v1 | User mock | `assets/micro/nursery_background.png` |
| Background v2 | PixelLab `create_map_object` (optional) | `assets/micro/nursery_background_v2.png` |
| Side ants | PixelLab sidescroller 32px (optional) | `assets/sprites/v2/side/*_side.png` |
| Layout anchors | Code | `scripts/data/nursery_layout.gd` |
| Path routes | Code + `Path2D` nodes | `scenes/citadel_world.tscn` |

Legacy `citadel_interior.png` tile atlas is **deprecated** for the micro panel (file kept for reference).

## Integration workflow

1. Queue job via PixelLab MCP → record UUID above
2. Poll `get_*` until complete (~2–5 min)
3. Download to `assets/raw/`
4. Copy processed sprites to `assets/sprites/`
5. Mark status `integrated` or note manual override

## Font

- **UI font:** `assets/fonts/pixel.ttf` — [Silkscreen](https://fonts.google.com/specimen/Silkscreen) (OFL)
- Import: antialiasing off, hinting none (see `[importer_defaults]` in `project.godot`)
- **Sizing:** Silkscreen is drawn on an **8px grid** — use only **8, 16, 24, 32…** px. Other sizes (9, 10, 17, 18) scale poorly and look blurry. HUD uses `HudTheme.apply_pixel_label()`.

## Current state

Game uses **hand-drawn macro terrain** and **PixelLab sprites** for macro entities. Micro panel shows a **cross-section nursery** (`nursery_background.png`) with path-patrolling side-view ants; nursery queue UI uses v2 HUD icons from Sprint 02 PixelLab jobs.
