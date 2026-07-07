# MORNING REPORT — assets lane (characters & animation) · 2026-07-07

Lane: `night/assets` · Fable 5 lead + 3 Codex co-devs · **zero meshy spend**
(no meshy MCP/API access existed in the session — balance could not even be
checked; every deliverable went through the ratified free paths, which the
backlog fully supported).

## Shipped (PR #36, merged 07:08Z)

**1. Gizmo's full authored moveset** (`gizmo_clips.glb`, authored at 50fps so
SwingTiming contacts land on exact frames):
- Contact-true swing combo `attack_1/2/3` (0.10/0.10/0.14s) + `special`
  (0.22s) — the code-owned-swings ruling is superseded; code poses remain the
  guarantee tier. Weapon mount follows the authored swing arm (Bone_019).
- `spark_cast` (release 0.15s), `hit`, `death`, `victory`, run/dash refresh.
  [wave 3: `cast_started` now actually routes to `spark_cast` — it was still
  reusing the `attack` swing when this line was first written.]
- Personality: `idle_fidget_key` (winds his own key) + `idle_fidget_chirp`
  (head-tilt, bobs at 0.50/0.70s for the audio lane). [wave 3: the 7s
  alternating standing-idle scheduler that fires them now exists in
  `gizmo_animator.gd` — the clips were authored in wave 1 but no driver played
  them until wave 3.]
- **Lore lane: the campfire cinematic clip is named `campfire_sit`** (3.2s
  seated loop). Drive it via **`GizmoAnimator.play_campfire_sit()`** — it
  deactivates the blend tree so the looping seat pose owns the skeleton; call
  `resume_locomotion()` to hand control back. [wave 3: the clip was authored in
  wave 1 but had no takeover method until wave 3 — a direct `ClipPlayer.play`
  would have been overridden by the active AnimationTree.] Note: the WeaponMount
  stays visible — hide it for the shot.

**2. Enemy roster clips** (bruiser + elite rigged GLBs):
- `attack` strikes keyed EXACTLY to brain windups (0.85s / 1.05s; key-readback
  delta 0.00000s), `hit_front`/`hit_back` directional reacts, `stagger` loop
  (shield-break ready — additive, no core-lane dependency taken), `spawn`
  materialize, decommission deaths. Controller picks direction by chase-target
  side; spawn yields to anything gameplay-driven.
- Chaff drone stays procedural by test-pinned ruling (wobble/tumble in
  enemy_visual.gd) — no rig owed.

**3. Weapon family 2 groundwork**: `lantern_staff_01` — procedural bpy
(1720 tris, emissive spark-glass core), wrapper + provenance + in-hand grip
proof at the fixed camera. **Core lane handoff: HZ-110 in queue/INDEX.md**
(wrapper is the interface; wire kit mechanics whenever).

## Shipped (PR #2 of the night — custodian)

**4. The Pattern's vessel**: `custodian_boss.glb` — 9-bone rig authored on the
meshy body, 5 clips: idle menace loop, `phase_shift` halo-flicker flourish,
`attack` (overreach slam, strike at the code's 1.20s telegraph), `attack_sweep`
(audit sweep, 0.90s), death = **the halo guttering out** (3 diminishing
flickers, then the slump). Codex read boss_brain.gd itself and keyed to the
real per-attack telegraphs instead of my briefed 1.05s guess. Playback wired
through CustodianVisual (composes with the presiding procedural layer).
**Decimation debt settled**: 1.35M → 140k faces, texture capped 2048→1024,
44MB → ~8MB.

## Wave 3 (night revival — closing the wiring gap)

The lane was revived mid-night. Audit finding: waves 1-2 **authored** every
backlog-#1 clip into `gizmo_clips.glb` (verified — re-running
`tools/animation/author_gizmo_clips.py` produces a byte-identical GLB) but three
were never **wired** into the controller, while this report already described
them as shipped. Wave 3 makes the report true. All wiring lives in
`godot/scripts/player/gizmo_animator.gd` (fence-clean; no swing-timing or
resolver edits):

- **`spark_cast`** — `cast_started` now fires the dedicated underhand-lob clip
  (added as a 5th one-shot slot) instead of reusing the `attack` swing.
- **`campfire_sit`** — new `play_campfire_sit()` takeover for the lore lane (see
  the corrected note above); the clip's loop mode is now preserved through the
  library builder so the seated pose actually loops.
- **Idle fidgets** — a 7s standing-idle alternating scheduler
  (`_tick_idle_fidget`) fires `idle_fidget_key` / `idle_fidget_chirp` in turn;
  resets on movement, any combat one-shot, or while a cinematic/death owns
  playback.
- Provenance sidecar refreshed (was listing 8 of the 15 authored clips).
- Coverage: `run_animation_tests.gd` 61 → 78 checks (spark_cast route, campfire
  takeover, fidget logic + wiring). Full battery green (orchestrator
  contact-damage flake reran clean at 457, per protocol).

Still owed (noted, not blocking): formal `promotion.yaml` for bruiser/elite
lab-side (codex REPORT scratch covers informally); in-engine fixed-camera
capture of `play_campfire_sit()` (the clip's Blender proof already exists).

## Evidence
- `docs/hades-pivot/ceremony/assets/2026-07-07-*` (gizmo clip proofs, enemy
  contact sheets, lantern-staff grip, custodian clip sheet).
- Lab ledger: `gizmo-asset-pipeline/runs/2026-07-07-night-assets/RUN.md` +
  promotion reports (`briefs/character/gizmo_clips.promotion.yaml`,
  `briefs/props/lantern_staff_01.*`).

## Battery
All ten suites green at each merge (player 155, enemy 213, boss 110,
orchestrator 428, animation 61, simulation 89, balance 43, game_controller 16,
room_graph 1328, integration_gate 1296). Play checkout synced under lock.

## Follow-ups filed
- HZ-110 (INDEX): core lane wires lantern-staff kit mechanics.
- Bruiser/elite retro-debt: clip + camera-proof items recorded settled on
  their lab briefs; Blender cleanup/wrapper items still owed (tracked there).
- Known cosmetic: weapon visible during campfire_sit/fidgets (lore lane hides
  the mount for cinematics).
