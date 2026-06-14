import {
  bountyProgress,
  echoBurstProgress,
  echoBurstTarget,
  evolvedCount,
  flowBurstProgress,
  flowRush,
  flowSaveProgress,
  powerScore,
  powerEchoProgress,
  snapBoostWindowProgress,
  surgeProgress,
  surgeReady,
  threatProgress,
  timeRemaining,
  upgradeTitle,
  xpProgress,
  type GameState,
  type UpgradeChoice,
  type UpgradeId
} from "../game/simulation";
import { isMuted, setMute } from "./sfx";

type HudInput = {
  x: number;
  y: number;
  action: boolean;
  restart: boolean;
};

type RunAwardTone = "gold" | "mint" | "cyan" | "pink";

type RunAward = {
  label: string;
  value: string;
  tone: RunAwardTone;
  score: number;
};

type RunSummary = {
  score: number;
  level: number;
  kills: number;
  power: number;
  flow: number;
  flowSaves: number;
  bounty: number;
  clutch: number;
  catalyst: number;
  cacheEvolve: number;
  evolved: number;
  rarePlus: number;
  time: number;
  win: boolean;
};

type RunRecords = Omit<RunSummary, "win"> & {
  runs: number;
  wins: number;
};

export type HudController = {
  setState: (state: GameState) => void;
  consumeInput: () => HudInput;
  showLevelChoices: (state: GameState, onPick: (id: UpgradeId) => void, onReroll: () => void) => void;
  hideLevelChoices: () => void;
  showRunEnd: (state: GameState, outcome: "complete" | "gameover", onRestart: () => void) => void;
  hideRunEnd: () => void;
  show: () => void;
  hide: () => void;
};

export const createHud = (host: HTMLElement): HudController => {
  const hud = document.createElement("div");
  hud.className = "hud";
  hud.innerHTML = `
    <section class="run-chip" aria-live="polite">
      <div>
        <p class="eyebrow">Gizmo Surge</p>
        <h1>Shape Storm</h1>
      </div>
      <div class="hearts" aria-label="Health"></div>
    </section>
    <section class="stat-panel" aria-live="polite">
      <div><span>Time</span><strong class="time-count"></strong></div>
      <div><span>Level</span><strong class="level-count"></strong></div>
      <div><span>KO</span><strong class="kill-count"></strong></div>
      <div><span>Score</span><strong class="score-count"></strong></div>
    </section>
    <section class="build-panel" aria-live="polite">
      <div class="build-list"></div>
    </section>
    <section class="progress-panel" aria-live="polite">
      <div class="progress-top">
        <span>XP</span>
        <strong class="xp-count"></strong>
      </div>
      <div class="meter xp-meter"><i></i></div>
      <div class="progress-top run-row">
        <span>Threat</span>
        <strong class="run-count"></strong>
      </div>
      <div class="meter run-meter"><i></i></div>
    </section>
    <section class="bounty-chip" aria-live="polite">
      <div class="bounty-copy">
        <span>Bounty</span>
        <strong class="bounty-title"></strong>
        <em class="bounty-hint"></em>
      </div>
      <div class="bounty-meta">
        <b class="bounty-count"></b>
        <small class="bounty-timer"></small>
      </div>
      <i></i>
    </section>
    <section class="tip-chip" aria-live="polite"></section>
    <section class="flow-chip" aria-live="polite">
      <span>Flow</span>
      <strong></strong>
      <i></i>
    </section>
    <section class="clutch-chip" aria-live="polite">
      <span>Clutch</span>
      <strong></strong>
      <i></i>
    </section>
    <section class="echo-chip" aria-live="polite">
      <span>Echo</span>
      <strong></strong>
      <i></i>
    </section>
    <section class="surge-chip" aria-live="polite">
      <span>Surge</span>
      <strong></strong>
      <i></i>
    </section>
    <button class="icon-button restart-button" type="button" aria-label="Restart run">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M4 12a8 8 0 1 0 3-6.2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" />
        <path d="M4 4v6h6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </button>
    <button class="icon-button mute-button" type="button" aria-label="Toggle sound">
      <svg viewBox="0 0 24 24" aria-hidden="true" class="mute-icon">
        <path d="M11 5L6 9H2v6h4l5 4V5z" fill="currentColor"/>
        <path class="mute-x" d="M17 9l4 4m0-4l-4 4" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>
      </svg>
    </button>
    <div class="touch-cluster" aria-label="Touch controls">
      <div class="joystick" aria-hidden="true"><div class="joystick-knob"></div></div>
      <button class="touch-button action-button" type="button">Boost</button>
    </div>
    <dialog class="level-dialog">
      <div class="level-card">
        <p class="eyebrow">Power Spike</p>
        <h2>Choose one</h2>
        <div class="choice-list"></div>
        <div class="choice-actions">
          <button class="reroll-button" type="button"></button>
        </div>
      </div>
    </dialog>
    <dialog class="end-dialog">
      <div class="end-card">
        <p class="eyebrow end-eyebrow"></p>
        <h2 class="end-title"></h2>
        <p class="end-subtitle"></p>
        <div class="results-breakdown"></div>
        <button class="primary-button" type="button">Play Again</button>
      </div>
    </dialog>
  `;
  host.appendChild(hud);

  const hearts = hud.querySelector<HTMLDivElement>(".hearts")!;
  const timeCount = hud.querySelector<HTMLElement>(".time-count")!;
  const levelCount = hud.querySelector<HTMLElement>(".level-count")!;
  const killCount = hud.querySelector<HTMLElement>(".kill-count")!;
  const scoreCount = hud.querySelector<HTMLElement>(".score-count")!;
  const buildList = hud.querySelector<HTMLDivElement>(".build-list")!;
  const xpCount = hud.querySelector<HTMLElement>(".xp-count")!;
  const xpMeter = hud.querySelector<HTMLElement>(".xp-meter i")!;
  const runCount = hud.querySelector<HTMLElement>(".run-count")!;
  const runMeter = hud.querySelector<HTMLElement>(".run-meter i")!;
  const bountyChip = hud.querySelector<HTMLElement>(".bounty-chip")!;
  const bountyTitle = hud.querySelector<HTMLElement>(".bounty-title")!;
  const bountyHint = hud.querySelector<HTMLElement>(".bounty-hint")!;
  const bountyCount = hud.querySelector<HTMLElement>(".bounty-count")!;
  const bountyTimer = hud.querySelector<HTMLElement>(".bounty-timer")!;
  const bountyMeter = hud.querySelector<HTMLElement>(".bounty-chip i")!;
  const tipChip = hud.querySelector<HTMLElement>(".tip-chip")!;
  const flowChip = hud.querySelector<HTMLElement>(".flow-chip")!;
  const flowLabel = hud.querySelector<HTMLElement>(".flow-chip span")!;
  const flowCount = hud.querySelector<HTMLElement>(".flow-chip strong")!;
  const flowMeter = hud.querySelector<HTMLElement>(".flow-chip i")!;
  const clutchChip = hud.querySelector<HTMLElement>(".clutch-chip")!;
  const clutchLabel = hud.querySelector<HTMLElement>(".clutch-chip span")!;
  const clutchCount = hud.querySelector<HTMLElement>(".clutch-chip strong")!;
  const clutchMeter = hud.querySelector<HTMLElement>(".clutch-chip i")!;
  const echoChip = hud.querySelector<HTMLElement>(".echo-chip")!;
  const echoLabel = hud.querySelector<HTMLElement>(".echo-chip span")!;
  const echoCount = hud.querySelector<HTMLElement>(".echo-chip strong")!;
  const echoMeter = hud.querySelector<HTMLElement>(".echo-chip i")!;
  const surgeChip = hud.querySelector<HTMLElement>(".surge-chip")!;
  const surgeCount = hud.querySelector<HTMLElement>(".surge-chip strong")!;
  const surgeMeter = hud.querySelector<HTMLElement>(".surge-chip i")!;
  const restartButton = hud.querySelector<HTMLButtonElement>(".restart-button")!;
  const muteButton = hud.querySelector<HTMLButtonElement>(".mute-button")!;
  const muteX = hud.querySelector<SVGPathElement>(".mute-x")!;
  const joystick = hud.querySelector<HTMLDivElement>(".joystick")!;
  const knob = hud.querySelector<HTMLDivElement>(".joystick-knob")!;
  const actionButton = hud.querySelector<HTMLButtonElement>(".action-button")!;
  const levelDialog = hud.querySelector<HTMLDialogElement>(".level-dialog")!;
  const choiceList = hud.querySelector<HTMLDivElement>(".choice-list")!;
  const rerollButton = hud.querySelector<HTMLButtonElement>(".reroll-button")!;
  const endDialog = hud.querySelector<HTMLDialogElement>(".end-dialog")!;
  const endEyebrow = hud.querySelector<HTMLElement>(".end-eyebrow")!;
  const endTitle = hud.querySelector<HTMLElement>(".end-title")!;
  const endSubtitle = hud.querySelector<HTMLElement>(".end-subtitle")!;
  const resultsBreakdown = hud.querySelector<HTMLDivElement>(".results-breakdown")!;
  const playAgain = hud.querySelector<HTMLButtonElement>(".primary-button")!;

  let joystickVector = { x: 0, y: 0 };
  let action = false;
  let restart = false;
  let activePointerId: number | null = null;
  let restartCallback: (() => void) | null = null;

  const requestRestart = () => {
    restart = true;
    if (levelDialog.open) levelDialog.close();
    if (endDialog.open) endDialog.close();
    restartCallback?.();
  };

  restartButton.addEventListener("click", requestRestart);
  playAgain.addEventListener("click", requestRestart);
  actionButton.addEventListener("click", () => { action = true; });

  muteButton.addEventListener("click", () => {
    setMute(!isMuted());
    muteX.style.display = isMuted() ? "block" : "none";
  });

  joystick.addEventListener("pointerdown", (event) => {
    activePointerId = event.pointerId;
    joystick.setPointerCapture(event.pointerId);
    updateJoystick(event);
  });
  joystick.addEventListener("pointermove", (event) => {
    if (event.pointerId === activePointerId) updateJoystick(event);
  });
  joystick.addEventListener("pointerup", (event) => {
    if (event.pointerId === activePointerId) resetJoystick();
  });
  joystick.addEventListener("pointercancel", resetJoystick);

  const setState = (state: GameState) => {
    hearts.innerHTML = Array.from({ length: state.player.maxHp }, (_, i) => `<span class="${i < state.player.hp ? "filled" : ""}"></span>`).join("");
    timeCount.textContent = formatTime(timeRemaining(state));
    levelCount.textContent = `${state.player.level}`;
    killCount.textContent = `${state.kills}`;
    scoreCount.textContent = compactNumber(state.player.score);
    xpCount.textContent = `${state.player.xp} / ${state.player.nextXp}`;
    xpMeter.style.width = `${Math.round(xpProgress(state) * 100)}%`;
    const threat = threatProgress(state);
    runCount.textContent = `${Math.round(threat * 100)}%`;
    runMeter.style.width = `${Math.round(threat * 100)}%`;
    const bounty = state.bounty;
    bountyChip.classList.toggle("active", Boolean(bounty));
    bountyChip.classList.toggle("urgent", Boolean(bounty && bounty.timer <= 6));
    bountyTitle.textContent = bounty ? bounty.title : "Next Bounty";
    bountyHint.textContent = bounty ? bounty.hint : "";
    bountyCount.textContent = bounty ? `${Math.floor(bounty.progress)} / ${bounty.target}` : `${state.bountiesCleared}`;
    bountyTimer.textContent = bounty ? `${Math.ceil(bounty.timer)}s` : "";
    bountyMeter.style.width = `${Math.round(bountyProgress(state) * 100)}%`;
    tipChip.textContent = state.messageTimer > 0 ? state.message : idleTip(state);
    const rush = flowRush(state);
    const burstProgress = flowBurstProgress(state);
    const saveProgress = flowSaveProgress(state);
    const flowSaving = saveProgress > 0;
    flowLabel.textContent = flowSaving ? "Save Flow" : burstProgress >= 0.82 ? "Burst Soon" : rush > 0 ? "Flow Rush" : "Flow";
    flowCount.textContent = flowSaving ? `${state.flowSave.count}x` : `${state.combo.count}x`;
    flowMeter.style.width = `${Math.round(flowSaving ? saveProgress * 100 : Math.min(1, state.combo.timer / 2.15) * 100)}%`;
    flowChip.classList.toggle("active", flowSaving || (state.combo.count >= 4 && state.combo.timer > 0));
    flowChip.classList.toggle("hot", state.combo.count >= 24 && state.combo.timer > 0);
    flowChip.classList.toggle("rush", rush > 0);
    flowChip.classList.toggle("burst-near", burstProgress >= 0.72);
    flowChip.classList.toggle("save", flowSaving);
    const clutchTarget = state.player.hp <= 2 ? 4 : 5;
    const clutchActive = state.clutch.timer > 0 && state.clutch.count > 0;
    const clutchNear = clutchActive && state.clutch.count >= clutchTarget - 1;
    clutchLabel.textContent = clutchNear ? "One More" : state.player.hp <= 2 ? "Clutch Save" : "Clutch";
    clutchCount.textContent = `${state.clutch.count}/${clutchTarget}`;
    clutchMeter.style.width = `${Math.round(Math.min(1, state.clutch.count / clutchTarget) * 100)}%`;
    clutchChip.classList.toggle("active", clutchActive);
    clutchChip.classList.toggle("near", clutchNear);
    clutchChip.classList.toggle("danger", clutchActive && state.player.hp <= 2);
    clutchChip.classList.toggle("fading", clutchActive && state.clutch.timer <= 0.8);
    const echoProgress = echoBurstProgress(state);
    echoLabel.textContent = echoProgress >= 0.72 ? "Echo Rush" : "Echo";
    echoCount.textContent = state.powerEcho > 0 ? `${state.echoCharge}/${echoBurstTarget(state)}` : "0";
    echoMeter.style.width = `${Math.round(Math.max(echoProgress, powerEchoProgress(state) * 0.18) * 100)}%`;
    echoChip.classList.toggle("active", state.powerEcho > 0);
    echoChip.classList.toggle("burst-near", echoProgress >= 0.72);
    const surge = surgeProgress(state);
    const ready = surgeReady(state);
    const snapWindow = snapBoostWindowProgress(state);
    surgeCount.textContent = ready ? "Ready" : `${Math.round(surge * 100)}%`;
    surgeMeter.style.width = `${Math.round(surge * 100)}%`;
    surgeChip.classList.toggle("active", surge > 0 || state.surgeBursts > 0);
    surgeChip.classList.toggle("ready", ready);
    muteX.style.display = isMuted() ? "block" : "none";
    actionButton.disabled = false;
    actionButton.classList.toggle("scooping", state.player.dashTimer > 0);
    actionButton.classList.toggle("cooling", state.player.dashCooldown > 0);
    actionButton.classList.toggle("snap-window", snapWindow > 0 && !state.player.boostQueued);
    actionButton.classList.toggle("queued", state.player.boostQueued);
    actionButton.textContent =
      state.player.dashTimer > 0
        ? "Scoop"
        : state.player.boostQueued
        ? "Queued"
        : state.player.dashCooldown > 0
          ? snapWindow > 0
            ? "Snap!"
            : `${state.player.dashCooldown.toFixed(1)}s`
          : "Boost";
    buildList.innerHTML = buildBadges(state);
  };

  const consumeInput = (): HudInput => {
    const next = { x: joystickVector.x, y: joystickVector.y, action, restart };
    action = false;
    restart = false;
    return next;
  };

  const showLevelChoices = (state: GameState, onPick: (id: UpgradeId) => void, onReroll: () => void) => {
    choiceList.innerHTML = state.choices.map((choice, index) => choiceButton(choice, index)).join("");
    choiceList.querySelectorAll<HTMLButtonElement>("button").forEach((button) => {
      button.addEventListener("click", () => onPick(button.dataset.upgradeId as UpgradeId));
    });
    rerollButton.disabled = state.rerolls <= 0;
    rerollButton.textContent = state.rerolls > 0 ? `Reroll Spark x${state.rerolls}` : "No Rerolls";
    rerollButton.onclick = state.rerolls > 0 ? onReroll : null;
    if (!levelDialog.open) levelDialog.showModal();
  };

  const hideLevelChoices = () => {
    if (levelDialog.open) levelDialog.close();
  };

  const showRunEnd = (state: GameState, outcome: "complete" | "gameover", onRestart: () => void) => {
    const summary = buildRunSummary(state, outcome);
    const previousRecords = loadRunRecords();
    const awards = [...buildRecordAwards(previousRecords, summary), ...buildRunAwards(state, outcome)]
      .sort((a, b) => b.score - a.score)
      .slice(0, 4);
    const records = mergeRunRecords(previousRecords, summary);
    saveRunRecords(records);

    restartCallback = onRestart;
    hideLevelChoices();
    endEyebrow.textContent = outcome === "complete" ? "Storm Cleared" : "Run Ended";
    endTitle.textContent = outcome === "complete" ? "Survived!" : "Try Again";
    endSubtitle.textContent =
      outcome === "complete"
        ? "That build had bite."
        : "The next power spike comes faster now that you know the swarm.";
    resultsBreakdown.innerHTML = `
      <div class="award-strip">${awards.map(runAward).join("")}</div>
      ${recordStrip(records)}
      <div class="result-row"><span>Level</span><strong>${state.player.level}</strong></div>
      <div class="result-row"><span>KOs</span><strong>${state.kills}</strong></div>
      <div class="result-row"><span>Caches opened</span><strong>${state.cachesOpened}</strong></div>
      <div class="result-row"><span>Catalyst caches</span><strong>${state.catalystCaches}</strong></div>
      <div class="result-row"><span>Cache evolutions</span><strong>${state.cacheEvolutions}</strong></div>
      <div class="result-row"><span>Elite caches</span><strong>${state.eliteKills}</strong></div>
      <div class="result-row"><span>Close calls</span><strong>${state.closeCalls}</strong></div>
      <div class="result-row"><span>Clutch bursts</span><strong>${state.clutch.bursts}</strong></div>
      <div class="result-row"><span>Best clutch</span><strong>${state.clutch.best}x</strong></div>
      <div class="result-row"><span>Recovery drops</span><strong>${state.recoveryDrops}</strong></div>
      <div class="result-row"><span>Rare+ picks</span><strong>${state.rarityFinds.rare + state.rarityFinds.epic}</strong></div>
      <div class="result-row"><span>Bounties</span><strong>${state.bountiesCleared}</strong></div>
      <div class="result-row"><span>Best bounty chain</span><strong>${state.bestBountyStreak}</strong></div>
      <div class="result-row"><span>Best flow</span><strong>${state.combo.best}x</strong></div>
      <div class="result-row"><span>Flow saves</span><strong>${state.flowSave.saves}</strong></div>
      <div class="result-row"><span>Best saved flow</span><strong>${state.flowSave.best}x</strong></div>
      <div class="result-row"><span>Boost scoops</span><strong>${state.boostScoops}</strong></div>
      <div class="result-row"><span>Perfect scoops</span><strong>${state.perfectScoops}</strong></div>
      <div class="result-row"><span>Snap boosts</span><strong>${state.snapBoosts}</strong></div>
      <div class="result-row"><span>Flow bursts</span><strong>${state.flowBursts}</strong></div>
      <div class="result-row"><span>Echo rushes</span><strong>${state.echoBursts}</strong></div>
      <div class="result-row"><span>Surge bursts</span><strong>${state.surgeBursts}</strong></div>
      <div class="result-row"><span>Dash threads</span><strong>${state.dashThreads}</strong></div>
      <div class="result-row"><span>Best thread</span><strong>${state.bestDashThread}x</strong></div>
      <div class="result-row"><span>Rerolls spent</span><strong>${state.rerollsUsed}</strong></div>
      <div class="result-row"><span>Second wind</span><strong>${state.secondWindUsed ? "Used" : "Ready"}</strong></div>
      <div class="result-row"><span>Evolutions</span><strong>${evolvedCount(state)}</strong></div>
      <div class="result-row"><span>Power</span><strong>${powerScore(state).toFixed(1)}x</strong></div>
      <div class="result-row"><span>Score</span><strong>${compactNumber(state.player.score)}</strong></div>
    `;
    if (!endDialog.open) endDialog.showModal();
  };

  const hideRunEnd = () => {
    if (endDialog.open) endDialog.close();
  };

  const show = () => { hud.style.opacity = "1"; hud.style.pointerEvents = "none"; };
  const hide = () => { hud.style.opacity = "0"; hud.style.pointerEvents = "none"; };

  function updateJoystick(event: PointerEvent) {
    const rect = joystick.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    const dx = event.clientX - centerX;
    const dy = event.clientY - centerY;
    const distance = Math.min(44, Math.hypot(dx, dy));
    const angle = Math.atan2(dy, dx);
    const x = Math.cos(angle) * distance;
    const y = Math.sin(angle) * distance;
    joystickVector = { x: x / 44, y: y / 44 };
    knob.style.transform = `translate(${x}px, ${y}px)`;
  }

  function resetJoystick() {
    activePointerId = null;
    joystickVector = { x: 0, y: 0 };
    knob.style.transform = "translate(0, 0)";
  }

  return { setState, consumeInput, showLevelChoices, hideLevelChoices, showRunEnd, hideRunEnd, show, hide };
};

const choiceButton = (choice: UpgradeChoice, index: number): string => `
  <button class="choice-card ${choice.rarity} ${willEvolve(choice) ? "evolve" : ""} ${nearEvolve(choice) ? "near-evolve" : ""}" type="button" data-upgrade-id="${choice.id}" style="--choice-color: ${choice.color}">
    <span class="choice-key">${index + 1}</span>
    <span class="choice-rarity">${choiceBadge(choice)}</span>
    <strong>${choice.title}</strong>
    <small>${choice.description}</small>
    <em><span>Rank ${choice.rank} -> ${Math.min(choice.maxRank, choice.rank + choice.rankGain)} / ${choice.maxRank}</span><b>${willEvolve(choice) ? "Evolve" : choice.rankGain > 1 ? `Surge +${choice.rankGain}` : "+1"}</b></em>
  </button>
`;

const willEvolve = (choice: UpgradeChoice): boolean => choice.rank < choice.maxRank && choice.rank + choice.rankGain >= choice.maxRank;
const nearEvolve = (choice: UpgradeChoice): boolean => choice.rank > 0 && !willEvolve(choice) && choice.maxRank - choice.rank <= 2;
const choiceBadge = (choice: UpgradeChoice): string => {
  if (willEvolve(choice)) return "evolve";
  if (nearEvolve(choice)) return `${choice.maxRank - choice.rank} to evolve`;
  return choice.rarity;
};

const buildBadges = (state: GameState): string => {
  const visible = (Object.entries(state.upgrades) as [UpgradeId, number][])
    .filter(([, rank]) => rank > 0)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 6);
  return visible.map(([id, rank]) => `<span class="${state.evolved[id] ? "evolved" : ""}">${upgradeTitle(id)} <strong>${state.evolved[id] ? "EV" : rank}</strong></span>`).join("");
};

const buildRunAwards = (state: GameState, outcome: "complete" | "gameover"): RunAward[] => {
  const rarePlus = state.rarityFinds.rare + state.rarityFinds.epic;
  const awards: RunAward[] = [
    outcome === "complete"
      ? { label: "Storm Clear", value: "Win", tone: "mint", score: 1000 }
      : { label: "Deepest Push", value: `L${state.player.level}`, tone: "cyan", score: state.player.level * 22 + state.elapsed * 0.18 }
  ];

  if (evolvedCount(state) > 0) awards.push({ label: "Evolved", value: `${evolvedCount(state)}`, tone: "gold", score: 180 + evolvedCount(state) * 70 });
  if (state.perfectScoops > 0) awards.push({ label: "Perfect Scoop", value: `${state.perfectScoops}`, tone: "gold", score: 150 + state.perfectScoops * 42 });
  if (state.snapBoosts >= 3) awards.push({ label: "Snap Boost", value: `${state.snapBoosts}`, tone: "gold", score: 142 + state.snapBoosts * 18 });
  if (state.clutch.bursts > 0) awards.push({ label: "Clutch Burst", value: `${state.clutch.bursts}`, tone: "cyan", score: 141 + state.clutch.bursts * 42 });
  if (state.recoveryDrops > 0) awards.push({ label: "Recovery", value: `${state.recoveryDrops}`, tone: "mint", score: 138 + state.recoveryDrops * 38 });
  if (state.cacheEvolutions > 0) awards.push({ label: "Cache Evolve", value: `${state.cacheEvolutions}`, tone: "gold", score: 220 + state.cacheEvolutions * 86 });
  if (state.catalystCaches > 0) awards.push({ label: "Catalyst", value: `${state.catalystCaches}`, tone: "cyan", score: 144 + state.catalystCaches * 40 });
  if (state.bestBountyStreak >= 2) awards.push({ label: "Bounty Chain", value: `${state.bestBountyStreak}`, tone: "gold", score: 140 + state.bestBountyStreak * 44 });
  if (state.bestDashThread >= 3) awards.push({ label: "Thread", value: `${state.bestDashThread}x`, tone: "cyan", score: 135 + state.bestDashThread * 14 });
  if (state.cachesOpened > 0) awards.push({ label: "Cache Rush", value: `${state.cachesOpened}`, tone: "gold", score: 132 + state.cachesOpened * 36 });
  if (state.echoBursts > 0) awards.push({ label: "Echo Rush", value: `${state.echoBursts}`, tone: "pink", score: 130 + state.echoBursts * 38 });
  if (state.flowBursts > 0) awards.push({ label: "Flow Burst", value: `${state.flowBursts}`, tone: "mint", score: 120 + state.flowBursts * 36 });
  if (state.flowSave.saves > 0) awards.push({ label: "Flow Save", value: `${state.flowSave.saves}`, tone: "cyan", score: 118 + state.flowSave.saves * 34 });
  if (rarePlus > 0) awards.push({ label: "Rare+", value: `${rarePlus}`, tone: "pink", score: 105 + rarePlus * 32 });
  if (state.secondWindUsed) awards.push({ label: "Second Wind", value: "Used", tone: "pink", score: 96 });

  return awards.sort((a, b) => b.score - a.score).slice(0, 4);
};

const runAward = (award: RunAward): string => `
  <span class="run-award ${award.tone}">
    <em>${award.label}</em>
    <strong>${award.value}</strong>
  </span>
`;

const RUN_RECORDS_KEY = "shape-storm-records-v1";

const EMPTY_RUN_RECORDS: RunRecords = {
  runs: 0,
  wins: 0,
  score: 0,
  level: 0,
  kills: 0,
  power: 0,
  flow: 0,
  flowSaves: 0,
  bounty: 0,
  clutch: 0,
  catalyst: 0,
  cacheEvolve: 0,
  evolved: 0,
  rarePlus: 0,
  time: 0
};

const buildRunSummary = (state: GameState, outcome: "complete" | "gameover"): RunSummary => ({
  score: state.player.score,
  level: state.player.level,
  kills: state.kills,
  power: Number(powerScore(state).toFixed(1)),
  flow: state.combo.best,
  flowSaves: state.flowSave.saves,
  bounty: state.bestBountyStreak,
  clutch: state.clutch.best,
  catalyst: state.catalystCaches,
  cacheEvolve: state.cacheEvolutions,
  evolved: evolvedCount(state),
  rarePlus: state.rarityFinds.rare + state.rarityFinds.epic,
  time: Math.floor(state.elapsed),
  win: outcome === "complete"
});

const loadRunRecords = (): RunRecords => {
  if (typeof localStorage === "undefined") return { ...EMPTY_RUN_RECORDS };

  try {
    const raw = localStorage.getItem(RUN_RECORDS_KEY);
    if (!raw) return { ...EMPTY_RUN_RECORDS };

    const parsed = JSON.parse(raw) as Partial<Record<keyof RunRecords, unknown>>;
    return {
      runs: wholeRecord(parsed.runs),
      wins: wholeRecord(parsed.wins),
      score: wholeRecord(parsed.score),
      level: wholeRecord(parsed.level),
      kills: wholeRecord(parsed.kills),
      power: numberRecord(parsed.power),
      flow: wholeRecord(parsed.flow),
      flowSaves: wholeRecord(parsed.flowSaves),
      bounty: wholeRecord(parsed.bounty),
      clutch: wholeRecord(parsed.clutch),
      catalyst: wholeRecord(parsed.catalyst),
      cacheEvolve: wholeRecord(parsed.cacheEvolve),
      evolved: wholeRecord(parsed.evolved),
      rarePlus: wholeRecord(parsed.rarePlus),
      time: wholeRecord(parsed.time)
    };
  } catch {
    return { ...EMPTY_RUN_RECORDS };
  }
};

const saveRunRecords = (records: RunRecords) => {
  if (typeof localStorage === "undefined") return;

  try {
    localStorage.setItem(RUN_RECORDS_KEY, JSON.stringify(records));
  } catch {
    // Storage can be disabled in private or embedded browser contexts.
  }
};

const mergeRunRecords = (records: RunRecords, summary: RunSummary): RunRecords => ({
  runs: records.runs + 1,
  wins: records.wins + (summary.win ? 1 : 0),
  score: Math.max(records.score, summary.score),
  level: Math.max(records.level, summary.level),
  kills: Math.max(records.kills, summary.kills),
  power: Math.max(records.power, summary.power),
  flow: Math.max(records.flow, summary.flow),
  flowSaves: Math.max(records.flowSaves, summary.flowSaves),
  bounty: Math.max(records.bounty, summary.bounty),
  clutch: Math.max(records.clutch, summary.clutch),
  catalyst: Math.max(records.catalyst, summary.catalyst),
  cacheEvolve: Math.max(records.cacheEvolve, summary.cacheEvolve),
  evolved: Math.max(records.evolved, summary.evolved),
  rarePlus: Math.max(records.rarePlus, summary.rarePlus),
  time: Math.max(records.time, summary.time)
});

const buildRecordAwards = (records: RunRecords, summary: RunSummary): RunAward[] => {
  if (records.runs === 0) {
    return [
      { label: "First Mark", value: compactNumber(summary.score), tone: "gold", score: 480 },
      ...(summary.win ? [{ label: "First Clear", value: "Win", tone: "mint" as const, score: 520 }] : [])
    ];
  }

  const awards: RunAward[] = [];
  if (summary.win && records.wins === 0) awards.push({ label: "First Clear", value: "Win", tone: "mint", score: 560 });
  if (summary.score > records.score) awards.push({ label: "Best Score", value: compactNumber(summary.score), tone: "gold", score: 540 });
  if (summary.level > records.level) awards.push({ label: "Best Level", value: `L${summary.level}`, tone: "cyan", score: 500 });
  if (summary.power > records.power) awards.push({ label: "Best Power", value: `${summary.power.toFixed(1)}x`, tone: "gold", score: 470 });
  if (summary.clutch > records.clutch) awards.push({ label: "Best Clutch", value: `${summary.clutch}x`, tone: "cyan", score: 450 });
  if (summary.flow > records.flow) awards.push({ label: "Best Flow", value: `${summary.flow}x`, tone: "mint", score: 430 });
  if (summary.flowSaves > records.flowSaves) awards.push({ label: "Best Saves", value: `${summary.flowSaves}`, tone: "cyan", score: 425 });
  if (summary.cacheEvolve > records.cacheEvolve) awards.push({ label: "Best Cache EV", value: `${summary.cacheEvolve}`, tone: "gold", score: 420 });
  if (summary.catalyst > records.catalyst) awards.push({ label: "Best Catalyst", value: `${summary.catalyst}`, tone: "cyan", score: 415 });
  if (summary.bounty > records.bounty) awards.push({ label: "Best Bounty", value: `${summary.bounty}`, tone: "pink", score: 410 });
  if (summary.rarePlus > records.rarePlus) awards.push({ label: "Best Rare+", value: `${summary.rarePlus}`, tone: "pink", score: 390 });
  return awards;
};

const recordStrip = (records: RunRecords): string => `
  <div class="record-strip">
    ${recordPill("Best Score", compactNumber(records.score))}
    ${recordPill("Best Level", `L${records.level}`)}
    ${recordPill("Best Flow", `${records.flow}x`)}
    ${recordPill("Wins", `${records.wins}/${records.runs}`)}
  </div>
`;

const recordPill = (label: string, value: string): string => `
  <span class="record-pill">
    <em>${label}</em>
    <strong>${value}</strong>
  </span>
`;

const numberRecord = (value: unknown): number => (typeof value === "number" && Number.isFinite(value) ? Math.max(0, value) : 0);
const wholeRecord = (value: unknown): number => Math.floor(numberRecord(value));

const idleTip = (state: GameState): string => {
  if (state.bounty) return `Bounty: ${state.bounty.title}. ${state.bounty.hint}`;
  if (flowSaveProgress(state) > 0) return "Flow Save! Grab any shard now.";
  if (state.player.hp <= 2 && state.pickups.some((pickup) => pickup.kind === "heart")) return "Recovery heart nearby. Sweep toward it.";
  if (state.clutch.timer > 0 && state.clutch.count >= 2) return `Clutch chain ${state.clutch.count}x. Stay sharp.`;
  if (!state.secondWindUsed && state.player.hp <= 2) return "Second Wind is ready if things go sideways.";
  if (state.powerEcho > 0 && echoBurstProgress(state) >= 0.72) return "Echo Rush is close. Sweep shards now.";
  if (state.powerEcho > 0) return "Power Echo is live. Sweep shards to burst.";
  if (surgeReady(state)) return "Surge ready. Boost through the swarm.";
  if (flowRush(state) > 0) return "Flow Rush is live. Keep sweeping.";
  if (state.player.boostQueued) return "Boost queued. Hold your line.";
  if (snapBoostWindowProgress(state) > 0) return "Boost is almost ready. Press now to Snap Boost.";
  if (state.pickups.some((pickup) => pickup.kind === "cache")) return "Cache nearby. Grab it for a power spike.";
  if (threatProgress(state) >= 0.78) return "Threat is high. Use Boost before the ring closes.";
  if (state.player.dashCooldown <= 0) return "Boost is ready.";
  if (state.pickups.length > 12) return "Sweep through shards for the next level-up.";
  return "Stay near XP, not inside the swarm.";
};

const compactNumber = (value: number): string => {
  if (value >= 1000000) return `${(value / 1000000).toFixed(1)}m`;
  if (value >= 10000) return `${Math.round(value / 1000)}k`;
  if (value >= 1000) return `${(value / 1000).toFixed(1)}k`;
  return `${Math.round(value)}`;
};

const formatTime = (seconds: number): string => {
  const totalSeconds = Math.ceil(Math.max(0, seconds));
  const minutes = Math.floor(totalSeconds / 60);
  const remaining = totalSeconds % 60;
  return `${minutes}:${remaining.toString().padStart(2, "0")}`;
};
