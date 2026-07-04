# GZ-161 — E6 decision: ADR 0012 — the Spark-of-Humanity meter (lore grill)

intent: The parked third quantity (ADR 0001) gets its dedicated pass: a grilled, lore-co-authored ruling on what the Spark-of-Humanity meter IS mechanically — or a ratified decision that it stays premise-only. Produces `docs/adr/0012-spark-of-humanity.md`.
files in scope: PRIMARY (new): `docs/adr/0012-spark-of-humanity.md`; a reconciliation/extraction note in gizmo-lore (their side of the grill). No game code.
grounding: ADR 0001 (three distinct quantities; meter mechanics TBD pending dedicated pass); NARRATIVE.md premise (Gizmo preserves the spark of humanity); lore lab's non-negotiables (Spark-of-Humanity is sacred/premise-level, NOT automatically a meter or fuel; Beacon rekindle NOT fuelled by it unless a future ADR says so); path-a spec §10 (neutral until this pass).
decisions made (RECOMMENDED DEFAULT to grill against): **"carried warmth" — a between-run world-state meter, not an in-run resource.** Each Beacon rekindled raises it; it gates ACT progression on the macro map (GZ-171's structure) and drives the world's visual re-humanizing baseline (GZ-133's ramp start point). It is never spent, never fuels anything in-run, never appears as an in-run bar. Rationale: keeps the sacred thing sacred (lore law), gives it real mechanical weight (act gates), zero collision with Sparks/guard/HP.
executable success criteria: ADR exists with the ruling + rejected alternatives (in-run meter; rekindle fuel — both must be explicitly rejected or adopted with lore sign-off recorded); lore-side extraction note exists; validators green in gizmo-lore (`python3 validators/validate_lore_terms.py`).
dependencies / order: blockedBy GZ-171 (macro-map ADR — the default's mechanical home must exist first).
model routing: **Opus** — the most canon-sensitive ruling in the queue; grilling discipline.
cross-domain: co-owned with gizmo-lore; run the lore half inside their lab.
status: deferred:E6
