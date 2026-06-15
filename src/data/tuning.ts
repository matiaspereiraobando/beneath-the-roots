import type { AntType, EnemyType, TowerType } from './types';

export const TUNING = {
  buildPhaseDuration: 40,
  queenSpawnInterval: 10,
  nurseryQueueSize: 5,
  defaultNurseryQueue: ['gatherer', 'gatherer', 'gatherer', 'builder', 'soldier'] as AntType[],

  queenSatietyMax: 100,
  queenSatietyDecayWave: 4,
  queenSatietyDecayBuild: 1,
  queenFeedCost: 15,
  queenFeedAmount: 35,
  queenAutoFeedThreshold: 50,
  queenAutoFeedEfficiency: 0.5,
  queenWellFedThreshold: 70,
  queenStarveThreshold: 30,
  queenWellFedSpawnMult: 1.35,
  queenStarveFireMult: 0.65,

  digDuration: 4,
  digCost: 15,
  buildDuration: 3,

  gathererTickInterval: 2,
  gathererBiomassPerTick: 3,
  gatherersPerDeposit: 2,

  waveClearBonusBase: 20,

  towerCosts: {
    spitter: 40,
    crusher: 50,
    needle: 45,
    gland: 35,
    mine: 25,
  } as Record<TowerType | 'mine', number>,

  upgradeCosts: [30, 60],

  towerBaseSlots: 2,
  towerMaxSlots: 4,

  soldierDpsBonus: 2,
  soldierFireRateBonus: 0.15,

  towerStats: {
    spitter: { range: 140, damage: 8, fireRate: 1.2, color: 0x4a6b3a },
    crusher: { range: 70, damage: 12, fireRate: 0.8, splashRadius: 45, color: 0x6b4a3a },
    needle: { range: 110, damage: 6, fireRate: 1.5, pierce: 3, color: 0x5a5a6b },
    gland: { range: 90, damage: 0, fireRate: 0, auraDamage: 0.25, auraFireRate: 0.2, color: 0x7a4a8b },
  } as Record<TowerType, {
    range: number;
    damage: number;
    fireRate: number;
    splashRadius?: number;
    pierce?: number;
    auraDamage?: number;
    auraFireRate?: number;
    color: number;
  }>,

  enemyStats: {
    skitter: { hp: 30, speed: 55, reward: 8, damage: 8, color: 0xc44d2a },
    chitin: { hp: 80, speed: 30, reward: 15, damage: 15, color: 0x5a4a3a },
    scarab: { hp: 200, speed: 22, reward: 40, damage: 25, color: 0x3a2a1a },
  } as Record<EnemyType, { hp: number; speed: number; reward: number; damage: number; color: number }>,

  mineDamage: 40,
  mineTriggerRadius: 20,

  breachDamageMultiplier: 1,
  startingQueenHp: 100,
} as const;
