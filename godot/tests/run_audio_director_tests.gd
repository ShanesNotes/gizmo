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
	await _test_contract_seam_and_describe_surface()
	await _test_registered_state_crossfades_to_target_cue()
	await _test_unknown_cue_noops_without_stopping_current_music()
	await _test_duplicate_state_is_idempotent()
	await _test_crossfade_progresses_while_tree_is_paused()
	await _test_registering_active_cue_swaps_stream_in_place()
	await _test_empty_registry_is_headless_safe()
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
	for bus_name in [&"Music", &"Ambience", &"SFX", &"UI", &"VoiceReserved"]:
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

func _test_contract_seam_and_describe_surface() -> void:
	var director := await _new_director()
	_check("AudioDirector exposes contract set_zone_state seam", director.has_method(&"set_zone_state"))
	_check("AudioDirector keeps deprecated set_music_state alias", director.has_method(&"set_music_state"))
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"HUB")
	await process_frame
	var hub_desc: Dictionary = director.describe()
	_check_eq("describe reports current state before transition", hub_desc.get("current_state", ""), "HUB")
	_check_eq("describe reports active cue id before transition", hub_desc.get("active_cue_id", ""), "music_hub")
	_check("describe exposes per-bus mix dictionary", hub_desc.get("bus_mix", null) is Dictionary)
	if hub_desc.get("bus_mix", null) is Dictionary:
		var bus_mix := hub_desc["bus_mix"] as Dictionary
		_check("describe bus mix includes Music volume_db", bus_mix.has("Music") and bus_mix["Music"].has("volume_db"))
	_check_eq("describe reports not fading before transition", hub_desc.get("fading", null), false)

	_request_zone_state(director, &"COMBAT")
	var mid_desc: Dictionary = director.describe()
	_check_eq("describe reports current state during transition", mid_desc.get("current_state", ""), "COMBAT")
	_check_eq("describe reports active cue id during transition", mid_desc.get("active_cue_id", ""), "music_combat")
	_check_eq("describe reports fading during transition", mid_desc.get("fading", null), true)

	await _wait_seconds(director.crossfade_seconds + 0.05)
	var after_desc: Dictionary = director.describe()
	_check_eq("describe keeps current state after transition", after_desc.get("current_state", ""), "COMBAT")
	_check_eq("describe keeps active cue id after transition", after_desc.get("active_cue_id", ""), "music_combat")
	_check_eq("describe reports not fading after transition", after_desc.get("fading", null), false)

	await _cleanup_director(director)

func _test_registered_state_crossfades_to_target_cue() -> void:
	var director := await _new_director()
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"HUB")
	await process_frame
	var hub_desc: Dictionary = director.describe()
	_check_eq("HUB request becomes active state", hub_desc["active_music_state"], "HUB")
	_check_eq("HUB uses registered hub cue", hub_desc["active_cue_id"], "music_hub")

	_request_zone_state(director, &"COMBAT")
	var combat_desc: Dictionary = director.describe()
	var last_crossfade: Dictionary = combat_desc["last_crossfade"]
	_check_eq("COMBAT request becomes requested state", combat_desc["requested_music_state"], "COMBAT")
	_check_eq("COMBAT immediately targets combat cue", combat_desc["active_cue_id"], "music_combat")
	_check_eq("crossfade records outgoing hub cue", last_crossfade["from_cue_id"], "music_hub")
	_check_eq("crossfade records incoming combat cue", last_crossfade["to_cue_id"], "music_combat")
	_check_eq("crossfade fades previous lane down", last_crossfade["from_target_db"], -80.0)
	_check_eq("crossfade fades next lane up", last_crossfade["to_target_db"], 0.0)
	_check_eq("state switch increments crossfade count", combat_desc["crossfade_count"], 2)

	await _cleanup_director(director)

func _test_unknown_cue_noops_without_stopping_current_music() -> void:
	var director := await _new_director()
	director.register_cue(&"music_hub", _new_stream())
	_request_zone_state(director, &"HUB")
	await process_frame
	var before: Dictionary = director.describe()

	_request_zone_state(director, &"CLEARED")
	await process_frame
	var after: Dictionary = director.describe()

	_check_eq("missing CLEARED cue records requested state", after["requested_music_state"], "CLEARED")
	_check_eq("missing CLEARED cue leaves active state unchanged", after["active_music_state"], "HUB")
	_check_eq("missing CLEARED cue leaves active cue unchanged", after["active_cue_id"], before["active_cue_id"])
	_check_eq("missing CLEARED cue does not crossfade", after["crossfade_count"], before["crossfade_count"])
	_check_eq("missing CLEARED cue records no-op reason", after["last_noop_reason"], "missing_registered_cue")

	await _cleanup_director(director)

func _test_duplicate_state_is_idempotent() -> void:
	var director := await _new_director()
	director.register_cue(&"music_combat", _new_stream())

	_request_zone_state(director, &"COMBAT")
	await process_frame
	var first: Dictionary = director.describe()
	_request_zone_state(director, &"COMBAT")
	await process_frame
	var second: Dictionary = director.describe()

	_check_eq("duplicate state keeps active cue", second["active_cue_id"], first["active_cue_id"])
	_check_eq("duplicate state does not crossfade again", second["crossfade_count"], first["crossfade_count"])
	_check_eq("duplicate state records idempotent no-op", second["last_noop_reason"], "duplicate_state")

	await _cleanup_director(director)

func _test_crossfade_progresses_while_tree_is_paused() -> void:
	var director := await _new_director()
	director.crossfade_seconds = 0.25
	director.register_cue(&"music_hub", _new_stream())
	director.register_cue(&"music_combat", _new_stream())
	_request_zone_state(director, &"HUB")
	await _wait_seconds(director.crossfade_seconds + 0.05)

	_check_eq("AudioDirector processes while the tree is paused", director.process_mode, Node.PROCESS_MODE_ALWAYS)
	paused = true
	_request_zone_state(director, &"COMBAT")
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
	director.register_cue(&"music_hub", first_stream)
	_request_zone_state(director, &"HUB")
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
	_check_eq("active cue hot-swap preserves state", after["active_music_state"], "HUB")
	_check_eq("active cue hot-swap does not count as a crossfade", after["crossfade_count"], before["crossfade_count"])
	_check("active cue hot-swap keeps the same active lane", same_player == active_player)
	_check("active cue hot-swap replaces the playing stream", same_player != null and same_player.stream == replacement_stream)
	_check("active cue hot-swap restarts playback on the active lane", same_player != null and same_player.playing)

	await _cleanup_director(director)

func _test_empty_registry_is_headless_safe() -> void:
	var director := await _new_director()

	_request_zone_state(director, &"HUB")
	_request_zone_state(director, &"COMBAT")
	await process_frame
	var desc: Dictionary = director.describe()

	_check_eq("empty registry has no registered cues", desc["registered_cue_count"], 0)
	_check_eq("empty registry has no active cue", desc["active_cue_id"], "")
	_check_eq("empty registry does not crossfade", desc["crossfade_count"], 0)
	_check_eq("empty registry keeps two music lanes available", desc["music_lane_count"], 2)

	await _cleanup_director(director)

func _test_autoload_registration() -> void:
	var autoload := root.get_node_or_null("AudioDirector")
	_check("AudioDirector autoload exists", autoload != null)
	if autoload == null:
		return
	_check("AudioDirector autoload exposes set_zone_state", autoload.has_method(&"set_zone_state"))
	_check("AudioDirector autoload exposes set_music_state", autoload.has_method(&"set_music_state"))
	_check("AudioDirector autoload exposes register_cue", autoload.has_method(&"register_cue"))
	_check("AudioDirector autoload exposes describe", autoload.has_method(&"describe"))
	var desc: Dictionary = autoload.describe()
	_check_eq("AudioDirector autoload starts with empty registry", desc["registered_cue_count"], 0)

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
