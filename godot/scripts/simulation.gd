class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## Slices: Sparks & leveling (0006); run clock & player health (0007);
##         enemies — spawn, chase, separate, contact (0008).
## Anchors: design intent -> reference/game-balance-reference.md (§3, §5, §6);
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
const CONTACT_GRACE := 7.0    # no contact damage before this (simulation.ts:722, "elapsed > 7")
const PLAYER_CONTACT_RADIUS := 0.4  # the player's own contact reach (metres)

# Enemies — in Godot metres (ADR 0002); relative balance from ENEMY_SPECS
# (simulation.ts:259). nibbler = the basic chaser (unlockAt 0).
const SPAWN_RING := 9.0       # spawn distance from the player (inside the 20x20 floor)
const NIBBLER_SPEED := 3.5    # m/s — slower than Gizmo (6.0) so he can kite
const NIBBLER_RADIUS := 1.0   # contact reach / separation radius
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
var max_enemies := 60         # alive-enemy cap (balance §6.1; simulation.ts MAX_ENEMIES 122)
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
	if run_duration <= 0.0:
		return 1.0
	return clampf(elapsed / run_duration, 0.0, 1.0)

## Seconds left in the run. Faithful to timeRemaining (simulation.ts:535).
func time_remaining() -> float:
	return maxf(0.0, run_duration - elapsed)

## How full the HP bar is, 0..1 — for the HUD (mirrors xp_progress's shape).
## Design: HP is the raw defensive pool (balance §3.1).
func hp_progress() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(hp) / max_hp, 0.0, 1.0)

## Apply damage to the player's HP. Returns true only if the hit landed.
## Mirrors the contact-damage primitive in simulation.ts:722-738: a real hit
## lowers HP, grants i-frames, floors at 0, and reaching 0 ends the run
## (gameover/lose). Zero/negative damage is a no-op — it must NOT grant free
## i-frames (matters once armor/shields/blocked hits exist; balance §3.4).
## Deferred to later lessons: knockback and the secondWind one-time save
## (simulation.ts:732-736). NOTE (ADR 0001): the health bar, not the Spark of
## Humanity meter.
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

## Spawn (capped), seek the player, separate so the pack reads as a crowd, then
## deal contact damage. Open-floor seek + soft separation, not navigation
## (ADR 0002). Called from tick().
func _update_enemies(dt: float, gizmo_position: Vector3) -> void:
	# 1. Spawn on a cadence, up to the alive cap (balance §6.1).
	_spawn_timer += dt
	if _spawn_timer >= spawn_interval:
		_spawn_timer -= spawn_interval
		if enemies.size() < max_enemies:
			_spawn_nibbler(gizmo_position)
	# 2. Seek toward Gizmo on the floor plane.
	for e in enemies:
		var to_player := gizmo_position - e.position
		to_player.y = 0.0
		var dist := to_player.length()
		if dist > 0.0001:
			e.position += to_player / dist * e.speed * dt
	# 3. Soft separation so overlapping enemies read as a crowd, not one blob.
	_separate_enemies()
	# 4. Contact damage — AFTER moving, using the player's contact radius, and
	#    only after the opening grace (simulation.ts:722). i-frames handle overlap.
	if elapsed > CONTACT_GRACE:
		for e in enemies:
			var to_player := gizmo_position - e.position
			to_player.y = 0.0
			if to_player.length() <= e.radius + PLAYER_CONTACT_RADIUS:
				take_damage(e.damage)

## Push overlapping enemies apart on the XZ plane by half their overlap each.
## Deterministic (no RNG) so tests are stable. O(n^2) — fine for a teaching
## slice; waves later need an alive cap (have it) and a spatial hash.
func _separate_enemies() -> void:
	var count := enemies.size()
	for i in count:
		for j in range(i + 1, count):
			var a := enemies[i]
			var b := enemies[j]
			var delta := b.position - a.position
			delta.y = 0.0
			var d := delta.length()
			var min_d := a.radius + b.radius
			if d < min_d:
				var push: Vector3
				if d > 0.0001:
					push = delta / d * (min_d - d) * 0.5
				else:
					# Exactly overlapping: deterministic nudge by index.
					push = Vector3(cos(i + j), 0.0, sin(i + j)) * min_d * 0.5
				a.position -= push
				b.position += push

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
