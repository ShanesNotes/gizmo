extends SceneTree

# Headless tests for HZ-041 Brass Sphere hub scene.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata-082 --path godot --script res://tests/run_hub_tests.gd

const HubControllerScript := preload("res://scripts/hub_controller.gd")
const HubScene := preload("res://scenes/hub.tscn")
const MetaState := preload("res://scripts/meta/meta_state.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running hub tests...")
	await _test_hub_scene_instantiates_with_required_nodes()
	await _test_hub_identity_visual_nameplates_and_blocker()
	await _test_run_surface_failure_label_api()
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

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _check_vec3_almost(desc: String, actual: Vector3, expected: Vector3, margin: float = 0.001) -> void:
	_check(
		"%s (got %s, expected %s +/- %.4f)" % [desc, actual, expected, margin],
		actual.distance_to(expected) <= margin
	)

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
	var failure_label := hub.get_node_or_null("HubUi/Root/RunSurfaceFailureLabel") as Label
	_check("run surface failure label exists", failure_label != null)
	if failure_label != null:
		_check("run surface failure label starts hidden", not failure_label.visible)

	await _cleanup(hub)

func _test_hub_identity_visual_nameplates_and_blocker() -> void:
	var hub := await _instantiate_hub()
	var placeholder := hub.get_node_or_null("GizmoPlaceholder") as CharacterBody3D
	_check("hub placeholder remains a CharacterBody3D", placeholder != null)
	if placeholder != null:
		_check("hub placeholder Capsule mesh has been removed", placeholder.get_node_or_null("Capsule") == null)
		_check("hub placeholder has VisualPivot node", placeholder.get_node_or_null("VisualPivot") is Node3D)
		_check("hub placeholder has gizmo.glb Model node", placeholder.get_node_or_null("VisualPivot/Model") is Node3D)
		var visual := placeholder.get_node_or_null("VisualPivot") as Node3D
		var model := placeholder.get_node_or_null("VisualPivot/Model") as Node3D
		_check("hub VisualPivot owns procedural visual script", visual != null and visual.has_method("update_visual"))
		if model != null:
			_check_vec3_almost("hub gizmo.glb uses player-scene scale", model.scale, Vector3(0.875, 0.875, 0.875))
			_check_almost("hub gizmo.glb keeps +Z to -Z yaw flip", absf(model.rotation.y), PI, 0.001)
			_check("hub gizmo.glb skeleton imports under Model", model.get_node_or_null("UniRigArmature/Skeleton3D") is Skeleton3D)
		if visual != null and visual.has_method("update_visual") and visual.has_method("visual_forward_direction"):
			visual.set("turn_speed", 50.0)
			placeholder.velocity = Vector3.RIGHT * 4.0
			visual.call("update_visual", 0.1)
			var forward := Vector3(visual.call("visual_forward_direction"))
			_check("hub visual faces placeholder velocity without player motor", forward.dot(Vector3.RIGHT) > 0.9)

	_check_nameplate(hub, "RunDoor/RunDoorNameplate", "THE RUN", Color(0.96, 0.68, 0.28, 1))
	_check_nameplate(hub, "MirrorAnchor/MirrorNameplate", "MIRROR", Color(0.48, 0.9, 0.58, 1))
	_check_nameplate(hub, "CodexAnchor/CodexNameplate", "CODEX", Color(0.72, 0.52, 1, 1))

	var run_door := hub.get_node_or_null("RunDoor") as Area3D
	var blocker := hub.get_node_or_null("RunDoorVoidBlocker") as StaticBody3D
	var blocker_collision := hub.get_node_or_null("RunDoorVoidBlocker/CollisionShape3D") as CollisionShape3D
	_check("run-door void blocker StaticBody3D exists", blocker != null)
	_check("run-door void blocker collider exists", blocker_collision != null)
	if blocker_collision != null:
		var blocker_box := blocker_collision.shape as BoxShape3D
		_check("run-door void blocker uses a BoxShape3D", blocker_box != null)
		if blocker_box != null:
			_check_vec3_almost("run-door void blocker shape covers the doorway", blocker_box.size, Vector3(3.0, 2.4, 0.35))
	if run_door != null and blocker != null:
		_check("run-door void blocker sits behind the trigger volume", blocker.global_position.z < run_door.global_position.z - 0.5)

	await _cleanup(hub)

func _test_run_surface_failure_label_api() -> void:
	var hub := await _instantiate_hub()
	var failure_label := hub.get_node_or_null("HubUi/Root/RunSurfaceFailureLabel") as Label
	_check("hub exposes run-surface failure API", hub.has_method(&"show_run_surface_load_failure") and hub.has_method(&"clear_run_surface_load_failure"))
	if failure_label != null and hub.has_method(&"show_run_surface_load_failure") and hub.has_method(&"clear_run_surface_load_failure"):
		hub.call(&"show_run_surface_load_failure", "Run surface failed to load - run the import step (see docs/hades-pivot/export.md).")
		_check("failure API shows the label", failure_label.visible)
		_check_eq("failure API writes the visible copy", failure_label.text, "Run surface failed to load - run the import step (see docs/hades-pivot/export.md).")
		hub.call(&"clear_run_surface_load_failure")
		_check("failure API hides the label", not failure_label.visible)

	await _cleanup(hub)

func _check_nameplate(hub: Node, path: String, expected_text: String, expected_color: Color) -> void:
	var label := hub.get_node_or_null(path) as Label3D
	_check("%s nameplate exists" % expected_text, label != null)
	if label == null:
		return
	_check_eq("%s nameplate text" % expected_text, label.text, expected_text)
	_check("%s nameplate uses requested color" % expected_text, label.modulate == expected_color)
	_check("%s nameplate has brass outline" % expected_text, label.outline_size >= 8 and label.outline_modulate.r < 0.2)
	_check("%s nameplate billboards to camera" % expected_text, label.billboard == BaseMaterial3D.BILLBOARD_ENABLED)
	_check("%s nameplate stays readable over geometry" % expected_text, label.no_depth_test)
	_check("%s nameplate font is readable at hub camera" % expected_text, label.font_size >= 36)

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

	hub.meta_state = null
	_check_eq("scrap label clears when meta state is explicitly nulled", scrap_label.text, "SCRAP 0")

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
