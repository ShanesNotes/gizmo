# Phase 1 visual smoke — Lumen Codex Theme + Panel family

> **Snapshot — read as history (captured pre-ADR-012 reset).** The
> `theme.tres`, `panel.tscn`/`panel.gd`, and `capture_panel_visual_smoke.gd`
> files referenced below now live in `docs/godot/answer-key/`, **not** `godot/`.
> This record is preserved as a point-in-time Phase-1 PASS, not a description of
> the current `godot/` shell.

Status: **PASS for the approved narrow Phase 1 reference-track slice**.
This is a screenshot-backed smoke check, not a pixel-parity claim. It is explicitly
subordinate to `docs/godot/DESIGN_TO_LESSON_HANDOFF.md` and the approved ralplan
PRD/test spec.

## Source anchors

- Teaching/design bridge: `docs/godot/DESIGN_TO_LESSON_HANDOFF.md`
- Concrete asset groups: `docs/godot/ASSET_IMPORT_PLAN.md` groups **#10–#13**
- Token sources: `design-system/tokens/colors.css`, `typography.css`, `spacing.css`
- Component contract: `design-system/components/core/Panel.prompt.md`
- React reference behavior: `design-system/components/core/Panel.jsx`
- Broader screen references: `design-system/ui_kits/lumen-codex/`
- Captured Godot baseline: `docs/godot/visual-smoke/panel_phase1_smoke.png`
- Capture harness: `godot/tests/capture_panel_visual_smoke.gd`

## Implemented in Godot

- `godot/ui/theme.tres` exposes the Phase 1 Lumen token subset:
  - dark surfaces: void/field/panel/panel_solid,
  - warm ink: lumen/lumen_dim/lumen_faint,
  - rule/reward/cost accents: gold_leaf/gold_tarnished/oxblood/coral,
  - economy accents retained as tokens only: flow/clutch/echo/surge,
  - spacing/radius/type-size constants needed by Panel.
- `godot/ui/components/panel/panel.tscn` and `panel.gd` implement only the Panel family:
  - dark-glass `PanelContainer` surface,
  - gold, danger, and plain tone rule-lines,
  - 12px rounded page-apparatus corners,
  - 16x12 content margins,
  - optional dashed inner rule,
  - uppercase manuscript-style eyebrow and dim body text.

## Checklist

- [x] Panel surface reads as the Lumen Codex dark page apparatus, not a generic bright card.
- [x] Gold/default tone uses the tarnished-gold rule line from token group #10.
- [x] Danger tone switches to coral/red cost language without introducing new art.
- [x] Plain tone is restrained and uses faint lumen hairline language.
- [x] Dashed inner rule can be toggled like the React `dashed` prop.
- [x] Eyebrow text uppercases and uses the gold manuscript label treatment.
- [x] Slice remains narrow: no Button, Meter, UpgradeCard, HUD, sprites, fonts, or raster assets were imported.
- [x] Lesson log remains simulation-first; this reference-track checklist does not advance lesson numbering.
- [x] A 640×360 Godot viewport PNG baseline is committed for future visual checks.

## Reproduce the captured baseline

The screenshot harness needs a real display driver; `--headless` uses Godot's
dummy renderer and is still reserved for syntax/instantiation checks.

```bash
godot --path godot --display-driver x11 --rendering-driver opengl3 \
  --audio-driver Dummy --resolution 640x360 \
  --script res://tests/capture_panel_visual_smoke.gd
```

Expected output:

- `docs/godot/visual-smoke/panel_phase1_smoke.png`
- PNG dimensions: 640×360
- visual: dark void ground, centered dark-glass panel, tarnished-gold border,
  dashed inner rule, uppercase gold eyebrow, dim body text.

## Known deferrals

- Brand fonts named by `fonts.css` are mapped as token intent/size only; actual font asset import waits for a future lesson that needs fonts.
- Shadows are approximated with Godot `StyleBoxFlat`; exact CSS multi-shadow/glow and stipple radiance wait for later visual polish.
- Full scene pixel parity waits until this Panel is placed into a real HUD/level-up lesson scene.
