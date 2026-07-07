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
  The SHIPPED controller `gizmo_animation_controller.gd` (the `AnimationController`
  node in `gizmo_player.tscn`) plays `spark_cast` on the CAST state / cast
  retrigger — reachable in-game as shipped in wave 1.
- Personality: `idle_fidget_key` (winds his own key) + `idle_fidget_chirp`
  (head-tilt, bobs at 0.50/0.70s for the audio lane) — the 7s alternating
  standing-idle scheduler lives in the shipped `gizmo_animation_controller.gd`
  (wave 1); reachable in-game.
- **Lore lane: the campfire cinematic clip is named `campfire_sit`** (3.2s
  seated loop). **Seam (corrected in wave 3): call
  `play_campfire_sit()` on the shipped `gizmo_animation_controller.gd`** — it
  holds the looping seat pose and makes `update_animation()` stand down until
  `resume_from_cinematic()`. The opening's Gizmo is currently the raw
  `gizmo.glb` (no clips, no controller), so the lore lane must attach an
  `AnimationController` to it — see the HZ handoff in `queue/INDEX.md`. Note:
  the WeaponMount stays visible — hide it for the shot.

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

## Wave 3 (night revival)

The lane was revived mid-night. Verified finding: waves 1-2 authored every
backlog-#1 clip into `gizmo_clips.glb` (re-running
`tools/animation/author_gizmo_clips.py` produces a byte-identical GLB) AND the
shipped controller `gizmo_animation_controller.gd` already grafts them and drives
`spark_cast` (CAST state), the 7s idle-fidget scheduler, and the `campfire_sit`
graft — so the report's wiring claims above were accurate as shipped in wave 1.
**Correction:** an earlier pass of this note wrongly attributed those to
`gizmo_animator.gd` (the alternate AnimationTree consumer, which is NOT
instantiated in any scene) and implied the claims were false — they were not.

The ONE genuine gap: the shipped controller grafted `campfire_sit` but exposed
no public trigger, and `update_animation()` would override any cinematic pose
every frame. Wave 3:

- **`play_campfire_sit()` / `resume_from_cinematic()` on the shipped
  `gizmo_animation_controller.gd`** — the real lore-lane seam. Sets a cinematic
  hold so `update_animation()` stands down; loops the seat pose. (`HZ-111` in
  `queue/INDEX.md`: the lore lane attaches an `AnimationController` to the
  opening's raw-`gizmo.glb` Gizmo and calls this.) Covered in
  `run_player_tests.gd` (155 → 161 checks, incl. hold-suppresses-state-map).
- **Parity for the second recognized clip consumer** `gizmo_animator.gd` (the
  boot spec names both controllers): added its `spark_cast` slot, a matching 7s
  idle-fidget scheduler, and a `play_campfire_sit()` takeover so the alternate
  pipeline handles the same clips if it is ever adopted. Covered in
  `run_animation_tests.gd` (61 → 78 checks). Note: this consumer does not ship
  yet — no scene instantiates it — so this is consistency work, not a shipped fix.
- Provenance sidecar refreshed (was listing 8 of the 15 authored clips).
- Full battery green (orchestrator contact-damage flake reran clean at 457).

Fence-clean: only the two clip-consumer controllers + their tests + provenance;
no swing-timing / resolver / scene / opening edits.

Still owed (noted, not blocking): the two enemy `promotion.yaml` files record a
real gate item — bruiser/elite embed 2048 albedo over the enemy 1024 cap (geometry
+ clips + proof all pass); resolve next asset session by capping to 1024 (custodian
precedent) or a design-choice budget waiver. In-engine fixed-camera capture of
the campfire seam this wave (below).

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
