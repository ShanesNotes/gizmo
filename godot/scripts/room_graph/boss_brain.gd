class_name BossBrain
extends RefCounted

signal add_wave_requested(requests: Array[Dictionary])
signal attack_windup_started(attack: Dictionary)
signal attack_committed(attack: Dictionary)

const ATTACK_AUDIT_SWEEP := "audit_sweep"
const ATTACK_COMPLIANCE_RING := "compliance_ring"
const ATTACK_OVERREACH_SLAM := "overreach_slam"
const ATTACK_DECOY_PING := "decoy_ping"

const PHASE_TWO_THRESHOLD := 0.75
const PHASE_THREE_THRESHOLD := 0.50
const PHASE_FOUR_THRESHOLD := 0.25
const PHASE_FOUR_COOLDOWN_MULTIPLIER := 0.8

const STATE_IDLE := "idle"
const STATE_WINDUP := "windup"
const STATE_RECOVERY := "recovery"

var max_hp: float = 2400.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_hp: float = max_hp
var _phase: int = 1
var _emitted_thresholds: Dictionary = {}
var _cooldowns: Dictionary = {}
var _last_attack_id: String = ""
var _state: String = STATE_IDLE
var _state_remaining: float = 0.0
var _current_attack: Dictionary = {}

func _init() -> void:
	_rng.randomize()

func configure(context: Dictionary = {}) -> void:
	var configured_rng: Variant = context.get("rng", null)
	if configured_rng is RandomNumberGenerator:
		_rng = configured_rng as RandomNumberGenerator
	max_hp = maxf(float(context.get("max_hp", max_hp)), 1.0)
	_current_hp = max_hp
	_phase = 1
	_emitted_thresholds.clear()
	_cooldowns.clear()
	_last_attack_id = ""
	_state = STATE_IDLE
	_state_remaining = 0.0
	_current_attack.clear()

func update_health(current_hp: float, p_max_hp: float = -1.0) -> void:
	if p_max_hp > 0.0:
		max_hp = maxf(p_max_hp, 1.0)
	var previous_phase := _phase
	_current_hp = clampf(current_hp, 0.0, max_hp)
	_phase = _phase_for_health(_current_hp)
	_emit_crossed_add_waves()
	if previous_phase != _phase and _phase == 4:
		_reapply_phase_tempo_to_active_cooldowns()

func current_phase() -> int:
	return _phase

func current_hp() -> float:
	return _current_hp

func unlocked_attack_ids() -> Array[String]:
	var ids: Array[String] = [ATTACK_AUDIT_SWEEP, ATTACK_COMPLIANCE_RING]
	if _phase >= 2:
		ids.append(ATTACK_OVERREACH_SLAM)
	if _phase >= 3:
		ids.append(ATTACK_DECOY_PING)
	return ids

func attack_definition(attack_id: String) -> Dictionary:
	var attack := _base_attack_definition(attack_id)
	if attack.is_empty():
		return {}
	if _phase >= 4:
		attack["cooldown_seconds"] = float(attack["cooldown_seconds"]) * PHASE_FOUR_COOLDOWN_MULTIPLIER
	return attack

func execution_state() -> String:
	return _state

func cooldown_remaining(attack_id: String) -> float:
	return float(_cooldowns.get(attack_id, 0.0))

func begin_next_attack() -> Dictionary:
	if _state != STATE_IDLE:
		return {}
	var attack := _pick_attack()
	if attack.is_empty():
		return {}
	_current_attack = attack.duplicate(true)
	_state = STATE_WINDUP
	_state_remaining = float(_current_attack.get("telegraph_seconds", 0.0))
	attack_windup_started.emit(_current_attack.duplicate(true))
	return _current_attack.duplicate(true)

func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var step := maxf(delta, 0.0)
	_advance_cooldowns(step)
	match _state:
		STATE_WINDUP:
			_state_remaining -= step
			if _state_remaining <= 0.00001:
				var committed_attack := _current_attack.duplicate(true)
				_mark_attack_committed(committed_attack)
				attack_committed.emit(committed_attack)
				events.append({"type": "attack_committed", "attack": committed_attack})
				_state = STATE_RECOVERY
				_state_remaining = float(committed_attack.get("recovery_seconds", 0.0))
		STATE_RECOVERY:
			_state_remaining -= step
			if _state_remaining <= 0.00001:
				_state = STATE_IDLE
				_state_remaining = 0.0
				_current_attack.clear()
		_:
			pass
	return events

func interrupt_current_attack() -> bool:
	if _state != STATE_WINDUP or _current_attack.is_empty():
		return false
	var interrupted_attack := _current_attack.duplicate(true)
	_state = STATE_RECOVERY
	_state_remaining = float(interrupted_attack.get("recovery_seconds", 0.0))
	_current_attack.clear()
	return true

func force_finish_current_attack() -> void:
	if _current_attack.is_empty():
		return
	_mark_attack_committed(_current_attack)
	_state = STATE_IDLE
	_state_remaining = 0.0
	_current_attack.clear()

func _phase_for_health(hp: float) -> int:
	var ratio := hp / maxf(max_hp, 1.0)
	if ratio <= PHASE_FOUR_THRESHOLD:
		return 4
	if ratio <= PHASE_THREE_THRESHOLD:
		return 3
	if ratio <= PHASE_TWO_THRESHOLD:
		return 2
	return 1

func _emit_crossed_add_waves() -> void:
	for threshold in [75, 50, 25]:
		if _emitted_thresholds.has(threshold):
			continue
		var hp_threshold := max_hp * (float(threshold) / 100.0)
		if _current_hp <= hp_threshold:
			_emitted_thresholds[threshold] = true
			add_wave_requested.emit(_add_wave_requests(threshold))

func _add_wave_requests(threshold: int) -> Array[Dictionary]:
	match threshold:
		75:
			return [_spawn_request(RoomDirector.ARCHETYPE_CHAFF, 2, "boss75")]
		50:
			return [
				_spawn_request(RoomDirector.ARCHETYPE_CHAFF, 1, "boss50"),
				_spawn_request(RoomDirector.ARCHETYPE_BRUISER, 1, "boss50"),
			]
		25:
			return [_spawn_request(RoomDirector.ARCHETYPE_CHAFF, 2, "boss25")]
		_:
			return []

func _spawn_request(archetype: String, count: int, prefix: String) -> Dictionary:
	var spawn_ids: Array[String] = []
	for index in range(maxi(count, 0)):
		spawn_ids.append("%s:%s:%d" % [prefix, archetype, index])
	return {
		"archetype": archetype,
		"count": count,
		"spawn_ids": spawn_ids,
	}

func _base_attack_definition(attack_id: String) -> Dictionary:
	match attack_id:
		ATTACK_AUDIT_SWEEP:
			return {
				"id": ATTACK_AUDIT_SWEEP,
				"display_name": "Audit Sweep",
				"shape": "line",
				"telegraph_seconds": 0.9,
				"recovery_seconds": 0.55,
				"cooldown_seconds": 1.35,
				"damage": 2,
				"weight": 1.05,
				"line_length": 8.0,
				"line_width": 0.85,
			}
		ATTACK_COMPLIANCE_RING:
			return {
				"id": ATTACK_COMPLIANCE_RING,
				"display_name": "Compliance Ring",
				"shape": "disc",
				"telegraph_seconds": 0.8,
				"recovery_seconds": 0.45,
				"cooldown_seconds": 1.2,
				"damage": 1,
				"weight": 1.0,
				"radius": 3.0,
			}
		ATTACK_OVERREACH_SLAM:
			return {
				"id": ATTACK_OVERREACH_SLAM,
				"display_name": "Overreach Slam",
				"shape": "disc",
				"telegraph_seconds": 1.2,
				"recovery_seconds": 0.65,
				"cooldown_seconds": 1.6,
				"damage": 2,
				"weight": 0.85,
				"radius": 2.5,
			}
		ATTACK_DECOY_PING:
			return {
				"id": ATTACK_DECOY_PING,
				"display_name": "Decoy Ping",
				"shape": "decoy_discs",
				"telegraph_seconds": 1.4,
				"recovery_seconds": 0.75,
				"cooldown_seconds": 2.2,
				"damage": 2,
				"weight": 0.65,
				"radius": 2.0,
				"decoy_count": 3,
				"real_index": 1,
			}
		_:
			return {}

func _pick_attack() -> Dictionary:
	var unlocked := unlocked_attack_ids()
	var candidates: Array[Dictionary] = []
	var total_weight := 0.0
	for attack_id in unlocked:
		if cooldown_remaining(attack_id) > 0.00001:
			continue
		if attack_id == _last_attack_id and unlocked.size() > 1:
			continue
		var attack := attack_definition(attack_id)
		if attack.is_empty():
			continue
		candidates.append(attack)
		total_weight += maxf(float(attack.get("weight", 1.0)), 0.001)
	if candidates.is_empty():
		return {}
	var roll := _rng.randf() * total_weight
	var cursor := 0.0
	for attack in candidates:
		cursor += maxf(float(attack.get("weight", 1.0)), 0.001)
		if roll <= cursor:
			return attack.duplicate(true)
	return candidates[candidates.size() - 1].duplicate(true)

func _mark_attack_committed(attack: Dictionary) -> void:
	var attack_id := String(attack.get("id", ""))
	if attack_id == "":
		return
	_last_attack_id = attack_id
	_cooldowns[attack_id] = float(attack.get("cooldown_seconds", 0.0))

func _advance_cooldowns(delta: float) -> void:
	if delta <= 0.0:
		return
	var keys := _cooldowns.keys()
	for key in keys:
		var attack_id := String(key)
		var next := maxf(0.0, float(_cooldowns.get(attack_id, 0.0)) - delta)
		if next <= 0.00001:
			_cooldowns.erase(attack_id)
		else:
			_cooldowns[attack_id] = next

func _reapply_phase_tempo_to_active_cooldowns() -> void:
	for key in _cooldowns.keys():
		var attack_id := String(key)
		_cooldowns[attack_id] = float(_cooldowns[attack_id]) * PHASE_FOUR_COOLDOWN_MULTIPLIER
