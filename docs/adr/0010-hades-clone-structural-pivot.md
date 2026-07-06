# ADR 0010 — Hades-clone structural pivot; prior prototype demoted to reference

## Decision

Gizmo's target structure is now a **Hades-clone**: fixed isometric/Diablo-angle
camera, **room-graph** traversal (not a single open arena/island), a
**dash + attack + special + cast** ability kit, **boon draft between rooms**
(run-scoped) plus meta-progression between deaths, biome/run structure, and
flat gouache/painterly presentation — reskinned entirely with existing Gizmo
lore (Shattered Meridian, Spark of Humanity, Sparks/Scrap, the Beacon, the
codex). This is a **structure and mechanics** decision; narrative/lore content
is unchanged and still governed by `design-handoff/NARRATIVE.md` and the
`gizmo-lore` clean canvas.

This overrides, on structure only:
- **Camera/level model**: the Path A "one large traversed island" model
  (CONTEXT.md, ADR 0005–0008) is superseded by Hades' room-to-room graph.
  Director-driven pressure (ADR 0003) and guard-over-HP (ADR 0007) survive as
  *combat* mechanics but now operate per-room, not over a whole-island pressure
  clock.
- **Ability kit**: the auto-fire + melee-progression model (ADR 0004) is
  superseded by an explicit dash/attack/special/cast kit.
- **Progression**: leveling/XP is superseded by a run-scoped boon draft
  (offered between rooms) plus a death-and-return meta-progression currency
  loop (Sparks/Scrap keep their names and fictional identity per ADR 0001;
  their mechanical role shifts to boon-economy currencies).
- **Codebase**: the current `godot/` implementation (arena controller, HUD,
  end-screen, simulation.gd port-in-progress) is **demoted to concept/reference
  only**. It is not the refactor base. Systems Hades structures differently
  (camera, level, combat, progression, UI) are rebuilt from scratch. Reusable
  math (damage/HP formulas, spawn-pressure curves in
  `reference/game-balance-reference.md`) is salvaged by value, not by
  architecture.

Unchanged: `gizmo.glb` character model, generated art assets, audio canon,
lore/narrative content, Godot project conventions (snake_case files, PascalCase
nodes, `godot/` containment, branch off `gizmo-3d`).

## Why

Standing creative mandate (2026-07-05): Gizmo has always been aimed at Hades'
flat-gouache look and combat feel; that intent was never written into
`CONTEXT.md`/`design-handoff/`. The current prototype's structure (static
arena, wave-free pressure clock, auto-fire, leveling) was built toward a
simpler loop that cannot be incrementally bent into a room-graph +
boon-draft + dash-kit shape without more churn than a clean rebuild of just
those systems.

## Rules Out

- Treating GZ-001…GZ-041 (the P0 fun-loop-v1 arena queue in
  `docs/afk/queue/INDEX.md`) as the frontier. It is retained as historical
  reference for salvageable balance math only; a new Hades-structure queue
  supersedes it (tracked going forward; this ADR is the pointer until that
  queue is written).
- Silently dropping old canon: `CONTEXT.md` still describes the Path A model
  until it is rewritten to reflect this pivot (tracked as follow-up); readers
  should treat this ADR as authoritative on structure in the interim.
- Rewriting lore, narrative, or art direction — only structure/mechanics
  changed here.
- Treating the current `godot/` scenes/scripts as anything other than
  reference/concept for the new build.
