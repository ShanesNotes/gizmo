# Gizmo Generation-Prompt Pack

`derived from ecosystem canon (lore, design-system, level-design, audio-canon, asset-pipeline); do not edit as source — edit the lab canon and regenerate`

Master prompt pack for AI asset generation. Written for a Codex session with MCP/API access
(Meshy, ElevenLabs, imagegen 2.0). Every prompt is canon-bound with provenance; Codex should
copy prompts verbatim, record provenance sidecars, and never improvise past the negative lists.

## Files

| File | Tool lane | Contents |
|---|---|---|
| `01-3d-meshy.md` | Meshy (text-to-3D / image-to-3D) | 14 queue items + enemies + pickups |
| `02-images-imagegen.md` | imagegen 2.0 | Reference sheets for image-to-3D, key art, HUD elements, end screens, icons |
| `03-sfx-elevenlabs.md` | ElevenLabs SFX v2 | Gizmo body/voice SFX, swarm, pickups, guard/HP, Beacon, UI |
| `04-music-ambience.md` | AIVA (shippable) / prototyping tools | 12 Path A cues × ORCH/JAZZ, bridges, 5 ambient beds |
| `05-voices-elevenlabs.md` | ElevenLabs Voice Design + TTS | Marginalia, Wick, Rote, Four Voices of the Hush |
| `06-map-environment.md` | imagegen 2.0 → Meshy | Zone-by-zone environment/map prompts along the Path A spine |

## Global law (applies to every prompt in this pack)

**Style tag — append to every visual prompt** (`gizmo-asset-pipeline/canon/prompt-grammar.yaml`):

> hand-painted gouache storybook; warm patinated brass and bronze + carved sandstone; teal/cyan
> glowing rune accents used scarcely; violet spark-crystal motif; matte, soft, weathered; deep
> violet shadows, warm highlights. Not photoreal, not neon, not glossy.

**Visual negative defaults** — append to every visual prompt:

> no photoreal chrome, no generic sci-fi droid or portal, no horror gore, no text labels or
> logos, no tiny filigree that will mush at gameplay scale, no direct copyrighted character
> resemblance, no neon glow flooding the object

**Scarce-light law (G6, X-L1)** — saturated teal-cyan (`#3fa9b6` / core `#8fe6e6`) appears ONLY on:
Gizmo's single faced eye/core, the guard layer, and an active Beacon's core-spark. Never on
currency, pickups, ambient fill, or decoration. Sparks crystals are **violet/indigo body
(`#7b62a4`/`#574073`/`#8a5bb0`) with warm gold-white inner glow (`#e0c17a`) — never teal** (ruling D6).

**Crimson discipline (G9)** — crimson `#da383b` is acute violence/contact punctuation only, never
baseline or ambient.

**Page vs world (X-P1, ruling D7)** — parchment ground (`#fdefde`/`#fae5cc`) is for HUD/UI/Codex
surfaces only; world scenery grounds in deep violet-void (`#1c1f23`), night-blue (`#2a4468`),
enchant-plum (`#574073`). Never a parchment sky, never a violet-void HUD panel.

**Face axis (G2, M4)** — Face = alive, faceless = hollowed. Hollowed things are the world's own
warm forms **de-faced, drained, mechanize-repeated, decayed** — never gears/circuits/cold-steel
invading an organic world. Night and the moon are never inherently evil; only de-facing is corrupt.

**Distinct quantities** — HP ≠ Guard ≠ Sparks ≠ Scrap ≠ Spark of Humanity. Visually, sonically,
and in copy. Never one all-purpose "spark" identity.

**Forbidden language in any prompt or filename** (validator-enforced,
`gizmo-asset-pipeline/canon/lore-bindings.yaml`, `gizmo-lore/validators/validate_lore_terms.py`):
"carry the spark to the beacon", "wave " / "waves of" / wave counters, "countdown", "boss arena",
"elite round", "spark fuel" / "fueled by the spark", "health pack", "save point",
"in the style of <living artist>". Pressure is director-driven and diegetic — siege, exposure,
encroachment — never rounds or timers.

**Provenance sidecar — required per generation before use**
(`gizmo-asset-pipeline/canon/policy.yaml` P2/P11; `gizmo-audio-canon/canon/production-standards.yaml`):
`[asset_id, prompt, tool, model, version, seed, params, task_id, utc_date, credit_cost, sha256]`
— ledger-before-use; no-retry-spend on a gate reject; 3-strike circuit breaker per asset.

**Audio delivery law** (`gizmo-audio-canon/canon/godot-handoff.yaml`): music/ambience loops → OGG
Vorbis with the loop-return point at file end (offset 0); SFX one-shots → WAV 48kHz/16-bit;
program loudness −18 LUFS integrated / −1 dBTP; raw generations stay in the audio lab's sources —
only converted, gate-passed files land in `godot/audio/`.

**Camera law** — everything must read at the fixed Diablo camera (offset (0,12,10), FOV 50,
~50° pitch, 1280×720). Silhouette + lighting carry identity, not fine texture. Check Meshy back
views first (known drift failure).

## Provenance anchors

- Game loop/mechanics: `gizmo/CONTEXT.md`, `docs/path-a-shattered-meridian-spec.md`, ADRs 0005–0008
- Visual law: `gizmo-design-system/canon/{CANON.md,motifs.yaml,bindings.yaml,acceptance-gates.md,concordance.yaml}`, `tokens/tokens.json`
- Narrative law: `gizmo-lore/canon/{LORE_CANON.md,glossary.yaml,fiction-mechanics.yaml,copy-rules.yaml}`
- Spatial law: `gizmo-level-design/canon/` (gates L1–L12, route-grammar, pressure-zones)
- Sonic law: `gizmo-audio-canon/canon/` (gates A1–A14, cue-map, motifs, ambient-layers), `reference/elevenlabs-*.md`
- Generation law: `gizmo-asset-pipeline/canon/{policy,lore-bindings,meshy-workflow,prompt-grammar,budgets,animation-pipeline}.yaml`, `queue/QUEUE.yaml`
