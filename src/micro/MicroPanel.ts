import Phaser from 'phaser';
import { COLORS, MACRO_WIDTH, MICRO_WIDTH, PANEL_HEIGHT } from '../config';
import type { GameState } from '../state/GameState';
import type { AntType } from '../data/types';
import { TUNING } from '../data/tuning';

const ANT_LABELS: Record<AntType, string> = {
  gatherer: 'G',
  builder: 'B',
  soldier: 'S',
};

const ANT_COLORS: Record<AntType, number> = {
  gatherer: 0x8b6914,
  builder: 0x5a4a3a,
  soldier: 0x882244,
};

export class MicroPanel extends Phaser.GameObjects.Container {
  private gameState: GameState;
  private queueSlots: Phaser.GameObjects.Container[] = [];
  private antCountText: Phaser.GameObjects.Text;
  private warehouseText: Phaser.GameObjects.Text;
  private feedBtn: Phaser.GameObjects.Container;
  private queenGfx: Phaser.GameObjects.Graphics;
  private crackGfx: Phaser.GameObjects.Graphics;
  private pulseTween: Phaser.Tweens.Tween | null = null;

  constructor(scene: Phaser.Scene, state: GameState) {
    super(scene, MACRO_WIDTH, 0);
    this.gameState = state;

    const bg = scene.add.rectangle(MICRO_WIDTH / 2, PANEL_HEIGHT / 2, MICRO_WIDTH, PANEL_HEIGHT, COLORS.microBg);
    bg.setStrokeStyle(2, COLORS.queen, 0.3);
    this.add(bg);

    const title = scene.add.text(MICRO_WIDTH / 2, 12, 'CITADEL', {
      fontSize: '11px',
      color: COLORS.textDim,
      fontStyle: 'bold',
    }).setOrigin(0.5);
    this.add(title);

    this.queenGfx = scene.add.graphics();
    this.crackGfx = scene.add.graphics();
    this.drawQueen();
    this.add([this.queenGfx, this.crackGfx]);

    this.feedBtn = this.createButton(MICRO_WIDTH / 2, 100, 'FEED QUEEN', () => {
      if (this.gameState.feedQueen(true)) {
        this.scene.cameras.main.flash(100, 100, 80, 40, false, undefined, 0.15);
      }
    });
    this.add(this.feedBtn);

    const feedCost = scene.add.text(MICRO_WIDTH / 2, 125, `Cost: ${TUNING.queenFeedCost} biomass`, {
      fontSize: '9px',
      color: COLORS.textDim,
    }).setOrigin(0.5);
    this.add(feedCost);

    const nurseryLabel = scene.add.text(16, 145, 'NURSERY QUEUE', { fontSize: '10px', color: COLORS.textDim });
    this.add(nurseryLabel);

    for (let i = 0; i < TUNING.nurseryQueueSize; i++) {
      const slot = this.createQueueSlot(i);
      this.queueSlots.push(slot);
      this.add(slot);
    }

    const whLabel = scene.add.text(16, 220, 'WAREHOUSE', { fontSize: '10px', color: COLORS.textDim });
    this.warehouseText = scene.add.text(16, 238, '', { fontSize: '12px', color: '#8b6914' });
    this.add([whLabel, this.warehouseText]);

    this.antCountText = scene.add.text(16, 280, '', { fontSize: '11px', color: COLORS.text, lineSpacing: 4 });
    this.add(this.antCountText);

    const door = scene.add.rectangle(0, PANEL_HEIGHT / 2, 4, 60, COLORS.queenGlow, 0.5);
    this.add(door);

    state.on('queueChanged', () => this.refreshQueue());
    state.on('antsChanged', () => this.refreshAnts());
    state.on('biomassChanged', () => this.refreshWarehouse());
    state.on('queenSatietyChanged', () => this.drawQueen());
    state.on('breach', () => this.onBreach());
    state.on('antSpawned', (type: AntType) => this.spawnAntVisual(type));
    state.on('levelLoaded', () => {
      this.refreshQueue();
      this.refreshAnts();
      this.refreshWarehouse();
    });

    this.refreshQueue();
    this.refreshAnts();
    this.refreshWarehouse();
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): Phaser.GameObjects.Container {
    const c = this.scene.add.container(x, y);
    const bg = this.scene.add.rectangle(0, 0, 120, 28, COLORS.queen);
    bg.setStrokeStyle(1, COLORS.queenGlow);
    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerdown', onClick);
    const txt = this.scene.add.text(0, 0, label, { fontSize: '11px', color: '#fff' }).setOrigin(0.5);
    c.add([bg, txt]);
    return c;
  }

  private createQueueSlot(index: number): Phaser.GameObjects.Container {
    const c = this.scene.add.container(20 + index * 52, 170);
    const bg = this.scene.add.rectangle(0, 0, 44, 36, COLORS.dirt);
    bg.setStrokeStyle(1, COLORS.dirtLight);
    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerdown', () => this.gameState.cycleQueueSlot(index));
    const txt = this.scene.add.text(0, 0, '?', { fontSize: '14px', color: '#fff' }).setOrigin(0.5);
    txt.setName('label');
    const sub = this.scene.add.text(0, 14, index === 0 ? 'NEXT' : '', { fontSize: '7px', color: COLORS.textDim }).setOrigin(0.5);
    c.add([bg, txt, sub]);
    return c;
  }

  private drawQueen(): void {
    const g = this.queenGfx;
    g.clear();
    const cx = MICRO_WIDTH / 2;
    const cy = 55;
    const satPct = this.gameState.queenSatiety / TUNING.queenSatietyMax;
    const color = satPct < 0.3 ? 0x662233 : COLORS.queen;

    g.fillStyle(color, 1);
    g.fillEllipse(cx, cy, 50, 36);
    g.fillStyle(COLORS.queenGlow, 0.4);
    g.fillEllipse(cx, cy - 4, 30, 20);

    if (satPct < TUNING.queenStarveThreshold / 100) {
      if (!this.pulseTween) {
        this.pulseTween = this.scene.tweens.add({
          targets: this.feedBtn,
          scale: 1.08,
          duration: 500,
          yoyo: true,
          repeat: -1,
        });
      }
    } else if (this.pulseTween) {
      this.pulseTween.stop();
      this.pulseTween = null;
      this.feedBtn.setScale(1);
    }
  }

  private onBreach(): void {
    this.scene.cameras.main.shake(200, 0.008);
    this.crackGfx.clear();
    const cx = MICRO_WIDTH / 2;
    const cy = 55;
    this.crackGfx.lineStyle(2, 0xcc3333, 0.8);
    this.crackGfx.lineBetween(cx - 20, cy - 10, cx + 5, cy + 15);
    this.crackGfx.lineBetween(cx + 15, cy - 15, cx - 10, cy + 10);
    this.scene.time.delayedCall(1500, () => this.crackGfx.clear());

    const flash = this.scene.add.rectangle(MICRO_WIDTH / 2, PANEL_HEIGHT / 2, MICRO_WIDTH, PANEL_HEIGHT, 0xcc0000, 0.2);
    this.add(flash);
    this.scene.tweens.add({ targets: flash, alpha: 0, duration: 400, onComplete: () => flash.destroy() });
  }

  private spawnAntVisual(type: AntType): void {
    const ant = this.scene.add.circle(MICRO_WIDTH / 2, 90, 4, ANT_COLORS[type]);
    this.add(ant);
    this.scene.tweens.add({
      targets: ant,
      x: -10,
      y: PANEL_HEIGHT / 2,
      alpha: 0,
      duration: 1200,
      onComplete: () => ant.destroy(),
    });
  }

  private refreshQueue(): void {
    this.gameState.nurseryQueue.forEach((type, i) => {
      const slot = this.queueSlots[i];
      const txt = slot.getByName('label') as Phaser.GameObjects.Text;
      txt.setText(ANT_LABELS[type]);
      const bg = slot.list[0] as Phaser.GameObjects.Rectangle;
      bg.setFillStyle(ANT_COLORS[type]);
    });
  }

  private refreshAnts(): void {
    const p = this.gameState.antPool;
    this.antCountText.setText(
      `Gatherers: ${p.gatherer}\nBuilders: ${p.builder}\nSoldiers: ${p.soldier} (${this.gameState.unassignedSoldiers} free)`,
    );
  }

  private refreshWarehouse(): void {
    this.warehouseText.setText(`${Math.floor(this.gameState.biomass)} biomass stored`);
  }

  private lowHpVignette = false;

  update(): void {
    const lowHp = this.gameState.queenHp / this.gameState.queenMaxHp < 0.3 && this.gameState.phase === 'wave';
    if (lowHp && !this.lowHpVignette) {
      this.lowHpVignette = true;
    } else if (!lowHp) {
      this.lowHpVignette = false;
    }
  }
}
