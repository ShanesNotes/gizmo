# Prompt — Warmed Vector System Lane

Status: locked draft
Last refreshed: 2026-06-15
Use for: Claude Design / HTML / CSS / SVG design-system warming pass.

## Reference inputs

Attach these source folders/files when running the vector-system prompt:

- `design-handoff/`, especially `Fusion-Codex.html`, `HANDOFF-fusion.md`, `FUSION-CODEX.md`, `mockup-title-fused.html`, `mockup-hud-fused.html`, `assets-fusion/*.svg`, `screens-fusion/*.png`
- `design-system/styles.css`
- `design-system/tokens/`
- Mood reference only: `art/explorations/title-captured-loved-title-gadgets-refined.jpg`
- Mood reference only: `art/explorations/title-bg-illuminated-mashup.jpg`
- Fonts: Fredoka, Cormorant Garamond, Nunito

## Boundary

This is vector/CSS/SVG only. It warms the existing system so it can sit on top of the generated watercolour key art. It must not repaint the UI, replace token names, or move mascot/enemy/icon/HUD work into the raster lane.

---

## Prompt 2 — Claude Design: warm the vector system to live in that world

```text
═══ ATTACH THESE ═══
• design-handoff/  (esp. Fusion-Codex.html, HANDOFF-fusion.md, FUSION-CODEX.md, the two
  mockup-*-fused.html, assets-fusion/*.svg, screens-fusion/*.png)
• design-system/styles.css + design-system/tokens/  (the live CSS custom properties)
• MOOD reference only (do NOT reproduce the painting): art/explorations/
  title-captured-loved-title-gadgets-refined.jpg +
  title-bg-illuminated-mashup.jpg
• Fonts (free Google): Fredoka, Cormorant Garamond, Nunito. Skip the .fig field — mockups are HTML.

═══ WHAT THIS IS ═══
A WARMING PASS on the existing "Lumen Codex" vector/CSS system — NOT a repaint into watercolour
(the painterly key art is generated separately by an image model and composited BEHIND the UI).
Keep every token name and every economy; evolve only the surface so the flat-vector UI reads as
if it lives in the storybook-codex world: warmer grounds, gold-leaf rule-lines, deckle-edged
illuminated panels, more bare-paper space. Output stays tokens-true HTML/CSS/SVG that composites
cleanly ON TOP of a painted indigo→cream background.

═══ PINNED MASTER BRIEF (re-invoke each turn: "Using the warmed Lumen Codex style…") ═══
[Hinge = GOLD; every reward is an illumination. The light: Flow #5BE6A4 · Clutch #54D8FF · Echo
#A98BFF · Surge #FFD24A; accents coral #FF6B7E, pink #FF79C6 (epic), orange #FF9D5C. The matter:
gold-leaf #E8BC88, tarnished #A87A2E, bole #7A5020, oxblood #7E2531, vermilion #C45A40 (charged
danger/heat), ink #211B17, lapis #263D5E (cold judgment — an event), parchment #F8F1E5; rare
event hues ward-green #365A49, dusty-rose #B07A83. Grounds void #0C0A16, field #15102A.
Laws: warm:cool ≈ 9:1; only red & gold saturate; gold=light, red=cost, ink=official; radiance is
MADE (stipple, not bloom). Type: Fredoka (display/numbers, inscription recipe), Cormorant
Garamond (manuscript voice — verdicts, eyebrows ILLUMINATION/COVENANT/RELIQUARY/VIGIL), Nunito
(UI body). EVERY token name stays (--flow, --surge, --gold-leaf, --oxblood, --panel,
.lumen-seal, --ease-settle…). For --panel, colors.css is authoritative: rgba(20,15,34,0.82)
(supersedes the ART-DIRECTION #181334@72% prose).]

═══ THE WARMING MOVES (vector, not paint) ═══
• GROUNDS: a continuous ground that goes void-dark #0C0A16 at the crown → bare cream parchment
  #F8F1E5 at the foot (CSS gradient over the composited key art) — charged empty space = warm paper.
• PANELS: dark-glass HUD panels become "illuminated-codex" panels — vellum/aged-paper fills WHERE
  READABILITY ALLOWS, a gold-leaf ruled border (--border-gold), dashed inner rule (--rule-inner),
  oxblood diamond corner wax-seals (.lumen-seal), and an SVG deckle/torn edge.
• RADIANCE: keep stipple-radiance as "made light" (CSS radial-dot texture, --stipple /
  --stipple-size), now reading as gold-dust on paper. No bloom.
• GILDING over glow: rarity signals by GOLD-LEAF + SEAL-DENSITY first, glow second. Common
  #9892B4 = flat ink mark; Evolve #FFD24A = fully illuminated (gold-ground + aureole + wax seal + ⚡).

═══ THE FOUR LAWS THAT KEEP IT PLAYABLE (the cozy-vs-arcade reconciliation) ═══
1. VALUE & CONTRAST. Warmth governs grounds, backers and charged-empty space. Anything PARSED AT
   SPEED — HUD meters, entity silhouettes, covenant states, dopamine numbers — keeps a hard ink
   contour and a clear value-step against its ground. Never put a pale cream panel directly behind
   a live meter; meters keep a local dark.
2. PER-COVENANT ENERGISED STATE (not gold-fleck). A covenant reads "charged" by CHROMA +
   RING-COMPLETENESS + a few ray-ticks; inert = the same sigil drained to a muted, low-chroma wash
   with a broken/dim ring. Gold-fleck/gold-ground stays EXCLUSIVE to Surge & Illumination so the
   gold hinge keeps meaning — mint/cyan/violet must not borrow it.
3. HUE-ON-PAPER. Neon hues were tuned to glow on #0C0A16; on cream they go chalky. So covenant
   marks live inside inked roundels that carry their OWN dark night (ink/lapis ground) — the hue
   holds luminance contrast against a local dark, not against the paper. "The roundel carries its
   own night."
4. FIDELITY BY SIZE. Illuminated texture (deckle, gold-leaf, stipple, vellum) applies at ≥ ~96px.
   At ≤48px: flat ink line + flat covenant fill + at most one gold accent. At 16px: silhouette +
   one hue + the sigil, no texture. State the size on every asset.

═══ DELIVERABLES — RUN ONE PER TURN, START WITH #1 ═══
(open each: "Using the warmed Lumen Codex style + the four laws: …", name the subject, its
states/variants, exact hexes, the size; close with "rebuild on the existing <reference>.svg
geometry — restyle fills/strokes only, keep the silhouette legible at 16/48px." Deliver tokens-true
HTML/CSS or clean SVG, honouring --ease-settle and prefers-reduced-motion.)

1. TITLE SCREEN (HTML) — the warmed UI layer over the composited KA-1 painting: correctly-lettered
   "THE LUMEN CODEX" Fredoka gold inscription (NEVER "CODEEX"), one gold "G" emblem
   (emblem-C-illuminated-G.svg), deckle illuminated frame with oxblood corner seals, Cormorant
   verdict plate "Press any key to wake the page." Composition follows the loved title's OPEN
   layout — treat mockup-title-fused.html as a checklist of elements, NOT a layout to copy.
2. HUD (HTML) — the hard case: a live "page apparatus" that survives speed. Illuminated-codex
   panels; the four covenant meters as a bottom cluster (each a roundel carrying its own night,
   Law 3; energised by chroma+ring, Law 2); coral Breath-flame hearts; XP rule mint→cyan→gold;
   "ILLUMINED!" gold callout on level-up. Apply Law 1 ruthlessly. Repaint the skin of
   mockup-hud-fused.html.
3. LEVEL-UP (HTML) — gold-ground blooms behind an ink covenant sigil; "ILLUMINED!" in Cormorant;
   three choice cards on illuminated backers; rarity shown by gilding level (gold-leaf +
   seal-density first).
4. RESULTS (HTML) — score as a Fredoka gold-leaf inscription; rank in Roman numerals
   ("Rank VII · Illuminating"); new-best marked ★; on a vellum spread.
5. COVENANT EMBLEMS (SVG sheet) — rebuild covenant-emblems.svg: each an illuminated roundel (ink
   ring + gold-leaf ring + dark stipple ground + ray-ticks) with sigil in its hue, carrying its
   own night; show meter-as-state for each. Legible at 48px.
6. UPGRADE ICONS (SVG) — rebuild a handful from icons.svg (Boost double-chevron, Flow waves,
   Clutch pulse-spike, Echo rings, Surge bolt): the locked construction "one glyph, dark chip,
   colored edge" — bold glyph on a dark-glass chip (base #181334) + thin colored edge + soft hue
   glow, warmed with a gold-leaf edge-catch. Flat at 16px per Law 4.
7. GIZMO MASCOT (SVG) — rebuild gizmo-illuminated.svg: warm-white teardrop chassis, cyan core-lens,
   gold-leaf fins, secular gold-ground aureole; states dormant → waking → thrust → struck
   (persistent craquelure scar) → illuminated. 16px silhouette must hold. STAYS VECTOR — the
   painted hero is retired.

═══ BOUNDARIES ═══
• Evolve, don't replace — every token name survives; only the surface warms. Vector/CSS/SVG only.
• Reuse, never invent — rebuild on existing assets-fusion/*.svg geometry; match the form language
  for any missing glyph.
• Emulate the hand, never copy the page — translate motifs into operations; aureole is secular
  geometry (no halos/saints).
• A symbol is game-ready only when it changes state — show before→after; no decoration-only ornament.
• Honour: warm:cool ≈ 9:1, only red & gold saturate, no emoji (lone ⚡✦↻★ are functional glyphs),
  one "!" per payoff. Wiring into Godot is a separate Claude Code phase — produce design assets only.

How they fit: run Prompt 1 first in an image model → it gives the painted title/backgrounds in
the loved style. Then run Prompt 2 in claude.ai/design → it warms the vector UI so it sits cleanly
on those paintings. The deliverables in Prompt 2 are ordered hardest-payoff-first (#2 HUD is the
real test of whether the warmth survives at gameplay speed).
```
