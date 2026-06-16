# Architecture — Beneath the Roots (Godot)

## Project layout

```
project.godot          # main config, autoloads, 960×540 viewport
scenes/
  menu.tscn            # level select
  game.tscn            # HUD + macro + micro shell
scripts/
  autoload/
    game_state.gd      # singleton gameplay state + signals
    game_config.gd     # layout constants (HUD height, panel ratios)
  menu.gd
  game.gd
assets/sprites/        # PNG sprites (PixelLab)
docs/                  # design docs (source of truth)
build/web/             # web export output (gitignored)
```

## Autoloads

| Name | Script | Role |
|------|--------|------|
| `GameState` | `game_state.gd` | Biomass, queen HP/satiety, phase, wave index |
| `GameConfig` | `game_config.gd` | Viewport size, macro/micro widths |

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

Use **container-based layout** for all UI. Game-world elements (path, enemies, towers) will live inside MacroPanel as `Node2D` sub-scenes later.

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
