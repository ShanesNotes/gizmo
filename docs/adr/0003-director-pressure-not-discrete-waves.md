# 0003 — Director pressure, not discrete wave rounds

**Status:** accepted · 2026-06-20

## Decision
Gizmo v1 uses a **director-driven enemy pressure curve**, not player-facing
discrete "WAVE x/5" rounds.

Enemies may spawn faster, become tougher, or introduce special threats as the run
progresses, but that escalation should read as continuous pressure unless the
user explicitly reopens the decision. The HUD should not teach a wave counter.

## Why
The "WAVE x/5" language came from stale concept artwork / earlier ideation, not
the active design intent. Carrying it forward would make lesson 0010 solve the
wrong problem and would push the game toward round transitions before the core
rogue-lite loop, HUD, and win/lose spine are stable.

## Consequences
- Lesson 0010 should be about a **pressure director**: spawn cadence/intensity,
  budget/caps, and maybe scheduled special-threat hooks — not "Wave 1/5".
- Existing references to waves in older docs/lessons should be read as generic
  enemy escalation unless updated.
- Later special encounters are still possible, but they should be introduced
  deliberately as their own mechanics, not because a wave counter implies them.

## Related
- ADR 0002: Simulation owns rules; scene renders.
- `CONTEXT.md`: active no-wave correction.
