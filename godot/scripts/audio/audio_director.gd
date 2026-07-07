extends Node

const MUSIC_STATE_HUB: StringName = &"HUB"
const MUSIC_STATE_COMBAT: StringName = &"COMBAT"
const MUSIC_STATE_CLEARED: StringName = &"CLEARED"

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const VOICE_BUS := &"VoiceReserved"
const ACTIVE_VOLUME_DB := 0.0
const SILENT_VOLUME_DB := -80.0
const SFX_POOL_SIZE := 8
const VOICE_DUCK_DB := 4.0
const VOICE_DIR := "res://audio/voice/"

## Voice line manifest: line_id -> variant count. One variant resolves to
## <line_id>.ogg; N > 1 resolves to <line_id>_1.ogg … <line_id>_N.ogg with a
## random pick. Files land later (Margin narrator + Custodian boss are in
## generation); missing files are a silent no-op — the seam ships dark.
## The spoken vigil (scripts: docs/hades-pivot/design/voice-scripts-v1.md;
## casting/provenance: audio lab 2026-07-06-voice-batch).
const VOICE_LINE_MANIFEST := {
	&"margin_intro": 3,
	&"margin_sendoff": 3,
	&"margin_death": 3,
	&"margin_victory": 2,
	&"margin_boss_warning": 1,
	&"margin_return": 2,
	&"pattern_intro": 2,
	&"pattern_phase_1": 1,
	&"pattern_phase_2": 1,
	&"pattern_phase_3": 1,
	&"pattern_player_defeat": 1,
	&"pattern_death": 1,
	# Reserved (unrecorded — future codex reading; also the dark-line test hook).
	&"margin_codex_entry": 1,
}

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
const V2_SILENCE_ENTRY_SECONDS := 15.0
const V2_DEFEAT_SILENCE_SECONDS := 2.5
## Long-form pacing (2026-07-06 playtest): a run picks its musical arc once —
## SEG A (JAZZ) → BRG bridge (JAZZ) → SEG B (JAZZ) — and rooms never retrigger.
## A SEG must play at least this fraction of its length before a soft milestone
## (room-transition arc advance) may replace it; hard milestones always cut.
const V2_MIN_PLAY_FRACTION := 0.65
## Combat-stretch JAZZ pool: the pressure-led SEGs from the cue map.
const V2_ARC_SEG_POOL: Array[StringName] = [&"ROAM", &"RUINS", &"KEEPER", &"GILDED", &"TRIAL"]
## Combat-band bridges (calm→engage, engage→high, high-band evasion).
const V2_ARC_BRIDGE_POOL: Array[String] = ["BRG_04", "BRG_08", "BRG_09"]

## Legacy EL demo loops were demoted and deleted (soundtrack v2 is the music
## source of truth); the register_cue/bind_music_state_cue seam remains for
## scene-layer cues and tests.
const MUSIC_CUE_MANIFEST := {}

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
var _v2_bridges: Dictionary = {}        # bridge id -> {"ORCH": path, "JAZZ": path}
var _v2_ui_contexts: Dictionary = {}    # context -> {"cue": zone-ish id, "variant": String}
var _v2_vitals_paths: Dictionary = {}   # variant -> path (AMB_03)
var _v2_loaded := false
var _pressure := 0.0
var _variant: StringName = &"ORCH"
var _silence_hold := false
var _silence_remaining := 0.0
var _arc_active := false
var _arc_stage: StringName = &""        # "" (pending) / SEG_A / BRIDGE / SEG_B
var _arc_seg_a: StringName = &""
var _arc_seg_b: StringName = &""
var _arc_bridge_id := ""
var _arc_rng := RandomNumberGenerator.new()
var _cue_started_ms := 0
var _active_stream_length := 0.0
var _ui_override_active := false
var _ui_override_tween: Tween = null
var _vitals_lane: AudioStreamPlayer = null
var _vitals_overlay_active := false
var _last_zone_request: StringName = &""

# ── Voice seam (Margin narrator + Custodian boss; VoiceReserved bus) ──────
var _voice_player: AudioStreamPlayer = null
var _voice_registry: Dictionary = {}    # line_id -> Array[AudioStream]
var _voice_rng := RandomNumberGenerator.new()
var _voice_speaking := false
var _last_voice_line: StringName = &""
var _last_voice_variant := -1
var _music_ducked := false
var _music_duck_base_db := 0.0

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
	# The arc bridge plays once; when it ends, SEG B carries the rest of the stretch.
	if _arc_active and _arc_stage == &"BRIDGE" and not _is_fading \
			and not _silence_hold and not _ui_override_active \
			and not _active_player().playing:
		_arc_play_stage(&"SEG_B")

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
	if _v2_loaded:
		# Hard milestones cut through everything and end the run arc.
		if v2_zone == &"REKINDLE_SIEGE":
			_arc_end()
			_play_v2_zone(v2_zone)
			return
		if state == &"HUB":
			_arc_end()
			_play_v2_zone(v2_zone)
			return
		# Run rooms never retrigger music: the run's arc owns the stretch.
		if state == &"COMBAT" or state == &"SHOP" or state == &"REST":
			if not _arc_active:
				_arc_roll()
			_arc_handle_room_request()
			return
		if _v2_zones.has(v2_zone):
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
		"v2_bridge_count": _v2_bridges.size(),
		"v2_variant": String(_variant),
		"v2_pressure": _pressure,
		"v2_silence_hold": _silence_hold,
		"v2_arc_active": _arc_active,
		"v2_arc_stage": String(_arc_stage),
		"v2_arc_seg_a": String(_arc_seg_a),
		"v2_arc_seg_b": String(_arc_seg_b),
		"v2_arc_bridge": _arc_bridge_id,
		"last_voice_line": String(_last_voice_line),
		"last_voice_variant": _last_voice_variant,
		"voice_speaking": _voice_speaking,
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
	_cue_started_ms = Time.get_ticks_msec()
	_active_stream_length = stream.get_length()
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
	## Pressure no longer flips variants (2026-07-06 playtest: shifts were far
	## too frequent). It only releases the run-entry silence so the arc's first
	## SEG lands on engagement; the combat stretch then lives in JAZZ.
	_pressure = clampf(level, 0.0, 1.0)
	if _silence_hold and _pressure > 0.0:
		_silence_hold = false
		_replay_requested_zone()

func begin_run_silence() -> void:
	## Presence grammar: run entry is authored silence; music enters on
	## engagement (pressure > 0) or after ~15 s. Run start is also the one
	## moment the run's musical arc is rolled.
	_silence_hold = true
	_silence_remaining = V2_SILENCE_ENTRY_SECONDS
	if _v2_loaded:
		_arc_roll()
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
			_arc_end()
			_ui_one_shot_after_silence(zone, variant, V2_DEFEAT_SILENCE_SECONDS)
		&"victory_sequence":
			_arc_end()
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

func play_voice_line(line_id: StringName) -> void:
	## One line at a time on the VoiceReserved bus; a new line interrupts the
	## old. Music ducks by VOICE_DUCK_DB while speaking and restores after.
	_last_noop_reason = &""
	if String(line_id).is_empty():
		_last_noop_reason = &"empty_voice_line"
		return
	var streams := _voice_streams_for(line_id)
	if streams.is_empty():
		if _voice_registry.has(line_id) or VOICE_LINE_MANIFEST.has(line_id):
			_last_noop_reason = &"missing_voice_line"
		else:
			_last_noop_reason = &"unknown_voice_line"
		return
	var index := 0
	if streams.size() > 1:
		index = _voice_rng.randi_range(0, streams.size() - 1)
	_ensure_voice_lane()
	_voice_player.stop()
	_voice_player.stream = streams[index]
	_voice_player.play()
	_voice_speaking = true
	_last_voice_line = line_id
	_last_voice_variant = index
	_duck_music_for_voice(true)

func register_voice_line(line_id: StringName, streams: Array) -> void:
	## Runtime drop-in seam (and the test hook): registered streams win over
	## the manifest paths for this line id.
	if String(line_id).is_empty() or streams.is_empty():
		return
	_voice_registry[line_id] = streams

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
	for bridge_entry in data.get("bridges", []):
		var bridge_id := str(bridge_entry.get("id", ""))
		var bridge_files: Dictionary = bridge_entry.get("files", {})
		var bridge_record := {}
		for variant in ["ORCH", "JAZZ"]:
			var bridge_list: Array = bridge_files.get(variant, [])
			if not bridge_list.is_empty():
				bridge_record[variant] = _v2_path_for_filename(str(bridge_list[0].get("filename", "")))
		if not bridge_id.is_empty() and not bridge_record.is_empty():
			_v2_bridges[bridge_id] = bridge_record
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
	_play_v2_path(StringName("v2:%s:%s" % [zone, variant]), path, loop, immediate, zone)

func _play_v2_path(cue_id: StringName, path: String, loop: bool, immediate: bool, state: StringName = &"") -> void:
	var stream := _load_stream(path, loop)
	if stream == null:
		_last_noop_reason = &"v2_stream_load_failed"
		return
	_set_stream_loop(stream, loop)
	_cue_registry[cue_id] = stream
	var play_state := state if String(state) != "" else cue_id
	_state_cue_ids[play_state] = cue_id
	var saved_fade := crossfade_seconds
	if immediate:
		crossfade_seconds = 0.0
	_play_registered_state(play_state, cue_id)
	crossfade_seconds = saved_fade

func _replay_requested_zone() -> void:
	if _arc_active:
		if _arc_stage == &"":
			_arc_play_stage(&"SEG_A")
		return
	var zone := _v2_zone_for_state(_last_zone_request)
	if _v2_loaded and _v2_zones.has(zone):
		_play_v2_zone(zone)

# ── Run arc: SEG A → bridge → SEG B, rolled once per run ──────────────────

func _arc_roll() -> void:
	var seg_pool: Array[StringName] = []
	for zone in V2_ARC_SEG_POOL:
		if _v2_zones.has(zone) and (_v2_zones[zone] as Dictionary).has("JAZZ"):
			seg_pool.append(zone)
	var bridge_pool: Array[String] = []
	for bridge_id in V2_ARC_BRIDGE_POOL:
		if _v2_bridges.has(bridge_id) and (_v2_bridges[bridge_id] as Dictionary).has("JAZZ"):
			bridge_pool.append(bridge_id)
	if seg_pool.size() < 2 or bridge_pool.is_empty():
		return
	_arc_rng.randomize()
	_arc_seg_a = seg_pool[_arc_rng.randi_range(0, seg_pool.size() - 1)]
	seg_pool.erase(_arc_seg_a)
	_arc_seg_b = seg_pool[_arc_rng.randi_range(0, seg_pool.size() - 1)]
	_arc_bridge_id = bridge_pool[_arc_rng.randi_range(0, bridge_pool.size() - 1)]
	_arc_active = true
	_arc_stage = &""
	_variant = &"JAZZ"

func _arc_end() -> void:
	_arc_active = false
	_arc_stage = &""
	_variant = &"ORCH"

func _arc_handle_room_request() -> void:
	if _silence_hold:
		_last_noop_reason = &"v2_playback_held"
		return
	match _arc_stage:
		&"":
			_arc_play_stage(&"SEG_A")
		&"SEG_A":
			# Room transitions are soft milestones: advance only once the
			# composition has had room to breathe (minimum-play guard).
			if _min_play_satisfied():
				_arc_play_stage(&"BRIDGE")
			else:
				_last_noop_reason = &"v2_arc_hold"
		_:
			_last_noop_reason = &"v2_arc_hold"

func _arc_play_stage(stage: StringName) -> void:
	match stage:
		&"SEG_A":
			_play_v2_cue(_arc_seg_a, &"JAZZ", true, false)
		&"BRIDGE":
			var record: Dictionary = _v2_bridges.get(_arc_bridge_id, {})
			var path := String(record.get("JAZZ", ""))
			if path.is_empty():
				_play_v2_cue(_arc_seg_b, &"JAZZ", true, false)
				_arc_stage = &"SEG_B"
				return
			_play_v2_path(StringName("v2:brg:%s:JAZZ" % _arc_bridge_id), path, false, false)
		&"SEG_B":
			_play_v2_cue(_arc_seg_b, &"JAZZ", true, false)
	_arc_stage = stage

func _min_play_satisfied() -> bool:
	if _active_stream_length <= 0.0:
		return true
	var elapsed := float(Time.get_ticks_msec() - _cue_started_ms) / 1000.0
	return elapsed >= V2_MIN_PLAY_FRACTION * _active_stream_length

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

func _voice_streams_for(line_id: StringName) -> Array:
	if _voice_registry.has(line_id):
		return _voice_registry[line_id]
	var count := int(VOICE_LINE_MANIFEST.get(line_id, 0))
	if count <= 0:
		return []
	var streams: Array = []
	for variant_index in range(1, count + 1):
		var path := (VOICE_DIR + String(line_id) + ".ogg") if count == 1 \
				else ("%s%s_%d.ogg" % [VOICE_DIR, line_id, variant_index])
		var stream := _load_stream(path, false)
		if stream != null:
			streams.append(stream)
	if not streams.is_empty():
		_voice_registry[line_id] = streams
	return streams

func _ensure_voice_lane() -> void:
	if _voice_player != null:
		return
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoiceLane"
	_voice_player.bus = String(VOICE_BUS)
	_voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_voice_player.finished.connect(_on_voice_finished)
	add_child(_voice_player)

func _on_voice_finished() -> void:
	_voice_speaking = false
	if _voice_player != null:
		_voice_player.stop()
	_duck_music_for_voice(false)

func _duck_music_for_voice(speaking: bool) -> void:
	var music_index := AudioServer.get_bus_index(MUSIC_BUS)
	if music_index < 0:
		return
	if speaking:
		if _music_ducked:
			return
		_music_ducked = true
		_music_duck_base_db = AudioServer.get_bus_volume_db(music_index)
		AudioServer.set_bus_volume_db(music_index, _music_duck_base_db - VOICE_DUCK_DB)
	elif _music_ducked:
		_music_ducked = false
		AudioServer.set_bus_volume_db(music_index, _music_duck_base_db)

func _exit_tree() -> void:
	# The duck edits global bus state; never leave it applied past this node.
	_duck_music_for_voice(false)

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
