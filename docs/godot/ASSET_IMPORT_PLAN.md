# Godot asset and design import plan

Goal: translate the Lumen Codex look into Godot without hand-rolling replacements. Use `design-system/`, `design-handoff/`, and `art/` as sources; copy into `godot/assets/` only when a lesson needs the asset.

## Non-negotiables
- Warm:cool ≈ 9:1; cool color is an event, not a wash.
- Only red and gold may saturate. Gold carries light/reward; red carries cost/danger.
- No generic AI sheen, rarity-glow spam, fog/bokeh mysticism, sacred/religious imagery, halo treatment, or emoji.

## Concrete import groups
| # | Source | Godot destination | Use |
|---|---|---|---|
| 1 | `art/character/gizmo-walk-source.png` (animated, gouache — primary player avatar); `design-system/assets/sprites/gizmo.svg`, `gizmo-illuminated.svg` (vector — brand/UI/static states) | `godot/assets/sprites/gizmo/` | Player avatar (animated) + branding/static (vector) — see §"Player character animation" below |
| 2 | `design-system/assets/sprites/enemy-*.svg` | `godot/assets/sprites/enemies/` | Drifter/bumper/counterfeit/behemoth families |
| 3 | `design-system/assets/sprites/pickup-spark.svg` | `godot/assets/sprites/pickups/` | Spark/XP pickup |
| 4 | `design-system/assets/sprites/pickup-heart.svg` | `godot/assets/sprites/pickups/` | Recovery pickup |
| 5 | `design-system/assets/sprites/pickup-cache*.svg`, `cache-reliquary.svg` | `godot/assets/sprites/caches/` | Cache and cache-open states |
| 6 | `design-system/assets/sprites/covenant-emblems.svg` | `godot/assets/sprites/ui/` | Flow/Clutch/Echo/Surge emblems |
| 7 | `design-system/assets/sprites/rarity*.svg` | `godot/assets/sprites/ui/` | Rarity ladder and upgrade cards |
| 8 | `design-system/assets/brand/emblem*.svg` | `godot/assets/brand/` | Title/branding; secular emblem only |
| 9 | `design-system/assets/screens/*.png`, `design-handoff/screens/*.png` | `godot/assets/reference/screens/` or docs-only reference | Visual comparison references, not final UI textures |
| 10 | `design-system/tokens/colors.css` | `godot/ui/theme.tres` and optional color constants | Void, field, panel, lumen, gold, oxblood, Flow, Clutch, Echo, Surge |
| 11 | `design-system/tokens/typography.css`, `fonts.css` | `godot/assets/fonts/` | Fredoka display/numbers, Cormorant Garamond labels/verdicts, Nunito UI |
| 12 | `design-system/tokens/spacing.css` | `godot/ui/theme.tres` and effect timings | Radii, spacing, motion/eases for panels and juice |
| 13 | `design-system/components/core/*.prompt.md` | `docs/godot/ui-component-notes.md` then `godot/ui/components/` | Button, Panel, Pill, Keycap, Meter, Seal, Eyebrow |
| 14 | `design-system/components/game/*.prompt.md` | `godot/ui/components/` | UpgradeCard, BoostButton, BreathRow, StatCell, VerdictBar |
| 15 | `design-handoff/assets-fusion/*.svg` | `godot/assets/fusion/` | Fusion Codex alternate/expanded art source |
| 16 | `art/` | `godot/assets/reference/art/` if needed | Extra reference only; do not replace design-system truth |

## Token mapping starter
- `--void`, `--field`, `--field-2` → project background and playfield colors.
- `--panel`, `--panel-solid`, `--scrim` → `Control` panel styles and modal dim.
- `--lumen`, `--lumen-dim`, `--lumen-faint` → primary/secondary/faint text.
- `--gold-leaf`, `--gold-tarnished`, `--bole` → reward lines, frames, and illuminated borders.
- `--oxblood`, `--vermilion`, `--coral` → cost, health, danger.
- `--flow`, `--clutch`, `--echo`, `--surge` → four economy accents.
- glow alpha tokens → sparing particles/glows only after gameplay reads clearly.

## Player character animation (ADR-015)

The player avatar's animation source is the painterly raster walk sheet at
`art/character/gizmo-walk-source.png` — Gizmo the clanker (brass body, glowing
cyan spark-core, purple cape).

- **Sheet geometry:** 1774×887, an **8 columns × 4 rows** grid (~221.75px cells,
  ~32 frames) — four directional walk cycles. Cells are slightly non-integer, so
  the grid must be regularized in cleanup.
- **Cleanup (Aseprite, done by the artist):** remove the grey background
  (transparent), trim/register frames to a consistent cell size and pivot, name
  the rows by facing (e.g. down/left/right/up — confirm against the sheet), export
  back to a clean sheet (and/or per-direction strips).
- **Godot import (when the lesson reaches it — after `PlayerAvatar3D`):**
  - 2.5D billboard route: `Sprite3D` (billboard, unshaded, alpha-scissor) with
    region/`AnimatedSprite3D` frames driven by simulation facing; or
  - sprite route: `SpriteFrames` resource + `AnimatedSprite2D`/`3D`, animations
    keyed `walk_down/walk_left/walk_right/walk_up`, picked by the simulation's
    `facing`.
  - The presenter selects the animation from the Simulation snapshot's facing —
    the sheet never drives rules (ADR-009).
- **Do not** place the sheet in `godot/` before cleanup or before the gating
  lesson (ADR-008/012: no code/assets ahead of the learner).
- The vector `gizmo.svg` / `gizmo-illuminated.svg` stay canonical for the title
  emblem, HUD, and any static/illuminated state.

## Import procedure per lesson
1. Copy the exact source asset into `godot/assets/...` with snake_case filenames.
2. Record the source path in the commit or lesson log.
3. Let Godot import the asset; keep generated `godot/.godot/` ignored.
4. If rasterizing SVG, export PNG at 2x and keep the SVG source beside it.
5. Verify the visual against `design-system/ui_kits/lumen-codex/` or `design-handoff/screens/`.
