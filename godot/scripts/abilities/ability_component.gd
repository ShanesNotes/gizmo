class_name AbilityComponent
extends Node

const SurgeAbilityScript := preload("res://scripts/abilities/surge_ability.gd")
const BUFFER_WINDOW: float = 0.12

## CharacterBody3D-attachable runtime owner for the Hades-pivot player kit.
## It grants abilities, spends resources, starts cooldowns, tracks cast ammo,
## tracks attack combos, and exposes dash i-frames without coupling to
## GameController or room code.

signal ability_activated(ability: Ability)
signal ability_failed(ability: Ability, reason: String)
signal cooldown_started(ability: Ability, duration: float)
signal cooldown_finished(ability_id: StringName)
signal resource_changed(resource_key: StringName, amount: float)
signal invulnerability_changed(active: bool)
signal combo_step_changed(step: int)
signal dash_started(direction: Vector3, speed: float, duration: float)
signal attack_started(step: int, damage: float)
signal special_started(potency: float)
signal cast_started(potency: float)
signal surge_started(damage: float, radius: float, stagger_seconds: float)
signal cast_ammo_changed(current_ammo: int, max_ammo: int, lodged_ammo: int)
signal cast_ammo_reclaimed(amount: int, current_ammo: int, lodged_ammo: int)

@export var auto_grant_default_kit: bool = true
@export var starting_abilities: Array[Ability] = []
@export var ability_modifiers: Array[AbilityModifier] = []
@export var state_machine: PlayerActionStateMachine
@export var player_vitals: PlayerVitals
@export var default_resource_key: StringName = &"spark_charge"
@export_range(0.0, 999.0) var starting_resource: float = 100.0

var _granted: Dictionary = {}
var _cooldowns: Dictionary = {}
var _resources: Dictionary = {}
var _iframe_remaining: float = 0.0
var _combo_step: int = 0
var _combo_window_remaining: float = 0.0
var _cast_ammo_current: int = -1
var _cast_ammo_lodged: int = 0
var _cast_max_ammo_seen: int = -1
var _dash_charges: int = -1
var _dash_bonus_charges: int = 0
var _buffered_attack_remaining: float = 0.0

func _ready() -> void:
	_ensure_state_machine()
	if not _resources.has(default_resource_key):
		_resources[default_resource_key] = starting_resource
	for ability in starting_abilities:
		grant(ability)
	if auto_grant_default_kit and _granted.is_empty():
		grant_default_kit()

func _process(delta: float) -> void:
	tick(delta)

func grant_default_kit() -> void:
	grant(DashAbility.new())
	grant(AttackAbility.new())
	grant(SpecialAbility.new())
	grant(CastAbility.new())
	grant(SurgeAbilityScript.new())

func grant(ability: Ability) -> void:
	if ability == null:
		push_warning("AbilityComponent cannot grant a null ability.")
		return
	if ability.ability_id == &"":
		push_warning("AbilityComponent cannot grant an ability with an empty ability_id.")
		return
	_granted[ability.ability_id] = ability

func has_ability(ability_id: StringName) -> bool:
	return _granted.has(ability_id)

func get_ability(ability_id: StringName) -> Ability:
	return _granted.get(ability_id) as Ability

func try_activate(ability_id: StringName, direction: Vector3 = Vector3.ZERO) -> bool:
	var base_ability := get_ability(ability_id)
	if base_ability == null:
		ability_failed.emit(null, "not_granted")
		return false

	var caster := get_parent()
	var ability := _runtime_ability(base_ability, caster)
	if _uses_cooldown(ability) and _cooldowns.has(ability.ability_id) \
			and not _cooldown_bypassed_by_dash_charge(ability):
		if _attack_failure_can_buffer(ability):
			_buffer_attack()
		ability_failed.emit(ability, "on_cooldown")
		return false
	if not _has_resource_for(ability):
		ability_failed.emit(ability, "insufficient_resource")
		return false
	if not _has_cast_ammo_for(ability):
		ability_failed.emit(ability, "no_cast_ammo")
		return false
	if not _has_spark_surge_charge_for(ability):
		ability_failed.emit(ability, "spark_not_ready")
		return false

	var machine := _ensure_state_machine()
	if not machine.can_start_ability(ability):
		if _attack_failure_can_buffer(ability):
			_buffer_attack()
		ability_failed.emit(ability, "busy")
		return false
	if not ability.can_activate(caster):
		ability_failed.emit(ability, "conditions_unmet")
		return false

	if not _flare_spark_surge_charge_for(ability):
		ability_failed.emit(ability, "spark_not_ready")
		return false
	if ability.kind == Ability.AbilityKind.DASH or ability.ability_id == &"attack":
		_clear_attack_buffer()
	_spend_resource_for(ability)
	_consume_cast_ammo_for(ability)
	_start_ability_effect(ability, direction)
	_start_cooldown(ability)
	ability_activated.emit(ability)
	return true

func enter_hitstun(duration: float) -> void:
	_ensure_state_machine().enter_hitstun(duration)

func bind_player_vitals(vitals: PlayerVitals) -> void:
	player_vitals = vitals

func tick(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_tick_state(safe_delta)
	_tick_cooldowns(safe_delta)
	_tick_iframes(safe_delta)
	_tick_combo(safe_delta)
	_tick_attack_buffer(safe_delta)

func set_resource(resource_key: StringName, amount: float) -> void:
	_resources[resource_key] = maxf(0.0, amount)
	resource_changed.emit(resource_key, _resources[resource_key])

func get_resource(resource_key: StringName) -> float:
	return float(_resources.get(resource_key, 0.0))

func cooldown_remaining(ability_id: StringName) -> float:
	return float(_cooldowns.get(ability_id, 0.0))

func is_on_cooldown(ability_id: StringName) -> bool:
	# The dash is "on cooldown" only when no charge is available: with meta
	# bonus charges a dash can fire while its recharge timer is still running.
	if ability_id == &"dash" and _cooldowns.has(&"dash"):
		return dash_charges() <= 0
	return _cooldowns.has(ability_id)

func dash_charges() -> int:
	_ensure_dash_charges()
	return _dash_charges

## Meta-progression seam (stat_grades["dash_charges"] → extra_dash_charges):
## grants additional dash charges on top of the DashAbility's own charge count.
func set_bonus_dash_charges(amount: int) -> void:
	_ensure_dash_charges()
	var previous_max := _dash_max_charges()
	_dash_bonus_charges = maxi(0, amount)
	var gained := _dash_max_charges() - previous_max
	_dash_charges = clampi(_dash_charges + maxi(gained, 0), 0, _dash_max_charges())

func is_invulnerable() -> bool:
	return _iframe_remaining > 0.0

func cast_ammo() -> int:
	_ensure_cast_ammo_state(get_ability(&"cast") as CastAbility)
	return _cast_ammo_current

func cast_max_ammo() -> int:
	var cast_ability := get_ability(&"cast") as CastAbility
	_ensure_cast_ammo_state(cast_ability)
	return _cast_max_ammo_for(cast_ability)

func cast_lodged_ammo() -> int:
	_ensure_cast_ammo_state(get_ability(&"cast") as CastAbility)
	return _cast_ammo_lodged

func reclaim_cast_ammo(amount: int = 1) -> int:
	_ensure_cast_ammo_state(get_ability(&"cast") as CastAbility)
	if amount <= 0 or _cast_ammo_lodged <= 0:
		return 0
	var open_capacity := maxi(0, cast_max_ammo() - _cast_ammo_current)
	var reclaimed := mini(amount, mini(_cast_ammo_lodged, open_capacity))
	if reclaimed <= 0:
		return 0
	_cast_ammo_lodged -= reclaimed
	_cast_ammo_current += reclaimed
	cast_ammo_reclaimed.emit(reclaimed, _cast_ammo_current, _cast_ammo_lodged)
	_emit_cast_ammo_changed()
	return reclaimed

func combo_step() -> int:
	return _combo_step

func current_action_state() -> PlayerActionStateMachine.ActionState:
	return _ensure_state_machine().current_state

func has_buffered_attack() -> bool:
	return _buffered_attack_remaining > 0.0

func _runtime_ability(ability: Ability, caster: Node) -> Ability:
	var runtime := ability.runtime_copy()
	for modifier in ability_modifiers:
		if modifier != null:
			modifier.modify_ability(runtime, caster)
	return runtime

func _start_ability_effect(ability: Ability, direction: Vector3) -> void:
	match ability.kind:
		Ability.AbilityKind.DASH:
			_start_dash(ability as DashAbility, direction)
		Ability.AbilityKind.ATTACK:
			_start_attack(ability as AttackAbility)
		Ability.AbilityKind.SPECIAL:
			_ensure_state_machine().start_ability(ability, ability.cast_time + ability.recovery_time)
			special_started.emit(ability.potency)
		Ability.AbilityKind.CAST:
			_ensure_state_machine().start_ability(ability, ability.cast_time + ability.recovery_time)
			cast_started.emit(ability.potency)
		Ability.AbilityKind.SURGE:
			_start_surge(ability)
		_:
			_ensure_state_machine().start_ability(ability, ability.cast_time + ability.recovery_time)

func _start_dash(ability: DashAbility, direction: Vector3) -> void:
	var duration := ability.dash_duration if ability != null else 0.0
	var iframe_duration := ability.iframe_duration if ability != null else 0.0
	var speed := ability.dash_speed if ability != null else 0.0
	_ensure_dash_charges()
	_dash_charges = maxi(0, _dash_charges - 1)
	_set_iframe_remaining(iframe_duration)
	_ensure_state_machine().start_ability(ability, duration)
	var dash_direction := direction
	if dash_direction.length_squared() > 0.001:
		dash_direction = dash_direction.normalized()
	dash_started.emit(dash_direction, speed, duration)

func _start_attack(ability: AttackAbility) -> void:
	var step := _next_combo_step(ability)
	var damage := ability.damage_for_step(step) if ability != null else 0.0
	var recovery := ability.recovery_for_step(step) if ability != null else 0.0
	_ensure_state_machine().start_ability(ability, recovery)
	attack_started.emit(step, damage)

func _start_surge(ability: Ability) -> void:
	_ensure_state_machine().start_ability(ability, ability.cast_time + ability.recovery_time)
	if ability == null:
		surge_started.emit(0.0, 0.0, 0.0)
		return
	surge_started.emit(float(ability.get("damage")), float(ability.get("radius")), float(ability.get("stagger_seconds")))

func _next_combo_step(ability: AttackAbility) -> int:
	var max_steps := maxi(ability.combo_steps if ability != null else 1, 1)
	if _combo_window_remaining > 0.0 and _combo_step > 0:
		_combo_step = (_combo_step % max_steps) + 1
	else:
		_combo_step = 1
	_combo_window_remaining = ability.combo_window if ability != null else 0.0
	combo_step_changed.emit(_combo_step)
	return _combo_step

func _start_cooldown(ability: Ability) -> void:
	if not _uses_cooldown(ability) or ability.cooldown <= 0.0:
		return
	# A charge-spent dash must not reset the running recharge timer.
	if ability.kind == Ability.AbilityKind.DASH and _cooldowns.has(ability.ability_id):
		return
	_cooldowns[ability.ability_id] = ability.cooldown
	cooldown_started.emit(ability, ability.cooldown)

func _uses_cooldown(ability: Ability) -> bool:
	return ability != null and ability.kind != Ability.AbilityKind.CAST

func _has_resource_for(ability: Ability) -> bool:
	if ability.cost <= 0.0:
		return true
	return get_resource(_resource_key_for(ability)) >= ability.cost

func _has_cast_ammo_for(ability: Ability) -> bool:
	if ability == null or ability.kind != Ability.AbilityKind.CAST:
		return true
	_ensure_cast_ammo_state(ability as CastAbility)
	return _cast_ammo_current > 0

func _has_spark_surge_charge_for(ability: Ability) -> bool:
	if ability == null or ability.kind != Ability.AbilityKind.SURGE:
		return true
	var vitals := _resolve_player_vitals()
	return vitals != null and vitals.can_spark_surge()

func _flare_spark_surge_charge_for(ability: Ability) -> bool:
	if ability == null or ability.kind != Ability.AbilityKind.SURGE:
		return true
	var vitals := _resolve_player_vitals()
	return vitals != null and vitals.flare_spark_surge_charge()

func _consume_cast_ammo_for(ability: Ability) -> void:
	if ability == null or ability.kind != Ability.AbilityKind.CAST:
		return
	_ensure_cast_ammo_state(ability as CastAbility)
	_cast_ammo_current = maxi(0, _cast_ammo_current - 1)
	_cast_ammo_lodged += 1
	_emit_cast_ammo_changed()

func _spend_resource_for(ability: Ability) -> void:
	if ability.cost <= 0.0:
		return
	var key := _resource_key_for(ability)
	set_resource(key, get_resource(key) - ability.cost)

func _resource_key_for(ability: Ability) -> StringName:
	return ability.resource_key if ability.resource_key != &"" else default_resource_key

func _ensure_cast_ammo_state(cast_ability: CastAbility = null) -> void:
	var max_ammo := _cast_max_ammo_for(cast_ability)
	if _cast_ammo_current < 0:
		_cast_ammo_current = max_ammo
		_cast_ammo_lodged = 0
		_cast_max_ammo_seen = max_ammo
		return

	if max_ammo > _cast_max_ammo_seen:
		_cast_ammo_current += max_ammo - _cast_max_ammo_seen
	elif max_ammo < _cast_max_ammo_seen:
		var overflow := (_cast_ammo_current + _cast_ammo_lodged) - max_ammo
		if overflow > 0:
			var lodged_reduction := mini(_cast_ammo_lodged, overflow)
			_cast_ammo_lodged -= lodged_reduction
			overflow -= lodged_reduction
			_cast_ammo_current = maxi(0, _cast_ammo_current - overflow)
	_cast_max_ammo_seen = max_ammo

func _cast_max_ammo_for(cast_ability: CastAbility = null) -> int:
	var source := cast_ability
	if source == null:
		source = get_ability(&"cast") as CastAbility
	if source == null:
		return 0
	return maxi(0, source.max_ammo)

func _emit_cast_ammo_changed() -> void:
	cast_ammo_changed.emit(_cast_ammo_current, cast_max_ammo(), _cast_ammo_lodged)

func _tick_state(delta: float) -> void:
	if state_machine != null:
		state_machine.tick(delta)

func _tick_cooldowns(delta: float) -> void:
	var finished: Array[StringName] = []
	for ability_id in _cooldowns.keys():
		var remaining := float(_cooldowns[ability_id]) - delta
		if remaining <= 0.0:
			finished.append(ability_id)
		else:
			_cooldowns[ability_id] = remaining
	for ability_id in finished:
		_cooldowns.erase(ability_id)
		if ability_id == &"dash":
			_refill_dash_charge()
		cooldown_finished.emit(ability_id)

func _tick_iframes(delta: float) -> void:
	if _iframe_remaining <= 0.0:
		return
	_iframe_remaining = maxf(0.0, _iframe_remaining - delta)
	if _iframe_remaining <= 0.0:
		invulnerability_changed.emit(false)

func _tick_combo(delta: float) -> void:
	if _combo_step <= 0 or _combo_window_remaining <= 0.0:
		return
	_combo_window_remaining = maxf(0.0, _combo_window_remaining - delta)
	if _combo_window_remaining <= 0.0:
		_combo_step = 0
		combo_step_changed.emit(_combo_step)

func _tick_attack_buffer(delta: float) -> void:
	if not has_buffered_attack():
		return
	_buffered_attack_remaining = maxf(0.0, _buffered_attack_remaining - delta)
	if _buffered_attack_remaining <= 0.0:
		_clear_attack_buffer()
		return
	if _buffered_attack_can_fire():
		_clear_attack_buffer()
		try_activate(&"attack")
		return
	if not _attack_buffer_waiting_for_blocker():
		_clear_attack_buffer()

func _buffer_attack() -> void:
	_buffered_attack_remaining = BUFFER_WINDOW

func _clear_attack_buffer() -> void:
	_buffered_attack_remaining = 0.0

func _attack_failure_can_buffer(ability: Ability) -> bool:
	if ability == null or ability.ability_id != &"attack":
		return false
	if not _has_resource_for(ability):
		return false
	if not _has_cast_ammo_for(ability):
		return false
	if not _has_spark_surge_charge_for(ability):
		return false
	if not ability.can_activate(get_parent()):
		return false
	var machine := _ensure_state_machine()
	if machine.current_state == PlayerActionStateMachine.ActionState.ATTACK \
			or machine.current_state == PlayerActionStateMachine.ActionState.SPECIAL:
		return true
	return machine.current_state == PlayerActionStateMachine.ActionState.IDLE \
		and _uses_cooldown(ability) \
		and _cooldowns.has(ability.ability_id)

func _buffered_attack_can_fire() -> bool:
	var base_ability := get_ability(&"attack")
	if base_ability == null:
		return false
	var caster := get_parent()
	var ability := _runtime_ability(base_ability, caster)
	if _uses_cooldown(ability) and _cooldowns.has(ability.ability_id):
		return false
	if not _has_resource_for(ability):
		return false
	if not _has_cast_ammo_for(ability):
		return false
	if not _has_spark_surge_charge_for(ability):
		return false
	if not _ensure_state_machine().can_start_ability(ability):
		return false
	return ability.can_activate(caster)

func _attack_buffer_waiting_for_blocker() -> bool:
	var machine := _ensure_state_machine()
	if machine.current_state == PlayerActionStateMachine.ActionState.ATTACK \
			or machine.current_state == PlayerActionStateMachine.ActionState.SPECIAL:
		return true
	var base_ability := get_ability(&"attack")
	if base_ability == null:
		return false
	var ability := _runtime_ability(base_ability, get_parent())
	return _uses_cooldown(ability) and _cooldowns.has(ability.ability_id)

func _set_iframe_remaining(duration: float) -> void:
	var was_invulnerable := is_invulnerable()
	_iframe_remaining = maxf(_iframe_remaining, duration)
	if not was_invulnerable and is_invulnerable():
		invulnerability_changed.emit(true)

func _cooldown_bypassed_by_dash_charge(ability: Ability) -> bool:
	return ability != null and ability.kind == Ability.AbilityKind.DASH and dash_charges() > 0

func _dash_max_charges() -> int:
	var dash := get_ability(&"dash") as DashAbility
	var base := dash.charges if dash != null else 1
	return maxi(1, base) + _dash_bonus_charges

func _ensure_dash_charges() -> void:
	if _dash_charges < 0:
		_dash_charges = _dash_max_charges()

func _refill_dash_charge() -> void:
	_ensure_dash_charges()
	var max_charges := _dash_max_charges()
	if _dash_charges >= max_charges:
		return
	_dash_charges += 1
	if _dash_charges < max_charges:
		var dash := get_ability(&"dash")
		if dash != null and dash.cooldown > 0.0:
			_cooldowns[&"dash"] = dash.cooldown
			cooldown_started.emit(dash, dash.cooldown)

func _ensure_state_machine() -> PlayerActionStateMachine:
	if state_machine == null:
		state_machine = PlayerActionStateMachine.new()
		state_machine.name = "ActionStateMachine"
		add_child(state_machine)
	return state_machine

func _resolve_player_vitals() -> PlayerVitals:
	if player_vitals != null and is_instance_valid(player_vitals):
		return player_vitals
	var parent := get_parent()
	if parent == null:
		return null
	var sibling := parent.get_node_or_null("PlayerVitals")
	if sibling is PlayerVitals:
		player_vitals = sibling as PlayerVitals
	return player_vitals
