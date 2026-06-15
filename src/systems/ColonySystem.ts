import type { GameState } from '../state/GameState';
import { nodeKey } from '../state/GameState';
import type { TowerType } from '../data/types';
import { TUNING } from '../data/tuning';

export class ColonySystem {
  private state: GameState;

  constructor(state: GameState) {
    this.state = state;
  }

  update(dt: number): void {
    this.updateSatiety(dt);
    this.updateSpawnQueue(dt);
    this.updateGatherers(dt);
    this.updateDigJobs(dt);
    this.updateBuildJobs(dt);
    this.autoFeed();
  }

  private updateSatiety(dt: number): void {
    if (this.state.phase === 'won' || this.state.phase === 'lost') return;
    const decay = this.state.phase === 'wave' ? TUNING.queenSatietyDecayWave : TUNING.queenSatietyDecayBuild;
    this.state.setSatiety(this.state.queenSatiety - decay * dt);
  }

  private updateSpawnQueue(dt: number): void {
    if (this.state.phase === 'won' || this.state.phase === 'lost') return;
    this.state.spawnTimer += dt;
    if (this.state.spawnTimer >= this.state.getSpawnInterval()) {
      this.state.spawnTimer = 0;
      this.state.spawnFromQueue();
    }
  }

  private updateGatherers(dt: number): void {
    if (!this.state.level?.deposits.length) return;
    const gatherers = this.state.antPool.gatherer;
    if (gatherers < 1) return;

    this.state.gathererTimer += dt;
    if (this.state.gathererTimer >= TUNING.gathererTickInterval) {
      this.state.gathererTimer = 0;
      const activeDeposits = Math.min(
        this.state.level.deposits.length,
        Math.floor(gatherers / TUNING.gatherersPerDeposit),
      );
      if (activeDeposits > 0) {
        this.state.addBiomass(TUNING.gathererBiomassPerTick * activeDeposits);
      }
    }
  }

  private autoFeed(): void {
    if (this.state.queenSatiety > TUNING.queenAutoFeedThreshold) return;
    if (this.state.biomass < Math.ceil(TUNING.queenFeedCost * TUNING.queenAutoFeedEfficiency)) return;
    this.state.feedQueen(false);
  }

  private updateDigJobs(dt: number): void {
    const completed: string[] = [];
    for (const job of this.state.digJobs) {
      job.progress += dt;
      if (job.progress >= job.duration) {
        this.state.setNodeState(job.x, job.y, 'ready');
        completed.push(job.tileKey);
        this.state.antPool.builder++;
        this.state.emit('digComplete', job);
        this.state.emit('antsChanged', this.state.antPool);
      }
    }
    this.state.digJobs = this.state.digJobs.filter((j) => !completed.includes(j.tileKey));
  }

  private updateBuildJobs(dt: number): void {
    const completed: string[] = [];
    for (const job of this.state.buildJobs) {
      job.progress += dt;
      if (job.progress >= job.duration) {
        completed.push(job.nodeKey);
        if (job.type === 'mine') {
          this.completeMine(job.nodeKey);
        } else {
          this.completeTower(job.nodeKey, job.type);
        }
      }
    }
    this.state.buildJobs = this.state.buildJobs.filter((j) => !completed.includes(j.nodeKey));
  }

  startDig(x: number, y: number): boolean {
    const state = this.state.getNodeState(x, y);
    if (state !== 'empty') return false;
    if (this.state.antPool.builder < 1) return false;
    if (!this.state.spendBiomass(TUNING.digCost)) return false;

    this.state.antPool.builder--;
    this.state.setNodeState(x, y, 'digging');
    const tileKey = nodeKey(x, y);
    this.state.digJobs.push({
      tileKey,
      x,
      y,
      progress: 0,
      duration: TUNING.digDuration,
    });
    this.state.emit('digStarted', { x, y });
    this.state.emit('antsChanged', this.state.antPool);
    return true;
  }

  startBuild(x: number, y: number, type: TowerType | 'mine', pathIndex?: number): boolean {
    const state = this.state.getNodeState(x, y);
    if (state !== 'ready') return false;

    const cost = TUNING.towerCosts[type];
    if (!this.state.spendBiomass(cost)) return false;

    const nodeKeyStr = nodeKey(x, y);
    this.state.setNodeState(x, y, 'building');
    this.state.buildJobs.push({
      nodeKey: pathIndex !== undefined ? `mine_${pathIndex}` : nodeKeyStr,
      type,
      progress: 0,
      duration: TUNING.buildDuration,
    });

    if (type === 'mine' && pathIndex !== undefined) {
      this.state.emit('buildStarted', { x, y, type, pathIndex });
    } else {
      this.state.emit('buildStarted', { x, y, type });
    }
    return true;
  }

  private completeTower(nodeKeyStr: string, type: TowerType): void {
    const [xs, ys] = nodeKeyStr.split(',');
    const x = Number(xs);
    const y = Number(ys);
    const tower = {
      id: `tower_${this.state.towers.length}`,
      type,
      x,
      y,
      soldiers: 0,
      upgradeTier: 0,
    };
    this.state.towers.push(tower);
    this.state.setNodeState(x, y, 'built');
    this.state.emit('towerPlaced', tower);
    this.state.emit('buildComplete', tower);
  }

  private completeMine(nodeKeyStr: string): void {
    const pathIndex = Number(nodeKeyStr.replace('mine_', ''));
    const mine = {
      id: this.state.nextMineId(),
      pathIndex,
      armed: this.state.phase === 'build',
    };
    this.state.mines.push(mine);
    this.state.emit('minePlaced', mine);
    this.state.emit('buildComplete', mine);
  }

  assignSoldier(towerId: string): boolean {
    if (this.state.unassignedSoldiers < 1) return false;
    const tower = this.state.towers.find((t) => t.id === towerId);
    if (!tower) return false;
    if (tower.soldiers >= this.state.getTowerSlots(tower)) return false;
    tower.soldiers++;
    this.state.unassignedSoldiers--;
    this.state.emit('towerUpgraded', tower);
    return true;
  }

  removeSoldier(towerId: string): boolean {
    const tower = this.state.towers.find((t) => t.id === towerId);
    if (!tower || tower.soldiers < 1) return false;
    tower.soldiers--;
    this.state.unassignedSoldiers++;
    this.state.emit('towerUpgraded', tower);
    return true;
  }

  upgradeTower(towerId: string): boolean {
    const tower = this.state.towers.find((t) => t.id === towerId);
    if (!tower) return false;
    if (tower.upgradeTier >= TUNING.upgradeCosts.length) return false;
    const cost = TUNING.upgradeCosts[tower.upgradeTier];
    if (!this.state.spendBiomass(cost)) return false;
    tower.upgradeTier++;
    this.state.emit('towerUpgraded', tower);
    return true;
  }

  placeMine(pathIndex: number): boolean {
    if (this.state.mines.some((m) => m.pathIndex === pathIndex)) return false;
    if (!this.state.spendBiomass(TUNING.towerCosts.mine)) return false;

    this.state.buildJobs.push({
      nodeKey: `mine_${pathIndex}`,
      type: 'mine',
      progress: 0,
      duration: TUNING.buildDuration,
    });
    this.state.emit('buildStarted', { type: 'mine', pathIndex });
    return true;
  }
}
