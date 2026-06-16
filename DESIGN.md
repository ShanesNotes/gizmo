# Design

## Source of truth
- Status: Draft
- Last refreshed: 2026-06-15
- Primary product surfaces: title screen, gameplay HUD, level-up choices, results, covenant emblems, upgrade icons, Gizmo mascot states.
- Evidence reviewed:
  - `README.md`
  - `design-system/SKILL.md`
  - `design-system/readme.md`
  - `design-system/styles.css`
  - `design-system/tokens/`
  - `design-handoff/README.md`
  - `design-handoff/FUSION-CODEX.md`
  - `design-handoff/HANDOFF-fusion.md`
  - `design-handoff/IMAGE-MODEL-BACKLOG.md`
  - `art/explorations/title-captured-loved-title-exact.jpg`
  - `art/explorations/title-captured-loved-title-gadgets-refined.jpg`
- Current revamp prompt sources:
  - `design-handoff/PROMPT-watercolor-keyart.md`
  - `design-handoff/PROMPT-warm-system.md`

## Brand
- Personality: kid-friendly premium arcade fused with illuminated-manuscript craft.
- Trust signals: disciplined tokens, legible vector states, warm hand-crafted matter, restrained use of glow.
- Avoid: generic AI watercolour sheen, fog/bokeh mysticism, rarity-glow spam, sacred/religious copying, crowded sigils, unreadable pale panels behind speed-critical UI.

## Product goals
- Goals:
  - Make the Godot rebuild feel like The Lumen Codex from the first title screen.
  - Keep gameplay-speed information crisp while warming the surrounding world.
  - Separate painterly richness behind the UI from token-true vector gameplay assets.
- Non-goals:
  - No full port or redesign in one pass.
  - No painterly mascot, enemies, HUD, icons, or covenant meters.
  - No replacement of the Phaser seed or existing handoff package.
- Success signals:
  - KA-1 can sit behind the title UI without baked text or UI chrome.
  - HUD meters remain readable at speed.
  - All warmed assets preserve existing token names and state logic.

## Personas and jobs
- Primary personas:
  - Learner/developer co-building Gizmo in Godot.
  - Future implementer using Claude Code and the design handoff.
  - Player reading arcade information at speed.
- User jobs:
  - Understand what belongs in raster vs vector.
  - Generate painterly background plates that composite cleanly.
  - Warm the vector system without losing gameplay contrast.
- Key contexts of use:
  - Local design iteration.
  - Godot rebuild implementation.
  - Future lesson artifacts and handoff docs.

## Information architecture
- Primary navigation: not applicable yet; game surfaces are state screens.
- Core routes/screens: title, gameplay HUD, level-up, results.
- Content hierarchy:
  - Title: wordmark/emblem/verdict prompt over quiet painted cosmos.
  - HUD: score/rank/Breath/XP/covenants as speed-critical apparatus.
  - Level-up: ILLUMINED verdict, covenant sigil, three cards.
  - Results: gold-leaf score, roman rank, new-best marker.

## Design principles
- Principle 1: Painterly behind, vector on top.
- Principle 2: The roundel carries its own night.
- Principle 3: Gold is the hinge; gold-leaf belongs to Surge and Illumination first.
- Principle 4: State before label.
- Tradeoffs:
  - More parchment warmth improves storybook feel but can reduce meter contrast.
  - More ornament sells codex craft but threatens speed readability.

## Visual language
- Color:
  - Light: Flow `#5BE6A4`, Clutch `#54D8FF`, Echo `#A98BFF`, Surge `#FFD24A`, danger coral `#FF6B7E`.
  - Matter: gold-leaf `#E8BC88`, tarnished `#A87A2E`, bole `#7A5020`, oxblood `#7E2531`, vermilion `#C45A40`, ink `#211B17`, lapis `#263D5E`, parchment `#F8F1E5`.
  - Grounds: void `#0C0A16`, field `#15102A`.
- Typography:
  - Fredoka for display/numbers/inscription.
  - Cormorant Garamond for manuscript voice and verdicts.
  - Nunito for UI body.
- Spacing/layout rhythm: generous charged empty space; large quiet bands around payoffs.
- Shape/radius/elevation: deckle frames at large scale; hard ink contours and local dark chips at small scale.
- Motion: use `--ease-settle`; honor `prefers-reduced-motion`; radiance by stipple and marks, not bloom.
- Imagery/iconography: watercolour/gouache for title/background/cards; SVG for character, enemies, icons, HUD, meters.

## Components
- Existing components to reuse:
  - `design-system/styles.css`
  - `design-system/tokens/`
  - `design-handoff/assets-fusion/*.svg`
  - `design-handoff/mockup-title-fused.html`
  - `design-handoff/mockup-hud-fused.html`
- New/changed components:
  - Warmed title screen HTML layer.
  - Warmed HUD HTML skin.
  - Illuminated card backer raster variants.
  - Updated covenant emblem SVG sheet.
  - Updated upgrade icon SVG subset.
- Variants and states:
  - Covenant roundels: inert vs energized by chroma, ring completeness, and ray ticks.
  - Gizmo vector states: dormant, waking, thrust, struck with persistent craquelure scar, illuminated.
  - Rarity: flat ink common through gold-ground Evolve.
- Token/component ownership:
  - Token names survive unchanged.
  - `design-system/tokens/colors.css` is authoritative for `--panel`.

## Accessibility
- Target standard: pragmatic readable game UI; preserve contrast for speed-critical surfaces.
- Keyboard/focus behavior: title prompt supports keyboard start; future UI controls must preserve visible focus.
- Contrast/readability: no pale cream panel directly behind live meters; local dark grounds under neon marks.
- Screen-reader semantics: future HTML mockups should use semantic labels for title, score, rank, choices, and results.
- Reduced motion and sensory considerations: honor `prefers-reduced-motion`; color changes must pair with shape/state changes.

## Responsive behavior
- Supported breakpoints/devices: follow existing `design-system/TOUCH-AND-RESPONSIVE-SPEC.md` and existing shipping breakpoints.
- Layout adaptations: preserve title open layout across landscape and portrait crops.
- Touch/hover differences: touch controls remain large and readable; hover polish must not be the only state signal.

## Interaction states
- Loading: keep quiet dark/indigo field with stipple; avoid fake chrome.
- Empty: use charged bare paper/quiet field rather than decorative filler.
- Error: oxblood/vermilion with ink contour and clear copy.
- Success: gold-leaf illumination; one payoff exclamation maximum.
- Disabled: drained low-chroma ink state with broken/dim ring.
- Offline/slow network, if applicable: not currently defined.

## Content voice
- Tone: plucky, distilled, ceremonial, generous but honest.
- Terminology: Illumination, Covenant, Reliquary, Vigil, Breath, Rank.
- Microcopy rules:
  - Sentence case for body.
  - UPPERCASE only for short dopamine callouts and manuscript eyebrows.
  - No emoji; lone `⚡`, `✦`, `↻`, `★` are functional glyphs only.
  - One `!` per payoff.

## Implementation constraints
- Framework/styling system: current design source is HTML/CSS/SVG plus design-system tokens; Godot integration is later.
- Design-token constraints: keep every existing token name and economy.
- Performance constraints: gameplay-speed elements need hard contours and clear value steps.
- Compatibility constraints: keep raster plates compositing-ready; avoid baked UI chrome in generated backgrounds.
- Test/screenshot expectations: compare warmed screens against saved mood references and fused mockups before implementation.

## Open questions
- [ ] Decide final storage path and naming for generated raster keepers / owner: design implementer / impact: asset import consistency.
- [ ] Decide whether CLI/API `gpt-image-2` or built-in Codex `image_gen` is the preferred generation path for final KA-1 / owner: user / impact: exact size and file-control expectations.
- [ ] Decide if `DESIGN.md` should become Active after the first warmed title/HUD pass / owner: user / impact: governance strength.

