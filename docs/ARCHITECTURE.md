# Architecture — Beneath the Roots (Godot)

## Project layout

```
project.godot          # main config, autoloads, 960×540 viewport
data/levels/           # level JSON (spawn, citadel, tunnels, waves)
scenes/
  menu.tscn            # level select
  game.tscn            # HUD + macro + colony rail/drawer shell
  macro_world.tscn     # macro tilemap gameplay (SubViewport)
  macro_panel.tscn     # SubViewport host for macro world
  colony_panel.tscn    # collapsible colony rail + overlay drawer
  colony_rail.tscn     # minimized 56px status strip
  colony_drawer.tscn   # expanded nursery UI overlay
  citadel_world.tscn   # nursery illustration (deferred from UI)
assets/
  theme/game_theme.tres
  fonts/pixel.ttf
  tilesets/            # macro_basic_tiles.png, macro_terrain_atlas.png
  sprites/
scripts/
  autoload/
    game_state.gd      # singleton gameplay state + signals
    game_config.gd     # layout constants
    theme_setup.gd
  data/
    game_tuning.gd     # autoload: combat + colony constants
    ant_types.gd       # GATHERER / BUILDER / SOLDIER enum
    level_loader.gd
  systems/
    pathfinding.gd     # AStarGrid2D
    wave_manager.gd
    combat_system.gd
    colony_system.gd   # satiety, queen spawn, gatherers
    macro_terrain_painter.gd  # dirt autotile mask painting
  util/
    macro_tileset.gd         # macro TileSet from PNG atlases
    citadel_tileset.gd       # micro citadel TileSet from PNG atlas
    placeholder_tilesets.gd  # fallback colors if PNG missing
    colony_ui_icons.gd       # shared nursery icon loading for rail/drawer
  macro_world.gd
  citadel_world.gd
  macro_panel.gd
  colony_panel.gd
  colony_rail.gd
  colony_drawer.gd
  menu.gd
  game.gd
docs/
build/web/
```

## Autoloads

| Name | Script | Role |
|------|--------|------|
| `GameState` | `game_state.gd` | Biomass, queen HP/satiety, phase, entities, signals |
| `GameConfig` | `game_config.gd` | Viewport size, macro width, colony rail/drawer widths |
| `GameTuning` | `game_tuning.gd` | Spitter/enemy/soldier + colony tuning |
| `ThemeSetup` | `theme_setup.gd` | Theme + runtime pixel font |

Panels subscribe to `GameState` signals — never duplicate state in UI scripts.

## Scene flow

```
menu.tscn  --(level selected)-->  game.tscn
game.tscn  --(ESC)-->            menu.tscn
```

## UI layout (game.tscn)

```
Control (root)
└── VBoxContainer
    ├── PanelContainer [HUD]           min height 48px
    └── Control [Content]
        ├── PanelContainer [MacroPanel]   904px (full width minus rail)
        └── Control [ColonyPanel]         anchored right
            ├── ColorRect [Scrim]         dim when drawer open (non-interactive)
            ├── PanelContainer [Drawer]   365px slide-over (default hidden)
            └── PanelContainer [Rail]     56px always visible
```

**Colony rail (default):** vertical satiety strip, G/B/S icon counts, clickable nursery queue icons, expand tab (`«`). Toggle drawer with tab or **M** (`toggle_colony_menu`).

**Colony drawer (expanded):** nursery queue, feed button, satiety label, colony counts, placeholder for future colony actions. Slides over macro; explicit minimize only (no click-outside). Breach feedback: rail **pulses** red (`GameState.citadel_breached`); drawer does not auto-open.

`citadel_world.tscn` remains on disk for future colony-interior visuals but is **not mounted** in the game UI in this layout pass.

Use **container-based layout** for HUD chrome. Macro gameplay runs in a **SubViewport** with `TileMapLayer` + `Node2D` entities and a **Camera2D** (WASD pan, clamped to map bounds). The viewport shows a window into the full level grid; tile size is 32px (`GameTuning.TILE_SIZE`).

`macro_world.gd` ticks **wave_manager**, **combat_system**, and **colony_system** each frame.

Colony UI (`colony_rail.gd`, `colony_drawer.gd`) drives `GameState.nursery_queue` and feed actions via shared helpers in `colony_ui_icons.gd`.

Macro visuals: logic grid in `level_data.cells` → `MacroTerrainPainter` picks basic tiles or dirt autotile masks (tunnel-neighbor bitmask) → `MacroTileset` atlas sources.

## Macro map anchors

- **Spawn:** top-left cave mouth (surface row)
- **Citadel breach:** bottom-right 3×3 tiles
- **Pathfinding:** `AStarGrid2D` on walkable tiles (static in Sprint 01)
- **Camera:** starts centered on spawn; `macro_pan_*` input actions (WASD) pan within bounds

## Rendering

- `default_texture_filter = Nearest` in project.godot
- Web export: **GL Compatibility** renderer only
- Integer viewport scale for pixel art

## Systems

| System | Script | Status |
|--------|--------|--------|
| Pathfinding | `scripts/systems/pathfinding.gd` | Sprint 01 |
| Wave manager | `scripts/systems/wave_manager.gd` | Sprint 01 |
| Combat | `scripts/systems/combat_system.gd` | Sprint 01 (+ starve penalty Sprint 02) |
| Colony | `scripts/systems/colony_system.gd` | Sprint 02 |
| Macro terrain | `scripts/systems/macro_terrain_painter.gd` | Sprint 01 |

## Level format

Port from Phaser prototype JSON in tag `phaser-prototype-v1` → Godot `Resource` or JSON under `data/levels/`.

## Previous prototype

Phaser + TypeScript implementation archived at git tag **`phaser-prototype-v1`**.
