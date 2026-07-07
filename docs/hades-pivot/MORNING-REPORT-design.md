# MORNING REPORT — design lane (night of 2026-07-07)

Lane: UI/UX & LOOK · branch `night/design` off `origin/gizmo-3d` · Fable orchestrator + Codex (xhigh) codev.

## TL;DR

**G12 — the gouache render target — is implemented, toggled, and proven by before/after
screenshots.** The whole game now reads hand-painted: Kuwahara brush pooling, edge-ink
lines, paper tooth, all below the UI layer. HZ-108B world-state tinting is live. The HUD
is rebuilt to the gizmo-hud.png brass language. *(Report updated in waves through the night.)*

## Ceremony shots — `docs/hades-pivot/ceremony/design/`

- `g12-hub-before.png` / `g12-hub-after.png` — the flagship A/B. Squint at the dais.
- `g12-run-room-before.png` / `g12-run-room-after.png` — combat room A/B (the after also
  shows the first HUD brasswork landing mid-night).
- *(more added as screens finish)*

## Wave log

### Wave 1 — G12 + HZ-108B (commit `ff1fbda`)
- **SHADER-ARCH-01 ruled** (design-system's fork to call): painterly post = subtle
  whole-frame canvas_item accent on the existing below-UI GradeLayer. UI is masked by
  construction; runs on Forward+ *and* gl_compatibility; one-post rule kept. Ruling
  recorded lab-side: `gizmo-design-system/extraction/reconciliation-2026-07-07-shader-arch-01.md`.
- `gouache_grade.gdshader`: small-radius Kuwahara (r=3) + edge-ink pooling toward
  `ink.warm` + two-octave paper grain. Honest finding: Kuwahara alone is a near no-op on
  flat greybox — the grain + edge ink are what carry the gouache read until L4 baked
  surfaces exist.
- **Toggle**: `gizmo/look/gouache_paint_enabled` project setting; `scripts/ui/look_grade.gd`
  zeroes every accent when off. Revert is one flag.
- **HZ-108B**: `tokens.state.*` tints in-engine — hub warm (sanctuary.ground), combat
  ember-tense (pressured.accent), cleared relief (sanctuary.frame) — tweened 1.2s on
  `room_entered`/`room_cleared`, feature-detected so the core lane can't break us.
- Bug found & fixed live: unseeded shader params aren't tweenable (runtime error caught
  via MCP screenshot run, seeded in `_ready`).

### Wave 2a — HUD rebuild (commit `1b7d9fc`, Codex brief 1)
- Brass/leather filigree framing on nameplate, sparks/scrap readouts, spark meter,
  ability slots. Shield bar luminous teal with top-glow edge (G6: teal = guard only).
  HP cells flash-then-desaturate on tick-down (the "crack" read). Three violet
  spark-cast pips. Boon rows → rarity-tinted framed slots. Region toast → parchment
  caption-bar, 30px. hud.gd public API + test node names preserved; 84 checks green,
  independently rerun.

## Theme publisher check (backlog #7) — FINDING

`make publish-godot-theme` publishes to the **hardcoded play checkout**
(`/home/ark/gizmo/godot/scenes/hud_theme.tres`) and `--out` refuses to leave the lab —
running it tonight would have written outside the worktree. Did NOT run it. Instead
regenerated the local witness and diffed: **worktree theme is fresh** (byte-identical).
Follow-up filed: add a `GIZMO_GAME_ROOT` override so ADR-0002 publishes can target a
worktree.

## Open / in flight

- Codex brief 2 (keepsake draft as illuminated manuscript) and brief 3 (screens sweep)
  — see wave log updates below as they land.
- PerfProbe A/B (paint on/off) scheduled for the quiet-worktree verification pass.
- Third-room G12 A/B pair wants in-run navigation; hub + first combat room shipped first.

## Follow-ups for INDEX

- HZ-108B: mark in-engine tinting DONE (design half); region voice dialects remain lore's.
- New: theme publisher worktree-override (small, tools/gen_godot_theme.py).
- New: promote `look.brush_*` slots only after level-design's silhouette probe under
  combat density (G12 promotion path; pass is flag-gated for cheap rejection).
