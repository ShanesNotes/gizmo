import Phaser from "phaser";
import {
  DASHER_WINDUP_TIME,
  WORLD_HEIGHT,
  WORLD_WIDTH,
  boostScoopRadius,
  chooseUpgrade,
  createGameState,
  enemyColor,
  orbitStats,
  pickupRadius,
  rerollUpgradeChoices,
  snapBoostWindowProgress,
  updateGameState,
  type AttackKind,
  type BountyKind,
  type BountyState,
  type EnemyState,
  type GameEvent,
  type GameState,
  type InputState,
  type PickupKind,
  type PickupState,
  type UpgradeChoice,
  type UpgradeId
} from "../game/simulation";
import type { HudController } from "../ui/hud";
import {
  blip,
  bossExplode,
  bossRumble,
  countdownBlip,
  explode,
  fanfare,
  hit,
  itemGet,
  isMuted,
  setMute,
  shieldHit,
  shootBubble,
  shootMagnet,
  shootSpark
} from "../ui/sfx";
import { drawWorld } from "./drawWorld";
import { fitSprite } from "./loadGameArt";
import { createTitleBackdrop, spawnConfettiBurst, spawnTitleSparkles } from "./titleArt";

type ScenePhase = "title" | "countdown" | "playing" | "ended";

type KeySet = {
  W: Phaser.Input.Keyboard.Key;
  A: Phaser.Input.Keyboard.Key;
  S: Phaser.Input.Keyboard.Key;
  D: Phaser.Input.Keyboard.Key;
  UP: Phaser.Input.Keyboard.Key;
  DOWN: Phaser.Input.Keyboard.Key;
  LEFT: Phaser.Input.Keyboard.Key;
  RIGHT: Phaser.Input.Keyboard.Key;
  SPACE: Phaser.Input.Keyboard.Key;
  R: Phaser.Input.Keyboard.Key;
  M: Phaser.Input.Keyboard.Key;
  ONE: Phaser.Input.Keyboard.Key;
  TWO: Phaser.Input.Keyboard.Key;
  THREE: Phaser.Input.Keyboard.Key;
};

type EnemyView = {
  sprite: Phaser.GameObjects.Image;
  glow: Phaser.GameObjects.Arc;
  tell: Phaser.GameObjects.Arc;
  barBack: Phaser.GameObjects.Rectangle;
  bar: Phaser.GameObjects.Rectangle;
};

type PickupView = {
  sprite: Phaser.GameObjects.Image;
  glow: Phaser.GameObjects.Arc;
};

type RewardPointerView = {
  container: Phaser.GameObjects.Container;
  ring: Phaser.GameObjects.Arc;
  arrow: Phaser.GameObjects.Triangle;
  label: Phaser.GameObjects.Text;
};

type RewardPointerTarget = {
  kind: "cache" | "heart" | "elite" | "shards";
  x: number;
  y: number;
  priority: number;
  distanceSq: number;
};

declare global {
  interface Window {
    __MISCHIEF_DEBUG__?: { scenePhase: () => ScenePhase; state: () => GameState; start: () => void };
  }
}

export class MischiefScene extends Phaser.Scene {
  private state!: GameState;
  private keys!: KeySet;
  private hero!: Phaser.GameObjects.Image;
  private heroShadow!: Phaser.GameObjects.Ellipse;
  private magnetRing!: Phaser.GameObjects.Arc;
  private rewardPointer!: RewardPointerView;
  private pointerTarget: Phaser.Math.Vector2 | null = null;
  private moving = false;
  private scenePhase: ScenePhase = "title";
  private choicesOpen = false;
  private endShown = false;
  private enemyViews = new Map<string, EnemyView>();
  private pickupViews = new Map<string, PickupView>();
  private orbitSprites: Phaser.GameObjects.Image[] = [];
  private sparkLayers: Phaser.GameObjects.Graphics[] = [];
  private sparkPoints: { x: number; y: number; size: number; speed: number; color: number }[][] = [];
  private auraGraphics!: Phaser.GameObjects.Graphics;
  private auraOffset = 0;
  private titleContainer?: Phaser.GameObjects.Container;
  private countdownContainer?: Phaser.GameObjects.Container;
  private countdownLabel?: Phaser.GameObjects.Text;
  private countdownFallback?: number;
  private debugNode?: HTMLElement;
  private lastPickupSoundAt = 0;
  private lastHitSoundAt = 0;
  private lastSparkSoundAt = 0;
  private lastOrbitSoundAt = 0;
  private titleStartCleanup?: () => void;
  private impactSlowTimer = 0;
  private impactSlowScale = 1;

  constructor(private readonly hud: HudController) {
    super("MischiefScene");
  }

  create() {
    this.state = createGameState();
    this.pointerTarget = null;
    this.moving = false;
    this.titleStartCleanup?.();
    this.titleStartCleanup = undefined;
    if (this.countdownFallback !== undefined) window.clearTimeout(this.countdownFallback);
    this.countdownFallback = undefined;
    this.scenePhase = "title";
    this.choicesOpen = false;
    this.endShown = false;
    this.impactSlowTimer = 0;
    this.impactSlowScale = 1;
    this.enemyViews.clear();
    this.pickupViews.clear();
    this.orbitSprites = [];
    this.sparkLayers = [];
    this.sparkPoints = [];

    this.cameras.main.setBounds(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
    this.cameras.main.setScroll(WORLD_WIDTH / 2 - this.scale.width / 2, WORLD_HEIGHT / 2 - this.scale.height / 2);

    this.buildSparkField();
    drawWorld(this);
    this.createHero();
    this.createMagnetRing();
    this.createRewardPointer();
    this.bindInput();
    this.exposeDebugState();

    this.hud.hideRunEnd();
    this.hud.hideLevelChoices();
    this.hud.hide();

    this.showTitle();
  }

  update(_time: number, deltaMs: number) {
    const rawDt = Math.min(deltaMs / 1000, 0.05);
    this.impactSlowTimer = Math.max(0, this.impactSlowTimer - rawDt);
    if (this.impactSlowTimer <= 0) this.impactSlowScale = 1;
    const tempoScale = this.impactSlowTimer > 0 ? this.impactSlowScale : 1;
    const dt = rawDt * tempoScale;
    this.scrollSparkField(dt);

    if (this.scenePhase === "title") return;
    if (this.scenePhase === "countdown") return;
    if (this.scenePhase === "ended") return;

    if (this.state.phase === "levelup") {
      this.handlePausedInput();
      this.syncWorld(deltaMs);
      this.hud.setState(this.state);
      this.updateDebugState();
      return;
    }

    const input = this.readInput();
    if (input.restart) {
      this.scene.restart();
      return;
    }

    const events = updateGameState(this.state, input, dt);
    this.syncWorld(deltaMs * tempoScale);
    this.processEvents(events);
    this.hud.setState(this.state);
    this.updateDebugState();
  }

  private buildSparkField() {
    const layerSpeeds = [9, 18, 33];
    const colors = [0xffffff, 0x70e6a8, 0xffd35a];
    for (let layer = 0; layer < layerSpeeds.length; layer += 1) {
      const points: { x: number; y: number; size: number; speed: number; color: number }[] = [];
      const count = layer === 0 ? 80 : layer === 1 ? 54 : 36;
      for (let i = 0; i < count; i += 1) {
        points.push({
          x: Math.random() * WORLD_WIDTH,
          y: Math.random() * WORLD_HEIGHT,
          size: 1.5 + Math.random() * (layer + 2),
          speed: layerSpeeds[layer],
          color: colors[layer]
        });
      }
      this.sparkPoints.push(points);
      this.sparkLayers.push(this.add.graphics().setDepth(1 + layer));
    }
    this.auraGraphics = this.add.graphics().setDepth(4);
    this.drawAura(0);
  }

  private scrollSparkField(dt: number) {
    for (let layer = 0; layer < this.sparkLayers.length; layer += 1) {
      const graphics = this.sparkLayers[layer];
      const points = this.sparkPoints[layer];
      graphics.clear();
      for (const point of points) {
        point.y += point.speed * dt;
        point.x += Math.sin((this.time.now + point.y) / 900) * dt * (layer + 1) * 8;
        if (point.y > WORLD_HEIGHT) {
          point.y -= WORLD_HEIGHT;
          point.x = Math.random() * WORLD_WIDTH;
        }
        graphics.fillStyle(point.color, layer === 0 ? 0.35 : 0.5);
        if (layer === 2) {
          graphics.fillTriangle(point.x, point.y - point.size, point.x + point.size, point.y + point.size, point.x - point.size, point.y + point.size);
        } else {
          graphics.fillCircle(point.x, point.y, point.size);
        }
      }
    }

    this.auraOffset += dt * 0.28;
    this.drawAura(this.auraOffset);
  }

  private drawAura(offset: number) {
    const graphics = this.auraGraphics;
    graphics.clear();
    const bands = [
      { x: 420, y: 360, radius: 330, color: 0xff79c6, alpha: 0.035 },
      { x: 1580, y: 540, radius: 380, color: 0x70e6a8, alpha: 0.038 },
      { x: 980, y: 1190, radius: 310, color: 0xffd35a, alpha: 0.04 },
      { x: 2160, y: 1110, radius: 270, color: 0x59dbff, alpha: 0.04 }
    ];
    for (const band of bands) {
      const y = band.y + Math.sin(offset + band.x * 0.001) * 24;
      graphics.fillStyle(band.color, band.alpha);
      graphics.fillCircle(band.x, y, band.radius);
    }
  }

  private showTitle() {
    const width = this.scale.width;
    const height = this.scale.height;
    const cx = width / 2;
    const cy = height / 2;

    const { bg, overlay } = createTitleBackdrop(this, 0x17121f, 0.52, 158);
    bg.setScrollFactor(0);
    overlay.setScrollFactor(0);
    const sparkles = spawnTitleSparkles(this, {
      depth: 161,
      colors: [0xfff7df, 0xff79c6, 0x70e6a8, 0xffd35a]
    });
    const title = this.add
      .text(cx, height * 0.2, "SHAPE\nSTORM", {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: `${Math.min(96, Math.max(58, width * 0.085))}px`,
        fontStyle: "bold",
        color: "#fff7df",
        stroke: "#ff79c6",
        strokeThickness: 7,
        align: "center",
        lineSpacing: 6
      })
      .setOrigin(0.5)
      .setDepth(162)
      .setScrollFactor(0)
      .setAlpha(0);
    const core = this.add.image(cx, cy + 24, "hero-core").setDepth(163).setScrollFactor(0);
    fitSprite(core, 200, 200);
    const subtitle = this.add
      .text(cx, height * 0.74, "GIZMO SURGE", {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: "26px",
        color: "#70e6a8",
        stroke: "#17121f",
        strokeThickness: 5
      })
      .setOrigin(0.5)
      .setDepth(164)
      .setScrollFactor(0)
      .setAlpha(0);
    const prompt = this.add
      .text(cx, height * 0.84, "PRESS ANY KEY OR TAP", {
        fontFamily: "Arial, sans-serif",
        fontSize: "18px",
        fontStyle: "bold",
        color: "#ffd35a",
        stroke: "#17121f",
        strokeThickness: 4
      })
      .setOrigin(0.5)
      .setDepth(164)
      .setScrollFactor(0)
      .setAlpha(0);

    this.titleContainer = this.add
      .container(0, 0, [bg, overlay, ...sparkles, title, core, subtitle, prompt])
      .setDepth(160);
    this.tweens.add({ targets: title, y: height * 0.2 - 10, alpha: 1, duration: 560, ease: "Back.easeOut" });
    this.tweens.add({ targets: core, angle: 360, duration: 900, ease: "Back.easeOut" });
    this.tweens.add({ targets: subtitle, alpha: 1, delay: 280, duration: 360 });
    this.tweens.add({
      targets: prompt,
      alpha: 1,
      delay: 620,
      duration: 260,
      onComplete: () => {
        this.tweens.add({ targets: prompt, alpha: 0.35, duration: 620, yoyo: true, repeat: -1, ease: "Sine.easeInOut" });
      }
    });

    const start = () => this.startFromTitle();
    const keyStart = (event: KeyboardEvent) => {
      if (event.repeat) return;
      start();
    };
    this.input.keyboard?.once("keydown", start);
    this.input.once("pointerdown", start);
    this.game.canvas.addEventListener("pointerdown", start, { once: true });
    window.addEventListener("keydown", keyStart, { once: true });
    this.titleStartCleanup = () => {
      this.game.canvas.removeEventListener("pointerdown", start);
      window.removeEventListener("keydown", keyStart);
    };
  }

  private startFromTitle() {
    if (this.scenePhase !== "title") return;
    this.titleStartCleanup?.();
    this.titleStartCleanup = undefined;
    this.scenePhase = "countdown";
    this.updateDebugState();
    blip(640, 0.08);
    this.countdownFallback = window.setTimeout(() => this.finishCountdown(), 4200);
    if (this.titleContainer) {
      this.tweens.add({
        targets: this.titleContainer.list,
        alpha: 0,
        duration: 280,
        onComplete: () => this.titleContainer?.destroy()
      });
    }
    this.time.delayedCall(330, () => this.runCountdown());
  }

  private runCountdown() {
    this.countdownLabel = this.add
      .text(this.scale.width / 2, this.scale.height / 2, "3", {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: "132px",
        fontStyle: "bold",
        color: "#ffd35a",
        stroke: "#17121f",
        strokeThickness: 10
      })
      .setOrigin(0.5)
      .setDepth(210)
      .setScale(0)
      .setScrollFactor(0);
    this.countdownContainer = this.add.container(0, 0, [this.countdownLabel]).setDepth(210);
    this.doCountdownStep(3);
  }

  private doCountdownStep(n: number) {
    if (!this.countdownLabel) return;
    const labels: Record<number, string> = { 3: "3", 2: "2", 1: "1", 0: "GO!" };
    const colors: Record<number, string> = { 3: "#ff79c6", 2: "#ffd35a", 1: "#59dbff", 0: "#70e6a8" };
    this.countdownLabel.setText(labels[n]);
    this.countdownLabel.setColor(colors[n]);
    countdownBlip(n);
    this.tweens.add({ targets: this.countdownLabel, scale: 1, duration: 170, ease: "Back.easeOut" });
    this.tweens.add({
      targets: this.countdownLabel,
      scale: 0,
      alpha: 0,
      duration: 210,
      delay: 560,
      ease: "Sine.easeIn",
      onComplete: () => {
        this.countdownLabel?.setAlpha(1).setScale(0);
        if (n > 0) this.doCountdownStep(n - 1);
        else this.finishCountdown();
      }
    });
  }

  private finishCountdown() {
    if (this.scenePhase !== "countdown") return;
    if (this.countdownFallback !== undefined) window.clearTimeout(this.countdownFallback);
    this.countdownFallback = undefined;
    this.countdownContainer?.destroy();
    this.beginPlaying();
  }

  private beginPlaying() {
    this.scenePhase = "playing";
    this.hero.setVisible(true);
    this.heroShadow.setVisible(true);
    this.hud.show();
    this.hud.setState(this.state);
    this.cameras.main.startFollow(this.hero, true, 0.08, 0.08);
    this.updateDebugState();
  }

  private bindInput() {
    this.input.removeAllListeners("pointerdown");
    this.input.removeAllListeners("pointermove");
    this.input.removeAllListeners("pointerup");
    this.input.keyboard?.removeAllListeners("keydown-M");

    this.keys = this.input.keyboard?.addKeys({
      W: Phaser.Input.Keyboard.KeyCodes.W,
      A: Phaser.Input.Keyboard.KeyCodes.A,
      S: Phaser.Input.Keyboard.KeyCodes.S,
      D: Phaser.Input.Keyboard.KeyCodes.D,
      UP: Phaser.Input.Keyboard.KeyCodes.UP,
      DOWN: Phaser.Input.Keyboard.KeyCodes.DOWN,
      LEFT: Phaser.Input.Keyboard.KeyCodes.LEFT,
      RIGHT: Phaser.Input.Keyboard.KeyCodes.RIGHT,
      SPACE: Phaser.Input.Keyboard.KeyCodes.SPACE,
      R: Phaser.Input.Keyboard.KeyCodes.R,
      M: Phaser.Input.Keyboard.KeyCodes.M,
      ONE: Phaser.Input.Keyboard.KeyCodes.ONE,
      TWO: Phaser.Input.Keyboard.KeyCodes.TWO,
      THREE: Phaser.Input.Keyboard.KeyCodes.THREE
    }) as KeySet;

    this.input.keyboard?.on("keydown-M", () => setMute(!isMuted()));

    this.input.on("pointerdown", (pointer: Phaser.Input.Pointer) => {
      if (this.scenePhase === "playing" && pointer.event.target === this.game.canvas) {
        this.pointerTarget = pointer.positionToCamera(this.cameras.main) as Phaser.Math.Vector2;
      }
    });
    this.input.on("pointermove", (pointer: Phaser.Input.Pointer) => {
      if (this.scenePhase === "playing" && pointer.isDown && pointer.event.target === this.game.canvas) {
        this.pointerTarget = pointer.positionToCamera(this.cameras.main) as Phaser.Math.Vector2;
      }
    });
    this.input.on("pointerup", () => {
      this.pointerTarget = null;
    });
  }

  private readInput(): InputState {
    let x = 0;
    let y = 0;
    if (this.keys.A.isDown || this.keys.LEFT.isDown) x -= 1;
    if (this.keys.D.isDown || this.keys.RIGHT.isDown) x += 1;
    if (this.keys.W.isDown || this.keys.UP.isDown) y -= 1;
    if (this.keys.S.isDown || this.keys.DOWN.isDown) y += 1;

    const hudInput = this.hud.consumeInput();
    x += hudInput.x;
    y += hudInput.y;

    if (this.pointerTarget) {
      const dx = this.pointerTarget.x - this.state.player.x;
      const dy = this.pointerTarget.y - this.state.player.y;
      if (Math.hypot(dx, dy) > 24) {
        x += dx;
        y += dy;
      } else {
        this.pointerTarget = null;
      }
    }

    const magnitude = Math.hypot(x, y);
    this.moving = magnitude > 0.02;
    return {
      x: magnitude > 0 ? x / magnitude : 0,
      y: magnitude > 0 ? y / magnitude : 0,
      action: Phaser.Input.Keyboard.JustDown(this.keys.SPACE) || hudInput.action,
      restart: Phaser.Input.Keyboard.JustDown(this.keys.R) || hudInput.restart
    };
  }

  private handlePausedInput() {
    const hudInput = this.hud.consumeInput();
    if (hudInput.restart || Phaser.Input.Keyboard.JustDown(this.keys.R)) {
      this.scene.restart();
      return;
    }
    if (Phaser.Input.Keyboard.JustDown(this.keys.ONE)) this.pickChoice(0);
    if (Phaser.Input.Keyboard.JustDown(this.keys.TWO)) this.pickChoice(1);
    if (Phaser.Input.Keyboard.JustDown(this.keys.THREE)) this.pickChoice(2);
  }

  private createHero() {
    this.heroShadow = this.add.ellipse(this.state.player.x, this.state.player.y + 32, 72, 20, 0x17121f, 0.34).setDepth(48);
    this.hero = this.add.image(this.state.player.x, this.state.player.y, "hero-core").setDepth(55);
    fitSprite(this.hero, 112, 112);
    this.hero.setVisible(false);
    this.heroShadow.setVisible(false);
  }

  private createMagnetRing() {
    this.magnetRing = this.add.circle(this.state.player.x, this.state.player.y, pickupRadius(this.state), 0xffffff, 0);
    this.magnetRing.setStrokeStyle(3, 0xffffff, 0.1).setDepth(12);
  }

  private syncWorld(deltaMs: number) {
    this.syncHero(deltaMs);
    this.syncMagnetRing();
    this.syncEnemies();
    this.syncPickups();
    this.syncRewardPointer();
    this.syncOrbitals();
  }

  private syncHero(deltaMs: number) {
    const speed = Math.hypot(this.state.player.vx, this.state.player.vy);
    const bob = Math.sin(this.time.now / 120) * (speed > 40 ? 3.1 : 1.4);
    const blink = this.state.player.invulnerable > 0 && Math.sin(this.time.now / 48) > 0;
    const echo = this.state.powerEcho > 0;
    const dashScale = this.state.player.dashTimer > 0 ? 1.16 : echo ? 1.06 : 1;
    this.hero
      .setPosition(this.state.player.x, this.state.player.y + bob)
      .setFlipX(this.state.player.facingX < 0)
      .setAlpha(blink ? 0.45 : 1)
      .setTint(echo ? 0xfff1a8 : 0xffffff)
      .setScale(dashScale);
    this.heroShadow.setPosition(this.state.player.x, this.state.player.y + 34).setAlpha(blink ? 0.18 : echo ? 0.46 : 0.34);
    const lean = Phaser.Math.Clamp(this.state.player.vx / 1650, -0.16, 0.16);
    this.hero.rotation = Phaser.Math.Linear(this.hero.rotation, lean, deltaMs / 150);
  }

  private syncMagnetRing() {
    const ready = this.state.player.dashCooldown <= 0;
    const queued = this.state.player.boostQueued;
    const snapWindow = snapBoostWindowProgress(this.state);
    this.magnetRing.setPosition(this.state.player.x, this.state.player.y);
    this.magnetRing.setRadius(pickupRadius(this.state) + boostScoopRadius(this.state) + snapWindow * 16);
    this.magnetRing.setStrokeStyle(
      this.state.player.dashTimer > 0 ? 5 : queued || snapWindow > 0 ? 3 + snapWindow * 2 : 3,
      this.state.player.dashTimer > 0 ? 0xffd35a : queued || snapWindow > 0 ? 0xffd35a : ready ? 0x70e6a8 : 0xffffff,
      this.state.player.dashTimer > 0 ? 0.34 : queued ? 0.3 : snapWindow > 0 ? 0.13 + snapWindow * 0.2 : ready ? 0.23 : 0.1
    );
  }

  private syncEnemies() {
    const activeIds = new Set(this.state.enemies.map((enemy) => enemy.id));
    for (const [id, view] of this.enemyViews.entries()) {
      if (!activeIds.has(id)) {
        view.sprite.destroy();
        view.glow.destroy();
        view.tell.destroy();
        view.barBack.destroy();
        view.bar.destroy();
        this.enemyViews.delete(id);
      }
    }

    for (const enemy of this.state.enemies) {
      let view = this.enemyViews.get(enemy.id);
      if (!view) {
        view = this.createEnemyView(enemy);
        this.enemyViews.set(enemy.id, view);
      }
      const hpRatio = Math.max(0, enemy.hp) / enemy.maxHp;
      const windupProgress = enemy.kind === "dasher" && enemy.chargeWindup > 0 ? 1 - enemy.chargeWindup / DASHER_WINDUP_TIME : 0;
      const bursting = enemy.kind === "dasher" && enemy.chargeBurst > 0;
      const warning = windupProgress > 0 || bursting;
      const bountyElite = enemy.elite && this.state.bounty?.kind === "elite";
      const pulse = enemy.elite ? 1 + Math.sin(this.time.now / 160) * 0.05 : 1;
      const scale = (enemy.radius / 26) * pulse * (bountyElite ? 1.04 : 1) * (bursting ? 1.18 : 1 + windupProgress * 0.12);
      view.sprite
        .setPosition(enemy.x, enemy.y)
        .setRotation(Math.atan2(enemy.vy, enemy.vx) + Math.PI / 2 + Math.sin(this.time.now / 360 + enemy.wobble) * 0.08)
        .setScale(scale)
        .setAlpha(1);
      if (enemy.kind === "dasher") {
        view.sprite.setTint(bursting ? 0xfff1a8 : windupProgress > 0.45 ? 0xffb3c2 : enemy.elite ? 0xfff1a8 : 0xffffff);
      }
      view.glow
        .setVisible(true)
        .setPosition(enemy.x, enemy.y)
        .setRadius(enemy.radius + (enemy.elite ? 26 : 14) + (warning ? 10 : 0) + (bountyElite ? 12 : 0))
        .setAlpha(
          bursting
            ? 0.44
            : windupProgress > 0
              ? 0.24 + windupProgress * 0.2
              : enemy.elite
                ? (bountyElite ? 0.44 : 0.3) + Math.sin(this.time.now / 150) * 0.08
                : 0.12 + (1 - hpRatio) * 0.16
        );
      view.tell
        .setVisible(warning)
        .setPosition(enemy.x, enemy.y)
        .setRadius(enemy.radius + 20 + windupProgress * 28 + (bursting ? 18 : 0))
        .setAlpha(bursting ? 0.72 : 0.32 + windupProgress * 0.5)
        .setStrokeStyle(bursting ? 8 : 5 + windupProgress * 5, bursting ? 0xffd35a : 0xff6584, bursting ? 0.8 : 0.42 + windupProgress * 0.38);
      view.barBack.setVisible(enemy.elite || hpRatio < 1).setPosition(enemy.x, enemy.y - enemy.radius - 16);
      view.bar
        .setVisible(enemy.elite || hpRatio < 1)
        .setPosition(enemy.x - 25, enemy.y - enemy.radius - 16)
        .setDisplaySize(Math.max(0, 50 * hpRatio), 6);
    }
  }

  private createEnemyView(enemy: EnemyState): EnemyView {
    const color = hexToNumber(enemy.elite ? "#ffd35a" : enemyColor(enemy.kind));
    const glow = this.add.circle(enemy.x, enemy.y, enemy.radius + 16, color, enemy.elite ? 0.24 : 0.12).setDepth(22);
    const tell = this.add.circle(enemy.x, enemy.y, enemy.radius + 24, 0xff6584, 0).setDepth(35).setVisible(false);
    tell.setStrokeStyle(5, 0xff6584, 0.5);
    const sprite = this.add.image(enemy.x, enemy.y, `enemy-${enemy.kind}`).setDepth(enemy.elite ? 34 : 30);
    if (enemy.elite) sprite.setTint(0xfff1a8);
    const barBack = this.add.rectangle(enemy.x, enemy.y - enemy.radius - 16, 50, 6, 0x17121f, 0.64).setDepth(36);
    const bar = this.add.rectangle(enemy.x - 25, enemy.y - enemy.radius - 16, 50, 6, color, 0.96).setOrigin(0, 0.5).setDepth(37);
    return { sprite, glow, tell, barBack, bar };
  }

  private syncPickups() {
    const activeIds = new Set(this.state.pickups.map((pickup) => pickup.id));
    for (const [id, view] of this.pickupViews.entries()) {
      if (!activeIds.has(id)) {
        view.sprite.destroy();
        view.glow.destroy();
        this.pickupViews.delete(id);
      }
    }

    for (const pickup of this.state.pickups) {
      let view = this.pickupViews.get(pickup.id);
      if (!view) {
        view = this.createPickupView(pickup);
        this.pickupViews.set(pickup.id, view);
      }
      const bob = Math.sin(pickup.bob) * 5;
      const bountyKind = this.state.bounty?.kind;
      const bountyRelevant =
        (pickup.kind === "xp" && (bountyKind === "sweep" || bountyKind === "flow")) ||
        (pickup.kind === "cache" && bountyKind === "cache");
      const cachePulse = pickup.kind === "cache" ? 1.08 + Math.sin(this.time.now / 150 + pickup.bob) * 0.12 : 1;
      const bountyPulse = bountyRelevant ? 1 + Math.sin(this.time.now / 130 + pickup.bob) * 0.08 : 1;
      const scale = (pickup.kind === "xp" ? 0.78 + Math.sin(this.time.now / 140 + pickup.bob) * 0.06 : cachePulse) * bountyPulse;
      view.sprite.setPosition(pickup.x, pickup.y + bob).setScale(scale).setRotation(this.time.now / (pickup.kind === "cache" ? 420 : 900));
      view.glow
        .setPosition(pickup.x, pickup.y)
        .setRadius((pickup.kind === "cache" ? 54 + Math.sin(this.time.now / 160 + pickup.bob) * 8 : pickup.kind === "heart" ? 42 : 28) + (bountyRelevant ? 12 : 0))
        .setAlpha(bountyRelevant ? 0.34 + Math.sin(this.time.now / 150 + pickup.bob) * 0.08 : pickup.kind === "xp" ? 0.16 : 0.26 + Math.sin(this.time.now / 180) * 0.08);
    }
  }

  private createPickupView(pickup: PickupState): PickupView {
    const color = pickup.kind === "cache" ? 0xffd35a : pickup.kind === "heart" ? 0xff6584 : 0x70e6a8;
    const glow = this.add.circle(pickup.x, pickup.y, pickup.kind === "xp" ? 28 : 42, color, 0.18).setDepth(24);
    const sprite = this.add.image(pickup.x, pickup.y, `pickup-${pickup.kind}`).setDepth(31);
    return { sprite, glow };
  }

  private createRewardPointer() {
    const ring = this.add.circle(0, 0, 25, 0x17121f, 0.82).setStrokeStyle(3, 0xffd35a, 0.95);
    const arrow = this.add.triangle(0, -2, -9, -12, 14, 0, -9, 12, 0xffd35a, 1);
    const label = this.add
      .text(0, 28, "CACHE", {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: "11px",
        fontStyle: "bold",
        color: "#fff7df",
        stroke: "#17121f",
        strokeThickness: 4
      })
      .setOrigin(0.5);
    const container = this.add.container(0, 0, [ring, arrow, label]).setDepth(125).setScrollFactor(0).setVisible(false);
    this.rewardPointer = { container, ring, arrow, label };
  }

  private syncRewardPointer() {
    const candidate = this.nearestRewardTarget();
    if (!candidate) {
      this.rewardPointer.container.setVisible(false);
      return;
    }

    const camera = this.cameras.main;
    const width = this.scale.width;
    const height = this.scale.height;
    const edge = 54;
    const screenX = candidate.x - camera.scrollX;
    const screenY = candidate.y - camera.scrollY;
    const cx = width / 2;
    const cy = height / 2;
    const dx = screenX - cx;
    const dy = screenY - cy;
    const scale = Math.min((width / 2 - edge) / Math.max(1, Math.abs(dx)), (height / 2 - edge) / Math.max(1, Math.abs(dy)));
    const x = cx + dx * scale;
    const y = cy + dy * scale;
    const color = candidate.kind === "heart" ? 0xff6584 : candidate.kind === "elite" ? 0xfff1a8 : candidate.kind === "shards" ? 0x70e6a8 : 0xffd35a;
    const label = candidate.kind === "elite" ? "BIG" : candidate.kind === "cache" ? "CACHE" : candidate.kind === "shards" ? "SHARDS" : "HEART";
    const hotTarget = candidate.kind === "elite" || candidate.kind === "shards";
    const pulse = 1 + Math.sin(this.time.now / (hotTarget ? 145 : 180)) * (hotTarget ? 0.12 : 0.08);
    const strokeWidth = hotTarget ? 4 : 3;

    this.rewardPointer.container
      .setVisible(true)
      .setPosition(Phaser.Math.Clamp(x, edge, width - edge), Phaser.Math.Clamp(y, edge, height - edge))
      .setScale(pulse)
      .setRotation(Math.atan2(dy, dx));
    this.rewardPointer.ring.setStrokeStyle(strokeWidth, color, 0.95).setFillStyle(0x17121f, hotTarget ? 0.88 : 0.82);
    this.rewardPointer.arrow.setFillStyle(color, 1);
    this.rewardPointer.label
      .setText(label)
      .setColor(candidate.kind === "heart" ? "#ff6584" : candidate.kind === "elite" ? "#fff7df" : candidate.kind === "shards" ? "#70e6a8" : "#ffd35a")
      .setRotation(-this.rewardPointer.container.rotation);
  }

  private nearestRewardTarget(): RewardPointerTarget | null {
    const camera = this.cameras.main;
    const edge = 74;
    const offscreen = (x: number, y: number): boolean => {
      const screenX = x - camera.scrollX;
      const screenY = y - camera.scrollY;
      return screenX < edge || screenX > this.scale.width - edge || screenY < edge || screenY > this.scale.height - edge;
    };
    const makeTarget = (kind: RewardPointerTarget["kind"], x: number, y: number, priority: number): RewardPointerTarget => ({
      kind,
      x,
      y,
      priority,
      distanceSq: distanceSquared(this.state.player.x, this.state.player.y, x, y)
    });

    const targets: RewardPointerTarget[] = [];
    const bountyKind = this.state.bounty?.kind;
    for (const pickup of this.state.pickups) {
      if (pickup.value < 0 || (pickup.kind !== "cache" && pickup.kind !== "heart") || !offscreen(pickup.x, pickup.y)) continue;
      const priority = pickup.kind === "heart" && this.state.player.hp <= 2 ? -1800 : pickup.kind === "cache" ? (bountyKind === "cache" ? -1450 : -900) : 0;
      targets.push(makeTarget(pickup.kind, pickup.x, pickup.y, priority));
    }

    for (const enemy of this.state.enemies) {
      if (!enemy.elite || enemy.hp <= 0 || !offscreen(enemy.x, enemy.y)) continue;
      const hpRatio = Phaser.Math.Clamp(enemy.hp / Math.max(1, enemy.maxHp), 0, 1);
      const bountyLift = bountyKind === "elite" ? -520 : 0;
      targets.push(makeTarget("elite", enemy.x, enemy.y, -1120 + bountyLift - Math.round((1 - hpRatio) * 420)));
    }

    const shardCluster = bountyKind === "sweep" || bountyKind === "flow" ? this.bestOffscreenShardCluster(offscreen) : null;
    if (shardCluster) targets.push(makeTarget("shards", shardCluster.x, shardCluster.y, -960 - shardCluster.score));

    targets.sort((a, b) => a.priority + Math.sqrt(a.distanceSq) - (b.priority + Math.sqrt(b.distanceSq)));
    return targets[0] ?? null;
  }

  private bestOffscreenShardCluster(offscreen: (x: number, y: number) => boolean): { x: number; y: number; score: number } | null {
    const shards = this.state.pickups.filter((pickup) => pickup.kind === "xp" && pickup.value > 0 && offscreen(pickup.x, pickup.y));
    if (shards.length === 0) return null;

    let best: { x: number; y: number; score: number } | null = null;
    const clusterRadiusSq = 210 * 210;
    for (const shard of shards) {
      let weight = 0;
      let weightedX = 0;
      let weightedY = 0;
      let count = 0;
      for (const other of shards) {
        if (distanceSquared(shard.x, shard.y, other.x, other.y) > clusterRadiusSq) continue;
        const value = Math.max(1, other.value);
        weight += value;
        weightedX += other.x * value;
        weightedY += other.y * value;
        count += 1;
      }
      const score = Math.min(720, weight * 26 + count * 22);
      if (!best || score > best.score) best = { x: weightedX / Math.max(1, weight), y: weightedY / Math.max(1, weight), score };
    }
    return best;
  }

  private syncOrbitals() {
    const stats = orbitStats(this.state);
    while (this.orbitSprites.length < stats.count) {
      this.orbitSprites.push(this.add.image(this.state.player.x, this.state.player.y, "orbit-star").setDepth(58));
    }
    while (this.orbitSprites.length > stats.count) {
      this.orbitSprites.pop()?.destroy();
    }

    for (let i = 0; i < this.orbitSprites.length; i += 1) {
      const angle = this.time.now / 380 + (Math.PI * 2 * i) / Math.max(1, this.orbitSprites.length);
      const x = this.state.player.x + Math.cos(angle) * stats.radius;
      const y = this.state.player.y + Math.sin(angle) * stats.radius;
      this.orbitSprites[i]
        .setPosition(x, y)
        .setRotation(angle)
        .setScale(0.72 + this.state.upgrades.orbit * 0.04)
        .setAlpha(0.92);
    }
  }

  private processEvents(events: GameEvent[]) {
    for (const event of events) {
      if (event.type === "attack") this.attackEffect(event.attack, event.x, event.y, event.color, event.targetX, event.targetY, event.radius);
      if (event.type === "hit") this.hitEffect(event.enemy, event.color, event.crit);
      if (event.type === "defeat") this.defeatEffect(event.enemy, event.xp, event.color);
      if (event.type === "pickup") this.pickupEffect(event.pickup);
      if (event.type === "cacheRush") this.cacheRushEffect(event.x, event.y, event.count);
      if (event.type === "combo") this.comboEffect(event.count);
      if (event.type === "flowSave") this.flowSaveEffect(event.x, event.y, event.saved, event.restored);
      if (event.type === "flowBurst") this.flowBurstEffect(event.x, event.y, event.count, event.burst);
      if (event.type === "echoBurst") this.echoBurstEffect(event.x, event.y, event.target, event.burst);
      if (event.type === "bountyStart") this.bountyStartEffect(event.bounty);
      if (event.type === "bountyExpired") this.bountyExpiredEffect(event.bounty, event.x, event.y);
      if (event.type === "bountyComplete") this.bountyCompleteEffect(event.x, event.y, event.kind, event.streak, event.reward);
      if (event.type === "boostScoop") this.boostScoopEffect(event.x, event.y, event.count, event.value, event.perfect, event.cooldownRefund);
      if (event.type === "snapBoost") this.snapBoostEffect(event.x, event.y, event.count);
      if (event.type === "dashThread") this.dashThreadEffect(event.x, event.y, event.count, event.elite, event.cooldownRefund);
      if (event.type === "enemyTell") this.enemyTellEffect(event.enemy);
      if (event.type === "closeCall") this.closeCallEffect(event.x, event.y, event.count, event.elite);
      if (event.type === "clutchBurst") this.clutchBurstEffect(event.x, event.y, event.burst);
      if (event.type === "recoveryDrop") this.recoveryDropEffect(event.x, event.y, event.reason);
      if (event.type === "surge") this.surgeEffect(event.x, event.y, event.burst);
      if (event.type === "levelup") this.levelUpEffect(event.level);
      if (event.type === "reroll") this.rerollEffect(event.remaining);
      if (event.type === "upgrade") this.upgradeEffect(event.choice);
      if (event.type === "evolve") this.evolveEffect(event.choice);
      if (event.type === "hurt") this.hurtEffect(event.x, event.y, event.hp);
      if (event.type === "secondWind") this.secondWindEffect(event.x, event.y);
      if (event.type === "dash") this.dashEffect(event.x, event.y);
      if (event.type === "elite") this.eliteEffect(event.enemy);
      if (event.type === "complete") this.showRunBanner("SURVIVED!", "#70e6a8", () => this.showRunEnd("complete"));
      if (event.type === "gameover") this.showRunBanner("OOPS!", "#ff6584", () => this.showRunEnd("gameover"));
    }
  }

  private attackEffect(attack: AttackKind, x: number, y: number, color: string, targetX?: number, targetY?: number, radius?: number) {
    const tint = hexToNumber(color);
    if (attack === "spark" && targetX !== undefined && targetY !== undefined) {
      this.sparkBeam(x, y, targetX, targetY, tint);
      if (this.time.now - this.lastSparkSoundAt > 85) {
        this.lastSparkSoundAt = this.time.now;
        shootSpark();
      }
      return;
    }

    if (attack === "orbit" && targetX !== undefined && targetY !== undefined) {
      const slash = this.add.line(0, 0, targetX - 24, targetY + 18, targetX + 24, targetY - 18, tint, 0.85).setOrigin(0, 0).setDepth(80).setLineWidth(7, 2);
      this.tweens.add({ targets: slash, alpha: 0, scaleX: 1.4, duration: 180, ease: "Sine.easeOut", onComplete: () => slash.destroy() });
      if (this.time.now - this.lastOrbitSoundAt > 180) {
        this.lastOrbitSoundAt = this.time.now;
        shootMagnet();
      }
      return;
    }

    const ring = this.add.circle(x, y, Math.max(40, radius ?? 120), tint, 0).setDepth(78);
    ring.setStrokeStyle(attack === "flow" ? 11 : 9, tint, attack === "dash" ? 0.78 : attack === "flow" ? 0.72 : 0.64);
    this.tweens.add({
      targets: ring,
      scale: attack === "pulse" ? 1.24 : attack === "flow" ? 1.36 : 1.55,
      alpha: 0,
      duration: attack === "dash" ? 260 : attack === "flow" ? 340 : 430,
      ease: "Sine.easeOut",
      onComplete: () => ring.destroy()
    });
    if (attack === "pulse") shootBubble();
    if (attack === "nova") itemGet();
    if (attack === "surge") blip(1520, 0.14);
    if (attack === "flow") blip(1320, 0.08);
    if (attack === "clutch") blip(1260, 0.07);
  }

  private sparkBeam(x: number, y: number, targetX: number, targetY: number, color: number) {
    const midX = (x + targetX) / 2 + (Math.random() - 0.5) * 55;
    const midY = (y + targetY) / 2 + (Math.random() - 0.5) * 55;
    const beamA = this.add.line(0, 0, x, y, midX, midY, color, 0.92).setOrigin(0, 0).setDepth(82).setLineWidth(5, 2);
    const beamB = this.add.line(0, 0, midX, midY, targetX, targetY, color, 0.92).setOrigin(0, 0).setDepth(82).setLineWidth(5, 2);
    this.tweens.add({ targets: [beamA, beamB], alpha: 0, duration: 140, ease: "Sine.easeOut", onComplete: () => { beamA.destroy(); beamB.destroy(); } });
  }

  private hitEffect(enemy: EnemyState, color: string, crit: boolean) {
    const flash = this.add.image(enemy.x, enemy.y, "hit-pop").setDepth(84).setTint(hexToNumber(color)).setScale(crit ? 1.1 : 0.74);
    this.tweens.add({ targets: flash, scale: crit ? 1.75 : 1.15, alpha: 0, angle: 90, duration: 260, ease: "Sine.easeOut", onComplete: () => flash.destroy() });
    const view = this.enemyViews.get(enemy.id);
    if (view) {
      view.sprite.setTintFill(0xffffff);
      this.time.delayedCall(48, () => {
        if (view.sprite.active) {
          view.sprite.clearTint();
          if (enemy.elite) view.sprite.setTint(0xfff1a8);
        }
      });
    }
    if (crit) this.floatText(enemy.x, enemy.y - enemy.radius - 18, "CRIT!", "#ffd35a", 24, true);
    if (this.time.now - this.lastHitSoundAt > 80) {
      this.lastHitSoundAt = this.time.now;
      hit();
    }
  }

  private defeatEffect(enemy: EnemyState, xp: number, color: string) {
    const tint = hexToNumber(color);
    const burst = this.add.image(enemy.x, enemy.y, "blast-burst").setDepth(86).setTint(tint).setScale(enemy.elite ? 1.2 : 0.62);
    this.tweens.add({ targets: burst, scale: enemy.elite ? 3.2 : 1.8, alpha: 0, angle: 160, duration: enemy.elite ? 760 : 420, ease: "Sine.easeOut", onComplete: () => burst.destroy() });

    const pieces = enemy.elite ? 18 : 7;
    for (let i = 0; i < pieces; i += 1) {
      const angle = (Math.PI * 2 * i) / pieces + Math.random() * 0.35;
      const distance = (enemy.elite ? 150 : 82) + Math.random() * 70;
      const chip = this.add.rectangle(enemy.x, enemy.y, 8 + Math.random() * 10, 5 + Math.random() * 8, tint, 0.95).setDepth(85).setRotation(angle);
      this.tweens.add({
        targets: chip,
        x: enemy.x + Math.cos(angle) * distance,
        y: enemy.y + Math.sin(angle) * distance,
        rotation: angle + Math.PI * 2,
        alpha: 0,
        duration: enemy.elite ? 760 : 430,
        ease: "Quad.easeOut",
        onComplete: () => chip.destroy()
      });
    }

    this.floatText(enemy.x, enemy.y - enemy.radius - 22, `+${xp}`, "#70e6a8", enemy.elite ? 34 : 20, true);
    if (enemy.elite) {
      this.hitImpact(120, 0.4, "#ffd35a", 0.11);
      bossExplode();
      this.cameras.main.shake(220, 0.015);
    } else if (this.state.kills % 8 === 0) {
      explode();
      this.cameras.main.shake(80, 0.004);
    }
  }

  private pickupEffect(pickup: PickupState) {
    if (pickup.kind === "cache") {
      itemGet();
      this.showBannerText("CACHE!", "#ffd35a");
      return;
    }
    if (pickup.kind === "heart") {
      blip(520, 0.12);
      this.floatText(pickup.x, pickup.y - 28, "+HEART", "#ff6584", 22, true);
      return;
    }
    if (this.time.now - this.lastPickupSoundAt > 55) {
      this.lastPickupSoundAt = this.time.now;
      const pitch = 820 + Math.min(720, this.state.combo.count * 24) + Math.random() * 120;
      blip(pitch, 0.04);
    }
  }

  private cacheRushEffect(x: number, y: number, count: number) {
    this.hitImpact(82, 0.58, "#ffd35a", 0.08);
    const halo = this.add.circle(x, y, 62, 0xffd35a, 0).setDepth(94);
    halo.setStrokeStyle(11, 0xffd35a, 0.82);
    const inner = this.add.circle(x, y, 28, 0xffffff, 0.3).setDepth(93);
    this.tweens.add({ targets: halo, scale: 2.35, alpha: 0, duration: 540, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.tweens.add({ targets: inner, scale: 2.45, alpha: 0, duration: 340, ease: "Quad.easeOut", onComplete: () => inner.destroy() });
    this.floatText(x, y - 90, count % 3 === 0 ? `CACHE x${count}` : "CACHE RUSH", "#ffd35a", count % 3 === 0 ? 25 : 22, true);
    this.floatText(x, y - 118, "SURGE + BOOST", "#fff7df", 16, true);
    blip(1540 + Math.min(220, count * 16), 0.095);
    this.cameras.main.shake(120, 0.006);
  }

  private comboEffect(count: number) {
    this.floatText(this.state.player.x, this.state.player.y - 82, `${count >= 18 ? "RUSH" : "FLOW"} ${count}x`, count >= 24 ? "#ffd35a" : "#70e6a8", 26, true);
    blip(1040 + Math.min(520, count * 9), 0.075);
    this.cameras.main.shake(count >= 24 ? 90 : 55, count >= 24 ? 0.005 : 0.003);
  }

  private flowSaveEffect(x: number, y: number, saved: number, restored: number) {
    const player = this.state.player;
    this.hitImpact(74, 0.56, "#59dbff", 0.08);
    this.showBannerText("FLOW SAVED!", "#59dbff");
    const line = this.add.line(0, 0, x, y, player.x, player.y, 0x59dbff, 0.74).setOrigin(0, 0).setDepth(90).setLineWidth(9, 2);
    const halo = this.add.circle(player.x, player.y, 58, 0x59dbff, 0).setDepth(94);
    halo.setStrokeStyle(11, 0xffd35a, 0.78);
    this.tweens.add({ targets: line, alpha: 0, scaleX: 1.08, duration: 260, ease: "Sine.easeOut", onComplete: () => line.destroy() });
    this.tweens.add({ targets: halo, scale: 2.2, alpha: 0, duration: 460, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.floatText(player.x, player.y - 94, `${restored}x SAVED`, "#fff7df", 25, true);
    this.floatText(player.x, player.y - 124, `FROM ${saved}x`, "#ffd35a", 17, true);
    blip(1280 + Math.min(260, restored * 7), 0.085);
    this.cameras.main.shake(95, 0.0055);
  }

  private flowBurstEffect(x: number, y: number, count: number, burst: number) {
    this.hitImpact(92, 0.56, "#70e6a8", 0.08);
    this.showBannerText("FLOW BURST!", "#70e6a8");
    const tint = 0x70e6a8;
    const halo = this.add.circle(x, y, 72, tint, 0).setDepth(94);
    halo.setStrokeStyle(12, tint, 0.78);
    this.tweens.add({ targets: halo, scale: 2.35, alpha: 0, duration: 520, ease: "Sine.easeOut", onComplete: () => halo.destroy() });

    for (let i = 0; i < 14; i += 1) {
      const angle = (Math.PI * 2 * i) / 14 + Math.random() * 0.2;
      const spark = this.add.rectangle(x, y, 20, 5, i % 3 === 0 ? 0xffd35a : tint, 0.9).setDepth(95).setRotation(angle);
      this.tweens.add({
        targets: spark,
        x: x + Math.cos(angle) * (112 + Math.random() * 54),
        y: y + Math.sin(angle) * (112 + Math.random() * 54),
        scaleX: 0.15,
        alpha: 0,
        duration: 420,
        ease: "Quad.easeOut",
        onComplete: () => spark.destroy()
      });
    }

    this.floatText(x, y - 112, `${count}x BURST ${burst}`, "#fff7df", 25, true);
    blip(1380 + Math.min(260, burst * 24), 0.11);
    this.cameras.main.shake(145, 0.008);
  }

  private echoBurstEffect(x: number, y: number, target: number, burst: number) {
    this.hitImpact(96, 0.54, "#b78cff", 0.09);
    this.showBannerText("ECHO RUSH!", "#b78cff");
    const halo = this.add.circle(x, y, 68, 0xb78cff, 0).setDepth(94);
    halo.setStrokeStyle(11, 0xb78cff, 0.78);
    const gold = this.add.circle(x, y, 38, 0xffd35a, 0.24).setDepth(93);
    this.tweens.add({ targets: halo, scale: 2.55, alpha: 0, duration: 560, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.tweens.add({ targets: gold, scale: 2.15, alpha: 0, duration: 360, ease: "Quad.easeOut", onComplete: () => gold.destroy() });

    for (let i = 0; i < 12; i += 1) {
      const angle = (Math.PI * 2 * i) / 12 + Math.random() * 0.24;
      const spark = this.add.rectangle(x, y, 16, 5, i % 2 === 0 ? 0xb78cff : 0xffd35a, 0.9).setDepth(95).setRotation(angle);
      this.tweens.add({
        targets: spark,
        x: x + Math.cos(angle) * (88 + Math.random() * 48),
        y: y + Math.sin(angle) * (88 + Math.random() * 48),
        scaleX: 0.14,
        alpha: 0,
        duration: 380,
        ease: "Quad.easeOut",
        onComplete: () => spark.destroy()
      });
    }

    this.floatText(x, y - 104, `ECHO ${target}/${target}`, "#fff7df", 24, true);
    this.floatText(x, y - 132, `RUSH ${burst}`, "#ffd35a", 18, true);
    blip(1460 + Math.min(260, burst * 24), 0.105);
    this.cameras.main.shake(130, 0.007);
  }

  private bountyStartEffect(bounty: BountyState) {
    const color = bounty.kind === "thread" ? "#59dbff" : bounty.kind === "sweep" || bounty.kind === "flow" ? "#70e6a8" : "#ffd35a";
    const tint = hexToNumber(color);
    const x = this.state.player.x;
    const y = this.state.player.y;
    const ring = this.add.circle(x, y, 62, tint, 0).setDepth(90);
    ring.setStrokeStyle(8, tint, 0.64);
    this.tweens.add({ targets: ring, scale: 2.05, alpha: 0, duration: 520, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.floatText(x, y - 98, bounty.title.toUpperCase(), color, 20, true);
    this.showBannerText("BOUNTY", color);
    blip(980, 0.06);
  }

  private bountyExpiredEffect(bounty: BountyState, x: number, y: number) {
    const ring = this.add.circle(x, y, 48, 0xffffff, 0).setDepth(88);
    ring.setStrokeStyle(5, 0xffffff, 0.34);
    this.tweens.add({ targets: ring, scale: 1.55, alpha: 0, duration: 340, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.floatText(x, y - 84, `${bounty.title} faded`, "#fff7df", 16, false);
    blip(460, 0.04);
  }

  private bountyCompleteEffect(x: number, y: number, kind: BountyKind, streak: number, reward: number) {
    const color = kind === "thread" ? "#59dbff" : kind === "sweep" || kind === "flow" ? "#70e6a8" : "#ffd35a";
    const tint = hexToNumber(color);
    this.hitImpact(streak >= 3 ? 150 : 105, streak >= 3 ? 0.36 : 0.5, color, streak >= 3 ? 0.13 : 0.09);
    this.showBannerText(streak >= 3 ? `BOUNTY x${streak}!` : "BOUNTY!", color);
    const halo = this.add.circle(x, y, 74, tint, 0).setDepth(96);
    halo.setStrokeStyle(streak >= 3 ? 15 : 11, tint, 0.82);
    const core = this.add.circle(x, y, 32, 0xffffff, 0.28).setDepth(95);
    this.tweens.add({ targets: halo, scale: streak >= 3 ? 2.8 : 2.25, alpha: 0, duration: streak >= 3 ? 680 : 520, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.tweens.add({ targets: core, scale: 2.35, alpha: 0, duration: 330, ease: "Quad.easeOut", onComplete: () => core.destroy() });
    for (let i = 0; i < 12; i += 1) {
      const angle = (Math.PI * 2 * i) / 12 + Math.random() * 0.25;
      const spark = this.add.rectangle(x, y, 16, 5, i % 2 === 0 ? tint : 0xffd35a, 0.92).setDepth(97).setRotation(angle);
      this.tweens.add({
        targets: spark,
        x: x + Math.cos(angle) * (86 + Math.random() * 54),
        y: y + Math.sin(angle) * (86 + Math.random() * 54),
        scaleX: 0.16,
        alpha: 0,
        duration: 420,
        ease: "Quad.easeOut",
        onComplete: () => spark.destroy()
      });
    }
    this.floatText(x, y - 108, `+${reward}`, "#fff7df", 25, true);
    this.floatText(x, y - 138, "SURGE + ECHO", "#ffd35a", 17, true);
    if (streak >= 3) fanfare();
    else itemGet();
    blip(1360 + Math.min(280, streak * 34), streak >= 3 ? 0.12 : 0.085);
    this.cameras.main.shake(streak >= 3 ? 190 : 110, streak >= 3 ? 0.011 : 0.006);
  }

  private closeCallEffect(x: number, y: number, count: number, elite: boolean) {
    const color = elite ? "#ffd35a" : "#59dbff";
    const ring = this.add.circle(x, y, elite ? 70 : 52, hexToNumber(color), 0).setDepth(93);
    ring.setStrokeStyle(elite ? 9 : 7, hexToNumber(color), elite ? 0.8 : 0.62);
    this.tweens.add({ targets: ring, scale: elite ? 1.65 : 1.35, alpha: 0, duration: 300, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.floatText(x, y - 78, count % 5 === 0 ? `CLOSE x${count}` : "CLOSE!", color, elite ? 28 : 22, true);
    blip(elite ? 1320 : 1180, elite ? 0.1 : 0.07);
    this.cameras.main.shake(elite ? 90 : 45, elite ? 0.005 : 0.0025);
  }

  private clutchBurstEffect(x: number, y: number, burst: number) {
    this.hitImpact(112, 0.42, "#59dbff", 0.1);
    this.showBannerText(burst % 3 === 0 ? `CLUTCH x${burst}!` : "CLUTCH!", "#59dbff");
    const halo = this.add.circle(x, y, 62, 0x59dbff, 0).setDepth(94);
    halo.setStrokeStyle(12, 0x59dbff, 0.82);
    const core = this.add.circle(x, y, 28, 0xffffff, 0.3).setDepth(93);
    this.tweens.add({ targets: halo, scale: 2.55, alpha: 0, duration: 560, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.tweens.add({ targets: core, scale: 2.15, alpha: 0, duration: 320, ease: "Quad.easeOut", onComplete: () => core.destroy() });
    for (let i = 0; i < 8; i += 1) {
      const angle = (Math.PI * 2 * i) / 8 + Math.random() * 0.22;
      const spark = this.add.rectangle(x, y, 14, 5, i % 2 === 0 ? 0x59dbff : 0xffffff, 0.9).setDepth(95).setRotation(angle);
      this.tweens.add({
        targets: spark,
        x: x + Math.cos(angle) * (74 + Math.random() * 40),
        y: y + Math.sin(angle) * (74 + Math.random() * 40),
        scaleX: 0.16,
        alpha: 0,
        duration: 340,
        ease: "Quad.easeOut",
        onComplete: () => spark.destroy()
      });
    }
    this.floatText(x, y - 104, "BOOST COOLED", "#fff7df", 18, true);
    blip(1360 + Math.min(260, burst * 22), 0.09);
    this.cameras.main.shake(125, 0.007);
  }

  private recoveryDropEffect(x: number, y: number, reason: "clutch" | "secondWind") {
    const color = reason === "secondWind" ? "#ffd35a" : "#59dbff";
    const tint = hexToNumber(color);
    const ring = this.add.circle(x, y, 44, tint, 0).setDepth(96);
    ring.setStrokeStyle(8, tint, 0.76);
    const pulse = this.add.circle(x, y, 22, 0xffffff, 0.24).setDepth(95);
    this.tweens.add({ targets: ring, scale: 2.15, alpha: 0, duration: 560, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.tweens.add({ targets: pulse, scale: 2.4, alpha: 0, duration: 360, ease: "Quad.easeOut", onComplete: () => pulse.destroy() });
    this.floatText(x, y - 64, "RECOVERY", color, 19, true);
    blip(reason === "secondWind" ? 1120 : 980, 0.075);
  }

  private surgeEffect(x: number, y: number, burst: number) {
    this.hitImpact(165, 0.34, "#ffd35a", 0.14);
    this.showBannerText("SURGE BURST!", "#ffd35a");
    const halo = this.add.circle(x, y, 84, 0xffd35a, 0).setDepth(94);
    halo.setStrokeStyle(14, 0xffd35a, 0.82);
    const core = this.add.circle(x, y, 42, 0xffffff, 0.34).setDepth(93);
    this.tweens.add({ targets: halo, scale: 3.2, alpha: 0, duration: 760, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
    this.tweens.add({ targets: core, scale: 2.4, alpha: 0, duration: 420, ease: "Quad.easeOut", onComplete: () => core.destroy() });
    this.floatText(x, y - 118, `BURST ${burst}`, "#fff7df", 25, true);
    fanfare();
    this.cameras.main.shake(240, 0.015);
  }

  private levelUpEffect(level: number) {
    this.hitImpact(76, 0.62, "#ffd35a", 0.07);
    this.showBannerText(`LEVEL ${level}!`, "#ffd35a");
    itemGet();
    if (!this.choicesOpen) {
      this.choicesOpen = true;
      this.showChoiceDialog();
    }
  }

  private showChoiceDialog() {
    this.hud.showLevelChoices(this.state, (id) => this.pickChoiceById(id), () => this.rerollChoices());
  }

  private rerollEffect(remaining: number) {
    const x = this.state.player.x;
    const y = this.state.player.y;
    const ring = this.add.circle(x, y, 82, 0xffd35a, 0).setDepth(96);
    ring.setStrokeStyle(11, 0xffd35a, 0.74);
    this.tweens.add({ targets: ring, scale: 2.1, alpha: 0, duration: 420, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.floatText(x, y - 92, remaining > 0 ? `REROLL x${remaining}` : "NEW SPREAD", "#ffd35a", 24, true);
    blip(1180, 0.1);
  }

  private upgradeEffect(choice: UpgradeChoice) {
    this.choicesOpen = false;
    const color = choice.color;
    const rarityPower = choice.rarity === "epic" ? 1.85 : choice.rarity === "rare" ? 1.25 : choice.rarity === "uncommon" ? 0.55 : 0;
    const ring = this.add.circle(this.state.player.x, this.state.player.y, 120, hexToNumber(color), 0).setDepth(92);
    ring.setStrokeStyle(12 + rarityPower * 3, hexToNumber(color), 0.72);
    this.tweens.add({ targets: ring, scale: 1.9 + rarityPower * 0.28, alpha: 0, duration: 520 + rarityPower * 90, ease: "Sine.easeOut", onComplete: () => ring.destroy() });

    if (rarityPower > 0) {
      this.hitImpact(choice.rarity === "epic" ? 140 : 98, choice.rarity === "epic" ? 0.34 : 0.5, color, choice.rarity === "epic" ? 0.13 : 0.09);
      const halo = this.add.circle(this.state.player.x, this.state.player.y, 76, 0xffffff, 0).setDepth(91);
      halo.setStrokeStyle(choice.rarity === "epic" ? 10 : 7, hexToNumber(color), choice.rarity === "epic" ? 0.82 : 0.64);
      this.tweens.add({ targets: halo, scale: choice.rarity === "epic" ? 3.2 : 2.55, alpha: 0, duration: choice.rarity === "epic" ? 780 : 620, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
      this.showBannerText(`${choice.rarity.toUpperCase()} SURGE!`, color);
      this.cameras.main.shake(choice.rarity === "epic" ? 230 : 145, choice.rarity === "epic" ? 0.014 : 0.008);
    }

    this.floatText(
      this.state.player.x,
      this.state.player.y - 96,
      choice.rankGain > 1 ? `+${choice.rankGain} RANKS` : "POWER UP",
      color,
      rarityPower > 0 ? 32 : 28,
      true
    );
    this.floatText(this.state.player.x, this.state.player.y - 126, choice.title.toUpperCase(), color, choice.rarity === "epic" ? 24 : 19, true);
    if (choice.rarity === "epic") fanfare();
    else blip(choice.rarity === "rare" ? 1420 : 1120, choice.rarity === "rare" ? 0.13 : 0.11);
  }

  private evolveEffect(choice: UpgradeChoice) {
    const x = this.state.player.x;
    const y = this.state.player.y;
    const color = choice.color;
    this.hitImpact(180, 0.3, color, 0.14);
    this.showBannerText("EVOLVED!", color);
    const ring = this.add.circle(x, y, 92, hexToNumber(color), 0).setDepth(97);
    ring.setStrokeStyle(18, hexToNumber(color), 0.92);
    const white = this.add.circle(x, y, 48, 0xffffff, 0.32).setDepth(96);
    this.tweens.add({ targets: ring, scale: 3.35, alpha: 0, duration: 860, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.tweens.add({ targets: white, scale: 2.65, alpha: 0, duration: 500, ease: "Quad.easeOut", onComplete: () => white.destroy() });
    this.floatText(x, y - 132, choice.title.toUpperCase(), color, 26, true);
    fanfare();
    this.cameras.main.shake(260, 0.016);
  }

  private hurtEffect(x: number, y: number, hp: number) {
    shieldHit();
    this.cameras.main.shake(140, 0.009);
    this.floatText(x, y - 56, hp <= 0 ? "DONE!" : "BUMP!", "#ff6584", 30, true);
    const flash = this.add.rectangle(WORLD_WIDTH / 2, WORLD_HEIGHT / 2, WORLD_WIDTH, WORLD_HEIGHT, 0xff3d64, 0.13).setDepth(91);
    this.tweens.add({ targets: flash, alpha: 0, duration: 230, ease: "Sine.easeOut", onComplete: () => flash.destroy() });
  }

  private secondWindEffect(x: number, y: number) {
    this.hitImpact(175, 0.34, "#fff7df", 0.14);
    this.showBannerText("SECOND WIND!", "#fff7df");
    const ring = this.add.circle(x, y, 96, 0xffd35a, 0).setDepth(96);
    ring.setStrokeStyle(16, 0xffd35a, 0.92);
    const inner = this.add.circle(x, y, 46, 0xffffff, 0.38).setDepth(95);
    const flash = this.add.rectangle(WORLD_WIDTH / 2, WORLD_HEIGHT / 2, WORLD_WIDTH, WORLD_HEIGHT, 0xffffff, 0.18).setDepth(94);
    this.tweens.add({ targets: ring, scale: 3.55, alpha: 0, duration: 820, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.tweens.add({ targets: inner, scale: 2.7, alpha: 0, duration: 480, ease: "Quad.easeOut", onComplete: () => inner.destroy() });
    this.tweens.add({ targets: flash, alpha: 0, duration: 280, ease: "Sine.easeOut", onComplete: () => flash.destroy() });
    this.floatText(x, y - 116, "ONE MORE CHANCE", "#ffd35a", 26, true);
    fanfare();
    this.cameras.main.shake(280, 0.018);
  }

  private dashEffect(x: number, y: number) {
    blip(720, 0.08);
    const afterImage = this.add.image(x, y, "hero-core").setDepth(52).setAlpha(0.36).setTint(0xffffff);
    this.tweens.add({ targets: afterImage, alpha: 0, scale: 1.8, duration: 260, ease: "Sine.easeOut", onComplete: () => afterImage.destroy() });
  }

  private snapBoostEffect(x: number, y: number, count: number) {
    const ring = this.add.circle(x, y, 58, 0xffd35a, 0).setDepth(93);
    ring.setStrokeStyle(9, 0xffd35a, 0.78);
    const inner = this.add.circle(x, y, 22, 0xffffff, 0.28).setDepth(92);
    this.tweens.add({ targets: ring, scale: 2.05, alpha: 0, duration: 330, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    this.tweens.add({ targets: inner, scale: 2.8, alpha: 0, duration: 230, ease: "Quad.easeOut", onComplete: () => inner.destroy() });
    this.floatText(x, y - 86, count % 5 === 0 ? `SNAP x${count}` : "SNAP BOOST", "#ffd35a", count % 5 === 0 ? 25 : 21, true);
    blip(1220 + Math.min(260, count * 18), 0.075);
    this.cameras.main.shake(62, 0.0035);
  }

  private dashThreadEffect(x: number, y: number, count: number, elite: boolean, cooldownRefund: number) {
    const chain = cooldownRefund > 0;
    const color = elite ? "#ffd35a" : chain ? "#59dbff" : "#ffffff";
    const tint = hexToNumber(color);
    const player = this.state.player;
    const line = this.add.line(0, 0, player.x, player.y, x, y, tint, chain ? 0.72 : 0.5).setOrigin(0, 0).setDepth(88).setLineWidth(chain ? 8 : 5, 1);
    this.tweens.add({ targets: line, alpha: 0, duration: chain ? 190 : 130, ease: "Sine.easeOut", onComplete: () => line.destroy() });

    const ring = this.add.circle(x, y, elite ? 42 : 32, tint, 0).setDepth(89);
    ring.setStrokeStyle(chain ? 8 : 5, tint, chain ? 0.72 : 0.48);
    this.tweens.add({ targets: ring, scale: chain ? 1.85 : 1.45, alpha: 0, duration: chain ? 300 : 210, ease: "Sine.easeOut", onComplete: () => ring.destroy() });

    if (chain || elite) {
      this.floatText(player.x, player.y - 92, `THREAD x${count}`, color, chain ? 24 : 20, true);
      if (cooldownRefund > 0) this.floatText(player.x, player.y - 118, `BOOST -${cooldownRefund.toFixed(1)}s`, "#ffd35a", 17, true);
      blip(elite ? 1480 : 1260 + Math.min(220, count * 30), elite ? 0.1 : 0.075);
      this.cameras.main.shake(elite ? 95 : 55, elite ? 0.006 : 0.0035);
    }
  }

  private boostScoopEffect(x: number, y: number, count: number, value: number, perfect: boolean, cooldownRefund: number) {
    const player = this.state.player;
    const tint = perfect ? 0xffffff : count >= 3 ? 0xffd35a : 0x70e6a8;
    const line = this.add.line(0, 0, x, y, player.x, player.y, tint, perfect ? 0.82 : 0.58).setOrigin(0, 0).setDepth(73).setLineWidth(perfect ? 10 : count >= 3 ? 7 : 5, 1);
    this.tweens.add({ targets: line, alpha: 0, duration: 180, ease: "Sine.easeOut", onComplete: () => line.destroy() });

    if (perfect) {
      const halo = this.add.circle(player.x, player.y, 66, 0xffffff, 0).setDepth(94);
      halo.setStrokeStyle(11, 0xffd35a, 0.86);
      this.tweens.add({ targets: halo, scale: 2.15, alpha: 0, duration: 430, ease: "Sine.easeOut", onComplete: () => halo.destroy() });
      for (let i = 0; i < 10; i += 1) {
        const angle = (Math.PI * 2 * i) / 10 + Math.random() * 0.2;
        const spark = this.add.rectangle(player.x, player.y, 18, 4, i % 2 === 0 ? 0xffffff : 0xffd35a, 0.9).setDepth(95).setRotation(angle);
        this.tweens.add({
          targets: spark,
          x: player.x + Math.cos(angle) * (70 + Math.random() * 44),
          y: player.y + Math.sin(angle) * (70 + Math.random() * 44),
          scaleX: 0.18,
          alpha: 0,
          duration: 300,
          ease: "Quad.easeOut",
          onComplete: () => spark.destroy()
        });
      }
      this.floatText(player.x, player.y - 92, `PERFECT x${count}`, "#fff7df", 27, true);
      this.floatText(player.x, player.y - 122, `BOOST -${cooldownRefund.toFixed(1)}s`, "#ffd35a", 18, true);
      blip(1480 + Math.min(280, count * 9), 0.11);
      this.cameras.main.shake(105, 0.006);
      return;
    }

    if (count >= 2) {
      const label = count >= 4 ? `SCOOP x${count}` : "SCOOP";
      this.floatText(player.x, player.y - 74, label, count >= 4 ? "#ffd35a" : "#70e6a8", count >= 4 ? 24 : 20, true);
      blip(980 + Math.min(420, count * 55 + value * 4), count >= 4 ? 0.08 : 0.055);
      this.cameras.main.shake(count >= 4 ? 70 : 36, count >= 4 ? 0.004 : 0.002);
    }
  }

  private enemyTellEffect(enemy: EnemyState) {
    const color = enemy.elite ? "#ffd35a" : "#ff6584";
    const ring = this.add.circle(enemy.x, enemy.y, enemy.radius + 22, hexToNumber(color), 0).setDepth(92);
    ring.setStrokeStyle(enemy.elite ? 8 : 6, hexToNumber(color), enemy.elite ? 0.72 : 0.58);
    this.tweens.add({ targets: ring, scale: 1.58, alpha: 0, duration: 360, ease: "Sine.easeOut", onComplete: () => ring.destroy() });
    blip(enemy.elite ? 820 : 680, enemy.elite ? 0.09 : 0.065);
  }

  private eliteEffect(enemy: EnemyState) {
    bossRumble();
    this.cameras.main.shake(140, 0.006);
    this.showBannerText("BIG SHAPE!", enemyColor(enemy.kind));
  }

  private pickChoice(index: number) {
    const choice = this.state.choices[index];
    if (!choice) return;
    this.pickChoiceById(choice.id);
  }

  private pickChoiceById(id: UpgradeId) {
    const events = chooseUpgrade(this.state, id);
    if (events.length === 0) return;
    this.hud.hideLevelChoices();
    this.choicesOpen = false;
    this.processEvents(events);
    this.hud.setState(this.state);
  }

  private rerollChoices() {
    const events = rerollUpgradeChoices(this.state);
    if (events.length === 0) return;
    this.processEvents(events);
    this.showChoiceDialog();
    this.hud.setState(this.state);
  }

  private showRunBanner(text: string, color: string, onDone: () => void) {
    if (this.endShown) return;
    this.endShown = true;
    this.scenePhase = "ended";
    this.hud.hideLevelChoices();
    if (text === "SURVIVED!") fanfare();
    const cx = this.cameras.main.scrollX + this.scale.width / 2;
    const cy = this.cameras.main.scrollY + this.scale.height / 2;
    const bg = this.add.rectangle(cx, cy, 680, 148, 0x17121f, 0.88).setDepth(130).setStrokeStyle(6, hexToNumber(color), 1);
    const label = this.add
      .text(cx, cy, text, {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: "78px",
        fontStyle: "bold",
        color,
        stroke: "#17121f",
        strokeThickness: 9
      })
      .setOrigin(0.5)
      .setDepth(131)
      .setScale(0.1);
    this.tweens.add({ targets: [bg, label], scale: 1, duration: 360, ease: "Back.easeOut" });
    this.cameras.main.shake(text === "SURVIVED!" ? 280 : 170, text === "SURVIVED!" ? 0.013 : 0.008);
    this.time.delayedCall(1450, () => {
      this.tweens.add({ targets: [bg, label], alpha: 0, duration: 280, onComplete: () => { bg.destroy(); label.destroy(); onDone(); } });
    });
  }

  private showRunEnd(outcome: "complete" | "gameover") {
    if (outcome === "complete") {
      spawnConfettiBurst(this, [0xff79c6, 0x70e6a8, 0xffd35a, 0xfff7df, 0x6ec8ff], 125);
    }
    this.hud.showRunEnd(this.state, outcome, () => this.scene.restart());
  }

  private showBannerText(text: string, color: string) {
    const cx = this.cameras.main.scrollX + this.scale.width / 2;
    const cy = this.cameras.main.scrollY + this.scale.height * 0.28;
    const label = this.add
      .text(cx, cy, text, {
        fontFamily: "Arial Black, Arial, sans-serif",
        fontSize: "52px",
        fontStyle: "bold",
        color,
        stroke: "#17121f",
        strokeThickness: 8
      })
      .setOrigin(0.5)
      .setDepth(122)
      .setScale(0.2)
      .setAlpha(0);
    this.tweens.add({ targets: label, scale: 1, alpha: 1, duration: 260, ease: "Back.easeOut" });
    this.tweens.add({ targets: label, y: cy - 54, alpha: 0, duration: 560, delay: 900, ease: "Sine.easeIn", onComplete: () => label.destroy() });
  }

  private hitImpact(durationMs: number, scale: number, color = "#fff7df", alpha = 0.12) {
    this.impactSlowTimer = Math.max(this.impactSlowTimer, durationMs / 1000);
    this.impactSlowScale = Math.min(this.impactSlowScale, scale);
    const flash = this.add
      .rectangle(this.scale.width / 2, this.scale.height / 2, this.scale.width, this.scale.height, hexToNumber(color), alpha)
      .setDepth(118)
      .setScrollFactor(0);
    this.tweens.add({ targets: flash, alpha: 0, duration: Math.max(90, durationMs * 1.45), ease: "Sine.easeOut", onComplete: () => flash.destroy() });
  }

  private floatText(x: number, y: number, text: string, color: string, size = 20, bold = false) {
    const label = this.add
      .text(x, y, text, {
        fontFamily: bold ? "Arial Black, Arial, sans-serif" : "Arial, sans-serif",
        fontSize: `${size}px`,
        fontStyle: "bold",
        color,
        stroke: "#17121f",
        strokeThickness: 5
      })
      .setOrigin(0.5)
      .setDepth(95)
      .setScale(0.5);
    this.tweens.add({ targets: label, scale: 1, duration: 140, ease: "Back.easeOut" });
    this.tweens.add({ targets: label, y: y - 48, alpha: 0, duration: 760, delay: 100, ease: "Sine.easeOut", onComplete: () => label.destroy() });
  }

  private exposeDebugState() {
    if (!import.meta.env.DEV) return;
    window.__MISCHIEF_DEBUG__ = { scenePhase: () => this.scenePhase, state: () => this.state, start: () => this.startFromTitle() };
    this.debugNode = document.querySelector<HTMLElement>("#mischief-debug-state") ?? document.createElement("pre");
    this.debugNode.id = "mischief-debug-state";
    this.debugNode.style.display = "none";
    document.body.appendChild(this.debugNode);
    this.updateDebugState();
  }

  private updateDebugState() {
    if (!this.debugNode) return;
    this.debugNode.textContent = JSON.stringify({
      camera: { scrollX: this.cameras.main.scrollX, scrollY: this.cameras.main.scrollY, width: this.cameras.main.width, height: this.cameras.main.height },
      scenePhase: this.scenePhase,
      state: this.state
    });
  }
}

const hexToNumber = (color: string): number => Number.parseInt(color.slice(1), 16);
const distanceSquared = (x1: number, y1: number, x2: number, y2: number): number => {
  const dx = x1 - x2;
  const dy = y1 - y2;
  return dx * dx + dy * dy;
};
