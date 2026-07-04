# GZ-104 — E1 (lab+game): SFX first pass wired to sim events

intent: The loop's touch feedback: hit / death / pickup / level-up / dash one-shots (WAV law), generated+converted lab-side, played game-side off the existing event channel.

files in scope: lab half in gizmo-audio-canon (SFX grammar per `sources/ambient/Ambient-sound-design.md` prompt grammar; WAV short-SFX law per godot-handoff.yaml); game half: `godot/scripts/audio_director.gd` (SFX region) or, if GZ-102 not yet landed, a small `sfx_player.gd` consuming `simulation_events_emitted` (game_controller.gd:14).
grounding: event types verified live in sim (`grep '"type"' godot/scripts/simulation.gd` at pickup — same rule as GZ-021); Gizmo sonic identity: small and handcrafted, never industrial (audio lab inherited canon — validator-enforced forbidden language).
decisions made: 5 SFX ids (sfx_hit, sfx_death, sfx_pickup, sfx_levelup, sfx_dash) registered in the lab's cue-map before conversion (their A1 traceability gate); polyphony cap 8 via SFX bus player pool.
executable success criteria: lab validators green; game: new tests assert event→SFX id mapping and the polyphony cap; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-103; benefits from GZ-102 but may precede it (recorded: sfx_player.gd is an acceptable interim, deleted by GZ-102's consolidation).
model routing: **Sonnet** — cross-repo coordination with locked laws.
cross-domain: cue ids minted lab-side FIRST (their canon owns the vocabulary), then consumed.
status: deferred:E1
format: one issue per file (gh import later).
