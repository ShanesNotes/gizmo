# Template — Lumen Codex Mobile HUD (portrait + touch)

A **starting-point template** for consuming projects: the fluid, safe-area-aware **portrait game HUD** with the live touch cluster. Re-skins the shipping touch scheme into the page-apparatus language; geometry follows `../../TOUCH-AND-RESPONSIVE-SPEC.md`.

> The desktop four-screen version is a **separate template**: `templates/lumen-codex/`.

## Run it
Open `index.html`. A **390×844** reference phone frame scales to fit. The **joystick drives Gizmo** around the play area and the **Snap-Boost** button cycles its six timing states (default → snap-window → scooping → cooling → …). Toggle **Tweaks** for declutter presets (Full / Calm / Minimal), field/frame toggles, panel opacity, roundel size, and a **fixed ↔ floating** joystick switch.

## Composition (top → bottom)
Illumination score + Breath · bounty **verdict chip** (`VerdictBar compact`) · play area (Gizmo + sparks + drifter) · condensed four-covenant cluster · `TouchControls` (joystick left, Boost right) anchored to the safe area.

## Files
- `index.html` — phone frame + Tweaks panel; loads `../../_ds_bundle.js` + `../../styles.css`.
- `HudPortrait.jsx` — the fluid portrait HUD (reads the live tweak flags).
- `kit-common.jsx` — shared chrome (`Stipple`, `PageFrame`, asset base).
- `tweaks-panel.jsx` — the Tweaks shell.

## Components used
`Panel`, `BreathRow`, `VerdictBar` (compact), `CovenantRoundel`, `Joystick`, `BoostButton`, `TouchControls`, `Eyebrow` — from `window.GizmoTheLumenCodexDesignSystem_512f7f`. Sprites from `../../assets/sprites`.
