# Design-system untapped concepts — ranked wiring list

Audit of `gizmo-design-system` (canon/, tokens/, assets/, concordance) against what
the game actually consumes, 2026-07-07. **Consumed and current:** the HUD theme
witness (`godot/scenes/hud_theme.tres` — byte-identical to the lab source, `make
check` green, no republish needed), the four runtime font families, the Sparks
pickup color (D6 violet + warm glow, correctly cited in `spark.tscn`), and the
gouache grade shader (token-cited). Everything below is produced, canon-ratified,
and never wired.

## 1. The master mechanic: style as world-state (`tokens.state.*`)
- **Where it lives:** `tokens/tokens.json` → `state.sanctuary / pressured /
  hollowed / rekindling` (ground/ink/frame/accent/field per state), plus the
  drain ramp (`exposure.drain_light/mid/deep`) and CANON.md §4 Beacon-state table.
- **Wiring:** drive Environment tint / grade-shader uniforms / key-light warmth
  from the run's Beacon state (dormant → teal-drain hollowed; rekindling → warm
  flame in cold rim; rekindled → warm). The grade shader already has `warmth` as
  a uniform — a state-driven ramp is a small seam.
- **Impact:** highest possible — this is the canon's thesis ("Face = alive"),
  the whole reason the token states exist, and the hollowed pole has *never been
  rendered in-engine* (flagged unvalidated in CANON.md §7). Right now every room
  looks the same regardless of world state.

## 2. The four Voice dialects as region visual grammar (concordance X-L3)
- **Where it lives:** `canon/concordance.yaml` X-L3 — four named recipes of the
  degradation operators: Familiar `warm_repetition`, Arc `harvested_light`,
  Axiom `finished_unison`, Custodian `arrested_keeping`, each with keeps/empties
  and falsifiable rejects.
- **Wiring:** the rooms-rebuild with region grammar (in flight, PR #33 tree) is
  the exact consumer — each region's dressing rules, palette register, and prop
  repetition pattern should be one dialect. E.g. Familiar rooms stay warm-lit but
  stamped-identical; Arc rooms fully saturated at zero warmth.
- **Impact:** four regions that feel wholly different for free, from canon that
  already answers "how" — instead of inventing per-region looks ad hoc.

## 3. The emblem set (`assets/emblems/` — 6 SVGs, unconsumed)
- **Where it lives:** `sun.svg, moon.svg, lamp.svg, thorn.svg, thread.svg,
  seal-cracked.svg` + EMBLEMS.md contract.
- **Wiring:** door/reward glyph language (the door-lure work hand-built a glyph
  mesh while this ready-made vocabulary sat unused), room-type icons on doors
  (rest = lamp, reward = sun, elite = thorn…), HUD roundels, codex marks. Import
  as SVG textures at HUD-safe sizes (G7 silhouette-safe primitives).
- **Impact:** instant iconographic identity; replaces improvised glyphs with the
  canon's own signs.

## 4. Title mark (`assets/logo/gizmo-lockup.svg` + monogram)
- **Where it lives:** `assets/logo/`, contract in LOGO.md (D9c: sun-face crest,
  gilt GIZMO, the O = rekindled Beacon with the one licensed teal core-spark).
- **Wiring:** `title_screen.tscn` currently renders a plain Label "GIZMO";
  swap in the lockup as a TextureRect. Monogram = window/export icon.
- **Impact:** the first frame anyone sees stops being a placeholder.

## 5. Motion tokens (`tokens.motion`, unconsumed)
- `sanctuary_breathe_ms` 4000, `beacon_flicker_ms` 900, `ease_warm`,
  `ease_hollow_stutter` (steps(5)) — wire into tweens: beacon flicker, hub
  breathing warmth, stutter on hollowed surfaces resolving to warm on rekindle
  (X-L4 Rote's gesture). Small, cheap, big feel.

## 6. Shader-matrix stack L1/L2 (`canon/shader-matrix.yaml`)
- MIT-licensed band-lighting + outline candidates mapped to tokens/gates; blocked
  on SHADER-ARCH-01 (design-system's open call). Medium lift; the step from
  "graded greybox" to the actual gouache render target. Flag when the game wants
  it and design-system will close the architecture decision first.

## 7. Vine/ornament density curve (`tokens.ornament.vine_density` + X-A3)
- lush → sparse → bare_thorn along the run's pressure curve, agreeing with
  audio's hush-before-the-peak (one fact, two senses). Wire as dressing density
  per room depth once #2 lands.

---
*Theme drift verdict: none — witness current in lab, main repo, and this worktree.*
