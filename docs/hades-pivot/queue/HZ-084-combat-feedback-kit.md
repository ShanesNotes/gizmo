# HZ-084 — Combat feedback kit (Fable-owned: the hardest feel problem)

**Status:** ready · **Worker:** FABLE (principal implements; Shane's directive 2026-07-06)
**Source:** director's playthrough — Surge staggered three enemies and the screen did not
change. Every combat event needs a read within one frame, greybox-budget only (materials,
tweens, one ring mesh — no particles yet, no shaders beyond StandardMaterial emission).

## The kit (exact spec)
1. **Hit flash** — on `take_damage` (enemy AND boss): albedo/emission pulse to white-hot,
   0.08s up / 0.12s down (tween, PROCESS_MODE always-safe). One helper on GreyboxEnemy so
   the Custodian inherits it.
2. **Death pop** — on enemy death: scale-Y squash to 0.05 + fade over 0.22s, then free
   (replaces the current instant vanish). Must not disturb the kill ledger timing (death
   signal fires first; the pop is cosmetic on a corpse node).
3. **Surge burst ring** — on surge fire: one expanding torus/disc mesh from the player,
   radius 0→surge radius over 0.25s, emission amber fading out; reuses TelegraphMarker's
   material idiom (or the marker scene itself with a "burst" mode).
4. **Stagger read** — staggered enemies tilt 12° and desaturate (albedo × 0.6) for the
   stagger duration; restores on recovery.
5. **Melee swing read** — a 0.1s forward arc-wedge flash from the player on attack commit
   (same primitive family as the burst ring, narrow arc shape) so whiffs are legible too.
6. **Guard hit read (player)** — the existing HUD pips flash the lost pip red for 0.2s
   (HUD-side, payload carries a `guard_delta` hint or the HUD diffs its last state).

## Constraints
- All cosmetic: zero gameplay-state writes from any effect; ledger/vitals timing untouched.
- Headless-safe: every effect no-ops cleanly without a viewport (guard `DisplayServer`/
  tree checks not required if effects are pure scene-tree tweens — verify suites stay green).
- Boss inherits 1/2/4 automatically via GreyboxEnemy; the burst/swing primitives live
  beside telegraph_marker.gd as one effects family.

## Acceptance
Suites all green (effects are cosmetic); live ceremony shows: hit flash on every landed
swing, death pops, a visible surge ring, readable stagger, pip flash on guard damage.
