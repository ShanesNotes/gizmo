# Gizmo — Image-Model Asset Backlog

*The phase **after** claude.ai/design.* claude.ai/design produces the clean **vector system** (mascot, enemies, icons, UI, screens). Image models (GPT-image, Grok/Aurora, Midjourney, Flux) then produce the **painterly / textured lane** vector can't reach — key art, illuminated backgrounds, and material plates you composite onto the vector. You already proved the pipeline with the Grok/Codex emblem renders in `brand/`.

---

## The boundary — what goes where

**KEEP VECTOR (do NOT send to image models)** — needs cross-frame consistency, crisp 16–48px legibility, clean transparency, easy palette edits, and a tidy sprite atlas:
> Gizmo mascot + all states · enemy gameplay sprites · the ~24 upgrade icons · HUD chrome & the four covenant meters · pickups (spark/cache/heart) · the mini emblem / favicon.

**SEND TO IMAGE MODELS (this backlog)** — richness, depth, painterly material, one-off hero pieces:
> Key art · backgrounds & environment plates · full-screen FX frames · texture/material plates · illuminated card backers · promo/store art · lore interstitials.

## Locked prompt docs

- `PROMPT-watercolor-keyart.md` — current raster/watercolour lane, locked to the loved title exploration on 2026-06-15.
- `PROMPT-warm-system.md` — companion Claude Design / vector-system warming lane, used after the painted assets exist.

KA-1 is now locked to the loved title exploration references:

- `art/explorations/title-captured-loved-title-gadgets-refined.jpg`
- `art/explorations/title-captured-loved-title-exact.jpg`

Direction note from the first `gpt-image-2` test:

- Keep the ancient mystical-world drift. Lost gizmos and gadgets are the subject; distant secular ruins, pyramids, towers, and geometric storm-shapes can live in the space only as small, soft background flavor.
- Tighten graphical fidelity toward the exact loved title capture: matte low-fi 1990s cartoon/gouache background painting, not glossy high-polish AI key art.
- Reject hyper-detailed brass, over-sharpened stars, fantasy-concept-art crispness, and 3D-render lighting.
- Current test keepers live in `art/generated/`: v1 proved the composition, v2 proved the drift, and v3 is the closest matte low-fi direction so far.

## Every prompt starts with the master style header

Paste the **master fused style brief** from `HANDOFF-fusion.md §1` (the "Lumen Codex" block: palette, hinge=gold, type, fidelity) at the top of *every* generation. Then add the per-asset seed below.


---

## Backlog (prioritized)

### P0 — Hero & key art *(highest impact)*

| ID | Asset | Why raster | Prompt seed | Spec |
|----|-------|-----------|-------------|------|
| KA-1 | **Title key art** | painterly depth + illuminated richness sells the splash | **Locked seed:** see `PROMPT-watercolor-keyart.md` → KA-1 "wake the page". Watercolour cosmos, lost gilded gadgets in ancient mystical codex-space, single gold-leaf "G" seal upper-right, clean calm upper-centre wordmark band. Fidelity target: matte low-fi 1990s cartoon/gouache background, not glossy AI key art.  | 2560×1440 + 1080×1920 portrait crop; PSD/layers if possible |
| KA-2 | **Boss reveal — The Storm-Seal** | dramatic, one-off | "The Storm-Seal: a colossal counterfeit master-seal with a crooked false crown and cracked oxblood sub-seals looming over a darkened page; ominous but restrained, beautiful-not-horror" | 2560×1440; match `assets-fusion/boss-storm-seal.svg` |
| KA-3 | **App-icon master** | high-detail downscales to all icon sizes | refine the chosen Illuminated-G (`brand/emblem-flat-raster.png`) — crisper edges, neon-true cyan core | 1024×1024, then export 512/192/180/32 |

### P1 — Backgrounds & environment plates

| ID | Asset | Why raster | Prompt seed | Spec |
|----|-------|-----------|-------------|------|
| BG-1 | **The Hush — base playfield** | painterly codex-page depth behind gameplay | **Locked seed:** see `PROMPT-watercolor-keyart.md` → BG-1 "the dark page under the storm". Quiet Hush cosmos, low central contrast, no gadgets crowding play space, edges fade to void. | 2560×1440; low central contrast; additive-ready darks |
| BG-2 | **Parallax layers (×3)** | depth/motion | far: void + faint stars; mid: codex-page texture; near: margin ornament/thorn-rule | 3× 2560×1440, transparent where needed |
| BG-3 | **Region progression (×4)** | escalating illumination = progress | left→right moral-light: dark/ink early regions → gold-illuminated late regions | 4× 2048×2048 |
| BG-4 | **Title / menu plate** | the illuminated page frame | gold-leaf bordered page with corner wax-seals, marginal covenant emblems, quiet center | 2560×1440 |

### P1 — Full-screen FX frames *(composite as overlays)*

| ID | Asset | Prompt seed | Spec |
|----|-------|-------------|------|
| FX-1 | **Level-up Illumination bloom** | "a gold-ground aureole blooming from center, stipple-radiance rays relighting the dark page" | 2560×1440, additive-ready (dark→transparent) |
| FX-2 | **Cache / reliquary-open burst** | "an oxblood wax seal cracking, gold-white light + reward arcing out" | radial, additive |
| FX-3 | **Covenant burst set (×4)** | each economy detonating in its hue (mint/cyan/violet/gold) | 4× radial sprites |

### P2 — Texture & material plates *(highest reuse — composite onto vector)*

| ID | Asset | Prompt seed | Spec |
|----|-------|-------------|------|
| TX-1 | **Gold-leaf + craquelure** | "burnished gold leaf sheet with fine craquelure, warm" | 2048² tileable |
| TX-2 | **Parchment / vellum grain** | "warm parchment, subtle laid-paper grain, no print" | 2048² tileable |
| TX-3 | **Stipple-radiance overlay** | "dense scatter of luminous dots fading out, [hue]" | 2048², ×5 hues, additive |
| TX-4 | **Ink-grain / handmade edge** | "uneven ink edge & registration grain" | 2048² overlay |

### P1 — Card & unlock art

| ID | Asset | Prompt seed | Spec |
|----|-------|-------------|------|
| CD-1 | **Illuminated card backers** | painterly vellum/deckle richness behind vector sigil + text | **Locked seed:** see `PROMPT-watercolor-keyart.md` → CARD-1. Aged cream portrait panel, hand-inked + gold-leaf ruled border, oxblood diamond wax-seal, center left empty; four border-only hue variants (mint/cyan/violet/gold). | 4× 1024×1536; transparent outside deckle edge |
| CD-2 | **Covenant unlock plates (×4)** | polished roundels of Flow·Thread / Clutch·Breath / Echo·Vigil / Surge·Seal for big-moment screens | 4× 1024² |

### P2 — Promo & store
PR-1 feature graphic / banner (1024×500) · PR-2 screenshot frames + device mockups · PR-3 social avatar/header from the emblem.

### P3 — Optional illustrative / lore
LO-1 loading "codex page" interstitials · LO-2 Gizmo dormant→waking lore vignettes.

---

## Suggested order
1. **KA-1 title key art** from `PROMPT-watercolor-keyart.md` (seed now locked to the loved title exploration), then **KA-3 app icon**.
2. **BG-1 playfield** + **TX-1/TX-2 textures** (unlock the in-game look fast; textures feed everything).
3. **FX-1 illumination** + **CD-1 rarity backers** (the dopamine moments).
4. **KA-2 boss**, **BG-3 regions**, then promo/lore.

**Always:** generate 3–4 variants → run the fidelity gate → keep one → hand the keeper to Claude Code with its target spec. Pair every raster piece with the locked vector atom it extends, so the set stays one world.
