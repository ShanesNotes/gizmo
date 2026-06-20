class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## Slices: Sparks & leveling (0006); run clock & player health (0007).
## Anchors: design intent -> reference/game-balance-reference.md §5;
##          fiction       -> design-handoff/NARRATIVE.md §4;
##          mechanics     -> game-src-phaser/src/game/simulation.ts
## ADR 0001: player HP here is the health bar — NOT the Spark of Humanity meter
## (a separate objective meter, mechanics TBD).

# Run phases (simulation.ts:1 RunPhase; "levelup" arrives with upgrades later).
const PHASE_PLAYING := "playing"
const PHASE_COMPLETE := "complete"
const PHASE_GAMEOVER := "gameover"

const RUN_DURATION := 240.0   # simulation.ts:202
const MAX_DT := 0.05          # safeDt clamp (simulation.ts:463)
const HIT_INVULN := 1.58      # i-frames after a hit (simulation.ts:724)

var phase := PHASE_PLAYING

# --- Sparks & leveling (0006) ---
var level: int = 1     # simulation.ts:359
var xp: int = 0
var next_xp: int = 0

# --- Run clock & health (0007) ---
var elapsed: float = 0.0
var run_duration: float = RUN_DURATION
var hp: int = 7        # simulation.ts:349 (createGameState)
var max_hp: int = 7
var invulnerable: float = 0.0

func _init() -> void:
	next_xp = next_xp_for_level(level)

# ---- Sparks & leveling ----

static func next_xp_for_level(lvl: int) -> int:
	var base := 56.0 + lvl * 14.0 + pow(lvl, 1.8) * 12.5
	var pacing := 1.12 if lvl == 1 else 1.48 + minf(0.36, (lvl - 2) * 0.07)
	return int(floor(base * pacing))

func add_xp(amount: int) -> bool:
	xp += maxi(0, amount)
	if xp >= next_xp:
		xp -= next_xp
		level += 1
		next_xp = next_xp_for_level(level)
		return true
	return false

func xp_progress() -> float:
	return clampf(float(xp) / next_xp, 0.0, 1.0)

# ---- Run clock & health ----

## Advance the run by dt seconds. Mirrors the top of updateGameState
## (simulation.ts:459-494): a no-op unless playing; dt is clamped so a stutter
## can't skip ahead; the run COMPLETES (a win) when the timer runs out.
func tick(dt: float) -> void:
	if phase != PHASE_PLAYING:
		return
	var safe_dt := clampf(dt, 0.0, MAX_DT)  # also guards a negative dt rewinding the run
	elapsed += safe_dt
	invulnerable = maxf(0.0, invulnerable - safe_dt)
	if elapsed >= run_duration:
		phase = PHASE_COMPLETE

## 0..1 fraction of the run elapsed. Faithful to runProgress (simulation.ts:533).
func run_progress() -> float:
	return clampf(elapsed / run_duration, 0.0, 1.0)

## Seconds left in the run. Faithful to timeRemaining (simulation.ts:535).
func time_remaining() -> float:
	return maxf(0.0, run_duration - elapsed)

## How full the HP bar is, 0..1 — for the HUD (mirrors xp_progress's shape).
## Design: HP is the raw defensive pool (balance §3.1).
func hp_progress() -> float:
	return clampf(float(hp) / max_hp, 0.0, 1.0)

## Apply damage to the player's HP. Returns true only if the hit landed.
## Mirrors the contact-damage primitive in simulation.ts:722-738: a real hit
## lowers HP, grants i-frames, floors at 0, and reaching 0 ends the run
## (gameover/lose). Zero/negative damage is a no-op — it must NOT grant free
## i-frames (matters once armor/shields/blocked hits exist; balance §3.4).
## Deferred to later lessons: the enemy-contact "elapsed > 7" grace, knockback,
## and the secondWind one-time save (simulation.ts:732-736). NOTE (ADR 0001):
## this is the health bar, NOT the Spark of Humanity meter.
func take_damage(amount: int) -> bool:
	if amount <= 0:
		return false
	if phase != PHASE_PLAYING or invulnerable > 0.0:
		return false
	hp = maxi(0, hp - amount)
	invulnerable = HIT_INVULN
	if hp <= 0:
		phase = PHASE_GAMEOVER
	return true
