import Phaser from 'phaser';
import { COLORS, GAME_WIDTH, HUD_HEIGHT } from '../config';
import type { GameState } from '../state/GameState';
import { getSatietyEffect } from './statLabels';
import { createUiText, setUiTextColor } from './createUiText';

export class HUD extends Phaser.GameObjects.Container {
  private gameState: GameState;
  private biomassText: Phaser.GameObjects.Text;
  private waveText: Phaser.GameObjects.Text;
  private phaseText: Phaser.GameObjects.Text;
  private queenHpBar: Phaser.GameObjects.Graphics;
  private satietyBar: Phaser.GameObjects.Graphics;
  private hintText: Phaser.GameObjects.Text;
  private muteBtn: Phaser.GameObjects.Text;
  private queenHpLabel: Phaser.GameObjects.Text;
  private satietyLabel: Phaser.GameObjects.Text;
  private transientHintActive = false;
  private transientTimer: Phaser.Time.TimerEvent | null = null;

  constructor(scene: Phaser.Scene, state: GameState) {
    super(scene, 0, 0);
    this.gameState = state;

    const bg = scene.add.rectangle(GAME_WIDTH / 2, HUD_HEIGHT / 2, GAME_WIDTH, HUD_HEIGHT, COLORS.hudBg);
    bg.setStrokeStyle(1, COLORS.dirt);
    this.add(bg);

    this.biomassText = createUiText(scene, 12, 6, '', 13, COLORS.text);
    this.waveText = createUiText(scene, 180, 6, '', 13, COLORS.text);
    this.phaseText = createUiText(scene, 320, 6, '', 13, COLORS.text);
    this.hintText = createUiText(scene, 12, 26, '', 11, COLORS.textDim, { maxWidth: 400 });

    this.queenHpBar = scene.add.graphics();
    this.satietyBar = scene.add.graphics();

    this.muteBtn = createUiText(scene, GAME_WIDTH - 12, 6, 'SND', 12, COLORS.text, { originX: 1, originY: 0 });
    this.queenHpLabel = createUiText(scene, 480, 2, 'Queen HP', 10, COLORS.textDim);
    this.satietyLabel = createUiText(scene, 620, 2, 'Satiety', 10, COLORS.textDim);
    this.muteBtn.setInteractive({ useHandCursor: true });
    this.muteBtn.on('pointerdown', () => {
      this.gameState.muted = !this.gameState.muted;
      this.muteBtn.setText(this.gameState.muted ? 'MUT' : 'SND');
    });

    this.add([
      this.biomassText,
      this.waveText,
      this.phaseText,
      this.hintText,
      this.queenHpBar,
      this.satietyBar,
      this.muteBtn,
      this.queenHpLabel,
      this.satietyLabel,
    ]);

    this.setDepth(20);

    state.on('biomassChanged', () => this.refresh());
    state.on('waveChanged', () => this.refresh());
    state.on('phaseChanged', () => this.refresh());
    state.on('queenHpChanged', () => this.refresh());
    state.on('queenSatietyChanged', () => this.refresh());
    state.on('levelLoaded', () => this.refresh());

    this.refresh();
  }

  showTransientHint(text: string, durationMs: number): void {
    this.transientHintActive = true;
    this.hintText.setText(text);
    setUiTextColor(this.hintText, '#ccaa44');
    this.transientTimer?.remove();
    this.transientTimer = this.scene.time.delayedCall(durationMs, () => {
      this.transientHintActive = false;
      this.transientTimer = null;
      this.refresh();
    });
  }

  refresh(): void {
    const s = this.gameState;
    const totalWaves = s.level?.waves.length ?? 0;
    this.biomassText.setText(`Biomass: ${Math.floor(s.biomass)}`);
    this.waveText.setText(`Wave: ${Math.min(s.waveIndex + 1, totalWaves)}/${totalWaves}`);
    this.phaseText.setText(
      s.phase === 'build' ? `BUILD ${Math.ceil(s.buildTimer)}s` : s.phase === 'wave' ? 'INVASION' : s.phase.toUpperCase(),
    );

    if (!this.transientHintActive) {
      if (s.hints.length > 0 && s.phase === 'build') {
        this.hintText.setText(s.hints[s.hintIndex % s.hints.length]);
        setUiTextColor(this.hintText, COLORS.textDim);
      } else if (s.phase === 'wave') {
        this.hintText.setText('Feed queen in citadel to restore fire rate');
        setUiTextColor(this.hintText, COLORS.textDim);
      } else {
        this.hintText.setText('');
      }
    }

    this.queenHpBar.clear();
    const hpX = 480;
    const barW = 120;
    this.queenHpBar.fillStyle(0x331111, 1);
    this.queenHpBar.fillRect(hpX, 14, barW, 8);
    const hpPct = s.queenHp / s.queenMaxHp;
    this.queenHpBar.fillStyle(hpPct < 0.3 ? 0xcc2222 : 0x882244, 1);
    this.queenHpBar.fillRect(hpX, 14, barW * hpPct, 8);

    this.satietyBar.clear();
    const satX = 620;
    this.satietyBar.fillStyle(0x332211, 1);
    this.satietyBar.fillRect(satX, 14, barW, 8);
    const satPct = s.queenSatiety / 100;
    const satietyFx = getSatietyEffect(s);
    this.satietyBar.fillStyle(satPct < 0.3 ? 0x882222 : satPct >= 0.7 ? 0x6b8b2a : 0x8b6914, 1);
    this.satietyBar.fillRect(satX, 14, barW * satPct, 8);

    if (s.queenSatiety <= 30 || s.queenSatiety >= 70) {
      setUiTextColor(this.satietyLabel, satietyFx.color);
    } else {
      setUiTextColor(this.satietyLabel, COLORS.textDim);
    }
  }

  update(): void {
    if (this.gameState.phase === 'build') {
      this.phaseText.setText(`BUILD ${Math.ceil(this.gameState.buildTimer)}s`);
    }
  }
}
