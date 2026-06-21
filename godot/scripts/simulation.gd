class_name Simulation
extends RefCounted

## Headless game logic, ported from game-src-phaser/src/game/simulation.ts.
## Slices: Sparks & leveling (0006); run clock & player health (0007);
##         enemies — spawn/chase/separate/contact (0008); auto-fire combat,
##         enemy death, Spark drops & collection + per-tick events (0009 — closes
##         the loop to 0006); director-driven enemy pressure that ramps with a
##         pressure curve (0010).
## Anchors: design intent -> reference/game-balance-reference.md (§2, §3, §5, §6);
##          fiction       -> design-handoff/NARRATIVE.md §4;
##          mechanics     -> game-src-phaser/src/game/simulation.ts
## ADR 0001: player HP is the health bar — NOT the Spark of Humanity meter.
## ADR 0002: Simulation owns the rules (incl. enemies/combat); the scene renders.
##           Values are in Godot metres, not Phaser pixels.

# Run phases (simulation.ts:1 RunPhase; "levelup" arrives with upgrades later).
const PHASE_PLAYING := "playing"
const PHASE_COMPLETE := "complete"
const PHASE_GAMEOVER := "gameover"

const RUN_DURATION := 240.0   # simulation.ts:202
const MAX_DT := 0.05          # safeDt clamp (simulation.ts:463)
const HIT_INVULN := 1.58      # i-frames after a hit (simulation.ts:724)
const CONTACT_GRACE := 7.0    # no contact damage before this (simulation.ts:722)
const PLAYER_CONTACT_RADIUS := 0.4  # the player's own contact reach (metres)

# Enemies — in Godot metres (ADR 0002); relative balance from ENEMY_SPECS
# (simulation.ts:259). v1 uses the source enemy roles as rules-only variants;
# visuals can catch up later. Trash dies in ~1 shot (~0.7s at the deliberate 0.7s
# cadence — ABOVE §5.4's ≤0.5s "incidental AoE" band; v1 fires single-target, not
# AoE). Bruisers/wardens punctuate the time-pressure curve instead of flattening
# difficulty at the alive cap (balance §5.4, §6.2).
const ENEMY_NIBBLER := "nibbler"
const ENEMY_DASHER := "dasher"
const ENEMY_BRUTE := "brute"
const ENEMY_WARDEN := "warden"
const SPAWN_RING := 9.0       # spawn distance from the player (inside the 20x20 floor)
const NIBBLER_SPEED := 2.1    # m/s — slower than Gizmo (3.6) so he can kite
const NIBBLER_RADIUS := 1.0   # contact reach / separation radius
const NIBBLER_HP := 1.0
const NIBBLER_DAMAGE := 1     # faithful to ENEMY_SPECS.nibbler.damage
const NIBBLER_XP := 3         # Spark value on death (ENEMY_SPECS.nibbler.xp)
const NIBBLER_COST := 1.1     # director budget to spawn one (ENEMY_SPECS.nibbler.cost, simulation.ts:259)
const DASHER_UNLOCK := 30.0   # source unlockAt: 30s
const DASHER_SPEED := 3.1
const DASHER_RADIUS := 0.9
const DASHER_HP := 1.0        # trash: one Spark shot, but fast enough to punish sloppy kiting
const DASHER_DAMAGE := 1
const DASHER_XP := 4
const DASHER_COST := 1.45
const BRUTE_UNLOCK := 66.0    # source unlockAt: 66s
const BRUTE_SPEED := 1.65
const BRUTE_RADIUS := 1.55
const BRUTE_HP := 4.0         # bruiser: 4 shots × 0.7s ≈ 2.8s target TTK (balance §5.4, 1–3s band)
const BRUTE_DAMAGE := 1
const BRUTE_XP := 11
const BRUTE_COST := 3.4
const WARDEN_UNLOCK := 98.0   # source unlockAt: 98s
const WARDEN_SPEED := 2.2
const WARDEN_RADIUS := 1.3
const WARDEN_HP := 3.0        # short priority target, not an elite/boss yet
const WARDEN_DAMAGE := 1
const WARDEN_XP := 8
const WARDEN_COST := 2.35
const MIN_ENEMY_COST := NIBBLER_COST
const CONTACT_KNOCKBACK := 1.35 # metres; ports the source bump recoil so one hit is not a death spiral

# Pressure director (0010) — time-ramped enemy spawning; "the clock is the boss"
# (balance §5.2). Faithful core of updateDirector + heatCurve (simulation.ts:666-689,
# 1727-1730): a pressure curve off elapsed fills a spawn budget that's spent on enemies.
const PRESSURE_EASE := 2.15   # source heatCurve easing exponent (simulation.ts:1729)
const PRESSURE_MAX := 1.0     # time-only pressure max; source heat reaches 1.42 later with level/kill bonuses
const BUDGET_BASE := 0.8         # budget/s at pressure 0 — lowered to match the slower clear rate (§5.3)
const BUDGET_PRESSURE_GAIN := 5.5 # weight on pressure^1.52 — lowered with the slower-pace re-tune (§5.3)
const BUDGET_PRESSURE_EXP := 1.52 # (simulation.ts:671)
const MAX_SPAWNS_PER_TICK := 14  # batch safety: a big budget can't stall one frame (simulation.ts:681)

# Combat & pickups (0009) — the auto-fire "spark" weapon and Spark collection.
const ATTACK_COOLDOWN := 0.7  # seconds between shots (slower, deliberate v1 pace; sets trash TTK ~0.7s — the single-target-cadence tradeoff vs §5.4's ≤0.5s AoE band)
const ATTACK_RANGE := 5.0     # metres the weapon reaches (shorter than 6: positioning matters, §2.3 range premium)
const ATTACK_DAMAGE := 1      # one-shots a nibbler (NIBBLER_HP 1.0)
const PICKUP_RADIUS := 2.4    # Spark collection radius (metres); v1 baseline avoids inaccessible XP (§6.2)
const ATTACK_COOLDOWN_MIN := 0.48
const ATTACK_LEVEL_COOLDOWN_MULT := 0.94
const ATTACK_LEVEL_TARGET_CAP := 3
const ATTACK_LEVEL_DAMAGE_STEP := 3

## One enemy as a lightweight data agent (ADR 0002). The scene mirrors these.
class Enemy extends RefCounted:
	var position := Vector3.ZERO
	var hp: float = 1.0
	var speed: float = 0.0
	var radius: float = 1.0
	var damage: int = 1
	var xp_value: int = 0
	var kind: String = ""

## A dropped Spark (the xp currency) as a data agent.
class Pickup extends RefCounted:
	var position := Vector3.ZERO
	var value: int = 0

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

# --- Enemies (0008) + pressure director (0010) ---
var enemies: Array[Enemy] = []
var max_enemies := 60         # alive-enemy cap (balance §6.1; simulation.ts MAX_ENEMIES 122)
var spawn_enabled := true     # director on; unit tests set false to place enemies by hand
var _spawn_budget := 0.0      # director credit; spend NIBBLER_COST per spawn (0010)
var _spawn_count := 0
var spawned_count := 0        # balance telemetry: total enemies created this run (§6.1, §11.1)
var spawned_by_kind := {}     # balance telemetry: enemy_spawned counts by kind (§11.1)

# --- Combat & pickups (0009) ---
var pickups: Array[Pickup] = []
var max_pickups := 90         # uncollected-Spark cap (simulation.ts:207 MAX_PICKUPS); drop oldest over cap
var attack_cooldown := ATTACK_COOLDOWN
var attack_range := ATTACK_RANGE
var attack_damage := ATTACK_DAMAGE
var pickup_radius := PICKUP_RADIUS
var _attack_timer := 0.0
var kills := 0                # balance telemetry: enemy_killed count (§11.1)

# --- Per-tick events (0009) — transient HUD/VFX feedback hooks. A minimal analogue
# of the GameEvent[] that simulation.ts builds fresh and returns each frame
# (simulation.ts:168-198 type, :462 new, :496 return): same lifecycle and the same
# five event names, but each carries only the fields our current systems produce.
# Richer GameEvent fields (attack kind, crit, color, upgrade choices, full object
# refs) land with those systems — adding them now would invent undesigned detail.
# Replaced with a fresh array each tick() (not cleared in place), so a consumer that
# stores the reference keeps that frame's snapshot. 0009 produces these; 0011 HUD and
# a later VFX lesson consume them — 0010 pressure director does NOT yet.
var last_events: Array[Dictionary] = []

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

# ---- Run clock, health, enemies & combat ----

## Advance the run by dt seconds, given where Gizmo is.
## Mirrors updateGameState (simulation.ts:459-494): starts a fresh events array,
## then (unless not playing) clamps dt; enemies update, the weapon fires, Sparks
## are collected; the run COMPLETES (a win) when the timer runs out.
func tick(dt: float, gizmo_position := Vector3.ZERO) -> void:
	last_events = []   # fresh array each frame (simulation.ts:462) — snapshot-safe; before the phase guard so a non-playing tick reports none, not stale
	if phase != PHASE_PLAYING:
		return
	var safe_dt := clampf(dt, 0.0, MAX_DT)
	elapsed += safe_dt
	invulnerable = maxf(0.0, invulnerable - safe_dt)
	_update_enemies(safe_dt, gizmo_position)
	_update_weapon(safe_dt, gizmo_position)
	_update_pickups(gizmo_position)
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

## Time-driven pressure scalar, 0..1 — "the clock is the boss" (balance §5.2).
## Mirrors the time term of source heatCurve (simulation.ts:1727-1730): an eased
## ramp over the run. Deferred refinements let the source heat reach 1.42 via
## + level*0.014 + kills*0.00135 once those systems exist.
func pressure() -> float:
	var t := (clampf(elapsed / run_duration, 0.0, 1.0)) if run_duration > 0.0 else 1.0
	return clampf(1.0 - pow(1.0 - t, PRESSURE_EASE), 0.0, PRESSURE_MAX)

## Source-fidelity alias. The TypeScript implementation calls this concept heatCurve;
## the Godot lesson/game language calls it pressure.
func heat() -> float:
	return pressure()

## How full the HP bar is, 0..1 — for the HUD (mirrors xp_progress's shape).
## Design: HP is the raw defensive pool (balance §3.1).
func hp_progress() -> float:
	if max_hp <= 0:
		return 0.0
	return clampf(float(hp) / max_hp, 0.0, 1.0)

## Apply damage to the player's HP. Returns true only if the hit landed.
## Mirrors simulation.ts:722-738: a real hit lowers HP, grants i-frames, floors
## at 0, and reaching 0 ends the run (gameover/lose). Zero/negative is a no-op —
## it must NOT grant free i-frames (balance §3.4). Deferred: knockback, secondWind
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

## Spawn (director-ramped & capped), seek the player, separate, then deal contact
## damage. Open-floor seek + soft separation, not navigation (ADR 0002). Called from tick().
func _update_enemies(dt: float, gizmo_position: Vector3) -> void:
	# Pressure director: a spawn budget that fills faster as pressure rises, spent on
	# enemies up to the cap (simulation.ts updateDirector 666-689). Off in unit tests.
	# Deferred from TS:671 (no player-power system yet): the + sqrt(pScore)*0.54 term
	# and the (1 + latePressure*0.15 + powerPressure) multiplier on the rate.
	if spawn_enabled:
		var budget_rate := BUDGET_BASE + pow(pressure(), BUDGET_PRESSURE_EXP) * BUDGET_PRESSURE_GAIN
		_spawn_budget += budget_rate * dt
		var spawned := 0
		while _spawn_budget >= MIN_ENEMY_COST and enemies.size() < max_enemies and spawned < MAX_SPAWNS_PER_TICK:
			var kind := _choose_enemy_kind()
			var cost := _enemy_cost(kind)
			if _spawn_budget < cost:
				break # save budget for the selected pricier role, mirroring simulation.ts:684
			_spawn_enemy(kind, gizmo_position)
			_spawn_budget -= cost
			spawned += 1
	for e in enemies:
		var to_player := gizmo_position - e.position
		to_player.y = 0.0
		var dist := to_player.length()
		if dist > 0.0001:
			e.position += to_player / dist * e.speed * dt
	_separate_enemies()
	if elapsed > CONTACT_GRACE:
		for e in enemies:
			var to_player := gizmo_position - e.position
			to_player.y = 0.0
			var dist := to_player.length()
			if dist <= e.radius + PLAYER_CONTACT_RADIUS and take_damage(e.damage):
				var away_from_player := (-to_player / dist) if dist > 0.0001 else Vector3.RIGHT
				e.position += away_from_player * CONTACT_KNOCKBACK

## Auto-fire: on a cooldown, the spark weapon hits the nearest live enemy bodies in
## range. Leveling gives the prototype Spark Chain just enough automatic scaling
## to test the balance curve before draft-upgrade choices exist (source has upgrade
## ranks; v1 has XP/levels but not the choice UI yet). Future Core Matrix lessons
## can replace these helpers without changing the combat seam.
## Mirrors updateWeapons + dealDamage (simulation.ts:817-836, 1169-1185): emits an
## attack + hit event, and a kill removes the enemy, drops a Spark (xp pickup)
## worth its xp_value, and emits a defeat event. Deferred: crits, cache/heart drops,
## projectile/aura VFX.
func _update_weapon(dt: float, gizmo_position: Vector3) -> void:
	_attack_timer += dt
	var cooldown := current_attack_cooldown()
	if _attack_timer < cooldown:
		return
	_attack_timer -= cooldown
	var candidates: Array[Enemy] = []
	for e in enemies:
		if e.hp <= 0.0:
			continue  # a corpse is not a target (simulation.ts:1714 filters hp > 0)
		var d := gizmo_position.distance_to(e.position)
		# in range when the enemy's BODY is reachable (simulation.ts:1716: dist <= range + radius)
		if d <= attack_range + e.radius:
			candidates.append(e)
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return gizmo_position.distance_to(a.position) < gizmo_position.distance_to(b.position)
	)
	var shots := mini(current_attack_target_count(), candidates.size())
	for i in shots:
		_hit_enemy(candidates[i], gizmo_position)

func current_attack_cooldown() -> float:
	var level_bonus := maxi(0, level - 1)
	var scaled := attack_cooldown * pow(ATTACK_LEVEL_COOLDOWN_MULT, level_bonus)
	var min_cooldown := ATTACK_COOLDOWN_MIN if attack_cooldown >= ATTACK_COOLDOWN else 0.01
	return maxf(min_cooldown, scaled)

func current_attack_target_count() -> int:
	return clampi(1 + maxi(0, level - 1), 1, ATTACK_LEVEL_TARGET_CAP)

func current_attack_damage() -> int:
	return attack_damage + int(floor(float(maxi(0, level - 1)) / ATTACK_LEVEL_DAMAGE_STEP))

func _hit_enemy(target: Enemy, gizmo_position: Vector3) -> void:
	if target == null or target.hp <= 0.0:
		return
	var damage := current_attack_damage()
	last_events.append({"type": "attack", "from": gizmo_position, "to": target.position})
	target.hp -= damage
	last_events.append({"type": "hit", "position": target.position, "damage": damage})
	if target.hp <= 0.0 and enemies.has(target):
		enemies.erase(target)
		kills += 1
		var spark := Pickup.new()
		spark.position = target.position
		spark.value = target.xp_value
		pickups.append(spark)
		last_events.append({"type": "defeat", "position": spark.position, "xp": spark.value})

## Collect Sparks within reach -> bank xp (the gain at simulation.ts:1014, which can
## level Gizmo up; 0006), emitting a pickup event (949) and a levelup event (1038)
## when the threshold is crossed. Uncollected Sparks are capped: over the
## cap, the OLDEST are dropped (simulation.ts:945: .slice(-MAX_PICKUPS)).
func _update_pickups(gizmo_position: Vector3) -> void:
	var kept: Array[Pickup] = []
	for p in pickups:
		if gizmo_position.distance_to(p.position) <= pickup_radius:
			last_events.append({"type": "pickup", "position": p.position, "value": p.value})
			if add_xp(p.value):
				last_events.append({"type": "levelup", "level": level})
		else:
			kept.append(p)
	if kept.size() > max_pickups:
		kept = kept.slice(kept.size() - max_pickups)
	pickups = kept

## Push overlapping enemies apart on the XZ plane by half their overlap each.
## Deterministic (no RNG). O(n^2) — fine for a teaching slice; pressure needs a cap
## (have it) and a spatial hash.
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
					push = Vector3(cos(i + j), 0.0, sin(i + j)) * min_d * 0.5
				a.position -= push
				b.position += push

func _choose_enemy_kind() -> String:
	# Deterministic, director-driven mix: not discrete waves, just more demanding
	# roles becoming eligible as the clock advances (source unlockAt values).
	var cadence := _spawn_count + 1
	if elapsed >= WARDEN_UNLOCK and cadence % 7 == 0:
		return ENEMY_WARDEN
	if elapsed >= BRUTE_UNLOCK and cadence % 11 == 0:
		return ENEMY_BRUTE
	if elapsed >= DASHER_UNLOCK and cadence % 3 == 0:
		return ENEMY_DASHER
	return ENEMY_NIBBLER

func _enemy_cost(kind: String) -> float:
	match kind:
		ENEMY_DASHER:
			return DASHER_COST
		ENEMY_BRUTE:
			return BRUTE_COST
		ENEMY_WARDEN:
			return WARDEN_COST
		_:
			return NIBBLER_COST

## Spawn one nibbler on a ring around the player. Deterministic golden-angle.
func _spawn_nibbler(gizmo_position: Vector3) -> void:
	_spawn_enemy(ENEMY_NIBBLER, gizmo_position)

func _spawn_enemy(kind: String, gizmo_position: Vector3) -> void:
	var angle := _spawn_count * 2.39996323  # golden angle (radians)
	_spawn_count += 1
	var e := Enemy.new()
	e.kind = kind
	e.position = gizmo_position + Vector3(cos(angle), 0.0, sin(angle)) * SPAWN_RING
	match kind:
		ENEMY_DASHER:
			e.hp = DASHER_HP
			e.speed = DASHER_SPEED
			e.radius = DASHER_RADIUS
			e.damage = DASHER_DAMAGE
			e.xp_value = DASHER_XP
		ENEMY_BRUTE:
			e.hp = BRUTE_HP
			e.speed = BRUTE_SPEED
			e.radius = BRUTE_RADIUS
			e.damage = BRUTE_DAMAGE
			e.xp_value = BRUTE_XP
		ENEMY_WARDEN:
			e.hp = WARDEN_HP
			e.speed = WARDEN_SPEED
			e.radius = WARDEN_RADIUS
			e.damage = WARDEN_DAMAGE
			e.xp_value = WARDEN_XP
		_:
			e.kind = ENEMY_NIBBLER
			e.hp = NIBBLER_HP
			e.speed = NIBBLER_SPEED
			e.radius = NIBBLER_RADIUS
			e.damage = NIBBLER_DAMAGE
			e.xp_value = NIBBLER_XP
	enemies.append(e)
	spawned_count += 1
	spawned_by_kind[e.kind] = int(spawned_by_kind.get(e.kind, 0)) + 1
