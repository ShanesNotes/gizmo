# 0012 — The Spark of Humanity meter is the Surge gauge (Call-gauge analog)

**Status:** accepted · 2026-07-06 · resolves the "mechanics TBD" left open by ADR 0001

## Decision
Under the Hades-clone structure (ADR 0010), the **Spark of Humanity meter** becomes the
structural analog of Hades' **God Gauge / Call**: a run-scoped charge meter that fills
through combat and is spent on a **Spark Surge** — a burst release of the flame Gizmo
carries.

Mechanics (v1.x):
1. **Charging.** Dealing damage adds a small charge; **losing guard adds a large charge**
   (Hades parity: taking hits charges the call fastest). Charge rates are exported tuning
   fields on the vitals/abilities side, not magic numbers.
2. **Spending.** Spend requires a **full gauge** (no partial call in v1.x). The Spark
   Surge is a radial burst centered on Gizmo: damages and briefly staggers every enemy in
   the room. One dedicated input action (`surge`, default `F`).
3. **Scope.** Charge persists across rooms within a run; empties on use and on death.
   Never banked, never a currency, never restored by REST fixtures.
4. **HUD.** Bottom-right slot per `design-handoff/ART_DIRECTION.md` HUD anatomy — a brass
   flame gauge. Payload-driven only: `render_spark(charge, charge_max)`; the HUD never
   reads game state.

## ADR 0001 compliance
All three quantities stay distinct. The meter is **not** HP/guard (it has no fail state —
an empty gauge is merely "not ready", never death) and **not** the Sparks currency
(fragments Gizmo collects). Narrative reconciliation of "keep it safe, keep it alive":
the Spark **flares in Gizmo's defense** when he takes hits protecting it — charging on
guard damage *is* the guarding fiction, and the Surge is the flame answering. Copy must
say "the Spark flares/surges", never "spend the Spark".

## What this rules out
- Any death/lose condition attached to the meter.
- Partial-charge spending, multiple gauge segments, or boon-modified Surge effects in
  v1.x (a later ADR may add Hades-style call-upgrade boons).
- Charging from currency pickups (that would blur meter vs. Sparks).

## Consequences
- HZ-103 implements: vitals/abilities-side charge accounting, the Surge ability through
  the existing ability-kit seam (ADR 0011 router action), HUD `render_spark`, and
  red-first tests (charge bands, full-gauge gate, empty-on-use/death, room persistence).
- `CONTEXT.md` domain language gains **Spark Surge** once implemented and playable.
