import Phaser from 'phaser';
import { COLORS, GAME_WIDTH, HUD_HEIGHT } from '../config';
import type { GameState } from '../state/GameState';

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

  constructor(scene: Phaser.Scene, state: GameState) {
    super(scene, 0, 0);
    this.gameState = state;

    const bg = scene.add.rectangle(GAME_WIDTH / 2, HUD_HEIGHT / 2, GAME_WIDTH, HUD_HEIGHT, COLORS.hudBg);
    bg.setStrokeStyle(1, COLORS.dirt);
    this.add(bg);

    this.biomassText = scene.add.text(12, 8, '', { fontSize: '13px', color: COLORS.text });
    this.waveText = scene.add.text(180, 8, '', { fontSize: '13px', color: COLORS.text });
    this.phaseText = scene.add.text(320, 8, '', { fontSize: '13px', color: COLORS.text });
    this.hintText = scene.add.text(12, 28, '', { fontSize: '11px', color: COLORS.textDim, wordWrap: { width: 500 } });

    this.queenHpBar = scene.add.graphics();
    this.satietyBar = scene.add.graphics();

    this.muteBtn = scene.add.text(GAME_WIDTH - 60, 10, '🔊', { fontSize: '16px' });
    this.queenHpLabel = scene.add.text(480, 0, 'Queen HP', { fontSize: '9px', color: COLORS.textDim });
    this.muteBtn.setInteractive({ useHandCursor: true });
    this.muteBtn.on('pointerdown', () => {
      this.gameState.muted = !this.gameState.muted;
      this.muteBtn.setText(this.gameState.muted ? '🔇' : '🔊');
    });

    this.add([this.biomassText, this.waveText, this.phaseText, this.hintText, this.queenHpBar, this.satietyBar, this.muteBtn, this.queenHpLabel]);

    this.setDepth(20);

    state.on('biomassChanged', () => this.refresh());
    state.on('waveChanged', () => this.refresh());
    state.on('phaseChanged', () => this.refresh());
    state.on('queenHpChanged', () => this.refresh());
    state.on('queenSatietyChanged', () => this.refresh());
    state.on('levelLoaded', () => this.refresh());

    this.refresh();
  }

  refresh(): void {
    const s = this.gameState;
    const totalWaves = s.level?.waves.length ?? 0;
    this.biomassText.setText(`Biomass: ${Math.floor(s.biomass)}`);
    this.waveText.setText(`Wave: ${Math.min(s.waveIndex + 1, totalWaves)}/${totalWaves}`);
    this.phaseText.setText(
      s.phase === 'build' ? `BUILD ${Math.ceil(s.buildTimer)}s` : s.phase === 'wave' ? 'INVASION' : s.phase.toUpperCase(),
    );

    if (s.hints.length > 0 && s.phase === 'build') {
      this.hintText.setText(s.hints[s.hintIndex % s.hints.length]);
    } else {
      this.hintText.setText('');
    }

    this.queenHpBar.clear();
    const hpX = 480;
    const barW = 120;
    this.queenHpBar.fillStyle(0x331111, 1);
    this.queenHpBar.fillRect(hpX, 12, barW, 10);
    const hpPct = s.queenHp / s.queenMaxHp;
    this.queenHpBar.fillStyle(hpPct < 0.3 ? 0xcc2222 : 0x882244, 1);
    this.queenHpBar.fillRect(hpX, 12, barW * hpPct, 10);

    this.satietyBar.clear();
    const satX = 620;
    this.satietyBar.fillStyle(0x332211, 1);
    this.satietyBar.fillRect(satX, 12, barW, 10);
    const satPct = s.queenSatiety / 100;
    this.satietyBar.fillStyle(satPct < 0.3 ? 0x882222 : 0x8b6914, 1);
    this.satietyBar.fillRect(satX, 12, barW * satPct, 10);
  }

  update(): void {
    if (this.gameState.phase === 'build') {
      this.phaseText.setText(`BUILD ${Math.ceil(this.gameState.buildTimer)}s`);
    }
  }
}
