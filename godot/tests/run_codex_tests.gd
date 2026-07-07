extends SceneTree

# Headless tests for the Codex unlock log and static entry table.
# Run with:
#   godot --headless --path godot --script res://tests/run_codex_tests.gd --user-data-dir /tmp/godot-night-lore

const CodexLogScript := preload("res://scripts/codex/codex_log.gd")
const CodexEntries := preload("res://scripts/codex/codex_entries.gd")

const TEST_ROOT := "/tmp/godot-night-lore/codex_tests"

const EXPECTED_EVENTS := {
	&"codex_first_blood": &"first_enemy_felled",
	&"codex_first_keepsake": &"first_keepsake_taken",
	&"codex_first_elite": &"first_elite_felled",
	&"codex_first_death": &"first_light_failed",
	&"codex_first_victory": &"first_beacon_rekindled",
	&"codex_the_pattern": &"first_pattern_heard",
}

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running Codex tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	await _test_unlock_on_event()
	await _test_event_unlock_is_idempotent()
	await _test_persistence_round_trip()
	await _test_unknown_event_is_noop()
	_test_table_entries_are_valid()
	_cleanup_test_root()

	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => Codex suite failed to load/compile)" if _passed == 0 else ""]
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

func _flush() -> void:
	await process_frame
	await process_frame

func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	await _flush()

func _path(test_name: String) -> String:
	return "%s/%s.cfg" % [TEST_ROOT, test_name]

func _remove_file(path: String) -> void:
	DirAccess.remove_absolute(path)

func _new_log(path: String) -> Node:
	var log: Node = CodexLogScript.new()
	log.save_path = path
	root.add_child(log)
	await process_frame
	return log

func _test_unlock_on_event() -> void:
	var path := _path("unlock_on_event")
	_remove_file(path)
	var log := await _new_log(path)
	var signals: Array[StringName] = []
	log.entry_unlocked.connect(func(entry_id: StringName) -> void:
		signals.append(entry_id)
	)

	var unlocked: Array[StringName] = log.notify_event(&"first_enemy_felled")

	_check_eq("first_enemy_felled unlocks one entry", unlocked, [&"codex_first_blood"])
	_check("codex_first_blood is now unlocked", log.is_unlocked(&"codex_first_blood"))
	_check_eq("unlocked_entries reports the unlocked id", log.unlocked_entries(), [&"codex_first_blood"])
	_check_eq("entry_unlocked signal emits the unlocked id", signals, [&"codex_first_blood"])

	await _cleanup(log)
	_remove_file(path)

func _test_event_unlock_is_idempotent() -> void:
	var path := _path("idempotent")
	_remove_file(path)
	var log := await _new_log(path)

	var first_unlock: Array[StringName] = log.notify_event(&"first_enemy_felled")
	var second_unlock: Array[StringName] = log.notify_event(&"first_enemy_felled")

	_check_eq("first event call unlocks the matching entry", first_unlock, [&"codex_first_blood"])
	_check_eq("second event call returns no new unlocks", second_unlock, [])
	_check_eq("duplicate event keeps one unlocked entry", log.unlocked_entries(), [&"codex_first_blood"])

	await _cleanup(log)
	_remove_file(path)

func _test_persistence_round_trip() -> void:
	var path := _path("round_trip")
	_remove_file(path)
	var first_log := await _new_log(path)
	var first_unlock: Array[StringName] = first_log.notify_event(&"first_keepsake_taken")
	await _cleanup(first_log)

	var second_log := await _new_log(path)

	_check_eq("first keepsake event unlocks its Codex entry", first_unlock, [&"codex_first_keepsake"])
	_check("round-tripped Codex log remembers the keepsake unlock", second_log.is_unlocked(&"codex_first_keepsake"))
	_check_eq("round-tripped Codex log exposes persisted entries", second_log.unlocked_entries(), [&"codex_first_keepsake"])

	await _cleanup(second_log)
	_remove_file(path)

func _test_unknown_event_is_noop() -> void:
	var path := _path("unknown_event")
	_remove_file(path)
	var log := await _new_log(path)
	var signals: Array[StringName] = []
	log.entry_unlocked.connect(func(entry_id: StringName) -> void:
		signals.append(entry_id)
	)

	var unlocked: Array[StringName] = log.notify_event(&"not_a_codex_event")

	_check_eq("unknown events return no new unlocks", unlocked, [])
	_check_eq("unknown events do not unlock entries", log.unlocked_entries(), [])
	_check_eq("unknown events emit no unlock signal", signals, [])
	_check("unknown events do not create a save file", not FileAccess.file_exists(path))

	await _cleanup(log)
	_remove_file(path)

func _test_table_entries_are_valid() -> void:
	_check_eq("Codex table has the expected number of entries", CodexEntries.TABLE.size(), EXPECTED_EVENTS.size())

	for entry_id in EXPECTED_EVENTS.keys():
		_check("Codex table contains %s" % entry_id, CodexEntries.TABLE.has(entry_id))
		if not CodexEntries.TABLE.has(entry_id):
			continue
		var entry := CodexEntries.TABLE[entry_id] as Dictionary
		var title := String(entry.get("title", ""))
		var body := String(entry.get("body", ""))
		var unlock_event := StringName(entry.get("unlock_event", &""))
		var voice_line := StringName(entry.get("voice_line", &""))

		_check("Codex entry %s title is non-empty" % entry_id, not title.strip_edges().is_empty())
		_check("Codex entry %s body is non-empty" % entry_id, not body.strip_edges().is_empty())
		_check("Codex entry %s body has at least two sentences" % entry_id, _sentence_count(body) >= 2)
		_check_eq("Codex entry %s unlock_event matches contract" % entry_id, unlock_event, EXPECTED_EVENTS[entry_id])
		_check_eq("Codex entry %s voice_line is reserved Margin Codex line" % entry_id, voice_line, &"margin_codex_entry")
		if entry.has("variant_index"):
			_check("Codex entry %s variant_index is an int" % entry_id, typeof(entry["variant_index"]) == TYPE_INT)

func _sentence_count(text: String) -> int:
	var count := 0
	for character in text:
		if character == "." or character == "!" or character == "?":
			count += 1
	return count

func _cleanup_test_root() -> void:
	for test_name in ["unlock_on_event", "idempotent", "round_trip", "unknown_event"]:
		_remove_file(_path(test_name))
