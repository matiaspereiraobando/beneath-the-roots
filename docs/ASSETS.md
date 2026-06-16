# Assets — Beneath the Roots

## Style bible

- **Tone:** Grim underground survival
- **Palette:** Desaturated browns (#3d2e22), dark tunnels (#2a1f18), acid green attacks (#6aff4a), queen purple (#6b2d5c)
- **Grid:** Macro **32px** tiles; micro/citadel **16px** tiles
- **Macro view:** Side-view sidescroller tilemap (`assets/tilesets/macro_terrain.tres`), scrollable via WASD
- **Micro view:** Top-down citadel tilemap (`assets/tilesets/citadel_interior.tres`)
- **Entities in macro:** Side-view sprites at native size (scale 1,1) on the tilemap grid

## Sprite conventions

| Asset | Size | Path |
|-------|------|------|
| Ants (worker, soldier) | 16×16 | `assets/sprites/` |
| Enemies | 24×32 | `assets/sprites/` |
| Towers / structures | 32×32 | `assets/sprites/` |
| Queen | 48×48 | `assets/sprites/queen.png` |
| Tunnel tileset (legacy PNG) | 16×16 | `assets/sprites/tunnel-tileset.png` |
| Macro terrain tileset | 32×32 | `assets/tilesets/macro_terrain.tres` |
| Citadel interior tileset | 16×16 | `assets/tilesets/citadel_interior.tres` |
| UI icons | 16×16 | `assets/sprites/ui/` |

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

## Integration workflow

1. Queue job via PixelLab MCP → record UUID above
2. Poll `get_*` until complete (~2–5 min)
3. Download to `assets/raw/`
4. Copy processed sprites to `assets/sprites/`
5. Mark status `integrated` or note manual override

## Font

- **UI font:** `assets/fonts/pixel.ttf` — [Silkscreen](https://fonts.google.com/specimen/Silkscreen) (OFL)
- Import: antialiasing off, hinting none (see `[importer_defaults]` in `project.godot`)

## Current state

Game uses **real PixelLab sprites** where integrated; remaining structures use colored placeholders until art is ready.
