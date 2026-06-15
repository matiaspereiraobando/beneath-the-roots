# Architecture — Beneath the Roots

## Stack

- **Phaser 3.90** + **TypeScript** + **Vite**
- Resolution: 960×540, pixelArt render mode
- Deploy: static `dist/` → itch.io HTML5

## Scene flow

```
BootScene → MenuScene → GameScene
```

## GameState (singleton)

`src/state/GameState.ts` is the single source of truth. Extends `Phaser.Events.EventEmitter`.

Panels and systems subscribe to events; they do not own gameplay state.

### Key events

| Event | Payload | When |
|-------|---------|------|
| `biomassChanged` | number | Biomass pool changes |
| `queenHpChanged` | hp, maxHp | Queen damaged |
| `queenSatietyChanged` | number | Satiety changes |
| `phaseChanged` | 'build' \| 'wave' \| 'won' \| 'lost' | Phase transition |
| `waveChanged` | index | Wave index updates |
| `antsChanged` | antPool | Ant counts change |
| `queueChanged` | AntType[] | Nursery queue changes |
| `enemySpawned` | EnemyInstance | New enemy |
| `enemyKilled` | enemy | Enemy died |
| `enemyReachedEnd` | enemy | Breach |
| `breach` | damage | Queen damaged (VFX) |
| `towerPlaced` | TowerDefinition | Tower built |
| `towerUpgraded` | TowerDefinition | Soldier/upgrade |
| `digStarted` / `digComplete` | job | Dig progress |
| `buildStarted` / `buildComplete` | job/tower | Build progress |
| `minePlaced` / `mineTriggered` | mine | Mine lifecycle |
| `gameWon` / `gameLost` | — | End state |

## Systems (updated each frame in GameScene)

| System | File | Responsibility |
|--------|------|----------------|
| WaveManager | `systems/WaveManager.ts` | Build/wave phases, spawning, breach |
| CombatSystem | `systems/CombatSystem.ts` | Tower targeting, projectiles, damage |
| ColonySystem | `systems/ColonySystem.ts` | Satiety, spawn queue, gatherers, dig/build |
| PathFollower | `systems/PathFollower.ts` | Enemy path math |

## UI

| Component | File | Panel |
|-----------|------|-------|
| HUD | `ui/HUD.ts` | Top bar |
| MacroPanel | `macro/MacroPanel.ts` | Left TD view |
| MicroPanel | `micro/MicroPanel.ts` | Right citadel |

## Level data

JSON in `src/data/levels/`. Loaded via `src/data/levels/index.ts`.

```typescript
interface LevelData {
  id: string;
  name: string;
  queenMaxHp: number;
  path: PathPoint[];
  preDugNodes: PathPoint[];
  softEarth: Rect[];
  deposits: PathPoint[];
  waves: WaveDefinition[];
  startingBiomass?: number;
  hints?: string[];
}
```

## Balance

All tunable numbers in `src/data/tuning.ts`.

## Folder structure

```
src/
├── main.ts           # Phaser game config
├── config.ts         # Resolution, colors
├── state/GameState.ts
├── scenes/           # Boot, Menu, Game
├── systems/          # Wave, Combat, Colony, Path
├── macro/MacroPanel.ts
├── micro/MicroPanel.ts
├── ui/HUD.ts
└── data/
    ├── types.ts
    ├── tuning.ts
    └── levels/
```
