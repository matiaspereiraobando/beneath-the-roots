import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH } from './config';

/** Snap canvas to whole-number zoom so pixels stay sharp when upscaled. */
export function applyIntegerZoom(game: Phaser.Game): void {
  const zoom = Math.max(
    1,
    Math.floor(Math.min(window.innerWidth / GAME_WIDTH, window.innerHeight / GAME_HEIGHT)),
  );
  game.scale.setZoom(zoom);
}

/** Scale a sprite by whole-number factors only (keeps pixel edges sharp). */
export function scaleSpriteToSize(
  sprite: Phaser.GameObjects.Image,
  targetW: number,
  targetH: number = targetW,
): void {
  const scale = Math.max(1, Math.floor(Math.min(targetW / sprite.width, targetH / sprite.height)));
  sprite.setScale(scale);
}

/** Nearest-neighbor on every texture — no bilinear blur on sprites/tiles. */
export function applyNearestFilter(game: Phaser.Game): void {
  for (const key of game.textures.getTextureKeys()) {
    game.textures.get(key).setFilter(Phaser.Textures.FilterMode.NEAREST);
  }
}

export function setupPixelArt(game: Phaser.Game): void {
  applyNearestFilter(game);
  game.textures.on(Phaser.Textures.Events.ADD, (_key: string, texture: Phaser.Textures.Texture) => {
    texture.setFilter(Phaser.Textures.FilterMode.NEAREST);
  });
  applyIntegerZoom(game);
  window.addEventListener('resize', () => applyIntegerZoom(game));
}
