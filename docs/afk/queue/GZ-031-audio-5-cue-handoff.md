# GZ-031 — Service lane (audio-canon): convert and hand off 5 loop-critical cues

intent: The minimum sonic dressing for the loop: five cues converted per the audio lab's promoted handoff law and installed into `godot/audio/`. Pointer ticket — work runs inside `C:/Users/Shane/gizmo-audio-canon` under its `AGENTS.md`.

files in scope: NONE in the game repo except the lab's own explicit scripted handoff into `godot/audio/` (converted OGG + provenance sidecars only; raw MP4s never land — ecosystem yaml `audio_canon_to_game` seam).

grounding: `gizmo-audio-canon/canon/godot-handoff.yaml` (OGG Vorbis music/ambience, 48kHz 16-bit, −18 LUFS, loop-authored, ffmpeg -bitexact, provenance sidecar, 9 CI gates) + `canon/cue-map.yaml`. Cue selection (loop-critical five, per path-a spec §9 mapping): `spawn_awakening`, `first_steps_roam`, `trial_pressure`, `rekindle_siege`, `sanctuary_bed`.

decisions made: five cues, not twelve — the loop needs onset/roam/crest/siege/breath; the rest is deferred epic E1. Audition notes must be honest (`not auditioned` is acceptable per that lab's evidence rules; loudness must be MEASURED before install).

executable success criteria:
1. Lab-side: `python3 validators/validate_all.py --root .` exits 0 in gizmo-audio-canon after the conversions.
2. Game-side: `godot/audio/` contains 5 OGG files + sidecars; `${GODOT_BIN:-godot} --headless --path godot --import` exits 0; `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: five canon-mapped, loudness-measured, loop-authored OGGs importable in the game repo.
dependencies / order: none — FRONTIER (parallel to everything). Blocks GZ-032.
model routing: **Sonnet** — scripted, reproducible ffmpeg/EBU R128 pipeline with locked rules.
cross-domain: audio_canon lane; do not work this from the game repo.
status: ready-for-agent (route to an agent booted inside gizmo-audio-canon/)
format: one issue per file (gh import later).
