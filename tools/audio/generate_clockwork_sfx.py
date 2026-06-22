#!/usr/bin/env python3
"""Generate first-level clockwork/brass SFX for Gizmo.

The goal is intentionally small and reproducible: grounded mechanical one-shots
that keep the existing Godot event paths stable while replacing arcade beeps.
"""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44_100
OUT_DIR = Path("godot/audio/sfx")


def make_buffer(duration: float) -> list[float]:
    return [0.0 for _ in range(int(duration * SAMPLE_RATE))]


def clamp01(value: float) -> float:
    return 0.0 if value < 0.0 else 1.0 if value > 1.0 else value


def percussive_env(t: float, duration: float, attack: float = 0.006, decay_power: float = 3.0) -> float:
    if t < 0.0 or t > duration:
        return 0.0
    attack_gain = clamp01(t / max(attack, 0.0001))
    decay_gain = max(0.0, 1.0 - (t / max(duration, 0.0001))) ** decay_power
    return attack_gain * decay_gain


def smooth_env(t: float, duration: float, attack: float = 0.02, release: float = 0.08) -> float:
    if t < 0.0 or t > duration:
        return 0.0
    a = clamp01(t / max(attack, 0.0001))
    r = clamp01((duration - t) / max(release, 0.0001))
    return min(a, r)


def add_tone(
    buf: list[float],
    start: float,
    duration: float,
    freq: float,
    amp: float,
    *,
    freq_end: float | None = None,
    attack: float = 0.004,
    decay_power: float = 2.5,
    pan_lfo: float = 0.0,
) -> None:
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buf), int((start + duration) * SAMPLE_RATE))
    if end_i <= start_i:
        return
    phase = 0.0
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        local = t / max(duration, 0.0001)
        f = freq + ((freq_end if freq_end is not None else freq) - freq) * local
        phase += (2.0 * math.pi * f) / SAMPLE_RATE
        overtone = 0.32 * math.sin(phase * 2.01) + 0.12 * math.sin(phase * 3.97)
        shimmer = 1.0 + pan_lfo * math.sin(2.0 * math.pi * 11.0 * t)
        buf[i] += amp * percussive_env(t, duration, attack, decay_power) * shimmer * (math.sin(phase) + overtone)


def add_bell(
    buf: list[float],
    start: float,
    duration: float,
    base_freq: float,
    amp: float,
    *,
    brightness: float = 1.0,
) -> None:
    partials = [1.0, 2.01, 2.72, 3.93, 5.44]
    gains = [1.0, 0.38, 0.26, 0.16, 0.08]
    for partial, gain in zip(partials, gains):
        add_tone(
            buf,
            start,
            duration * (0.85 + 0.1 / partial),
            base_freq * partial,
            amp * gain * brightness,
            attack=0.0025,
            decay_power=2.0 + partial * 0.2,
            pan_lfo=0.015,
        )


def add_noise_burst(
    buf: list[float],
    start: float,
    duration: float,
    amp: float,
    *,
    seed: int,
    attack: float = 0.003,
    decay_power: float = 4.0,
    lowpass: float = 0.18,
    highpass: float = 0.02,
) -> None:
    rng = random.Random(seed)
    start_i = max(0, int(start * SAMPLE_RATE))
    end_i = min(len(buf), int((start + duration) * SAMPLE_RATE))
    low = 0.0
    slow = 0.0
    for i in range(start_i, end_i):
        t = (i - start_i) / SAMPLE_RATE
        white = rng.uniform(-1.0, 1.0)
        low += lowpass * (white - low)
        slow += highpass * (low - slow)
        band = low - slow
        buf[i] += amp * percussive_env(t, duration, attack, decay_power) * band


def add_tick_cluster(buf: list[float], times: list[float], *, seed: int, amp: float = 0.22) -> None:
    rng = random.Random(seed)
    for n, t in enumerate(times):
        freq = rng.choice([760.0, 910.0, 1180.0, 1460.0, 1880.0]) * rng.uniform(0.92, 1.08)
        add_bell(buf, t, rng.uniform(0.08, 0.18), freq, amp * rng.uniform(0.55, 1.0), brightness=0.65)
        add_noise_burst(buf, t, rng.uniform(0.035, 0.07), amp * 0.18, seed=seed + n * 19, decay_power=5.0)


def add_body_thump(buf: list[float], start: float, amp: float = 0.42, freq: float = 120.0) -> None:
    add_tone(buf, start, 0.22, freq, amp, freq_end=freq * 0.62, attack=0.002, decay_power=3.8)
    add_tone(buf, start + 0.004, 0.18, freq * 1.8, amp * 0.34, freq_end=freq * 1.15, attack=0.002, decay_power=4.4)


def soft_clip_and_normalize(buf: list[float], target_peak: float = 0.76) -> list[float]:
    clipped = [math.tanh(sample * 1.18) for sample in buf]
    peak = max(max(clipped), -min(clipped), 0.0001)
    gain = target_peak / peak
    out = [sample * gain for sample in clipped]
    fade = min(len(out) // 3, int(0.006 * SAMPLE_RATE))
    for i in range(fade):
        g = i / max(fade, 1)
        out[i] *= g
        out[-i - 1] *= g
    return out


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    final = soft_clip_and_normalize(samples)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for sample in final:
            value = max(-1.0, min(1.0, sample))
            frames.extend(struct.pack("<h", int(value * 32767)))
        wav.writeframes(bytes(frames))


def build_attack() -> list[float]:
    buf = make_buffer(0.34)
    add_noise_burst(buf, 0.000, 0.055, 0.20, seed=101, decay_power=5.5, lowpass=0.34)
    add_bell(buf, 0.006, 0.18, 1280.0, 0.20, brightness=0.78)
    add_tone(buf, 0.025, 0.24, 690.0, 0.34, freq_end=360.0, attack=0.006, decay_power=2.4, pan_lfo=0.025)
    add_tone(buf, 0.046, 0.27, 240.0, 0.22, freq_end=212.0, attack=0.012, decay_power=2.1)
    add_tick_cluster(buf, [0.018, 0.052, 0.091], seed=111, amp=0.105)
    return buf


def build_hit() -> list[float]:
    buf = make_buffer(0.28)
    add_body_thump(buf, 0.000, amp=0.54, freq=104.0)
    add_noise_burst(buf, 0.004, 0.15, 0.34, seed=202, decay_power=3.1, lowpass=0.11, highpass=0.012)
    add_bell(buf, 0.010, 0.20, 390.0, 0.24, brightness=0.5)
    add_bell(buf, 0.020, 0.12, 820.0, 0.12, brightness=0.42)
    add_tick_cluster(buf, [0.027, 0.074], seed=222, amp=0.08)
    return buf


def build_defeat() -> list[float]:
    buf = make_buffer(0.82)
    add_body_thump(buf, 0.000, amp=0.38, freq=96.0)
    add_tone(buf, 0.040, 0.62, 520.0, 0.23, freq_end=146.0, attack=0.018, decay_power=1.9, pan_lfo=0.04)
    add_noise_burst(buf, 0.026, 0.54, 0.28, seed=303, attack=0.018, decay_power=2.1, lowpass=0.075, highpass=0.006)
    add_tick_cluster(buf, [0.055, 0.092, 0.137, 0.193, 0.278, 0.363, 0.491], seed=333, amp=0.13)
    add_bell(buf, 0.18, 0.50, 245.0, 0.16, brightness=0.45)
    return buf


def build_pickup() -> list[float]:
    buf = make_buffer(0.38)
    add_tick_cluster(buf, [0.000], seed=444, amp=0.08)
    add_bell(buf, 0.018, 0.28, 1320.0, 0.28, brightness=0.78)
    add_bell(buf, 0.055, 0.25, 1760.0, 0.16, brightness=0.68)
    add_tone(buf, 0.020, 0.22, 520.0, 0.12, freq_end=840.0, attack=0.012, decay_power=2.8)
    add_noise_burst(buf, 0.012, 0.18, 0.08, seed=404, attack=0.01, decay_power=3.6, lowpass=0.24)
    return buf


def build_levelup() -> list[float]:
    buf = make_buffer(1.05)
    add_noise_burst(buf, 0.000, 0.32, 0.09, seed=505, attack=0.035, decay_power=2.0, lowpass=0.08)
    notes = [392.0, 493.88, 587.33, 783.99]
    for idx, note in enumerate(notes):
        start = 0.05 + idx * 0.135
        add_bell(buf, start, 0.46, note, 0.22 - idx * 0.015, brightness=0.55)
        add_tick_cluster(buf, [start - 0.015], seed=550 + idx, amp=0.055)
    add_tone(buf, 0.12, 0.78, 196.0, 0.16, freq_end=220.0, attack=0.08, decay_power=1.6, pan_lfo=0.02)
    add_bell(buf, 0.62, 0.35, 987.77, 0.08, brightness=0.48)
    return buf


def main() -> None:
    builders = {
        "spark_attack.wav": build_attack,
        "spark_hit.wav": build_hit,
        "spark_defeat.wav": build_defeat,
        "spark_pickup.wav": build_pickup,
        "spark_levelup.wav": build_levelup,
    }
    for name, builder in builders.items():
        path = OUT_DIR / name
        write_wav(path, builder())
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
