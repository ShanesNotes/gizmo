extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const PlayerAvatar3DScript := preload("res://scripts/player_avatar_3d.gd")
const SimSpaceScript := preload("res://scripts/sim_space.gd")
const CameraRig3DScript := preload("res://scripts/camera_rig_3d.gd")
const HudPresenterScript := preload("res://scripts/hud_presenter.gd")

var _failures: int = 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_input_map_actions()
	_test_player_avatar_scene()
	await _test_main_scene_uses_input()
	await _test_completion_message_comes_from_simulation()

	if _failures == 0:
		print("Player scene tests passed")
	else:
		printerr("Player scene tests failed: %d" % _failures)
	quit(_failures)

func _test_input_map_actions() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		_assert_true(InputMap.has_action(action), "InputMap has %s" % action)

func _test_player_avatar_scene() -> void:
	var player := PlayerScene.instantiate()
	get_root().add_child(player)
	_assert_true(player is Node3D, "player scene root is a display-only Node3D")
	_assert_true(player.get_script() == PlayerAvatar3DScript, "player scene root uses PlayerAvatar3D script")
	_assert_true(not (player is CharacterBody3D), "player scene does not own character-body movement")
	_assert_true(not (player is RigidBody3D), "player scene does not own rigid-body physics")
	_assert_true(not (player is Area3D), "player scene does not own area/collision sensing")
	_assert_true(player.has_node("Visuals"), "player has Visuals node")
	_assert_true(player.has_node("Visuals/FaceMarker"), "player has facing marker")
	var snapshot: Dictionary = {"x": 1400.0, "y": 950.0, "facing_x": -1.0}
	var snapshot_before: String = var_to_str(snapshot)
	player.apply_snapshot(snapshot)
	_assert_equal(var_to_str(snapshot), snapshot_before, "apply_snapshot does not mutate player snapshot")
	_assert_vector3_approx(player.global_position, SimSpaceScript.to_world(Vector2(1400.0, 950.0)), "apply_snapshot maps sim x/y through SimSpace")
	_assert_true(float(player.get_node("Visuals/FaceMarker").position.x) < 0.0, "apply_snapshot flips marker left")
	player.queue_free()

func _test_main_scene_uses_input() -> void:
	var main := MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	var player := main.get_node("World/Entities/PlayerAvatar")
	_assert_true(main is Node3D, "main scene root is Node3D")
	_assert_true(player != null, "main scene has PlayerAvatar")
	_assert_true(player is Node3D, "main PlayerAvatar is Node3D")
	_assert_true(main.has_node("CameraRig/Camera3D"), "main scene has Camera3D")
	_assert_true(main.get_node("CameraRig").get_script() == CameraRig3DScript, "CameraRig uses CameraRig3D presenter")
	_assert_true(main.get_node("HUD").get_script() == HudPresenterScript, "HUD uses HudPresenter")
	_assert_true(not main.has_node("CameraRig/Camera2D"), "main scene no longer has Camera2D")
	_assert_true(main.has_node("HUD/Root/Title"), "main scene keeps HUD title")
	var ground := main.get_node("World/Ground") as MeshInstance3D
	var ground_plane := ground.mesh as PlaneMesh
	_assert_vector3_approx(Vector3(ground_plane.size.x, 0.0, ground_plane.size.y), Vector3(26.0, 0.0, 17.0), "main ground derives the sim world extent")
	var camera := main.get_node("CameraRig/Camera3D") as Camera3D
	_assert_true(camera.current, "Camera3D is current")
	_assert_equal(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "Camera3D is orthographic")
	_assert_approx(camera.size, 14.4, "Camera3D starts at readable orthographic size")
	var start_x: float = float(main.state["player"]["x"])
	Input.action_press(&"move_right")
	main._physics_process(0.05)
	Input.action_release(&"move_right")
	_assert_true(float(main.state["player"]["x"]) > start_x, "move_right input advances simulation player")
	_assert_vector3_approx(player.global_position, SimSpaceScript.to_world_from_snapshot(main.state["player"]), "PlayerAvatar follows simulation through SimSpace")
	_assert_vector3_approx(main.get_node("CameraRig").global_position, SimSpaceScript.to_world_from_snapshot(main.state["player"]), "CameraRig presenter follows the raw SimSpace target")
	main.queue_free()

func _test_completion_message_comes_from_simulation() -> void:
	var main := MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.state["phase"] = "complete"
	main.state["message"] = "Four minutes survived. The playground is yours."
	main._apply_state()
	var title := main.get_node("HUD/Root/Title") as Label
	_assert_true(title.text == "Four minutes survived. The playground is yours.", "completion title uses simulation message")
	main.queue_free()

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_failures += 1
		printerr("FAIL %s" % label)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_approx(actual: Variant, expected: float, label: String, epsilon: float = 0.0001) -> void:
	if abs(float(actual) - expected) > epsilon:
		_failures += 1
		printerr("FAIL %s: expected %.4f, got %.4f" % [label, expected, float(actual)])

func _assert_vector3_approx(actual: Vector3, expected: Vector3, label: String, epsilon: float = 0.0001) -> void:
	_assert_approx(actual.x, expected.x, "%s x" % label, epsilon)
	_assert_approx(actual.y, expected.y, "%s y" % label, epsilon)
	_assert_approx(actual.z, expected.z, "%s z" % label, epsilon)
