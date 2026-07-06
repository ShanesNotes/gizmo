# HZ-075 — THE CUSTODIAN: first boss encounter

**Status:** ready-for-agent · **Worker:** Codex (expect /decompose) · **Deps:** HZ-074
**Design authority (binding):** `docs/hades-pivot/design/boss-custodian.md` — the full
fight design: HP 2400, phase ladder 75/50/25, attack roster with telegraph table,
boss-owned adds through the orchestrator's existing spawn machinery, weighted-random
no-repeat attack selection, ceremony via the shipped run_completed path.
**Grounding:** `docs/hades-pivot/research/boss-structure-reference.md`.

## Slices (decompose along these seams)
1. **TelegraphMarker primitive** — one reusable scene (disc/line, exported color/shape/
   pulse, lifetime) + tests. No boss dependency; other systems may reuse it.
2. **BossBrain** (headless-testable): phase machine on HP thresholds → attack picker
   (weights, cooldowns, no-immediate-repeat) → attack execution states (windup→commit→
   recover); emits add_wave_requested(requests) in the RoomDirector request shape;
   deterministic under seeded RNG. Full red-first battery (phase transitions, unlock
   ladder, no-repeat, add waves exactly-once per threshold).
3. **custodian_boss.gd + boss node in boss_arena.tscn**: CharacterBody3D, vitals at boss
   scale, no chase-contact loop, reports died(spawn_id) through the existing ledger; slow
   reposition behavior; attack execution drives TelegraphMarkers + damage application via
   orchestrator seams.
4. **Orchestrator boss-room integration**: boss room seals doors until boss death, boss
   death → room clear → run_completed (spec §2.5 — NO reward step), adds spawn through
   the existing telegraphed/separated spawn path, intro nameplate + brief camera hold.
5. **Integration gate**: full run ending in a real boss fight driven by the DPS model —
   victory ceremony fires; boss TTK inside 10–60s band; adds ledger consistent; death
   during boss fight tears down cleanly.

## Fence
NEW files (boss_brain.gd, custodian_boss.gd, telegraph_marker.*), boss_arena.tscn,
run_orchestrator.gd (boss-room integration region), suites: new run_boss_tests.gd +
orchestrator + integration_gate. NOT enemies/ (reuse via request shape only), director,
player, boons, hud internals.
