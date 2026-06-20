class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## Slices: Sparks & leveling (0006); run clock & player health (0007);
##         enemies — spawn, chase, contact (0008).
## Anchors: design intent -> reference/game-balance-reference.md (§3, §5);
##          fiction       -> design-handoff/NARRATIVE.md §4;
##          mechanics     -> game-src-phaser/src/game/simulation.ts
## ADR 0001: player HP is the health bar — NOT the Spark of Humanity meter.
## ADR 0002: Simulation owns the rules (incl. enemies); the scene renders them.
##           Values are in Godot metres, not Phaser pixels.

# Run phases (simulation.ts:1 RunPhase; "levelup" arrives with upgrades later).
const PHASE_PLAYING := "playing"
const PHASE_COMPLETE := "complete"
const PHASE_GAMEOVER := "gameover"

const RUN_DURATION := 240.0   # simulation.ts:202
const MAX_DT := 0.05          # safeDt clamp (simulation.ts:463)
const HIT_INVULN := 1.58      # i-frames after a hit (simulation.ts:724)

# Enemies — in Godot metres (ADR 0002); relative balance from ENEMY_SPECS
# (simulation.ts:259). nibbler = the basic chaser (unlockAt 0).
const SPAWN_RING := 12.0      # distance from the player that enemies spawn at
const NIBBLER_SPEED := 3.5    # m/s — slower than Gizmo (6.0) so he can kite
const NIBBLER_RADIUS := 1.0   # contact reach
const NIBBLER_HP := 1.0
const NIBBLER_DAMAGE := 1     # faithful to ENEMY_SPECS.nibbler.damage

## One enemy as a lightweight data agent (ADR 0002). The scene mirrors these.
class Enemy extends RefCounted:
	var position := Vector3.ZERO
	var hp: float = 1.0
	var speed: float = 0.0
	var radius: float = 1.0
	var damage: int = 1
	var kind: String = ""

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

# --- Enemies (0008) ---
var enemies: Array[Enemy] = []
var spawn_interval := 1.2     # seconds between spawns (v1 seed; cadence = balance §5.3 later)
var _spawn_timer := 0.0
var _spawn_count := 0

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

# ---- Run clock, health & enemies ----

## Advance the run by dt seconds, given where Gizmo is (for enemy targeting).
## Mirrors the top of updateGameState (simulation.ts:459-494): a no-op unless
## playing; dt is clamped so a stutter can't skip ahead (or a negative frame
## rewind); enemies update; the run COMPLETES (a win) when the timer runs out.
func tick(dt: float, gizmo_position := Vector3.ZERO) -> void:
	if phase != PHASE_PLAYING:
		return
	var safe_dt := clampf(dt, 0.0, MAX_DT)
	elapsed += safe_dt
	invulnerable = maxf(0.0, invulnerable - safe_dt)
	_update_enemies(safe_dt, gizmo_position)
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

## Spawn on a cadence, then seek the player and deal contact damage.
## Open-floor seek steering, not navigation (ADR 0002). Called from tick().
func _update_enemies(dt: float, gizmo_position: Vector3) -> void:
	_spawn_timer += dt
	if _spawn_timer >= spawn_interval:
		_spawn_timer -= spawn_interval
		_spawn_nibbler(gizmo_position)
	for e in enemies:
		var to_player := gizmo_position - e.position
		to_player.y = 0.0  # stay on the floor plane
		var dist := to_player.length()
		if dist > 0.0001:
			e.position += to_player / dist * e.speed * dt  # seek toward Gizmo
		if dist <= e.radius:
			take_damage(e.damage)  # contact; i-frames handle overlap/repeat

## Spawn one nibbler on a ring around the player. The angle is deterministic
## (golden-angle spread) so tests don't depend on RNG.
func _spawn_nibbler(gizmo_position: Vector3) -> void:
	var angle := _spawn_count * 2.39996323  # golden angle (radians)
	_spawn_count += 1
	var e := Enemy.new()
	e.kind = "nibbler"
	e.position = gizmo_position + Vector3(cos(angle), 0.0, sin(angle)) * SPAWN_RING
	e.hp = NIBBLER_HP
	e.speed = NIBBLER_SPEED
	e.radius = NIBBLER_RADIUS
	e.damage = NIBBLER_DAMAGE
	enemies.append(e)
