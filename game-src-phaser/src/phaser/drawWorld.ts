import Phaser from "phaser";
import { WORLD_HEIGHT, WORLD_WIDTH } from "../game/simulation";

export const drawWorld = (scene: Phaser.Scene) => {
  const g = scene.add.graphics();

  g.fillGradientStyle(0x24172d, 0x24172d, 0x183c37, 0x4d2440, 1);
  g.fillRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);

  drawGrid(g);
  drawColorFields(g);
  drawRail(g);
  drawLandmarks(g);

  g.destroy();
};

const drawGrid = (g: Phaser.GameObjects.Graphics) => {
  g.lineStyle(2, 0xfff7df, 0.055);
  for (let x = 100; x < WORLD_WIDTH; x += 100) {
    g.lineBetween(x, 0, x, WORLD_HEIGHT);
  }
  for (let y = 100; y < WORLD_HEIGHT; y += 100) {
    g.lineBetween(0, y, WORLD_WIDTH, y);
  }

  g.lineStyle(4, 0xfff7df, 0.08);
  for (let x = 300; x < WORLD_WIDTH; x += 600) {
    g.lineBetween(x, 0, x, WORLD_HEIGHT);
  }
  for (let y = 250; y < WORLD_HEIGHT; y += 500) {
    g.lineBetween(0, y, WORLD_WIDTH, y);
  }
};

const drawColorFields = (g: Phaser.GameObjects.Graphics) => {
  drawPad(g, 520, 430, 0x70e6a8, 170);
  drawPad(g, 1290, 850, 0xff79c6, 230);
  drawPad(g, 2070, 460, 0xffd35a, 190);
  drawPad(g, 740, 1270, 0x59dbff, 180);
  drawPad(g, 1980, 1280, 0xff9d66, 170);
};

const drawPad = (g: Phaser.GameObjects.Graphics, x: number, y: number, color: number, radius: number) => {
  g.fillStyle(color, 0.08);
  g.fillCircle(x, y, radius);
  g.lineStyle(8, color, 0.2);
  g.strokeCircle(x, y, radius * 0.62);
  g.lineStyle(3, 0xfff7df, 0.14);
  g.strokeCircle(x, y, radius * 0.32);
};

const drawRail = (g: Phaser.GameObjects.Graphics) => {
  g.lineStyle(14, 0x17121f, 0.3);
  g.strokeRoundedRect(58, 58, WORLD_WIDTH - 116, WORLD_HEIGHT - 116, 36);
  g.lineStyle(4, 0xfff7df, 0.18);
  g.strokeRoundedRect(76, 76, WORLD_WIDTH - 152, WORLD_HEIGHT - 152, 28);
};

const drawLandmarks = (g: Phaser.GameObjects.Graphics) => {
  const marks = [
    { x: 250, y: 240, color: 0xff79c6, sides: 3 },
    { x: 2350, y: 250, color: 0x70e6a8, sides: 4 },
    { x: 270, y: 1470, color: 0xffd35a, sides: 5 },
    { x: 2340, y: 1450, color: 0x59dbff, sides: 6 }
  ];

  for (const mark of marks) {
    g.fillStyle(0x17121f, 0.24);
    g.fillCircle(mark.x, mark.y + 24, 60);
    g.fillStyle(mark.color, 0.28);
    polygon(g, mark.x, mark.y, 58, mark.sides);
    g.lineStyle(5, mark.color, 0.52);
    strokePolygon(g, mark.x, mark.y, 58, mark.sides);
  }
};

const polygon = (g: Phaser.GameObjects.Graphics, x: number, y: number, radius: number, sides: number) => {
  g.beginPath();
  for (let i = 0; i < sides; i += 1) {
    const angle = -Math.PI / 2 + (Math.PI * 2 * i) / sides;
    const px = x + Math.cos(angle) * radius;
    const py = y + Math.sin(angle) * radius;
    if (i === 0) g.moveTo(px, py);
    else g.lineTo(px, py);
  }
  g.closePath();
  g.fillPath();
};

const strokePolygon = (g: Phaser.GameObjects.Graphics, x: number, y: number, radius: number, sides: number) => {
  g.beginPath();
  for (let i = 0; i < sides; i += 1) {
    const angle = -Math.PI / 2 + (Math.PI * 2 * i) / sides;
    const px = x + Math.cos(angle) * radius;
    const py = y + Math.sin(angle) * radius;
    if (i === 0) g.moveTo(px, py);
    else g.lineTo(px, py);
  }
  g.closePath();
  g.strokePath();
};
