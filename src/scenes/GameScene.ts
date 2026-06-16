import Phaser from 'phaser';
import { COLORS, GAME_HEIGHT, GAME_WIDTH, HUD_HEIGHT } from '../config';
import { createUiText } from '../ui/createUiText';
import { getLevelById } from '../data/levels/index';
import { GameState } from '../state/GameState';
import { PathFollower } from '../systems/PathFollower';
import { WaveManager } from '../systems/WaveManager';
import { CombatSystem } from '../systems/CombatSystem';
import { ColonySystem } from '../systems/ColonySystem';
import { HUD } from '../ui/HUD';
import { MacroPanel } from '../macro/MacroPanel';
import { MicroPanel } from '../micro/MicroPanel';

export class GameScene extends Phaser.Scene {
  private state!: GameState;
  private waveManager!: WaveManager;
  private combat!: CombatSystem;
  private colony!: ColonySystem;
  private pathFollower!: PathFollower;
  private macroPanel!: MacroPanel;
  private hud!: HUD;
  private paused = false;

  constructor() {
    super('Game');
  }

  init(data: { levelId?: string }): void {
    this.registry.set('pendingLevelId', data.levelId ?? 'level1_breach');
    this.state = GameState.reset();
  }

  create(): void {
    const levelId = this.registry.get('pendingLevelId') as string;
    const level = getLevelById(levelId);
    if (!level) {
      this.scene.start('Menu');
      return;
    }

    this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, COLORS.bg);

    this.colony = new ColonySystem(this.state);
    this.pathFollower = new PathFollower(level.path);
    this.waveManager = new WaveManager(this.state, this.pathFollower);
    this.combat = new CombatSystem(this.state, this.waveManager);

    this.macroPanel = new MacroPanel(this, this.state, this.colony);
    this.macroPanel.setY(HUD_HEIGHT);
    this.add.existing(this.macroPanel);
    this.combat.bindEnemyPositions((enemy) => this.macroPanel.getEnemyPosition(enemy));

    const microPanel = new MicroPanel(this, this.state);
    microPanel.setY(HUD_HEIGHT);
    this.add.existing(microPanel);

    this.hud = new HUD(this, this.state);
    this.add.existing(this.hud);

    // Load level AFTER panels subscribe to events
    this.state.loadLevel(level);
    this.macroPanel.bindLevel(level);

    this.state.on('gameWon', () => this.showOverlay('COLONY SURVIVED', '#6aff4a'));
    this.state.on('gameLost', () => this.showOverlay('THE QUEEN HAS FALLEN', '#cc3333'));
    this.state.on('waveStarted', (idx: number) => {
      this.showBanner(`WAVE ${idx + 1}`);
      if (idx === 0) {
        this.hud.showTransientHint('Feed the queen during waves to keep towers firing at full rate', 6000);
      }
    });

    this.input.keyboard?.on('keydown-ESC', () => {
      this.paused = !this.paused;
      this.physics?.pause();
    });
    this.input.keyboard?.on('keydown-SPACE', () => {
      if (this.state.phase === 'build') this.waveManager.skipBuildTimer();
    });
    this.input.keyboard?.on('keydown-R', () => {
      this.scene.restart({ levelId: this.state.level?.id });
    });

    createUiText(this, GAME_WIDTH - 8, GAME_HEIGHT - 8, 'SPACE: skip build | R: restart', 16, COLORS.textDim, {
      originX: 1,
      originY: 1,
      depth: 100,
    });
  }

  private showBanner(text: string): void {
    const banner = createUiText(this, GAME_WIDTH / 2, GAME_HEIGHT / 2 - 40, text, 40, '#cc4444', {
      originX: 0.5,
      originY: 0.5,
      depth: 50,
    });
    banner.setAlpha(0);
    this.tweens.add({
      targets: banner,
      alpha: 1,
      duration: 300,
      yoyo: true,
      hold: 800,
      onComplete: () => banner.destroy(),
    });
  }

  private showOverlay(text: string, color: string): void {
    const bg = this.add.rectangle(GAME_WIDTH / 2, GAME_HEIGHT / 2, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0.7);
    bg.setDepth(90);
    createUiText(this, GAME_WIDTH / 2, GAME_HEIGHT / 2 - 20, text, 44, color, {
      originX: 0.5,
      originY: 0.5,
      depth: 91,
    });

    const menuBtn = createUiText(this, GAME_WIDTH / 2, GAME_HEIGHT / 2 + 40, 'Main Menu', 26, COLORS.text, {
      originX: 0.5,
      originY: 0.5,
      depth: 91,
    });
    menuBtn.setInteractive({ useHandCursor: true });
    menuBtn.on('pointerdown', () => this.scene.start('Menu'));

    const retryBtn = createUiText(this, GAME_WIDTH / 2, GAME_HEIGHT / 2 + 80, 'Retry', 26, COLORS.text, {
      originX: 0.5,
      originY: 0.5,
      depth: 91,
    });
    retryBtn.on('pointerdown', () => this.scene.restart({ levelId: this.state.level?.id }));
  }

  update(_time: number, delta: number): void {
    if (this.paused || this.state.phase === 'won' || this.state.phase === 'lost') return;
    const dt = delta / 1000;
    this.colony.update(dt);
    this.waveManager.update(dt);
    this.combat.update(dt);
    this.macroPanel.update();
    this.hud.update();
  }
}
