# Gizmo — full-game phase map (long-horizon DAG)

The whole road from today's build to the finished game. Every phase is a band of tickets in this
folder; a phase opens when its gate ticket is green. World facts from
`docs/reference/shattered-meridian-region-graph.json`; loop law from CONTEXT.md + ADRs 0001–0009.

## Phases

| Phase | Meaning | Ticket band | Gate (exit criterion) |
|---|---|---|---|
| **P0 — Fun-loop v1** | the rogue-lite loop is real on Hearthwake Basin | GZ-001–041 | GZ-020 integration green + GZ-040 export |
| **P1 — Dressed v1** | v1 sounds/looks/feels finished | GZ-101–104 (audio), GZ-111–113 (bake), GZ-121–122 (anim), GZ-131–134 (style) | GZ-113 validators green + GZ-134 style probe shipped |
| **P2 — Systems depth** | draft depth + juice + canon coherence | GZ-151–156 (juice), GZ-141 (concordance), GZ-161–162 (Spark-of-Humanity) | GZ-154 evolutions green; ADR 0011 ratified |
| **P3 — World frame** | runs live inside a world: meta map, saves, acts | GZ-171–175 | GZ-172 save round-trip green + ADR 0010 ratified |
| **P4 — Act 1** | three branch regions playable | REGION-BRASS / -VERDANT / -RUST (template ×3) + GZ-181 (enemy variety) | all three region gate tests green |
| **P5 — Act 2** | four mid regions + mystery route | REGION-RUNE / -OBS / -PRISM / -ASH + GZ-182 | act-2 gate tests green |
| **P6 — Act 3 / finale** | convergence + the Null Crown | REGION-TEMPEST / -NULL + GZ-183 (finale siege) | NULL gate test green: false crown falls, last warmth carried |
| **P7 — 1.0 ship** | shell, polish, release | GZ-191–194 | release build + store page live |

Phases overlap where lanes are disjoint (labs run ahead: region kits for P4 can start during P1).
Within a phase, tickets carry their own blockedBy; across phases, the gate ticket is the only edge.

## Standing laws (inherited by every band; tickets don't restate them)
1. Branch off `gizmo-3d`; `tools/godot/run_all_checks.sh` green before done; revert on red.
2. Sim owns rules, scenes render, GameController bridges (ADR 0002); API-CONTRACT.md tracks surface.
3. No waves, no countdown, no player-facing round language — ever (ADR 0003/0005; validator-enforced from GZ-113 on).
4. Sparks ≠ Scrap ≠ guard ≠ HP ≠ Spark-of-Humanity (ADR 0001); collapse = reject.
5. Labs own their canon; game consumes handoffs; conflicts become extraction notes, never silent picks (gizmo-ecosystem.yaml).
6. Every ticket: one primary file, executable ACs, recorded decisions, model routing.

## Decision tickets (judgment sliced like code — each produces an ADR, with my recommended default recorded so a cold agent can ratify-and-go)
- GZ-151 → ADR 0011: score/combo disposition (default: cut; keep close-call dash refund as feel)
- GZ-161 → ADR 0012: Spark-of-Humanity meter (default: stays premise-only until Act 2; then "carried warmth" run modifier)
- GZ-171 → ADR 0010: run/world structure (default: one run = one island; macro map = between-run meta progression)
- REGION-TEMPLATE R-slice-0 per region → each region's spine ruling

## File conventions in this band
One file per ticket EXCEPT regions: each REGION-<ID>.md instantiates the 7-slice REGION-TEMPLATE.md
with that region's parameters — the template carries the full schema once; region files carry only
deltas. (Nine near-identical 60-line files would be churn, not precision.) At pickup, a dispatcher
splits a region file into 7 issues mechanically.
