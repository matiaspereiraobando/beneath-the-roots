import Phaser from 'phaser';
import { COLORS } from '../config';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  preload(): void {
    this.load.image('queen', '/sprites/queen.png');
    this.load.image('spitter', '/sprites/spitter.png');
    this.load.image('worker', '/sprites/worker.png');
    this.load.image('tunnel-tileset', '/sprites/tunnel-tileset.png');
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
