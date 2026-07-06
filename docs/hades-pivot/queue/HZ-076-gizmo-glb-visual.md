# HZ-076 — Gizmo's real body: gizmo.glb replaces the teal capsule

**Status:** ready-for-agent · **Worker:** Codex · **Deps:** none (visual-only fence)
The character model exists at `godot/assets/gizmo.glb` (meshy.ai, 53-bone rig, NO animation
clips — v1 moves it with code per CLAUDE.md; clips are a later lesson).

## Scope
1. Instance gizmo.glb as the player visual inside `gizmo_player.tscn` (replace/hide the
   capsule mesh; keep the CharacterBody3D collision capsule EXACTLY as-is — physics
   unchanged). Scale/orient the model to the existing capsule footprint (~1.0 radius,
   facing -Z or matching motor facing convention — verify against motor.facing_direction
   usage).
2. Rotate the visual to face `motor.facing_direction` (smooth turn, exported turn speed
   ~10 rad/s lerp) — the model should visibly face where Gizmo moves/attacks.
3. Simple procedural life: idle bob (subtle sine on visual Y), movement lean (slight tilt
   into velocity). Exported amplitudes, tasteful defaults. NO AnimationPlayer clips.
4. Verify headless import works (`--import` on a clean .godot) and the scene loads in
   tests without GPU (visual node must not break headless suites — guard anything
   viewport-dependent).
5. Tests: player suite — visual node exists, faces movement direction after motor updates,
   collision shape unchanged (radius/height asserted).

## Fence
godot/scenes/gizmo_player.tscn, a new gizmo_visual.gd (or player-scene script region for
visual only), godot/assets/ import settings if needed, run_player_tests.gd. Do NOT touch
player_motor.gd logic, vitals, abilities, orchestrator, HUD.
