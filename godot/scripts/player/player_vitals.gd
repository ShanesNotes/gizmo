class_name PlayerVitals
extends Node

signal vitals_changed(hp: int, max_hp: int, guard: int, max_guard: int)
signal guard_changed(guard: int, max_guard: int)
signal spark_surge_changed(charge: float, charge_max: float)
signal player_died()

@export_range(1, 99) var max_hp: int = 3
@export_range(0, 99) var max_guard: int = 10
## ADR 0007 staged model: guard recharges one pip at a time after a damage
## delay; true HP does not regenerate in this component.
@export_range(0.0, 30.0, 0.1) var guard_recharge_delay: float = 2.0
@export_range(0.0, 30.0, 0.1) var guard_recharge_rate: float = 1.0
@export_range(0.0, 5.0, 0.05) var damage_lockout: float = 1.8
@export_group("Spark Surge")
@export_range(1.0, 999.0, 1.0) var spark_surge_charge_max: float = 100.0
@export_range(0.0, 100.0, 0.1) var spark_damage_dealt_charge_rate: float = 5.0
@export_range(0.0, 100.0, 0.1) var spark_guard_damage_taken_charge_rate: float = 20.0

var hp: int = max_hp
var guard: int = max_guard
var spark_surge_charge: float = 0.0
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
	spark_surge_charge = 0.0
	_dead = false
	_guard_recharge_elapsed = guard_recharge_delay
	_guard_recharge_progress = 0.0
	_damage_lockout_remaining = 0.0
	_emit_vitals_changed()
	_emit_spark_surge_changed()

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
		if absorbed > 0:
			record_guard_damage_taken(absorbed)
			_notify_audio_event(&"guard_hit")

	if incoming > 0:
		hp_damage = mini(hp, incoming)
		hp -= hp_damage

	if absorbed > 0 or hp_damage > 0:
		_damage_lockout_remaining = maxf(damage_lockout, 0.0)
		_reset_guard_recharge_timer()
	_emit_vitals_changed()
	if hp <= 0 and not _dead:
		_dead = true
		empty_spark_surge_charge()
		player_died.emit()
	return _damage_result(absorbed, hp_damage)

func record_damage_dealt(amount: float) -> void:
	_add_spark_surge_charge(maxf(amount, 0.0) * spark_damage_dealt_charge_rate)

func record_guard_damage_taken(amount: float) -> void:
	_add_spark_surge_charge(maxf(amount, 0.0) * spark_guard_damage_taken_charge_rate)

func set_spark_surge_charge(amount: float) -> void:
	var next := clampf(amount, 0.0, maxf(spark_surge_charge_max, 0.0))
	if is_equal_approx(next, spark_surge_charge):
		return
	spark_surge_charge = next
	_emit_spark_surge_changed()

func empty_spark_surge_charge() -> void:
	set_spark_surge_charge(0.0)

func can_spark_surge() -> bool:
	return not _dead and spark_surge_charge_max > 0.0 and spark_surge_charge + 0.0001 >= spark_surge_charge_max

func flare_spark_surge_charge() -> bool:
	if not can_spark_surge():
		return false
	empty_spark_surge_charge()
	return true

## Sanctuary-style full guard restore (ADR 0007). Clamps, resets recharge
## bookkeeping, and emits — the one sanctioned external refill entry point.
func refill_guard() -> void:
	guard = maxi(max_guard, 0)
	_guard_recharge_elapsed = guard_recharge_delay
	_guard_recharge_progress = 0.0
	_emit_vitals_changed()

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
		"spark_surge_charge": spark_surge_charge,
		"dead": _dead,
	}

func _emit_vitals_changed() -> void:
	vitals_changed.emit(hp, max_hp, guard, max_guard)
	guard_changed.emit(guard, max_guard)

func _emit_spark_surge_changed() -> void:
	spark_surge_changed.emit(spark_surge_charge, spark_surge_charge_max)

func _add_spark_surge_charge(amount: float) -> void:
	if amount <= 0.0 or _dead:
		return
	set_spark_surge_charge(spark_surge_charge + amount)

func _reset_guard_recharge_timer() -> void:
	_guard_recharge_elapsed = 0.0
	_guard_recharge_progress = 0.0

func _tick_damage_lockout(delta: float) -> void:
	_damage_lockout_remaining = maxf(0.0, _damage_lockout_remaining - delta)
	if _damage_lockout_remaining <= 0.00001:
		_damage_lockout_remaining = 0.0

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
