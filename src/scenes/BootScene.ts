import Phaser from 'phaser';
import { COLORS } from '../config';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  create(): void {
    const g = this.add.graphics();
    g.fillStyle(COLORS.dirt, 1);
    g.fillRect(0, 0, 16, 16);
    g.fillStyle(COLORS.acid, 1);
    g.fillRect(4, 4, 8, 8);
    g.generateTexture('placeholder', 16, 16);
    g.destroy();

    this.scene.start('Menu');
  }
}
