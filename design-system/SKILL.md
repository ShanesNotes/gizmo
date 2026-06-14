---
name: gizmo-design
description: Use this skill to generate well-branded interfaces and assets for Gizmo — "The Lumen Codex" design system (a kid-friendly neon-arcade survivors-like fused with illuminated-manuscript craft), either for production or throwaway prototypes/mocks. Contains essential design guidelines, colors, type, fonts, assets, and the game UI-kit components for prototyping.
user-invocable: true
---

# Gizmo — The Lumen Codex

A spark re-illuminates a sleeping codex, and the dopamine becomes a verdict. Neon charge (Flow mint, Clutch cyan, Echo violet, Surge gold) sits inside ancient gold-ground over a deep indigo void. **The hinge is gold — every reward reads as an "illumination."**

Read **`readme.md`** first — it holds the full design guide: CONTENT FUNDAMENTALS (voice/tone/casing), VISUAL FOUNDATIONS (color, type, panels, motion, the "page apparatus"), and ICONOGRAPHY. Then explore:

- **`styles.css`** + `tokens/` — link `styles.css` for all CSS custom properties and the three webfonts (Fredoka · Cormorant Garamond · Nunito). Tokens: colors (void/matter/charge), typography (the `.lumen-inscription` recipe), spacing/radii/shadows/motion, plus `.lumen-stipple` / `.lumen-frame` / `.lumen-seal` utilities.
- **`components/`** — reusable React primitives. Core: Button, Panel, Pill, Keycap, Meter, Seal, Eyebrow. Game: CovenantRoundel, UpgradeCard, StatCell, BreathRow, VerdictBar. Each has a `.prompt.md` with usage.
- **`ui_kits/lumen-codex/`** — interactive recreation of the four game screens (Title, HUD, Level-Up, Results); a model for composing the components.
- **`assets/`** — all SVG sprites (gizmo, enemies, pickups, covenant emblems, rarity ladder, the upgrade-chip icon atlas) + brand emblems and raster finals. **Copy these out; never hand-roll replacements.**
- **`guidelines/`** — foundation specimen cards (color/type/spacing/brand).

## Working rules
- If creating visual artifacts (slides, mocks, throwaway prototypes), **copy assets out** and produce static HTML files for the user to view, linking `styles.css` and using the token variables. For production code, copy assets and read the rules here to design as a brand expert.
- Honor the non-negotiables: warm:cool ≈ 9:1 (cool is an event); only red & gold saturate; **gold carries light, red carries cost, ink makes it official.** Charged empty space frames every payoff. No generic-AI sheen, no rarity-glow spam, no fog/bokeh mysticism, no religious/sacred imagery (the gold aureole is secular geometry, never a halo). No emoji in copy.
- If the user invokes this skill without guidance, ask what they want to build, ask a few focused questions, then act as an expert designer who outputs HTML artifacts *or* production code as needed.
