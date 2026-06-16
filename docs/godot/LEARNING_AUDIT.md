# Gizmo Godot Teaching Scaffold — LEARNING AUDIT

**Date:** 2026-06-15
**Auditor:** synthesis lead (10-dimension review, adversarially verified)
**Subject:** Co-development teaching scaffold for porting *The Lumen Codex* (Phaser/TS) to Godot 4.6.2 GDScript, from-zero.

## Executive verdict

The machine baseline is perfect and the architecture is clean — but the **learning process is not yet rock solid**, and it breaks at the worst possible place. All 12 empirical verification gates pass on Godot 4.6.2.stable.mono (import, 7 syntax checks, 4 `run_*_tests.gd` suites green), the live `godot/` project is fully ADR-011-compliant (flat headless simulation, orthographic Camera3D, `SimSpace` as the sole x/y→x/z seam, zero renderer fields in snapshots), and the seed-fidelity and naming spines are sound. However, the lesson scaffold collapses at the climactic integration lessons: **lesson 0008 dumps a finished five-script system as a black box** (InputMap + the SimSpace coordinate seam + three presenter scripts, two with no shown body + a full `main.gd` rewrite) for a learner whose demonstrated ZPD is only lesson 0001; **lessons 0004/0007/0008 say "Replace the file" / "Add" against live ahead-of-learner files** (the 306-line gate-passing `simulation.gd`, the presenters) with no disclosure they already exist; and **lesson 0002 never sets the `%Title` unique-name marker** that lesson 0007's `%Title` requires, guaranteeing a null crash on the learner's first "running game". The spine is trustworthy; the failures are concentrated, located, and mechanically fixable — but until lesson 0008 is split, the ahead-of-learner code is reconciled instead of clobbered, and the SimSpace seam is taught back as its own win, the co-development contract is violated exactly where the payoff lives.

**Overall status: RED.** P0 × 5 · P1 × 8 · P2 × 7.

## Empirical gates

All gates run in order against Godot `4.6.2.stable.mono.official.71f334935` (`godot` on PATH). Independently re-confirmed during synthesis.

| Project | Command | Result |
|---|---|---|
| godot/ | `godot --headless --path godot --import` | PASS (exit 0, no SCRIPT ERROR) |
| godot/ | `--check-only --script res://scripts/simulation.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://scripts/main.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://scripts/sim_space.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://scripts/player_avatar_3d.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://scripts/camera_rig_3d.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://scripts/hud_presenter.gd` | PASS (exit 0) |
| godot/ | `--check-only --script res://ui/components/panel/panel.gd` ¹ | PASS (exit 0) |
| godot/ | `--script res://tests/run_simulation_tests.gd` | PASS — "Simulation tests passed" |
| godot/ | `--script res://tests/run_player_scene_tests.gd` | PASS — "Player scene tests passed" |
| godot/ | `--script res://tests/run_presentation_3d_tests.gd` | PASS — "Presentation 3D tests passed" |
| godot/ | `--script res://tests/run_ui_smoke_tests.gd` | PASS — "UI smoke tests passed" |
| answer-key | `--headless --path docs/godot/answer-key --import` | PASS (registers `class_name Simulation`) |
| answer-key | `--check-only --script res://scripts/simulation.gd` | PASS (exit 0) |
| answer-key | `--script res://tests/run_simulation_tests.gd` | PASS — "Simulation tests passed" |

¹ **Gate-path correction (itself a finding):** `panel.gd` lives at `godot/ui/components/panel/panel.gd`, NOT `godot/scripts/ui/components/panel/panel.gd`. Anyone scripting gates from the task text verbatim hits a "file not found" failure on panel.

**Out of scope (display/GPU dependent, intentionally NOT gated):** `godot/tests/capture_main_2_5d_visual_smoke.gd` and `capture_panel_visual_smoke.gd` `push_error` that they require a real display driver; under `--headless` the dummy rasterizer yields empty PNGs. They are artifact-capture steps, not pass/fail gates, and were excluded from `all_passed`.

**Bottom line:** the verification spine is real — every gate is green, every canonical command quoted in `CLAUDE.md`, `LEARNING_PATH.md`, `PORT_MAP.md`, and the lesson test-runs resolves to a script that returns exit 0 with its documented success print. No gate points at a non-existent script in the lesson chain, and no quoted command is empirically failing.

## Dimension scorecard

| Dim | Title | Status | One-line |
|---|---|---|---|
| D1 | 2.5D Pivot Consistency | 🟡 | Live code/scenes pure Node3D + orthographic Camera3D, SimSpace sole seam, no renderer fields; stale answer-key Node2D shell + RESOURCES.md Camera2D + 0003 framing keep it off green. |
| D2 | Lesson vs Live-Code / Answer-Key Fidelity | 🟡 | Correct API signatures & naming, but P0 missing `%Title` marker (0002→0007 crash), `$Name`-vs-`%Title` error, FaceMarker omission, unshown presenter bodies. |
| D3 | Lesson vs Seed Fidelity | 🟢 | Every load-bearing constant and the movement port verbatim-faithful to `simulation.ts`; disputed wall-clamp test is correct; only P3 polish. |
| D4 | Pedagogical Soundness & Sequencing (ZPD) | 🟡 | Honest incremental arc & strong red/green discipline, but 0008 is a ZPD cliff and its scene-assembly win has no closing regression gate. |
| D5 | Teaching-Contract Adherence | 🔴 | Early lessons honor the contract; 0008 Part 3 dumps a finished 5-script black box and 0004/0007 "Replace the file" would clobber verified ahead-of-learner code. |
| D6 | Verification-Gate Correctness | 🟡 | All 12 gates re-confirmed green; weakened by 0002's `res://` main_scene promise (live is `uid://`) and 0008 gating only the sim while the presentation win goes unverified by two existing passing suites. |
| D7 | HTML Lesson Technical Quality | 🟡 | All 8 files well-formed, self-contained, correct space→tab copy buttons; missing `kbd{}` CSS in 0002–0005 and no copy button in 0003 (first paste-code lesson). |
| D8 | Forward-Path Integrity & Black-Box Risk | 🔴 | Gates green & architecture clean, but the next lesson is not cleanly executable: SimSpace seam + 2 presenters land as a triple black box; 0004 collides with the live 306-line simulation. |
| D9 | Naming / Structure / Repo Hygiene | 🟡 | 100% snake_case, correct PascalCase, paired `.uid` sidecars, contained project; defects are `unique_id=453854140` on main.tscn:22, the stale Node2D answer-key, and doc miscites. |
| D10 | Source-anchor Accuracy | 🟡 | Every load-bearing anchor resolves exactly; clamp math verified; two real defects — fabricated `baseWidth` (PORT_MAP:27) and `camera_rig.gd` vs live `camera_rig_3d.gd` (PORT_MAP:56). |

## Prioritized remediation plan

Per the co-development contract, the P0/P1 pedagogy items below are **recommendations to act on with the learner**, not changes to auto-apply. `safe-auto` items are mechanical doc/CSS edits safe to apply directly.

### P0 — blockers (the learning process is broken here; fix before teaching past 0003)

- [ ] **[D5/D8] Lesson 0008 dumps a finished 5-script system in one slice (black box, multi-win)** — `lessons/0008-the-player-moves.html:186-245` — Split into at least 3 lessons: (a) movement-rules-in-`simulation.gd` + headless test (current Parts 1-2, already self-contained); (b) the SimSpace seam as its own win; (c) wiring avatar/camera/HUD + `main.gd`. Do not present steps 1-7 of Part 3 as one lesson. *(co-dev-decision)*
- [ ] **[D5/D8] Lesson 0008 names `sim_space.gd` / `camera_rig_3d.gd` / `hud_presenter.gd` with no body while live files exist undisclosed** — `lessons/0008-the-player-moves.html:201,203` (called at `:239-242`) — Promote SimSpace to its own slice showing the live `sim_space.gd` body (sim x→Godot x, sim y→Godot z, Godot y=0) line-by-line; show or explicitly mark `camera_rig_3d.gd::follow_stage_position` and `hud_presenter.gd::apply_state` as pre-built presenters to **read, not recreate**. Never call a method whose body the learner has not seen. *(co-dev-decision)*
- [ ] **[D5/D8] Lesson 0004 "Replace the file" would clobber the live 306-line gate-passing `simulation.gd`** — `lessons/0004-first-game-state.html:113-147` (live `godot/scripts/simulation.gd` = 306 lines: `STATE_SCHEMA_KEYS`, `PLAYER_SCHEMA_KEYS`, `_update_player`, `next_xp_for_level`) — Reconcile the ADR-008 "empty skeleton" premise with the populated live tree: either quarantine the ahead-of-learner code (move rescue copy aside, learner authors the subset in a fresh/teaching branch) or convert every "create/replace" step into "open and read the existing file." Add a disclosure box; do not silently overwrite a green baseline. *(co-dev-decision)*
- [ ] **[D2] Lesson 0002 never sets the `%Title` unique-name marker that 0007's `%Title` requires → guaranteed null crash** — `lessons/0002-first-scene-and-play.html:124-127` vs `lessons/0007-state-on-screen.html:123` vs live `godot/scenes/main.tscn:74` (`unique_name_in_owner = true`) — After "a Label named Title" in 0002, add a step: "Right-click Title → **Access as Unique Name** (so it shows `%Title`)." Also teach `%` vs `$` so the marker is a concept, not a magic flag. *(safe-auto, with concept note)*

### P1 — serious (undermine trust / pacing; fix before the integration arc)

- [ ] **[D2/D4] Lesson 0007 mental-model bullet teaches `$Name`/`$Title` while its own code (and live code) uses `%Title`** — `lessons/0007-state-on-screen.html:167,172` — Change `:167` to `@onready + %UniqueName = a safe reference to a scene-unique node (Access as Unique Name); $Path is the alternative for fixed child paths`; fix the curiosity prompt at `:172` to `%Title vs $HUD/Root/Title`. `$Title` from `Main` would genuinely fail (Title is nested under HUD/Root). *(safe-auto)*
- [ ] **[D2] Lesson 0008's taught `player_avatar_3d.gd` omits the FaceMarker the live script/scene require** — `lessons/0008-the-player-moves.html:202,205-213` vs live `player_avatar_3d.gd:8,13` + `player.tscn:36-39` — Either add a `FaceMarker` MeshInstance3D under Visuals and the `_face_marker.position.x` flip, OR add a one-line "the live avatar adds a FaceMarker for facing — deferred" note so the lesson version is a declared subset. Prefer the defer-and-note for pacing. *(co-dev-decision)*
- [ ] **[D4] Lesson 0008's scene-assembly win ships with no closing verification gate** — `lessons/0008-the-player-moves.html:183` (sim-only gate) vs `LEARNING_PATH.md:46` — Add `godot --headless --path godot --script res://tests/run_player_scene_tests.gd` (expect "Player scene tests passed") after the scene wiring; this test already asserts exactly the wiring (InputMap, PlayerAvatar3D-via-SimSpace, orthographic+current Camera3D, presenters). *(safe-auto)*
- [ ] **[D6] Lesson 0008 builds the whole 2.5D presentation layer but gates only the flat simulation (false-green)** — `lessons/0008-the-player-moves.html:183` — After the sim gate, add `run_player_scene_tests.gd` and `run_presentation_3d_tests.gd` (both exist and PASS). NOTE: `run_player_scene_tests.gd:40,46` asserts a `Visuals/FaceMarker` (position.x flip) while the lesson teaches `_visuals.rotation.y` — reconcile the avatar contract (resolve with the FaceMarker fix above) or gate on `run_presentation_3d_tests.gd`, which the taught scene satisfies, to avoid a new false-red. *(co-dev-decision)*
- [ ] **[D6] Lesson 0002 promises `run/main_scene="res://scenes/main.tscn"` but the editor-generated live `project.godot:14` is `uid://di7plimb8je4i`** — `lessons/0002-first-scene-and-play.html:144,158` — Change BOTH lines to acknowledge the uid form ("Godot 4.6 records it as a `uid://` reference"); keep `ls godot/scenes/main.tscn` as the path-level confirm. A correct learner currently reads `uid://` as a failure. *(safe-auto)*
- [ ] **[D1/D9] Answer-key reference scene is a pre-pivot `Node2D` shell with no camera** — `docs/godot/answer-key/scenes/main.tscn:3` (`type="Node2D"`) vs live `godot/scenes/main.tscn:22` (Node3D + orthographic Camera3D) — `CLAUDE.md` invites consulting the answer-key to "check direction." Add a one-line banner to `docs/godot/answer-key/README.md`: "main.tscn here is the pre-ADR-011 2D shell; the active 2.5D presentation lives in `godot/scenes/main.tscn`." (Regenerating it to a Node3D rig is contract-unsafe per ADR-008's sim-only scoping — the banner is the right minimal fix.) *(co-dev-decision)*
- [ ] **[D10] PORT_MAP cites a fabricated Phaser camera anchor `baseWidth` absent from the entire seed** — `docs/godot/PORT_MAP.md:27` (also `GODOT-PORT.md:17,28`) — Replace `baseWidth`/zoom with the real API: `MischiefScene.ts setBounds (line 156) / setScroll (157) / startFollow lerp 0.08 (431)`. A future camera-sizing lesson grounded on this anchor would stall. *(safe-auto)*
- [ ] **[D9] `main.tscn:22` carries a non-standard `unique_id=453854140` node attribute the editor never writes** — `godot/scenes/main.tscn:22` — Re-save the scene in the Godot editor so it canonicalizes the root node line, restoring editor-first fidelity for lesson 0002's scene-building teach-back. *(safe-auto via editor re-save)*

### P2 — polish / consistency (fix opportunistically)

- [ ] **[D9] `GODOT-PORT.md` writes the target filename as PascalCase `Simulation.gd`** — `GODOT-PORT.md:16,41` — Write `simulation.gd (class_name Simulation, headless-testable)`; removes the need for the `PORT_MAP.md:58` corrective and aligns with ADR-004. *(safe-auto)*
- [ ] **[D1] RESOURCES.md names `Camera2D` as the project's representative camera concept** — `RESOURCES.md:6` — Replace with `Camera3D` (orthographic); the project uses and tests for Camera3D, and rejects Camera2D (DECISIONS.md:59). *(safe-auto)*
- [ ] **[D7] `kbd{}` CSS rule missing in lessons 0002–0005 despite `<kbd>` usage** — `lessons/0002…html`–`0005…html` (rule present only in 0006–0008:31) — Paste the `kbd{}` rule verbatim from `0006:31-32` into the `<style>` block of 0002–0005. *(safe-auto)*
- [ ] **[D7] Lesson 0003 (first paste-GDScript lesson) has no copy-to-clipboard button** — `lessons/0003-first-gdscript.html:119-130` — Port the copy `<script>` + `.copy-btn` CSS from `0004` (0003's block already uses literal tabs, so space→tab is a no-op). *(safe-auto)*
- [ ] **[D4] Lesson 0007's `$Name` accessor bullet (duplicate of D2 item, ZPD-framed)** — `lessons/0007-state-on-screen.html:167` — Also add a scene step marking Title "Access as Unique Name" so `%Title` actually resolves at runtime (the accessor fix alone is incomplete). *(safe-auto)*
- [ ] **[D4] Unexplained `_process`→`_physics_process` swap between 0007 and 0008** — `lessons/0008-the-player-moves.html:229` — Add one note: input + fixed-step simulation belong in `_physics_process` (fixed 60Hz, stable dt); the 0006 dt-clamp still protects against spikes. The lesson currently poses the question (0008:277) but never answers it. *(co-dev-decision)*
- [ ] **[D10] PORT_MAP naming example `camera_rig.gd` contradicts live `camera_rig_3d.gd`** — `docs/godot/PORT_MAP.md:56` — Change to `camera_rig_3d.gd` (or a neutral existing file like `sim_space.gd`); the same doc names it correctly at `:32`. *(safe-auto)*

### Confirmed non-findings (logged so they are NOT "fixed" by mistake)

- **The 0008 right-wall clamp test (x=2529 → 2530) is CORRECT.** Recomputed: blend = 1−exp(−23·0.05) ≈ 0.683 → vx ≈ 181.8 → next.x ≈ 2538.1 > 2530 (WORLD_WIDTH 2600 − PLAYER_WORLD_MARGIN 70) → clamps to 2530.0. Matches the passing `run_simulation_tests.gd:120-122`. Disregard the earlier "test is wrong" concern.
- **Naming-rule fidelity is clean for lessons 0002/0007/0008.** Node names (PascalCase), `class_name` identifiers, and filenames (snake_case) all obey ADR-004; no `Simulation.gd`-style filename leak in any lesson.

## Forward path

**Lesson 0009 should NOT be "pickups & XP" yet.** The most important corrective is to repair the integration frontier before adding new mechanics. Recommended near-term sequence (decomposing lesson 0008 per `LESSON_ROADMAP.md:29-34`):

1. **0008 (keep):** movement rules in `simulation.gd` + headless test — current Parts 1-2 are self-contained and gate-passing (`run_simulation_tests.gd`).
2. **Next slice — the SimSpace seam (its own win):** open and read the existing `godot/scripts/sim_space.gd`. Teach it as the SOLE ADR-011 coordinate boundary: sim x → Godot x, sim y → Godot z, Godot y = 0 (visual height only). Close with the existing `run_presentation_3d_tests.gd` (it asserts the coordinate-seam math).
3. **Next slice — PlayerAvatar3D + player.tscn:** build the avatar including the live FaceMarker; teach `apply_snapshot` as a display adapter that owns no rules.
4. **Next slice — wiring:** `main.gd` + InputMap actions + the two presenters; close with `run_player_scene_tests.gd` (`LEARNING_PATH.md:46`).
5. **Then** the original "pickups & XP" becomes the genuine next win.

**Teach-back plan for ahead-of-learner code.** The live `godot/` runs ahead of the learner (ZPD = lesson 0001 only). This is *verified code*, not *verified understanding* — it must be taught back, never dumped:

- **`sim_space.gd`** — teach as its own lesson (item above). It is the architectural crux; one sentence + a magic call is the exact black box the contract forbids.
- **`camera_rig_3d.gd`** (`follow_stage_position`, ~3 lines) and **`hud_presenter.gd`** (`apply_state`, ~6 lines) — show their full bodies inline and explicitly frame them as "pre-built display-only presenters to open and read, not recreate." They are NOT in the answer-key (which holds only `simulation.gd`), so showing them is authoring teaching content, not pasting the answer-key.
- **Presentation tests** (`run_player_scene_tests.gd`, `run_presentation_3d_tests.gd`) — currently passing but cited in NO lesson. Surface them as the closing gates for their respective slices so the learner's wiring is gated by a real regression test, not an eyeball "press Play."
- **Reconcile the repo-state contradiction:** ADR-008 promises an "empty skeleton" but `godot/` is populated. Decide once, with the learner: either quarantine the ahead-of-learner code so lessons author it fresh, OR rewrite "create/replace" steps as "open and read the existing file." Every "Replace the file" instruction must stop colliding with a green baseline.

`LESSON_ROADMAP.md` stops at 0008 while `DESIGN_TO_LESSON_HANDOFF.md:16` cites it as the "0001–0012 spine" — add the planned 0009–0012 rows (pickups/XP, level-up sim, level-up UI, emblem title) so the forward path is computable from the roadmap, not reverse-engineered. (The authoritative `/teach` spine is `LEARNING_PATH.md`, whose later phases do cover this — so this is a doc-accuracy fix, not a blocked path.)

## How to keep this rock solid — maintenance checklist

- [ ] **Re-run all 12 gates after every lesson** (import → 7 syntax checks → 4 `run_*_tests.gd`). Green is the floor, not the ceiling.
- [ ] **One win per lesson.** If a lesson attaches a script, that script's body must be shown or explicitly marked "read, don't recreate." No callable method without a visible body.
- [ ] **Never "Replace the file" on live ahead-of-learner code without a disclosure box.** Author subsets in a teaching context; reconcile, don't clobber.
- [ ] **Every lesson closes with a named verification command** that gates the actual win (the scene-wiring lesson gates the scene tests, not just the sim).
- [ ] **Compute the next lesson from `learning-records/`, not from hardcoded `✓ done` breadcrumbs** in the draft HTML (only lesson 0001 is demonstrated).
- [ ] **Keep the answer-key honest about direction:** if it stays frozen at the pre-pivot 2D shell, the README banner must say so; the live `godot/` is the authoritative 2.5D reference.
- [ ] **Treat misquoted/stale citations as findings.** Anchors (seed line numbers, filenames, gate paths) must resolve exactly — re-verify `baseWidth`-class fabrications and `camera_rig.gd`-class miscites.
- [ ] **Re-save edited scenes in the editor** so machine-written attributes (e.g. a stray `unique_id=`) stay canonical and match what lesson 0002 teaches the learner to produce.
- [ ] **`--check-only` returns exit 0 even on a missing script** — never trust a syntax gate's pass without confirming the path exists (the `panel.gd` path error is the live example).

---

## Remediation status — 2026-06-15 session

**Decisions taken (by the learner):** (1) **Full from-zero reset** — relocate all ahead-of-learner code into the reference quarantine; (2) **apply all safe-auto fixes now**; (3) **re-pivot the answer-key to 2.5D**.

### Done this session

- **Root-cause structural reset (ADR-012).** All ahead-of-learner code (`simulation.gd`, `main.gd`, `sim_space.gd`, `player_avatar_3d.gd`, `camera_rig_3d.gd`, `hud_presenter.gd`, both scenes, `theme.tres` + panel component, all tests) **moved out of `godot/` into `docs/godot/answer-key/`**. `godot/` reset to the bare lesson-0001 shell (`project.godot` stripped of main scene + input actions). This directly resolves the two **RED** dimensions' root cause: the 0004/0007/0008 clobber risk (D5-3, D8-2) and the assume-undisclosed-files black box (D5-2, D8-1) — there is no longer ahead-of-learner code in `godot/` to clobber or silently assume.
- **Answer-key re-pivoted to 2.5D.** Replaced the stale 2D `Node2D` shell with the verified 2.5D snapshot. Resolves D1-1, D9-4. Verified: `import` + all four `run_*_tests.gd` pass at `docs/godot/answer-key/`; `godot/` imports clean as an empty shell. Pre-reset state backed up at `.scratch/from-zero-reset-backup-2026-06-15/`.
- **Doc-correctness fixes applied:** `baseWidth` fabrication → real camera mechanism in `PORT_MAP.md` + `GODOT-PORT.md` (D10-1, D3-2, D8-6 framing); `camera_rig.gd` → `camera_rig_3d.gd` (D10-2, D9-3); `Camera2D` → `Camera3D` in `RESOURCES.md` (D1-2); `Simulation.gd` filename casing → `simulation.gd` in `GODOT-PORT.md` (D9-2); added the planned 0009–0012 spine to `LESSON_ROADMAP.md` so the handoff's "0001–0012" citation is honest (D8-4). Spine docs (`DECISIONS` ADR-012, `LESSON_LOG`, `LEARNING_PATH`, `PORT_MAP`, `LESSON_ROADMAP`) reconciled with the reset.
- **HTML hygiene applied:** added the missing `kbd{}` rule to lessons 0002–0005 (D7-1); added the full copy-to-clipboard infrastructure (CSS + `position:relative` + tab-emitting `<script>`) to lesson 0003, the first GDScript-paste lesson (D7-2).

### Folded into the co-development rebuild (NOT auto-applied — these are the learner's lessons)

Because lessons 0002–0008 are now drafts to **rebuild from the shell, one win per lesson**, the remaining lesson-*content* findings are addressed when each lesson is rebuilt with the learner, not by polishing soon-to-be-rewritten drafts:

- **Split lesson 0008** into the roadmap's five micro-lessons: InputMap → Simulation movement → `SimSpace` seam (its own win) → `PlayerAvatar3D` → `Main` wiring (D5-1, D8-1/3, D4-1).
- 0002 `%Title` unique-name marker + 0007 `$Name`→`%Title` accessor (D2-1/2, D4-3); FaceMarker in the player avatar (D2-3); honest "create" (not "Replace") framing now that files don't pre-exist (D5-3); 0008 closes with the scene/presentation gate, not the sim-only gate (D4-2, D6-2); `_process`→`_physics_process` transition explained (D4-4); 0002 verification-output text matches an editor-generated project (D6-1).
- Re-derive `simulation.gd`/`main.gd` as honest subsets that converge on the answer-key (D5-4, D3-1), with anchors re-verified against the seed (D10-3, D3-2).

### Path to GREEN

1. Co-develop the rebuilt lessons via `/teach`, lesson by lesson, verifying each against the answer-key and a closing gate. 2. Append a `learning-records/` entry as the learner demonstrates each. 3. Re-run the `gizmo-learning-audit` workflow to confirm D1–D10 all green and the gates pass against the rebuilt `godot/`.