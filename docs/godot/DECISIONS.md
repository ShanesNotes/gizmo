# Gizmo Godot port decisions

## ADR-001 — Use a contained `godot/` project
- Decision: keep all Godot files under `godot/`.
- Why: protects the Phaser/TypeScript seed and root playable build while giving Claude Code a runnable teaching target.
- Rejected: root-level Godot project files; too easy to pollute the seed/reference build.

## ADR-002 — Teach headless simulation first
- Decision: port `game-src-phaser/src/game/simulation.ts` before visuals.
- Why: `GODOT-PORT.md` identifies it as the mechanics source of truth, and headless tests make small lessons verifiable.
- Rejected: direct full scene/UI port; high parity risk and weak learning value.

## ADR-003 — Target Godot 4.6.x stable by default
- Decision: teach against Godot 4.6.x stable. Planning identified 4.6.3 stable as the latest target on 2026-06-14; local verification used `4.6.2.stable.mono.official`.
- Why: stable releases are better for learning than RC builds, and any 4.6.x stable should preserve this first teaching shell.
- If `${GODOT_BIN:-godot}` reports a different stable 4.6.x version, record it here before continuing; do not switch to 4.7 RC without an explicit decision.

## ADR-004 — Use Godot-native naming from lesson one
- Decision: snake_case files/folders and PascalCase node/class names.
- Why: follows Godot style guidance and prevents conceptual names like `Simulation.gd` leaking into actual filenames.

## ADR-005 — Preserve unrelated dirty work
- Preflight observed before this prep:
  - `M design-handoff/IMAGE-MODEL-BACKLOG.md`
  - untracked `design-handoff/brand/ka3-app-icon-*`
  - untracked `tmp/`
- Decision: execution edits only the approved teaching/Godot prep files.
## ADR-006 — Commit Godot UID sidecars
- Decision: keep Godot-generated `.uid` sidecar files with their scripts/resources and do not add `*.uid` or `*.import` to `.gitignore`.
- Why: Godot 4.4+ uses UID sidecars as project state for scripts/resources; the Godot team says `.uid` files should be committed and moved with their source file.
- Rejected: treating `.uid` sidecars as disposable cache like `godot/.godot/`.

## ADR-007 — `/teach` is the engine; this prep is grounding
- Decision: run the global `/teach` skill from this directory as the teaching
  engine. Added its scaffold — `MISSION.md`, `NOTES.md`, `RESOURCES.md`,
  `reference/`, `learning-records/` (starts at 0001), `lessons/` — alongside
  `docs/godot/*` grounding. `/teach` is the only teaching engine for this repo,
  and project-local/generated mentor-skill drafts are non-canonical.
- Why: the user wants a from-zero, publishable HTML lesson guide, separate from
  their other (`game-dev`) workspace. `/teach` computes the zone of proximal
  development from `learning-records/`, which starts empty here.

## ADR-008 — Set aside the pre-built port as an answer key
- Decision: move the pre-built Godot project (`project.godot`, `scenes/main.tscn`,
  `scripts/simulation.gd` + tests) out of `godot/` to `docs/godot/answer-key/`,
  leaving `godot/` an empty skeleton. Verified still passing at the new path.
- Why: the spirit is **co-development paced for understanding** — build the port
  together at learning pace, not start from a finished solution. The answer key
  is for checking direction and unblocking, not copy-paste. `godot/` empty means
  lesson 0001 ("create the project") is real.
- Note: this is *co-development*, not a purist "learner types every line" rule —
  the AI explains and writes code alongside the learner; the bar is that the
  learner can explain each piece.


## ADR-009 — Simulation owns player movement; PlayerAvatar3D displays it
- Decision: keep player position/velocity/facing in `godot/scripts/simulation.gd`; `scripts/main.gd` translates InputMap actions into a plain input dictionary; `scripts/sim_space.gd` maps flat x/y into 2.5D stage x/z; `scripts/player_avatar_3d.gd` applies snapshots to the scene.
- Why: the Phaser source of truth is a pure simulation. Duplicating movement in both a Godot controller and the simulation would create drift. Keeping the coordinate seam explicit prevents renderer-owned fields from leaking into state.
- Rejected: independent `Player.gd` movement rules that bypass simulation state; permanent `Camera2D`/`Node2D` presentation for the active path.

## ADR-010 — Quarantine generated prep drafts instead of publishing them
- Decision: move generated/recovered `docs/godot/prep/` material to `.omx/rescue-quarantine/` and keep source-visible docs focused on learner-facing lessons, trust boundaries, and verified references.
- Why: the prep tree duplicated lessons and contained implementation-shaped drafts that conflicted with the editor-first teaching contract.
- Rejected: leaving dense prepass handoffs beside the active lesson path where they look canonical.


## ADR-011 — Teach flat simulation with orthographic 2.5D presentation
- Decision: pivot the active Godot path early to `Node3D` + orthographic `Camera3D` presentation while keeping `Simulation` flat and headless-testable. `SimSpace` is the sole coordinate boundary: sim x/y maps to Godot x/z, and Godot y is visual height only.
- Why: Gizmo wants the readability and charm of a 2.5D stage, but its rules stay simpler, testable, and faithful to the Phaser seed as flat 2D mechanics. The learner has only demonstrated project creation, so this pivot happens before a 2D scene model becomes learner-owned.
- Rejected: a permanent parallel `main_3d.tscn`; moving gameplay into `CharacterBody3D`; adding renderer-owned fields such as z, position_3d, global_position, transform, or visual height to simulation snapshots.


## ADR-012 — Full from-zero reset: relocate ahead-of-learner code into the answer-key
- Decision: on 2026-06-15, after a learning-process audit (`docs/godot/LEARNING_AUDIT.md`) found the integration lessons (0004/0007/0008) collided with rescue code that ran ahead of the learner — "Replace the file" instructions that would clobber the verified `simulation.gd`, and lesson 0008 dumping a finished five-script system as a black box — the learner chose a **full from-zero reset**. ALL ahead-of-learner code (`simulation.gd`, `main.gd`, `sim_space.gd`, `player_avatar_3d.gd`, `camera_rig_3d.gd`, `hud_presenter.gd`, `scenes/main.tscn` + `player.tscn`, `ui/theme.tres` + the panel component, and every `run_*`/`capture_*` test) was **moved out of `godot/` into `docs/godot/answer-key/`**. `godot/` is once again the bare lesson-0001 project shell: `project.godot` reset to a freshly-created state (no main scene, no input actions) with only `.gitkeep` scaffolding dirs.
- Re-pivot: the answer-key, previously a pre-pivot 2D shell, is **replaced by this verified 2.5D snapshot**, so the only reference the learner consults to "check direction" matches the active ADR-011 2.5D path. Verified on Godot 4.6.2: `import` + all four `run_*_tests.gd` pass at `docs/godot/answer-key/`; `godot/` imports clean as an empty shell.
- Why: the teaching contract (ADR-007/008, `MISSION.md`) is co-development paced for understanding — nothing lands as a black box. Code ahead of the learner that lessons silently overwrite or assume *is* that black box. Resetting makes every "create this file" honest and lets the player core be rebuilt from zero, one win per lesson.
- Consequence: lessons 0002–0008 are drafts to be **rebuilt against the shell** during co-development; lesson 0008 must be split into the roadmap's five micro-lessons (InputMap → Simulation movement → SimSpace → PlayerAvatar3D → Main wiring). Supersedes the "Current live Godot rescue baseline" framing in `PORT_MAP.md` and the "verified code ahead" `LESSON_LOG.md` entries — those now describe the answer-key, not `godot/`.
- Backup: the complete pre-reset state (both the old 2D answer-key and the live 2.5D `godot/`) is preserved at `.scratch/from-zero-reset-backup-2026-06-15/`.


## ADR-013 — Adopt the "clanker preserving the spark of humanity" premise as canon
- Decision: on 2026-06-16, adopt the narrative premise — *Gizmo is a clanker tasked with preserving the spark of humanity, protecting it from ever-encroaching dehumanized technology, in a gouache cosmos filled with lost tech.* Canon lives in `design-handoff/NARRATIVE.md`; every other doc cites it instead of restating a one-liner.
- Why: the premise gives the existing mechanics a reason and unifies them — Spark = rescued humanity, enemy shapes = dehumanized tech, Caches/reliquaries = lost tech, the gouache art direction = the cosmos. It is a fiction layer over a frozen system.
- Consequence: the standalone "neon spark re-illuminates an ancient codex" one-liner is demoted; the illuminated-manuscript craft is retained as the **UI/ceremony sub-motif** (the Codex = the record of preserved sparks), not the premise. README and the design docs point to `NARRATIVE.md`.
- Rejected: discarding the manuscript/Codex design work (it stays as the interface ceremony); rewriting the design handoff or any token/economy/asset to match the new premise (none change).

## ADR-014 — Adopt the Game Dev Balance Reference Artifact as the tuning reference
- Decision: bring the Game Dev Balance Reference Artifact into the repo at `reference/game-balance-reference.md` as the external tuning reference, and add `docs/godot/BALANCE_MODEL.md` mapping its vocabulary onto Gizmo's actual systems (that file owns the full mapping).
- Why: Gizmo is a bullet-heaven/survivors-like; the artifact is a directly-applicable balance bible. Mapping it now gives the port a shared tuning language and guardrails before numbers get copied blindly.
- Decision (deepening, recorded not built): per artifact §14, balance values are a **data table, not constants**. The Godot port should introduce a `Balance` Resource as the single tuning seam (the test surface for §11.3 balance tests) once the port grows past a handful of constants — reached during co-development, not built ahead of the learner.
- Rejected: porting `simulation.ts`'s scattered `const` knobs verbatim as the long-term shape.

## ADR-015 — Gizmo character animation comes from the gouache raster walk sheet
- Decision: the player **avatar animation** source is the painterly raster sheet at `art/character/gizmo-walk-source.png`, held as a **source asset** and imported only after Aseprite cleanup, when the lesson reaches player animation. Sheet geometry and the import pipeline live in `docs/godot/ASSET_IMPORT_PLAN.md` §"Player character animation".
- Why: the locked art direction is matte gouache; an animated painterly Gizmo fits the cosmos better than the flat vector `gizmo.svg` for the *player avatar*. The vector `gizmo.svg`/`gizmo-illuminated.svg` stay canonical for branding, UI, and static states.
- Consequence: the sheet is NOT placed in `godot/` now — that would run ahead of the learner (ADR-008/012).
- Rejected: importing the raw sheet straight into `godot/` before cleanup; replacing the vector emblem/brand assets.

## ADR-016 — `CONTEXT.md` is the orientation keystone; one canonical owner per truth
- Decision: add a root `CONTEXT.md` as the single deep orientation module (domain glossary + architecture vocabulary + a doc-ownership map), and reduce the duplicated "grounding"/method/anchor blocks scattered across `CLAUDE.md`, `MISSION.md`, `NOTES.md`, `RESOURCES.md`, `GODOT-PORT.md`, and `README.md` to pointers. Each kind of truth gets exactly one canonical owner (the §5 map in `CONTEXT.md`).
- Why: orientation was a shallow interface restated 4–7 times (the grounding list in `NOTES` ≈ `RESOURCES`; the loop one-liner in 4 docs). Deleting any one copy didn't reduce complexity — it caused drift. One deep module with high leverage and real locality fixes that and is the input the architecture-review lens itself expects.
- Consequence: the global "CONTEXT.md + docs/adr/" convention is satisfied by `CONTEXT.md` + the existing `docs/godot/DECISIONS.md` ADR log (no parallel empty `docs/adr/` is created).
- Rejected: gutting the machine-loaded `CLAUDE.md` teaching contract (it stays inline — it is the always-loaded instruction); creating a second ADR directory.
