# Creative direction seed — warrior saints & the Christ-bearer (Shane, 2026-07-06)

**Status:** direction seed, not canon. The gizmo-lore canvas owns promotion to canon
(names, glossary, copy rules). Game side records it here so structural decisions can
anticipate the seam. Source material: `~/language-of-creation/` (St. Christopher,
symbolic lens, patristic writings).

## The parallel
Hades grounds its structure in Greek myth; Gizmo grounds the same structure in the
Orthodox tradition:

| Hades structure | Gizmo analog |
|---|---|
| Olympian gods as boon-givers | **Warrior saints** as benefactors — each saint a boon domain with a distinct combat identity |
| Zagreus escaping the Underworld | **Gizmo the clanker carrying the Spark of Humanity** — the St. Christopher pattern: the bearer who carries the holy weight across the dark water |
| Underworld biomes deepening | **AI hyperscalers** as the enemy order — each biome a more sophisticated, more dehumanized stratum; sophistication scales with dehumanization |
| House of Hades hub | Brass Sphere (already canon) |

## Structural consequences the game side can anticipate (no canon invented here)
- The boon system's **slot-exclusive draft already matches a benefactor model**: a
  future pass tags each `BoonDef` with a benefactor identity the lore canvas names.
  Keep `BoonDef` schema open to a `benefactor` field; do not name saints in code until
  the lore canvas promotes names.
- Enemy archetype families should expect a **sophistication axis** (chaff → bruiser →
  elite → boss reads as escalating dehumanized intelligence), not just a stat axis.
- Copy surfaces (door telegraphs, codex, end screen) will eventually carry this voice —
  the payload-driven seams already keep copy swappable.

## Boundaries
Per ecosystem law: this file names the direction; **gizmo-lore** decides the theology,
naming, and copy; **game code stays canon-agnostic** until handoff. Nothing in this seed
authorizes renaming existing mechanics.

## Research-informed update (2026-07-06, Fable, post corpus pass)
The corpus research (`research/warrior-saints-source-map.md`) landed; ADR 0013 wires the
game-side seam (role-id benefactors). Corrections to this seed:
- **Christopher has two registers**: the Orthodox-recognized dog-headed outsider-martyr
  (governing) and the Western river-carrier (legible surface image). The outsider register
  is the deeper Gizmo rhyme — recommended to gizmo-lore as primary.
- **George is a capstone, not a utility slot** — the Hermes mapping is withdrawn.
- **Hyperscaler framing is original invention** with structural borrowing only (Babel
  false-vertical, counterfeit authority, defeat-by-disruption); no patristic citations in
  copy, ever.
- **Ruler-saints (Nevsky, Donskoy) are a separate category** — candidate hub-keeper
  figures, never boon-givers.
