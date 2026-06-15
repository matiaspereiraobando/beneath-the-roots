export const GAME_WIDTH = 960;
export const GAME_HEIGHT = 540;
export const HUD_HEIGHT = 48;
export const MACRO_RATIO = 0.68;
export const PANEL_HEIGHT = GAME_HEIGHT - HUD_HEIGHT;
export const MACRO_WIDTH = Math.floor(GAME_WIDTH * MACRO_RATIO);
export const MICRO_WIDTH = GAME_WIDTH - MACRO_WIDTH;

export const COLORS = {
  bg: 0x0a0806,
  macroBg: 0x1a1410,
  microBg: 0x120e0c,
  hudBg: 0x0d0a08,
  dirt: 0x3d2e22,
  dirtLight: 0x4a3828,
  tunnel: 0x2a1f18,
  softEarth: 0x5c4a32,
  preDug: 0x3a4a38,
  buildNode: 0x2d3d2a,
  acid: 0x6aff4a,
  acidDark: 0x3a8828,
  biomass: 0x8b6914,
  queen: 0x6b2d5c,
  queenGlow: 0x9b4d7c,
  enemySkitter: 0xc44d2a,
  enemyChitin: 0x5a4a3a,
  enemyScarab: 0x3a2a1a,
  spitter: 0x4a6b3a,
  crusher: 0x6b4a3a,
  needle: 0x5a5a6b,
  gland: 0x7a4a8b,
  mine: 0x4a6b2a,
  text: '#c8b8a8',
  textDim: '#6a5a4a',
  danger: '#cc3333',
  satiety: '#8b6914',
  satietyLow: '#882222',
} as const;
