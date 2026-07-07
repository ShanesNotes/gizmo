extends SceneTree

# Headless tests for the campfire opening sequence, controls card, speaker
# panel, and first-run objective banner (playtest 2, Lane 4).
# Run with:
#   godot --headless --user-data-dir /tmp/fable-opening2 --path godot --script res://tests/run_opening_tests.gd

const OpeningScene := preload("res://scenes/opening.tscn")
const OpeningSequenceScript := preload("res://scripts/ui/opening_sequence.gd")
const ControlsCardScene := preload("res://scenes/controls_card.tscn")
const SpeakerPanelScene := preload("res://scenes/speaker_panel.tscn")
const ObjectiveBannerScene := preload("res://scenes/objective_banner.tscn")
const AppScene := preload("res://scenes/app.tscn")
const HubControllerScript := preload("res://scripts/hub_controller.gd")

const TEST_ROOT := "/tmp/fable-opening2/opening-tests"

class StubVoiceDirector:
	extends Node

	var registered: Dictionary = {}
	var played: Array = []
	var speaking := false
	var last_line: StringName = &""

	func register_voice_line(line_id: StringName, streams: Array) -> void:
		registered[line_id] = streams

	func play_voice_line(line_id: StringName) -> void:
		played.append(line_id)
		speaking = true
		last_line = line_id

	func describe() -> Dictionary:
		return {
			"voice_speaking": speaking,
			"last_voice_line": String(last_line),
		}

class StubRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	func run_summary(_victory: bool = false) -> Dictionary:
		return {}

	func start_run(_bonuses: Dictionary) -> void:
		pass

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running opening/guide tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	await _test_seen_flag_helpers()
	await _test_opening_beats_are_canon_shaped()
	await _test_opening_cinematic_staging_rules()
	await _test_opening_registers_and_speaks_ordered_lines()
	await _test_margin_figure_reveals_at_the_portrait_beat()
	await _test_gizmo_is_seated_at_the_campfire()
	await _test_opening_skip_finishes_once()
	await _test_opening_skip_during_title_finishes_once()
	await _test_opening_missing_title_sting_is_noop()
	await _test_controls_card_teaches_every_control()
	await _test_app_shell_first_boot_shows_opening_then_hub()
	await _test_app_shell_seen_flag_boots_straight_to_hub()
	await _test_app_shell_replay_flag_reopens_opening()
	await _test_speaker_panel_appears_for_guide_lines_only()
	await _test_objective_banner_shows_once_on_first_run_entry()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => opening suite failed to load/compile)" if _passed == 0 else ""]
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

func _seen_path(test_name: String) -> String:
	return "%s/opening_seen_%s.cfg" % [TEST_ROOT, test_name]

func _remove_file(path: String) -> void:
	DirAccess.remove_absolute(path)

func _new_opening(director: Node) -> Node:
	var opening: Node = OpeningScene.instantiate()
	opening.audio_director = director
	root.add_child(opening)
	await process_frame
	return opening

func _caption_index_containing(fragment: String) -> int:
	var beats: Array = OpeningSequenceScript.BEATS
	for index in range(beats.size()):
		if String(beats[index].get("caption", "")).contains(fragment):
			return index
	return -1

func _title_beat_index() -> int:
	var beats: Array = OpeningSequenceScript.BEATS
	for index in range(beats.size()):
		if bool(beats[index].get("title_card", false)):
			return index
	return -1

func _first_portrait_beat_index() -> int:
	var beats: Array = OpeningSequenceScript.BEATS
	for index in range(beats.size()):
		if bool(beats[index].get("reveal_portrait", false)):
			return index
	return -1

func _first_voice_beat_index() -> int:
	var beats: Array = OpeningSequenceScript.BEATS
	for index in range(beats.size()):
		if beats[index].has("voice"):
			return index
	return -1

func _advance_opening_to_beat(opening: Node, director: StubVoiceDirector, target_index: int) -> void:
	while int(opening._beat_index) < target_index and not bool(opening._finished):
		director.speaking = false
		opening.advance_time(60.0)
		await process_frame

func _test_seen_flag_helpers() -> void:
	var path := _seen_path("helpers")
	_remove_file(path)

	_check("has_seen is false without a flag file", not OpeningSequenceScript.has_seen(path))
	_check_eq("mark_seen writes the flag file", OpeningSequenceScript.mark_seen(path), OK)
	_check("has_seen is true after mark_seen", OpeningSequenceScript.has_seen(path))

	_remove_file(path)

func _test_opening_beats_are_canon_shaped() -> void:
	var beats: Array = OpeningSequenceScript.BEATS
	_check("opening has at least four beats", beats.size() >= 4)
	var spoken_count := 0
	for beat in beats:
		if beat.has("caption"):
			var caption := String(beat.get("caption", ""))
			_check("captioned beat caption is non-empty", not caption.is_empty())
		if beat.has("voice"):
			spoken_count += 1
			var voice := StringName(beat.get("voice", &""))
			_check(
				"beat voice '%s' has a registered source" % voice,
				OpeningSequenceScript.VOICE_SOURCES.has(voice)
			)
	_check("opening still has at least four spoken beats", spoken_count >= 4)
	var all_captions := ""
	for beat in beats:
		all_captions += String(beat.get("caption", "")) + " "
	_check("beats name the guide (Margin/Marginalia)", all_captions.contains("Margin"))
	_check("beats name the Spark", all_captions.contains("Spark"))
	_check("beats name the Vigil", all_captions.contains("Vigil"))

func _test_opening_cinematic_staging_rules() -> void:
	var beats: Array = OpeningSequenceScript.BEATS
	var poses: Dictionary = OpeningSequenceScript.CAMERA_POSES
	var pre_beat: Dictionary = beats[0]
	var keep_alive_index := _caption_index_containing("Keep it alive")
	var title_index := _title_beat_index()
	var portrait_index := _first_portrait_beat_index()

	_check("pre-beat is first and has no caption", not pre_beat.has("caption"))
	_check("pre-beat is first and has no voice", not pre_beat.has("voice"))
	_check_eq("pre-beat starts on the ember close camera pose", StringName(pre_beat.get("camera_pose", &"")), &"ember_close")
	_check("title beat exists", title_index >= 0)
	if title_index >= 0:
		var title_beat: Dictionary = beats[title_index]
		_check("title beat has no voice key", not title_beat.has("voice"))
	_check("keep-it-alive beat exists", keep_alive_index >= 0)
	_check("title beat lands after keep it alive", keep_alive_index >= 0 and title_index == keep_alive_index + 1)
	_check("portrait reveal happens after title", title_index >= 0 and portrait_index > title_index)

	for beat in beats:
		_check(
			"no beat both reveals portrait and shows title",
			not (bool(beat.get("reveal_portrait", false)) and bool(beat.get("title_card", false)))
		)
		if beat.has("camera_pose"):
			var pose_name := StringName(beat.get("camera_pose", &""))
			_check("camera pose '%s' exists" % pose_name, poses.has(pose_name))

func _test_opening_registers_and_speaks_ordered_lines() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)

	for voice_id in OpeningSequenceScript.VOICE_SOURCES.keys():
		_check(
			"opening registers voice line '%s' with the director" % voice_id,
			director.registered.has(voice_id)
		)
	_check("opening joins the opening_sequence group", opening.is_in_group(&"opening_sequence"))
	_check_eq("opening starts silently on the ember pre-beat", director.played.size(), 0)

	# Pre-beat finishes -> first spoken line plays.
	director.speaking = false
	opening.advance_time(60.0)
	await process_frame
	var first_voice_index := _first_voice_beat_index()
	var first_played: StringName = director.played.front() if director.played.size() > 0 else &""
	_check_eq(
		"opening speaks the first spoken beat after the ember pre-beat",
		first_played,
		StringName(OpeningSequenceScript.BEATS[first_voice_index].get("voice"))
	)

	# Voice "finishes", minimum beat time passes -> next beat line plays.
	director.speaking = false
	opening.advance_time(60.0)
	await process_frame
	var second_played: StringName = director.played[1] if director.played.size() > 1 else &""
	_check_eq(
		"second spoken beat line follows the first in order",
		second_played,
		StringName(OpeningSequenceScript.BEATS[first_voice_index + 1].get("voice"))
	)

	await _cleanup(opening)
	await _cleanup(director)

func _test_margin_figure_reveals_at_the_portrait_beat() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)

	var figure := opening.get_node_or_null("MarginFigure") as Node3D
	_check("opening stages Margin's physical figure at the campfire", figure != null)
	_check("Margin's figure is hidden before her reveal (voice before image)", figure != null and not figure.visible)

	var portrait_index := _first_portrait_beat_index()
	_check("opening has a portrait/Margin reveal beat", portrait_index >= 0)
	await _advance_opening_to_beat(opening, director, portrait_index)

	_check("Margin's figure resolves into view on the reveal beat", figure != null and figure.visible)

	await _cleanup(opening)
	await _cleanup(director)

func _test_gizmo_is_seated_at_the_campfire() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)

	var animator := opening.get_node_or_null("GizmoAnimator")
	_check("opening attaches the Gizmo animation controller", animator != null)
	if animator != null and animator.has_method("is_cinematic_holding"):
		# is_cinematic_holding only latches if campfire_sit actually grafted from
		# the authored clip GLB and is playing — proves Gizmo is seated, not idling.
		_check("Gizmo is seated at the fire (campfire_sit holds the cinematic)", bool(animator.is_cinematic_holding()))
	else:
		_check("Gizmo animation controller exposes the campfire seam", false)

	await _cleanup(opening)
	await _cleanup(director)

func _test_opening_skip_finishes_once() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)

	var finish_count := [0]
	opening.finished.connect(func() -> void: finish_count[0] += 1)
	opening.skip()
	await process_frame
	_check_eq("skip emits finished once", finish_count[0], 1)
	opening.skip()
	await process_frame
	_check_eq("second skip does not re-emit finished", finish_count[0], 1)

	await _cleanup(opening)
	await _cleanup(director)

func _test_opening_skip_during_title_finishes_once() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)
	var title_index := _title_beat_index()
	await _advance_opening_to_beat(opening, director, title_index)

	var finish_count := [0]
	opening.finished.connect(func() -> void: finish_count[0] += 1)
	opening.skip()
	await process_frame
	_check_eq("skip during title emits finished once", finish_count[0], 1)
	opening.skip()
	await process_frame
	_check_eq("second skip during title does not re-emit finished", finish_count[0], 1)

	await _cleanup(opening)
	await _cleanup(director)

func _test_opening_missing_title_sting_is_noop() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var opening := await _new_opening(director)
	opening.title_sting_path = "res://audio/music/__missing_opening_title_for_test.ogg"
	var title_index := _title_beat_index()
	await _advance_opening_to_beat(opening, director, title_index)
	_check_eq("title beat starts with the missing sting path configured", int(opening._beat_index), title_index)

	director.speaking = false
	opening.advance_time(60.0)
	await process_frame
	var title_card := opening.find_child("TitleCard", true, false) as Control
	_check("missing title sting does not block sequence advance", int(opening._beat_index) > title_index)
	_check("title tween fast-forwards and hides the title card", title_card != null and not title_card.visible)

	await _cleanup(opening)
	await _cleanup(director)

func _test_controls_card_teaches_every_control() -> void:
	var card: Node = ControlsCardScene.instantiate()
	root.add_child(card)
	await process_frame

	var rows: Array = card.CONTROL_ROWS
	var keys := ""
	var actions := ""
	for row in rows:
		keys += String(row[0]) + " "
		actions += String(row[1]) + " "
	for expected_key in ["WASD", "LEFT CLICK", "RIGHT CLICK", "Q", "SPACE", "F", "ESC"]:
		_check("controls card lists %s" % expected_key, keys.contains(expected_key))
	for expected_action in ["Move", "Swing", "Special", "Cast", "Dash", "Surge", "Pause"]:
		_check("controls card teaches %s" % expected_action, actions.contains(expected_action))
	_check_eq("controls card is titled HOW TO KEEP", card.TITLE, "HOW TO KEEP")

	var grid := card.find_child("ControlsGrid", true, false)
	_check("controls card builds a row per control", grid != null and grid.get_child_count() == rows.size() * 2)

	card.close()
	_check("controls card close() hides it", not card.is_open())
	card.open()
	_check("controls card open() shows it", card.is_open())

	await _cleanup(card)

func _new_app(seen_path: String) -> Node:
	var app: Node = AppScene.instantiate()
	app.meta_save_path = "%s/meta_%s.cfg" % [TEST_ROOT, str(randi())]
	app.opening_seen_path = seen_path
	root.add_child(app)
	await process_frame
	return app

func _content(app: Node) -> Node:
	var slot := app.get_node("ContentSlot")
	if slot.get_child_count() == 0:
		return null
	return slot.get_child(0)

func _test_app_shell_first_boot_shows_opening_then_hub() -> void:
	var seen_path := _seen_path("first_boot")
	_remove_file(seen_path)
	var app := await _new_app(seen_path)

	var content := _content(app)
	_check("first boot swaps the opening into the content slot", content != null and content.get_script() == OpeningSequenceScript)

	content.emit_signal(&"finished")
	await _flush()
	var after := _content(app)
	_check("opening finished hands off to the hub", after != null and after.get_script() == HubControllerScript)
	_check("opening finished persists the seen flag", OpeningSequenceScript.has_seen(seen_path))

	await _cleanup(app)
	_remove_file(seen_path)

func _test_app_shell_seen_flag_boots_straight_to_hub() -> void:
	var seen_path := _seen_path("seen_boot")
	OpeningSequenceScript.mark_seen(seen_path)
	var app := await _new_app(seen_path)

	var content := _content(app)
	_check("seen flag boots directly into the hub", content != null and content.get_script() == HubControllerScript)

	await _cleanup(app)
	_remove_file(seen_path)

func _test_app_shell_replay_flag_reopens_opening() -> void:
	var seen_path := _seen_path("replay")
	OpeningSequenceScript.mark_seen(seen_path)
	OpeningSequenceScript.replay_requested = true
	var app := await _new_app(seen_path)

	var content := _content(app)
	_check("replay request shows the opening despite the seen flag", content != null and content.get_script() == OpeningSequenceScript)
	_check("replay request is consumed by the opening boot", not OpeningSequenceScript.replay_requested)

	OpeningSequenceScript.replay_requested = false
	await _cleanup(app)
	_remove_file(seen_path)

func _test_speaker_panel_appears_for_guide_lines_only() -> void:
	var director := StubVoiceDirector.new()
	root.add_child(director)
	var panel: Node = SpeakerPanelScene.instantiate()
	panel.audio_director = director
	root.add_child(panel)
	await process_frame

	panel.refresh_from_director()
	_check("speaker panel starts hidden", not panel.is_panel_visible())

	director.play_voice_line(&"margin_sendoff")
	panel.refresh_from_director()
	_check("speaker panel appears while a Margin line plays", panel.is_panel_visible())
	var name_label := panel.find_child("SpeakerNameLabel", true, false) as Label
	_check_eq("speaker panel names the guide", name_label.text, "MARGIN")
	var portrait := panel.find_child("PortraitTexture", true, false) as TextureRect
	_check("speaker panel carries the portrait art", portrait != null and portrait.texture != null)

	director.speaking = false
	panel.refresh_from_director()
	_check("speaker panel hides when the line ends", not panel.is_panel_visible())

	director.play_voice_line(&"pattern_intro")
	panel.refresh_from_director()
	_check("speaker panel stays hidden for non-guide lines", not panel.is_panel_visible())

	await _cleanup(panel)
	await _cleanup(director)

func _test_objective_banner_shows_once_on_first_run_entry() -> void:
	var app_like := Node.new()
	app_like.name = "AppLike"
	var slot := Node.new()
	slot.name = "ContentSlot"
	app_like.add_child(slot)
	var banner: Node = ObjectiveBannerScene.instantiate()
	app_like.add_child(banner)
	root.add_child(app_like)
	await process_frame

	_check("banner starts hidden", not banner.is_banner_visible())
	_check_eq("banner copy is the canon objective", banner.OBJECTIVE_COPY, "Carry the Spark to the Beacon")

	var surface := StubRunSurface.new()
	slot.add_child(surface)
	await _flush()
	_check("banner shows on first run entry", banner.is_banner_visible())
	_check_eq("banner shows once", banner.shown_count, 1)
	var label := banner.find_child("ObjectiveLabel", true, false) as Label
	_check_eq("banner label carries the objective copy", label.text, "Carry the Spark to the Beacon")

	surface.queue_free()
	await _flush()
	var second := StubRunSurface.new()
	slot.add_child(second)
	await _flush()
	_check_eq("banner does not re-show on the second run entry", banner.shown_count, 1)

	await _cleanup(app_like)
