# Porting Gizmo to Godot

Goal: rebuild **Gizmo** (currently a Phaser/TypeScript web prototype) in **Godot**, keeping the proven loop and the **"Lumen Codex"** look. You don't port the web engine — you port three things: **the mechanics**, **the look**, and **the feel**.

## The three inputs (all in this repo)
1. **Mechanics — `game-src-phaser/src/game/simulation.ts`** (~1,750 lines of *pure game logic*: movement, spawn, XP/level, the four economies, caches, bounty, damage/heal, run state). **This is the source of truth — port it to GDScript first.**
2. **Look — `design-system/`** (the Claude Design output: `tokens/` colors+type, `components/`, `SKILL.md`, `ui_kits/lumen-codex/` screens) + **`design-handoff/`** (art bible, the Fusion Codex, palette hexes, fonts, SVG assets, screen mockups).
3. **Feel — the playable build** (`index.html` + `assets/`): serve the repo root (`npx serve .`) and play it to feel the loop before porting.

## The loop to reproduce
Pilot a spark-bot through a storm of shapes; vacuum **Spark** (XP); level up → pick a roguelite **upgrade card**; pop big shapes → crack **Caches** (sealed reliquaries); feed four parallel economies — **Flow** (mint), **Clutch**/near-miss (cyan), **Echo** (violet), **Surge** (gold) — plus **Bounty** chases and a timing-based **Boost / Snap Boost**. Survive to "Storm Cleared."

## Where each system lives (read these to port)
| Source file | What it is | Godot target |
|---|---|---|
| `src/game/simulation.ts` | pure game rules & state (PORT FIRST) | `Simulation.gd` (headless-testable) |
| `src/phaser/MischiefScene.ts` | scene: input, camera (RESIZE + `baseWidth` zoom + follow), spawn, draw | Main scene + `Camera2D` |
| `src/phaser/createTextures.ts`, `drawWorld.ts`, `titleArt.ts`, `loadGameArt.ts` | procedural/loaded art | Godot sprites / textures |
| `src/ui/hud.ts` + `src/styles.css` | the DOM HUD | Godot `Control` scenes + `Theme` |
| `src/ui/sfx.ts` | audio | `AudioStreamPlayer` |

## Art → Godot mapping
- **Palette** → a Godot `Theme` + color constants from `design-system/tokens/colors.css` (hexes also in `design-handoff/FUSION-CODEX.md`). Rule: warm:cool ≈ 9:1; only red & gold saturate; gold = reward.
- **Fonts** → Fredoka (display + numbers), Cormorant Garamond (manuscript labels/verdicts), Nunito (UI) — add as Godot FontFiles.
- **Sprites** → `design-handoff/assets*/*.svg` + `design-system/assets/sprites/`. Godot imports SVG directly (bump import `scale`), or rasterize to PNG @2×.
- **HUD / screens** → rebuild as `Control` scenes; visual targets = `design-system/ui_kits/lumen-codex/` and `design-handoff/mockup-*.html`. The `design-system/components/` (Button, Panel, Pill, Meter, Seal, CovenantRoundel, UpgradeCard, VerdictBar, BreathRow, StatCell) are your component spec.
- **Juice/motion** → eases in `design-system/tokens/spacing.css`; implement shake / hit-stop / number-pops / level-up "Nova" bloom with `Tween` + a `Camera2D` shake. See `design-handoff/FUSION-CODEX.md` (Motion).
- **"Zoom out to see more"** = `Camera2D.zoom` (Phaser used `baseWidth`/`setZoom`). Tune by playtest; render floating combat numbers in screen-space so they stay readable.

## Suggested Godot layout
```
scenes/   Main, Title, Hud, LevelUp, Results
scripts/  Simulation.gd, Player.gd, Enemy.gd, Spawner.gd, economies/*.gd
ui/       Theme.tres + Control scenes mirroring design-system/components
assets/   sprites (from design-handoff/assets) + fonts
audio/
```

## Start order
1. Play the web build to feel it.
2. Port `simulation.ts` → `Simulation.gd` (logic only; unit-test it headless).
3. Minimal scene: movement + spawn + one enemy + Spark pickup + XP/level.
4. Add the four economies, Cache, Bounty, Boost.
5. Build the HUD from the design system; apply the Theme.
6. Juice pass (shake, pops, Nova, audio).
