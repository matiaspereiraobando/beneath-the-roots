# Beneath the Roots

Dual-screen grim survival tower defense. Defend tunnel approaches on the left while keeping the queen fed and birthing on the right.

**Jam pitch:** *Intruders crawl through the tunnels toward your queen. Hold them on the left. Keep her fed and birthing on the right.*

## Quick start

```bash
npm install
npm run dev
```

Open http://localhost:5173

## Build for itch.io

```bash
npm run build
```

Zip the `dist/` folder and upload as HTML5.

## Controls

| Key | Action |
|-----|--------|
| Click toolbar | Select build mode (Dig, towers, mine) |
| Click map | Dig / place / interact |
| Click tower | +/- soldiers, upgrade |
| Click nursery slots | Cycle ant type in queue |
| FEED QUEEN | Spend biomass to restore satiety |
| SPACE | Skip build phase timer |
| R | Restart level |
| ESC | Pause (partial) |

## Docs

- [Game Design](docs/GAME_DESIGN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Sprints](docs/SPRINTS.md)
- [Assets](docs/ASSETS.md)
