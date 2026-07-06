class_name CustodianBoss
extends GreyboxEnemy

signal add_wave_requested(requests: Array[Dictionary])

const BossBrainScript := preload("res://scripts/room_graph/boss_brain.gd")
const TelegraphMarkerScript := preload("res://scripts/room_graph/telegraph_marker.gd")

const BOSS_ARCHETYPE := "custodian"
const BOSS_MAX_HP := 2400.0
const INTRO_LABEL_NAME := "Nameplate"

@export var reposition_speed: float = 0.85
@export var preferred_distance: float = 5.6
@export var leash_distance: float = 8.0

var boss_brain = BossBrainScript.new()

var _active_markers: Array = []
var _current_attack_context: Dictionary = {}
var _stagger_remaining: float = 0.0
var _rng: RandomNumberGenerator = null
var _fight_started := false

func _ready() -> void:
	_configured = true
	if spawn_id == "":
		spawn_id = "boss:custodian"
	archetype = BOSS_ARCHETYPE
	max_hp = BOSS_MAX_HP
	if hp <= 0.0:
		hp = max_hp
	_dead = false
	_spawn_windup_remaining = 0.0
	_apply_boss_visuals()
	_configure_brain()

func _exit_tree() -> void:
	clear_telegraph_markers()
	super()

func configure_boss(p_spawn_id: String = "boss:custodian", p_rng: RandomNumberGenerator = null) -> void:
	clear_telegraph_markers()
	spawn_id = p_spawn_id
	archetype = BOSS_ARCHETYPE
	max_hp = BOSS_MAX_HP
	hp = max_hp
	_dead = false
	_spawn_windup_remaining = 0.0
	_stagger_remaining = 0.0
	_fight_started = false
	velocity = Vector3.ZERO
	_rng = p_rng
	_configure_brain()
	_apply_boss_visuals()

func set_chase_target(target: Node3D) -> void:
	chase_target = target

func clear_chase_target() -> void:
	chase_target = null
	_fight_started = false
	velocity = Vector3.ZERO

func begin_fight() -> void:
	if _dead:
		return
	_fight_started = true

func end_fight() -> void:
	_fight_started = false
	velocity = Vector3.ZERO

func is_fight_started() -> bool:
	return _fight_started

func stagger(duration: float) -> void:
	_stagger_remaining = maxf(_stagger_remaining, minf(maxf(duration, 0.0), 0.35))
	velocity = Vector3.ZERO
	if boss_brain.interrupt_current_attack():
		clear_telegraph_markers()

func is_staggered() -> bool:
	return _stagger_remaining > 0.0

func is_spawning() -> bool:
	return false

func spawn_windup_remaining() -> float:
	return 0.0

func take_damage(amount: float, charges_spark: bool = true) -> float:
	var remaining := super.take_damage(amount, charges_spark)
	if not is_dead():
		boss_brain.update_health(hp, max_hp)
	return remaining

func tick_chase(target_position: Vector3, delta: float) -> Dictionary:
	var result := _reposition_result_for(target_position)
	if _dead:
		velocity = Vector3.ZERO
		result["velocity"] = velocity
		result["attack_state"] = boss_brain.execution_state()
		result["damage_event"] = {}
		return result
	_tick_stagger(delta)
	if _fight_started and _stagger_remaining <= 0.0:
		velocity = Vector3(result["velocity"])
	else:
		velocity = Vector3.ZERO
		result["velocity"] = velocity
	result["attack_state"] = boss_brain.execution_state()
	result["damage_event"] = {}
	return result

func show_nameplate(show: bool) -> void:
	var label := _nameplate()
	if label != null:
		label.visible = show

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		velocity = Vector3.ZERO
		set_physics_process(false)
		return
	if _dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	_tick_stagger(delta)
	if _fight_started and _stagger_remaining <= 0.0:
		_tick_reposition(delta)
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	_face_target(delta)
	if not _fight_started:
		return
	if _stagger_remaining > 0.0:
		return
	for event in boss_brain.tick(delta):
		if String(event.get("type", "")) == "attack_committed":
			_commit_attack(event.get("attack", {}) as Dictionary)
	if boss_brain.execution_state() == BossBrainScript.STATE_IDLE and chase_target != null:
		var attack: Dictionary = boss_brain.begin_next_attack()
		if not attack.is_empty():
			_spawn_telegraphs_for_attack(attack)

func _configure_brain() -> void:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	boss_brain.configure({
		"rng": _rng,
		"max_hp": max_hp,
	})
	boss_brain.update_health(hp, max_hp)
	var callback := Callable(self, "_on_brain_add_wave_requested")
	if not boss_brain.add_wave_requested.is_connected(callback):
		boss_brain.add_wave_requested.connect(callback)

func _on_brain_add_wave_requested(requests: Array[Dictionary]) -> void:
	add_wave_requested.emit(requests)

func _tick_stagger(delta: float) -> void:
	_stagger_remaining = maxf(0.0, _stagger_remaining - maxf(delta, 0.0))

func _tick_reposition(_delta: float) -> void:
	if chase_target == null:
		velocity = Vector3.ZERO
		return
	var to_player := chase_target.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance <= 0.001:
		velocity = Vector3.ZERO
		return
	var direction := to_player / distance
	if distance > leash_distance:
		velocity = direction * reposition_speed
	elif distance < preferred_distance:
		velocity = -direction * reposition_speed * 0.45
	else:
		velocity = Vector3.ZERO

func _reposition_result_for(target_position: Vector3) -> Dictionary:
	var to_player := target_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var direction := Vector3.ZERO
	var next_velocity := Vector3.ZERO
	if distance > 0.001:
		direction = to_player / distance
		if distance > leash_distance:
			next_velocity = direction * reposition_speed
		elif distance < preferred_distance:
			next_velocity = -direction * reposition_speed * 0.45
	return {
		"velocity": next_velocity,
		"direction": direction,
		"distance": distance,
		"in_contact": distance <= contact_radius,
		"attack_state": boss_brain.execution_state(),
		"damage_event": {},
	}

func _spawn_telegraphs_for_attack(attack: Dictionary) -> void:
	_clear_committed_markers()
	_current_attack_context = attack.duplicate(true)
	var attack_id := String(attack.get("id", ""))
	match attack_id:
		BossBrainScript.ATTACK_AUDIT_SWEEP:
			_spawn_line_marker(_current_attack_context)
		BossBrainScript.ATTACK_COMPLIANCE_RING:
			_spawn_disc_marker(_current_attack_context, global_position, "ring")
		BossBrainScript.ATTACK_OVERREACH_SLAM:
			_spawn_disc_marker(_current_attack_context, _player_position(), "slam")
		BossBrainScript.ATTACK_DECOY_PING:
			_spawn_decoy_markers(_current_attack_context)
		_:
			pass

func _spawn_line_marker(attack: Dictionary) -> void:
	var marker := _new_marker()
	var target := _player_position()
	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.000001:
		direction = Vector3(0.0, 0.0, -1.0)
	direction = direction.normalized()
	var line_length := float(attack.get("line_length", 8.0))
	marker.global_position = global_position + direction * (line_length * 0.5)
	marker.rotation.y = atan2(direction.x, direction.z)
	marker.configure({
		"marker_id": "%s:%s" % [spawn_id, attack.get("id", "")],
		"shape": TelegraphMarkerScript.SHAPE_LINE,
		"length": line_length,
		"width": float(attack.get("line_width", 0.85)),
		"duration": float(attack.get("telegraph_seconds", 0.9)),
		"color": Color(1.0, 0.72, 0.22, 0.7),
		"pulse": true,
	})
	attack["origin"] = global_position
	attack["target_position"] = global_position + direction * line_length
	_active_markers.append(marker)

func _spawn_disc_marker(attack: Dictionary, position: Vector3, suffix: String) -> void:
	var marker := _new_marker()
	marker.global_position = Vector3(position.x, 0.02, position.z)
	marker.configure({
		"marker_id": "%s:%s:%s" % [spawn_id, attack.get("id", ""), suffix],
		"shape": TelegraphMarkerScript.SHAPE_DISC,
		"radius": float(attack.get("radius", 2.0)),
		"duration": float(attack.get("telegraph_seconds", 0.8)),
		"color": Color(1.0, 0.72, 0.22, 0.68),
		"pulse": true,
	})
	attack["target_position"] = marker.global_position
	_active_markers.append(marker)

func _spawn_decoy_markers(attack: Dictionary) -> void:
	var center := _player_position()
	var offsets: Array[Vector3] = [
		Vector3(-2.2, 0.0, -0.6),
		Vector3(0.0, 0.0, 0.0),
		Vector3(2.2, 0.0, 0.8),
	]
	var positions: Array[Vector3] = []
	var real_index := int(attack.get("real_index", 1))
	for index in range(offsets.size()):
		var marker := _new_marker()
		var position := center + offsets[index]
		marker.global_position = Vector3(position.x, 0.02, position.z)
		var color := Color(1.0, 0.16, 0.1, 0.82) if index == real_index else Color(1.0, 0.72, 0.22, 0.5)
		marker.configure({
			"marker_id": "%s:%s:%d" % [spawn_id, attack.get("id", ""), index],
			"shape": TelegraphMarkerScript.SHAPE_DISC,
			"radius": float(attack.get("radius", 2.0)),
			"duration": float(attack.get("telegraph_seconds", 1.4)),
			"color": color,
			"pulse": index == real_index,
		})
		positions.append(marker.global_position)
		_active_markers.append(marker)
	attack["decoy_positions"] = positions

func _new_marker() -> Node3D:
	var marker := TelegraphMarkerScript.new() as Node3D
	var parent := get_parent()
	if parent != null:
		parent.add_child(marker)
	else:
		add_child(marker)
	return marker

func _commit_attack(attack: Dictionary) -> void:
	for marker in _active_markers:
		if marker != null and is_instance_valid(marker):
			marker.commit()
	_active_markers.clear()
	var resolved_attack := attack
	if not _current_attack_context.is_empty() and String(_current_attack_context.get("id", "")) == String(attack.get("id", "")):
		resolved_attack = _current_attack_context.duplicate(true)
	_current_attack_context.clear()
	if chase_target == null or not is_instance_valid(chase_target):
		return
	if _attack_hits_player(resolved_attack):
		damage_event.emit({
			"damage": int(resolved_attack.get("damage", 0)),
			"spawn_id": spawn_id,
			"archetype": archetype,
			"attack_id": String(resolved_attack.get("id", "")),
			"source_position": global_position,
			})

func clear_telegraph_markers() -> void:
	for marker in _active_markers:
		if marker != null and is_instance_valid(marker):
			(marker as Node).queue_free()
	_active_markers.clear()
	_current_attack_context.clear()

func _attack_hits_player(attack: Dictionary) -> bool:
	var attack_id := String(attack.get("id", ""))
	var player_position := _player_position()
	match attack_id:
		BossBrainScript.ATTACK_AUDIT_SWEEP:
			var origin: Vector3 = attack.get("origin", global_position)
			var target: Vector3 = attack.get("target_position", global_position)
			return _point_distance_to_segment_xz(player_position, origin, target) <= float(attack.get("line_width", 0.85))
		BossBrainScript.ATTACK_COMPLIANCE_RING:
			return _xz_distance(player_position, global_position) <= float(attack.get("radius", 3.0))
		BossBrainScript.ATTACK_OVERREACH_SLAM:
			var target_position: Vector3 = attack.get("target_position", global_position)
			return _xz_distance(player_position, target_position) <= float(attack.get("radius", 2.5))
		BossBrainScript.ATTACK_DECOY_PING:
			var positions: Array = attack.get("decoy_positions", [])
			var real_index := int(attack.get("real_index", 1))
			if real_index >= 0 and real_index < positions.size():
				var real_position: Vector3 = positions[real_index]
				return _xz_distance(player_position, real_position) <= float(attack.get("radius", 2.0))
			return false
		_:
			return false

func _player_position() -> Vector3:
	if chase_target != null and is_instance_valid(chase_target):
		return chase_target.global_position
	return global_position

func _point_distance_to_segment_xz(point: Vector3, a: Vector3, b: Vector3) -> float:
	var p := Vector2(point.x, point.z)
	var start := Vector2(a.x, a.z)
	var end := Vector2(b.x, b.z)
	var segment := end - start
	var length_sq := segment.length_squared()
	if length_sq <= 0.000001:
		return p.distance_to(start)
	var t := clampf((p - start).dot(segment) / length_sq, 0.0, 1.0)
	return p.distance_to(start + segment * t)

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _face_target(delta: float) -> void:
	if visual_pivot == null or chase_target == null or not is_instance_valid(chase_target):
		return
	var direction := chase_target.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.000001:
		return
	direction = direction.normalized()
	var target_yaw := atan2(direction.x, direction.z)
	var turn_weight := 1.0 - exp(-turn_speed * maxf(delta, 0.0))
	visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_yaw, turn_weight)

func _apply_boss_visuals() -> void:
	var pivot := get_node_or_null("VisualPivot") as Node3D
	if pivot != null:
		visual_pivot = pivot
	var label := _nameplate()
	if label != null:
		label.text = "THE CUSTODIAN"
		label.visible = false

func _nameplate() -> Label3D:
	return get_node_or_null(INTRO_LABEL_NAME) as Label3D

func _clear_committed_markers() -> void:
	var survivors: Array = []
	for marker in _active_markers:
		if marker != null and is_instance_valid(marker) and not marker.is_queued_for_deletion():
			survivors.append(marker)
	_active_markers = survivors
