# GZ-183 — E8/P6 decision+impl: the Null Crown guardian ruling

intent: The last enemy question, answered at the door of the finale: does NULL get a bespoke guardian, or is the perfected siege (R-NULL-8) the truer boss? An ADR-grade ruling, then the small implementation it licenses.
files in scope: PRIMARY (new): `docs/adr/0013-null-crown-guardian.md`; impl per ruling (sim Cluster A if adopted).
grounding: ADR 0005 (swarm-at-peak IS the Path A boss; bespoke guardian = "named later upgrade" — this IS the named later moment); lore (the Crown is anti-sanctuary — imitation, not monster); the full system inventory by P6 (storm surges, false sanctuaries, elites, two act-2 kinds).
decisions made (RECOMMENDED DEFAULT): **no bespoke guardian.** The Crown's boss is the false-sanctuary siege itself — the game's thesis (imitation vs. warmth) argues against ending on a big monster; it ends on discernment under maximum pressure. Licensed implementation under the default: one FINALE ELITE variant ("Hollow Keeper" — warden-class, guard-like shield that must be broken twice, spawns only during the NULL siege, max 2 alive) as punctuation inside the siege, not a boss bar. No boss HP bar ever (HUD absence assertion).
executable success criteria: ADR exists; if the default stands — sim tests for the Hollow Keeper (shield-break twice, siege-only, cap 2) and the R-NULL-8 scenario updated; gate green. If overruled — the ADR must scope the guardian as its own ticket band before any code.
dependencies / order: blockedBy REGION-TEMPEST R-7 (the evidence of how the systems stack). Blocks R-NULL-8.
model routing: **Opus** — the game's final design ruling.
status: deferred:P6
