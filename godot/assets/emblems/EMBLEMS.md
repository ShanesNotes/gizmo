# Gizmo Emblem Library — contracts

Harvested from the studio parent grammar (**Symbolic Illuminated**) and recoloured to `/tokens`, then
re-mapped to Gizmo motifs (M1–M9) after a per-emblem **Resemblance-trap / G11** test. These are **2D
witness / HUD / spec-layer** assets — **NOT** 3D world art (G12 still open). Each SVG is a 64×64
two-plate drawing (off-register colour plate + ink line + interior hatch). *Derived from canon
package; do not edit as source* (edit `/canon` + `/tokens`, then re-derive).

| Emblem | Motif | Register | Notes (after the M4/G11 test) |
|---|---|---|---|
| `sun.svg` | M6 celestial (day) | living | Rayed disk + worked centre. The **living** register adds a serene **face** (faced = alive); the disk alone is the base. |
| `moon.svg` | M6 celestial (night) | living ↔ hollowed | Crescent + stars. **Pacing arc removed (G5 — no timing device.)** Living night = add a face; hollowing = **void** the face (socket + fracture). *Night ≠ evil.* |
| `lamp.svg` | M8 beacon | living | Vigil lantern, warm flame. Rekindled/living frame; an **active** beacon adds a teal core-spark (G6); a **dormant** beacon snuffs/cools it. |
| `thorn.svg` | M9 decay | hollowed | Bramble; encroaches from the margin as exposure rises. |
| `seal-cracked.svg` | M9 decay | hollowed | Damaged-but-**holding** wax seal (endurance under stress). **NOT the de-face operator** — de-facing is the presence/absence of a **face** (M4), a different drawing. |
| `thread.svg` | M4 / B-face (repair) | re-humanizing | Needle + gold thread = **mend**, scar honored. **NOT M5 wayfinding** (that is the unbroken path/braid/light-stream stroke; never a depleting meter — B-thread/ADR-0001). |

**Recurrence rule (G0-safe, falsifiable):** an emblem may repeat freely; it is a FAIL only to paste it
*identically across a state change it is meant to register* (e.g. an M4 living→hollowed transition).

**Colour map (parent → /tokens):** ink `#2a2230`→`ink.warm #352c2b`; gold `#bb8a39`→`metal.gold_deep
#c9906b`; straw `#ecca82`→`metal.gold_lit #e0c17a`; oxblood `#8c2435`→`accent.crimson_deep #b14455`;
blue `#2a4468`→`cool.night_blue #2a4468`. States recolour at use (living = warm/ink; hollowed =
slate/drain). Standalone files carry the **living/neutral** palette; the HTML witnesses inline
`var(--c-…)` so they respond to world-state.

**Provenance:** parent emblems `assets/emblems/{sun,moon,lamp,thorn,seal,seal-cracked,thread}` on the
claude.ai/design project *Symbolic Illuminated*; pulled + recoloured 2026-06-21. Contact sheet +
before/after witness renders: `extraction/emblem-harvest/`.
