class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## First slice: the player's Sparks (the `xp` currency in code) and re-humanizing
## (leveling). Pure data + math — no scene, no rendering — so it runs and is
## tested headlessly. Anchors:
##   design / tuning intent  -> reference/game-balance-reference.md §5 (Progression, XP)
##   fiction (system→meaning) -> design-handoff/NARRATIVE.md §4 (Sparks = xp; level up = re-humanize)
##   mechanics source of truth -> game-src-phaser/src/game/simulation.ts

## Re-humanizing progress. "Sparks" in the fiction; `xp` in the Phaser code.
var level: int = 1     # simulation.ts:359
var xp: int = 0        # Sparks banked toward the next level (simulation.ts:360)
var next_xp: int = 0   # Sparks needed for the next level (simulation.ts:361)

func _init() -> void:
	next_xp = next_xp_for_level(level)

## Sparks needed to advance FROM `lvl` to the next level.
## Faithful to nextXpForLevel() — simulation.ts:1721-1725.
static func next_xp_for_level(lvl: int) -> int:
	var base := 56.0 + lvl * 14.0 + pow(lvl, 1.8) * 12.5
	var pacing := 1.12 if lvl == 1 else 1.48 + minf(0.36, (lvl - 2) * 0.07)
	return int(floor(base * pacing))

## Bank Sparks. Returns true if it triggered a level-up (re-humanizing).
## Mirrors the level-up block — simulation.ts:1029-1038 — where the remainder
## carries into the next level. Pickup values are non-negative, so we guard.
func add_xp(amount: int) -> bool:
	xp += maxi(0, amount)
	if xp >= next_xp:
		xp -= next_xp
		level += 1
		next_xp = next_xp_for_level(level)
		return true
	return false

## How full the Sparks bar is, 0..1 — for the HUD later.
## Faithful to xpProgress() — simulation.ts:534.
func xp_progress() -> float:
	return clampf(float(xp) / next_xp, 0.0, 1.0)
