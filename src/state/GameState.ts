import Phaser from 'phaser';
import type {
  AntType,
  BuildJob,
  BuildNodeState,
  DigJob,
  EnemyInstance,
  GamePhase,
  LevelData,
  MinePlacement,
  ProjectileInstance,
  TowerDefinition,
} from '../data/types';
import { TUNING } from '../data/tuning';

export type GameEvent =
  | 'biomassChanged'
  | 'queenHpChanged'
  | 'queenSatietyChanged'
  | 'phaseChanged'
  | 'waveChanged'
  | 'antsChanged'
  | 'queueChanged'
  | 'enemySpawned'
  | 'enemyKilled'
  | 'enemyReachedEnd'
  | 'towerPlaced'
  | 'towerUpgraded'
  | 'digStarted'
  | 'digComplete'
  | 'buildStarted'
  | 'buildComplete'
  | 'minePlaced'
  | 'mineTriggered'
  | 'breach'
  | 'levelLoaded'
  | 'gameWon'
  | 'gameLost'
  | 'hint'
  | 'antSpawned'
  | 'minesRearmed'
  | 'waveStarted'
  | 'waveCleared';

export class GameState extends Phaser.Events.EventEmitter {
  private static instance: GameState | null = null;

  biomass = 50;
  queenHp: number = TUNING.startingQueenHp;
  queenMaxHp: number = TUNING.startingQueenHp;
  queenSatiety: number = TUNING.queenSatietyMax;
  phase: GamePhase = 'build';
  waveIndex = 0;
  buildTimer: number = TUNING.buildPhaseDuration;
  spawnTimer = 0;

  antPool: Record<AntType, number> = { gatherer: 2, builder: 1, soldier: 1 };
  nurseryQueue: AntType[] = [...TUNING.defaultNurseryQueue];
  unassignedSoldiers = 0;

  level: LevelData | null = null;
  enemies: EnemyInstance[] = [];
  projectiles: ProjectileInstance[] = [];
  towers: TowerDefinition[] = [];
  mines: MinePlacement[] = [];

  nodeStates = new Map<string, BuildNodeState>();
  digJobs: DigJob[] = [];
  buildJobs: BuildJob[] = [];

  gathererTimer = 0;
  waveSpawnQueue: { type: string; timer: number }[] = [];
  waveEnemiesRemaining = 0;
  towerCooldowns = new Map<string, number>();
  muted = false;
  hints: string[] = [];
  hintIndex = 0;

  private enemyIdCounter = 0;
  private projectileIdCounter = 0;
  private mineIdCounter = 0;

  static getInstance(): GameState {
    if (!GameState.instance) {
      GameState.instance = new GameState();
    }
    return GameState.instance;
  }

  static reset(): GameState {
    GameState.instance = new GameState();
    return GameState.instance;
  }

  loadLevel(level: LevelData): void {
    this.level = level;
    this.biomass = level.startingBiomass ?? 50;
    this.queenMaxHp = level.queenMaxHp;
    this.queenHp = level.queenMaxHp;
    this.queenSatiety = TUNING.queenSatietyMax;
    this.phase = 'build';
    this.waveIndex = 0;
    this.buildTimer = TUNING.buildPhaseDuration;
    this.spawnTimer = 0;
    this.antPool = { gatherer: 2, builder: 1, soldier: 1 };
    this.nurseryQueue = [...TUNING.defaultNurseryQueue];
    this.unassignedSoldiers = 1;
    this.enemies = [];
    this.projectiles = [];
    this.towers = [];
    this.mines = [];
    this.digJobs = [];
    this.buildJobs = [];
    this.nodeStates.clear();
    this.towerCooldowns.clear();
    this.waveSpawnQueue = [];
    this.waveEnemiesRemaining = 0;
    this.gathererTimer = 0;
    this.hints = level.hints ?? [];
    this.hintIndex = 0;
    this.enemyIdCounter = 0;
    this.projectileIdCounter = 0;
    this.mineIdCounter = 0;

    for (const node of level.preDugNodes) {
      const key = nodeKey(node.x, node.y);
      this.nodeStates.set(key, 'ready');
    }
    for (const tile of level.softEarth) {
      const key = nodeKey(tile.x, tile.y);
      if (!this.nodeStates.has(key)) {
        this.nodeStates.set(key, 'empty');
      }
    }

    this.emit('levelLoaded', level);
    this.emit('biomassChanged', this.biomass);
    this.emit('queenHpChanged', this.queenHp, this.queenMaxHp);
    this.emit('queenSatietyChanged', this.queenSatiety);
    this.emit('phaseChanged', this.phase);
    this.emit('waveChanged', this.waveIndex);
    this.emit('antsChanged', this.antPool);
    this.emit('queueChanged', this.nurseryQueue);
  }

  addBiomass(amount: number): void {
    this.biomass += amount;
    this.emit('biomassChanged', this.biomass);
  }

  spendBiomass(amount: number): boolean {
    if (this.biomass < amount) return false;
    this.biomass -= amount;
    this.emit('biomassChanged', this.biomass);
    return true;
  }

  damageQueen(amount: number): void {
    if (this.phase === 'won' || this.phase === 'lost') return;
    this.queenHp = Math.max(0, this.queenHp - amount);
    this.emit('queenHpChanged', this.queenHp, this.queenMaxHp);
    this.emit('breach', amount);
    if (this.queenHp <= 0) {
      this.phase = 'lost';
      this.emit('phaseChanged', this.phase);
      this.emit('gameLost');
    }
  }

  feedQueen(manual = true): boolean {
    const cost = manual ? TUNING.queenFeedCost : Math.ceil(TUNING.queenFeedCost * TUNING.queenAutoFeedEfficiency);
    if (!this.spendBiomass(cost)) return false;
    const amount = manual ? TUNING.queenFeedAmount : TUNING.queenFeedAmount * TUNING.queenAutoFeedEfficiency;
    this.queenSatiety = Math.min(TUNING.queenSatietyMax, this.queenSatiety + amount);
    this.emit('queenSatietyChanged', this.queenSatiety);
    return true;
  }

  setSatiety(value: number): void {
    this.queenSatiety = Phaser.Math.Clamp(value, 0, TUNING.queenSatietyMax);
    this.emit('queenSatietyChanged', this.queenSatiety);
  }

  cycleQueueSlot(index: number): void {
    const types: AntType[] = ['gatherer', 'builder', 'soldier'];
    const current = this.nurseryQueue[index];
    const next = types[(types.indexOf(current) + 1) % types.length];
    this.nurseryQueue[index] = next;
    this.emit('queueChanged', this.nurseryQueue);
  }

  spawnFromQueue(): void {
    const type = this.nurseryQueue.shift()!;
    this.nurseryQueue.push(type);
    this.antPool[type]++;
    if (type === 'soldier') {
      this.unassignedSoldiers++;
    }
    this.emit('queueChanged', this.nurseryQueue);
    this.emit('antsChanged', this.antPool);
    this.emit('antSpawned', type);
  }

  getSpawnInterval(): number {
    let interval = TUNING.queenSpawnInterval;
    if (this.queenSatiety >= TUNING.queenWellFedThreshold) {
      interval /= TUNING.queenWellFedSpawnMult;
    }
    return interval;
  }

  getFireRateMultiplier(): number {
    if (this.queenSatiety <= TUNING.queenStarveThreshold) {
      return TUNING.queenStarveFireMult;
    }
    return 1;
  }

  nextEnemyId(): string {
    return `enemy_${++this.enemyIdCounter}`;
  }

  nextProjectileId(): string {
    return `proj_${++this.projectileIdCounter}`;
  }

  nextMineId(): string {
    return `mine_${++this.mineIdCounter}`;
  }

  getNodeState(x: number, y: number): BuildNodeState | undefined {
    return this.nodeStates.get(nodeKey(x, y));
  }

  setNodeState(x: number, y: number, state: BuildNodeState): void {
    this.nodeStates.set(nodeKey(x, y), state);
  }

  getTowerSlots(tower: TowerDefinition): number {
    return Math.min(TUNING.towerMaxSlots, TUNING.towerBaseSlots + tower.upgradeTier);
  }

  getTowerStats(tower: TowerDefinition) {
    const base = TUNING.towerStats[tower.type];
    const tierMult = 1 + tower.upgradeTier * 0.25;
    const soldierDmg = tower.soldiers * TUNING.soldierDpsBonus;
    const soldierRate = 1 + tower.soldiers * TUNING.soldierFireRateBonus;
    return {
      range: base.range * (1 + tower.upgradeTier * 0.1),
      damage: (base.damage + soldierDmg) * tierMult,
      fireRate: base.fireRate * soldierRate * tierMult,
      splashRadius: base.splashRadius,
      pierce: base.pierce,
      auraDamage: base.auraDamage,
      auraFireRate: base.auraFireRate,
      color: base.color,
    };
  }

  getAuraBuff(tower: TowerDefinition): { damage: number; fireRate: number } {
    let damage = 0;
    let fireRate = 0;
    for (const other of this.towers) {
      if (other.id === tower.id || other.type !== 'gland') continue;
      const dist = Phaser.Math.Distance.Between(tower.x, tower.y, other.x, other.y);
      const glandStats = TUNING.towerStats.gland;
      if (dist <= glandStats.range) {
        damage += glandStats.auraDamage ?? 0;
        fireRate += glandStats.auraFireRate ?? 0;
      }
    }
    return { damage, fireRate };
  }

  winGame(): void {
    this.phase = 'won';
    this.emit('phaseChanged', this.phase);
    this.emit('gameWon');
  }
}

export function nodeKey(x: number, y: number): string {
  return `${x},${y}`;
}
