# Architecture — Beneath the Roots (Godot)

## Project layout

```
project.godot          # main config, autoloads, 960×540 viewport
data/levels/           # level JSON (spawn, citadel, tunnels, waves)
scenes/
  menu.tscn            # level select
  game.tscn            # HUD + macro + micro shell
  macro_world.tscn     # macro tilemap gameplay (SubViewport)
  macro_panel.tscn     # SubViewport host for macro world
  citadel_world.tscn   # micro top-down citadel tilemap
  micro_panel.tscn     # SubViewport host for citadel world
assets/
  theme/game_theme.tres
  fonts/pixel.ttf
  tilesets/            # PixelLab terrain (placeholder runtime for now)
  sprites/
scripts/
  autoload/
    game_state.gd      # singleton gameplay state + signals
    game_config.gd     # layout constants
    theme_setup.gd
  data/
    game_tuning.gd     # autoload: combat constants
    level_loader.gd
  systems/
    pathfinding.gd     # AStarGrid2D
    wave_manager.gd
    combat_system.gd
  util/
    placeholder_tilesets.gd
  macro_world.gd
  citadel_world.gd
  macro_panel.gd
  micro_panel.gd
  menu.gd
  game.gd
docs/
build/web/
```

## Autoloads

| Name | Script | Role |
|------|--------|------|
| `GameState` | `game_state.gd` | Biomass, queen HP/satiety, phase, entities, signals |
| `GameConfig` | `game_config.gd` | Viewport size, macro/micro widths |
| `GameTuning` | `game_tuning.gd` | Spitter/enemy/soldier constants |
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
    ├── PanelContainer [HUD]     min height 48px
    └── HBoxContainer [Content]
        ├── PanelContainer [MacroPanel]   min width 652px
        └── PanelContainer [MicroPanel]   expands (308px)
```

Use **container-based layout** for HUD/micro chrome. Macro gameplay runs in a **SubViewport** with `TileMapLayer` + `Node2D` entities.

## Macro map anchors

- **Spawn:** top-left cave mouth (surface row)
- **Citadel breach:** bottom-right 3×3 tiles
- **Pathfinding:** `AStarGrid2D` on walkable tiles (static in Sprint 01)

## Rendering

- `default_texture_filter = Nearest` in project.godot
- Web export: **GL Compatibility** renderer only
- Integer viewport scale for pixel art

## Planned systems (sprints)

| System | Script (planned) |
|--------|------------------|
| Path follower | `scripts/systems/path_follower.gd` |
| Wave manager | `scripts/systems/wave_manager.gd` |
| Combat | `scripts/systems/combat_system.gd` |
| Colony | `scripts/systems/colony_system.gd` |
| Level data | `resources/levels/*.tres` or JSON |

## Level format

Port from Phaser prototype JSON in tag `phaser-prototype-v1` → Godot `Resource` or JSON under `data/levels/`.

## Previous prototype

Phaser + TypeScript implementation archived at git tag **`phaser-prototype-v1`**.
