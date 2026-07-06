extends SceneTree

# Headless tests for HZ-041 Brass Sphere hub scene.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_hub_tests.gd

const HubControllerScript := preload("res://scripts/hub_controller.gd")
const HubScene := preload("res://scenes/hub.tscn")
const MetaState := preload("res://scripts/meta/meta_state.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running hub tests...")
	await _test_hub_scene_instantiates_with_required_nodes()
	await _test_scrap_label_reflects_injected_meta_state()
	await _test_run_requested_emits_once_per_door_entry()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => hub tests failed to load/compile)" if _passed == 0 else ""]
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

func _instantiate_hub(meta_state: MetaState = null) -> Node:
	var hub := HubScene.instantiate()
	if meta_state != null:
		hub.meta_state = meta_state
	root.add_child(hub)
	await process_frame
	return hub

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_hub_scene_instantiates_with_required_nodes() -> void:
	var hub := await _instantiate_hub()

	_check("hub scene has HubController script", hub.get_script() == HubControllerScript)
	_check("HubSpawn marker exists", hub.get_node_or_null("HubSpawn") is Marker3D)
	_check("RunDoor Area3D exists", hub.get_node_or_null("RunDoor") is Area3D)
	_check("MirrorAnchor marker exists", hub.get_node_or_null("MirrorAnchor") is Marker3D)
	_check("CodexAnchor marker exists", hub.get_node_or_null("CodexAnchor") is Marker3D)
	_check("placeholder Gizmo body is a CharacterBody3D", hub.get_node_or_null("GizmoPlaceholder") is CharacterBody3D)
	_check("scrap display label exists", hub.get_node_or_null("HubUi/Root/ScrapLabel") is Label)

	await _cleanup(hub)

func _test_scrap_label_reflects_injected_meta_state() -> void:
	var meta_state: MetaState = MetaState.new()
	meta_state.scrap_banked = 123
	var hub := await _instantiate_hub(meta_state)
	var scrap_label := hub.get_node("HubUi/Root/ScrapLabel") as Label

	_check_eq("scrap label reflects injected meta state on ready", scrap_label.text, "SCRAP 123")

	var next_meta_state: MetaState = MetaState.new()
	next_meta_state.scrap_banked = 7
	hub.meta_state = next_meta_state
	_check_eq("scrap label refreshes when meta state is reinjected", scrap_label.text, "SCRAP 7")

	await _cleanup(hub)

func _test_run_requested_emits_once_per_door_entry() -> void:
	var hub := await _instantiate_hub()
	var run_door := hub.get_node("RunDoor") as Area3D
	var body := CharacterBody3D.new()
	body.name = "DoorHarnessBody"
	root.add_child(body)
	var request_state := {"count": 0}
	hub.run_requested.connect(func() -> void:
		request_state["count"] = int(request_state["count"]) + 1
	)

	run_door.emit_signal(&"body_entered", body)
	run_door.emit_signal(&"body_entered", body)
	_check_eq("duplicate body_entered during one overlap emits once", int(request_state["count"]), 1)

	run_door.emit_signal(&"body_exited", body)
	run_door.emit_signal(&"body_entered", body)
	_check_eq("body_entered after exit emits a second run request", int(request_state["count"]), 2)

	var scenery := Node3D.new()
	root.add_child(scenery)
	run_door.emit_signal(&"body_exited", body)
	run_door.emit_signal(&"body_entered", scenery)
	_check_eq("non-CharacterBody3D door overlaps are ignored", int(request_state["count"]), 2)

	scenery.queue_free()
	body.queue_free()
	await process_frame
	await _cleanup(hub)
