# Gizmo Godot port map

This map keeps Claude Code teaching grounded in the current web seed. The Phaser/TypeScript project remains the source until a Godot slice is tested.

## Source-of-truth order
1. Mechanics: `game-src-phaser/src/game/simulation.ts` (`WORLD_WIDTH = 2600`, `WORLD_HEIGHT = 1700`, `RUN_DURATION = 240`, `createGameState()`, `updateGameState()`).
2. Feel: root playable build, served with `npx serve .`.
3. Look: `design-system/`, `design-handoff/`, especially `design-system/tokens/colors.css` and `design-handoff/FUSION-CODEX.md`.
4. Port guidance: `GODOT-PORT.md`.

## Mechanics map
| Web seed | Responsibility | Godot target | First teaching slice |
|---|---|---|---|
| `simulation.ts` `GameState` | Full run state: phase, elapsed, player, enemies, pickups, timers, economies | `godot/scripts/simulation.gd` with `class_name Simulation` | Build `create_game_state()` dictionary with world, run, player, upgrades, empty enemies/pickups |
| `simulation.ts` `WORLD_WIDTH/WORLD_HEIGHT/RUN_DURATION` | Core constants | Constants in `simulation.gd` | Test 2600x1700, 240 seconds |
| `simulation.ts` `createGameState()` | Initial state | `Simulation.create_game_state()` | Test player centered, level 1, spark rank 1 |
| `simulation.ts` `updateGameState()` | One tick of pure logic; clamps `dt` to `0.05` | `Simulation.update_state(state, input, dt)` | Test elapsed advances by max `0.05` and phase remains valid |
| `simulation.ts` upgrade helpers | Upgrade ranks, choices, rerolls | Later `godot/scripts/economies/upgrades.gd` or resource data | Defer until initial state tests pass |
| `simulation.ts` Flow/Clutch/Echo/Surge/Bounty | Economies and streak logic | `godot/scripts/economies/*.gd` | Add one economy per lesson |

## Scene/input/camera map
| Web seed | Responsibility | Godot target | Notes |
|---|---|---|---|
| `game-src-phaser/src/phaser/MischiefScene.ts` | Scene loop, input, camera, effects | `godot/scenes/main.tscn` | Minimal placeholder until headless tests pass |
| `MischiefScene.ts` player movement | Input vector and velocity | `godot/scripts/simulation.gd` movement + `godot/scripts/player_avatar_3d.gd` display adapter through `godot/scripts/sim_space.gd` | Simulation owns rules; PlayerAvatar3D displays snapshots on the 2.5D stage |
| `MischiefScene.ts` spawn orchestration | Enemy/pickup creation | `godot/scripts/spawner.gd` | Keep driven by `Simulation` data |
| Phaser camera `setBounds` + `setScroll` + `startFollow` (no zoom) | Responsive view | orthographic `Camera3D` under `godot/scenes/main.tscn` with `CameraRig` following the SimSpace-mapped player | Tune `Camera3D.size` by playtesting root web build |
| Phaser events/effects | Hit sparks, pops, shake | `godot/scripts/effects/*.gd` | Add after mechanics parity checks |

## Reference baseline (answer-key, not live in `godot/`)
As of the 2026-06-15 full from-zero reset (ADR-012), `godot/` is the bare lesson-0001 shell. The verified player-core reference lives at `docs/godot/answer-key/` on the active 2.5D path. Rebuild it into `godot/` from zero, one win per lesson; consult the answer-key to check direction, never paste wholesale.

> **How to read every `godot/...` path in the tables above and below.** A `godot/scripts/...` (or `godot/scenes/...`, `godot/ui/...`) target is **the destination inside the learner's shell once that slice is built**, *not* a file that exists there today. After the ADR-012 reset those files do **not** live in `godot/` yet — the verified reference implementation lives in `docs/godot/answer-key/` (e.g. `godot/scripts/simulation.gd` → `docs/godot/answer-key/scripts/simulation.gd`). The mapping content itself is unchanged; only the location of the verified copy moved. See `CONTEXT.md` §3 (architecture vocabulary: Simulation → SimSpace → 2.5D stage) and §4 (`godot/` = learner workspace vs. `docs/godot/answer-key/` = verified reference).
- `scripts/simulation.gd` is the mechanics authority: tested first schema plus movement core.
- `scripts/main.gd` reads InputMap actions and passes a plain input dictionary into `Simulation.update_state()`; camera/HUD updates are delegated to display-only presenters in `scripts/camera_rig_3d.gd` and `scripts/hud_presenter.gd`.
- `scripts/sim_space.gd` is the only simulation-to-stage coordinate seam: sim x/y map to Godot x/z, and Godot y is visual height.
- `scripts/player_avatar_3d.gd` / `scenes/player.tscn` are visual adapters only. Do not move gameplay rules there unless a new ADR replaces ADR-009.
- Tests: `tests/run_simulation_tests.gd`, `run_player_scene_tests.gd`, `run_presentation_3d_tests.gd`, `run_ui_smoke_tests.gd`.

## HUD/UI/audio map
| Web seed | Responsibility | Godot target | Notes |
|---|---|---|---|
| `game-src-phaser/src/ui/hud.ts` | DOM HUD values | `godot/ui/hud.tscn` | Use Godot `Control` nodes |
| `game-src-phaser/src/styles.css` | HUD and layout CSS | `godot/ui/theme.tres` | Translate, do not copy CSS blindly |
| `design-system/components/core/*` | Button, Panel, Pill, Meter, Seal, Eyebrow | `godot/ui/components/*.tscn` | Build reusable Control scenes |
| `design-system/components/game/*` | UpgradeCard, BoostButton, BreathRow, StatCell, VerdictBar | `godot/ui/components/*.tscn` | One component per lesson after core loop |
| `game-src-phaser/src/ui/sfx.ts` | WebAudio SFX | `godot/audio/` + `AudioStreamPlayer` | Defer until gameplay loop exists |

## Asset/design map
| Source | Godot target | Rule |
|---|---|---|
| `design-system/tokens/colors.css` | `godot/ui/theme.tres`, color constants/resources | Warm:cool ≈ 9:1; gold carries reward/light, red carries cost |
| `design-system/assets/sprites/` | `godot/assets/sprites/` | Copy existing SVG/PNG; no hand-rolled replacements |
| `design-handoff/assets-fusion/` | `godot/assets/sprites/` and brand sheets | Keep illuminated-manuscript craft, no sacred/halo imagery |
| `design-system/assets/screens/` and `design-handoff/screens/` | visual references only | Use for comparison, not as final UI textures |
| `art/` | `godot/assets/reference/` if imported | Preserve provenance in asset notes |

## Naming rules
- Files/folders are snake_case: `player.gd`, `camera_rig_3d.gd`, `theme.tres`.
- Godot classes/nodes are PascalCase: `Simulation`, `CameraRig`, `Main`.
- Do not copy `GODOT-PORT.md`'s conceptual `Simulation.gd` casing into filenames.

## Godot UID sidecars
Godot 4.4+ may create `.uid` files beside scripts/resources during import. Keep those files versioned and move/delete them with the source file; they are not cache like `godot/.godot/`.
