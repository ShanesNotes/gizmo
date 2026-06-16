# Design → Lesson handoff (for implementation agents)

**What this is.** The bridge between the design work *already done* and the
lesson-by-lesson Godot build. Point an implementation agent here first. It does
not re-specify the design system or the lessons — it says **when each finished
design asset enters the Godot project, which lesson/phase gates it, and how to
prove it landed correctly.**

**Read order for a new agent**
1. This file — the map and the rules.
2. `GODOT-PORT.md` — the three inputs (mechanics / look / feel) and the seed-as-truth.
3. `.omx/plans/prd-godot-claude-code-teaching-workflow-20260614T170933Z.md` — the
   approved two-track plan + phases (the execution ledger).
4. `docs/godot/ASSET_IMPORT_PLAN.md` — the 16 concrete asset import groups.
5. `design-handoff/IMAGE-MODEL-BACKLOG.md` — the raster/painterly lane + fidelity gate.
6. `docs/godot/LESSON_ROADMAP.md` — the sim-first lesson spine (0001–0012).

---

## The one rule that orders everything: two tracks, one log

The approved plan (PRD §RALPLAN-DR, ADR #1) splits work into two tracks:

- **Lesson-track — simulation-first.** This is the spine. It advances the lesson
  log (`docs/godot/LESSON_LOG.md`) **only** when a *verified simulation milestone*
  passes. Mechanics ported from `game-src-phaser/src/game/simulation.ts`.
- **Reference-track — UI / theme / assets.** May proceed in parallel, in **narrow
  verified slices**, but **never advances the lesson log.** This is where the
  finished design work gets front-loaded.

> **For agents:** doing UI/asset work is allowed and encouraged ahead of need —
> but do **not** bump lesson numbers or write a `LESSON_LOG.md` checkpoint for it.
> Record reference-track progress in this file's changelog or the commit, not the
> lesson log. (Test-spec §Lesson-log rule.)

---

## What is already done (do NOT re-create any of this)

The design phase produced a complete, locked **vector system** plus a started
**raster lane**. Treat all of it as source-of-truth; per `CLAUDE.md` and the
backlog's fidelity gate, **never hand-roll a replacement.**

**Vector system — `design-system/`** (the claude.ai/design output)
- `tokens/` — `colors.css`, `typography.css`, `spacing.css`, `fonts.css`
  (void/surfaces, four economy hues, gold/oxblood, radii, eases). → Godot `Theme`.
- `components/core/` + `components/game/` — 15 components, each with a
  `*.prompt.md` **spec** (Button, Panel, Pill, Keycap, Meter, Seal, Eyebrow;
  UpgradeCard, BoostButton, BreathRow, StatCell, VerdictBar, Joystick, etc.).
  These are the **component contracts** to rebuild as Godot `Control` scenes.
- `ui_kits/lumen-codex/` + `templates/` — the four built screens (Title, HUD,
  Level-Up, Results) — the **visual smoke targets**.
- `assets/sprites/` — gizmo, enemy families, pickups, caches, covenant emblems,
  rarity ladder. `assets/brand/` — the Illuminated-G emblem set.

**Raster lane — `design-handoff/` (image-model, `IMAGE-MODEL-BACKLOG.md`)**
- ✅ **KA-3 app-icon master** — `design-handoff/brand/ka3-app-icon-master-1024.png`
  (+ 512/192/180/32 exports).
- ✅ **KA-1 title key art** — `design-handoff/brand/ka1-title-key-art-2560x1440.png`
  (+ 1080×1920 portrait).
- ⏳ Everything else in the backlog (BG-1 playfield, FX-1 illumination, CD-1 rarity
  backers, KA-2 boss…) is **not yet generated** — leave the ⏳ rows alone until a
  lesson needs them; generate via the backlog's 3–4-variants → fidelity-gate flow.

**Boundary (backlog §The boundary):** gameplay sprites, icons, HUD chrome, mini
emblem stay **vector**. Key art, backgrounds, FX frames, texture plates, card
backers are the **raster** lane. Don't cross them.

---

## The integration map — which lesson opens which design door

Each lesson is sim-first; the design column is the **reference-track asset that
becomes eligible to front-load once that lesson lands.** "Eligible" = you may
import it now; it doesn't block the lesson. Import group `#n` references
`ASSET_IMPORT_PLAN.md`.

| Lesson / milestone (sim-track win) | Design asset that becomes eligible | Source → dest | Import group |
|---|---|---|---|
| **player core** (0008 SPLIT into 5 micro-lessons per ADR-012 / `LESSON_ROADMAP.md`: InputMap → Simulation movement → SimSpace → `PlayerAvatar3D` → Main wiring) — eligible **after the `PlayerAvatar3D` micro-lesson** | Gizmo player **animation** sheet — the avatar renders via `PlayerAvatar3D` on the 2.5D stage, **not** an `icon.svg` swap (see `ASSET_IMPORT_PLAN.md` §"Player character animation" + ADR-015) | `art/character/gizmo-walk-source.png` → `godot/assets/sprites/gizmo/` (vector `gizmo.svg` stays brand/UI/static) | #1 |
| **0009 pickups & XP** | Spark pickup sprite | `…/pickup-spark.svg` → `godot/assets/sprites/pickups/` | #3 |
| **0010 level-up choice (sim)** | — (logic only; no art yet) | — | — |
| **0011 level-up choice UI** | Theme + `Panel`/`UpgradeCard` family; rarity + covenant emblems; Fredoka/Cormorant/Nunito | tokens → `godot/ui/theme.tres`; `…/rarity*.svg`, `covenant-emblems.svg` → `…/sprites/ui/`; fonts → `…/fonts/` | #10–14, #6–7 |
| **0012 emblem title screen** | The Illuminated-G emblem (vector) + KA-1 key art backer (raster, optional) | `…/brand/emblem*.svg` → `godot/assets/brand/`; `ka1-title-key-art…png` → `…/reference/screens/` then composite | #8, backlog KA-1 |
| **HUD phase** (Horizon) | HUD chrome: `Meter`, `StatCell`, `BreathRow`, `VerdictBar`, covenant meters | `components/*.prompt.md` → `godot/ui/components/` | #13–14 |
| **Enemies/caches** (Horizon) | Enemy families, cache/reliquary sprites | `…/enemy-*.svg`, `…/pickup-cache*.svg`, `cache-reliquary.svg` | #2, #5 |
| **Juice pass** (Horizon) | FX frames + texture plates (raster) | backlog FX-1/FX-2, TX-1…TX-4 (⏳ generate when reached) | backlog P1/P2 |

> The **first** reference-track slice the plan authorizes (PRD Phase 1) is
> deliberately narrow: **`theme.tres` + token groups #10/#12 + the `Panel` family
> only.** Everything else above waits its turn (PRD Phase 3: one family at a time).

---

## Reference-track execution order (mirrors PRD phases)

- **Phase 0 — canonicalize paths first.** Pin `title.gd` to `godot/scripts/`,
  rewire `main.tscn`, retire the scene-local copy; record the two-track boundary in
  docs. *(Executed; see "Path cleanup status" below.)*
- **Phase 1 — narrow UI foundation.** `theme.tres` from token groups #10 (colors)
  and #12 (spacing/radii/eases) + base typography (#11), and **only the `Panel`
  family**. Nothing else.
- **Phase 3 — widen one family at a time.** Add the next component/sprite family
  only after the current one passes the gate. Use the **exact** groups in
  `ASSET_IMPORT_PLAN.md`; never a generic "copy the design system" bucket.

---

## The per-slice verification gate (run on EVERY theme/component/scene slice)

From the test-spec — a slice is not "done" until all four pass:

1. **Import** — `godot --headless --path godot --import` exits clean after the change.
2. **Syntax** — `--check-only` on any new/changed GDScript.
3. **Headless instantiation** — load the new scene/`Control` headlessly and exit 0
   (a throwaway `extends SceneTree` smoke script that instances it).
4. **Visual smoke** — one checklist comparison against the matching reference in
   `design-system/ui_kits/lumen-codex/` or `design-handoff/screens/`.

Raster assets additionally pass the backlog **fidelity gate** (palette-true,
radiance-is-made, no AI-sheen/halo/sacred-copy, state-reads, composites-clean,
matches-vector) before they ship.

---

## Hard boundaries (lifted from the locked docs)

- **Never invent or re-roll** a sprite/emblem that already exists in
  `design-system/assets/` — copy it (`CLAUDE.md`; backlog "Matches the vector").
- **Warm:cool ≈ 9:1; only red & gold saturate.** Gold = reward/light, oxblood =
  cost. No rarity-glow spam, fog/bokeh, generic AI sheen, halos, sacred imagery,
  or emoji. (`ASSET_IMPORT_PLAN.md §Non-negotiables`.)
- **Copy assets in only when a lesson needs them**, with snake_case filenames, SVG
  source kept beside any rasterization, source path recorded in the commit/log.
- **`design-system/` and `design-handoff/` are read-only source.** Do not edit them
  to fit Godot; translate into `godot/`.
- **The contained `godot/` boundary stays intact** — no project files climb out of it.

---

## Path cleanup status (Phase 0 — HISTORICAL, voided by the ADR-012 reset)

> **Read as history.** The path moves below ran against the pre-reset live `godot/`
> tree. The 2026-06-15 full from-zero reset (ADR-012) relocated **all** that live
> Godot code — `main.gd`, `main.tscn`, and the rest of the player core — out of
> `godot/` into `docs/godot/answer-key/`. `godot/` is now the bare lesson-0001
> shell, so these `godot/scenes/main.gd` → `godot/scripts/main.gd` moves no longer
> describe the current tree; the canonicalized layout lives in the answer-key
> (`docs/godot/answer-key/scripts/main.gd`, `scenes/main.tscn`). Kept for provenance.

The learner explicitly approved execution via `$ultragoal`. The live scene driver
`godot/scenes/main.gd` and its `.uid` sidecar were moved to `godot/scripts/main.gd`,
and `godot/scenes/main.tscn` now references `res://scripts/main.gd`. No duplicate
`godot/scenes/main.gd` remains. The previously named orphan `godot/scenes/title.gd`
was already absent when this slice ran, so there was no title script to move.

This is a reference-track/housekeeping slice — it does **not** advance the lesson
log.

---

*Maintain this file as the design↔lesson contract: when a lesson ships and opens a
new design door, tick the integration map; when a backlog raster moves ⏳→✅, note it
here and in `IMAGE-MODEL-BACKLOG.md`. The lesson log stays simulation-only.*

## Reference-track changelog

- **2026-06-14 — Phase 0 housekeeping:** canonicalized `main.gd` under `godot/scripts/`, rewired `main.tscn`, confirmed the stale scene-local `title.gd` was absent, and recorded that this non-counting reference-track work does not advance the lesson log.

