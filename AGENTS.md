# Agent Onboarding — Beneath the Roots (Godot)

Read these files **before** making changes:

1. [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) — mechanics source of truth
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Godot structure and autoloads
3. [docs/SPRINTS.md](docs/SPRINTS.md) — current sprint status
4. The active sprint file in `docs/sprints/`

## Rules

1. **Scope:** Only implement tasks in the current sprint file.
2. **State:** All gameplay state flows through `GameState` autoload (`scripts/autoload/game_state.gd`).
3. **UI:** Use Godot `Control` nodes with containers (VBox/HBox/Margin/Panel) — no manual pixel positioning unless in the game world layer.
4. **Art:** Placeholders OK. Check `docs/ASSETS.md` for PixelLab job IDs.
5. **Commits:** Prefix `sprint-0N:` e.g. `sprint-01: add path follower`
6. **Phaser archive:** Tag `phaser-prototype-v1` — do not resurrect Phaser files on `master`.

## Commands

Open project in Godot 4.3+ and press **F5**, or:

```bash
godot --path "D:/MATIAS/PROJECTS/Games/beneath-the-roots"
```

Godot MCP tools: `create_scene`, `add_node`, `run_project`, `get_project_info`.

## Web export

Project → Export → Web → export folder → zip → itch.io (HTML, play in browser).

## Stack

- Godot 4 + GDScript
- 960×540, `canvas_items` stretch, nearest texture filter
- Macro 68% / Micro 32% / HUD 48px
