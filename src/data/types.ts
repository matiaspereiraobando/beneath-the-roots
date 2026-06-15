export type AntType = 'gatherer' | 'builder' | 'soldier';
export type GamePhase = 'build' | 'wave' | 'won' | 'lost';
export type TowerType = 'spitter' | 'crusher' | 'needle' | 'gland';
export type EnemyType = 'skitter' | 'chitin' | 'scarab';
export type BuildNodeState = 'empty' | 'digging' | 'ready' | 'building' | 'built';

export interface PathPoint {
  x: number;
  y: number;
}

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface WaveEnemySpawn {
  type: EnemyType;
  count: number;
  interval: number;
  delay?: number;
}

export interface WaveDefinition {
  enemies: WaveEnemySpawn[];
  clearBonus?: number;
}

export interface LevelData {
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

export interface TowerDefinition {
  id: string;
  type: TowerType;
  x: number;
  y: number;
  soldiers: number;
  upgradeTier: number;
}

export interface DigJob {
  tileKey: string;
  x: number;
  y: number;
  progress: number;
  duration: number;
}

export interface BuildJob {
  nodeKey: string;
  type: TowerType | 'mine';
  progress: number;
  duration: number;
}

export interface MinePlacement {
  id: string;
  pathIndex: number;
  armed: boolean;
}

export interface EnemyInstance {
  id: string;
  type: EnemyType;
  hp: number;
  maxHp: number;
  speed: number;
  pathProgress: number;
  reward: number;
  damage: number;
  pierceRemaining?: number;
}

export interface ProjectileInstance {
  id: string;
  x: number;
  y: number;
  targetId: string;
  damage: number;
  speed: number;
  towerType: TowerType;
  pierce?: number;
  splashRadius?: number;
}
