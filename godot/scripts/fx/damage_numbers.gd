class_name DamageNumbers
extends Node3D

const NodePoolScript := preload("res://scripts/util/node_pool.gd")
const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")

const MAX_POOL_SIZE := 48
const PREWARM_COUNT := 16
const MERGE_WINDOW_SECONDS := 0.08
const MERGE_RADIUS_XZ := 0.6
const NORMAL_FONT_SIZE := 64
const BOOSTED_FONT_SIZE := 84
const CRIT_FONT_SIZE := 110
const NORMAL_SECONDS := CombatEffectsScript.DAMAGE_NUMBER_SECONDS
const CRIT_SECONDS := 0.72
const NORMAL_RISE := CombatEffectsScript.DAMAGE_NUMBER_RISE
const CRIT_RISE := 1.15

const TIER_NORMAL := 0
const TIER_BOOSTED := 1
const TIER_CRIT := 2
const TIER_PLAYER_HIT := 3

var _pool: NodePool = null
var _active_labels: Dictionary = {}
var _merge_records: Dictionary = {}
var _tweens: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _merge_token: int = 0

func _ready() -> void:
	add_to_group("damage_numbers")
	_rng.seed = 90210
	_pool = NodePoolScript.new(Callable(self, "_make_label"), self, MAX_POOL_SIZE) as NodePool
	_pool.prewarm(PREWARM_COUNT)

func pop(origin: Vector3, amount: float, opts: Dictionary = {}) -> void:
	if amount <= 0.0 or _pool == null:
		return
	_flush_expired_merges()
	var tier := _tier_for_opts(opts)
	var merge_key := _find_merge_key(origin)
	if merge_key != "":
		_merge_into_label(merge_key, origin, amount, tier)
		return

	var label := _pool.acquire() as Label3D
	if label == null:
		return
	_reset_label(label)
	_apply_tier(label, tier)
	label.text = _format_amount(amount)
	label.global_position = origin

	var instance_id := label.get_instance_id()
	_active_labels[instance_id] = label
	_register_merge_record(label, origin, amount, tier)
	_start_motion(label, origin, tier)

func available_count() -> int:
	return _pool.available_count() if _pool != null else 0

func in_use_count() -> int:
	return _pool.in_use_count() if _pool != null else 0

func total_count() -> int:
	return _pool.total_count() if _pool != null else 0

func _make_label() -> Label3D:
	var label := Label3D.new()
	label.name = "DamageNumber"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 14
	return label

func _register_merge_record(label: Label3D, origin: Vector3, amount: float, tier: int) -> void:
	var cell := _quantize_origin(origin)
	var key := _merge_key(cell.x, cell.y)
	_merge_token += 1
	var token := _merge_token
	_merge_records[key] = {
		"label": label,
		"origin": origin,
		"amount": amount,
		"tier": tier,
		"expires_at": _now_msec() + int(MERGE_WINDOW_SECONDS * 1000.0),
		"token": token,
	}
	_schedule_merge_expiry(key, token)

func _merge_into_label(key: String, origin: Vector3, amount: float, tier: int) -> void:
	var record: Dictionary = _merge_records.get(key, {})
	var label := record.get("label") as Label3D
	if label == null or not is_instance_valid(label):
		_merge_records.erase(key)
		pop(origin, amount, {"crit": tier == TIER_CRIT, "boosted": tier == TIER_BOOSTED, "player_hit": tier == TIER_PLAYER_HIT})
		return

	var merged_amount := float(record.get("amount", 0.0)) + amount
	var merged_tier := maxi(int(record.get("tier", TIER_NORMAL)), tier)
	label.text = _format_amount(merged_amount)
	_apply_tier(label, merged_tier)

	_merge_token += 1
	record["amount"] = merged_amount
	record["tier"] = merged_tier
	record["origin"] = origin
	record["expires_at"] = _now_msec() + int(MERGE_WINDOW_SECONDS * 1000.0)
	record["token"] = _merge_token
	_merge_records[key] = record
	_schedule_merge_expiry(key, _merge_token)
	_start_motion(label, label.global_position, merged_tier)

func _find_merge_key(origin: Vector3) -> String:
	var cell := _quantize_origin(origin)
	var now := _now_msec()
	for x_offset in range(-1, 2):
		for z_offset in range(-1, 2):
			var key := _merge_key(cell.x + x_offset, cell.y + z_offset)
			if not _merge_records.has(key):
				continue
			var record: Dictionary = _merge_records[key]
			if int(record.get("expires_at", 0)) < now:
				_merge_records.erase(key)
				continue
			var label := record.get("label") as Label3D
			if label == null or not is_instance_valid(label):
				_merge_records.erase(key)
				continue
			var record_origin: Vector3 = record.get("origin", origin)
			if _xz_distance(record_origin, origin) <= MERGE_RADIUS_XZ:
				return key
	return ""

func _flush_expired_merges() -> void:
	var now := _now_msec()
	for key in _merge_records.keys():
		var record: Dictionary = _merge_records[key]
		var label := record.get("label") as Label3D
		if int(record.get("expires_at", 0)) < now or label == null or not is_instance_valid(label):
			_merge_records.erase(key)

func _schedule_merge_expiry(key: String, token: int) -> void:
	if not is_inside_tree():
		return
	var timer := get_tree().create_timer(MERGE_WINDOW_SECONDS)
	var callback := func() -> void:
		_expire_merge_key(key, token)
	timer.timeout.connect(callback, CONNECT_ONE_SHOT)

func _expire_merge_key(key: String, token: int) -> void:
	if not _merge_records.has(key):
		return
	var record: Dictionary = _merge_records[key]
	if int(record.get("token", -1)) == token:
		_merge_records.erase(key)

func _start_motion(label: Label3D, origin: Vector3, tier: int) -> void:
	_kill_tween_for_label(label)
	var duration := CRIT_SECONDS if tier == TIER_CRIT else NORMAL_SECONDS
	var rise := CRIT_RISE if tier == TIER_CRIT else NORMAL_RISE
	var drift := Vector3(_rng.randf_range(-0.35, 0.35), 0.0, _rng.randf_range(-0.15, 0.15))
	var tween := label.create_tween()
	var instance_id := label.get_instance_id()
	_tweens[instance_id] = tween
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", origin + drift + Vector3(0.0, rise, 0.0), duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration * 0.55) \
		.set_delay(duration * 0.45)
	tween.tween_property(label, "outline_modulate:a", 0.0, duration * 0.55) \
		.set_delay(duration * 0.45)
	if tier == TIER_BOOSTED or tier == TIER_CRIT:
		var start_scale := 0.72 if tier == TIER_CRIT else 0.82
		var punch_scale := 1.24 if tier == TIER_CRIT else 1.14
		label.scale = Vector3.ONE * start_scale
		tween.tween_property(label, "scale", Vector3.ONE * punch_scale, 0.06) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "scale", Vector3.ONE, 0.12) \
			.set_delay(0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		label.scale = Vector3.ONE
	tween.chain().tween_callback(func() -> void:
		_release_label(label)
	)

func _release_label(label: Label3D) -> void:
	if label == null or not is_instance_valid(label):
		return
	_kill_tween_for_label(label)
	_remove_label_merge_records(label)
	_active_labels.erase(label.get_instance_id())
	_reset_label(label)
	if _pool != null:
		_pool.release(label)

func _kill_tween_for_label(label: Label3D) -> void:
	var instance_id := label.get_instance_id()
	var tween := _tweens.get(instance_id) as Tween
	_tweens.erase(instance_id)
	if tween != null and tween.is_valid():
		tween.kill()

func _remove_label_merge_records(label: Label3D) -> void:
	for key in _merge_records.keys():
		var record: Dictionary = _merge_records[key]
		if record.get("label") == label:
			_merge_records.erase(key)

func _reset_label(label: Label3D) -> void:
	label.text = ""
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = NORMAL_FONT_SIZE
	label.outline_size = 14
	label.outline_modulate = Color(0.08, 0.05, 0.02, 0.9)
	label.modulate = CombatEffectsScript.DAMAGE_NUMBER_COLOR
	label.scale = Vector3.ONE
	label.position = Vector3.ZERO

func _apply_tier(label: Label3D, tier: int) -> void:
	label.font_size = _font_size_for_tier(tier)
	label.modulate = _color_for_tier(tier)
	label.outline_modulate = Color(0.08, 0.05, 0.02, 0.9)

func _tier_for_opts(opts: Dictionary) -> int:
	if bool(opts.get("player_hit", false)):
		return TIER_PLAYER_HIT
	if bool(opts.get("crit", false)):
		return TIER_CRIT
	if bool(opts.get("boosted", false)):
		return TIER_BOOSTED
	return TIER_NORMAL

func _font_size_for_tier(tier: int) -> int:
	match tier:
		TIER_CRIT:
			return CRIT_FONT_SIZE
		TIER_BOOSTED:
			return BOOSTED_FONT_SIZE
		_:
			return NORMAL_FONT_SIZE

func _color_for_tier(tier: int) -> Color:
	match tier:
		TIER_PLAYER_HIT:
			return CombatEffectsScript.PLAYER_HIT_NUMBER_COLOR
		TIER_CRIT:
			return CombatEffectsScript.FX_IDENTITY
		TIER_BOOSTED:
			return CombatEffectsScript.FX_IDENTITY_RIM
		_:
			return CombatEffectsScript.DAMAGE_NUMBER_COLOR

func _format_amount(amount: float) -> String:
	return str(maxi(1, roundi(amount)))

func _quantize_origin(origin: Vector3) -> Vector2i:
	return Vector2i(
		floori(origin.x / MERGE_RADIUS_XZ),
		floori(origin.z / MERGE_RADIUS_XZ)
	)

func _merge_key(x: int, z: int) -> String:
	return "%d:%d" % [x, z]

func _now_msec() -> int:
	return int(Time.get_ticks_msec())

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
