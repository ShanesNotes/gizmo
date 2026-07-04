# GZ-191 — P7 (UI): settings menu

intent: The shell grows up: audio sliders (Music/Ambience/SFX buses), window mode, and input rebinding behind the pause menu — persisted in meta_state.
files in scope: PRIMARY (new): `godot/scenes/settings_menu.tscn` + `godot/scripts/settings_menu.gd`; hooks in pause_menu.gd + meta_state.gd (settings dict); tests: extend run_meta_state_tests + a UI runner case.
grounding: GZ-103 buses (sliders map to AudioServer bus volume_db, verify API in 4.7 docs); GZ-172 persistence law (settings ride the same save, schema-versioned); rebinding via InputMap runtime API (godot-prompter:input-handling).
decisions made: v1.0 scope EXACTLY — three volume sliders, fullscreen/windowed toggle, rebind for move/dash/interact/pause, reset-to-defaults; nothing else (no graphics presets — the art pipeline is fixed-target by design).
executable success criteria: tests — slider value → bus dB round-trips through save/load; rebind persists and survives restart; reset restores defaults. Gate green.
dependencies / order: blockedBy GZ-041, GZ-103, GZ-172.
model routing: **Sonnet**.
status: deferred:P7
