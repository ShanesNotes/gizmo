# GZ-192 — P7 (UI): onboarding — the first two minutes

intent: A stranger learns the loop without a tutorial level: contextual one-line prompts in the first run only (move → dash → collect → draft → beacon), each shown once, dismissed by doing.
files in scope: PRIMARY (new): `godot/scripts/onboarding.gd` + a HUD hint line (Cluster C); meta_state flag (seen_onboarding); tests: run_hud_tests + meta round-trip.
grounding: tone anchor ts:455 ("Move, dodge, collect shards, pick upgrades."); lore copy rules (warm, plucky, sentence case); trigger points all observable via existing surface (first input, first pickup, first awaiting_choice, first beacon proximity — API-CONTRACT).
decisions made: five hints max, each ≤ 8 words, world-anchored where possible (beacon hint IS the existing objective cue — no duplicate); suppressed entirely when seen_onboarding; no modal, no pause, no "tutorial" word anywhere.
executable success criteria: tests — each trigger shows its hint exactly once per fresh save, none on a seasoned save; absence — no modal nodes, no /tutorial/i text. Gate green.
dependencies / order: blockedBy GZ-172. Cluster C ordering.
model routing: **Haiku** — five strings and five triggers.
cross-domain: hint copy final pass = lore handoff (placeholders shippable).
status: deferred:P7
