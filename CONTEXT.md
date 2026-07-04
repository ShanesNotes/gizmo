# CONTEXT — read this first

The one orientation file for the Gizmo repo: what the game is, how it's built,
how it's taught, and **where each kind of truth lives**. If two docs disagree,
this file and the ADRs (`docs/godot/DECISIONS.md`) win.

## 1. What Gizmo is

A kid-friendly **bullet-heaven / survivors-like**. Premise (canon —
`design-handoff/NARRATIVE.md`):

> Gizmo is a **clanker** tasked with preserving the **spark of humanity**,
> protecting it from ever-encroaching **dehumanized technology**, across a
> **gouache cosmos filled with lost tech**.

It started as a Phaser/TypeScript web prototype (still the playable feel
reference) and is being **rebuilt in Godot** as a slow, co-developed teaching
project. The port *is* the curriculum.

## 2. The domain language

Use these names exactly; they are the same in the code, the fiction, and the
design system.

- **Spark** — the XP/charge the player gathers; fictionally, fragments of
  humanity being rescued.
- **Cache** (a.k.a. reliquary) — sealed lost tech; cracking it frees Spark and
  sometimes an **evolution** (a combo/upgrade gate).
- **The four economies / covenants** — parallel reward tracks: **Flow**,
  **Clutch**, **Echo**, **Surge** (colors + fiction in
  `design-handoff/NARRATIVE.md` §4). Gold always means reward.
- **Bounty** — a risk/streak chase objective.
- **Boost / Snap Boost** — the hand-timed scoop; the player-skill lever.
- **Enemy kinds** — `nibbler / dasher / brute / warden`, escalating dehumanized
  tech; they map to TTK bands (`docs/godot/BALANCE_MODEL.md`).
- **Illumination / the Codex** — the ceremony layer: the record of preserved
  sparks; the gold-leaf reward language (a retained sub-motif, not the premise —
  see NARRATIVE §5).

## 3. The architecture (vocabulary that resolves most questions)

The port is built around one **deep module** and a single coordinate **seam**.

- **Simulation** — the flat 2D rules plane (movement, spawn, XP/level, the four
  economies, Cache/Bounty/Boost, damage/heal, run state). Pure, headless,
  testable. Its interface is a **snapshot + a stream of events**. This is the
  source of truth being ported from `simulation.ts` → `simulation.gd`.
  *Invariant:* Simulation never holds renderer fields (no `z`, `position_3d`,
  `transform`, visual height). World `width`/`height` are flat 2D bounds.
- **SimSpace** — the *only* coordinate seam: maps Simulation's flat `x/y` onto the
  Godot stage (`x → x`, `y → z`, Godot `y` = visual height only).
- **The 2.5D stage** — `Node3D` + an **orthographic `Camera3D`**. Flat rules,
  dimensional presentation (ADR-011).
- **Presenters** — display-only **adapters** that read Simulation snapshots/events
  and move visuals (`player_avatar_3d.gd`, camera rig, HUD presenter). Presenters
  never own rules.
- **Screen-space HUD** — survival info stays in a `CanvasLayer` / `Control` tree,
  not diegetic 3D.

So: **flat rules → SimSpace → 2.5D stage; events → presenters; status →
screen-space HUD.** Most "where should this go?" questions answer themselves
against that line.

## 4. The teaching model (the contract)

This is **co-development paced for understanding**, run through the global
`/teach` skill — not "watch the AI build" and not "type every line yourself."
The bar: the learner can explain every piece; nothing lands as a black box.

- `godot/` — the **learner's workspace**. Currently a **bare lesson-0001 shell**
  (ADR-012 from-zero reset). The learner builds it up, one win per lesson.
- `docs/godot/answer-key/` — the **verified reference port** (the finished 2.5D
  implementation), set aside. Consult it to check direction or unblock; **never**
  paste it in wholesale as a lesson. *This is where the "live code" lives — not
  `godot/`.*
- `learning-records/` — the **only** record of learner progress. Lesson HTML
  drafts are *not* progress; verified-ahead code is *not* progress.
- `lessons/` — self-contained HTML, numbered `0001-…`, one tangible win each.
- **Do not build Godot game code ahead of the learner.** Architecture/code
  improvements that would do so are *recorded as ADRs/guidance* and applied
  during co-development.

## 5. Doc-ownership map — where each truth lives

Read the **owner** for a topic; the rest are pointers.

| Truth | Canonical owner |
|---|---|
| This orientation / domain language / doc map | **`CONTEXT.md`** (this file) |
| Locked decisions (ADRs) | **`docs/godot/DECISIONS.md`** |
| Story / premise / world / fiction-mapping | **`design-handoff/NARRATIVE.md`** |
| Look & feel (palette, type, motion, components) | **`design-handoff/FUSION-CODEX.md`** + `design-system/` |
| Why-we're-doing-this charter (why/success/scope) | **`MISSION.md`** |
| Teacher's working method & lesson conventions | **`NOTES.md`** |
| Annotated resources / external links | **`RESOURCES.md`** |
| Phaser→Godot source map & line anchors | **`GODOT-PORT.md`** + `docs/godot/PORT_MAP.md` |
| Mechanics source of truth | **`game-src-phaser/src/game/simulation.ts`** |
| Balance/tuning model (Gizmo-specific) | **`docs/godot/BALANCE_MODEL.md`** |
| Generic balance reference (external) | **`reference/game-balance-reference.md`** |
| Asset → Godot import plan | **`docs/godot/ASSET_IMPORT_PLAN.md`** |
| Lesson spine / sequence | **`docs/godot/LEARNING_PATH.md`** + `docs/godot/LESSON_ROADMAP.md` |
| Canonical-source ranking & live-vs-reference | **`docs/godot/TRUST_BOUNDARIES.md`** |
| Verification gates | **`docs/godot/PLAYTEST_CHECKLIST.md`** + `CLAUDE.md` §Commands |

Point-in-time **snapshots** (read as history, not living spec):
`docs/godot/LEARNING_AUDIT.md`, `docs/godot/GODOT_AGENT_TOOLING_REVIEW.md`,
`docs/godot/UI_PANEL_VISUAL_SMOKE.md`.

## 6. Environment & engine

- Godot **target 4.7.x stable** (upgraded 2026-07-03, ADR-017). Prior teaching
  work was **verified locally on 4.6.2.stable.mono.official**; re-verification on
  4.7 is pending on the host. This statement is canonical — other docs cite it
  rather than pinning a patch.
- Naming: snake_case files/folders, PascalCase nodes / `class_name`.
- Gates (full list in `CLAUDE.md`): web build (`npm ci && npm run build`), feel
  check (`npx serve .`), Godot import / `--check-only` / headless tests.

## 7. Boundaries

Do not rewrite the Phaser seed, the root Vite build, or the design handoff. Do
not hand-roll Lumen Codex assets (use `design-system/`, `design-handoff/`,
`art/`). Do not stage `node_modules/`, `dist/`, `.godot/`, or generated cache.
Do not attempt a full port in one lesson.
