# Claude Design — "Set up your design system" field guide

Exact answers for each field of the Claude Design setup screen. Attach the **`design-handoff`** folder.

## Company name / design system name
```
Gizmo — "The Lumen Codex" design system
```

## Blurb
```
Gizmo is a kid-friendly bullet-heaven (survivors-like) where a neon spark re-illuminates an
ancient, sleeping codex. The design system, "The Lumen Codex," fuses futuristic neon arcade
with illuminated-manuscript symbolism: flat-vector forms, ink contours, and neon glow resting
on gold-leaf, over a deep indigo void. Premium, mixed-age, dopamine + disciplined minimalism.
```

## Examples / code / folder
- Keep **`design-handoff`** attached (it copies selected files, that's fine).
- Most important for it to learn from: `Fusion-Codex.html` + `FUSION-CODEX.md` (the brief), `screens-fusion/` + `screens/` (visual references to MATCH), `assets-fusion/` + `assets/` (the vector atoms), `HANDOFF-fusion.md` (the fidelity rules).
- **Skip the .fig field** — mockups are HTML, not Figma.

## Add fonts, logos and assets — drag these
- Logos: `brand/logo-lockup-raster.jpg`, `brand/emblem-flat-raster.png`, `assets-fusion/emblem.svg`, `assets-fusion/emblem-mark-mini.svg`
- Key assets: `assets-fusion/gizmo-illuminated.svg`, `assets-fusion/covenant-emblems.svg`, `assets-fusion/rarity-illuminated.svg`
- Fonts (free Google Fonts — name them in notes, or drop .ttf): **Fredoka**, **Cormorant Garamond**, **Nunito**

## Any other notes? (paste)
```
PALETTE — neon "light": Flow #5BE6A4, Clutch #54D8FF, Echo #A98BFF, Surge #FFD24A.
Ancient "matter": Gold-leaf #E8BC88, Tarnished Gold #A87A2E, Burnt Bole #7A5020,
Oxblood #7E2531, Vermilion #C45A40, Ink #211B17, Lapis-night #263D5E, Parchment #F8F1E5.
Base void #0C0A16. Rule: warm:cool ≈ 9:1; only red/gold saturate; ink makes it official.
GOLD IS THE HINGE — every reward reads as an "illumination."

TYPE: Fredoka (display + dopamine numbers, gold-leafed w/ ink stroke), Cormorant Garamond
(manuscript labels/verdicts), Nunito (UI body).

MATERIAL: flat vector + confident ink contours + soft neon glow built from STIPPLE RADIANCE
(dots, not bloom) on gold-leaf ground. HUD panels = ink + gold-leaf "page apparatus" with
corner wax-seals and a dashed inner rule. Charged empty space frames every payoff.

SCOPE for this system: the UI + components — HUD, menus, upgrade/rarity cards, the icon set,
title/level-up/results screens. Match the attached screen mockups and emblem exactly.

DO NOT: generic-AI sheen, rarity-glow spam, victory-sparkle confetti, fog/bokeh mysticism,
or any religious/sacred imagery (the gold "aureole" is secular geometry, never a halo).
```

## After setup
- Refine via conversation/sliders, building in layers: brand foundation → color tokens → type scale → logo → components → docs.
- Save the result as a reusable **Skill** that bundles this brief + references, so every future request auto-applies "The Lumen Codex."
- Use Claude Design for the **UI/system**; route painterly art (key art, backgrounds, FX, textures) to image models via `IMAGE-MODEL-BACKLOG.md`.
