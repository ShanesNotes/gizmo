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
   recompute, keep mutation-proofing). The probe's player side is synthetic by design, while
   live ceremonies and integration gates cover the real ability path.
3. Director wave budgets: bruiser/elite counts per tier so room TTK lands ~20–40s for
   combat rooms (Hades pacing), elite_arena noticeably harder.
4. Red-first: per-archetype TTK band tests at real swing cadence (kit numbers cited).

## Fence
enemies/ (archetypes, enemy, brain), room_director.gd (wave budgets), the survivability
probe in run_orchestrator_tests.gd, enemy/director suites. NOT abilities/vitals/HUD if
HZ-103 still in flight — sequence after it merges.

## Live evidence appendix (2026-07-06 ceremonies, post HZ-073)
- Single chaff in contact melts the full 10-pip guard in roughly 5 seconds; three chasers
  kill in ~2-3s of contact. Every unassisted live run ended in death (0:14 → 0:41 → 0:32
  across tuning states); nobody has survived past room 2 without script assistance.
- Attacks one-shot everything (melee [18,20,26] vs HP 1/4) — no combat texture.
- Spark charge from damage dealt reached only 15% after 3 kills; guard damage charges much
  faster — verify the intended Hades ratio (taking hits charges faster) still holds after
  rebalance rather than degenerating into "only getting hit charges the gauge".
- Pacing target confirmed: cautious player clears ≥3 rooms; combat rooms ~20-40s; death
  should come from mistakes, not contact-DPS melt.
