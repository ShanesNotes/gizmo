# GZ-134 — E3 (game): HUD reflects the world's hollowing

intent: The cartouche itself participates: at sustained high exposure the HUD frame cools/drains subtly; guard-lit warmth returns in sanctuary and at rekindle. Small, felt, never a meter (no exposure readout — spec §7 stands).
files in scope: PRIMARY: `godot/scripts/hud.gd` + hud.tscn (theme PARAMETER modulation only — never edits hud_theme.tres); tests: run_hud_tests.gd.
grounding: design-system exposure token group (drain ramps, violence, ember role-keys exist in tokens); spec §7's "no exposure meter" — this is ambient modulation, below conscious readout; GZ-133's smoothed exposure signal (reuse it — one authority).
decisions made: modulation range capped subtle (≤ 12% desaturation/cool shift of the frame modulate color — a felt chill, not a signal); disabled entirely on the end screens.
executable success criteria: tests assert modulate tracks the style director's blend within the cap, and NO node exposes a numeric/bar representation of exposure; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-133. Cluster C (hud files) — one in flight at a time.
model routing: **Haiku** — one modulate binding with a cap.
cross-domain: token role-keys consumed only.
status: deferred:E3
