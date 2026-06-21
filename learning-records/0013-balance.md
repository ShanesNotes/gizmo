# 0013 — Balance: make the run lethal

**Date:** 2026-06-20
**Lesson:** `lessons/0013-balance.html`
**Mode:** **user/Codex-built prototype → Claude reviewed → user hardened → Claude verified & captured.**
The learner implemented the balance prototype + harness, handed it off; Claude adversarially
reviewed it, the learner took path (a) and hardened the harness, Claude re-verified and committed.
**Status:** DRAFT (prototype balance verified by deterministic sim profiles; live playtest pending)

## What was built
A metric-driven balance pass so the v1 run is naturally survivable **and** lethal (no debug keys),
grounded in `reference/game-balance-reference.md`. Scoped to `simulation.gd` + `run_balance_tests.gd`.
- **Enemy roles, rules-only, no waves** (`simulation.ts:259`): nibbler / dasher (30s) / brute (66s) /
  warden (98s) — same chaser logic, different stats, time-gated. The director saves budget for pricier
  roles (`simulation.ts:684`) instead of always defaulting to nibblers. Continuous pressure with
  variety (ADR 0003), not discrete rounds.
- **Survivable + lethal**: `BUDGET_BASE 0.45→0.9`, `BUDGET_PRESSURE_GAIN 9.5→10.5` (more early threat,
  §5.3); `CONTACT_KNOCKBACK 1.35` anti-death-spiral on real hits only (§3.4); `PICKUP_RADIUS 1.8→2.4`
  (§6.2); prototype **Spark Chain** level scaling (canon weapon, `simulation.ts:267`) — more targets,
  floored cooldown, +damage every 3 levels — a **temporary** stand-in until the Core Matrix /
  upgrade-choice system (ADR 0001); combat seam unchanged so it's swappable.
- **Telemetry**: `kills`, `spawned_count`, `spawned_by_kind` (§6.1).

## Verified (implementation)
- `run_balance_tests.gd` → **PASS — 32**; full suite still green (sim 69 · hud 8 · end 6 · controller 10);
  `--check-only` clean on `simulation.gd` + the harness.
- godot-runtime MCP residue guard: `project.godot` diff empty, no `mcp_bridge.gd*`.
- Pinned outcomes: stationary loses ~55s (first damage ~46s); mistake-kite loses ~187s (first hit ~75s);
  decent true-speed kite wins with HP remaining (2–6 damage events); 60s probe: 116 spawns / 102 kills /
  26 dashers. TTK: trash 0.55s, brute 2.05s, warden 1.55s.

## Review → harden (the teaching beat: "tests pass" ≠ "tests verify")
Claude's adversarial review (5-agent workflow) PASSED reference-alignment and no-waves/canon, found the
combat refactor correct (one cosmetic nit), but **FAILED the test harness on rigor**: `damage_events == 7`
was tautological (max_hp=7 ⇒ guaranteed), bands were ±11% loose, the mistake-kite margin was brittle, and
the "competent kite" win used a near-**optimal** omniscient avoider — so it proved "an optimal player can
win", not the stated criterion "win possible with **decent** play". (A second FAIL — file isolation — was a
false positive: the verifier conflated the user's parallel art-stream dirt; the 0013 diff is confined to
`simulation.gd` + the harness.)

The learner took **path (a)** and hardened the harness to a real regression guard:
- decent-kite now uses **true 6.0 m/s, 5.5 m sensing, 0.2 s reaction lag, wall bounce** — a fair
  competent-human proxy, not a robot;
- replaced the tautological check with a **one-shot/chip guard** (`max_hit_delta <= 1`, §3.4);
- added a **tuning-sensitive 60s pressure probe** (spawn/kill/max-alive/dasher bands that move with
  `BUDGET_*`);
- tightened TTK + mistake-kite bands;
- renamed the cosmetic local `floor` → `min_cooldown`.

## What the slice covers (to confirm with the learner)
Metric-driven tuning (target curve from the reference *before* touching constants); rules-only enemy
roles vs visuals; director budget priority for pricier roles; one-shot control via knockback; the
distinction between **tests that pass** and **tests that verify** (deterministic regression proxies); and
why this is a **prototype**, not final balance.

## Honest status & what's NOT proven
- Verified by **deterministic sim profiles only** — catches structural + gross-tuning regressions, NOT a
  human feel pass.
- **Enemy behaviour around world-kit pillars is unverified** — the Simulation is a flat-plane positional
  model (separation, but no 3D-obstacle awareness); clipping/stacking can only be judged in a live run.
- The **Spark Chain auto-scale is a balance bridge**, not the final upgrade design.

## Deferred (named, flagged in-lesson)
- The real **Core Matrix / upgrade-choice** system (replaces the prototype Spark Chain scale).
- **Live playtest** (feel) + **world-kit collision** verification.
- **Elite/boss** tiers (§5.4 bands ready), and finer second-pass tuning.

See [[v1-loop-complete-balance-pass-next]] (now substantially addressed at the prototype level) and
[[parallel-workstreams]] (scoped commit; art-stream dirt left untouched).
