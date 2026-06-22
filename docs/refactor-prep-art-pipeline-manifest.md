# Refactor prep — art/audio/world-pipeline hygiene manifest

Status: read-only classification for the Path A refactor prep pass. No files were
moved, deleted, staged, or rewritten to produce this manifest.

## Classification rule

- **Keep:** forward-useful source/reference/backlog material that can inform later art
  implementation, but still must be reconciled against active canon before use.
- **Archive-candidate:** logs or one-off pipeline records from previous art-stream work;
  useful as history, not active architecture.
- **Rebuild-needed:** contains useful intent but stale mechanics, stale paths, or references
  to quarantined/untracked runtime assets; rebuild from active Path A canon before relying on it.

## Keep

| Path | Why keep | Caution |
|---|---|---|
| `design-handoff/concept art/` | Strong visual source material for Gizmo, enemies, world tone, beacon/tower/workshop/spark references. | Art reference only; concept-art wave/boss implications do not override ADR 0003. |
| `docs/world-asset-prompts.md` | Best forward asset-prompt backlog for image-model → Meshy → Godot workflow. | Update the `beacon_01` label that says "carry the Spark to the Beacon" before using it as implementation copy. |
| `docs/first-level-visual-asset-backlog.md` | Prioritizes top hero/environment assets and records generated reference/Meshy decisions. | Treat as backlog, not proof that assets are committed/active. |
| `docs/meshy-connector-preflight.md` | Operational evidence for Meshy connector availability. | Credential/tool availability must be rechecked before credit-spending work. |
| `docs/meshy-mcp-setup.md` | Useful local setup instructions for Meshy MCP. | Never commit `.env` or API keys; run from user shell when needed. |
| `docs/meshy-world-kit-prompts.md` | Useful first-pass GLB prompt templates for floor/pylon kit. | Earlier cost gates still apply; generated assets may now live in quarantine/untracked paths. |
| `/home/ark/gizmo-audio-canon/sources/ambient/Ambient-sound-design.md` | User-authored sonic identity; strong material language for brass/stone/blue energy. | Contains retired wave-counter/wave-layer language; use identity sections, not mechanics sections, until cleaned. |
| `tools/audio/generate_clockwork_sfx.py` | Reproducible local synthesis path for grounded SFX. | Only promote if matching audio assets/tests are promoted too. |
| `tools/blender/gen_floating_islands.py` and `tools/blender/optimize_glb.py` | Useful author-time geometry/optimization tools. | ADR 0008 says baker/stagehand tooling must be rebuilt with manifests/provenance before active use. |
| `tools/run-meshy-mcp.sh` | Useful MCP launcher wrapper. | Keep credentials local; confirm package/API state before use. |

## Archive-candidate

These should remain available as history, but should not be treated as active architecture
for the Path A refactor:

| Path | Why archive-candidate |
|---|---|
| `docs/enemy-visual-log.md` | Meshy enemy integration log for Nibbler 01; useful provenance, but tied to art-stream scene/script files not in the clean committed gate. |
| `docs/gizmo-animation-log.md` | Walk-sheet/rig animation experiment log; useful teaching record, but animation clips are later scope per `CONTEXT.md`. |
| `docs/meshy-world-kit-generation-log.md` | Credit/task provenance for first floor/pylon Meshy kit; keep as generation history, not active layout authority. |
| `docs/meshy-image-reference-generation-log.md` | Credit/task provenance for generated reference/Meshy north-beacon work; useful, but asset promotion depends on later art-stream decision. |
| `godot/_quarantine/2026-06-21-pre-art-refactor/` | Already a quarantine/rollback archive containing art/audio/world-kit experiments and originals. Do not pull from it blindly during the loop refactor. |

## Rebuild-needed before active use

| Path | Rebuild reason |
|---|---|
| `docs/first-level-asset-pipeline.md` | Early inventory references `/home/ark/Downloads`, old scene state, and asset-promotion assumptions. Rebuild as a current tracked-asset manifest after the Path A loop refactor chooses which art-stream files to promote. |
| `docs/first-level-expansion-audit.md` | Useful diagnosis, but it describes the expanded first-level/audio/art ultragoal rather than the current clean committed gate. Rebuild if the refactor needs a fresh implementation order. |
| `docs/first-level-audio-pipeline.md` | Documents untracked/quarantined GameAudio wiring; rebuild only if audio stream is promoted into committed code. |
| `docs/first-level-audio-redesign.md` | Good mix intent, but references untracked audio implementation. Rebuild or trim to design intent before commit. |
| `docs/first-level-feedback-pipeline.md` | Documents FeedbackFx/GameAudio bridge from art-stream work. Rebuild after deciding whether those scene-side hooks enter the committed slice. |
| `docs/first-level-sfx-redesign.md` | Useful sound-design target, but depends on untracked generated WAVs/tests. Rebuild alongside any committed SFX promotion. |
| `docs/first-level-procedural-layout.md` | Documents a 91-tile expanded layout and world-kit wrapper path that is not the clean committed gate. Rebuild after ADR 0008 stagehand rules are implemented. |

## Immediate refactor guidance

- Do not archive/move anything yet; this pass only classifies.
- During the Path A loop refactor, read art-stream docs as optional design context, not as source of truth.
- The active implementation authority remains `CONTEXT.md`, ADRs 0003/0005/0006/0008, and committed Godot code/tests.
- Promote art/audio/world files only in small, test-backed slices after the loop refactor has a stable simulation/HUD seam.
