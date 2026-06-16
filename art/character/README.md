# art/character — Gizmo player avatar (source)

Source art for the in-game player character, Gizmo the clanker (brass body,
glowing cyan spark-core, purple cape). See `design-handoff/NARRATIVE.md` for who
he is and `docs/godot/ASSET_IMPORT_PLAN.md` §"Player character animation" for the
import pipeline.

## `gizmo-walk-source.png`

- The raw animated walk sheet: **1774×887, 8 cols × 4 rows** (~32 frames,
  ~221.75px cells), four directional walk cycles, grey background.
- **Status: source — not import-ready.** Clean in Aseprite first (transparent
  background, trim/register frames to a consistent cell + pivot, name rows by
  facing), then export and import into `godot/assets/` — and only when the lesson
  reaches player animation (after the `PlayerAvatar3D` slice).
- Do **not** copy this into `godot/` ahead of that lesson (ADR-008/012: no assets
  ahead of the learner). ADR-015 records the pipeline decision.

The vector `design-system/assets/sprites/gizmo.svg` / `gizmo-illuminated.svg`
remain canonical for the title emblem, HUD, and static/illuminated states.
