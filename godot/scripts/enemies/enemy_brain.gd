class_name EnemyBrain
extends RefCounted

const ATTACK_READY := "ready"
const ATTACK_WINDUP := "windup"
const ATTACK_RECOVERY := "recovery"

var move_speed: float = 0.0
var contact_radius: float = 1.0
var melee_damage: int = 1
var attack_windup: float = 0.35
var attack_recovery: float = 0.65

var _attack_state := ATTACK_READY
var _attack_timer := 0.0

func configure(stats: Dictionary) -> void:
	move_speed = float(stats.get("move_speed", move_speed))
	contact_radius = float(stats.get("contact_radius", contact_radius))
	melee_damage = int(stats.get("damage", melee_damage))
	attack_windup = float(stats.get("attack_windup", attack_windup))
	attack_recovery = float(stats.get("attack_recovery", attack_recovery))
	reset_attack()

func reset_attack() -> void:
	_attack_state = ATTACK_READY
	_attack_timer = 0.0

func attack_state() -> String:
	return _attack_state

func attack_timer_remaining() -> float:
	return _attack_timer

func step(current_position: Vector3, target_position: Vector3, delta: float) -> Dictionary:
	var safe_delta: float = maxf(delta, 0.0)
	var steering := chase_steering(current_position, target_position, move_speed, contact_radius, safe_delta)
	var damage_payload: Dictionary = {}

	if bool(steering["in_contact"]):
		damage_payload = _tick_contact_attack(safe_delta, target_position)
	else:
		reset_attack()

	return {
		"velocity": steering["velocity"],
		"direction": steering["direction"],
		"distance": steering["distance"],
		"in_contact": steering["in_contact"],
		"attack_state": _attack_state,
		"damage_event": damage_payload,
	}

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
