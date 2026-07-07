# Voice scripts v3 — threshold address sweep (2026-07-07 night, lore lane)

derived from lore canon; do not edit as source
(voice-scripts-v1 registers govern; copy-rules law: no wave/round/countdown words, the
Spark flares/surges never spent, ≤12 spoken words, sentence case.)

## THE PATTERN — pre-boss door address (`pattern_door`, 2 variants, rotate)
The pattern speaks BEFORE the door, from the antechamber. Same casting law as v1
(Daniel, stability .92 style .03, chorus doubling; menace as serenity).
1. "You are expected. The door was never locked to you."
2. "Come through. I have prepared a quiet place for it."

## MARGIN — region-entry lines (`margin_region_<region_id>`, 1 each)
Region dialect color: each line carries its region's landmark character (RegionTable
is the naming source of truth). Locked casting: Lily, .35/.65/.85, halo echo.
- `margin_region_hearth`: "Hearthwake. Every keeping starts warm. Go while it lasts."
- `margin_region_brass`: "Brasswind. The keeps still count hours no one lives."
- `margin_region_verdant`: "The Archive grows. Trees remember gentler librarians."
- `margin_region_prism`: "Prism Reach. Light here forgets which way it was going."
- `margin_region_tempest`: "The Verge. The storm engine never learned to rest."
- `margin_region_null`: "The Null Crown. Hold your light close now, little keeper."
- `margin_region_rust`: "Rustchain. The titans slept before they were finished."
- `margin_region_ash`: "Ashfall. The crucible remembers every shape it gave."

## MARGIN — run-milestone barks (once per run each)
- `margin_flawless` (first room cleared untouched): "Not one scratch entered. The page stays clean."
- `margin_near_death` (room cleared after HP ran low): "You nearly joined the quiet. You did not. Write that."

## MARGIN — title-screen attract (`margin_attract`, 1)
- "The lamp is lit, keeper. The page is open."
Wiring note: title_screen.gd is outside the lore fence — file + manifest ship now;
the one-call wiring is queued as an INDEX follow-up for the design lane.

## Wiring (run_orchestrator.gd AUDIO region only)
- Region entry: audio-region tracker `_maybe_speak_region_entry(room)` — speaks on
  region_id change; NULL/HEARTH included; one line per region per run.
- Pattern pre-door: on loading a room whose next rooms include the boss chamber,
  after Margin's existing cleared-room warning law: Margin warns on clear (existing
  `_maybe_speak_boss_warning`), the Pattern addresses on antechamber entry.
- Flawless/near-death: derived inside the audio region from data already flowing
  through it (`notify_vitals` + zone-state transitions); one fire per run each.
