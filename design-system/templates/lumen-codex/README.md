# Template — Lumen Codex Game UI (desktop)

A **starting-point template** for consuming projects: the four canonical Gizmo screens as an interactive click-through, composed from the design-system components. A recreation of the handoff mockups (`design-handoff/mockup-*-fused.html` + base), not a new design.

> The portrait/touch version is a **separate template**: `templates/lumen-codex-mobile/`.

## Run it
Open `index.html`. The stage is a fixed **1280×720** frame that scales to fit (letterboxed on black). A bottom switcher jumps between screens; the flow also chains naturally. Toggle **Tweaks** in the toolbar for the declutter panel (Full / Calm / Minimal presets, field/panel toggles, panel opacity, roundel size).

## Flow
- **Title** — wordmark + Illuminated-G emblem + hero. *Click anywhere / press any key* → HUD ("wake the page").
- **HUD** — the page apparatus in play. Click the **verdict bar** (The Claiming) → Level-Up; click the **sealed reliquary** sprite → Results; click any **covenant roundel** to charge its meter.
- **Level-Up** — three rarity cards (Rare / Epic / Evolve). Pick one → back to HUD.
- **Results** — STORM CLEARED + score + records + awards. *Run it back* → HUD; *Title* → Title.

## Files
- `index.html` — scaling stage; loads `../../_ds_bundle.js` + `../../styles.css` + the screens + `tweaks-panel.jsx`.
- `app.jsx` — screen state machine, stage scaling, switcher chrome, and the Tweaks panel (declutter presets; persists screen + tweaks in `localStorage`).
- `kit-common.jsx` — shared chrome: `Stipple`, `PageFrame` (frame + corner wax-seals), `Aureole`, asset base.
- `TitleScreen.jsx` · `HudScreen.jsx` · `LevelUpScreen.jsx` · `ResultsScreen.jsx` — each reads the live tweak flags.

## Components used
`Button`, `Panel`, `Pill`, `StatCell`, `BreathRow`, `VerdictBar`, `CovenantRoundel`, `UpgradeCard`, `Eyebrow` — from `window.GizmoTheLumenCodexDesignSystem_512f7f`. Sprites come from `../../assets/sprites` and `../../assets/brand`.
