# Sprint 02 — Dual Screen

**Status:** complete

## Goal

Both panels live simultaneously with meaningful coupling.

## Tasks

- [x] Layout: macro 68% / micro 32%, shared HUD
- [x] Micro: Queen feed, nursery queue (5 slots), warehouse
- [x] SpawnQueue: queen spawns from queue → ant pool
- [x] Queen satiety decay during waves + feed
- [x] Starvation debuff / well-fed spawn buff
- [x] Breach VFX on micro (shake, cracks, red flash)
- [x] Ant walk visual from citadel to macro

## Gate

- [x] Level 1 playable with both panels — feeding matters during waves

## Files touched

`src/micro/MicroPanel.ts`, `src/systems/ColonySystem.ts`, `src/ui/HUD.ts`
