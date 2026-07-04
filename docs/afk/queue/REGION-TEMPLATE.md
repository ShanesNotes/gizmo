# REGION-TEMPLATE — the 7-slice pattern every region instantiates

Each REGION-<ID>.md provides only the parameter block; these seven tickets are minted from it
mechanically at pickup (ids R-<ID>-1 … R-<ID>-7). All inherit PHASE-MAP standing laws, the GZ-174
region scene contract, and GZ-175 difficulty profiles. Hearthwake (HEARTH) already exists — it is
the proof this template is buildable; its build order IS this order.

## R-<ID>-1 — Region spine ruling [lab: level-design, Opus]
The region's spatial-symbolic spec: instantiate the directed spine (origin → branch → landmark →
trial → sanctuary → beacon) for THIS region's question/transformation/corruption (from the region
graph), as a zone table in spec-§4 format (named markers, positions, roles, exposure 0..1, radii)
plus a walkable footprint sketch. Grounded in their canon (L-gates); delivered as data + a
reconciliation-ready witness. AC: their `make validate` green; zone table complete; the output
answers "what does this region make the player do, read, and feel?"

## R-<ID>-2 — Kit brief & asset queue [lab: asset-pipeline, Opus]
Queue + produce the region's kit per their law: landmark set-piece, 2–3 dressing families in the
region's palette, beacon variant reskin, ground/base. Prompts respect lore-bindings; camera-proof
screenshots gate promotion. AC: promotion reports validate; installs land additive; game gate green.

## R-<ID>-3 — Cue set [lab: audio-canon, Sonnet]
Region music/ambience: map or commission cues for roam/trial/siege + one ambient bed in the
region's mood (cue-map extension, their canon owns ids), convert per handoff law. AC: lab
validators green; OGGs + sidecars installed; cue ids registered before conversion (A1 gate).

## R-<ID>-4 — Region scene bake [game, Sonnet]
Author `godot/scenes/regions/<id>.tscn` per the GZ-174 contract from R-1's zone table + R-2's kit
(via the GZ-112 baker where recipes exist; hand-composed otherwise, manifest still written).
AC: contract-conformance assert passes; GZ-113 validators green; exposure at every marker matches
R-1's table (recorded values test).

## R-<ID>-5 — Region threat flavor [game (sim Cluster A), Sonnet]
The region's mechanical personality WITHOUT new enemy classes where possible: a spawn-weight
profile + at most ONE region twist implemented as sim data/flag (each region file names its twist;
twists reuse existing systems — zones, guard, budget, elites). AC: sim tests for the twist +
profile; balance suite green at the region's difficulty profile.

## R-<ID>-6 — Region audio/style wiring [game, Haiku]
Register R-3 cues in the AudioDirector state map and the region palette in the style director
baseline. AC: state-matrix test rows for this region green; gate green.

## R-<ID>-7 — Region gate test [game, Sonnet]
The region's GZ-020 analog: scripted win + loss integration runs through the region scene at its
difficulty profile, asserting the twist fired, the siege peaked, and the beacon rekindled →
meta_state records it and the world map lights the neighbors. AC: added to the integration runner;
full gate green. **A region is DONE when R-7 is green — nothing else counts.**

## Ordering
R-1 → (R-2 ∥ R-3) → R-4 → (R-5 ∥ R-6) → R-7. Regions parallelize freely EXCEPT R-5 slices
(Cluster A: serialize across regions) and R-4 landings (one region scene lands at a time).
Act order: BRASS/VERDANT/RUST (P4) → RUNE/OBS/PRISM/ASH (P5) → TEMPEST/NULL (P6).
