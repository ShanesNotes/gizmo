import Phaser from "phaser";

export const preloadTitleArt = (scene: Phaser.Scene): void => {
  scene.load.image("title-bg", "./art/title-bg.jpg");
};

/** Ken-burns title backdrop with readability overlay. Returns overlay depth for layering UI above. */
export const createTitleBackdrop = (
  scene: Phaser.Scene,
  overlayColor = 0x0a2830,
  overlayAlpha = 0.42,
  baseDepth = 98
): { bg: Phaser.GameObjects.Image; overlay: Phaser.GameObjects.Rectangle } => {
  const W = scene.scale.width;
  const H = scene.scale.height;
  const bg = scene.add.image(W / 2, H / 2, "title-bg").setScrollFactor(0).setDepth(baseDepth);
  const cover = Math.max(W / bg.width, H / bg.height);
  const startScale = cover * 1.06;
  const endScale = cover * 1.14;
  bg.setScale(startScale);
  scene.tweens.add({
    targets: bg,
    scale: endScale,
    duration: 14000,
    ease: "Sine.easeInOut",
    yoyo: true,
    repeat: -1
  });
  scene.tweens.add({
    targets: bg,
    x: W / 2 + 12,
    duration: 18000,
    ease: "Sine.easeInOut",
    yoyo: true,
    repeat: -1
  });

  const overlay = scene.add
    .rectangle(W / 2, H / 2, W, H, overlayColor, overlayAlpha)
    .setScrollFactor(0)
    .setDepth(baseDepth + 1);

  return { bg, overlay };
};

/** Subtle floating sparkle dots for title screens. */
export const spawnTitleSparkles = (
  scene: Phaser.Scene,
  options: { count?: number; colors?: number[]; depth?: number } = {}
): Phaser.GameObjects.Arc[] => {
  const count = options.count ?? Phaser.Math.Between(3, 5);
  const colors = options.colors ?? [0xffffff, 0xffd24b, 0xff79c6];
  const depth = options.depth ?? 101;
  const W = scene.scale.width;
  const H = scene.scale.height;
  const sparkles: Phaser.GameObjects.Arc[] = [];

  for (let i = 0; i < count; i++) {
    const x = Phaser.Math.Between(Math.floor(W * 0.08), Math.floor(W * 0.92));
    const y = Phaser.Math.Between(Math.floor(H * 0.12), Math.floor(H * 0.88));
    const radius = Phaser.Math.Between(3, 5);
    const color = Phaser.Utils.Array.GetRandom(colors) as number;
    const dot = scene.add
      .circle(x, y, radius, color, 0.65)
      .setScrollFactor(0)
      .setDepth(depth)
      .setAlpha(0.35);
    sparkles.push(dot);

    scene.tweens.add({
      targets: dot,
      y: y - Phaser.Math.Between(14, 32),
      alpha: 0.9,
      scaleX: 1.25,
      scaleY: 1.25,
      duration: Phaser.Math.Between(1100, 1900),
      ease: "Sine.easeInOut",
      yoyo: true,
      repeat: -1,
      delay: i * 160
    });
    scene.tweens.add({
      targets: dot,
      x: x + Phaser.Math.Between(-16, 16),
      duration: Phaser.Math.Between(1500, 2600),
      ease: "Sine.easeInOut",
      yoyo: true,
      repeat: -1,
      delay: i * 90
    });
  }

  return sparkles;
};

/** Confetti burst for results / victory screens. */
export const spawnConfettiBurst = (scene: Phaser.Scene, colors?: number[], depth = 130): void => {
  const W = scene.scale.width;
  const H = scene.scale.height;
  const palette = colors ?? [0xf5c300, 0xff79c6, 0x70e6a8, 0xffd35a, 0x6ec8ff];

  for (let i = 0; i < 28; i++) {
    const x = Phaser.Math.Between(80, W - 80);
    const color = Phaser.Utils.Array.GetRandom(palette) as number;
    const size = Phaser.Math.Between(6, 11);
    const conf = scene.add.graphics();
    conf.fillStyle(color, 1);
    if (i % 3 === 0) {
      conf.fillCircle(size / 2, size / 2, size / 2);
    } else {
      conf.fillRect(0, 0, size, size * 0.65);
    }
    conf.setPosition(x, -20);
    conf.setDepth(depth);
    conf.setAlpha(0.92);
    scene.tweens.add({
      targets: conf,
      y: H + 40,
      x: x + Phaser.Math.Between(-90, 90),
      angle: Phaser.Math.Between(0, 720),
      duration: Phaser.Math.Between(1400, 2800),
      ease: "Linear",
      delay: Phaser.Math.Between(0, 1200),
      onComplete: () => conf.destroy()
    });
  }
};