class_name PlayerVitals
extends Node

signal vitals_changed(hp: int, max_hp: int, guard: int, max_guard: int)
signal guard_changed(guard: int, max_guard: int)
signal player_died()

@export_range(1, 99) var max_hp: int = 3
@export_range(0, 99) var max_guard: int = 10
## ADR 0007 staged model: guard recharges one pip at a time after a damage
## delay; true HP does not regenerate in this component.
@export_range(0.0, 30.0, 0.1) var guard_recharge_delay: float = 2.0
@export_range(0.0, 30.0, 0.1) var guard_recharge_rate: float = 1.0
@export_range(0.0, 5.0, 0.05) var damage_lockout: float = 1.8

var hp: int = max_hp
var guard: int = max_guard
var _dead := false
var _guard_recharge_elapsed := 0.0
var _guard_recharge_progress := 0.0
var _damage_lockout_remaining := 0.0

func _ready() -> void:
	reset()

func _process(delta: float) -> void:
	tick_guard_recharge(delta)

func reset() -> void:
	hp = maxi(max_hp, 1)
	guard = maxi(max_guard, 0)
	_dead = false
	_guard_recharge_elapsed = guard_recharge_delay
	_guard_recharge_progress = 0.0
	_damage_lockout_remaining = 0.0
	_emit_vitals_changed()

func apply_damage(amount: int) -> Dictionary:
	var incoming := maxi(amount, 0)
	var absorbed := 0
	var hp_damage := 0
	if incoming <= 0 or _dead:
		return _damage_result(absorbed, hp_damage)
	if _damage_lockout_remaining > 0.0:
		return _damage_result(absorbed, hp_damage)

	if guard > 0:
		absorbed = mini(guard, incoming)
		guard -= absorbed
		incoming -= absorbed

	if incoming > 0:
		hp_damage = mini(hp, incoming)
		hp -= hp_damage

	if absorbed > 0 or hp_damage > 0:
		_damage_lockout_remaining = maxf(damage_lockout, 0.0)
		_reset_guard_recharge_timer()
	_emit_vitals_changed()
	if hp <= 0 and not _dead:
		_dead = true
		player_died.emit()
	return _damage_result(absorbed, hp_damage)

func tick_guard_recharge(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return
	_tick_damage_lockout(step)
	if _dead:
		return
	if max_guard <= 0 or guard >= max_guard or guard_recharge_rate <= 0.0:
		_guard_recharge_progress = 0.0
		return

	var previous_elapsed := _guard_recharge_elapsed
	_guard_recharge_elapsed += step
	if _guard_recharge_elapsed < guard_recharge_delay:
		return

	var recharge_time := step
	if previous_elapsed < guard_recharge_delay:
		recharge_time = _guard_recharge_elapsed - guard_recharge_delay
	if recharge_time <= 0.0:
		return

	_guard_recharge_progress += recharge_time * guard_recharge_rate
	var recovered := mini(max_guard - guard, int(floor(_guard_recharge_progress + 0.00001)))
	if recovered <= 0:
		return

	guard += recovered
	_guard_recharge_progress -= float(recovered)
	if guard >= max_guard:
		_guard_recharge_progress = 0.0
	_emit_vitals_changed()

func is_dead() -> bool:
	return _dead

func _damage_result(absorbed: int, hp_damage: int) -> Dictionary:
	return {
		"absorbed": absorbed,
		"hp_damage": hp_damage,
		"hp": hp,
		"guard": guard,
		"dead": _dead,
	}

func _emit_vitals_changed() -> void:
	vitals_changed.emit(hp, max_hp, guard, max_guard)
	guard_changed.emit(guard, max_guard)

func _reset_guard_recharge_timer() -> void:
	_guard_recharge_elapsed = 0.0
	_guard_recharge_progress = 0.0

func _tick_damage_lockout(delta: float) -> void:
	_damage_lockout_remaining = maxf(0.0, _damage_lockout_remaining - delta)
	if _damage_lockout_remaining <= 0.00001:
		_damage_lockout_remaining = 0.0
