import Phaser from 'phaser';
import type { GameState } from '../state/GameState';
import type { EnemyInstance, TowerDefinition } from '../data/types';
import type { WaveManager } from './WaveManager';

export class CombatSystem {
  private state: GameState;
  private waveManager: WaveManager;
  private enemyPosGetter: ((enemy: EnemyInstance) => { x: number; y: number } | null) | null = null;

  constructor(state: GameState, waveManager: WaveManager) {
    this.state = state;
    this.waveManager = waveManager;
  }

  bindEnemyPositions(getter: (enemy: EnemyInstance) => { x: number; y: number } | null): void {
    this.enemyPosGetter = getter;
  }

  update(dt: number): void {
    if (this.state.phase !== 'wave') return;

    for (const tower of this.state.towers) {
      if (tower.type === 'gland') continue;
      this.updateTower(tower, dt);
    }

    this.updateProjectiles(dt);
  }

  private updateTower(tower: TowerDefinition, dt: number): void {
    const stats = this.state.getTowerStats(tower);
    const aura = this.state.getAuraBuff(tower);
    const fireMult = this.state.getFireRateMultiplier() * (1 + aura.fireRate);
    const dmgMult = 1 + aura.damage;

    let cd = this.state.towerCooldowns.get(tower.id) ?? 0;
    cd -= dt;
    if (cd > 0) {
      this.state.towerCooldowns.set(tower.id, cd);
      return;
    }

    const target = this.findTarget(tower, stats.range);
    if (!target) return;

    const damage = stats.damage * dmgMult;
    const interval = stats.fireRate > 0 ? 1 / (stats.fireRate * fireMult) : 999;

    if (tower.type === 'crusher' && stats.splashRadius) {
      this.splashDamage(target, damage, stats.splashRadius);
      this.state.emit('towerFired', tower, target, 'splash');
    } else if (tower.type === 'needle' && stats.pierce) {
      this.waveManager.damageEnemy(target.id, damage, stats.pierce);
      this.state.emit('towerFired', tower, target, 'pierce');
    } else {
      this.state.projectiles.push({
        id: this.state.nextProjectileId(),
        x: tower.x,
        y: tower.y,
        targetId: target.id,
        damage,
        speed: 200,
        towerType: tower.type,
      });
      this.state.emit('towerFired', tower, target, 'projectile');
    }

    this.state.towerCooldowns.set(tower.id, interval);
  }

  private findTarget(tower: TowerDefinition, range: number): EnemyInstance | null {
    let best: EnemyInstance | null = null;
    let bestProgress = -1;
    for (const enemy of this.state.enemies) {
      const pos = this.getEnemyPos(enemy);
      if (!pos) continue;
      const dist = Phaser.Math.Distance.Between(tower.x, tower.y, pos.x, pos.y);
      if (dist <= range && enemy.pathProgress > bestProgress) {
        best = enemy;
        bestProgress = enemy.pathProgress;
      }
    }
    return best;
  }

  private getEnemyPos(enemy: EnemyInstance): { x: number; y: number } | null {
    return this.enemyPosGetter?.(enemy) ?? null;
  }

  private splashDamage(center: EnemyInstance, damage: number, radius: number): void {
    const centerPos = this.getEnemyPos(center);
    if (!centerPos) return;
    for (const enemy of [...this.state.enemies]) {
      const pos = this.getEnemyPos(enemy);
      if (!pos) continue;
      const dist = Phaser.Math.Distance.Between(centerPos.x, centerPos.y, pos.x, pos.y);
      if (dist <= radius) {
        this.waveManager.damageEnemy(enemy.id, damage * (1 - (dist / radius) * 0.5));
      }
    }
  }

  private updateProjectiles(dt: number): void {
    const toRemove: string[] = [];
    for (const proj of this.state.projectiles) {
      const target = this.state.enemies.find((e) => e.id === proj.targetId);
      if (!target) {
        toRemove.push(proj.id);
        continue;
      }
      const targetPos = this.getEnemyPos(target);
      if (!targetPos) {
        toRemove.push(proj.id);
        continue;
      }
      const dx = targetPos.x - proj.x;
      const dy = targetPos.y - proj.y;
      const dist = Math.hypot(dx, dy);
      if (dist < 8) {
        this.waveManager.damageEnemy(target.id, proj.damage);
        toRemove.push(proj.id);
        this.state.emit('projectileHit', proj, target);
      } else {
        proj.x += (dx / dist) * proj.speed * dt;
        proj.y += (dy / dist) * proj.speed * dt;
      }
    }
    this.state.projectiles = this.state.projectiles.filter((p) => !toRemove.includes(p.id));
  }
}
