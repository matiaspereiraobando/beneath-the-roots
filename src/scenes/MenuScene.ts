import Phaser from 'phaser';
import { COLORS, GAME_HEIGHT, GAME_WIDTH } from '../config';
import { LEVELS } from '../data/levels/index';

export class MenuScene extends Phaser.Scene {
  constructor() {
    super('Menu');
  }

  create(): void {
    this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, COLORS.bg);

    this.add.text(GAME_WIDTH / 2, 80, 'BENEATH THE ROOTS', {
      fontSize: '36px',
      color: COLORS.text,
      fontStyle: 'bold',
    }).setOrigin(0.5);

    this.add.text(GAME_WIDTH / 2, 130, 'Defend the tunnels. Keep the queen alive.', {
      fontSize: '14px',
      color: COLORS.textDim,
    }).setOrigin(0.5);

    const playableLevels = LEVELS.filter((l) => l.id !== 'level0_test');
    playableLevels.forEach((level, i) => {
      const y = 200 + i * 60;
      const btn = this.add.rectangle(GAME_WIDTH / 2, y, 280, 44, COLORS.dirt);
      btn.setStrokeStyle(1, COLORS.dirtLight);
      btn.setInteractive({ useHandCursor: true });
      this.add.text(GAME_WIDTH / 2, y, `${i + 1}. ${level.name}`, {
        fontSize: '16px',
        color: COLORS.text,
      }).setOrigin(0.5);
      btn.on('pointerdown', () => {
        this.scene.start('Game', { levelId: level.id });
      });
      btn.on('pointerover', () => btn.setFillStyle(COLORS.preDug));
      btn.on('pointerout', () => btn.setFillStyle(COLORS.dirt));
    });

    const testBtn = this.add.text(GAME_WIDTH / 2, GAME_HEIGHT - 60, '[Dev Test Level]', {
      fontSize: '12px',
      color: COLORS.textDim,
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });
    testBtn.on('pointerdown', () => this.scene.start('Game', { levelId: 'level0_test' }));

    this.add.text(GAME_WIDTH / 2, GAME_HEIGHT - 30, 'Click to select a level', {
      fontSize: '11px',
      color: COLORS.textDim,
    }).setOrigin(0.5);
  }
}
