# Teaching notes — Gizmo Godot port

Working notes for the teacher. The engine here is the `/teach` skill.

## Method
- **Co-development, paced for understanding.** This is a slow-down-and-learn
  effort — not "watch the AI build," and not "type everything yourself." The AI
  explains, demonstrates, and writes code *with* the learner. The bar is that
  the learner can explain every piece afterward. Keep them in the loop on
  decisions; don't drop finished black boxes. Prefer small slices with a pause
  to absorb.
- **Editor-first.** Lessons are real actions in the Godot editor, not
  hand-authoring engine files at the CLI. Lesson 1 is literally: open Godot, New
  Project, hit **Create**. Build the game up from there, one visible win per lesson.
- **The seed is the teacher's grounding — not the learner's homework.** The
  Phaser/TS seed and port framework exist so the AI knows what to build next and
  can teach efficiently (saving tokens). Lean on them. Don't make the learner read
  or reconstruct the seed. The bigger outcome this workspace optimizes for:
  teaching the learner (and others, via the published guide) *how to co-develop a
  game in Godot with Claude Code + the teach skill* — the seed is the vehicle.
- **Answer key.** `docs/godot/answer-key/` holds a finished, verified reference
  port (the codex pre-pass: `project.godot`, `scenes/main.tscn`,
  `scripts/simulation.gd`, headless `tests/`). It's set aside so we rebuild the
  port together at learning pace. Consult it to check direction or unblock —
  don't paste it in wholesale as the lesson.
- **From-zero guide.** No prior Godot knowledge is assumed in the lessons. This
  learner has separate experience in the `game-dev` workspace, deliberately not
  carried over, so the published guide reads from lesson 1. Compute the zone of
  proximal development from *this* workspace's `learning-records/` only, which
  starts empty.

## Grounding (don't re-derive — cite these)
- Grounding / source anchors: see `RESOURCES.md` (annotated) and `CONTEXT.md` §5
  (doc-ownership map). Premise canon: `design-handoff/NARRATIVE.md`.

## Environment
- Godot verified: `4.6.2.stable.mono.official` at `~/.local/bin/godot`.
- Headless tests (answer-key): `godot --headless --path docs/godot/answer-key
  --script res://tests/run_simulation_tests.gd`.
- The learner runs equivalents against the shared `godot/` build as it grows.
- Naming: snake_case files/folders, PascalCase node names / `class_name`.

## Lessons
- Self-contained HTML in `lessons/`, numbered `0001-…`, built for publishing
  (mirror the `game-dev/lessons` style). One tangible win each.
- **Code blocks are copy/paste with tabs (learner request, 0004+).** Every `<pre>`
  gets a **Copy** button; the handler converts leading 4-space groups → real tabs
  so GDScript pastes into Godot without "unexpected indent". Author snippets with
  4-space indentation; the button emits tabs. (Convention mirrors game-dev's
  `_lesson.js`.) Reusable script lives at the bottom of `lessons/0004-…html`.
  Backfill 0001–0003 if revisited.

## Design anchors (learner intent — steer lessons toward these)
- **Title screen = the emblem as a start button.** Minimalist: just the Gizmo
  logo, a power-button "G", centered. The player *presses the emblem to start
  the game*. Confirmed-canonical asset: `design-system/assets/brand/emblem.svg`
  (the "Illuminated-G" — power-button glyph, cyan core + lapis ring, gold
  medallion; guideline `design-system/guidelines/brand-emblem.html`). Use
  `emblem-mark-mini.svg` only below ~48px. Per CLAUDE.md: copy the existing SVG
  into `godot/assets/`, don't invent a replacement.
- **Lesson arc this implies:** the swaying "Gizmo" Label (0002–0003) is throwaway
  scaffolding. The real title screen lands once we can *start a game* — a natural
  home for teaching **import an SVG → `TextureButton` (or Control) → the
  `pressed` signal → `change_scene_to_file()`** (signals + scene transitions, not
  yet taught). Slot it after a minimal playable game scene exists so "Start"
  has somewhere to go.
