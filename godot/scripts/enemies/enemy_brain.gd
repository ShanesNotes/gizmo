class_name EnemyBrain
extends RefCounted

const ATTACK_READY := "ready"
const ATTACK_WINDUP := "windup"
const ATTACK_RECOVERY := "recovery"

## Movement personalities (playtest 2: dynamic AI — no enemy ever stands
## still in aggro). Styles are data-driven from EnemyArchetypes stats.
const STYLE_SKIRMISHER := "skirmisher"  # chaff: strafe-orbit + darting lunges
const STYLE_JUGGERNAUT := "juggernaut"  # bruiser: shoulders forward, drifting pauses
const STYLE_STALKER := "stalker"        # elite: circles at range, cuts in

const MOVE_APPROACH := "approach"
const MOVE_ORBIT := "orbit"
const MOVE_LUNGE := "lunge"
const MOVE_ADVANCE := "advance"
const MOVE_PAUSE := "pause"
const MOVE_CIRCLE := "circle"
const MOVE_CUT_IN := "cut_in"

# Skirmisher: orbit inside engage range, then commit in a dart.
const SKIRMISHER_ENGAGE_RANGE := 3.4
const SKIRMISHER_ORBIT_RADIUS := 2.5
const SKIRMISHER_LUNGE_SCALE := 2.2
const SKIRMISHER_LUNGE_TIMEOUT := 1.4
# Juggernaut: straight pushes broken by short drifting hesitations.
const JUGGERNAUT_PAUSE_DRIFT := 0.3
# Stalker: wide ring, then a committed cut-in.
const STALKER_RING_RADIUS := 4.2
const STALKER_ENGAGE_RANGE := 5.7
const STALKER_CUT_IN_SCALE := 1.4
const STALKER_CUT_IN_TIMEOUT := 4.0

var move_speed: float = 0.0
var contact_radius: float = 1.0
var attack_release_radius: float = 1.25
var melee_damage: int = 1
var attack_windup: float = 0.35
var attack_recovery: float = 0.65
var movement_style: String = STYLE_SKIRMISHER

var _attack_state := ATTACK_READY
var _attack_timer := 0.0
var _stagger_timer := 0.0
var _move_state := MOVE_APPROACH
var _move_timer := 0.0
var _orbit_sign := 1.0
var _jitter := 0.0
var _rng := RandomNumberGenerator.new()

func configure(stats: Dictionary) -> void:
	move_speed = float(stats.get("move_speed", move_speed))
	contact_radius = float(stats.get("contact_radius", contact_radius))
	attack_release_radius = maxf(float(stats.get("attack_release_radius", contact_radius * 1.25)), contact_radius)
	melee_damage = int(stats.get("damage", melee_damage))
	attack_windup = float(stats.get("attack_windup", attack_windup))
	attack_recovery = float(stats.get("attack_recovery", attack_recovery))
	movement_style = String(stats.get("movement_style", movement_style))
	reset_attack()
	_stagger_timer = 0.0
	_move_state = MOVE_APPROACH
	_move_timer = 0.0
	_orbit_sign = 1.0
	_jitter = 0.0
	_rng.seed = 0

## Deterministic per-enemy variation: the spawner seeds each brain (e.g. from
## its spawn_id hash) so orbits and pauses desync across a pack yet replay
## exactly under the same seed.
func set_behavior_seed(seed_value: int) -> void:
	_rng.seed = seed_value

func move_state() -> String:
	return _move_state

func reset_attack() -> void:
	_attack_state = ATTACK_READY
	_attack_timer = 0.0

func stagger(duration: float) -> void:
	_stagger_timer = maxf(_stagger_timer, maxf(duration, 0.0))
	reset_attack()

func is_staggered() -> bool:
	return _stagger_timer > 0.0

func stagger_remaining() -> float:
	return _stagger_timer

func attack_state() -> String:
	return _attack_state

func attack_timer_remaining() -> float:
	return _attack_timer

func step(current_position: Vector3, target_position: Vector3, delta: float) -> Dictionary:
	var safe_delta: float = maxf(delta, 0.0)
	if _stagger_timer > 0.0:
		tick_stagger(safe_delta)
		var stagger_steering := chase_steering(current_position, target_position, 0.0, contact_radius, safe_delta)
		return {
			"velocity": Vector3.ZERO,
			"direction": stagger_steering["direction"],
			"distance": stagger_steering["distance"],
			"in_contact": stagger_steering["in_contact"],
			"attack_state": _attack_state,
			"damage_event": {},
		}
	var steering := chase_steering(current_position, target_position, move_speed, contact_radius, safe_delta)
	var damage_payload: Dictionary = {}
	var distance := float(steering["distance"])
	var in_contact := bool(steering["in_contact"])
	var attack_active := _attack_state != ATTACK_READY
	var velocity := Vector3.ZERO

	if in_contact or (attack_active and distance <= attack_release_radius):
		damage_payload = _tick_contact_attack(safe_delta, target_position)
	else:
		if attack_active:
			reset_attack()
		velocity = _style_velocity(steering, safe_delta)

	return {
		"velocity": velocity,
		"direction": steering["direction"],
		"distance": steering["distance"],
		"in_contact": steering["in_contact"],
		"attack_state": _attack_state,
		"damage_event": damage_payload,
	}

func tick_stagger(delta: float) -> void:
	if _stagger_timer <= 0.0:
		return
	_stagger_timer = maxf(0.0, _stagger_timer - maxf(delta, 0.0))

static func chase_steering(
	current_position: Vector3,
	target_position: Vector3,
	speed: float,
	stop_radius: float,
	delta: float = 0.0
) -> Dictionary:
	var offset := Vector3(
		target_position.x - current_position.x,
		0.0,
		target_position.z - current_position.z
	)
	var distance := offset.length()
	var radius := maxf(stop_radius, 0.0)
	var direction := Vector3.ZERO
	if distance > 0.000001:
		direction = offset / distance

	var in_contact := distance <= radius
	var velocity := Vector3.ZERO
	if not in_contact:
		var desired_speed := maxf(speed, 0.0)
		if delta > 0.0:
			desired_speed = minf(desired_speed, maxf(0.0, distance - radius) / delta)
		velocity = direction * desired_speed

	return {
		"velocity": velocity,
		"direction": direction,
		"distance": distance,
		"in_contact": in_contact,
	}

# --- movement personality ------------------------------------------------------

func _style_velocity(steering: Dictionary, delta: float) -> Vector3:
	var distance := float(steering["distance"])
	var to_target := Vector3(steering["direction"])
	if to_target.length_squared() <= 0.000001:
		return Vector3.ZERO
	_move_timer = maxf(0.0, _move_timer - delta)

	match movement_style:
		STYLE_JUGGERNAUT:
			return _juggernaut_velocity(steering, to_target)
		STYLE_STALKER:
			return _stalker_velocity(steering, to_target, distance, delta)
		_:
			return _skirmisher_velocity(steering, to_target, distance, delta)

func _skirmisher_velocity(steering: Dictionary, to_target: Vector3, distance: float, delta: float) -> Vector3:
	match _move_state:
		MOVE_LUNGE:
			if _move_timer <= 0.0:
				_enter_orbit()
			else:
				return _dart_velocity(to_target, SKIRMISHER_LUNGE_SCALE, distance, delta)
		MOVE_ORBIT:
			if _move_timer <= 0.0:
				_move_state = MOVE_LUNGE
				_move_timer = SKIRMISHER_LUNGE_TIMEOUT
				return _dart_velocity(to_target, SKIRMISHER_LUNGE_SCALE, distance, delta)
		_:
			if distance > SKIRMISHER_ENGAGE_RANGE:
				return Vector3(steering["velocity"])
			_enter_orbit()
	return _ring_velocity(to_target, distance, SKIRMISHER_ORBIT_RADIUS)

func _juggernaut_velocity(steering: Dictionary, to_target: Vector3) -> Vector3:
	if _move_state != MOVE_ADVANCE and _move_state != MOVE_PAUSE:
		_enter_advance()
	elif _move_timer <= 0.0:
		if _move_state == MOVE_ADVANCE:
			_enter_pause()
		else:
			_enter_advance()
	if _move_state == MOVE_PAUSE:
		# Hesitation reads as a pause but the body keeps drifting sideways —
		# the verdict's law: trash never stands there.
		return _tangent(to_target) * _orbit_sign * (move_speed * JUGGERNAUT_PAUSE_DRIFT)
	return Vector3(steering["velocity"])

func _stalker_velocity(steering: Dictionary, to_target: Vector3, distance: float, delta: float) -> Vector3:
	match _move_state:
		MOVE_CUT_IN:
			if _move_timer <= 0.0:
				_enter_circle()
			else:
				return _dart_velocity(to_target, STALKER_CUT_IN_SCALE, distance, delta)
		MOVE_CIRCLE:
			if _move_timer <= 0.0:
				_move_state = MOVE_CUT_IN
				_move_timer = STALKER_CUT_IN_TIMEOUT
				return _dart_velocity(to_target, STALKER_CUT_IN_SCALE, distance, delta)
		_:
			if distance > STALKER_ENGAGE_RANGE:
				return Vector3(steering["velocity"])
			_enter_circle()
	return _ring_velocity(to_target, distance, STALKER_RING_RADIUS)

## Tangential orbit with a radial spring toward the preferred ring, plus a
## per-phase jitter so the arc never reads as a compass-perfect circle.
func _ring_velocity(to_target: Vector3, distance: float, ring_radius: float) -> Vector3:
	var tangent := _tangent(to_target) * _orbit_sign
	var radial := to_target * clampf((distance - ring_radius) * 0.8, -1.0, 1.0)
	var blend := tangent + radial * 0.6
	if blend.length_squared() <= 0.000001:
		blend = tangent
	return blend.normalized().rotated(Vector3.UP, _jitter) * move_speed

## Committed dart toward the target, clamped so one tick never tunnels past
## the contact radius.
func _dart_velocity(to_target: Vector3, speed_scale: float, distance: float, delta: float) -> Vector3:
	var desired := move_speed * maxf(speed_scale, 0.0)
	if delta > 0.0:
		desired = minf(desired, maxf(0.0, distance - contact_radius) / delta)
	return to_target * desired

func _tangent(direction: Vector3) -> Vector3:
	return Vector3(-direction.z, 0.0, direction.x)

func _enter_orbit() -> void:
	_move_state = MOVE_ORBIT
	_move_timer = _rng.randf_range(0.8, 1.6)
	if _rng.randf() < 0.35:
		_orbit_sign = -_orbit_sign
	_jitter = _rng.randf_range(-0.25, 0.25)

func _enter_advance() -> void:
	_move_state = MOVE_ADVANCE
	_move_timer = _rng.randf_range(1.0, 1.8)

func _enter_pause() -> void:
	_move_state = MOVE_PAUSE
	_move_timer = _rng.randf_range(0.35, 0.6)
	if _rng.randf() < 0.5:
		_orbit_sign = -_orbit_sign

func _enter_circle() -> void:
	_move_state = MOVE_CIRCLE
	_move_timer = _rng.randf_range(1.6, 2.4)
	if _rng.randf() < 0.3:
		_orbit_sign = -_orbit_sign
	_jitter = _rng.randf_range(-0.15, 0.15)

func _tick_contact_attack(delta: float, target_position: Vector3) -> Dictionary:
	if _attack_state == ATTACK_READY:
		_attack_state = ATTACK_WINDUP
		_attack_timer = attack_windup

	if _attack_state == ATTACK_WINDUP:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_state = ATTACK_RECOVERY
			_attack_timer = attack_recovery
			return {
				"damage": melee_damage,
				"target_position": target_position,
				"contact_radius": contact_radius,
				"windup": attack_windup,
			}
	elif _attack_state == ATTACK_RECOVERY:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_state = ATTACK_READY
			_attack_timer = 0.0

	return {}
