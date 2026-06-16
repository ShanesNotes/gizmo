# Prompt — Watercolor Key Art Lane

Status: locked draft
Last refreshed: 2026-06-15
Use for: painterly/raster-only title art, gameplay plates, and illuminated card backers.

## Reference inputs

Attach these as reference/mood images when the image workflow supports references:

- North star / style reference: `art/explorations/title-captured-loved-title-gadgets-refined.jpg`
- Exact loved title capture / mood reference: `art/explorations/title-captured-loved-title-exact.jpg`
- Helpful system reference: `art/explorations/title-bg-illuminated-mashup.jpg`
- Anti-references: `art/explorations/title-bg-codex-sigils.jpg`, `art/explorations/title-mashup-reference-covenants.jpg`, `art/explorations/title-mashup-reference-aureole-stipple.jpg`

## Execution notes

- This is the raster lane. It is for watercolour/gouache richness the vector system should not fake.
- Gizmo, enemies, icons, HUD chrome, and covenant meters stay vector.
- The title wordmark is set later as vector/HTML. Do not bake text into KA-1.
- Ancient-world drift is allowed when it reads as lost gizmos and gadgets floating through a vast mystical codex-space. Abstract ruins, pyramids, towers, and geometric horizon-shapes are acceptable only as small, distant, secular background flavor. Gadgets remain the subject.
- Graphical fidelity target: matte low-fi 1990s cartoon background painting / Saturday-morning adventure art. Prefer flat gouache fields, soft cel-animation background rendering, hand-ink wobble, and visible paper grain over glossy high-polish AI concept-art detail.
- Built-in Codex `image_gen` is suitable for preview and workspace-bound raster generation. Exact API/model/size control belongs to the CLI/API path.
- `gpt-image-2` can be used for the image-model lane when CLI/API mode is explicitly chosen and `OPENAI_API_KEY` is available.
- Layered/PSD output is desirable when available but not guaranteed; keep compositing-safe clean space and separable regions.

---

## Prompt 1 — Image model: the watercolour look itself

This makes the game look like the loved reference. Attach `title-captured-loved-title-gadgets-refined.jpg`.

```text
═══ THE LUMEN CODEX — master style header (paste atop EVERY generation) ═══
STYLE: "The Lumen Codex" — a kid-friendly premium arcade fused with illuminated-manuscript
craft. The hinge is GOLD: the biggest reward (Surge) and a manuscript blessing (Illumination)
are the same gold light, so every payoff is an illumination. WORLD "The Hush": a vast dormant
illuminated codex whose pages have gone dark; a tiny cyan-core spark relights them.

PALETTE — the light (these may saturate; use sparingly): Flow mint #5BE6A4 · Clutch cyan #54D8FF
· Echo violet #A98BFF · Surge gold #FFD24A · danger coral #FF6B7E.
The matter (the body of the painting): gold-leaf #E8BC88 · tarnished gold #A87A2E · burnt bole
#7A5020 · oxblood #7E2531 · vermilion #C45A40 · warm brown-black ink #211B17 · lapis night
#263D5E · cream parchment #F8F1E5. Grounds: void #0C0A16, indigo field #15102A.

LAWS: warm-to-cool ≈ 9:1 — cool is an event, not a default. Only red and gold sit at full
saturation; everything else is a muted wash. Gold carries light, red carries cost, ink makes it
official. Radiance is MADE — hand-flecked gold-dust + dry-brush sunburst ticks, NEVER generic
bloom, bokeh, or lens flare. Charged empty space (bare paper) frames every payoff.

═══ THE LOOK TO MATCH ═══
North star: the attached title exploration "title-captured-loved-title-gadgets-refined.jpg".
Hand-painted watercolour & gouache, storybook / 90s-Saturday-morning-cartoon warmth. Gilded
gadgets — brass telescope, joystick, gear-medallions, gem-set geode stones, a sealed reliquary
chest — drift across a dreamy cosmos that bleeds wet-into-wet from a deep starry indigo crown →
violet → coral → peach, draining to BARE CREAM PAPER at the lower edge. Visible cold-press paper
tooth; granulating pigment in the darks; confident but slightly wobbly hand-inked contours (warm
brown-black, not pure black); scattered stars and hand-flecked gold dust. Gold reads as real
LEAF — opaque, edge-cracked, catching light — never a glossy digital gradient.

GRAPHICAL FIDELITY TARGET: matte, low-fi 1990s cartoon background painting. The loved reference
looks closer to hand-painted cel-animation/gouache production art than modern polished concept
art: simplified shapes, lower detail density, soft matte color fields, restrained highlights, and
visible hand wobble. Avoid the default high-polish image-generation look: no hyper-detailed brass
rendering, no crisp fantasy key-art finish, no glossy 3D lighting, no over-sharpened stars.

RESTRAINT IS THE TRICK. The loved image earns its warmth by showing FEW marks, each fully
realised, on lots of quiet paper. Do NOT crowd the scene with sigils, covenant discs, eyes, or
seals. ANTI-REFERENCES — do not imitate, they failed by going busy and chalky:
"title-bg-codex-sigils.jpg", "title-mashup-reference-covenants.jpg",
"title-mashup-reference-aureole-stipple.jpg". At most ONE system mark per scene — a single gold
"G" power-seal medallion with a cyan core-spark (as in "title-bg-illuminated-mashup.jpg").

═══ FIDELITY GATE — reject & regenerate unless ALL pass ═══
1. Palette-true: neon hues read as the exact hexes; gold-leaf/oxblood/ink for matter;
   warm:cool ≈ 9:1; no off-brand teal/lime/magenta drift.
2. Radiance is made (flecks + gold-ground), not bloom/bokeh/flare.
3. No drift: no rarity-glow spam, victory-sparkle confetti, fog/tarot mysticism, generic-AI
   watercolour sheen, or stocky 3D-render look.
4. No sacred copying: the gold aureole is secular geometry — no halos, saints, clergy, liturgical text.
5. State reads: the image shows what's true (dormant vs illuminated) before any text.
6. Composites clean: leaves a readable, lower-contrast central play-space; darks are
   additive-ready; no baked-in UI chrome.
7. Matches the system: same cyan-core spark identity, same gold "G" seal — not a re-invention.

═══ PER-ASSET SEEDS (one render at a time; prepend the header each time) ═══

KA-1 · TITLE KEY ART — "wake the page"
"A vast dormant illuminated codex-page as a watercolour cosmos: deep starry indigo crown bleeding
through violet, coral and peach down to bare cream paper at the foot. Gilded gadgets (brass
telescope, joystick, gear-medallions, gem-set geode stones, a wax-sealed reliquary chest) drift
in loose orbit like lost gizmos and gadgets suspended in an ancient mystical world, with generous
quiet space between them. Distant abstract ruins, pyramids, towers, and geometric storm-shapes may
sit on the horizon only as tiny, secular, soft cartoon-background flavor; they must not become the
main scene. Gadgets remain the subject. A single gold-leaf 'G' power-seal
medallion with a cyan core-spark, upper-right. Hand-flecked gold dust; a few distant geometric
storm-shapes on the horizon. LEAVE A CLEAN, CALM upper-centre band of night sky as charged empty
space for the wordmark — do NOT paint any lettering or text (the wordmark is set in vector
afterward). Wet-into-wet washes, granulating darks, cold-press tooth, wobbly warm-ink contours,
gold as cracked leaf. Keep the rendering matte and low-fi: 1990s Saturday-morning cartoon
background painting, simplified gouache forms, soft cel-animation fields, fewer crisp highlights,
less hyper-detailed metal, no glossy AI polish."
Spec: 2560×1440 landscape + 1080×1920 portrait crop; layered/PSD if possible.

BG-1 · GAMEPLAY BACKGROUND PLATE — "the dark page under the storm"
"The same Hush cosmos as a loopable PLAYFIELD backdrop, quieter and lower-contrast — mostly deep
indigo-to-bole darks with a faint granulating nebula and a sparse gold-dust grid, so bright
vector gameplay reads cleanly on top. No gadgets crowding the centre; keep a calm mid-field;
edges fade to void for seamless scroll."
Spec: 2560×1440, low central contrast, additive-ready darks.

CARD-1 · ILLUMINATED CARD BACKER — for level-up choices
"A small portrait vellum panel: aged cream paper with a granulating wash, a hand-inked + gold-leaf
ruled border with a torn deckle edge and an oxblood diamond wax-seal in one corner. Centre left
empty (vector sigil + text composite on top). Four variants — a whisper of mint / cyan / violet /
gold wash in the BORDER ONLY."
Spec: 1024×1536, transparent outside the deckle edge, 4 hue variants.

NOTE — Gizmo the character is NOT painted here, and no painterly mascot is wanted. The mascot,
enemies, icons, HUD chrome and the four covenant meters stay VECTOR (claude.ai/design). Where the
hero would appear, leave charged empty space to composite the vector spark-bot on top.
```
