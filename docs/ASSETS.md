# Assets — Beneath the Roots

## Style bible

- **Tone:** Grim underground survival
- **Palette:** Desaturated browns (#3d2e22), dark tunnels (#2a1f18), acid green attacks (#6aff4a), queen purple (#6b2d5c)
- **Grid:** 16px base tile
- **View:** Side-view (sidescroller) for all sprites

## Sprite conventions

| Asset | Size | Path |
|-------|------|------|
| Ants (worker, soldier) | 16×16 | `public/sprites/ants/` |
| Enemies | 24×32 | `public/sprites/enemies/` |
| Towers / structures | 32×32 | `public/sprites/towers/` |
| Queen | 48×48 | `public/sprites/queen.png` |
| Tunnel tileset | 16×16 | `public/sprites/tiles/` |
| UI icons | 16×16 | `public/sprites/ui/` |

## PixelLab job tracker

| Asset | Tool | Job ID | Status | Local path | Manual override |
|-------|------|--------|--------|------------|-----------------|
| Tunnel tileset | create_sidescroller_tileset | `a0f9842a-581b-4977-9289-a6ee077bcaf6` | processing | — | — |
| Queen | create_1_direction_object | `a3716da9-32c2-42ee-a26a-183d9add8933` | processing | — | — |
| Acid spitter mound | create_1_direction_object | `9e004905-7e70-4cad-a091-c83bf9152647` | processing | — | — |
| Crusher sac | create_1_direction_object | _pending_ | queued | — | — |
| Worker ant | create_1_direction_object | _pending_ | queued | — | — |
| Skitter enemy | create_1_direction_object | _pending_ | queued | — | — |

## Integration workflow

1. Queue job via PixelLab MCP → record UUID above
2. Poll `get_*` until complete (~2–5 min)
3. Download to `assets/raw/`
4. Copy processed sprites to `public/sprites/`
5. Update Phaser BootScene to load real textures
6. Mark status `integrated` or note manual override

## Current state

Game uses **colored placeholder rectangles** from Sprint 0. Real art is optional polish — game is fully playable without it.
