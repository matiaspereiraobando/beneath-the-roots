# Agent Onboarding — Beneath the Roots

Read these files **before** making changes:

1. [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) — mechanics source of truth
2. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — code structure and GameState
3. [docs/SPRINTS.md](docs/SPRINTS.md) — current sprint status
4. The active sprint file in `docs/sprints/`

## Rules

1. **Scope:** Only implement tasks in the current sprint file. No feature creep.
2. **State:** All gameplay state flows through `src/state/GameState.ts`. Do not duplicate state in UI panels.
3. **Art:** Placeholder rectangles are fine. Never block code on PixelLab jobs. Check `docs/ASSETS.md` for job IDs.
4. **Commits:** Use prefix `sprint-0N:` e.g. `sprint-01: add enemy path following`
5. **Session end:** Update `docs/SPRINTS.md` with status, blockers, and next task.

## Commands

```bash
npm install
npm run dev      # dev server at localhost:5173
npm run build    # production build to dist/
npm run preview  # preview production build
```

## itch.io deploy

1. `npm run build`
2. Zip contents of `dist/` folder
3. Upload to itch.io as HTML5 game

## Stack

- Phaser 3 + TypeScript + Vite
- 960×540 resolution, pixel art mode
- Split screen: macro (left 68%) + micro citadel (right 32%)
