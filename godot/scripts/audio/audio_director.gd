extends Node

const MUSIC_STATE_HUB: StringName = &"HUB"
const MUSIC_STATE_COMBAT: StringName = &"COMBAT"
const MUSIC_STATE_CLEARED: StringName = &"CLEARED"

const MUSIC_BUS := &"Music"
const ACTIVE_VOLUME_DB := 0.0
const SILENT_VOLUME_DB := -80.0

@export_range(0.0, 10.0, 0.01, "or_greater") var crossfade_seconds: float = 1.25

var _cue_registry: Dictionary = {}
var _state_cue_ids: Dictionary = {
	MUSIC_STATE_HUB: &"music_hub",
	MUSIC_STATE_COMBAT: &"music_combat",
	MUSIC_STATE_CLEARED: &"music_cleared",
}
var _music_lanes: Array[AudioStreamPlayer] = []
var _active_lane_index := 0
var _requested_music_state: StringName = &""
var _active_music_state: StringName = &""
var _active_cue_id: StringName = &""
var _last_noop_reason: StringName = &""
var _last_crossfade: Dictionary = {}
var _crossfade_count := 0
var _crossfade_tween: Tween = null
var _is_fading := false

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_ensure_music_lanes()

func register_cue(cue_id: StringName, stream: AudioStream) -> void:
	if String(cue_id).is_empty() or stream == null:
		return
	_cue_registry[cue_id] = stream
	if _active_cue_id == cue_id:
		var active_player := _active_player()
		active_player.stream = stream
		active_player.bus = String(MUSIC_BUS)
		active_player.play()
		return
	var requested_cue := _cue_id_for_state(_requested_music_state)
	if requested_cue == cue_id and _active_cue_id != cue_id:
		_play_registered_state(_requested_music_state, cue_id)

func bind_music_state_cue(state: StringName, cue_id: StringName) -> void:
	if String(state).is_empty() or String(cue_id).is_empty():
		return
	_state_cue_ids[state] = cue_id

func set_zone_state(state: StringName) -> void:
	_last_noop_reason = &""
	if String(state).is_empty():
		_last_noop_reason = &"empty_state"
		return

	_requested_music_state = state
	var cue_id := _cue_id_for_state(state)
	if String(cue_id).is_empty():
		_last_noop_reason = &"missing_state_cue"
		return
	if not _cue_registry.has(cue_id):
		_last_noop_reason = &"missing_registered_cue"
		return
	if _active_music_state == state and _active_cue_id == cue_id:
		_last_noop_reason = &"duplicate_state"
		return

	_play_registered_state(state, cue_id)

func set_music_state(state: StringName) -> void:
	set_zone_state(state)

func describe() -> Dictionary:
	_ensure_music_lanes()
	var active_player := _active_player()
	var inactive_player := _inactive_player()
	return {
		"current_state": String(_active_music_state),
		"requested_music_state": String(_requested_music_state),
		"active_music_state": String(_active_music_state),
		"active_cue_id": String(_active_cue_id),
		"bus_mix": _bus_mix(),
		"fading": _is_fading,
		"registered_cue_count": _cue_registry.size(),
		"registered_cues": _registered_cue_ids(),
		"state_cue_ids": _state_cue_ids_as_strings(),
		"crossfade_count": _crossfade_count,
		"last_crossfade": _last_crossfade.duplicate(true),
		"last_noop_reason": String(_last_noop_reason),
		"music_lane_count": _music_lanes.size(),
		"active_lane": active_player.name,
		"inactive_lane": inactive_player.name,
		"active_volume_db": active_player.volume_db,
		"inactive_volume_db": inactive_player.volume_db,
	}

func _cue_id_for_state(state: StringName) -> StringName:
	return StringName(_state_cue_ids.get(state, &""))

func _play_registered_state(state: StringName, cue_id: StringName) -> void:
	_ensure_music_lanes()
	var stream := _cue_registry.get(cue_id) as AudioStream
	if stream == null:
		_last_noop_reason = &"missing_registered_cue"
		return

	if _crossfade_tween != null:
		_crossfade_tween.kill()
		_crossfade_tween = null
	_is_fading = false

	var from_player := _active_player()
	var to_lane_index := 1 - _active_lane_index
	var to_player := _music_lanes[to_lane_index]
	var from_cue_id := _active_cue_id

	to_player.stream = stream
	to_player.bus = String(MUSIC_BUS)
	to_player.volume_db = SILENT_VOLUME_DB
	to_player.play()

	_active_lane_index = to_lane_index
	_active_music_state = state
	_active_cue_id = cue_id
	_crossfade_count += 1
	_last_noop_reason = &""
	_last_crossfade = {
		"from_cue_id": String(from_cue_id),
		"to_cue_id": String(cue_id),
		"from_lane": from_player.name,
		"to_lane": to_player.name,
		"from_start_db": from_player.volume_db,
		"from_target_db": SILENT_VOLUME_DB,
		"to_start_db": SILENT_VOLUME_DB,
		"to_target_db": ACTIVE_VOLUME_DB,
		"duration": crossfade_seconds,
	}

	var fade_duration := maxf(0.0, crossfade_seconds)
	if fade_duration <= 0.0:
		from_player.volume_db = SILENT_VOLUME_DB
		from_player.stop()
		to_player.volume_db = ACTIVE_VOLUME_DB
		_is_fading = false
		return

	_is_fading = true
	_crossfade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	_crossfade_tween.tween_property(from_player, "volume_db", SILENT_VOLUME_DB, fade_duration)
	_crossfade_tween.tween_property(to_player, "volume_db", ACTIVE_VOLUME_DB, fade_duration)
	_crossfade_tween.chain().tween_callback(func() -> void:
		from_player.stop()
		_is_fading = false
	)

func _ensure_music_lanes() -> void:
	while _music_lanes.size() < 2:
		var lane := AudioStreamPlayer.new()
		lane.name = "MusicLane%d" % (_music_lanes.size() + 1)
		lane.process_mode = Node.PROCESS_MODE_ALWAYS
		lane.bus = String(MUSIC_BUS)
		lane.volume_db = SILENT_VOLUME_DB
		add_child(lane)
		_music_lanes.append(lane)

func _active_player() -> AudioStreamPlayer:
	_ensure_music_lanes()
	return _music_lanes[_active_lane_index]

func _inactive_player() -> AudioStreamPlayer:
	_ensure_music_lanes()
	return _music_lanes[1 - _active_lane_index]

func _registered_cue_ids() -> Array[String]:
	var cue_ids: Array[String] = []
	for cue_id in _cue_registry.keys():
		cue_ids.append(String(cue_id))
	cue_ids.sort()
	return cue_ids

func _state_cue_ids_as_strings() -> Dictionary:
	var result := {}
	for state in _state_cue_ids.keys():
		result[String(state)] = String(_state_cue_ids[state])
	return result

func _bus_mix() -> Dictionary:
	var result := {}
	for bus_index in range(AudioServer.get_bus_count()):
		var bus_name := String(AudioServer.get_bus_name(bus_index))
		result[bus_name] = {
			"volume_db": AudioServer.get_bus_volume_db(bus_index),
		}
	return result
