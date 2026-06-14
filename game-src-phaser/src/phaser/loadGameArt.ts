import Phaser from "phaser";

/** Load Grok-generated gouache sprites (replaces procedural placeholders). */
export const preloadGameArt = (scene: Phaser.Scene): void => {
  scene.load.image("hero-core", "./art/sprites/hero.jpg");
};

/** Scale loaded sprite to match previous procedural footprint. */
export const fitSprite = (
  image: Phaser.GameObjects.Image,
  targetW: number,
  targetH: number
): void => {
  const sx = targetW / image.width;
  const sy = targetH / image.height;
  image.setScale(Math.min(sx, sy));
};