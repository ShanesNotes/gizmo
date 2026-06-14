import Phaser from "phaser";

type TextureDraw = (graphics: Phaser.GameObjects.Graphics) => void;

export const createTextures = (scene: Phaser.Scene) => {
  // Hero loads from public/art/sprites/ via loadGameArt.ts
  texture(scene, "enemy-nibbler", 86, 86, (g) => drawEnemyCircle(g, 0x69e6b7));
  texture(scene, "enemy-dasher", 86, 86, (g) => drawEnemyTriangle(g, 0xff7a7a));
  texture(scene, "enemy-brute", 102, 102, (g) => drawEnemySquare(g, 0xffd35a));
  texture(scene, "enemy-warden", 96, 96, (g) => drawEnemyShield(g, 0x83b8ff));
  texture(scene, "pickup-xp", 48, 48, drawXpGem);
  texture(scene, "pickup-cache", 72, 72, drawCache);
  texture(scene, "pickup-heart", 58, 58, drawHeart);
  texture(scene, "orbit-star", 54, 54, drawOrbitStar);
  texture(scene, "hit-pop", 72, 72, drawHitPop);
  texture(scene, "blast-burst", 96, 96, drawBlastBurst);
};

const texture = (scene: Phaser.Scene, key: string, width: number, height: number, draw: TextureDraw) => {
  const graphics = scene.add.graphics();
  draw(graphics);
  graphics.generateTexture(key, width, height);
  graphics.destroy();
};

const drawEnemyCircle = (g: Phaser.GameObjects.Graphics, color: number) => {
  g.fillStyle(0x17121f, 0.22);
  g.fillEllipse(43, 68, 52, 12);
  g.fillStyle(color, 1);
  g.fillCircle(43, 42, 28);
  g.lineStyle(5, 0xfff7df, 0.9);
  g.strokeCircle(43, 42, 18);
  g.fillStyle(0x17121f, 1);
  g.fillCircle(35, 38, 4);
  g.fillCircle(51, 38, 4);
};

const drawEnemyTriangle = (g: Phaser.GameObjects.Graphics, color: number) => {
  g.fillStyle(0x17121f, 0.22);
  g.fillEllipse(43, 70, 54, 12);
  g.fillStyle(color, 1);
  g.beginPath();
  g.moveTo(43, 8);
  g.lineTo(76, 67);
  g.lineTo(10, 67);
  g.closePath();
  g.fillPath();
  g.lineStyle(5, 0xfff7df, 0.9);
  g.lineBetween(32, 45, 54, 45);
  g.lineStyle(4, 0x17121f, 0.9);
  g.lineBetween(37, 32, 33, 38);
  g.lineBetween(49, 32, 53, 38);
};

const drawEnemySquare = (g: Phaser.GameObjects.Graphics, color: number) => {
  g.fillStyle(0x17121f, 0.22);
  g.fillEllipse(51, 82, 66, 14);
  g.fillStyle(color, 1);
  g.fillRoundedRect(20, 18, 62, 62, 14);
  g.lineStyle(6, 0xfff7df, 0.86);
  g.strokeRoundedRect(29, 27, 44, 44, 10);
  g.fillStyle(0x17121f, 1);
  g.fillRoundedRect(35, 43, 32, 8, 4);
};

const drawEnemyShield = (g: Phaser.GameObjects.Graphics, color: number) => {
  g.fillStyle(0x17121f, 0.22);
  g.fillEllipse(48, 76, 62, 13);
  g.fillStyle(color, 1);
  g.beginPath();
  g.moveTo(48, 9);
  g.lineTo(78, 23);
  g.lineTo(72, 58);
  g.lineTo(48, 85);
  g.lineTo(24, 58);
  g.lineTo(18, 23);
  g.closePath();
  g.fillPath();
  g.lineStyle(6, 0xfff7df, 0.9);
  g.lineBetween(48, 20, 48, 70);
  g.lineStyle(5, 0x17121f, 0.72);
  g.strokeCircle(48, 45, 14);
};

const drawXpGem = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0x17121f, 0.2);
  g.fillEllipse(24, 39, 34, 7);
  g.fillStyle(0x70e6a8, 1);
  g.beginPath();
  g.moveTo(24, 4);
  g.lineTo(42, 24);
  g.lineTo(24, 44);
  g.lineTo(6, 24);
  g.closePath();
  g.fillPath();
  g.fillStyle(0xfff7df, 0.76);
  g.fillTriangle(24, 8, 35, 22, 24, 25);
};

const drawCache = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0x17121f, 0.24);
  g.fillEllipse(36, 58, 50, 11);
  g.fillStyle(0xffd35a, 1);
  for (let i = 0; i < 8; i += 1) {
    const angle = (Math.PI * 2 * i) / 8;
    g.fillCircle(36 + Math.cos(angle) * 24, 34 + Math.sin(angle) * 24, 9);
  }
  g.fillCircle(36, 34, 22);
  g.lineStyle(5, 0xfff7df, 0.9);
  g.strokeCircle(36, 34, 17);
  g.fillStyle(0xff79c6, 1);
  g.fillCircle(36, 34, 8);
};

const drawHeart = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0x17121f, 0.18);
  g.fillEllipse(29, 48, 38, 8);
  g.fillStyle(0xff6584, 1);
  g.fillCircle(20, 22, 12);
  g.fillCircle(38, 22, 12);
  g.beginPath();
  g.moveTo(10, 27);
  g.lineTo(29, 50);
  g.lineTo(48, 27);
  g.lineTo(29, 18);
  g.closePath();
  g.fillPath();
  g.fillStyle(0xfff7df, 0.8);
  g.fillCircle(22, 19, 4);
};

const drawOrbitStar = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0xff79c6, 1);
  g.beginPath();
  for (let i = 0; i < 10; i += 1) {
    const radius = i % 2 === 0 ? 24 : 10;
    const angle = -Math.PI / 2 + (Math.PI * 2 * i) / 10;
    const x = 27 + Math.cos(angle) * radius;
    const y = 27 + Math.sin(angle) * radius;
    if (i === 0) g.moveTo(x, y);
    else g.lineTo(x, y);
  }
  g.closePath();
  g.fillPath();
  g.fillStyle(0xfff7df, 0.85);
  g.fillCircle(27, 27, 7);
};

const drawHitPop = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0xffffff, 0.92);
  g.fillCircle(36, 36, 12);
  g.lineStyle(5, 0xffffff, 0.86);
  for (let i = 0; i < 10; i += 1) {
    const angle = (Math.PI * 2 * i) / 10;
    g.lineBetween(36 + Math.cos(angle) * 20, 36 + Math.sin(angle) * 20, 36 + Math.cos(angle) * 32, 36 + Math.sin(angle) * 32);
  }
};

const drawBlastBurst = (g: Phaser.GameObjects.Graphics) => {
  g.fillStyle(0xffffff, 0.95);
  g.fillCircle(48, 48, 14);
  for (let i = 0; i < 14; i += 1) {
    const angle = (Math.PI * 2 * i) / 14;
    const radius = i % 2 === 0 ? 37 : 27;
    g.fillCircle(48 + Math.cos(angle) * radius, 48 + Math.sin(angle) * radius, i % 2 === 0 ? 8 : 5);
  }
};
