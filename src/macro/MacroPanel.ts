import Phaser from 'phaser';
import { COLORS, MACRO_WIDTH, PANEL_HEIGHT } from '../config';
import type { GameState } from '../state/GameState';
import type { ColonySystem } from '../systems/ColonySystem';
import { PathFollower } from '../systems/PathFollower';
import type { LevelData, MinePlacement, TowerDefinition, TowerType } from '../data/types';
import { TUNING } from '../data/tuning';

export class MacroPanel extends Phaser.GameObjects.Container {
  private gameState: GameState;
  private colony: ColonySystem;
  private pathFollower: PathFollower | null = null;
  private gfx: Phaser.GameObjects.Graphics;
  private enemySprites = new Map<string, Phaser.GameObjects.Container>();
  private towerSprites = new Map<string, Phaser.GameObjects.Container>();
  private mineSprites = new Map<string, Phaser.GameObjects.Graphics>();
  private projectileGfx: Phaser.GameObjects.Graphics;
  private buildToolbar: Phaser.GameObjects.Container;
  private selectedBuild: TowerType | 'mine' | 'dig' | null = null;

  constructor(scene: Phaser.Scene, state: GameState, colony: ColonySystem) {
    super(scene, 0, 0);
    this.gameState = state;
    this.colony = colony;

    const bg = scene.add.rectangle(MACRO_WIDTH / 2, PANEL_HEIGHT / 2, MACRO_WIDTH, PANEL_HEIGHT, COLORS.macroBg);
    this.add(bg);

    this.gfx = scene.add.graphics();
    this.projectileGfx = scene.add.graphics();
    this.buildToolbar = scene.add.container(8, PANEL_HEIGHT - 44);
    this.add([this.gfx, this.projectileGfx, this.buildToolbar]);

    this.createToolbar();

    state.on('levelLoaded', (level: LevelData) => {
      this.pathFollower = new PathFollower(level.path);
      this.redraw();
    });
    state.on('enemySpawned', () => this.syncEnemies());
    state.on('enemyKilled', () => this.syncEnemies());
    state.on('enemyReachedEnd', () => this.syncEnemies());
    state.on('towerPlaced', () => this.syncTowers());
    state.on('towerUpgraded', () => this.syncTowers());
    state.on('digStarted', () => this.redraw());
    state.on('digComplete', () => this.redraw());
    state.on('buildStarted', () => this.redraw());
    state.on('buildComplete', () => {
      this.redraw();
      this.syncTowers();
      this.syncMines();
    });
    state.on('minePlaced', () => this.syncMines());
    state.on('mineTriggered', (mine: MinePlacement) => {
      const g = this.mineSprites.get(mine.id);
      if (g) {
        this.scene.tweens.add({ targets: g, alpha: 0.3, duration: 200, yoyo: true });
      }
    });
    state.on('towerFired', (tower: TowerDefinition, _target: unknown, type: string) => {
      if (type === 'splash') {
        const flash = scene.add.circle(tower.x, tower.y, 20, COLORS.acid, 0.5);
        this.add(flash);
        scene.tweens.add({ targets: flash, alpha: 0, scale: 2, duration: 300, onComplete: () => flash.destroy() });
      }
    });
    state.on('phaseChanged', () => this.redraw());

    this.setDepth(10);

    this.setInteractive(new Phaser.Geom.Rectangle(0, 0, MACRO_WIDTH, PANEL_HEIGHT), Phaser.Geom.Rectangle.Contains);
    this.on('pointerdown', (pointer: Phaser.Input.Pointer) => this.handleClick(pointer.x, pointer.y));
  }

  bindLevel(level: LevelData): void {
    this.pathFollower = new PathFollower(level.path);
    this.redraw();
  }

  private createToolbar(): void {
    const items: { label: string; type: TowerType | 'mine' | 'dig' }[] = [
      { label: 'Dig', type: 'dig' },
      { label: 'Spit', type: 'spitter' },
      { label: 'Crush', type: 'crusher' },
      { label: 'Needle', type: 'needle' },
      { label: 'Gland', type: 'gland' },
      { label: 'Mine', type: 'mine' },
    ];
    items.forEach((item, i) => {
      const btn = this.scene.add.rectangle(i * 72 + 30, 0, 64, 28, COLORS.dirt);
      btn.setStrokeStyle(1, COLORS.dirtLight);
      btn.setInteractive({ useHandCursor: true });
      const txt = this.scene.add.text(i * 72 + 30, 0, item.label, { fontSize: '10px', color: COLORS.text }).setOrigin(0.5);
      btn.on('pointerdown', () => {
        this.selectedBuild = item.type;
        this.buildToolbar.each((child: Phaser.GameObjects.GameObject) => {
          if (child instanceof Phaser.GameObjects.Rectangle) child.setFillStyle(COLORS.dirt);
        });
        btn.setFillStyle(COLORS.preDug);
      });
      this.buildToolbar.add([btn, txt]);
    });
  }

  getEnemyPosition = (enemy: { pathProgress: number }) => {
    return this.pathFollower?.getPositionAtProgress(enemy.pathProgress) ?? null;
  };

  private handleClick(x: number, y: number): void {
    if (this.gameState.phase === 'won' || this.gameState.phase === 'lost') return;

    if (this.selectedBuild === 'dig') {
      const tile = this.findSoftEarthAt(x, y);
      if (tile) this.colony.startDig(tile.x, tile.y);
      return;
    }

    if (this.selectedBuild === 'mine' && this.pathFollower) {
      const progress = this.findNearestPathProgress(x, y);
      if (progress !== null) this.colony.placeMine(progress);
      return;
    }

    const node = this.findNodeAt(x, y);
    if (!node) return;

    const ns = this.gameState.getNodeState(node.x, node.y);
    if (ns === 'ready' && this.selectedBuild && this.selectedBuild !== 'mine') {
      this.colony.startBuild(node.x, node.y, this.selectedBuild);
      return;
    }

    const tower = this.gameState.towers.find((t) => Math.hypot(t.x - x, t.y - y) < 24);
    if (tower) {
      this.showTowerMenu(tower.id, tower.x, tower.y);
    }
  }

  private findSoftEarthAt(x: number, y: number) {
    for (const tile of this.gameState.level?.softEarth ?? []) {
      if (x >= tile.x && x <= tile.x + tile.w && y >= tile.y && y <= tile.y + tile.h) {
        return { x: tile.x + tile.w / 2, y: tile.y + tile.h / 2 };
      }
    }
    return null;
  }

  private findNodeAt(x: number, y: number) {
    for (const [key, state] of this.gameState.nodeStates) {
      if (state !== 'ready' && state !== 'empty' && state !== 'digging' && state !== 'building') continue;
      const [xs, ys] = key.split(',');
      const nx = Number(xs);
      const ny = Number(ys);
      if (Math.hypot(x - nx, y - ny) < 20) return { x: nx, y: ny };
    }
    return null;
  }

  private findNearestPathProgress(x: number, y: number): number | null {
    if (!this.pathFollower) return null;
    let best = 0;
    let bestDist = Infinity;
    for (let i = 0; i < 600; i += 10) {
      const pos = this.pathFollower.getPositionAtProgress(i);
      if (!pos) break;
      const d = Math.hypot(pos.x - x, pos.y - y);
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return bestDist < 30 ? best : null;
  }

  private showTowerMenu(towerId: string, x: number, y: number): void {
    const existing = this.getByName('towerMenu');
    existing?.destroy();

    const menu = this.scene.add.container(x, y - 40);
    menu.setName('towerMenu');

    const addBtn = (label: string, ox: number, fn: () => void) => {
      const b = this.scene.add.rectangle(ox, 0, 28, 20, COLORS.dirtLight);
      b.setInteractive({ useHandCursor: true });
      b.on('pointerdown', fn);
      const t = this.scene.add.text(ox, 0, label, { fontSize: '12px', color: '#fff' }).setOrigin(0.5);
      menu.add([b, t]);
    };

    addBtn('+', -35, () => this.colony.assignSoldier(towerId));
    addBtn('-', -5, () => this.colony.removeSoldier(towerId));
    addBtn('^', 25, () => this.colony.upgradeTower(towerId));

    this.add(menu);
    this.scene.time.delayedCall(3000, () => menu.destroy());
  }

  redraw(): void {
    const g = this.gfx;
    g.clear();
    const level = this.gameState.level;
    if (!level) return;

    g.fillStyle(COLORS.dirt, 1);
    g.fillRect(0, 0, MACRO_WIDTH, PANEL_HEIGHT);

    if (this.pathFollower) {
      g.lineStyle(32, COLORS.tunnelFloor, 1);
      g.beginPath();
      const path = level.path;
      g.moveTo(path[0].x, path[0].y);
      for (let i = 1; i < path.length; i++) g.lineTo(path[i].x, path[i].y);
      g.strokePath();

      g.lineStyle(3, COLORS.dirtLight, 0.8);
      g.beginPath();
      g.moveTo(path[0].x, path[0].y);
      for (let i = 1; i < path.length; i++) g.lineTo(path[i].x, path[i].y);
      g.strokePath();
    }

    for (const dep of level.deposits) {
      g.fillStyle(0x6b5a2a, 0.8);
      g.fillCircle(dep.x, dep.y, 12);
      g.fillStyle(0x8b7a3a, 1);
      g.fillCircle(dep.x, dep.y, 6);
    }

    for (const [key, state] of this.gameState.nodeStates) {
      const [xs, ys] = key.split(',');
      const x = Number(xs);
      const y = Number(ys);
      if (state === 'ready') {
        g.fillStyle(COLORS.preDug, 0.8);
        g.fillCircle(x, y, 16);
      } else if (state === 'empty') {
        g.fillStyle(COLORS.softEarth, 0.6);
        g.fillRect(x - 16, y - 16, 32, 32);
      } else if (state === 'digging') {
        const job = this.gameState.digJobs.find((j) => j.tileKey === key);
        g.fillStyle(COLORS.softEarth, 0.4);
        g.fillRect(x - 16, y - 16, 32, 32);
        if (job) {
          g.fillStyle(COLORS.acidDark, 0.8);
          g.fillRect(x - 16, y + 12, 32 * (job.progress / job.duration), 4);
        }
      } else if (state === 'building') {
        g.fillStyle(COLORS.buildNode, 0.6);
        g.fillCircle(x, y, 14);
      }
    }

    for (const job of this.gameState.buildJobs) {
      if (job.type === 'mine') continue;
      const [xs, ys] = job.nodeKey.split(',');
      g.fillStyle(COLORS.acid, 0.5);
      g.fillCircle(Number(xs), Number(ys), 12 * (job.progress / job.duration));
    }
  }

  private syncEnemies(): void {
    const active = new Set(this.gameState.enemies.map((e) => e.id));
    for (const [id, container] of this.enemySprites) {
      if (!active.has(id)) {
        container.destroy();
        this.enemySprites.delete(id);
      }
    }
    for (const enemy of this.gameState.enemies) {
      if (this.enemySprites.has(enemy.id)) continue;
      const stats = TUNING.enemyStats[enemy.type];
      const c = this.scene.add.container(0, 0);
      const body = this.scene.add.rectangle(0, 0, 18, 14, stats.color);
      const hpBar = this.scene.add.rectangle(0, -12, 16, 3, 0x33ff33);
      hpBar.setName('hpBar');
      c.add([body, hpBar]);
      this.enemySprites.set(enemy.id, c);
      this.add(c);
    }
  }

  private syncTowers(): void {
    for (const t of this.towerSprites.values()) t.destroy();
    this.towerSprites.clear();
    for (const tower of this.gameState.towers) {
      const stats = TUNING.towerStats[tower.type];
      const c = this.scene.add.container(tower.x, tower.y);
      const body = this.scene.add.rectangle(0, 0, 28, 28, stats.color);
      body.setStrokeStyle(2, 0xffffff, 0.3);
      const label = this.scene.add.text(0, 0, tower.type[0].toUpperCase(), { fontSize: '10px', color: '#fff' }).setOrigin(0.5);
      const slots = this.scene.add.text(0, 14, `⚔${tower.soldiers}`, { fontSize: '8px', color: COLORS.text }).setOrigin(0.5);
      c.add([body, label, slots]);
      if (tower.type === 'gland') {
        const aura = this.scene.add.circle(0, 0, stats.range, stats.color, 0.1);
        c.addAt(aura, 0);
      }
      this.towerSprites.set(tower.id, c);
      this.add(c);
    }
  }

  private syncMines(): void {
    for (const g of this.mineSprites.values()) g.destroy();
    this.mineSprites.clear();
    for (const mine of this.gameState.mines) {
      const pos = this.pathFollower?.getPositionAtIndex(mine.pathIndex);
      if (!pos) continue;
      const g = this.scene.add.graphics();
      g.fillStyle(COLORS.mine, mine.armed ? 1 : 0.3);
      g.fillCircle(pos.x, pos.y, 8);
      this.mineSprites.set(mine.id, g);
      this.add(g);
    }
  }

  update(): void {
    for (const enemy of this.gameState.enemies) {
      const container = this.enemySprites.get(enemy.id);
      const pos = this.getEnemyPosition(enemy);
      if (!container || !pos) continue;
      container.setPosition(pos.x, pos.y);
      const hpBar = container.getByName('hpBar') as Phaser.GameObjects.Rectangle;
      if (hpBar) hpBar.setScale(enemy.hp / enemy.maxHp, 1);
    }

    this.projectileGfx.clear();
    for (const proj of this.gameState.projectiles) {
      this.projectileGfx.fillStyle(COLORS.acid, 1);
      this.projectileGfx.fillCircle(proj.x, proj.y, 4);
    }
  }
}
