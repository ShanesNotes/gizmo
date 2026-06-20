class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## First slice: player XP and leveling. No scene, no rendering — pure and testable.

var level: int = 1
var xp: int = 0
var next_xp: int = 0

func _init() -> void:
	next_xp = next_xp_for_level(level)

## XP needed to advance FROM `lvl` to the next level.
## Faithful to nextXpForLevel() in simulation.ts.
static func next_xp_for_level(lvl: int) -> int:
	var base := 56.0 + lvl * 14.0 + pow(lvl, 1.8) * 12.5
	var pacing := 1.12 if lvl == 1 else 1.48 + minf(0.36, (lvl - 2) * 0.07)
	return int(floor(base * pacing))

## Grant XP. Returns true if it triggered a level-up.
## Mirrors the level-up block in simulation.ts: the remainder carries over.
func add_xp(amount: int) -> bool:
	xp += amount
	if xp >= next_xp:
		xp -= next_xp
		level += 1
		next_xp = next_xp_for_level(level)
		return true
	return false
