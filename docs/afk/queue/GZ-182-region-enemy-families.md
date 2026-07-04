# GZ-182 — E8/P5 (sim+labs): act-2 enemy family pass

intent: Act 2 earns new silhouettes: TWO new enemy kinds (not reskins) covering gaps the four base kinds leave — a ranged harasser and a splitting swarm-seed — plus per-region spawn-weight profiles for RUNE/OBS/PRISM/ASH.
files in scope: sim half: `godot/scripts/simulation.gd` (two kind blocks in the established const pattern, simulation.gd:34–65 house style) — Cluster A; asset half: routed to gizmo-asset-pipeline (briefs respect lore-bindings: hollowed devices, never gore); tests: sim + balance suites.
grounding: balance §5.4 bands (harasser = trash-tier ranged, TTK ≤0.7s, projectile dodgeable at 3.6 m/s walk; seed = bruiser 1–3s that splits into 3 nibbler-class motes on death — pack pressure per §6.1); enemy-design guardrail: every kind must be answerable by at least two of the three weapons (anti-hard-counter, recorded).
decisions made (recorded stats v1): harasser — speed 1.8, hp 2, keeps 6m distance, projectile 4 m/s dmg 1 cost 2.6 unlock: act 2 only; seed — speed 1.4, hp 3, radius 1.4, on-death spawns 3 motes (nibbler stats, xp 1, no further split) cost 3.8. Projectiles are NEW sim surface (`projectiles` array, ticked, walkable-clamped) — API-CONTRACT updated by this ticket.
executable success criteria: sim tests — harasser kiting/projectile hit/dodge windows, seed split exactly-once, projectile containment; balance TTK bands at act-2 profiles; camera-proof screenshots from the asset lab before install. Gate green.
dependencies / order: blockedBy GZ-175 (profiles), GZ-030 pipeline mature. Blocks act-2 R-7 gates (regions may land scenes first; their gate tests wait for this).
model routing: **Opus** — first projectile system + first enemy-count expansion; balance-critical.
status: deferred:P5
