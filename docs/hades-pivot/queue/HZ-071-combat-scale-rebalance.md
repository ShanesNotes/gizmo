# HZ-071 — Combat scale rebalance (TTK bands unreachable)

**Status:** ready-for-agent · **Worker:** Codex · **Deps:** HZ-103 (fence overlap: vitals/enemies/abilities)
**Source:** Fable strategic gate 2026-07-06 (flag raised during HZ-070 corrections).

Melee kit damage `[18, 20, 26]` vs archetype HP `chaff 1.0 / bruiser 4.0`: every enemy is
one-shot. Balance ref §5.4 bands — trash ≤0.5s (a hit or two), **bruiser 1–3s, elite
3–10s** — are unreachable; combat has no target-priority texture, boons that add damage
change nothing perceptible.

## Scope
1. Rebase enemy HP pools onto the melee kit's scale (trash ~1–2 hits, bruiser ~4–7 hits
   / 1–3s at real swing cadence, and add an **elite** archetype in the 3–10s band for
   elite_arena rooms). Keep contact damage per ADR-0007 guard model.
2. Re-tune the survivability probe bands (the DPS-model probe from HZ-070 will shift —
   recompute, keep mutation-proofing).
3. Director wave budgets: bruiser/elite counts per tier so room TTK lands ~20–40s for
   combat rooms (Hades pacing), elite_arena noticeably harder.
4. Red-first: per-archetype TTK band tests at real swing cadence (kit numbers cited).

## Fence
enemies/ (archetypes, enemy, brain), room_director.gd (wave budgets), the survivability
probe in run_orchestrator_tests.gd, enemy/director suites. NOT abilities/vitals/HUD if
HZ-103 still in flight — sequence after it merges.
