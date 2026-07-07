# ECOSYSTEM WIRING PLAN — produced material → playable demo

**Author:** Fable (principal), 2026-07-06 late. **Trigger:** Shane's zoom-out directive
after the demo wave generated NEW music beside a produced 61-track score. **Law:** the
ecosystem routing map (`gizmo-ecosystem.yaml`) — siblings are sources of truth; the game
repo implements; cross-domain conflicts get reconciliation notes, never silent picks.

## The miss, named precisely
The demo wave (PR #28) consumed the audio-canon *interface contract* but not the
*produced material behind it*. Two ElevenLabs loops were generated while
`/home/ark/gizmo-soundtrack` holds **61 produced MP4 cues** — a dual-variant score
(JAZZ = world under pressure / ORCH = world at ease, provisional polarity) with SEG
(zone segments), AMB (ambient beds incl. vitals overlay), and BRG (12 authored
transition bridges), plus a machine-readable cue map
(`docs/audio/soundtrack_cue_map_v2.json`) and a full AudioDirector-v2 implementation
spec (`docs/audio/soundtrack-map-v2.md`). Similarly, the four meshy enemy models
bypassed the asset-pipeline lab's brief→generate→cleanup→promote machinery.

## Inventory of produced-but-unwired material (verified tonight)
| Sibling | Material | State |
|---|---|---|
| soundtrack_source | 61 MP4 cues (SEG/AMB/BRG × JAZZ/ORCH) | sha256 manifest in audio-canon; NOT auditioned; never ship raw |
| audio_canon | cue-map, motifs, production standards, godot-handoff, AudioDirector-v2 spec | complete; awaiting conversion + implementation |
| level_design | `docs/reference/shattered-meridian-region-graph.json` (in-repo!), encounter-beats.yaml, audio-integration.yaml, landmark taxonomy | region graph landed, never consumed by the generator |
| visual_symbolic_design | HUD theme publisher (make publish-godot-theme), shader-matrix.yaml (gouache render-target G12), Meridian Concordance | theme witness present (staleness unchecked); painterly look unimplemented |
| asset_pipeline | briefs/{character,enemies,landmarks,props,world-kit}, Meshy workflow canon, import gates, promotion reports | machinery ready; tonight's 4 models bypassed it |
| lore | glossary, copy-rules, fiction-mechanics, world-structure | benefactor names + door/codex copy awaiting promotion (research §6 questions outstanding) |

## Phases (ordered by demo impact × material readiness)

### Phase 0 — Reconciliation notes (Fable, tonight, no code)
- **R1 audio:** EL music loops are demo-provisional, superseded by Phase 1; EL SFX
  remain but must be reconciled against audio-canon's own SFX prompt grammar
  (`gizmo/docs/generation-prompts/03-sfx-elevenlabs.md`) — note filed lab-side.
- **R2 assets:** the four meshy models are draft witnesses pending retroactive briefs +
  promotion reports in the asset lab; future generations route through the lab.

### Phase 1 — SOUNDTRACK V2 LIVE (the headline; tonight)
1. **Conversion batch** (orchestrator): all 61 MP4 → 48k OGG per godot-handoff
   (`ffmpeg -bitexact`), landing `godot/audio/music/soundtrack_v2/` with the manifest
   copied alongside; loudness gate still deferred to the lab's audition pass (recorded).
2. **AudioDirector v2** (Codex, one big slice off the written spec): cue registry from
   `soundtrack_cue_map_v2.json`; dual-variant selection with hysteresis (engage ≥0.25,
   relax <0.15, 20s dwell) driven by a pressure scalar the orchestrator computes from
   live-enemy count/tier; presence grammar (authored silence at spawn, 45s idle fade,
   immediate cut edges); BRG bridges on state edges; menu/UI cues (title = SEG_01 ORCH,
   defeat = 2-4s silence then SEG_06 ORCH once, victory = SEG_12 ORCH); vitals overlay
   AMB_03 via notify_vitals. **Zone reconciliation:** the cue map speaks Path A zones —
   map pivot states provisionally (HUB→SEG_01/AMB_01 family, COMBAT→trial-family JAZZ,
   CLEARED→calm ORCH, BOSS→siege family) and record every assignment as
   audition-pending in the handoff note (extends the vocabulary-rev request already
   filed). Gates A3/A4/A9/A10/A12/A13/A14 are reject conditions.
3. EL loops demoted to fallback cues; deleted once v2 passes ceremony.

### Phase 2 — Asset pipeline becomes the only asset door (tomorrow)
Retro-brief + promotion reports for the 4 models (lab-side); wrapper-install layout
(`godot/assets/<category>/<asset_id>/`); then the lab's existing briefs
(landmarks/props/world-kit) start filling rooms — the demo's set dressing lane.

### Phase 3 — The gouache look (tomorrow; design-system owns)
Implement the shader-matrix render-target decision (G12): painterly CompositorEffect
or per-material stack per the matrix; republish HUD theme if drifted. This is the
single biggest visual jump available and it is already specified lab-side.

### Phase 4 — Region grammar into the run generator (tomorrow)
Generator consumes `shattered-meridian-region-graph.json` + encounter-beats for biome
identity (room names, moods, encounter pacing per region); level-design's
audio-integration.yaml then binds zones→cues properly (replaces my provisional map).

### Phase 5 — Lore promotion loop (async)
Send research §6 answers + benefactor role-id table to the lore canvas; consume
returned names/copy for benefactor display names, door telegraphs, codex strings.

## Execution reality (Fable access ends unannounced tomorrow)
Tonight: Phase 0 + Phase 1 (conversion mine; AudioDirector v2 on Codex; ceremony after).
Tomorrow-safe: every phase above is written to be executable by Opus/Codex without
Fable — specs are in sibling canons; this plan is the router.
