# HZ-102B — Gouache look pass (what changed visually)

**Status:** done · **Worker:** Claude (Fable visual principal) · **Fence:** scene files + new shader only

The greybox now reads art-directed instead of unlit-engine-grey. One paragraph, then the receipts:
Every room, the run fallback, the hub, and the legacy arena now carry a soft gouache grade at the
Environment level — filmic tonemap + gentle contrast, pole-correct saturation (warm rooms bloom
slightly richer, drain rooms sit slightly ashen), a soft-light glow that makes emissives pool like
wet paint, and a per-mood fog bed (slate-teal drain in combat, deeper drain in elite, brass/amber
in shop and rest, gilt in reward, violet-plum void in boss — all colors traced to
`gizmo-design-system/tokens/tokens.json`, gate G1). On top of the 3D frame (and *below* all UI —
CanvasLayer −1, so HUD/pause/boon-draft are never double-styled) a new screen-reading grade shader
`godot/shaders/gouache_grade.gdshader` adds warm diffusion (mip-blur screen-blend), a parchment/ink
split-tone, and an ink-warm vignette. Subtle by default; all four strengths are shader uniforms.

## Mechanism (per canon/shader-matrix.yaml)

SHADER-ARCH-01 is still **open** and Layer 3 (painterly post) is blocked on it — so this pass is
deliberately **not** a Kuwahara/brush CompositorEffect and claims no `look.brush_*` slot (G12
honesty). It is an environment/material-stack grade + a canvas finishing pass, per the matrix's
own recommendation ("baked-first; post as subtle accent"). Everything no-ops headless.

## Reconciliation finding (HZ-077 vs runtime — file, don't pick silently)

**HZ-077's per-room Environment moods were never visible during actual runs.** Godot activates the
*first* `WorldEnvironment` in tree order per world; `run.tscn`'s own WorldEnvironment sat before
`%Rooms`, masking every room's Environment (verified empirically with a headless probe, Godot
4.7). Fix shipped here, scene-file-only: run.tscn's WorldEnvironment is now the **last** node, so
an instanced room's Environment takes precedence and run's acts as the between-rooms fallback
(probe confirmed precedence + restore-on-free). Only room `KeyLight`s were carrying mood before;
now ambient/fog/grade land too. **Follow-up for the game lab (out of my fence):** run.tscn still
has a neutral white `DirectionalLight3D` (energy 1.25) that stacks on every room's mood KeyLight
and washes it toward noon — consider deleting it or dimming it to a fill (~0.3) now that room
environments actually apply.

## What to eyeball (no live screenshot available to this agent)

1. Run a full run: combat rooms should feel slate-teal dusk with a faint depth haze; shop/rest
   glow brass-warm; boss arena sinks into violet void with strongest contrast.
2. Corners of the frame settle into warm ink (never neutral black); emissive exit pads and the
   Beacon-warm materials should bloom softly.
3. G6 check: Gizmo's teal eye/core must stay a scarce spark — the soft-light glow should not
   spread it into an ambient bloom (glow_intensity ≤ 0.45 everywhere; hdr_threshold default 1.0).
4. HUD, pause menu, boon draft must look untouched (grade sits at CanvasLayer −1).

## Files

- NEW `godot/shaders/gouache_grade.gdshader` (G10 provenance stamp + token comments inside)
- `godot/scenes/run.tscn` — WorldEnvironment moved last + graded; GradeLayer/GradeRect added
- `godot/scenes/hub.tscn` — env grade + GradeLayer/GradeRect
- `godot/scenes/rooms/{combat_small,combat_large,elite_arena,shop_small,rest_alcove,reward_cache,boss_arena}.tscn` — per-mood fog/glow/adjustments
- `godot/scenes/main.tscn` — conservative env-only grade (legacy arena)

Gates satisfied: G1 (all hues token-traced), G6 (no new teal surfaces), G9 (drain baseline,
no crimson field), G10 (stamp), G12 (no shader-target overclaim). Suites: see gate run below.

*derived from canon package; do not edit as source*

## Addendum — presentation beats (slice 2)

Four threshold beats, all cosmetic, all red-first: (1) room-entry settle — RoomCamera starts 15%
pulled back along its offset and eases in over 0.6s as a pure _process overlay (hard-cut and
bounds-clamp pins untouched; see `settle_overlay`); (2) room-clear shine — RoomDoor pulses a warm
gold_lit OmniLight3D ("UnlockShine", 0.45s decay) when a door unlocks; sealed doors snuff it;
(3) death/victory fade — EndScreen's Root modulate eases 0→1 over 0.8s (INK_FADE_SECONDS) so the
ink scrim rises before the title lands; visibility/label contracts unchanged (integration pins
green); (4) boss push-in — `push_in(1.0)`/`release_push()` overlay on RoomCamera, invoked from the
nameplate hold via guarded has_method calls. New checks live in run_room_camera_tests (+3 tests),
run_end_screen_tests (+1), run_room_door_tests (+1).
