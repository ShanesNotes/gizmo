# CONTEXT — Gizmo (3D)

Orientation keystone. Read first; if other docs disagree, this wins.

## Hades-clone structural pivot (2026-07-05)
Standing mandate: Gizmo is now built as a **structural and stylistic clone of
Hades** (fixed isometric camera, room-graph traversal, dash/attack/special/cast
kit, boon draft between rooms + death-and-return meta-progression, flat
gouache art) reskinned with existing Gizmo lore. This **supersedes** the Path A
"traverse one island" model and the P0 fun-loop-v1 arena queue described below
on structure/mechanics only — narrative/lore/art-direction canon is unchanged.
See `docs/adr/0010-hades-clone-structural-pivot.md` for the full reconciliation
and what's demoted to reference-only. The rest of this file still describes
the pre-pivot Path A model; treat it as historical until rewritten.

## Clean-slate reset (2026-06-20)
This project is now a **clean-slate 3D Godot rebuild**. Prior 2.5D, sprite-first,
or orthographic-presentation plans/docs are inactive history unless the user
explicitly reactivates them. Use them only as archaeology; do not let them steer
new work.

## Operating mode pivot (2026-07-04)
The default development mode is now **AFK coding-agent-driven** work: small,
bounded, verified slices with tracker/Daily handoff. The `/teach` lesson path is
preserved history and can resume only when explicitly requested; it no longer
controls the default pace of implementation.

## What the game is
A **rogue-lite** in which **Gizmo**, a clanker, preserves the **spark of humanity**
through escalating **enemy pressure** across a **gouache cosmos of lost tech**.
Genre tag: **rogue-lite**. Premise canon: `design-handoff/NARRATIVE.md`.

## No-wave correction (2026-06-20)
Do **not** frame Gizmo as discrete "WAVE x/5" rounds. That language came from
stale concept artwork / earlier ideation and is inactive unless the user
explicitly reintroduces it. The active model is a **director-driven pressure
curve**: enemies spawn, pressure ramps, the run can crest into special threats
later, but the player should not see or learn a wave-round structure in v1.
If older docs say waves/elites/bosses, read that as generic enemy escalation
only. See `docs/adr/0003-director-pressure-not-discrete-waves.md`.

## The loop (active model — Path A, 2026-06-21)
**Traverse a wounded floating island under director-driven enemy pressure and
rekindle a cold Beacon.** Win = **Beacon Rekindled**; lose = **HP 0**. The run clock
no longer wins — it is the **`pressure_clock`** that only fuels the director (ADR 0005).
Pressure is **place-aware**: the island decides how cruel the swarm becomes (ADR 0006).
Survivability is a **recoverable guard over fixed mortal HP** (ADR 0007).

The broader rogue-lite economy still stands as the eventual target: two currencies,
**Sparks** (primary) and **Scrap** (secondary), and run-building via the **Core Matrix**
(ability draft, keys 1/2/3) and **Gadgets**. Per ADR 0001 these — and the **Spark of
Humanity** meter — stay **distinct quantities**: the rekindle is *not* the Spark of
Humanity, and HP is *not* the Spark of Humanity. Full target:
`docs/path-a-shattered-meridian-spec.md`.

## Path A is a microcosm of the Shattered Meridian (2026-06-21)
The first island is **not "the first level"** — it is the first small enactment of the
whole world pattern: *warm origin → broken route → discernment branch → landmark memory
→ sanctuary breath → cold Beacon rekindled → road opens outward.* The world is
**painterly floating islands in a gouache cosmos of lost tech**; Path A is a **flat
combat-readability layer with dramatic non-walkable vertical scenery**. The **Brass
Sphere** survives as spawn / workshop / ceremony, and the **codex** as a UI / memory /
record motif — not as the whole world premise. **No player-facing countdown or
wave-round framing.** Greybox first, painterly assets swapped in as they arrive
(ADR 0008). Spec: `docs/path-a-shattered-meridian-spec.md`.

## The direction (decided 2026-06-20)
Built in **3D with a fixed Diablo-style camera** (looking down ~45°), not 2.5D
sprites. Reason: with a 3D model the engine solves camera angle, facing direction,
and frame-to-frame consistency for free — exactly where AI-generated 2D sprite
sheets fall apart. The old 2.5D sprite scaffolding was removed; recover anything
from git history only if the user explicitly asks for archaeology.

## v1 scope (the only thing we're building first)
The active first build is **Path A — one large painterly floating island** Gizmo
**traverses** under director pressure to **rekindle a Beacon** (win = rekindled, lose =
HP 0); see `docs/path-a-shattered-meridian-spec.md` and ADRs 0005–0008. The prior
"static arena + survive-the-countdown + win/lose screen" framing is **retired**.
**The character is `godot/assets/gizmo.glb` — a meshy.ai model with a 53-bone rig but
no animation clips yet.** v1 moves it with code (no clips needed); adding a walk/attack
clip (via meshy's "Animate", played through an `AnimationPlayer`) is a *later* lesson,
not a v1 blocker. Don't expand scope past Path A until it ships.

## Where each truth lives
- **Path A build target (active first level)** → `docs/path-a-shattered-meridian-spec.md`,
  pinned by `docs/adr/0005`–`0008`. World-grammar source = the Shattered Meridian region
  graph (HEARTH / Hearthwake Basin region).
- **Premise / story** → `design-handoff/NARRATIVE.md`
- **Balance / design foundation (game-agnostic theory)** →
  `reference/game-balance-reference.md` — formulas, TTK bands, spawn budgets,
  upgrade math. The north star; `simulation.ts` is one implementation of it.
- **Mechanics (one implementation of the above)** →
  `game-src-phaser/src/game/simulation.ts` — the source of truth to port. Port
  logic before scene polish.
- **Feel reference (playable)** → root web build; `npx serve .` and play `index.html`
- **Art direction** → character = `godot/assets/gizmo.glb`; UI & world look =
  `design-handoff/gizmo-hud.png` (the canonical visual target); look governed by
  `design-handoff/ART_DIRECTION.md`. Art is generated fresh (meshy.ai / ludo) to
  match the HUD; do not hand-author.
- **Asset manufacturing / Meshy world kits** →
  `/home/ark/gizmo-asset-pipeline/queue/QUEUE.yaml` and that lab's `briefs/`,
  `canon/`, and promotion reports. Root prompt docs are backlog/provenance only.
- **Audio canon / runtime handoff** → `/home/ark/gizmo-audio-canon/` owns cue maps,
  ambience/SFX grammar, and the Godot handoff law. **Raw soundtrack source media** lives in
  `/home/ark/gizmo-soundtrack/`; those MP4s are source material only and must be converted
  through audio-canon rules before anything lands in `godot/audio/`.
- **3D character model** → `godot/assets/gizmo.glb` (meshy.ai: 53-bone rig, no clips yet)
- **The Godot build** → `godot/` (snake_case files, PascalCase nodes)
- **Learning path / historical teaching record** → `lessons/` (one HTML win each, numbered from `0001`) +
  `learning-records/` (records are drafts until the learner can explain the slice).
  Built so far: `0001`–`0020` — player + fixed Diablo camera, Sparks & leveling,
  run state & player health, enemies (spawn/chase/separate/contact), combat
  (auto-fire → death → Spark → XP → level), director-driven pressure (`0010`), HUD
  (`0011`), win/lose (`0012`), balance pass (`0013`), obstacle-aware enemies (`0014`),
  melee-start weapon progression (`0015`), and the Path A beacon-rekindle arc
  (`0016`–`0020`: timer win retired, beacon becomes win, rekindle channel wired live,
  timer symbols retired to `pressure_clock`). The active AFK implementation queue now
  lives in `docs/afk/queue/INDEX.md`; use that frontier instead of lesson numbering unless
  the user explicitly resumes `/teach`.

## How it's built
Agent-driven by default: define executable success criteria, make surgical Godot
changes under `godot/`, verify with `tools/godot/run_all_checks.sh`, and record
durable outcomes in GitHub issues or the Daily ledger. Teaching sessions still use
`/teach`; see `CLAUDE.md`.
