import Phaser from 'phaser';
import { COLORS, MACRO_WIDTH, MICRO_WIDTH, PANEL_HEIGHT } from '../config';
import { createUiText, setUiTextColor } from '../ui/createUiText';
import type { GameState } from '../state/GameState';
import type { AntType } from '../data/types';
import { TUNING } from '../data/tuning';
import { getSatietyEffect } from '../ui/statLabels';
import { scaleSpriteToSize } from '../pixelArt';

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
  private satietyEffectText: Phaser.GameObjects.Text;
  private warehouseText: Phaser.GameObjects.Text;
  private feedBtn: Phaser.GameObjects.Container;
  private queenGfx: Phaser.GameObjects.Graphics;
  private crackGfx: Phaser.GameObjects.Graphics;
  private pulseTween: Phaser.Tweens.Tween | null = null;

  private queenSprite: Phaser.GameObjects.Image | null = null;

  constructor(scene: Phaser.Scene, state: GameState) {
    super(scene, MACRO_WIDTH, 0);
    this.gameState = state;

    const bg = scene.add.rectangle(MICRO_WIDTH / 2, PANEL_HEIGHT / 2, MICRO_WIDTH, PANEL_HEIGHT, COLORS.microBg);
    bg.setStrokeStyle(2, COLORS.queen, 0.3);
    this.add(bg);

    createUiText(scene, MICRO_WIDTH / 2, 12, 'CITADEL', 18, COLORS.textDim, { originX: 0.5, originY: 0.5, parent: this });

    this.queenGfx = scene.add.graphics();
    this.crackGfx = scene.add.graphics();
    if (scene.textures.exists('queen')) {
      this.queenSprite = scene.add.image(MICRO_WIDTH / 2, 58, 'queen');
      scaleSpriteToSize(this.queenSprite, 56);
      this.add(this.queenSprite);
    }
    this.drawQueen();
    this.add([this.queenGfx, this.crackGfx]);

    this.feedBtn = this.createButton(MICRO_WIDTH / 2, 98, 'FEED QUEEN', () => {
      if (this.gameState.feedQueen(true)) {
        this.scene.cameras.main.flash(100, 100, 80, 40, false, undefined, 0.15);
      }
    });
    this.add(this.feedBtn);

    createUiText(scene, MICRO_WIDTH / 2, 118, `Cost: ${TUNING.queenFeedCost} biomass`, 10, COLORS.textDim, {
      originX: 0.5,
      originY: 0,
      parent: this,
    });
    this.satietyEffectText = createUiText(scene, MICRO_WIDTH / 2, 132, '', 10, COLORS.textDim, {
      originX: 0.5,
      originY: 0,
      maxWidth: MICRO_WIDTH - 16,
      parent: this,
    });

    createUiText(scene, 16, 154, 'NURSERY QUEUE', 11, COLORS.textDim, { parent: this });

    for (let i = 0; i < TUNING.nurseryQueueSize; i++) {
      const slot = this.createQueueSlot(i);
      this.queueSlots.push(slot);
      this.add(slot);
    }

    createUiText(scene, 16, 228, 'WAREHOUSE', 11, COLORS.textDim, { parent: this });
    this.warehouseText = createUiText(scene, 16, 244, '', 12, '#8b6914', { parent: this });

    this.antCountText = createUiText(scene, 16, 290, '', 11, COLORS.text, {
      lineSpacing: 4,
      parent: this,
    });

    const door = scene.add.rectangle(0, PANEL_HEIGHT / 2, 4, 60, COLORS.queenGlow, 0.5);
    this.add(door);

    state.on('queueChanged', () => this.refreshQueue());
    state.on('antsChanged', () => this.refreshAnts());
    state.on('biomassChanged', () => this.refreshWarehouse());
    state.on('queenSatietyChanged', () => {
      this.drawQueen();
      this.refreshSatietyEffect();
    });
    state.on('phaseChanged', () => this.refreshSatietyEffect());
    state.on('breach', () => this.onBreach());
    state.on('antSpawned', (type: AntType) => this.spawnAntVisual(type));
    state.on('levelLoaded', () => {
      this.refreshQueue();
      this.refreshAnts();
      this.refreshWarehouse();
      this.refreshSatietyEffect();
    });

    this.refreshQueue();
    this.refreshAnts();
    this.refreshWarehouse();
    this.refreshSatietyEffect();

    this.setDepth(10);
  }

  private createButton(x: number, y: number, label: string, onClick: () => void): Phaser.GameObjects.Container {
    const c = this.scene.add.container(x, y);
    const bg = this.scene.add.rectangle(0, 0, 120, 28, COLORS.queen);
    bg.setStrokeStyle(1, COLORS.queenGlow);
    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerdown', onClick);
    c.add(bg);
    createUiText(this.scene, 0, 0, label, 11, '#fff', { originX: 0.5, originY: 0.5, parent: c });
    return c;
  }

  private createQueueSlot(index: number): Phaser.GameObjects.Container {
    const c = this.scene.add.container(20 + index * 52, 172);
    const bg = this.scene.add.rectangle(0, 0, 44, 36, COLORS.dirt);
    bg.setStrokeStyle(1, COLORS.dirtLight);
    bg.setName('bg');
    bg.setInteractive({ useHandCursor: true });
    bg.on('pointerdown', () => this.gameState.cycleQueueSlot(index));
    c.add(bg);
    const txt = createUiText(this.scene, 0, 0, '?', 14, '#fff', { originX: 0.5, originY: 0.5, parent: c });
    txt.setName('label');
    if (index === 0) {
      createUiText(this.scene, 0, 22, 'NEXT', 9, COLORS.textDim, { originX: 0.5, originY: 0, parent: c });
    }
    return c;
  }

  private drawQueen(): void {
    const g = this.queenGfx;
    g.clear();
    const satPct = this.gameState.queenSatiety / TUNING.queenSatietyMax;

    if (this.queenSprite) {
      this.queenSprite.setTint(satPct < 0.3 ? 0xaa6666 : 0xffffff);
    } else {
      const cx = MICRO_WIDTH / 2;
      const cy = 55;
      const color = satPct < 0.3 ? 0x662233 : COLORS.queen;
      g.fillStyle(color, 1);
      g.fillEllipse(cx, cy, 50, 36);
      g.fillStyle(COLORS.queenGlow, 0.4);
      g.fillEllipse(cx, cy - 4, 30, 20);
    }

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
    const color = ANT_COLORS[type];
    let ant: Phaser.GameObjects.Image | Phaser.GameObjects.Arc;
    if (type === 'gatherer' && this.scene.textures.exists('worker')) {
      ant = this.scene.add.image(MICRO_WIDTH / 2, 90, 'worker');
      scaleSpriteToSize(ant, 16);
    } else {
      ant = this.scene.add.circle(MICRO_WIDTH / 2, 90, 4, color);
    }
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
      const bg = slot.getByName('bg') as Phaser.GameObjects.Rectangle;
      bg.setFillStyle(ANT_COLORS[type]);
    });
  }

  private refreshAnts(): void {
    const p = this.gameState.antPool;
    this.antCountText.setText(
      `Gatherers: ${p.gatherer}\nBuilders: ${p.builder}\nSoldiers: ${p.soldier} (${this.gameState.unassignedSoldiers} free)`,
    );
  }

  private refreshSatietyEffect(): void {
    const fx = getSatietyEffect(this.gameState);
    this.satietyEffectText.setText(fx.text);
    setUiTextColor(this.satietyEffectText, fx.color);
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
