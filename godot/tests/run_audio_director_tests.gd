extends SceneTree

# Headless tests for HZ-104 AudioDirector runtime seam.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata-104 --log-file /tmp/codex-godot-userdata-104/logs/godot.log --path godot --script res://tests/run_audio_director_tests.gd

const AudioDirectorScript := preload("res://scripts/audio/audio_director.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running AudioDirector tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_bus_layout_has_contract_buses()
	await _test_master_bus_uses_hard_limiter()
	await _test_music_bus_uses_sidechain_ducking()
	await _test_manifest_music_cues_register_and_loop()
	await _test_v2_run_arc_persists_across_rooms()
	await _test_v2_arc_min_play_guard_and_bridge()
	await _test_v2_milestones_cut_through_guard()
	await _test_v2_vitals_overlay_and_defeat_sequence()
	await _test_voice_seam_missing_and_unknown_lines_noop()
	await _test_voice_duck_and_restore_with_interrupt()
	await _test_voice_variant_selection_is_seed_deterministic()
	await _test_notify_event_known_unknown_and_round_robin_pool()
	await _test_contract_seam_and_describe_surface()
	await _test_registered_state_crossfades_to_target_cue()
	await _test_unknown_cue_noops_without_stopping_current_music()
	await _test_duplicate_state_is_idempotent()
	await _test_crossfade_progresses_while_tree_is_paused()
	await _test_registering_active_cue_swaps_stream_in_place()
	await _test_cueless_state_is_headless_safe()
	await _test_autoload_registration()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => AudioDirector failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _check_almost_eq(desc: String, actual: float, expected: float, tolerance: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, tolerance], absf(actual - expected) <= tolerance)

func _test_bus_layout_has_contract_buses() -> void:
	for bus_name in [&"Music", &"Ambience", &"SFX", &"UI", &"Voice"]:
		_check("bus layout exposes %s bus" % bus_name, AudioServer.get_bus_index(bus_name) >= 0)

func _test_master_bus_uses_hard_limiter() -> void:
	var master_index := AudioServer.get_bus_index(&"Master")
	_check("Master bus exists", master_index >= 0)
	if master_index < 0:
		return
	_check("Master bus has at least one effect", AudioServer.get_bus_effect_count(master_index) > 0)
	if AudioServer.get_bus_effect_count(master_index) <= 0:
		return

	var effect := AudioServer.get_bus_effect(master_index, 0)
	_check("Master bus effect 0 is AudioEffectHardLimiter", effect is AudioEffectHardLimiter)
	if effect is AudioEffectHardLimiter:
		var hard_limiter := effect as AudioEffectHardLimiter
		_check_almost_eq("hard limiter ceiling_db matches contract", hard_limiter.ceiling_db, -0.5)
		_check_almost_eq("hard limiter pre_gain_db maps contract threshold", hard_limiter.pre_gain_db, -1.0)


func _test_music_bus_uses_sidechain_ducking() -> void:
	var music_index := AudioServer.get_bus_index(&"Music")
	_check("Music bus exists for sidechain ducking", music_index >= 0)
	if music_index < 0:
		return
	_check_eq("Music bus keeps inherited resting volume", AudioServer.get_bus_volume_db(music_index), -14.0)
	_check("Music bus has Voice + SFX compressors", AudioServer.get_bus_effect_count(music_index) >= 2)
	if AudioServer.get_bus_effect_count(music_index) < 2:
		return
	var voice_effect := AudioServer.get_bus_effect(music_index, 0)
	var sfx_effect := AudioServer.get_bus_effect(music_index, 1)
	_check("Music effect 0 is the Voice sidechain compressor", voice_effect is AudioEffectCompressor)
	_check("Music effect 1 is the SFX sidechain compressor", sfx_effect is AudioEffectCompressor)
	if voice_effect is AudioEffectCompressor:
		var voice_compressor := voice_effect as AudioEffectCompressor
		_check_eq("Voice compressor sidechains from Voice", voice_compressor.sidechain, &"Voice")
		_check("Voice compressor is stronger than 6:1", voice_compressor.ratio >= 6.0)
		_check("Voice compressor attacks quickly", voice_compressor.attack_us <= 5000.0)
	if sfx_effect is AudioEffectCompressor:
		var sfx_compressor := sfx_effect as AudioEffectCompressor
		_check_eq("SFX compressor sidechains from SFX", sfx_compressor.sidechain, &"SFX")
		_check("SFX compressor is moderate", sfx_compressor.ratio >= 2.0 and sfx_compressor.ratio <= 4.0)

func _test_manifest_music_cues_register_and_loop() -> void:
	var director := await _new_director()
	var desc: Dictionary = director.describe()
	# Soundtrack v2: the EL demo loops are demoted; the 61-cue score table
	# (audio/music/soundtrack_v2/cue_map.json) is the music source of truth.
	_check("v2 cue table loaded", desc.get("v2_loaded", false) == true)
	_check_eq("v2 table carries all fifteen zones", int(desc.get("v2_zone_count", 0)), 15)
	for zone in ["SANCTUARY", "ROAM", "REKINDLE_SIEGE", "TRIAL", "ORIGIN"]:
		var record: Dictionary = director._v2_zones.get(StringName(zone), {})
		_check("v2 zone %s has an ORCH file on disk" % zone,
			record.has("ORCH") and ResourceLoader.exists(String(record["ORCH"])))

	_request_zone_state(director, &"HUB")
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var hub_desc: Dictionary = director.describe()
	_check_eq("HUB routes to the SANCTUARY v2 cue", hub_desc.get("active_cue_id", ""), "v2:SANCTUARY:ORCH")
	var hub_player := director.get_node_or_null(String(hub_desc.get("active_lane", ""))) as AudioStreamPlayer
	_check("HUB v2 request loads a real AudioStream", hub_player != null and hub_player.stream != null)
	_check("HUB v2 stream loops", hub_player != null and _stream_loops(hub_player.stream))

	await _cleanup_director(director)

func _test_v2_run_arc_persists_across_rooms() -> void:
	var director := await _new_director()
	director.begin_run_silence()
	var rolled: Dictionary = director.describe()
	_check("run start rolls a musical arc", rolled.get("v2_arc_active", false) == true)
	var seg_a := String(rolled.get("v2_arc_seg_a", ""))
	var seg_b := String(rolled.get("v2_arc_seg_b", ""))
	_check("arc SEG A comes from the JAZZ combat pool", director.V2_ARC_SEG_POOL.has(StringName(seg_a)))
	_check("arc SEG B comes from the JAZZ combat pool", director.V2_ARC_SEG_POOL.has(StringName(seg_b)))
	_check("arc SEG B differs from SEG A", seg_a != seg_b)
	_check("arc picks a bridge", String(rolled.get("v2_arc_bridge", "")) != "")

	_request_zone_state(director, &"COMBAT")
	_check_eq("silence hold blocks zone playback", String(director.describe().get("last_noop_reason", "")), "v2_playback_held")
	director.set_pressure(0.5)
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var desc: Dictionary = director.describe()
	_check_eq("engagement enters the arc's SEG A in JAZZ", String(desc.get("active_cue_id", "")), "v2:%s:JAZZ" % seg_a)
	_check_eq("combat stretch lives in the JAZZ variant", desc.get("v2_variant", ""), "JAZZ")
	var crossfades := int(desc.get("crossfade_count", -1))

	# Rooms do NOT retrigger music: combat, shop, and rest requests all hold the arc.
	for room_state in [&"COMBAT", &"SHOP", &"REST", &"COMBAT"]:
		_request_zone_state(director, room_state)
	await process_frame
	var held: Dictionary = director.describe()
	_check_eq("room churn keeps the arc's SEG A playing", String(held.get("active_cue_id", "")), "v2:%s:JAZZ" % seg_a)
	_check_eq("room churn never crossfades", int(held.get("crossfade_count", -1)), crossfades)
	_check_eq("room hold records its no-op reason", String(held.get("last_noop_reason", "")), "v2_arc_hold")
	_check_eq("zone requests are still recorded for the seam", String(held.get("requested_music_state", "")), "COMBAT")

	# Pressure swings no longer flip the variant mid-track.
	director.set_pressure(0.0)
	director.set_pressure(0.9)
	await process_frame
	var after_pressure: Dictionary = director.describe()
	_check_eq("pressure swings leave the arc track alone", String(after_pressure.get("active_cue_id", "")), "v2:%s:JAZZ" % seg_a)
	_check_eq("pressure swings do not crossfade", int(after_pressure.get("crossfade_count", -1)), crossfades)
	await _cleanup_director(director)

func _test_v2_arc_min_play_guard_and_bridge() -> void:
	var director := await _new_director()
	director.begin_run_silence()
	director.set_pressure(0.5)
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var desc: Dictionary = director.describe()
	var seg_a := String(desc.get("v2_arc_seg_a", ""))
	var seg_b := String(desc.get("v2_arc_seg_b", ""))
	var bridge := String(desc.get("v2_arc_bridge", ""))
	_check("arc SEG A has a real track length", float(director._active_stream_length) > 30.0)

	# A room transition before the minimum-play point must NOT advance the arc.
	_request_zone_state(director, &"COMBAT")
	await process_frame
	_check_eq("early room transition holds SEG A (min-play guard)", String(director.describe().get("active_cue_id", "")), "v2:%s:JAZZ" % seg_a)

	# Simulate the track having breathed past the minimum-play fraction.
	director._cue_started_ms = Time.get_ticks_msec() - int(0.7 * director._active_stream_length * 1000.0)
	_request_zone_state(director, &"COMBAT")
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var brg_desc: Dictionary = director.describe()
	_check_eq("post-min-play room transition enters the JAZZ bridge", String(brg_desc.get("active_cue_id", "")), "v2:brg:%s:JAZZ" % bridge)
	_check_eq("bridge is the arc's connective stage", String(brg_desc.get("v2_arc_stage", "")), "BRIDGE")
	var bridge_player := director.get_node_or_null(String(brg_desc.get("active_lane", ""))) as AudioStreamPlayer
	_check("bridge plays once (non-looping)", bridge_player != null and not _stream_loops(bridge_player.stream))

	# When the bridge finishes, SEG B takes over and loops.
	if bridge_player != null:
		bridge_player.stop()
	await process_frame
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var seg_b_desc: Dictionary = director.describe()
	_check_eq("bridge resolves into the arc's SEG B", String(seg_b_desc.get("active_cue_id", "")), "v2:%s:JAZZ" % seg_b)
	var seg_b_player := director.get_node_or_null(String(seg_b_desc.get("active_lane", ""))) as AudioStreamPlayer
	_check("SEG B loops for the rest of the stretch", seg_b_player != null and _stream_loops(seg_b_player.stream))

	# Further rooms hold on SEG B; the arc has no fourth stage.
	director._cue_started_ms = Time.get_ticks_msec() - int(0.9 * director._active_stream_length * 1000.0)
	_request_zone_state(director, &"COMBAT")
	await process_frame
	_check_eq("SEG B holds through remaining rooms", String(director.describe().get("active_cue_id", "")), "v2:%s:JAZZ" % seg_b)
	await _cleanup_director(director)

func _test_v2_milestones_cut_through_guard() -> void:
	var director := await _new_director()
	director.begin_run_silence()
	director.set_pressure(0.5)
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var seg_a := String(director.describe().get("v2_arc_seg_a", ""))
	_check_eq("arc is playing SEG A before the boss", String(director.describe().get("active_cue_id", "")), "v2:%s:JAZZ" % seg_a)

	# BOSS is a hard milestone: it cuts immediately even though SEG A is fresh.
	_request_zone_state(director, &"BOSS")
	var boss_desc: Dictionary = director.describe()
	_check("BOSS routes to REKINDLE_SIEGE", String(boss_desc.get("active_cue_id", "")).begins_with("v2:REKINDLE_SIEGE"))
	_check_almost_eq("siege entry is an immediate cut", float((boss_desc.get("last_crossfade", {}) as Dictionary).get("duration", -1.0)), 0.0)
	_check("BOSS milestone ends the run arc", boss_desc.get("v2_arc_active", true) == false)

	# Hub return is a hard milestone too, and lands in ORCH.
	_request_zone_state(director, &"HUB")
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var hub_desc: Dictionary = director.describe()
	_check_eq("hub return plays the sanctuary in ORCH", String(hub_desc.get("active_cue_id", "")), "v2:SANCTUARY:ORCH")
	_check_eq("hub rests in the ORCH variant", hub_desc.get("v2_variant", ""), "ORCH")

	# In the hub, pressure noise must not restart or flip anything.
	var crossfades := int(hub_desc.get("crossfade_count", -1))
	director.set_pressure(0.9)
	director.set_pressure(0.0)
	await process_frame
	_check_eq("hub ignores pressure churn", int(director.describe().get("crossfade_count", -1)), crossfades)
	await _cleanup_director(director)

func _test_v2_vitals_overlay_and_defeat_sequence() -> void:
	var director := await _new_director()
	director.notify_vitals(0.0, 10.0, 3.0, 10.0)
	_check("critical vitals raise the AMB_03 overlay", director.describe().get("v2_vitals_overlay", false) == true)
	director.notify_vitals(5.0, 10.0, 8.0, 10.0)
	_check("recovery lowers the overlay", director.describe().get("v2_vitals_overlay", true) == false)
	director.play_ui_context(&"defeat_reflection")
	_check("defeat reflection holds a UI override", director.describe().get("v2_ui_override", false) == true)
	await _wait_seconds(3.2)
	var after: Dictionary = director.describe()
	_check_eq("defeat plays SEG_06 ORCH once", String(after.get("active_cue_id", "")), "v2:RUINS:ORCH")
	# The override HOLDS while the reflection piece plays (no doubling with the
	# hub zone — Shane playtest 2); it releases on the one-shot's finished.
	_check("defeat override holds through the reflection one-shot", after.get("v2_ui_override", false) == true)
	director._on_ui_one_shot_finished()
	_check("override releases when the reflection finishes", director.describe().get("v2_ui_override", true) == false)
	await _cleanup_director(director)

func _test_voice_seam_missing_and_unknown_lines_noop() -> void:
	var director := await _new_director()
	_check("AudioDirector exposes play_voice_line seam", director.has_method(&"play_voice_line"))
	var before: Dictionary = director.describe()
	_check_eq("describe exposes last_voice_line", String(before.get("last_voice_line", "?")), "")
	_check_eq("describe exposes voice_speaking", before.get("voice_speaking", true), false)

	# Manifest-known line whose files do not exist yet (reserved dark entry).
	director.play_voice_line(&"margin_reserved_dark")
	await process_frame
	var missing: Dictionary = director.describe()
	_check_eq("manifest line with no files is a silent no-op", String(missing.get("last_noop_reason", "")), "missing_voice_line")
	_check_eq("missing files leave voice_speaking false", missing.get("voice_speaking", true), false)

	director.play_voice_line(&"no_such_line")
	_check_eq("unknown line records its no-op reason", String(director.describe().get("last_noop_reason", "")), "unknown_voice_line")

	# The manifest carries the announced speakers.
	_check("manifest knows the Margin death variants", int(director.VOICE_LINE_MANIFEST.get(&"margin_death", 0)) == 3)
	_check("manifest knows a Custodian line", int(director.VOICE_LINE_MANIFEST.get(&"pattern_intro", 0)) >= 1)
	await _cleanup_director(director)

func _test_voice_duck_and_restore_with_interrupt() -> void:
	var director := await _new_director()
	var music_index := AudioServer.get_bus_index(&"Music")
	var base_db := AudioServer.get_bus_volume_db(music_index)

	var first := _new_stream()
	var second := _new_stream()
	director.register_voice_line(&"pattern_intro", [first])
	director.register_voice_line(&"margin_codex_entry", [second])

	director.play_voice_line(&"pattern_intro")
	await process_frame
	var speaking: Dictionary = director.describe()
	_check_eq("voice line marks the director speaking", speaking.get("voice_speaking", false), true)
	_check_eq("last_voice_line records the line id", String(speaking.get("last_voice_line", "")), "pattern_intro")
	_check("voice lane rides the Voice bus", director._voice_player != null and director._voice_player.bus == "Voice")
	_check("voice lane is playing the registered stream", director._voice_player.stream == first)
	_check_almost_eq("voice playback leaves Music bus at resting gain", AudioServer.get_bus_volume_db(music_index), base_db)

	# A new line interrupts the old one; the duck holds without stacking.
	director.play_voice_line(&"margin_codex_entry")
	await process_frame
	_check("new line interrupts the previous stream", director._voice_player.stream == second)
	_check_almost_eq("interrupt keeps Music bus gain unchanged", AudioServer.get_bus_volume_db(music_index), base_db)

	director._voice_player.emit_signal(&"finished")
	await process_frame
	var done: Dictionary = director.describe()
	_check_eq("finished line clears voice_speaking", done.get("voice_speaking", true), false)
	_check_almost_eq("finished line leaves the Music bus at rest", AudioServer.get_bus_volume_db(music_index), base_db)
	await _cleanup_director(director)
	_check_almost_eq("director teardown leaves the Music bus at rest", AudioServer.get_bus_volume_db(music_index), base_db)

func _test_voice_variant_selection_is_seed_deterministic() -> void:
	var director := await _new_director()
	var variants: Array[AudioStream] = [_new_stream(), _new_stream(), _new_stream()]
	director.register_voice_line(&"margin_death", variants)

	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 20260706
	var expected_index := expected_rng.randi_range(0, variants.size() - 1)

	director._voice_rng.seed = 20260706
	director.play_voice_line(&"margin_death")
	await process_frame
	_check("seeded rng picks the expected variant", director._voice_player.stream == variants[expected_index])
	_check_eq("describe exposes the picked variant index", int(director.describe().get("last_voice_variant", -1)), expected_index)
	await _cleanup_director(director)

func _test_notify_event_known_unknown_and_round_robin_pool() -> void:
	var director := await _new_director()
	_check("AudioDirector exposes notify_event seam", director.has_method(&"notify_event"))
	var before: Dictionary = director.describe()
	var initial_count := int(before.get("sfx_play_count", -1))
	_check_eq("SFX manifest registers thirteen events", int(before.get("sfx_registered_event_count", -1)), 13)
	_check_eq("UI manifest registers one event", int(before.get("ui_registered_event_count", -1)), 1)
	_check_eq("music sting manifest registers one event", int(before.get("music_sting_registered_event_count", -1)), 1)
	_check_eq("SFX pool preallocates eight players", int(before.get("sfx_pool_size", -1)), 8)

	if director.has_method(&"notify_event"):
		director.call(&"notify_event", &"unknown_audio_event")
	await process_frame
	var unknown_desc: Dictionary = director.describe()
	_check_eq("unknown SFX event is a silent no-op", int(unknown_desc.get("sfx_play_count", -1)), initial_count)
	_check_eq("unknown SFX event records no-op reason", unknown_desc.get("last_noop_reason", ""), "unknown_audio_event")

	var events: Array[StringName] = [
		&"melee_hit",
		&"enemy_death",
		&"surge_burst",
		&"cast_shot",
		&"guard_hit",
		&"door_open",
		&"boon_pickup",
		&"dash_whoosh",
		&"boss_telegraph",
	]
	for event in events:
		if director.has_method(&"notify_event"):
			director.call(&"notify_event", event)
	await process_frame

	var after: Dictionary = director.describe()
	_check_eq("known SFX events advance the pool", int(after.get("sfx_play_count", -1)), initial_count + events.size())
	_check_eq("round-robin wraps to the first SFX lane after eight plays", after.get("last_sfx_player", ""), "SfxLane1")
	_check_eq("last known SFX event is recorded", after.get("last_sfx_event", ""), "boss_telegraph")

	director.call(&"notify_event", &"ui_click")
	await process_frame
	_check_eq("UI click routes through the UI event seam", director.describe().get("last_ui_event", ""), "ui_click")
	_check("UI click uses the UI bus", director._ui_player != null and director._ui_player.bus == "UI")
	_check_eq("UI click does not increment SFX play count", int(director.describe().get("sfx_play_count", -1)), initial_count + events.size())

	director.call(&"notify_event", &"room_clear")
	await process_frame
	_check_eq("room_clear fires the music sting seam", director.describe().get("last_music_sting_event", ""), "room_clear")
	_check("room_clear sting uses the Music bus", director._music_sting_player != null and director._music_sting_player.bus == "Music")

	await _cleanup_director(director)

func _test_contract_seam_and_describe_surface() -> void:
	var director := await _new_director()
	_check("AudioDirector exposes contract set_zone_state seam", director.has_method(&"set_zone_state"))
	_check("AudioDirector keeps deprecated set_music_state alias", director.has_method(&"set_music_state"))
	director.bind_music_state_cue(&"TEST_A", &"music_hub")
	director.bind_music_state_cue(&"TEST_B", &"music_combat")
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"TEST_A")
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var hub_desc: Dictionary = director.describe()
	_check_eq("describe reports current state before transition", hub_desc.get("current_state", ""), "TEST_A")
	_check_eq("describe reports active cue id before transition", hub_desc.get("active_cue_id", ""), "music_hub")
	_check("describe exposes per-bus mix dictionary", hub_desc.get("bus_mix", null) is Dictionary)
	if hub_desc.get("bus_mix", null) is Dictionary:
		var bus_mix := hub_desc["bus_mix"] as Dictionary
		_check("describe bus mix includes Music volume_db", bus_mix.has("Music") and bus_mix["Music"].has("volume_db"))
	_check_eq("describe reports not fading before transition", hub_desc.get("fading", null), false)

	_request_zone_state(director, &"TEST_B")
	var mid_desc: Dictionary = director.describe()
	_check_eq("describe reports current state during transition", mid_desc.get("current_state", ""), "TEST_B")
	_check_eq("describe reports active cue id during transition", mid_desc.get("active_cue_id", ""), "music_combat")
	_check_eq("describe reports fading during transition", mid_desc.get("fading", null), true)

	await _wait_seconds(director.crossfade_seconds + 0.05)
	var after_desc: Dictionary = director.describe()
	_check_eq("describe keeps current state after transition", after_desc.get("current_state", ""), "TEST_B")
	_check_eq("describe keeps active cue id after transition", after_desc.get("active_cue_id", ""), "music_combat")
	_check_eq("describe reports not fading after transition", after_desc.get("fading", null), false)

	await _cleanup_director(director)

func _test_registered_state_crossfades_to_target_cue() -> void:
	var director := await _new_director()
	director.bind_music_state_cue(&"TEST_A", &"music_hub")
	director.bind_music_state_cue(&"TEST_B", &"music_combat")
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"TEST_A")
	await process_frame
	var hub_desc: Dictionary = director.describe()
	_check_eq("TEST_A request becomes active state", hub_desc["active_music_state"], "TEST_A")
	_check_eq("TEST_A uses registered hub cue", hub_desc["active_cue_id"], "music_hub")

	_request_zone_state(director, &"TEST_B")
	var combat_desc: Dictionary = director.describe()
	var last_crossfade: Dictionary = combat_desc["last_crossfade"]
	_check_eq("TEST_B request becomes requested state", combat_desc["requested_music_state"], "TEST_B")
	_check_eq("TEST_B immediately targets combat cue", combat_desc["active_cue_id"], "music_combat")
	_check_eq("crossfade records outgoing hub cue", last_crossfade["from_cue_id"], "music_hub")
	_check_eq("crossfade records incoming combat cue", last_crossfade["to_cue_id"], "music_combat")
	_check_eq("crossfade fades previous lane down", last_crossfade["from_target_db"], -80.0)
	_check_eq("crossfade fades next lane up", last_crossfade["to_target_db"], 0.0)
	_check_eq("state switch increments crossfade count", combat_desc["crossfade_count"], 2)

	await _cleanup_director(director)

func _test_unknown_cue_noops_without_stopping_current_music() -> void:
	var director := await _new_director()
	director.bind_music_state_cue(&"TEST_A", &"music_hub")
	director.register_cue(&"music_hub", _new_stream())
	_request_zone_state(director, &"TEST_A")
	await process_frame
	var before: Dictionary = director.describe()

	_request_zone_state(director, &"NO_SUCH_STATE")
	await process_frame
	var after: Dictionary = director.describe()
	_check_eq("unknown state leaves active state unchanged", after["active_music_state"], "TEST_A")
	_check_eq("unknown state leaves active cue unchanged", after["active_cue_id"], before["active_cue_id"])
	_check_eq("unknown state does not crossfade", after["crossfade_count"], before["crossfade_count"])
	_check_eq("unknown state records no-op reason", after["last_noop_reason"], "missing_state_cue")

	_request_zone_state(director, &"CLEARED")
	await process_frame
	var cleared: Dictionary = director.describe()
	_check_eq("v2 CLEARED is pressure-only (zone unchanged)", cleared["active_music_state"], "TEST_A")
	_check_eq("v2 CLEARED records its no-op reason", cleared["last_noop_reason"], "v2_cleared_pressure_only")
	_check_eq("CLEARED does not fire a sting without a room_clear event", cleared["last_music_sting_event"], "")

	# Region ambience seam (levels lane 2026-07-07).
	for region in ["HEARTH", "BRASS", "VERDANT", "RUST"]:
		_check("ambient bed for %s exists on disk" % region,
			ResourceLoader.exists(String(director.AMBIENT_BED_MANIFEST[StringName(region)])))
	director.set_region_ambience(&"BRASS")
	var amb: Dictionary = director.describe()
	_check_eq("region ambience activates the requested bed", amb["active_ambient_region"], "BRASS")
	_check("region ambience bed is playing", amb["ambient_playing"] == true)
	director.set_region_ambience(&"NO_SUCH_REGION")
	var amb_off: Dictionary = director.describe()
	_check_eq("unknown region stops the ambient bed", amb_off["active_ambient_region"], "")
	_check("unknown region leaves nothing playing", amb_off["ambient_playing"] == false)

	await _cleanup_director(director)

func _test_duplicate_state_is_idempotent() -> void:
	var director := await _new_director()
	director.bind_music_state_cue(&"TEST_B", &"music_combat")
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"TEST_B")
	await process_frame
	var first: Dictionary = director.describe()
	_request_zone_state(director, &"TEST_B")
	await process_frame
	var second: Dictionary = director.describe()

	_check_eq("duplicate state keeps active cue", second["active_cue_id"], first["active_cue_id"])
	_check_eq("duplicate state does not crossfade again", second["crossfade_count"], first["crossfade_count"])
	_check_eq("duplicate state records idempotent no-op", second["last_noop_reason"], "duplicate_state")

	await _cleanup_director(director)

func _test_crossfade_progresses_while_tree_is_paused() -> void:
	var director := await _new_director()
	director.crossfade_seconds = 0.25
	director.bind_music_state_cue(&"TEST_A", &"music_hub")
	director.bind_music_state_cue(&"TEST_B", &"music_combat")
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())
	_request_zone_state(director, &"TEST_A")
	await _wait_seconds(director.crossfade_seconds + 0.05)

	_check_eq("AudioDirector processes while the tree is paused", director.process_mode, Node.PROCESS_MODE_ALWAYS)
	paused = true
	_request_zone_state(director, &"TEST_B")
	var immediate: Dictionary = director.describe()
	await _wait_seconds(0.12)
	var mid: Dictionary = director.describe()
	paused = false

	_check_eq("paused transition reports fading", mid.get("fading", null), true)
	_check(
		"paused transition advances incoming lane volume",
		float(mid.get("active_volume_db", -80.0)) > float(immediate.get("active_volume_db", -80.0))
	)

	await _wait_seconds(director.crossfade_seconds + 0.05)
	var after: Dictionary = director.describe()
	_check_eq("paused transition completes after unpause", after.get("fading", null), false)

	await _cleanup_director(director)

func _test_registering_active_cue_swaps_stream_in_place() -> void:
	var director := await _new_director()
	var first_stream := _new_stream()
	var replacement_stream := _new_stream()
	director.bind_music_state_cue(&"TEST_A", &"music_hub")
	director.register_cue(&"music_hub", first_stream)
	_request_zone_state(director, &"TEST_A")
	await _wait_seconds(director.crossfade_seconds + 0.05)
	var before: Dictionary = director.describe()
	var active_player := director.get_node_or_null(String(before["active_lane"])) as AudioStreamPlayer
	_check("active lane is inspectable before hot-swap", active_player != null)
	if active_player == null:
		await _cleanup_director(director)
		return
	_check("first registration is playing on active lane", active_player.stream == first_stream)

	director.register_cue(&"music_hub", replacement_stream)
	await process_frame
	var after: Dictionary = director.describe()
	var same_player := director.get_node_or_null(String(after["active_lane"])) as AudioStreamPlayer
	_check_eq("active cue hot-swap preserves state", after["active_music_state"], "TEST_A")
	_check_eq("active cue hot-swap does not count as a crossfade", after["crossfade_count"], before["crossfade_count"])
	_check("active cue hot-swap keeps the same active lane", same_player == active_player)
	_check("active cue hot-swap replaces the playing stream", same_player != null and same_player.stream == replacement_stream)
	_check("active cue hot-swap restarts playback on the active lane", same_player != null and same_player.playing)

	await _cleanup_director(director)

func _test_cueless_state_is_headless_safe() -> void:
	var director := await _new_director()

	_request_zone_state(director, &"NO_CUE_STATE")
	await process_frame
	var desc: Dictionary = director.describe()

	# Legacy EL demo loops are deleted; the v2 score table is the music source
	# of truth and cue registration happens on demand.
	_check_eq("cueless state registers no legacy manifest cues", desc["registered_cue_count"], 0)
	_check_eq("cueless state has no active cue", desc["active_cue_id"], "")
	_check_eq("cueless state does not crossfade", desc["crossfade_count"], 0)
	_check_eq("cueless state records missing cue binding", desc["last_noop_reason"], "missing_state_cue")
	_check_eq("cueless state keeps two music lanes available", desc["music_lane_count"], 2)

	await _cleanup_director(director)

func _test_autoload_registration() -> void:
	var autoload := root.get_node_or_null("AudioDirector")
	_check("AudioDirector autoload exists", autoload != null)
	if autoload == null:
		return
	_check("AudioDirector autoload exposes set_zone_state", autoload.has_method(&"set_zone_state"))
	_check("AudioDirector autoload exposes set_music_state", autoload.has_method(&"set_music_state"))
	_check("AudioDirector autoload exposes register_cue", autoload.has_method(&"register_cue"))
	_check("AudioDirector autoload exposes notify_event", autoload.has_method(&"notify_event"))
	_check("AudioDirector autoload exposes describe", autoload.has_method(&"describe"))
	var desc: Dictionary = autoload.describe()
	_check_eq("AudioDirector autoload registers no legacy manifest cues", desc["registered_cue_count"], 0)
	_check_eq("AudioDirector autoload registers manifest SFX events", int(desc.get("sfx_registered_event_count", -1)), 13)
	_check_eq("AudioDirector autoload registers UI events", int(desc.get("ui_registered_event_count", -1)), 1)
	_check_eq("AudioDirector autoload registers music stings", int(desc.get("music_sting_registered_event_count", -1)), 1)
	_check_eq("AudioDirector autoload owns pooled SFX players", int(desc.get("sfx_pool_size", -1)), 8)

func _new_director() -> Node:
	var director: Node = AudioDirectorScript.new()
	director.crossfade_seconds = 0.01
	root.add_child(director)
	await process_frame
	return director

func _cleanup_director(director: Node) -> void:
	paused = false
	director.queue_free()
	await process_frame
	await process_frame

func _new_stream() -> AudioStream:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 48000.0
	return stream

func _request_zone_state(director: Node, state: StringName) -> void:
	if director.has_method(&"set_zone_state"):
		director.call(&"set_zone_state", state)
	elif director.has_method(&"set_music_state"):
		director.call(&"set_music_state", state)

func _wait_seconds(seconds: float) -> void:
	await create_timer(maxf(seconds, 0.0), true).timeout

func _stream_loops(stream: AudioStream) -> bool:
	if stream == null:
		return false
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			return bool(stream.get("loop"))
	return false
