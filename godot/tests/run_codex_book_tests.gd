extends SceneTree

## Codex book prop: cycling reads over unlocked entries, exact-variant line
## registration, headless-safe without a director.

const CodexBookScene := preload("res://scenes/npcs/codex_book.tscn")
const CodexLogScript := preload("res://scripts/codex/codex_log.gd")

var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	await process_frame
	await _test_reads_cycle_unlocked_entries()
	await _test_no_director_is_safe()
	var verdict := "PASS - %d checks" % _passed if _failed == 0 \
			else "FAIL - %d passed, %d failed" % [_passed, _failed]
	print(verdict)
	quit(0 if _failed == 0 else 1)

func _check(label: String, ok: bool) -> void:
	if ok:
		_passed += 1
		print("  ok   - %s" % label)
	else:
		_failed += 1
		print("  FAIL - %s" % label)

func _make_temp_log(unlock_events: Array) -> Node:
	var log: Node = CodexLogScript.new()
	log.save_path = "user://saves/test_codex_book_%d.cfg" % randi()
	for event in unlock_events:
		log.notify_event(event)
	return log

func _test_reads_cycle_unlocked_entries() -> void:
	var book: Area3D = CodexBookScene.instantiate()
	var log := _make_temp_log([&"first_enemy_felled", &"first_light_failed"])
	book.codex_log = log
	book.add_child(log)
	root.add_child(book)
	await process_frame

	var first: StringName = book.read_next_entry()
	var second: StringName = book.read_next_entry()
	var third: StringName = book.read_next_entry()
	_check("first read returns an unlocked entry", String(first) != "")
	_check("reads cycle distinct unlocked entries", first != second)
	_check("cycle wraps back to the first entry", third == first)

	book.queue_free()
	await process_frame

func _test_no_director_is_safe() -> void:
	var book: Area3D = CodexBookScene.instantiate()
	var log := _make_temp_log([])
	book.codex_log = log
	book.add_child(log)
	root.add_child(book)
	await process_frame

	var read: StringName = book.read_next_entry()
	_check("nothing unlocked reads nothing", String(read) == "")
	_check("book survives headless with no director", is_instance_valid(book))

	book.queue_free()
	await process_frame
