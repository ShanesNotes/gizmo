extends Node

const MUSIC_STATE_HUB: StringName = &"HUB"
const MUSIC_STATE_COMBAT: StringName = &"COMBAT"
const MUSIC_STATE_CLEARED: StringName = &"CLEARED"

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const ACTIVE_VOLUME_DB := 0.0
const SILENT_VOLUME_DB := -80.0
const SFX_POOL_SIZE := 8

const V2_CUE_MAP_PATH := "res://audio/music/soundtrack_v2/cue_map.json"
const V2_AUDIO_DIR := "res://audio/music/soundtrack_v2/"
## Pivot-state → cue-map-zone aliases (provisional, audition-pending; see
## docs/hades-pivot/audio-canon-handoff-note.md).
const V2_STATE_ALIASES := {
	&"HUB": &"SANCTUARY",
	&"COMBAT": &"ROAM",
	&"BOSS": &"REKINDLE_SIEGE",
	&"SHOP": &"SCRAP_MERCHANT",
	&"REST": &"SANCTUARY",
	&"ORIGIN_ENTRY": &"ORIGIN",
}
const V2_ENGAGE_PRESSURE := 0.25
const V2_RELAX_PRESSURE := 0.15
const V2_VARIANT_DWELL_SECONDS := 20.0
const V2_SILENCE_ENTRY_SECONDS := 15.0
const V2_IDLE_FADE_SECONDS := 45.0
const V2_DEFEAT_SILENCE_SECONDS := 2.5

const MUSIC_CUE_MANIFEST := {
	MUSIC_STATE_HUB: {
		"cue_id": &"music_hub",
		"path": "res://audio/music/music_hub_loop.ogg",
	},
	MUSIC_STATE_COMBAT: {
		"cue_id": &"music_combat",
		"path": "res://audio/music/music_combat_loop.ogg",
	},
}

const SFX_EVENT_MANIFEST := {
	&"melee_hit": "res://audio/sfx/sfx_melee_hit.wav",
	&"enemy_death": "res://audio/sfx/sfx_enemy_death.wav",
	&"surge_burst": "res://audio/sfx/sfx_surge_burst.wav",
	&"cast_shot": "res://audio/sfx/sfx_cast_shot.wav",
	&"guard_hit": "res://audio/sfx/sfx_guard_hit.wav",
	&"door_open": "res://audio/sfx/sfx_door_open.wav",
	&"boon_pickup": "res://audio/sfx/sfx_boon_pickup.wav",
	&"ui_click": "res://audio/sfx/sfx_ui_click.wav",
	&"dash_whoosh": "res://audio/sfx/sfx_dash_whoosh.wav",
	&"boss_telegraph": "res://audio/sfx/sfx_boss_telegraph.wav",
}

@export_range(0.0, 10.0, 0.01, "or_greater") var crossfade_seconds: float = 1.25

var _cue_registry: Dictionary = {}
var _state_cue_ids: Dictionary = {
	MUSIC_STATE_HUB: &"music_hub",
	MUSIC_STATE_COMBAT: &"music_combat",
}
var _music_lanes: Array[AudioStreamPlayer] = []
var _sfx_registry: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _active_lane_index := 0
var _sfx_pool_index := 0
var _requested_music_state: StringName = &""
var _active_music_state: StringName = &""
var _active_cue_id: StringName = &""
var _last_sfx_event: StringName = &""
var _last_sfx_player_name := ""
var _last_noop_reason: StringName = &""
var _last_crossfade: Dictionary = {}
var _crossfade_count := 0
var _sfx_play_count := 0
var _sfx_event_counts: Dictionary = {}
var _crossfade_tween: Tween = null
var _is_fading := false

# ── Soundtrack v2 state (dual-variant score; spec: docs/audio/soundtrack-map-v2.md) ──
var _v2_zones: Dictionary = {}          # zone -> {"ORCH": path, "JAZZ": path, "rule": String}
var _v2_ui_contexts: Dictionary = {}    # context -> {"cue": zone-ish id, "variant": String}
var _v2_vitals_paths: Dictionary = {}   # variant -> path (AMB_03)
var _v2_loaded := false
var _pressure := 0.0
var _variant: StringName = &"ORCH"
var _variant_last_switch_ms := -1000000
var _silence_hold := false
var _silence_remaining := 0.0
var _idle_quiet_elapsed := 0.0
var _idle_faded := false
var _ui_override_active := false
var _ui_override_tween: Tween = null
var _vitals_lane: AudioStreamPlayer = null
var _vitals_overlay_active := false
var _last_zone_request: StringName = &""

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_ensure_music_lanes()
	_register_music_manifest()
	_ensure_sfx_pool()
	_register_sfx_manifest()
	_load_v2_cue_table()
	set_process(true)

func _process(delta: float) -> void:
	if _silence_hold:
		_silence_remaining -= delta
		if _silence_remaining <= 0.0:
			_silence_hold = false
			_replay_requested_zone()
	if not _silence_hold and not _ui_override_active and _pressure < V2_RELAX_PRESSURE \
			and _v2_zone_for_state(_last_zone_request) == &"ROAM" and not _idle_faded:
		_idle_quiet_elapsed += delta
		if _idle_quiet_elapsed >= V2_IDLE_FADE_SECONDS:
			_idle_faded = true
			_fade_active_lane_out(8.0)
	elif _pressure >= V2_RELAX_PRESSURE:
		_idle_quiet_elapsed = 0.0
		if _idle_faded:
			_idle_faded = false
			_replay_requested_zone()

func register_cue(cue_id: StringName, stream: AudioStream, loop: bool = true) -> void:
	if String(cue_id).is_empty() or stream == null:
		return
	_set_stream_loop(stream, loop)
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

	_last_zone_request = state
	_requested_music_state = state
	# CLEARED is not a zone in v2: the zone stays, pressure relaxes elsewhere.
	if _v2_loaded and state == &"CLEARED":
		_last_noop_reason = &"v2_cleared_pressure_only"
		return
	var v2_zone := _v2_zone_for_state(state)
	if _v2_loaded and _v2_zones.has(v2_zone):
		_play_v2_zone(v2_zone)
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

func notify_event(event: StringName) -> void:
	_last_noop_reason = &""
	if String(event).is_empty():
		_last_noop_reason = &"empty_sfx_event"
		return
	var stream := _sfx_registry.get(event) as AudioStream
	if stream == null:
		_last_noop_reason = &"unknown_sfx_event"
		return

	_ensure_sfx_pool()
	var player := _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.bus = String(SFX_BUS)
	player.volume_db = ACTIVE_VOLUME_DB
	player.play()

	_sfx_play_count += 1
	_last_sfx_event = event
	_last_sfx_player_name = player.name
	var event_key := String(event)
	_sfx_event_counts[event_key] = int(_sfx_event_counts.get(event_key, 0)) + 1

func describe() -> Dictionary:
	_ensure_music_lanes()
	_ensure_sfx_pool()
	var active_player := _active_player()
	var inactive_player := _inactive_player()
	return {
		"v2_loaded": _v2_loaded,
		"v2_zone_count": _v2_zones.size(),
		"v2_variant": String(_variant),
		"v2_pressure": _pressure,
		"v2_silence_hold": _silence_hold,
		"v2_ui_override": _ui_override_active,
		"v2_vitals_overlay": _vitals_overlay_active,
		"v2_last_zone_request": String(_last_zone_request),
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
		"sfx_pool_size": _sfx_players.size(),
		"sfx_registered_event_count": _sfx_registry.size(),
		"sfx_registered_events": _registered_sfx_events(),
		"sfx_play_count": _sfx_play_count,
		"sfx_event_counts": _sfx_event_counts.duplicate(true),
		"last_sfx_event": String(_last_sfx_event),
		"last_sfx_player": _last_sfx_player_name,
		"next_sfx_player_index": _sfx_pool_index,
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

func _ensure_sfx_pool() -> void:
	while _sfx_players.size() < SFX_POOL_SIZE:
		var lane := AudioStreamPlayer.new()
		lane.name = "SfxLane%d" % (_sfx_players.size() + 1)
		lane.process_mode = Node.PROCESS_MODE_ALWAYS
		lane.bus = String(SFX_BUS)
		lane.volume_db = ACTIVE_VOLUME_DB
		add_child(lane)
		_sfx_players.append(lane)

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

func _registered_sfx_events() -> Array[String]:
	var events: Array[String] = []
	for event in _sfx_registry.keys():
		events.append(String(event))
	events.sort()
	return events

func _state_cue_ids_as_strings() -> Dictionary:
	var result := {}
	for state in _state_cue_ids.keys():
		result[String(state)] = String(_state_cue_ids[state])
	return result

func _register_music_manifest() -> void:
	for state in MUSIC_CUE_MANIFEST.keys():
		var record: Dictionary = MUSIC_CUE_MANIFEST[state]
		var cue_id := record.get("cue_id", &"") as StringName
		var stream := load(String(record.get("path", ""))) as AudioStream
		if stream == null:
			continue
		bind_music_state_cue(state, cue_id)
		register_cue(cue_id, stream)

func _register_sfx_manifest() -> void:
	for event in SFX_EVENT_MANIFEST.keys():
		var stream := load(String(SFX_EVENT_MANIFEST[event])) as AudioStream
		if stream == null:
			continue
		_sfx_registry[event] = stream

func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			stream.set("loop", enabled)
			return

func _bus_mix() -> Dictionary:
	var result := {}
	for bus_index in range(AudioServer.get_bus_count()):
		var bus_name := String(AudioServer.get_bus_name(bus_index))
		result[bus_name] = {
			"volume_db": AudioServer.get_bus_volume_db(bus_index),
		}
	return result


# ══════════════════ Soundtrack v2 (dual-variant score) ══════════════════
# Spec: docs/audio/soundtrack-map-v2.md · map: audio/music/soundtrack_v2/cue_map.json
# Zone assignments are provisional pending the audio lab's audition pass.

func set_pressure(level: float) -> void:
	_pressure = clampf(level, 0.0, 1.0)
	if _silence_hold and _pressure > 0.0:
		_silence_hold = false
		_replay_requested_zone()
	var now := Time.get_ticks_msec()
	var dwell_ok := (now - _variant_last_switch_ms) >= int(V2_VARIANT_DWELL_SECONDS * 1000.0)
	var wanted := _variant
	if _pressure >= V2_ENGAGE_PRESSURE:
		wanted = &"JAZZ"
	elif _pressure < V2_RELAX_PRESSURE:
		wanted = &"ORCH"
	if wanted != _variant and dwell_ok:
		_variant = wanted
		_variant_last_switch_ms = now
		_replay_requested_zone()

func begin_run_silence() -> void:
	## Presence grammar: run entry is authored silence; music enters on
	## engagement (pressure > 0) or after ~15 s.
	_silence_hold = true
	_silence_remaining = V2_SILENCE_ENTRY_SECONDS
	_idle_quiet_elapsed = 0.0
	_idle_faded = false
	_fade_active_lane_out(0.6)

func play_ui_context(context: StringName) -> void:
	if not _v2_loaded or not _v2_ui_contexts.has(context):
		_last_noop_reason = &"missing_ui_context"
		return
	var entry: Dictionary = _v2_ui_contexts[context]
	var zone := _v2_zone_for_cue(str(entry.get("cue", "")))
	var variant := StringName(str(entry.get("variant", "ORCH")))
	match context:
		&"defeat_reflection":
			_ui_one_shot_after_silence(zone, variant, V2_DEFEAT_SILENCE_SECONDS)
		&"victory_sequence":
			_ui_one_shot_after_silence(zone, variant, 0.4)
		_:
			# Looping UI bed (main_menu, shop_ui, ...): plays as a normal zone.
			_ui_override_active = false
			_play_v2_cue(zone, variant, true, false)

func notify_vitals(guard: float, guard_max: float, hp: float, hp_max: float) -> void:
	## Critical-vitals overlay (AMB_03): enters only when guard is broken AND
	## hp is in the bottom third (gate A4 — never a zone, never a currency).
	var critical := guard <= 0.0 and hp_max > 0.0 and hp * 3.0 <= hp_max
	if critical == _vitals_overlay_active:
		return
	_vitals_overlay_active = critical
	_ensure_vitals_lane()
	if critical:
		var path := String(_v2_vitals_paths.get(String(_variant), _v2_vitals_paths.get("ORCH", "")))
		var stream := _load_stream(path, true)
		if stream == null:
			return
		_vitals_lane.stream = stream
		_vitals_lane.volume_db = SILENT_VOLUME_DB
		_vitals_lane.play()
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_vitals_lane, "volume_db", -6.0, 1.2)
	else:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_vitals_lane, "volume_db", SILENT_VOLUME_DB, 1.5)
		tween.tween_callback(func() -> void:
			if _vitals_lane != null:
				_vitals_lane.stop())

func v2_loaded() -> bool:
	return _v2_loaded

func v2_zone_count() -> int:
	return _v2_zones.size()

func v2_active_variant() -> StringName:
	return _variant

func v2_pressure() -> float:
	return _pressure

func _load_v2_cue_table() -> void:
	if not FileAccess.file_exists(V2_CUE_MAP_PATH):
		_v2_loaded = false
		return
	var raw := FileAccess.get_file_as_string(V2_CUE_MAP_PATH)
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		push_warning("AudioDirector: cue_map.json failed to parse; v2 disabled.")
		return
	var data := parsed as Dictionary
	for zone_entry in data.get("zones", []):
		var zone := StringName(str(zone_entry.get("zone", "")))
		var files: Dictionary = zone_entry.get("files", {})
		var record := {
			"rule": str(zone_entry.get("variant_rule", "ORCH")),
			"cue": str(zone_entry.get("cue", "")),
		}
		for variant in ["ORCH", "JAZZ"]:
			var lst: Array = files.get(variant, [])
			if not lst.is_empty():
				record[variant] = _v2_path_for_filename(str(lst[0].get("filename", "")))
		if String(zone) != "" and record.has("ORCH"):
			_v2_zones[zone] = record
	for ui_entry in data.get("ui_contexts", []):
		_v2_ui_contexts[StringName(str(ui_entry.get("context", "")))] = ui_entry
	var vit: Dictionary = data.get("vitals_overlay", {})
	for variant in ["ORCH", "JAZZ"]:
		var lst: Array = (vit.get("files", {}) as Dictionary).get(variant, [])
		if not lst.is_empty():
			_v2_vitals_paths[variant] = _v2_path_for_filename(str(lst[0].get("filename", "")))
	_v2_loaded = not _v2_zones.is_empty()

func _v2_path_for_filename(mp4_name: String) -> String:
	var stem := mp4_name.trim_suffix(".mp4")
	stem = stem.replace(" ", "_").replace("\u2019", "").replace("'", "")
	return V2_AUDIO_DIR + stem + ".ogg"

func _v2_zone_for_cue(cue: String) -> StringName:
	for zone in _v2_zones:
		if str((_v2_zones[zone] as Dictionary).get("cue", "")) == cue:
			return zone
	return StringName(cue)

func _v2_zone_for_state(state: StringName) -> StringName:
	if _v2_zones.has(state):
		return state
	return StringName(V2_STATE_ALIASES.get(state, &""))

func _play_v2_zone(zone: StringName) -> void:
	if _ui_override_active or _silence_hold:
		_last_noop_reason = &"v2_playback_held"
		return
	var record: Dictionary = _v2_zones.get(zone, {})
	var variant := _variant
	var rule := str(record.get("rule", "ORCH"))
	# Fixed-rule zones override the pressure variant.
	if rule == "ORCH":
		variant = &"ORCH"
	elif rule == "JAZZ":
		variant = &"JAZZ"
	if not record.has(String(variant)):
		variant = &"ORCH"
	var immediate := zone == &"REKINDLE_SIEGE"
	_play_v2_cue(zone, variant, true, immediate)

func _play_v2_cue(zone: StringName, variant: StringName, loop: bool, immediate: bool) -> void:
	var record: Dictionary = _v2_zones.get(zone, {})
	var path := String(record.get(String(variant), ""))
	if path.is_empty():
		_last_noop_reason = &"v2_missing_variant_file"
		return
	var stream := _load_stream(path, loop)
	if stream == null:
		_last_noop_reason = &"v2_stream_load_failed"
		return
	var cue_id := StringName("v2:%s:%s" % [zone, variant])
	_set_stream_loop(stream, loop)
	_cue_registry[cue_id] = stream
	_state_cue_ids[zone] = cue_id
	var saved_fade := crossfade_seconds
	if immediate:
		crossfade_seconds = 0.0
	_play_registered_state(zone, cue_id)
	crossfade_seconds = saved_fade

func _replay_requested_zone() -> void:
	var zone := _v2_zone_for_state(_last_zone_request)
	if _v2_loaded and _v2_zones.has(zone):
		_play_v2_zone(zone)

func _ui_one_shot_after_silence(zone: StringName, variant: StringName, silence_seconds: float) -> void:
	_ui_override_active = true
	_fade_active_lane_out(0.5)
	if _ui_override_tween != null:
		_ui_override_tween.kill()
	_ui_override_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ui_override_tween.tween_interval(maxf(silence_seconds, 0.0))
	_ui_override_tween.tween_callback(func() -> void:
		_ui_override_active = false
		_play_v2_cue(zone, variant, false, true))

func _fade_active_lane_out(seconds: float) -> void:
	var player := _active_player()
	if player == null or not player.playing:
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_db", SILENT_VOLUME_DB, maxf(seconds, 0.05))

func _ensure_vitals_lane() -> void:
	if _vitals_lane != null:
		return
	_vitals_lane = AudioStreamPlayer.new()
	_vitals_lane.name = "VitalsOverlayLane"
	_vitals_lane.bus = String(MUSIC_BUS)
	_vitals_lane.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_vitals_lane)

func _load_stream(path: String, loop: bool) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var stream := ResourceLoader.load(path) as AudioStream
	if stream != null:
		_set_stream_loop(stream, loop)
	return stream
