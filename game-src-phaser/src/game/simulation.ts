export type RunPhase = "playing" | "levelup" | "complete" | "gameover";
export type EnemyKind = "nibbler" | "dasher" | "brute" | "warden";
export type PickupKind = "xp" | "cache" | "heart";
export type AttackKind = "spark" | "pulse" | "orbit" | "nova" | "dash" | "surge" | "flow" | "clutch";
export type UpgradeRarity = "common" | "uncommon" | "rare" | "epic";
export type BountyKind = "sweep" | "flow" | "thread" | "cache" | "elite";
export type UpgradeId =
  | "spark"
  | "pulse"
  | "orbit"
  | "magnet"
  | "sprint"
  | "heart"
  | "focus"
  | "jackpot"
  | "nova";

export type InputState = { x: number; y: number; action: boolean; restart: boolean };

export type PlayerState = {
  x: number;
  y: number;
  vx: number;
  vy: number;
  facingX: number;
  hp: number;
  maxHp: number;
  invulnerable: number;
  dashCooldown: number;
  dashTimer: number;
  boostBuffer: number;
  boostQueued: boolean;
  level: number;
  xp: number;
  nextXp: number;
  score: number;
};

export type EnemyState = {
  id: string;
  kind: EnemyKind;
  x: number;
  y: number;
  vx: number;
  vy: number;
  radius: number;
  hp: number;
  maxHp: number;
  speed: number;
  damage: number;
  xpValue: number;
  wobble: number;
  chargeWindup: number;
  chargeBurst: number;
  chargeCooldown: number;
  elite: boolean;
};

export type PickupState = {
  id: string;
  kind: PickupKind;
  x: number;
  y: number;
  value: number;
  bob: number;
  scooped: boolean;
};

export type UpgradeChoice = {
  id: UpgradeId;
  title: string;
  description: string;
  rarity: UpgradeRarity;
  color: string;
  rank: number;
  rankGain: number;
  maxRank: number;
};

export type UpgradeRanks = Record<UpgradeId, number>;
export type UpgradeEvolutions = Record<UpgradeId, boolean>;

export type BountyState = {
  kind: BountyKind;
  title: string;
  hint: string;
  progress: number;
  target: number;
  timer: number;
  duration: number;
};

export type GameState = {
  phase: RunPhase;
  elapsed: number;
  runDuration: number;
  player: PlayerState;
  enemies: EnemyState[];
  pickups: PickupState[];
  upgrades: UpgradeRanks;
  evolved: UpgradeEvolutions;
  timers: {
    spawn: number;
    spark: number;
    pulse: number;
    orbit: number;
  };
  director: {
    budget: number;
    nextEliteAt: number;
    wave: number;
  };
  choices: UpgradeChoice[];
  kills: number;
  eliteKills: number;
  cachesOpened: number;
  catalystCaches: number;
  cacheEvolutions: number;
  closeCalls: number;
  closeCallCooldown: number;
  clutch: {
    count: number;
    timer: number;
    best: number;
    bursts: number;
  };
  cacheDropCooldown: number;
  recoveryDropCooldown: number;
  recoveryDrops: number;
  surgeCharge: number;
  surgeBursts: number;
  flowBursts: number;
  boostScoops: number;
  perfectScoops: number;
  snapBoosts: number;
  dashThreads: number;
  bestDashThread: number;
  dashThreadIds: string[];
  rerolls: number;
  rerollsUsed: number;
  powerEcho: number;
  echoCharge: number;
  echoBursts: number;
  bounty: BountyState | null;
  bountyCooldown: number;
  bountiesCleared: number;
  bountyStreak: number;
  bestBountyStreak: number;
  secondWindUsed: boolean;
  combo: {
    count: number;
    timer: number;
    best: number;
    nextBurstAt: number;
  };
  flowSave: {
    count: number;
    timer: number;
    best: number;
    saves: number;
  };
  rarityFinds: Record<UpgradeRarity, number>;
  rarityDryStreak: number;
  message: string;
  messageTimer: number;
};

export type GameEvent =
  | { type: "attack"; attack: AttackKind; x: number; y: number; targetX?: number; targetY?: number; radius?: number; color: string }
  | { type: "hit"; enemy: EnemyState; attack: AttackKind; damage: number; crit: boolean; color: string }
  | { type: "defeat"; enemy: EnemyState; xp: number; color: string }
  | { type: "pickup"; pickup: PickupState; value: number }
  | { type: "cacheRush"; x: number; y: number; count: number }
  | { type: "combo"; count: number }
  | { type: "flowSave"; x: number; y: number; saved: number; restored: number }
  | { type: "flowBurst"; x: number; y: number; count: number; burst: number }
  | { type: "echoBurst"; x: number; y: number; target: number; burst: number }
  | { type: "bountyStart"; bounty: BountyState }
  | { type: "bountyExpired"; bounty: BountyState; x: number; y: number }
  | { type: "bountyComplete"; x: number; y: number; kind: BountyKind; streak: number; reward: number }
  | { type: "boostScoop"; x: number; y: number; count: number; value: number; perfect: boolean; cooldownRefund: number }
  | { type: "snapBoost"; x: number; y: number; count: number }
  | { type: "dashThread"; x: number; y: number; count: number; elite: boolean; cooldownRefund: number }
  | { type: "enemyTell"; enemy: EnemyState }
  | { type: "closeCall"; x: number; y: number; count: number; elite: boolean }
  | { type: "clutchBurst"; x: number; y: number; burst: number }
  | { type: "recoveryDrop"; x: number; y: number; reason: "clutch" | "secondWind" }
  | { type: "surge"; x: number; y: number; burst: number }
  | { type: "levelup"; level: number; choices: UpgradeChoice[] }
  | { type: "reroll"; choices: UpgradeChoice[]; remaining: number }
  | { type: "upgrade"; choice: UpgradeChoice }
  | { type: "evolve"; choice: UpgradeChoice }
  | { type: "hurt"; x: number; y: number; hp: number }
  | { type: "secondWind"; x: number; y: number }
  | { type: "dash"; x: number; y: number }
  | { type: "elite"; enemy: EnemyState }
  | { type: "complete" }
  | { type: "gameover" };

export const WORLD_WIDTH = 2600;
export const WORLD_HEIGHT = 1700;
export const RUN_DURATION = 240;

const START_X = WORLD_WIDTH / 2;
const START_Y = WORLD_HEIGHT / 2;
const MAX_ENEMIES = 122;
const MAX_PICKUPS = 90;
const CONTACT_RADIUS = 18;
const DASH_COOLDOWN = 4.35;
const DASH_TIME = 0.26;
const BOOST_BUFFER_TIME = 0.24;
export const SNAP_BOOST_WINDOW = 0.46;
const BOOST_QUEUE_GRACE = 0.12;
const SURGE_MAX = 100;
export const FLOW_BURST_STEP = 144;
const FLOW_BURST_GROWTH = 42;
const FLOW_SAVE_MIN_COMBO = 18;
const FLOW_SAVE_WINDOW = 1.35;
const FLOW_SAVE_RESTORE = 0.68;
const BOOST_SCOOP_BASE_RADIUS = 92;
const BOOST_SCOOP_SPEED_BONUS = 0.42;
const PERFECT_SCOOP_COUNT = 16;
const DASH_THREAD_RADIUS = 38;
const REROLL_CAP = 2;
const POWER_ECHO_COMMON = 4.6;
const POWER_ECHO_MAX = 9.2;
const ECHO_BURST_BASE = 12;
const ECHO_BURST_GROWTH = 4;
const ECHO_BURST_GROWTH_CAP = 30;
const CLUTCH_CHAIN_WINDOW = 2.55;
const CLUTCH_BURST_TARGET = 5;
const FIRST_BOUNTY_DELAY = 6.2;
const BOUNTY_RESTART_DELAY = 4.2;
export const DASHER_WINDUP_TIME = 0.72;
const DASHER_BURST_TIME = 0.28;
const DASHER_COOLDOWN = 4.15;

type EnemySpec = {
  radius: number;
  hp: number;
  speed: number;
  damage: number;
  xp: number;
  cost: number;
  color: string;
  unlockAt: number;
};

type UpgradeDef = {
  title: string;
  base: string;
  color: string;
  maxRank: number;
  weight: number;
  unlockLevel: number;
};

const ENEMY_SPECS: Record<EnemyKind, EnemySpec> = {
  nibbler: { radius: 22, hp: 1.15, speed: 98, damage: 1, xp: 3, cost: 1.1, color: "#69e6b7", unlockAt: 0 },
  dasher: { radius: 19, hp: 1.05, speed: 166, damage: 1, xp: 4, cost: 1.45, color: "#ff7a7a", unlockAt: 30 },
  brute: { radius: 37, hp: 4.3, speed: 76, damage: 1, xp: 11, cost: 3.4, color: "#ffd35a", unlockAt: 66 },
  warden: { radius: 30, hp: 2.8, speed: 104, damage: 1, xp: 8, cost: 2.35, color: "#83b8ff", unlockAt: 98 }
};

const UPGRADE_DEFS: Record<UpgradeId, UpgradeDef> = {
  spark: {
    title: "Spark Chain",
    base: "Auto-zaps harder. Every few ranks adds another target.",
    color: "#ffd35a",
    maxRank: 8,
    weight: 1.25,
    unlockLevel: 1
  },
  pulse: {
    title: "Bubble Pulse",
    base: "Adds a soft blast around you that pops nearby shapes.",
    color: "#59dbff",
    maxRank: 6,
    weight: 0.96,
    unlockLevel: 2
  },
  orbit: {
    title: "Orbit Stars",
    base: "Summons circling stars that clip enemies close to you.",
    color: "#ff79c6",
    maxRank: 6,
    weight: 0.96,
    unlockLevel: 2
  },
  magnet: {
    title: "Snack Magnet",
    base: "Pulls XP shards from farther away.",
    color: "#70e6a8",
    maxRank: 5,
    weight: 0.88,
    unlockLevel: 1
  },
  sprint: {
    title: "Sneaker Mode",
    base: "Move faster and steer out of tight spots.",
    color: "#ff9d66",
    maxRank: 5,
    weight: 0.84,
    unlockLevel: 1
  },
  heart: {
    title: "Extra Heart",
    base: "Gain max health and heal right now.",
    color: "#ff6584",
    maxRank: 4,
    weight: 0.74,
    unlockLevel: 1
  },
  focus: {
    title: "Quick Fingers",
    base: "All weapons recharge faster.",
    color: "#b78cff",
    maxRank: 5,
    weight: 0.82,
    unlockLevel: 1
  },
  jackpot: {
    title: "Jackpot Sparks",
    base: "More crits, bigger scores, and better cache drops.",
    color: "#ffe66d",
    maxRank: 4,
    weight: 0.24,
    unlockLevel: 5
  },
  nova: {
    title: "Level-Up Nova",
    base: "Every level-up blasts a happy shockwave.",
    color: "#ffffff",
    maxRank: 4,
    weight: 0.26,
    unlockLevel: 6
  }
};

const UPGRADE_IDS = Object.keys(UPGRADE_DEFS) as UpgradeId[];

export const createGameState = (): GameState => ({
  phase: "playing",
  elapsed: 0,
  runDuration: RUN_DURATION,
  player: {
    x: START_X,
    y: START_Y,
    vx: 0,
    vy: 0,
    facingX: 1,
    hp: 7,
    maxHp: 7,
    invulnerable: 0,
    dashCooldown: 0,
    dashTimer: 0,
    boostBuffer: 0,
    boostQueued: false,
    level: 1,
    xp: 0,
    nextXp: nextXpForLevel(1),
    score: 0
  },
  enemies: [],
  pickups: [],
  upgrades: {
    spark: 1,
    pulse: 0,
    orbit: 0,
    magnet: 0,
    sprint: 0,
    heart: 0,
    focus: 0,
    jackpot: 0,
    nova: 0
  },
  evolved: {
    spark: false,
    pulse: false,
    orbit: false,
    magnet: false,
    sprint: false,
    heart: false,
    focus: false,
    jackpot: false,
    nova: false
  },
  timers: {
    spawn: 0,
    spark: 0.3,
    pulse: 1.6,
    orbit: 0.55
  },
  director: {
    budget: 0,
    nextEliteAt: 55,
    wave: 1
  },
  choices: [],
  kills: 0,
  eliteKills: 0,
  cachesOpened: 0,
  catalystCaches: 0,
  cacheEvolutions: 0,
  closeCalls: 0,
  closeCallCooldown: 0,
  clutch: {
    count: 0,
    timer: 0,
    best: 0,
    bursts: 0
  },
  cacheDropCooldown: 0,
  recoveryDropCooldown: 0,
  recoveryDrops: 0,
  surgeCharge: 0,
  surgeBursts: 0,
  flowBursts: 0,
  boostScoops: 0,
  perfectScoops: 0,
  snapBoosts: 0,
  dashThreads: 0,
  bestDashThread: 0,
  dashThreadIds: [],
  rerolls: 1,
  rerollsUsed: 0,
  powerEcho: 0,
  echoCharge: 0,
  echoBursts: 0,
  bounty: null,
  bountyCooldown: FIRST_BOUNTY_DELAY,
  bountiesCleared: 0,
  bountyStreak: 0,
  bestBountyStreak: 0,
  secondWindUsed: false,
  combo: {
    count: 0,
    timer: 0,
    best: 0,
    nextBurstAt: FLOW_BURST_STEP
  },
  flowSave: {
    count: 0,
    timer: 0,
    best: 0,
    saves: 0
  },
  rarityFinds: {
    common: 0,
    uncommon: 0,
    rare: 0,
    epic: 0
  },
  rarityDryStreak: 0,
  message: "Move, dodge, collect shards, pick upgrades.",
  messageTimer: 4.5
});

export const updateGameState = (state: GameState, input: InputState, dt: number): GameEvent[] => {
  if (state.phase !== "playing") return [];

  const events: GameEvent[] = [];
  const safeDt = Math.min(dt, 0.05);
  state.elapsed += safeDt;
  state.messageTimer = Math.max(0, state.messageTimer - safeDt);
  state.player.invulnerable = Math.max(0, state.player.invulnerable - safeDt);
  state.player.dashCooldown = Math.max(0, state.player.dashCooldown - safeDt);
  state.player.dashTimer = Math.max(0, state.player.dashTimer - safeDt);
  state.player.boostBuffer = Math.max(0, state.player.boostBuffer - safeDt);
  if (state.player.boostBuffer <= 0) state.player.boostQueued = false;
  if (state.player.dashTimer <= 0 && state.dashThreadIds.length > 0) state.dashThreadIds = [];
  const hadPowerEcho = state.powerEcho > 0;
  state.powerEcho = Math.max(0, state.powerEcho - safeDt);
  if (hadPowerEcho && state.powerEcho <= 0) state.echoCharge = 0;
  state.closeCallCooldown = Math.max(0, state.closeCallCooldown - safeDt);
  updateClutch(state, safeDt);
  state.cacheDropCooldown = Math.max(0, state.cacheDropCooldown - safeDt);
  state.recoveryDropCooldown = Math.max(0, state.recoveryDropCooldown - safeDt);
  updateBounty(state, safeDt, events);
  updateCombo(state, safeDt);

  updatePlayer(state, input, safeDt, events);
  updateDirector(state, safeDt, events);
  updateEnemies(state, safeDt, events);
  updateWeapons(state, safeDt, events);
  updatePickups(state, safeDt, events);
  state.enemies = state.enemies.filter((enemy) => enemy.hp > 0);

  if (state.elapsed >= state.runDuration) {
    state.phase = "complete";
    state.message = "Four minutes survived. The playground is yours.";
    state.messageTimer = 99;
    events.push({ type: "complete" });
  }

  return events;
};

export const chooseUpgrade = (state: GameState, upgradeId: UpgradeId): GameEvent[] => {
  if (state.phase !== "levelup") return [];
  const choice = state.choices.find((candidate) => candidate.id === upgradeId);
  if (!choice) return [];

  const events: GameEvent[] = [{ type: "upgrade", choice }];
  applyUpgradeChoice(state, choice, events);
  activatePowerEcho(state, choice);
  state.choices = [];
  state.phase = "playing";
  if (!events.some((event) => event.type === "evolve")) {
    state.message = upgradeMessage(choice.id, state.upgrades[choice.id]);
    state.messageTimer = 2.3;
  }

  if (upgradeId === "nova") {
    castNova(state, events, 190 + state.upgrades.nova * 34, 2.2 + state.upgrades.nova * 0.8);
  }

  return events;
};

export const rerollUpgradeChoices = (state: GameState): GameEvent[] => {
  if (state.phase !== "levelup" || state.rerolls <= 0 || state.choices.length === 0) return [];

  state.rerolls -= 1;
  state.rerollsUsed += 1;
  state.choices = rollUpgradeChoices(state, 3, "reroll");
  state.message = "Reroll Spark spent. New power spread.";
  state.messageTimer = 99;

  return [{ type: "reroll", choices: state.choices, remaining: state.rerolls }];
};

export const runProgress = (state: GameState): number => clamp(state.elapsed / state.runDuration, 0, 1);
export const xpProgress = (state: GameState): number => clamp(state.player.xp / state.player.nextXp, 0, 1);
export const timeRemaining = (state: GameState): number => Math.max(0, state.runDuration - state.elapsed);
export const threatProgress = (state: GameState): number => clamp(heatCurve(state) / 1.42, 0, 1);
export const surgeProgress = (state: GameState): number => clamp(state.surgeCharge / SURGE_MAX, 0, 1);
export const surgeReady = (state: GameState): boolean => state.surgeCharge >= SURGE_MAX;
export const powerEchoProgress = (state: GameState): number => clamp(state.powerEcho / POWER_ECHO_MAX, 0, 1);
export const echoBurstTarget = (state: GameState): number =>
  ECHO_BURST_BASE + Math.min(ECHO_BURST_GROWTH_CAP, state.echoBursts * ECHO_BURST_GROWTH) + Math.floor(state.player.level * 0.5);
export const echoBurstProgress = (state: GameState): number => (state.powerEcho > 0 ? clamp(state.echoCharge / echoBurstTarget(state), 0, 1) : 0);
export const bountyProgress = (state: GameState): number => (state.bounty ? clamp(state.bounty.progress / state.bounty.target, 0, 1) : 0);
export const snapBoostWindowProgress = (state: GameState): number => {
  if (state.player.boostQueued) return 1;
  if (state.player.dashTimer > 0 || state.player.dashCooldown <= 0 || state.player.dashCooldown > SNAP_BOOST_WINDOW) return 0;
  return clamp(1 - state.player.dashCooldown / SNAP_BOOST_WINDOW, 0.18, 1);
};
export const flowBurstProgress = (state: GameState): number => {
  if (state.combo.timer <= 0 || state.combo.count <= 0) return 0;
  return clamp(state.combo.count / state.combo.nextBurstAt, 0, 0.999);
};
export const flowSaveProgress = (state: GameState): number =>
  state.flowSave.timer > 0 && state.flowSave.count > 0 ? clamp(state.flowSave.timer / FLOW_SAVE_WINDOW, 0, 1) : 0;
export const flowRush = (state: GameState): number => {
  if (state.combo.timer <= 0 || state.combo.count < 18) return 0;
  return clamp(0.05 + (state.combo.count - 18) / 700, 0.05, 0.14);
};
export const pickupRadius = (state: GameState): number => {
  const firstPickCatchup = state.player.level === 1 && state.elapsed > 22 ? Math.min(120, (state.elapsed - 22) * 12) : 0;
  const flowSavePull = flowSaveProgress(state) > 0 ? 44 : 0;
  return 260 + state.upgrades.magnet * 58 + (state.evolved.magnet ? 110 : 0) + firstPickCatchup + flowRush(state) * 120 + flowSavePull;
};
export const boostScoopRadius = (state: GameState): number => {
  if (state.player.dashTimer <= 0) return 0;
  return BOOST_SCOOP_BASE_RADIUS + state.upgrades.sprint * 10 + (state.evolved.sprint ? 42 : 0) + flowRush(state) * 80;
};
export const enemyColor = (kind: EnemyKind): string => ENEMY_SPECS[kind].color;
export const upgradeColor = (upgradeId: UpgradeId): string => UPGRADE_DEFS[upgradeId].color;
export const upgradeTitle = (upgradeId: UpgradeId): string => UPGRADE_DEFS[upgradeId].title;
export const upgradeMaxRank = (upgradeId: UpgradeId): number => UPGRADE_DEFS[upgradeId].maxRank;
export const evolvedCount = (state: GameState): number => Object.values(state.evolved).filter(Boolean).length;

export const orbitStats = (state: GameState): { count: number; radius: number; color: string } => {
  const rank = state.upgrades.orbit;
  if (rank <= 0) return { count: 0, radius: 0, color: UPGRADE_DEFS.orbit.color };
  return {
    count: 1 + Math.floor((rank + 1) / 2) + (state.evolved.orbit ? 1 : 0),
    radius: 88 + rank * 14 + (state.evolved.orbit ? 18 : 0),
    color: UPGRADE_DEFS.orbit.color
  };
};

export const powerScore = (state: GameState): number => {
  const u = state.upgrades;
  return (
    1 +
    state.player.level * 0.085 +
    u.spark * 0.24 +
    u.pulse * 0.22 +
    u.orbit * 0.24 +
    u.focus * 0.12 +
    u.sprint * 0.06 +
    u.jackpot * 0.12 +
    u.nova * 0.1 +
    evolvedCount(state) * 0.18 +
    state.clutch.bursts * 0.035 +
    (state.powerEcho > 0 ? 0.12 : 0)
  );
};

const updatePlayer = (state: GameState, input: InputState, dt: number, events: GameEvent[]) => {
  const magnitude = Math.hypot(input.x, input.y);
  const dx = magnitude > 0 ? input.x / magnitude : 0;
  const dy = magnitude > 0 ? input.y / magnitude : 0;

  if (input.action) {
    const canQueueBoost = state.player.dashTimer <= 0 && state.player.dashCooldown > 0 && state.player.dashCooldown <= SNAP_BOOST_WINDOW;
    state.player.boostBuffer = Math.max(state.player.boostBuffer, canQueueBoost ? state.player.dashCooldown + BOOST_QUEUE_GRACE : BOOST_BUFFER_TIME);
    state.player.boostQueued = canQueueBoost;
  }

  if (state.player.boostBuffer > 0 && state.player.dashCooldown <= 0 && state.player.dashTimer <= 0) {
    const releaseSurge = surgeReady(state);
    const snapBoost = state.player.boostQueued;
    state.player.boostBuffer = 0;
    state.player.boostQueued = false;
    state.player.dashTimer = DASH_TIME;
    state.player.dashCooldown = DASH_COOLDOWN;
    state.dashThreadIds = [];
    state.player.invulnerable = Math.max(state.player.invulnerable, DASH_TIME + 0.08);
    if (magnitude <= 0.04) {
      state.player.vx = state.player.facingX * 670;
      state.player.vy = 0;
    }
    events.push({ type: "dash", x: state.player.x, y: state.player.y });
    if (snapBoost) {
      state.snapBoosts += 1;
      state.player.score += 140 + state.snapBoosts * 18 + state.upgrades.sprint * 25;
      addSurge(state, 4 + (state.evolved.sprint ? 2 : 0));
      state.message = "Snap Boost! Perfect timing.";
      state.messageTimer = 1.15;
      events.push({ type: "snapBoost", x: state.player.x, y: state.player.y, count: state.snapBoosts });
    }
    castNova(state, events, 96 + state.upgrades.nova * 14, 1.1 + state.upgrades.nova * 0.35, "dash");
    if (releaseSurge) {
      state.surgeCharge = 0;
      state.surgeBursts += 1;
      state.player.score += 720 + state.surgeBursts * 90 + state.upgrades.jackpot * 130;
      const rerollCharged = addReroll(state, 1);
      state.message = rerollCharged ? "Surge Burst! Reroll Spark charged." : "Surge Burst! Boost detonated stored charge.";
      state.messageTimer = 1.8;
      events.push({ type: "surge", x: state.player.x, y: state.player.y, burst: state.surgeBursts });
      castNova(state, events, 228 + state.upgrades.nova * 36, 3.15 + state.upgrades.nova * 0.58, "surge");
    }
  }

  const activeDash = state.player.dashTimer > 0;
  const dashDx = magnitude > 0 ? dx : state.player.facingX;
  const dashDy = magnitude > 0 ? dy : 0;
  const dashBoost = state.player.dashTimer > 0 ? (state.evolved.sprint ? 2.76 : 2.58) : 1;
  const speed = (266 + state.upgrades.sprint * 24 + (state.evolved.sprint ? 34 : 0)) * dashBoost * (1 + flowRush(state) * 0.32);
  const targetVx = activeDash ? dashDx * speed : dx * speed;
  const targetVy = activeDash ? dashDy * speed : dy * speed;
  const response = magnitude > 0 || activeDash ? 23 : 30;
  const blend = 1 - Math.exp(-response * dt);
  state.player.vx = lerp(state.player.vx, targetVx, blend);
  state.player.vy = lerp(state.player.vy, targetVy, blend);
  state.player.x = clamp(state.player.x + state.player.vx * dt, 70, WORLD_WIDTH - 70);
  state.player.y = clamp(state.player.y + state.player.vy * dt, 70, WORLD_HEIGHT - 70);
  if (state.player.x <= 70 || state.player.x >= WORLD_WIDTH - 70) state.player.vx = 0;
  if (state.player.y <= 70 || state.player.y >= WORLD_HEIGHT - 70) state.player.vy = 0;
  if (Math.abs(state.player.vx) > 8) state.player.facingX = state.player.vx > 0 ? 1 : -1;
};

const updateDirector = (state: GameState, dt: number, events: GameEvent[]) => {
  const heat = heatCurve(state);
  const pScore = powerScore(state);
  const latePressure = clamp((state.elapsed - 70) / 145, 0, 1);
  const powerPressure = clamp((pScore - 2.6) * 0.045, 0, 0.2);
  const budgetRate = (0.45 + Math.pow(heat, 1.52) * 9.5 + Math.sqrt(pScore) * 0.54) * (1 + latePressure * 0.15 + powerPressure);
  state.director.budget += budgetRate * dt;

  if (state.elapsed >= state.director.nextEliteAt) {
    spawnEnemy(state, chooseEliteKind(state), true, events);
    state.director.nextEliteAt += 48 - Math.min(20, state.director.wave * 2.6);
    state.director.wave += 1;
  }

  let safety = 0;
  while (state.director.budget >= 1 && state.enemies.length < MAX_ENEMIES && safety < 14) {
    const kind = chooseEnemyKind(state);
    const cost = ENEMY_SPECS[kind].cost;
    if (state.director.budget < cost) break;
    spawnEnemy(state, kind, false, events);
    state.director.budget -= cost;
    safety += 1;
  }
};

const updateEnemies = (state: GameState, dt: number, events: GameEvent[]) => {
  for (const enemy of state.enemies) {
    const toPlayerX = state.player.x - enemy.x;
    const toPlayerY = state.player.y - enemy.y;
    const dist = Math.max(0.001, Math.hypot(toPlayerX, toPlayerY));
    updateEnemyCharge(state, enemy, dt, dist, events);

    const chargeWindup = enemy.kind === "dasher" && enemy.chargeWindup > 0;
    const chargeBurst = enemy.kind === "dasher" && enemy.chargeBurst > 0;
    const wobbleAmount = chargeBurst ? 0.05 : chargeWindup ? 0.1 : enemy.kind === "dasher" ? 0.3 : 0.18;
    const wobble = Math.sin(state.elapsed * 2.6 + enemy.wobble) * wobbleAmount;
    const nx = toPlayerX / dist;
    const ny = toPlayerY / dist;
    const px = -ny * wobble;
    const py = nx * wobble;
    const chaseBurst = chargeBurst ? (enemy.elite ? 1.46 : 1.34) : chargeWindup ? 0.5 : 1;

    enemy.vx = (nx + px) * enemy.speed * chaseBurst;
    enemy.vy = (ny + py) * enemy.speed * chaseBurst;
    enemy.x = clamp(enemy.x + enemy.vx * dt, 40, WORLD_WIDTH - 40);
    enemy.y = clamp(enemy.y + enemy.vy * dt, 40, WORLD_HEIGHT - 40);

    const contactDistance = enemy.radius + CONTACT_RADIUS;
    const hitX = state.player.x - enemy.x;
    const hitY = state.player.y - enemy.y;
    const hitDist = Math.max(0.001, Math.hypot(hitX, hitY));
    const hitNx = hitX / hitDist;
    const hitNy = hitY / hitDist;
    if (state.player.dashTimer > 0 && hitDist <= enemy.radius + DASH_THREAD_RADIUS) {
      triggerDashThread(state, enemy, events);
    }
    if (state.elapsed > 7 && hitDist <= contactDistance && state.player.invulnerable <= 0) {
      state.player.hp = Math.max(0, state.player.hp - enemy.damage);
      state.player.invulnerable = 1.58;
      state.player.vx = hitNx * 330;
      state.player.vy = hitNy * 330;
      enemy.x = clamp(enemy.x - hitNx * 56, 40, WORLD_WIDTH - 40);
      enemy.y = clamp(enemy.y - hitNy * 56, 40, WORLD_HEIGHT - 40);
      state.message = state.player.hp <= 1 ? "Careful. Grab a heart or clear space." : "Bumped. Dash through gaps with Space.";
      state.messageTimer = 2.1;
      events.push({ type: "hurt", x: state.player.x, y: state.player.y, hp: state.player.hp });
      if (state.player.hp <= 0) {
        if (!state.secondWindUsed) {
          triggerSecondWind(state, events);
          return;
        }
        state.phase = "gameover";
        events.push({ type: "gameover" });
        return;
      }
    } else if (
      state.elapsed > 9 &&
      state.closeCallCooldown <= 0 &&
      state.player.invulnerable <= 0 &&
      hitDist > contactDistance + 4 &&
      hitDist <= contactDistance + 34
    ) {
      state.closeCalls += 1;
      state.closeCallCooldown = enemy.elite ? 0.9 : 0.62;
      state.player.dashCooldown = Math.max(0, state.player.dashCooldown - (enemy.elite ? 0.55 : 0.32));
      state.player.score += Math.round(70 + Math.min(240, state.combo.count * 3.2) + (enemy.elite ? 220 : 0));
      if (state.combo.count > 0) state.combo.timer = Math.max(state.combo.timer, 0.9 + Math.min(0.35, state.combo.count * 0.006));
      state.message = state.player.dashCooldown <= 0 ? "Close call! Boost is ready." : "Close call! Boost cooled faster.";
      state.messageTimer = 1.1;
      addSurge(state, enemy.elite ? 20 : 12);
      recordClutch(state, enemy.elite, events);
      events.push({ type: "closeCall", x: state.player.x, y: state.player.y, count: state.closeCalls, elite: enemy.elite });
    }
  }
};

const updateClutch = (state: GameState, dt: number) => {
  if (state.clutch.timer <= 0) return;
  state.clutch.timer = Math.max(0, state.clutch.timer - dt);
  if (state.clutch.timer <= 0) state.clutch.count = 0;
};

const recordClutch = (state: GameState, elite: boolean, events: GameEvent[]) => {
  state.clutch.count = Math.min(CLUTCH_BURST_TARGET, state.clutch.count + (elite ? 2 : 1));
  state.clutch.timer = CLUTCH_CHAIN_WINDOW + Math.min(0.45, state.upgrades.sprint * 0.05);
  state.clutch.best = Math.max(state.clutch.best, state.clutch.count);
  if (state.clutch.count >= clutchBurstTarget(state)) triggerClutchBurst(state, events);
};

const clutchBurstTarget = (state: GameState): number => (state.player.hp <= 2 ? CLUTCH_BURST_TARGET - 1 : CLUTCH_BURST_TARGET);

const triggerClutchBurst = (state: GameState, events: GameEvent[]) => {
  state.clutch.count = 0;
  state.clutch.timer = 0;
  state.clutch.bursts += 1;
  state.player.invulnerable = Math.max(state.player.invulnerable, 0.28);
  state.player.dashCooldown = Math.max(0, state.player.dashCooldown - (0.72 + state.upgrades.sprint * 0.025 + (state.evolved.sprint ? 0.16 : 0)));
  state.player.score += Math.round(430 + state.clutch.bursts * 105 + Math.min(560, state.combo.count * 1.6) + state.upgrades.jackpot * 85);
  addSurge(state, 14 + Math.min(10, state.clutch.bursts + state.upgrades.sprint));
  state.message = state.player.dashCooldown <= 0 ? "Clutch Burst! Boost snapped ready." : "Clutch Burst! Near misses detonated.";
  state.messageTimer = 1.45;
  if (state.player.hp <= 2 && maybeDropRecoveryHeart(state, events, "clutch")) {
    state.message = "Clutch Burst! Recovery heart popped.";
    state.messageTimer = 1.6;
  }
  events.push({ type: "clutchBurst", x: state.player.x, y: state.player.y, burst: state.clutch.bursts });
  castNova(state, events, 132 + state.upgrades.sprint * 8 + Math.min(28, state.clutch.bursts * 2), 0.72 + state.upgrades.jackpot * 0.08, "clutch");
};

const updateEnemyCharge = (state: GameState, enemy: EnemyState, dt: number, dist: number, events: GameEvent[]) => {
  if (enemy.kind !== "dasher") return;

  if (enemy.chargeBurst > 0) {
    enemy.chargeBurst = Math.max(0, enemy.chargeBurst - dt);
    if (enemy.chargeBurst <= 0) enemy.chargeCooldown = DASHER_COOLDOWN + Math.random() * 1.05 + (enemy.elite ? -0.55 : 0);
    return;
  }

  if (enemy.chargeWindup > 0) {
    enemy.chargeWindup = Math.max(0, enemy.chargeWindup - dt);
    if (enemy.chargeWindup <= 0) enemy.chargeBurst = DASHER_BURST_TIME + (enemy.elite ? 0.08 : 0);
    return;
  }

  enemy.chargeCooldown = Math.max(0, enemy.chargeCooldown - dt);
  if (state.elapsed > 8 && enemy.chargeCooldown <= 0 && dist <= 500) {
    enemy.chargeWindup = DASHER_WINDUP_TIME;
    if (enemy.elite || dist <= 380) events.push({ type: "enemyTell", enemy: { ...enemy } });
  }
};

const updateWeapons = (state: GameState, dt: number, events: GameEvent[]) => {
  state.timers.spark -= dt;
  state.timers.pulse -= dt;
  state.timers.orbit -= dt;

  if (state.timers.spark <= 0) {
    const stats = sparkStats(state);
    state.timers.spark += stats.cooldown;
    const targets = nearestEnemies(state, stats.range, stats.targets);
    for (const target of targets) {
      events.push({
        type: "attack",
        attack: "spark",
        x: state.player.x,
        y: state.player.y,
        targetX: target.x,
        targetY: target.y,
        color: UPGRADE_DEFS.spark.color
      });
      dealDamage(state, target, stats.damage, "spark", events, UPGRADE_DEFS.spark.color);
    }
  }

  if (state.upgrades.pulse > 0 && state.timers.pulse <= 0) {
    const stats = pulseStats(state);
    state.timers.pulse += stats.cooldown;
    events.push({
      type: "attack",
      attack: "pulse",
      x: state.player.x,
      y: state.player.y,
      radius: stats.radius,
      color: UPGRADE_DEFS.pulse.color
    });
    for (const enemy of state.enemies) {
      if (distance(state.player.x, state.player.y, enemy.x, enemy.y) <= stats.radius + enemy.radius) {
        knockEnemy(state, enemy, 48);
        dealDamage(state, enemy, stats.damage, "pulse", events, UPGRADE_DEFS.pulse.color);
      }
    }
  }

  if (state.upgrades.orbit > 0 && state.timers.orbit <= 0) {
    const stats = orbitDamageStats(state);
    state.timers.orbit += stats.cooldown;
    const targets = nearestEnemies(state, stats.radius, stats.count);
    for (const target of targets) {
      events.push({
        type: "attack",
        attack: "orbit",
        x: state.player.x,
        y: state.player.y,
        targetX: target.x,
        targetY: target.y,
        color: UPGRADE_DEFS.orbit.color
      });
      dealDamage(state, target, stats.damage, "orbit", events, UPGRADE_DEFS.orbit.color);
    }
  }

  state.enemies = state.enemies.filter((enemy) => enemy.hp > 0);
};

const updatePickups = (state: GameState, dt: number, events: GameEvent[]) => {
  const radius = pickupRadius(state);
  const scoopRadius = boostScoopRadius(state);
  let scoopedCount = 0;
  let scoopedValue = 0;
  let scoopedX = 0;
  let scoopedY = 0;
  for (const pickup of state.pickups) {
    pickup.bob += dt * 4;
    const dist = distance(state.player.x, state.player.y, pickup.x, pickup.y);
    const basePullRadius = pickup.kind === "xp" ? radius : radius + (pickup.kind === "cache" ? 124 : 66);
    const pullRadius = basePullRadius + (pickup.kind === "xp" ? scoopRadius : scoopRadius * 0.35);
    if (
      scoopRadius > 0 &&
      pickup.kind === "xp" &&
      !pickup.scooped &&
      dist > basePullRadius * 0.72 &&
      dist <= pullRadius
    ) {
      pickup.scooped = true;
      scoopedCount += 1;
      scoopedValue += pickup.value;
      scoopedX += pickup.x;
      scoopedY += pickup.y;
    }
    if (dist <= pullRadius) {
      const speed = (pickup.kind === "xp" ? 520 : pickup.kind === "cache" ? 560 : 450) * (pickup.scooped ? 1 + BOOST_SCOOP_SPEED_BONUS : scoopRadius > 0 ? 1.14 : 1);
      const nx = (state.player.x - pickup.x) / Math.max(0.001, dist);
      const ny = (state.player.y - pickup.y) / Math.max(0.001, dist);
      pickup.x += nx * speed * dt * (1 + (1 - dist / pullRadius) * 1.2);
      pickup.y += ny * speed * dt * (1 + (1 - dist / pullRadius) * 1.2);
    }

    if (distance(state.player.x, state.player.y, pickup.x, pickup.y) <= 34) {
      collectPickup(state, pickup, events);
      pickup.value = -1;
    }
  }

  if (scoopedCount > 0) {
    state.boostScoops += scoopedCount;
    state.player.score += Math.round(scoopedCount * 18 + scoopedValue * (4 + state.upgrades.jackpot));
    if (scoopedCount >= 2) addSurge(state, Math.min(5, 1 + Math.floor(scoopedCount / 2)));
    const perfect = scoopedCount >= PERFECT_SCOOP_COUNT;
    let cooldownRefund = 0;
    if (perfect) {
      state.perfectScoops += 1;
      cooldownRefund = perfectScoopRefund(state, scoopedCount);
      state.player.dashCooldown = Math.max(0, state.player.dashCooldown - cooldownRefund);
      state.player.score += Math.round(260 + scoopedCount * 34 + scoopedValue * (1.7 + state.upgrades.jackpot * 0.25));
      addSurge(state, Math.min(12, 6 + Math.floor(scoopedCount / 8)));
      state.message = state.player.dashCooldown <= 0 ? "Perfect Scoop! Boost snapped ready." : "Perfect Scoop! Boost cooled faster.";
      state.messageTimer = 1.45;
    }
    events.push({
      type: "boostScoop",
      x: scoopedX / scoopedCount,
      y: scoopedY / scoopedCount,
      count: scoopedCount,
      value: scoopedValue,
      perfect,
      cooldownRefund
    });
  }

  state.pickups = state.pickups.filter((pickup) => pickup.value >= 0).slice(-MAX_PICKUPS);
};

const collectPickup = (state: GameState, pickup: PickupState, events: GameEvent[]) => {
  events.push({ type: "pickup", pickup: { ...pickup }, value: pickup.value });

  if (pickup.kind === "heart") {
    state.player.hp = Math.min(state.player.maxHp, state.player.hp + 1);
    state.message = "Heart found. Back in it.";
    state.messageTimer = 1.7;
    return;
  }

  if (pickup.kind === "cache") {
    state.cachesOpened += 1;
    state.player.score += 320 + state.cachesOpened * 75 + state.upgrades.jackpot * 120;
    state.player.dashCooldown = Math.max(0, state.player.dashCooldown - (0.4 + state.upgrades.jackpot * 0.035));
    addSurge(state, 10 + Math.min(7, state.cachesOpened + state.upgrades.jackpot));
    events.push({ type: "cacheRush", x: pickup.x, y: pickup.y, count: state.cachesOpened });

    const autoChoice = rollUpgradeChoices(state, 1, "cache")[0];
    if (!autoChoice) {
      state.player.score += 900 + state.upgrades.jackpot * 160;
      state.message = "Cache jackpot: score burst!";
      state.messageTimer = 2.3;
      castNova(state, events, 230, 2.4 + state.upgrades.jackpot * 0.3);
      addBountyProgress(state, "cache", 1, events, pickup.x, pickup.y);
      return;
    }

    const cacheMode = cacheChoiceMode(state, autoChoice);
    events.push({ type: "upgrade", choice: autoChoice });
    applyUpgradeChoice(state, autoChoice, events);
    activatePowerEcho(state, autoChoice, 0.75);
    if (cacheMode !== "unlock") state.catalystCaches += 1;
    if (cacheMode === "evolve") state.cacheEvolutions += 1;
    const catalystBonus = cacheMode === "evolve" ? 1180 : cacheMode === "catalyst" ? 520 : 0;
    state.player.score += 450 + catalystBonus + state.upgrades.jackpot * 125;
    if (cacheMode === "evolve") {
      addSurge(state, 30 + state.upgrades.jackpot * 2);
      state.powerEcho = Math.min(POWER_ECHO_MAX, Math.max(state.powerEcho, 3.1 + state.upgrades.focus * 0.04));
      state.message = `Catalyst Cache: ${autoChoice.title} evolved!`;
    } else if (cacheMode === "catalyst") {
      addSurge(state, 12 + state.upgrades.jackpot);
      state.message = `Catalyst Cache: ${autoChoice.title} +${autoChoice.rankGain}!`;
    } else {
      state.message = `Cache jackpot: ${autoChoice.title}!`;
    }
    state.messageTimer = 2.3;
    castNova(
      state,
      events,
      cacheMode === "evolve" ? 260 : 210,
      2.1 + state.upgrades.jackpot * 0.25 + (cacheMode === "evolve" ? 0.55 : cacheMode === "catalyst" ? 0.22 : 0)
    );
    addBountyProgress(state, "cache", 1, events, pickup.x, pickup.y);
    return;
  }

  if (state.flowSave.timer > 0 && state.flowSave.count > 0 && state.combo.count <= 0) {
    restoreFlowSave(state, pickup, events);
  }

  state.combo.count += 1;
  state.combo.timer = 2.15 + Math.min(0.55, state.upgrades.magnet * 0.08);
  state.combo.best = Math.max(state.combo.best, state.combo.count);
  addBountyProgress(state, "sweep", 1, events, pickup.x, pickup.y);
  syncFlowBounty(state, events);

  const xpGain = Math.ceil(pickup.value * (1 + state.upgrades.jackpot * 0.04));
  const flowScore = 1 + Math.min(0.75, state.combo.count * 0.012);
  state.player.xp += xpGain;
  state.player.score += Math.round(xpGain * (8 + state.upgrades.jackpot * 2) * flowScore);

  if (state.combo.count === 12 || state.combo.count === 24 || state.combo.count === 40 || state.combo.count % 64 === 0) {
    state.message = state.combo.count >= 18 ? `Flow Rush ${state.combo.count}x. Move faster. Zap faster.` : `Flow ${state.combo.count}x. Keep sweeping shards.`;
    state.messageTimer = 1.6;
    addSurge(state, state.combo.count >= 40 ? 14 : state.combo.count >= 24 ? 10 : 6);
    events.push({ type: "combo", count: state.combo.count });
  }

  triggerFlowBurst(state, events);
  chargePowerEcho(state, events);

  if (state.player.xp >= state.player.nextXp) {
    state.player.xp -= state.player.nextXp;
    state.player.level += 1;
    state.player.nextXp = nextXpForLevel(state.player.level);
    state.choices = rollUpgradeChoices(state, 3, "level");
    if (state.choices.length > 0) {
      state.phase = "levelup";
      state.message = `Level ${state.player.level}. Pick your power spike.`;
      state.messageTimer = 99;
      events.push({ type: "levelup", level: state.player.level, choices: state.choices });
    } else {
      state.player.score += 650 + state.player.level * 55;
      state.message = "Everything maxed. XP turns into score bursts.";
      state.messageTimer = 2.3;
    }
    if (state.upgrades.nova > 0) {
      castNova(state, events, 190 + state.upgrades.nova * 34, 2.2 + state.upgrades.nova * 0.8);
    }
  }
};

const triggerFlowBurst = (state: GameState, events: GameEvent[]) => {
  if (state.combo.count < state.combo.nextBurstAt) return;

  state.flowBursts += 1;
  state.player.score += 820 + state.combo.count * 9 + state.flowBursts * 120 + state.upgrades.jackpot * 140;
  const rerollCharged = addReroll(state, 1);
  state.message = rerollCharged ? `Flow Burst ${state.combo.count}x! Reroll Spark charged.` : `Flow Burst ${state.combo.count}x! Streak shockwave.`;
  state.messageTimer = 1.8;
  addSurge(state, 12 + Math.min(8, Math.floor(state.combo.count / FLOW_BURST_STEP) * 2));
  events.push({ type: "flowBurst", x: state.player.x, y: state.player.y, count: state.combo.count, burst: state.flowBursts });
  state.combo.nextBurstAt += FLOW_BURST_STEP + state.flowBursts * FLOW_BURST_GROWTH;
  castNova(
    state,
    events,
    150 + Math.min(52, state.combo.count * 0.38) + state.upgrades.magnet * 4,
    0.95 + state.upgrades.focus * 0.06 + state.upgrades.jackpot * 0.08,
    "flow"
  );
};

const chargePowerEcho = (state: GameState, events: GameEvent[]) => {
  if (state.powerEcho <= 0) return;

  state.echoCharge += 1;
  const target = echoBurstTarget(state);
  if (state.echoCharge < target) return;

  state.echoCharge = 0;
  state.echoBursts += 1;
  state.powerEcho = Math.min(POWER_ECHO_MAX, state.powerEcho + 0.95 + state.upgrades.focus * 0.04);
  state.player.dashCooldown = Math.max(0, state.player.dashCooldown - 0.26 - state.upgrades.sprint * 0.018);
  state.player.score += Math.round(440 + target * 34 + state.echoBursts * 115 + state.upgrades.jackpot * 100);
  addSurge(state, 8 + Math.min(6, Math.floor(state.echoBursts / 2) + state.upgrades.jackpot));
  state.message = "Echo Rush! Power window extended.";
  state.messageTimer = 1.35;
  events.push({ type: "echoBurst", x: state.player.x, y: state.player.y, target, burst: state.echoBursts });
};

const spawnEnemy = (state: GameState, kind: EnemyKind, elite: boolean, events: GameEvent[]) => {
  const spec = ENEMY_SPECS[kind];
  const heat = heatCurve(state);
  const eliteMultiplier = elite ? 3.65 + heat * 1.05 : 1;
  const hpScale = 1 + heat * 2.18 + Math.max(0, powerScore(state) - 2.35) * 0.16;
  const angle = Math.random() * Math.PI * 2;
  const distanceFromPlayer = 560 + Math.random() * 260;
  const x = clamp(state.player.x + Math.cos(angle) * distanceFromPlayer, 60, WORLD_WIDTH - 60);
  const y = clamp(state.player.y + Math.sin(angle) * distanceFromPlayer, 60, WORLD_HEIGHT - 60);

  const enemy: EnemyState = {
    id: `enemy-${state.elapsed.toFixed(2)}-${Math.random().toString(16).slice(2)}`,
    kind,
    x,
    y,
    vx: 0,
    vy: 0,
    radius: spec.radius * (elite ? 1.55 : 1),
    hp: spec.hp * hpScale * eliteMultiplier,
    maxHp: spec.hp * hpScale * eliteMultiplier,
    speed: spec.speed * (elite ? 0.78 : 1) * (1 + heat * 0.22),
    damage: elite ? 2 : spec.damage,
    xpValue: Math.round(spec.xp * (elite ? 3.6 : 1) * (1 + heat * 0.22)),
    wobble: Math.random() * Math.PI * 2,
    chargeWindup: 0,
    chargeBurst: 0,
    chargeCooldown: kind === "dasher" ? 1.7 + Math.random() * 2.0 + (elite ? -0.35 : 0) : 0,
    elite
  };

  state.enemies.push(enemy);
  if (elite) {
    state.message = "Big shape incoming. Pop it for a cache.";
    state.messageTimer = 2.5;
    events.push({ type: "elite", enemy: { ...enemy } });
  }
};

const updateCombo = (state: GameState, dt: number) => {
  if (state.combo.timer > 0) {
    state.combo.timer = Math.max(0, state.combo.timer - dt);
  }

  if (state.combo.timer <= 0 && state.combo.count > 0) {
    const droppedCount = state.combo.count;
    if (droppedCount >= FLOW_SAVE_MIN_COMBO && state.flowSave.timer <= 0) {
      state.flowSave.count = droppedCount;
      state.flowSave.timer = FLOW_SAVE_WINDOW + Math.min(0.35, state.upgrades.magnet * 0.025 + state.upgrades.focus * 0.018);
      state.message = `Flow slipping! Grab a shard to save ${droppedCount}x.`;
      state.messageTimer = Math.max(state.messageTimer, 1);
    }
    state.combo.count = 0;
    state.combo.nextBurstAt = FLOW_BURST_STEP;
  }

  if (state.flowSave.timer > 0 && state.combo.count <= 0) {
    state.flowSave.timer = Math.max(0, state.flowSave.timer - dt);
    if (state.flowSave.timer <= 0) state.flowSave.count = 0;
  }
};

const restoreFlowSave = (state: GameState, pickup: PickupState, events: GameEvent[]) => {
  const saved = state.flowSave.count;
  const restored = Math.min(saved - 1, Math.max(12, Math.floor(saved * FLOW_SAVE_RESTORE)));
  state.combo.count = Math.max(state.combo.count, restored);
  state.combo.timer = Math.max(state.combo.timer, 1.38 + Math.min(0.38, state.upgrades.magnet * 0.04));
  state.combo.best = Math.max(state.combo.best, state.combo.count);
  state.flowSave.saves += 1;
  state.flowSave.best = Math.max(state.flowSave.best, saved);
  state.flowSave.count = 0;
  state.flowSave.timer = 0;
  state.player.score += Math.round(260 + restored * 6 + state.upgrades.jackpot * 90);
  addSurge(state, 9 + Math.min(8, Math.floor(restored / 12)) + state.upgrades.jackpot);
  state.message = `Flow saved! ${restored}x snapped back.`;
  state.messageTimer = 1.45;
  events.push({ type: "flowSave", x: pickup.x, y: pickup.y, saved, restored });
};

const dealDamage = (
  state: GameState,
  enemy: EnemyState,
  damage: number,
  attack: AttackKind,
  events: GameEvent[],
  color: string
) => {
  if (enemy.hp <= 0) return;
  const critChance = 0.05 + state.upgrades.jackpot * 0.035 + (state.evolved.jackpot ? 0.055 : 0);
  const crit = Math.random() < critChance;
  const finalDamage = damage * (crit ? 1.8 : 1);
  enemy.hp -= finalDamage;
  events.push({ type: "hit", enemy: { ...enemy }, attack, damage: finalDamage, crit, color });

  if (enemy.hp <= 0) {
    state.kills += 1;
    state.player.score += Math.round(28 + enemy.xpValue * 9 + (enemy.elite ? 500 : 0));
    events.push({ type: "defeat", enemy: { ...enemy }, xp: enemy.xpValue, color });
    dropPickup(state, "xp", enemy.x, enemy.y, enemy.xpValue);

    const cacheChance = enemy.elite ? 1 : 0.0018 + state.upgrades.jackpot * 0.0045 + (state.evolved.jackpot ? 0.0015 : 0);
    if (enemy.elite || (state.cacheDropCooldown <= 0 && Math.random() < cacheChance)) {
      dropPickup(state, "cache", enemy.x + randomOffset(22), enemy.y + randomOffset(22), 1);
      if (!enemy.elite) state.cacheDropCooldown = Math.max(8, 13 - state.upgrades.jackpot * 1.4);
      if (enemy.elite) {
        state.eliteKills += 1;
        addBountyProgress(state, "elite", 1, events, enemy.x, enemy.y);
      }
    }

    const heartChance = state.player.hp <= 2 ? 0.045 : 0.012;
    if (Math.random() < heartChance) dropPickup(state, "heart", enemy.x + randomOffset(28), enemy.y + randomOffset(28), 1);
  }
};

const castNova = (
  state: GameState,
  events: GameEvent[],
  radius: number,
  damage: number,
  attack: AttackKind = "nova"
) => {
  const color = attack === "dash" ? "#ffffff" : attack === "surge" ? "#ffd35a" : attack === "flow" ? "#70e6a8" : attack === "clutch" ? "#59dbff" : UPGRADE_DEFS.nova.color;
  const evolvedNova = state.evolved.nova && (attack === "nova" || attack === "dash" || attack === "surge" || attack === "flow" || attack === "clutch");
  const finalRadius = radius + (evolvedNova ? 42 : 0);
  const finalDamage = damage * (evolvedNova ? 1.18 : 1);
  events.push({ type: "attack", attack, x: state.player.x, y: state.player.y, radius: finalRadius, color });
  for (const enemy of state.enemies) {
    if (distance(state.player.x, state.player.y, enemy.x, enemy.y) <= finalRadius + enemy.radius) {
      knockEnemy(state, enemy, attack === "dash" ? 74 : attack === "surge" ? 136 : attack === "flow" ? 96 : attack === "clutch" ? 116 : 112);
      dealDamage(state, enemy, finalDamage, attack, events, color);
    }
  }
};

const triggerSecondWind = (state: GameState, events: GameEvent[]) => {
  state.secondWindUsed = true;
  state.player.hp = Math.min(state.player.maxHp, 2);
  state.player.invulnerable = 2.4;
  state.player.dashCooldown = 0;
  state.player.boostBuffer = 0;
  state.player.boostQueued = false;
  state.player.vx = 0;
  state.player.vy = 0;
  state.surgeCharge = Math.max(state.surgeCharge, 55);
  state.player.score += 1200 + state.player.level * 120;
  state.message = "Second Wind! Boost is ready. Run it back.";
  state.messageTimer = 2.4;
  events.push({ type: "secondWind", x: state.player.x, y: state.player.y });
  if (maybeDropRecoveryHeart(state, events, "secondWind")) {
    state.message = "Second Wind! Recovery heart popped.";
    state.messageTimer = 2.4;
  }
  castNova(state, events, 285 + state.upgrades.nova * 34, 4.1 + state.upgrades.nova * 0.65, "nova");
};

const maybeDropRecoveryHeart = (state: GameState, events: GameEvent[], reason: "clutch" | "secondWind"): boolean => {
  if (state.recoveryDropCooldown > 0) return false;
  if (state.player.hp > 2) return false;
  if (state.pickups.some((pickup) => pickup.kind === "heart" && pickup.value >= 0)) return false;

  const angle = recoveryDropAngle(state);
  const distance = reason === "secondWind" ? 350 : 310;
  const x = clamp(state.player.x + Math.cos(angle) * distance + randomOffset(38), 86, WORLD_WIDTH - 86);
  const y = clamp(state.player.y + Math.sin(angle) * distance + randomOffset(38), 86, WORLD_HEIGHT - 86);
  dropPickup(state, "heart", x, y, 1);
  state.recoveryDrops += 1;
  state.recoveryDropCooldown = reason === "secondWind" ? 5.5 : 9.5;
  events.push({ type: "recoveryDrop", x, y, reason });
  return true;
};

const recoveryDropAngle = (state: GameState): number => {
  const closest = state.enemies
    .map((enemy) => ({ enemy, dist: distance(state.player.x, state.player.y, enemy.x, enemy.y) }))
    .sort((a, b) => a.dist - b.dist)[0]?.enemy;
  if (closest) return Math.atan2(state.player.y - closest.y, state.player.x - closest.x);
  if (Math.hypot(state.player.vx, state.player.vy) > 12) return Math.atan2(state.player.vy, state.player.vx);
  return Math.random() * Math.PI * 2;
};

const addSurge = (state: GameState, amount: number) => {
  if (state.surgeCharge >= SURGE_MAX) return;
  const previous = state.surgeCharge;
  state.surgeCharge = clamp(state.surgeCharge + amount, 0, SURGE_MAX);
  if (previous < SURGE_MAX && state.surgeCharge >= SURGE_MAX) {
    state.message = "Surge ready. Boost to burst.";
    state.messageTimer = 1.8;
  }
};

const addReroll = (state: GameState, amount: number): boolean => {
  const previous = state.rerolls;
  state.rerolls = Math.min(REROLL_CAP, state.rerolls + amount);
  return state.rerolls > previous;
};

const updateBounty = (state: GameState, dt: number, events: GameEvent[]) => {
  if (!state.bounty) {
    state.bountyCooldown = Math.max(0, state.bountyCooldown - dt);
    if (state.elapsed >= FIRST_BOUNTY_DELAY && state.bountyCooldown <= 0) startBounty(state, events);
    return;
  }

  state.bounty.timer = Math.max(0, state.bounty.timer - dt);
  if (state.bounty.timer > 0) return;

  const expired = state.bounty;
  state.bounty = null;
  state.bountyStreak = 0;
  state.bountyCooldown = BOUNTY_RESTART_DELAY + 1.4;
  events.push({ type: "bountyExpired", bounty: expired, x: state.player.x, y: state.player.y });
  if (state.messageTimer <= 0.2) {
    state.message = "Bounty faded. New one soon.";
    state.messageTimer = 1.2;
  }
};

const startBounty = (state: GameState, events: GameEvent[]) => {
  state.bounty = createBounty(state, chooseBountyKind(state));
  state.bountyCooldown = 0;
  events.push({ type: "bountyStart", bounty: state.bounty });
  if (state.messageTimer <= 0.2) {
    state.message = `Bounty: ${state.bounty.title}.`;
    state.messageTimer = 1.4;
  }
};

const chooseBountyKind = (state: GameState): BountyKind => {
  const kinds: BountyKind[] = ["sweep", "flow"];
  const weights = [1.28, 1.16];

  if (state.elapsed >= 18) {
    kinds.push("thread");
    weights.push(0.88 + Math.min(0.26, state.upgrades.sprint * 0.04));
  }
  if (state.pickups.some((pickup) => pickup.kind === "cache" && pickup.value >= 0)) {
    kinds.push("cache");
    weights.push(2.15);
  }
  if (state.enemies.some((enemy) => enemy.elite && enemy.hp > 0)) {
    kinds.push("elite");
    weights.push(2.0);
  }

  return weightedChoice(kinds, weights);
};

const createBounty = (state: GameState, kind: BountyKind): BountyState => {
  const levelPressure = Math.min(12, state.player.level + Math.floor(state.elapsed / 42));
  const clearPressure = Math.min(10, state.bountiesCleared * 2);
  if (kind === "flow") {
    const target = Math.min(72, Math.max(22, state.combo.count + 15 + Math.floor(levelPressure * 1.3) + state.bountyStreak * 2));
    const duration = 24 + Math.min(7, Math.floor(state.player.level / 2));
    return {
      kind,
      title: "Flow Streak",
      hint: "Keep grabbing shards without dropping flow.",
      progress: Math.min(state.combo.count, target),
      target,
      timer: duration,
      duration
    };
  }
  if (kind === "thread") {
    const target = state.player.level >= 9 ? 4 : 3;
    const duration = 25;
    return {
      kind,
      title: "Dash Thread",
      hint: "Boost close past enemies.",
      progress: 0,
      target,
      timer: duration,
      duration
    };
  }
  if (kind === "cache") {
    const duration = 31;
    return {
      kind,
      title: "Crack Cache",
      hint: "Chase the gold pickup.",
      progress: 0,
      target: 1,
      timer: duration,
      duration
    };
  }
  if (kind === "elite") {
    const duration = 34;
    return {
      kind,
      title: "Pop Big Shape",
      hint: "Burn down the big target.",
      progress: 0,
      target: 1,
      timer: duration,
      duration
    };
  }

  const target = 16 + Math.min(34, levelPressure * 2 + clearPressure);
  const duration = 23 + Math.min(7, Math.floor(state.player.level / 2));
  return {
    kind,
    title: "Shard Sweep",
    hint: "Vacuum XP shards fast.",
    progress: 0,
    target,
    timer: duration,
    duration
  };
};

const addBountyProgress = (state: GameState, kind: BountyKind, amount: number, events: GameEvent[], x = state.player.x, y = state.player.y) => {
  if (!state.bounty || state.bounty.kind !== kind) return;
  state.bounty.progress = Math.min(state.bounty.target, state.bounty.progress + amount);
  if (state.bounty.progress >= state.bounty.target) completeBounty(state, events, x, y);
};

const syncFlowBounty = (state: GameState, events: GameEvent[]) => {
  if (!state.bounty || state.bounty.kind !== "flow") return;
  state.bounty.progress = Math.min(state.bounty.target, Math.max(state.bounty.progress, state.combo.count));
  if (state.bounty.progress >= state.bounty.target) completeBounty(state, events, state.player.x, state.player.y);
};

const completeBounty = (state: GameState, events: GameEvent[], x: number, y: number) => {
  if (!state.bounty) return;
  const { kind, title, target } = state.bounty;
  state.bounty = null;
  state.bountiesCleared += 1;
  state.bountyStreak += 1;
  state.bestBountyStreak = Math.max(state.bestBountyStreak, state.bountyStreak);

  const reward = Math.round(520 + state.player.level * 34 + target * 19 + state.bountyStreak * 170 + state.upgrades.jackpot * 90);
  state.player.score += reward;
  state.player.dashCooldown = Math.max(0, state.player.dashCooldown - (0.42 + Math.min(0.4, state.bountyStreak * 0.045) + state.upgrades.sprint * 0.014));
  addSurge(state, 15 + Math.min(15, state.bountyStreak * 2 + state.upgrades.jackpot));
  state.powerEcho = Math.min(POWER_ECHO_MAX, Math.max(state.powerEcho, 1.8 + state.bountyStreak * 0.16 + state.upgrades.focus * 0.045));
  state.echoCharge = Math.max(state.echoCharge, Math.floor(echoBurstTarget(state) * 0.16));
  const rerollCharged = state.bountyStreak % 3 === 0 && addReroll(state, 1);
  state.message = rerollCharged ? `Bounty chain x${state.bountyStreak}! Reroll Spark charged.` : `${title} cleared! Surge and Echo spiked.`;
  state.messageTimer = 1.9;
  state.bountyCooldown = BOUNTY_RESTART_DELAY;
  events.push({ type: "bountyComplete", x, y, kind, streak: state.bountyStreak, reward });
};

const activatePowerEcho = (state: GameState, choice: UpgradeChoice, scale = 1) => {
  const rarityBonus = choice.rarity === "epic" ? 2.4 : choice.rarity === "rare" ? 1.55 : choice.rarity === "uncommon" ? 0.65 : 0;
  const evolveBonus = state.evolved[choice.id] && state.upgrades[choice.id] >= choice.maxRank ? 1.4 : 0;
  state.powerEcho = Math.min(POWER_ECHO_MAX, Math.max(state.powerEcho, (POWER_ECHO_COMMON + rarityBonus + evolveBonus) * scale));
  state.echoCharge = 0;
};

const powerEchoDamageScale = (state: GameState): number => (state.powerEcho > 0 ? 1.15 : 1);
const powerEchoCooldownScale = (state: GameState): number => (state.powerEcho > 0 ? 0.92 : 1);

const perfectScoopRefund = (state: GameState, count: number): number =>
  Math.min(1.65, 0.74 + (count - PERFECT_SCOOP_COUNT) * 0.055 + state.upgrades.sprint * 0.035 + (state.evolved.sprint ? 0.18 : 0));

const triggerDashThread = (state: GameState, enemy: EnemyState, events: GameEvent[]) => {
  if (state.dashThreadIds.includes(enemy.id)) return;

  state.dashThreadIds.push(enemy.id);
  const count = state.dashThreadIds.length;
  const chain = count === 3;
  const cooldownRefund = chain ? Math.min(0.52, 0.26 + state.upgrades.sprint * 0.02 + (state.evolved.sprint ? 0.1 : 0)) : 0;

  state.dashThreads += 1;
  state.bestDashThread = Math.max(state.bestDashThread, count);
  state.player.score += Math.round(90 + count * 20 + enemy.xpValue * 2.6 + (enemy.elite ? 260 : 0));
  if (cooldownRefund > 0) state.player.dashCooldown = Math.max(0, state.player.dashCooldown - cooldownRefund);
  addSurge(state, enemy.elite ? 5 : chain ? 4 : 1);

  if (chain || enemy.elite) {
    state.message = cooldownRefund > 0 ? `Dash Thread x${count}! Boost cooled faster.` : "Dash Thread! Clean gap.";
    state.messageTimer = 1.15;
  }

  events.push({ type: "dashThread", x: enemy.x, y: enemy.y, count, elite: enemy.elite, cooldownRefund });
  addBountyProgress(state, "thread", 1, events, enemy.x, enemy.y);
};

const knockEnemy = (state: GameState, enemy: EnemyState, amount: number) => {
  const dx = enemy.x - state.player.x;
  const dy = enemy.y - state.player.y;
  const dist = Math.max(0.001, Math.hypot(dx, dy));
  enemy.x = clamp(enemy.x + (dx / dist) * amount, 40, WORLD_WIDTH - 40);
  enemy.y = clamp(enemy.y + (dy / dist) * amount, 40, WORLD_HEIGHT - 40);
};

const dropPickup = (state: GameState, kind: PickupKind, x: number, y: number, value: number) => {
  state.pickups.push({
    id: `pickup-${kind}-${state.elapsed.toFixed(2)}-${Math.random().toString(16).slice(2)}`,
    kind,
    x: clamp(x + randomOffset(18), 48, WORLD_WIDTH - 48),
    y: clamp(y + randomOffset(18), 48, WORLD_HEIGHT - 48),
    value,
    bob: Math.random() * Math.PI * 2,
    scooped: false
  });
};

const chooseEnemyKind = (state: GameState): EnemyKind => {
  const unlocked = (Object.keys(ENEMY_SPECS) as EnemyKind[]).filter((kind) => state.elapsed >= ENEMY_SPECS[kind].unlockAt);
  const heat = heatCurve(state);
  const weights = unlocked.map((kind) => {
    if (kind === "nibbler") return Math.max(0.35, 1.3 - heat * 0.55);
    if (kind === "dasher") return 0.34 + heat * 0.62;
    if (kind === "brute") return Math.max(0.1, heat * 0.58);
    return Math.max(0.08, (heat - 0.35) * 0.7);
  });
  return weightedChoice(unlocked, weights);
};

const chooseEliteKind = (state: GameState): EnemyKind => {
  if (state.elapsed > 145) return Math.random() < 0.48 ? "warden" : "brute";
  if (state.elapsed > 85) return Math.random() < 0.65 ? "brute" : "dasher";
  return "brute";
};

type ChoiceSource = "level" | "cache" | "reroll";

const rollUpgradeChoices = (state: GameState, count: number, source: ChoiceSource): UpgradeChoice[] => {
  const candidates = eligibleUpgradeIds(state);
  const result: UpgradeChoice[] = [];

  if (source === "level" && state.player.level === 2 && state.upgrades.pulse === 0 && state.upgrades.orbit === 0) {
    result.push(toChoice(state, Math.random() < 0.55 ? "pulse" : "orbit", source));
  }

  while (result.length < count && candidates.length > 0) {
    const hasFirstWeaponUnlock = state.player.level === 2 && result.some((choice) => choice.id === "pulse" || choice.id === "orbit");
    const remaining = candidates
      .filter((id) => !result.some((choice) => choice.id === id))
      .filter((id) => !(hasFirstWeaponUnlock && (id === "pulse" || id === "orbit")));
    if (remaining.length === 0) break;
    const weights = remaining.map((id) => upgradeWeight(state, id, source));
    result.push(toChoice(state, weightedChoice(remaining, weights), source));
  }

  return result.slice(0, count);
};

const eligibleUpgradeIds = (state: GameState): UpgradeId[] =>
  UPGRADE_IDS.filter((id) => state.upgrades[id] < UPGRADE_DEFS[id].maxRank)
    .filter((id) => state.upgrades[id] > 0 || state.player.level >= UPGRADE_DEFS[id].unlockLevel);

const toChoice = (state: GameState, id: UpgradeId, source: ChoiceSource): UpgradeChoice => {
  const def = UPGRADE_DEFS[id];
  const nextRank = state.upgrades[id] + 1;
  const rarity = upgradeRarity(state, id, nextRank, source);
  const rankGain = Math.min(rankGainForRarity(rarity), def.maxRank - state.upgrades[id]);
  return {
    id,
    title: def.title,
    description: upgradeDescription(id, nextRank, rankGain),
    rarity,
    color: def.color,
    rank: state.upgrades[id],
    rankGain,
    maxRank: def.maxRank
  };
};

const upgradeWeight = (state: GameState, id: UpgradeId, source: ChoiceSource): number => {
  const rank = state.upgrades[id];
  const def = UPGRADE_DEFS[id];
  const rarityLift = id === "jackpot" || id === "nova" ? 0.5 + state.upgrades.jackpot * 0.08 : 1;
  const catchup = rank === 0 && (id === "pulse" || id === "orbit") ? 1.08 : 1;
  const survivalLift = id === "heart" && state.player.hp <= 2 ? 2.2 : 1;
  const diminishing = 1 - (rank / def.maxRank) * 0.28;
  const ranksFromEvolution = def.maxRank - rank;
  const evolutionLift =
    rank <= 0 || state.evolved[id]
      ? 1
      : ranksFromEvolution <= 1
        ? 2.05
        : ranksFromEvolution <= 2
          ? 1.58
          : ranksFromEvolution <= 3
          ? 1.18
          : 1;
  const cacheLift =
    source === "cache"
      ? rank > 0
        ? 2.25 + Math.max(0, 4 - ranksFromEvolution) * 0.58
        : 0.54
      : 1;
  const cacheEvolutionLift =
    source === "cache" && rank > 0 && !state.evolved[id] && ranksFromEvolution <= 2 ? 2.2 : 1;
  return def.weight * rarityLift * catchup * survivalLift * diminishing * evolutionLift * cacheLift * cacheEvolutionLift;
};

const cacheChoiceMode = (state: GameState, choice: UpgradeChoice): "unlock" | "catalyst" | "evolve" => {
  const reachesEvolution = choice.rank < choice.maxRank && choice.rank + choice.rankGain >= choice.maxRank;
  if (!state.evolved[choice.id] && reachesEvolution) return "evolve";
  return state.upgrades[choice.id] > 0 ? "catalyst" : "unlock";
};

const applyUpgradeChoice = (state: GameState, choice: UpgradeChoice, events?: GameEvent[]) => {
  const currentRank = state.upgrades[choice.id];
  const nextRank = Math.min(choice.maxRank, currentRank + choice.rankGain);
  const gainedRanks = nextRank - currentRank;
  state.upgrades[choice.id] = nextRank;
  state.rarityFinds[choice.rarity] += 1;
  state.rarityDryStreak = choice.rarity === "rare" || choice.rarity === "epic" ? 0 : Math.min(6, state.rarityDryStreak + 1);
  if (choice.rarity === "epic") addSurge(state, 42);
  else if (choice.rarity === "rare") addSurge(state, 26);
  else if (choice.rarity === "uncommon") addSurge(state, 8);

  if (choice.id === "heart") {
    state.player.maxHp += gainedRanks;
    state.player.hp = Math.min(state.player.maxHp, state.player.hp + gainedRanks + 1);
  }

  if (!state.evolved[choice.id] && currentRank < choice.maxRank && nextRank >= choice.maxRank) {
    state.evolved[choice.id] = true;
    state.player.score += 1600 + state.player.level * 120;
    const rerollCharged = addReroll(state, 1);
    addSurge(state, 55);
    state.message = rerollCharged ? `${UPGRADE_DEFS[choice.id].title} evolved! Reroll Spark charged.` : `${UPGRADE_DEFS[choice.id].title} evolved!`;
    state.messageTimer = 2.4;
    if (choice.id === "heart") {
      state.player.maxHp += 2;
      state.player.hp = Math.min(state.player.maxHp, state.player.hp + 3);
    }
    events?.push({ type: "evolve", choice });
  }
};

const upgradeDescription = (id: UpgradeId, rank: number, rankGain: number): string => {
  const surge = rankGain > 1 ? ` Surge +${rankGain} ranks.` : "";
  if (id === "spark") {
    const targets = 1 + Math.floor((rank + 1) / 3);
    return `Zap ${targets} target${targets === 1 ? "" : "s"} for stronger damage.${surge}`;
  }
  if (id === "pulse") return rank === 1 ? `Unlock a bubble blast around you.${surge}` : `Bubble blast gets wider and punchier.${surge}`;
  if (id === "orbit") return rank === 1 ? `Unlock a circling star guard.${surge}` : `More star hits near your body.${surge}`;
  if (id === "magnet") return `XP shards zip in from farther away.${surge}`;
  if (id === "sprint") return `Move faster without making controls twitchy.${surge}`;
  if (id === "heart") return `Add max health and heal right now.${surge}`;
  if (id === "focus") return `All auto-weapons recharge faster.${surge}`;
  if (id === "jackpot") return `More crits, score bursts, and surprise caches.${surge}`;
  return `Level-ups and dashes create bigger shockwaves.${surge}`;
};

const upgradeRarity = (state: GameState, id: UpgradeId, rank: number, source: ChoiceSource): UpgradeRarity => {
  const level = state.player.level;
  const dryLift = source === "level" || source === "reroll" ? Math.min(0.12, state.rarityDryStreak * 0.024) : 0;
  const rerollLift = source === "reroll" ? 0.022 + state.upgrades.jackpot * 0.003 : 0;
  if (source === "cache") {
    if (level >= 8 && Math.random() < 0.15 + state.upgrades.jackpot * 0.035) return "epic";
    return "rare";
  }
  if ((id === "jackpot" || id === "nova") && level >= UPGRADE_DEFS[id].unlockLevel) {
    if (level >= 9 && Math.random() < 0.18 + state.upgrades.jackpot * 0.045 + dryLift + rerollLift * 0.4) return "epic";
    return "rare";
  }
  if (rank >= UPGRADE_DEFS[id].maxRank && level >= 7) {
    if (level >= 10 && Math.random() < 0.2 + dryLift + rerollLift * 0.4) return "epic";
    return "rare";
  }
  if (rank === 1 && (id === "pulse" || id === "orbit")) return "uncommon";
  const rareChance = Math.max(0, (level - 5) * 0.024 + state.upgrades.jackpot * 0.009 + dryLift + rerollLift);
  const epicChance = Math.max(0, (level - 8) * 0.006 + state.upgrades.jackpot * 0.004 + dryLift * 0.25 + rerollLift * 0.25);
  if (level >= 9 && Math.random() < epicChance) return "epic";
  if (level >= 6 && (rank % 5 === 0 || Math.random() < rareChance)) return "rare";
  if (level >= 3 && (rank % 4 === 0 || Math.random() < 0.07)) return "uncommon";
  return "common";
};

const rankGainForRarity = (rarity: UpgradeRarity): number => {
  if (rarity === "epic") return 2;
  if (rarity === "rare") return 2;
  return 1;
};

const upgradeMessage = (id: UpgradeId, rank: number): string => {
  if (rank >= UPGRADE_DEFS[id].maxRank) return `${UPGRADE_DEFS[id].title} evolved!`;
  return `${UPGRADE_DEFS[id].title} rank ${rank}. Nice power spike.`;
};

const sparkStats = (state: GameState) => {
  const rank = state.upgrades.spark;
  const focus = state.upgrades.focus;
  const rush = flowRush(state);
  const echoDamage = powerEchoDamageScale(state);
  const echoCooldown = powerEchoCooldownScale(state);
  return {
    range: 690 + rank * 20 + (state.evolved.spark ? 80 : 0),
    targets: 1 + Math.floor((rank + 1) / 3) + (state.evolved.spark ? 1 : 0),
    cooldown: Math.max(0.28, (0.86 - rank * 0.045) * (1 - focus * 0.055) * (1 - rush * 0.38) * (state.evolved.focus ? 0.9 : 1) * (state.evolved.spark ? 0.92 : 1) * echoCooldown),
    damage: (1.05 + rank * 0.44) * (1 + state.upgrades.jackpot * 0.03) * (state.evolved.spark ? 1.16 : 1) * echoDamage
  };
};

const pulseStats = (state: GameState) => {
  const rank = state.upgrades.pulse;
  const focus = state.upgrades.focus;
  const rush = flowRush(state);
  const echoDamage = powerEchoDamageScale(state);
  const echoCooldown = powerEchoCooldownScale(state);
  return {
    radius: 128 + rank * 26 + (state.evolved.pulse ? 46 : 0),
    cooldown: Math.max(0.58, (1.64 - rank * 0.085) * (1 - focus * 0.045) * (1 - rush * 0.34) * (state.evolved.focus ? 0.91 : 1) * (state.evolved.pulse ? 0.88 : 1) * echoCooldown),
    damage: (0.82 + rank * 0.34) * (state.evolved.pulse ? 1.22 : 1) * echoDamage
  };
};

const orbitDamageStats = (state: GameState) => {
  const rank = state.upgrades.orbit;
  const orbit = orbitStats(state);
  const rush = flowRush(state);
  const echoDamage = powerEchoDamageScale(state);
  const echoCooldown = powerEchoCooldownScale(state);
  return {
    count: orbit.count,
    radius: orbit.radius + 46,
    cooldown: Math.max(0.18, (0.42 - state.upgrades.focus * 0.018) * (1 - rush * 0.3) * (state.evolved.focus ? 0.9 : 1) * (state.evolved.orbit ? 0.9 : 1) * echoCooldown),
    damage: (0.52 + rank * 0.2) * (state.evolved.orbit ? 1.18 : 1) * echoDamage
  };
};

const nearestEnemies = (state: GameState, range: number, count: number): EnemyState[] =>
  state.enemies
    .filter((enemy) => enemy.hp > 0)
    .map((enemy) => ({ enemy, dist: distance(state.player.x, state.player.y, enemy.x, enemy.y) }))
    .filter((entry) => entry.dist <= range + entry.enemy.radius)
    .sort((a, b) => a.dist - b.dist)
    .slice(0, count)
    .map((entry) => entry.enemy);

const nextXpForLevel = (level: number): number => {
  const base = 56 + level * 14 + Math.pow(level, 1.8) * 12.5;
  const pacing = level === 1 ? 1.12 : 1.48 + Math.min(0.36, (level - 2) * 0.07);
  return Math.floor(base * pacing);
};

const heatCurve = (state: GameState): number => {
  const timeHeat = clamp(state.elapsed / state.runDuration, 0, 1);
  const eased = 1 - Math.pow(1 - timeHeat, 2.15);
  return clamp(eased + state.player.level * 0.014 + state.kills * 0.00135, 0, 1.42);
};

const weightedChoice = <T>(items: T[], weights: number[]): T => {
  const total = weights.reduce((sum, weight) => sum + Math.max(0, weight), 0);
  let roll = Math.random() * total;
  for (let i = 0; i < items.length; i += 1) {
    roll -= Math.max(0, weights[i]);
    if (roll <= 0) return items[i];
  }
  return items[items.length - 1];
};

const randomOffset = (amount: number): number => (Math.random() - 0.5) * amount * 2;
const clamp = (value: number, min: number, max: number): number => Math.min(max, Math.max(min, value));
const distance = (x1: number, y1: number, x2: number, y2: number): number => Math.hypot(x1 - x2, y1 - y2);
const lerp = (from: number, to: number, t: number): number => from + (to - from) * clamp(t, 0, 1);
