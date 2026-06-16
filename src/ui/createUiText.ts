import Phaser from 'phaser';

export type UiTextOptions = {
  originX?: number;
  originY?: number;
  maxWidth?: number;
  lineSpacing?: number;
  depth?: number;
  parent?: Phaser.GameObjects.Container;
};

/** UI labels: monospace + 2x resolution + integer positions. */
export function createUiText(
  scene: Phaser.Scene,
  x: number,
  y: number,
  content: string,
  sizePx: number,
  color: string,
  options: UiTextOptions = {},
): Phaser.GameObjects.Text {
  const text = scene.add.text(Math.round(x), Math.round(y), content, {
    fontFamily: 'Courier New, Consolas, monospace',
    fontSize: `${sizePx}px`,
    color,
    resolution: 2,
    wordWrap: options.maxWidth ? { width: options.maxWidth } : undefined,
    lineSpacing: options.lineSpacing,
  });

  if (options.originX !== undefined || options.originY !== undefined) {
    text.setOrigin(options.originX ?? 0, options.originY ?? 0);
  }
  if (options.depth !== undefined) {
    text.setDepth(options.depth);
  }
  if (options.parent) {
    options.parent.add(text);
  }

  return text;
}

export function setUiTextColor(text: Phaser.GameObjects.Text, color: string): void {
  text.setColor(color);
}

export function createUiTextBlock(
  scene: Phaser.Scene,
  x: number,
  y: number,
  lines: string[],
  sizePx: number,
  color: string,
  options: UiTextOptions = {},
): Phaser.GameObjects.Text {
  return createUiText(scene, x, y, lines.join('\n'), sizePx, color, {
    lineSpacing: options.lineSpacing ?? 2,
    ...options,
  });
}
