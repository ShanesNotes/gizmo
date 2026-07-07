# 0007 — Survival is a recoverable guard over a fixed mortal HP

**Status:** accepted · 2026-06-21 · **amended 2026-07-07 (playtest 2)**

> **Amendment (Halo-CE model, playtest 2 verdict):** the guard is now a
> **continuous shield bar** (100 points, recharge after delay), and mortal HP
> is **3 discrete hull blocks** that tick **exactly one per shield-broken
> hit** — overflow from the breaking hit never reaches the hull (break
> grace), and hull never regenerates in-run. The sanctuary language stands:
> the REST Ember Alcove refills the **shield only**, never hull blocks.
> Implementation: `godot/scripts/player/player_vitals.gd`.

## Decision
Gizmo's survivability is **two layers**, in the Halo lineage:

1. A **recoverable guard / shield buffer** on top of
2. **fixed mortal HP** underneath.

- **Damage hits guard first.** HP reads as precious, one-way attrition.
- **Guard recharges after a delay since last damage.** The **Sanctuary** (a
  relief-role `PressureZone`, ADR 0006) shortens that delay / raises the recharge
  rate. **True HP does not regenerate** by default. Recovery is **capped** so sustain
  never erases danger.
- **Anti-camp is structural:** the temporal pressure term keeps climbing even at low
  exposure (ADR 0006), and sanctuary relief is *partial*, so camping the sanctuary is
  dominated by the rising `pressure_clock`.
- **Staging:** if the guard pool is too large for the first commit, ship the Sanctuary
  as **pressure relief only**, with the `SanctuaryAnchor` seam ready for guard
  recharge later. **Do not** bake "sanctuary heals HP" as canon under any staging.

## Why
- The sim has **no healing at all** today — `hp` only decrements
  (`godot/scripts/simulation.gd:248`). A pure attrition race gives the Sanctuary
  nothing to do and makes retreat irrational: the rational player ignores it and
  races the Beacon. A *recoverable* guard gives the loop a reason to exist —
  push → hurt → retreat → recover → repush — without trivializing mortality.
- The balance reference treats shields/barriers as **temp-HP with a recharge delay
  and capped recovery**; this matches that model.
- Mortality stays meaningful by keeping HP a one-way resource, **distinct** from the
  renewable guard.

## What this rules out
- Free HP regeneration, or the Sanctuary as a heal-fountain.
- A guard so generous (or relief so total) that camping the Sanctuary is optimal.
- Conflating the guard with HP, **Sparks**, or the **Spark of Humanity** (ADR 0001
  stays intact). The guard is a neutral "protective light," **not** the Spark of
  Humanity meter; its narrative framing waits on ADR 0001's pending pass.

## Consequences
- **`simulation.gd`:** add a guard pool + recharge-delay timer + sanctuary modifier;
  `take_damage` (`:243`) routes to guard before `hp`.
- **HUD:** guard-over-HP readout — a cyan/teal recoverable guard bar above a smaller
  warm mortal HP bar (ADR 0005 HUD changes; Path A spec §HUD).
- A future **Core Matrix** draft may feed guard upgrades (the visible Level/Sparks/XP
  runway stays).

## Related
- ADR 0001 (Sparks ≠ HP ≠ Spark of Humanity — keep quantities distinct);
  ADR 0002; ADR 0005; ADR 0006 (the Sanctuary is a relief-role pressure zone).
- `reference/game-balance-reference.md` (shield = temp-HP + recharge delay, capped).
- `docs/path-a-shattered-meridian-spec.md`; `simulation.gd:125`/`:243`.
