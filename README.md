# Beneath the Roots

Dual-screen ant colony tower defense — **Godot 4** rebuild.

The Phaser prototype is archived at git tag [`phaser-prototype-v1`](https://github.com/matiaspereiraobando/beneath-the-roots/releases/tag/phaser-prototype-v1).

## Stack

- **Godot 4.6** (GL Compatibility — required for web export)
- **GDScript**
- **960×540** viewport, integer stretch, nearest-neighbor textures
- Split screen: macro (left 68%) + micro citadel (right 32%)

## Run locally

1. Open this folder in **Godot 4.3+** (Project → Import → `project.godot`)
2. Press **F5** to run

Or via Godot MCP / CLI:

```bash
godot --path . --headless --quit  # sanity check
godot --path .
```

## Docs

| File | Purpose |
|------|---------|
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | Mechanics source of truth |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Godot project structure |
| [docs/ASSETS.md](docs/ASSETS.md) | PixelLab asset IDs |
| [docs/SPRINTS.md](docs/SPRINTS.md) | Sprint tracker |
| [AGENTS.md](AGENTS.md) | Agent onboarding |

## Web export (itch.io)

1. Project → Export → Add **Web** preset
2. Use **Compatibility** renderer, single-threaded (default in 4.3+)
3. Export to `build/web/index.html`
4. Zip **contents** of export folder → upload to itch.io as HTML
5. Check **This file will be played in the browser**

## Assets

Sprites live in `assets/sprites/` (queen, spitter, worker, skitter, tunnel tileset).
