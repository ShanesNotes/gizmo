// sfx.ts — WebAudio oscillator SFX for Asteroid Defense, no asset files required

let _muted = false;
let _ctx: AudioContext | null = null;

const ctx = (): AudioContext => {
  if (!_ctx) _ctx = new AudioContext();
  return _ctx;
};

export const setMute = (muted: boolean): void => { _muted = muted; };
export const isMuted = (): boolean => _muted;

/** Short UI blip */
export const blip = (freq = 880, duration = 0.06): void => {
  if (_muted) return;
  const c = ctx();
  const osc = c.createOscillator();
  const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "square";
  osc.frequency.setValueAtTime(freq, c.currentTime);
  osc.frequency.exponentialRampToValueAtTime(freq * 1.4, c.currentTime + duration * 0.5);
  gain.gain.setValueAtTime(0.18, c.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, c.currentTime + duration);
  osc.start(c.currentTime); osc.stop(c.currentTime + duration);
};

/** Spark shot — fast yellow zap */
export const shootSpark = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(900, now);
  osc.frequency.exponentialRampToValueAtTime(300, now + 0.08);
  gain.gain.setValueAtTime(0.28, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
  osc.start(now); osc.stop(now + 0.1);
};

/** Bubble shot — big slow whomp */
export const shootBubble = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "sine";
  osc.frequency.setValueAtTime(220, now);
  osc.frequency.exponentialRampToValueAtTime(110, now + 0.28);
  gain.gain.setValueAtTime(0.0, now);
  gain.gain.linearRampToValueAtTime(0.32, now + 0.04);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.32);
  osc.start(now); osc.stop(now + 0.35);
};

/** Magnet shot — homing arc swoosh */
export const shootMagnet = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const osc2 = c.createOscillator();
  const gain = c.createGain();
  osc.connect(gain); osc2.connect(gain); gain.connect(c.destination);
  osc.type = "triangle";
  osc.frequency.setValueAtTime(440, now);
  osc.frequency.exponentialRampToValueAtTime(880, now + 0.22);
  osc2.type = "sine";
  osc2.frequency.setValueAtTime(660, now + 0.05);
  osc2.frequency.exponentialRampToValueAtTime(330, now + 0.22);
  gain.gain.setValueAtTime(0.22, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.26);
  osc.start(now); osc.stop(now + 0.26);
  osc2.start(now + 0.05); osc2.stop(now + 0.26);
};

/** Hit — chunky crack */
export const hit = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "square";
  osc.frequency.setValueAtTime(160, now);
  osc.frequency.exponentialRampToValueAtTime(60, now + 0.1);
  gain.gain.setValueAtTime(0.3, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
  osc.start(now); osc.stop(now + 0.12);
};

/** Explosion — satisfying boom */
export const explode = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const osc2 = c.createOscillator();
  const gain = c.createGain();
  osc.connect(gain); osc2.connect(gain); gain.connect(c.destination);
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(200, now);
  osc.frequency.exponentialRampToValueAtTime(30, now + 0.5);
  osc2.type = "square";
  osc2.frequency.setValueAtTime(110, now);
  osc2.frequency.exponentialRampToValueAtTime(40, now + 0.4);
  gain.gain.setValueAtTime(0.4, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.55);
  osc.start(now); osc.stop(now + 0.55);
  osc2.start(now); osc2.stop(now + 0.45);
};

/** Mini-boss explosion — HUGE low rumble */
export const bossExplode = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  for (let i = 0; i < 3; i++) {
    const delay = i * 0.07;
    const osc = c.createOscillator(); const gain = c.createGain();
    osc.connect(gain); gain.connect(c.destination);
    osc.type = "sawtooth";
    osc.frequency.setValueAtTime(180 - i * 40, now + delay);
    osc.frequency.exponentialRampToValueAtTime(20, now + delay + 0.8);
    gain.gain.setValueAtTime(0.5, now + delay);
    gain.gain.exponentialRampToValueAtTime(0.001, now + delay + 0.9);
    osc.start(now + delay); osc.stop(now + delay + 0.9);
  }
};

/** Item get — Zelda-style jingle */
export const itemGet = (): void => {
  if (_muted) return;
  const c = ctx();
  const notes = [523, 659, 784, 1047, 1319, 1047, 1319];
  const times = [0, 0.08, 0.16, 0.24, 0.32, 0.44, 0.52];
  notes.forEach((freq, i) => {
    const now = c.currentTime + times[i];
    const osc = c.createOscillator(); const gain = c.createGain();
    osc.connect(gain); gain.connect(c.destination);
    osc.type = i >= 4 ? "triangle" : "square";
    osc.frequency.setValueAtTime(freq, now);
    gain.gain.setValueAtTime(0.0, now);
    gain.gain.linearRampToValueAtTime(0.2, now + 0.02);
    gain.gain.setValueAtTime(0.2, now + 0.06);
    gain.gain.exponentialRampToValueAtTime(0.001, now + (i >= 4 ? 0.22 : 0.1));
    osc.start(now); osc.stop(now + 0.3);
  });
};

/** Shield hit — OUCH */
export const shieldHit = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(300, now);
  osc.frequency.exponentialRampToValueAtTime(80, now + 0.2);
  gain.gain.setValueAtTime(0.38, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);
  osc.start(now); osc.stop(now + 0.25);
};

/** Mission fanfare — ascending arpeggio */
export const fanfare = (): void => {
  if (_muted) return;
  const c = ctx();
  const notes = [523, 659, 784, 1047, 1319];
  notes.forEach((freq, i) => {
    const delay = i * 0.09;
    const now = c.currentTime + delay;
    const osc = c.createOscillator(); const gain = c.createGain();
    osc.connect(gain); gain.connect(c.destination);
    osc.type = i === notes.length - 1 ? "triangle" : "square";
    osc.frequency.setValueAtTime(freq, now);
    gain.gain.setValueAtTime(0.0, now);
    gain.gain.linearRampToValueAtTime(0.22, now + 0.03);
    gain.gain.setValueAtTime(0.22, now + 0.1);
    gain.gain.exponentialRampToValueAtTime(0.001, now + (i === notes.length - 1 ? 0.45 : 0.14));
    osc.start(now); osc.stop(now + 0.5);
  });
};

/** Single star blip for results tally */
export const starBlip = (index: number): void => {
  if (_muted) return;
  const freqs = [784, 988, 1175];
  blip(freqs[index] ?? 880, 0.1);
};

/** Countdown blip — pass 3/2/1 for ticks, 0 for GO */
export const countdownBlip = (n: number): void => {
  if (_muted) return;
  blip(n === 0 ? 1320 : 440, n === 0 ? 0.18 : 0.08);
};

/** Low dramatic rumble for mini-boss */
export const bossRumble = (): void => {
  if (_muted) return;
  const c = ctx(); const now = c.currentTime;
  const osc = c.createOscillator(); const gain = c.createGain();
  osc.connect(gain); gain.connect(c.destination);
  osc.type = "sawtooth";
  osc.frequency.setValueAtTime(55, now);
  osc.frequency.setValueAtTime(65, now + 0.15);
  osc.frequency.setValueAtTime(50, now + 0.3);
  gain.gain.setValueAtTime(0.0, now);
  gain.gain.linearRampToValueAtTime(0.28, now + 0.1);
  gain.gain.setValueAtTime(0.28, now + 0.5);
  gain.gain.exponentialRampToValueAtTime(0.001, now + 0.9);
  osc.start(now); osc.stop(now + 0.9);
};
