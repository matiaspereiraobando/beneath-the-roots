import type { LevelData } from '../types';
import level0 from './level0.json';
import level1 from './level1.json';
import level2 from './level2.json';
import level3 from './level3.json';

export const LEVELS: LevelData[] = [
  level0 as LevelData,
  level1 as LevelData,
  level2 as LevelData,
  level3 as LevelData,
];

export function getLevelById(id: string): LevelData | undefined {
  return LEVELS.find((l) => l.id === id);
}

export function getLevelByIndex(index: number): LevelData | undefined {
  return LEVELS[index];
}
