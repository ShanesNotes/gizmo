# Lumen Codex — Game UI Kit

Interactive click-through recreation of Gizmo's four canonical screens, composed from the design-system components. This is a recreation of the handoff mockups (`design-handoff/mockup-*-fused.html` + base), not a new design.

## Run it
Open `index.html` for the four desktop screens, or `mobile.html` for the portrait HUD + touch cluster. The desktop stage is a fixed **1280×720** frame that scales to fit; the mobile page is a fluid **390×844** reference in a phone frame.

## Flow
- **Title** — wordmark + Illuminated-G emblem + hero. *Click anywhere / press any key* → HUD ("wake the page").
- **HUD** — the page apparatus in play. Click the **verdict bar** (The Claiming) → Level-Up; click the **sealed reliquary** sprite → Results; click any **covenant roundel** to charge its meter.
- **Level-Up** — three rarity cards (Rare / Epic / Evolve). Pick one → back to HUD.
- **Results** — STORM CLEARED + score + records + awards. *Run it back* → HUD; *Title* → Title.

## Files
- `index.html` — scaling stage, loads `_ds_bundle.js` + the screens.
- `app.jsx` — screen state machine + stage scaling + switcher chrome (persists current screen in `localStorage`).
- `kit-common.jsx` — shared chrome: `Stipple`, `PageFrame` (frame + corner wax-seals), `Aureole`, asset base.
- `TitleScreen.jsx` · `HudScreen.jsx` · `LevelUpScreen.jsx` · `ResultsScreen.jsx`.
- `mobile.html` + `HudPortrait.jsx` — the fluid portrait HUD: score + breath, the bounty **verdict chip** (`VerdictBar compact`), a condensed four-covenant cluster, and the live `TouchControls` (joystick drives Gizmo, Boost cycles its snap states). Geometry follows `../../TOUCH-AND-RESPONSIVE-SPEC.md`.

## Components used
`Button`, `Panel`, `Pill`, `StatCell`, `BreathRow`, `VerdictBar`, `CovenantRoundel`, `UpgradeCard`, `Eyebrow`, plus the touch layer `Joystick`, `BoostButton`, `TouchControls` — from `window.GizmoTheLumenCodexDesignSystem_512f7f`. Sprites come from `../../assets/sprites` and `../../assets/brand`.
