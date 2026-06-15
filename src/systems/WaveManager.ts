import Phaser from 'phaser';
import { PathFollower } from './PathFollower';
import type { GameState } from '../state/GameState';
import type { EnemyType } from '../data/types';
import { TUNING } from '../data/tuning';

export class WaveManager {
  private state: GameState;
  private pathFollower: PathFollower;
  private spawning = false;

  constructor(state: GameState, pathFollower: PathFollower) {
    this.state = state;
    this.pathFollower = pathFollower;
  }

  update(dt: number): void {
    if (this.state.phase === 'won' || this.state.phase === 'lost') return;

    if (this.state.phase === 'build') {
      this.updateBuildPhase(dt);
      return;
    }

    if (this.state.phase === 'wave') {
      this.updateWavePhase(dt);
    }
  }

  private updateBuildPhase(dt: number): void {
    this.state.buildTimer -= dt;
    if (this.state.buildTimer <= 0) {
      this.startWave();
    }
  }

  private startWave(): void {
    const level = this.state.level;
    if (!level) return;

    if (this.state.waveIndex >= level.waves.length) {
      this.state.winGame();
      return;
    }

    this.state.phase = 'wave';
    this.state.emit('phaseChanged', 'wave');

    for (const mine of this.state.mines) {
      mine.armed = true;
    }
    this.state.emit('minesRearmed');

    const wave = level.waves[this.state.waveIndex];
    this.state.waveSpawnQueue = [];
    this.state.waveEnemiesRemaining = 0;

    let delay = 0;
    for (const group of wave.enemies) {
      delay += group.delay ?? 0;
      for (let i = 0; i < group.count; i++) {
        this.state.waveSpawnQueue.push({ type: group.type, timer: delay });
        delay += group.interval;
        this.state.waveEnemiesRemaining++;
      }
    }

    this.spawning = true;
    this.state.emit('waveStarted', this.state.waveIndex);
  }

  private updateWavePhase(dt: number): void {
    this.updateSpawns(dt);
    this.updateEnemies(dt);
    this.checkWaveComplete();
  }

  private updateSpawns(dt: number): void {
    if (!this.spawning) return;
    for (let i = this.state.waveSpawnQueue.length - 1; i >= 0; i--) {
      const entry = this.state.waveSpawnQueue[i];
      entry.timer -= dt;
      if (entry.timer <= 0) {
        this.spawnEnemy(entry.type as EnemyType);
        this.state.waveSpawnQueue.splice(i, 1);
      }
    }
    if (this.state.waveSpawnQueue.length === 0) {
      this.spawning = false;
    }
  }

  private spawnEnemy(type: EnemyType): void {
    const stats = TUNING.enemyStats[type];
    const enemy = {
      id: this.state.nextEnemyId(),
      type,
      hp: stats.hp,
      maxHp: stats.hp,
      speed: stats.speed,
      pathProgress: 0,
      reward: stats.reward,
      damage: stats.damage,
    };
    this.state.enemies.push(enemy);
    this.state.emit('enemySpawned', enemy);
  }

  private updateEnemies(dt: number): void {
    const toRemove: string[] = [];

    for (const enemy of this.state.enemies) {
      enemy.pathProgress += enemy.speed * dt;
      const pos = this.pathFollower.getPositionAtProgress(enemy.pathProgress);
      if (!pos) {
        toRemove.push(enemy.id);
        this.state.damageQueen(enemy.damage * TUNING.breachDamageMultiplier);
        this.state.emit('enemyReachedEnd', enemy);
        continue;
      }

      for (const mine of this.state.mines) {
        if (!mine.armed) continue;
        const minePos = this.pathFollower.getPositionAtIndex(mine.pathIndex);
        if (!minePos) continue;
        const dist = Phaser.Math.Distance.Between(pos.x, pos.y, minePos.x, minePos.y);
        if (dist < TUNING.mineTriggerRadius) {
          enemy.hp -= TUNING.mineDamage;
          mine.armed = false;
          this.state.emit('mineTriggered', mine);
          if (enemy.hp <= 0) {
            this.killEnemy(enemy);
            toRemove.push(enemy.id);
          }
        }
      }
    }

    this.state.enemies = this.state.enemies.filter((e) => !toRemove.includes(e.id));
  }

  killEnemy(enemy: { id: string; reward: number }): void {
    this.state.addBiomass(enemy.reward);
    this.state.waveEnemiesRemaining--;
    this.state.emit('enemyKilled', enemy);
  }

  damageEnemy(enemyId: string, damage: number, pierce = 0): void {
    const enemy = this.state.enemies.find((e) => e.id === enemyId);
    if (!enemy) return;
    enemy.hp -= damage;
    if (enemy.hp <= 0) {
      this.killEnemy(enemy);
      this.state.enemies = this.state.enemies.filter((e) => e.id !== enemyId);
    } else if (pierce > 0) {
      const behind = this.state.enemies
        .filter((e) => e.pathProgress > enemy.pathProgress && e.id !== enemyId)
        .sort((a, b) => a.pathProgress - b.pathProgress);
      for (let i = 0; i < pierce && i < behind.length; i++) {
        behind[i].hp -= damage * 0.6;
        if (behind[i].hp <= 0) {
          this.killEnemy(behind[i]);
          this.state.enemies = this.state.enemies.filter((e) => e.id !== behind[i].id);
        }
      }
    }
  }

  private checkWaveComplete(): void {
    if (this.spawning) return;
    if (this.state.enemies.length > 0) return;
    if (this.state.waveSpawnQueue.length > 0) return;

    const level = this.state.level;
    if (!level) return;

    const wave = level.waves[this.state.waveIndex];
    const bonus = wave.clearBonus ?? TUNING.waveClearBonusBase;
    this.state.addBiomass(bonus);
    this.state.waveIndex++;
    this.state.emit('waveChanged', this.state.waveIndex);

    if (this.state.waveIndex >= level.waves.length) {
      this.state.winGame();
      return;
    }

    this.state.phase = 'build';
    this.state.buildTimer = TUNING.buildPhaseDuration;
    this.state.emit('phaseChanged', 'build');
    this.state.emit('waveCleared', this.state.waveIndex - 1);
  }

  skipBuildTimer(): void {
    if (this.state.phase === 'build') {
      this.state.buildTimer = 0;
    }
  }
}
