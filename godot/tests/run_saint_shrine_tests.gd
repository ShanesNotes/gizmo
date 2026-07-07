extends SceneTree

# Headless tests for saints as hub icon shrines.
# Run with:
#   mkdir -p /tmp/codex-saint-shrine-userdata/logs
#   godot --headless --user-data-dir /tmp/codex-saint-shrine-userdata --log-file /tmp/codex-saint-shrine-userdata/logs/godot.log --path godot --script res://tests/run_saint_shrine_tests.gd

const SaintShrineScript := preload("res://scripts/npcs/saint_shrine.gd")
const SaintShrineScene := preload("res://scenes/npcs/saint_shrine.tscn")

const TEST_ROOT := "/tmp/codex-saint-shrine-tests"

class StubAudioDirector:
	extends Node

	var played: Array[StringName] = []
	var speaking := false
	var last_line: StringName = &""

	func play_voice_line(line_id: StringName) -> void:
		played.append(line_id)
		last_line = line_id
		speaking = true

	func describe() -> Dictionary:
		return {
			"voice_speaking": speaking,
			"last_voice_line": String(last_line),
		}

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running saint shrine tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	await _test_scene_has_shrine_placeholder_contract()
	await _test_first_interact_speaks_meeting_then_offer()
	await _test_persisted_meeting_starts_with_offer()
	await _test_offer_rotation_uses_base_offer_id()
	await _test_saint_voice_speaking_blocks_retrigger_spam()
	await _test_no_director_is_headless_noop()
	await _test_unknown_role_still_forms_voice_ids()
	await _test_ungrouped_character_body_is_fallback_player()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => saint shrine suite failed to load/compile)" if _passed == 0 else ""]
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

func _save_path(test_name: String) -> String:
	return "%s/shrines_%s.cfg" % [TEST_ROOT, test_name]

func _remove_file(path: String) -> void:
	DirAccess.remove_absolute(path)

func _new_director() -> StubAudioDirector:
	var director := StubAudioDirector.new()
	root.add_child(director)
	return director

func _new_player(grouped: bool = true) -> CharacterBody3D:
	var player := CharacterBody3D.new()
	player.name = "PlayerBody"
	if grouped:
		player.add_to_group(&"player")
	root.add_child(player)
	return player

func _new_shrine(path: String, director: Node = null, role: StringName = &"bearer") -> SaintShrine:
	var shrine := SaintShrineScene.instantiate() as SaintShrine
	shrine.shrine_save_path = path
	shrine.saint_role = role
	shrine.audio_director = director
	root.add_child(shrine)
	await process_frame
	return shrine

func _enter(shrine: SaintShrine, body: CharacterBody3D) -> void:
	shrine.emit_signal(&"body_entered", body)
	await process_frame

func _interact(shrine: SaintShrine) -> void:
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = true
	shrine._unhandled_input(event)
	await process_frame

func _cleanup(nodes: Array[Node]) -> void:
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	await process_frame
	await process_frame

func _played_at(director: StubAudioDirector, index: int) -> StringName:
	if index < 0 or index >= director.played.size():
		return &""
	return director.played[index]

func _test_scene_has_shrine_placeholder_contract() -> void:
	var path := _save_path("scene")
	_remove_file(path)
	var shrine := await _new_shrine(path, _new_director())

	var proximity := shrine.get_node_or_null("ProximityShape") as CollisionShape3D
	_check("shrine owns a CollisionShape3D proximity", proximity != null)
	_check("proximity uses a CylinderShape3D", proximity != null and proximity.shape is CylinderShape3D)
	if proximity != null and proximity.shape is CylinderShape3D:
		var cylinder := proximity.shape as CylinderShape3D
		_check_eq("proximity radius is about two meters across", cylinder.radius, 1.0)
		_check_eq("proximity height is about two meters", cylinder.height, 2.0)
	var prompt := shrine.get_node_or_null("PromptLabel") as Label3D
	_check("shrine owns a prompt Label3D", prompt != null)
	if prompt != null:
		_check_eq("prompt text is venerate", prompt.text, "venerate")
	var plaque := shrine.get_node_or_null("PlaqueLabel") as Label3D
	_check("shrine owns a plaque Label3D", plaque != null)
	if plaque != null:
		_check("plaque carries the full display title", plaque.text.contains("Saint Christopher"))
	_check("placeholder root exists for one-child asset swap", shrine.get_node_or_null("Placeholder") is Node3D)
	_check("ModelSocket marks the future saint asset landing spot", shrine.get_node_or_null("Placeholder/ModelSocket") is Node3D)
	_check("icon panel placeholder is a mesh", shrine.get_node_or_null("Placeholder/IconPanel") is MeshInstance3D)
	_check("candle light placeholder is warm low OmniLight", shrine.get_node_or_null("Placeholder/CandleLight") is OmniLight3D)

	await _cleanup([shrine.audio_director, shrine])
	_remove_file(path)

func _test_first_interact_speaks_meeting_then_offer() -> void:
	var path := _save_path("meeting_then_offer")
	_remove_file(path)
	var director := _new_director()
	var shrine := await _new_shrine(path, director)
	var player := _new_player()
	await _enter(shrine, player)

	await _interact(shrine)
	_check_eq("first veneration requests the bearer meeting line", _played_at(director, 0), &"saint_bearer_meeting")
	_check("first veneration persists that the bearer has been met", SaintShrineScript.has_met(&"bearer", path))

	director.speaking = false
	await _interact(shrine)
	_check_eq("second veneration requests the bearer offer base line", _played_at(director, 1), &"saint_bearer_offer")

	await _cleanup([player, shrine, director])
	_remove_file(path)

func _test_persisted_meeting_starts_with_offer() -> void:
	var path := _save_path("preseeded")
	_remove_file(path)
	_check_eq("pre-seeding bearer met succeeds", SaintShrineScript.mark_met(&"bearer", path), OK)
	var director := _new_director()
	var shrine := await _new_shrine(path, director)
	var player := _new_player()
	await _enter(shrine, player)

	await _interact(shrine)
	_check_eq("persisted bearer met skips meeting and requests offer", _played_at(director, 0), &"saint_bearer_offer")

	await _cleanup([player, shrine, director])
	_remove_file(path)

func _test_offer_rotation_uses_base_offer_id() -> void:
	var path := _save_path("offer_rotation")
	_remove_file(path)
	SaintShrineScript.mark_met(&"marksman", path)
	var director := _new_director()
	var shrine := await _new_shrine(path, director, &"marksman")
	var player := _new_player()
	await _enter(shrine, player)

	for index in range(3):
		director.speaking = false
		await _interact(shrine)
		_check_eq("offer veneration %d passes the marksman offer base id" % (index + 1), _played_at(director, index), &"saint_marksman_offer")

	await _cleanup([player, shrine, director])
	_remove_file(path)

func _test_saint_voice_speaking_blocks_retrigger_spam() -> void:
	var path := _save_path("spam_guard")
	_remove_file(path)
	var director := _new_director()
	director.speaking = true
	director.last_line = &"saint_bearer_meeting"
	var shrine := await _new_shrine(path, director)
	var player := _new_player()
	await _enter(shrine, player)

	await _interact(shrine)
	_check_eq("active saint voice blocks retrigger spam", director.played.size(), 0)

	await _cleanup([player, shrine, director])
	_remove_file(path)

func _test_no_director_is_headless_noop() -> void:
	var path := _save_path("no_director")
	_remove_file(path)
	var shrine := await _new_shrine(path, null)
	shrine.audio_director = null
	var player := _new_player()
	await _enter(shrine, player)

	await _interact(shrine)
	_check("missing AudioDirector does not crash and still records veneration", SaintShrineScript.has_met(&"bearer", path))

	await _cleanup([player, shrine])
	_remove_file(path)

func _test_unknown_role_still_forms_voice_ids() -> void:
	var path := _save_path("unknown_role")
	_remove_file(path)
	var director := _new_director()
	var shrine := await _new_shrine(path, director, &"lampwright")
	var player := _new_player()
	await _enter(shrine, player)

	await _interact(shrine)
	_check_eq("unknown role still forms the meeting id", _played_at(director, 0), &"saint_lampwright_meeting")
	director.speaking = false
	await _interact(shrine)
	_check_eq("unknown role still forms the offer id", _played_at(director, 1), &"saint_lampwright_offer")

	await _cleanup([player, shrine, director])
	_remove_file(path)

func _test_ungrouped_character_body_is_fallback_player() -> void:
	var path := _save_path("fallback_player")
	_remove_file(path)
	var director := _new_director()
	var shrine := await _new_shrine(path, director)
	var player := _new_player(false)
	await _enter(shrine, player)

	await _interact(shrine)
	_check_eq("ungrouped CharacterBody3D works when no player group is present", _played_at(director, 0), &"saint_bearer_meeting")

	await _cleanup([player, shrine, director])
	_remove_file(path)
