extends SceneTree

const MainScene: PackedScene = preload("res://scenes/main.tscn")
const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const PlayerAvatar3DScript := preload("res://scripts/player_avatar_3d.gd")
const SimSpaceScript := preload("res://scripts/sim_space.gd")
const CameraRig3DScript := preload("res://scripts/camera_rig_3d.gd")
const HudPresenterScript := preload("res://scripts/hud_presenter.gd")
const SimulationScript := preload("res://scripts/simulation.gd")

var _failures: int = 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_center_maps_to_origin()
	_test_world_bounds_are_symmetric()
	_test_radius_scale()
	_test_snapshot_mapping_does_not_mutate_sim_state()
	await _test_main_scene_2_5d_contract()
	await _test_player_presentation_3d_contract()

	if _failures == 0:
		print("Presentation 3D tests passed")
	else:
		printerr("Presentation 3D tests failed: %d" % _failures)
	quit(_failures)

func _test_center_maps_to_origin() -> void:
	var world_position: Vector3 = SimSpaceScript.to_world(Vector2(1300.0, 850.0))
	_assert_vector3_approx(world_position, Vector3.ZERO, "sim center maps to stage origin")
	_assert_vector2_approx(SimSpaceScript.to_sim(world_position), Vector2(1300.0, 850.0), "stage origin maps back to sim center")

func _test_world_bounds_are_symmetric() -> void:
	var top_left: Vector3 = SimSpaceScript.to_world(Vector2.ZERO)
	var bottom_right: Vector3 = SimSpaceScript.to_world(Vector2(2600.0, 1700.0))
	_assert_vector3_approx(top_left, Vector3(-13.0, 0.0, -8.5), "top-left sim bound maps to negative stage extent")
	_assert_vector3_approx(bottom_right, Vector3(13.0, 0.0, 8.5), "bottom-right sim bound maps to positive stage extent")
	_assert_vector2_approx(SimSpaceScript.world_size_to_stage({"width": 2600, "height": 1700}), Vector2(26.0, 17.0), "world size maps to stage meters")

func _test_radius_scale() -> void:
	_assert_approx(SimSpaceScript.to_world_radius(70.0), 0.7, "radius scales from sim units to meters")

func _test_snapshot_mapping_does_not_mutate_sim_state() -> void:
	var simulation: Simulation = SimulationScript.new()
	var state: Dictionary = simulation.create_game_state()
	var player_before: String = var_to_str(state["player"])
	var state_before: String = var_to_str(state)
	var mapped: Vector3 = SimSpaceScript.to_world_from_snapshot(state["player"])
	_assert_vector3_approx(mapped, Vector3.ZERO, "player snapshot maps through SimSpace")
	_assert_equal(var_to_str(state["player"]), player_before, "SimSpace does not mutate player snapshot")
	_assert_equal(var_to_str(state), state_before, "SimSpace does not mutate state")

func _test_main_scene_2_5d_contract() -> void:
	var main := MainScene.instantiate()
	get_root().add_child(main)
	await process_frame
	_assert_true(main is Node3D, "main scene root is Node3D")
	_assert_true(main.has_node("World/Ground"), "main scene has quiet 3D ground")
	var ground := main.get_node("World/Ground") as MeshInstance3D
	var ground_plane := ground.mesh as PlaneMesh
	_assert_vector2_approx(ground_plane.size, SimSpaceScript.world_size_to_stage(main.state["world"]), "ground plane size is derived from SimSpace world size")
	_assert_true(main.has_node("CameraRig/Camera3D"), "main scene has Camera3D")
	_assert_true(main.get_node("CameraRig").get_script() == CameraRig3DScript, "CameraRig has its presenter script")
	_assert_true(main.get_node("HUD").get_script() == HudPresenterScript, "HUD has its presenter script")
	_assert_true(not main.has_node("CameraRig/Camera2D"), "main scene has no stale Camera2D")
	_assert_true(main.has_node("HUD/Root/Title"), "main scene keeps screen-space HUD")
	var camera := main.get_node("CameraRig/Camera3D") as Camera3D
	_assert_true(camera.current, "Camera3D is current")
	_assert_equal(camera.projection, Camera3D.PROJECTION_ORTHOGONAL, "Camera3D is orthographic")
	_assert_approx(camera.size, 14.4, "Camera3D uses starter readable orthographic size")
	main.queue_free()

func _test_player_presentation_3d_contract() -> void:
	var player := PlayerScene.instantiate()
	get_root().add_child(player)
	await process_frame
	_assert_true(player is Node3D, "player presenter root is Node3D")
	_assert_true(player.get_script() == PlayerAvatar3DScript, "player presenter uses PlayerAvatar3D script")
	_assert_true(not (player is CharacterBody3D), "player presenter does not own character-body movement")
	_assert_true(not (player is RigidBody3D), "player presenter does not own rigid-body physics")
	_assert_true(not (player is Area3D), "player presenter does not own area/collision sensing")
	_assert_true(player.has_method("apply_snapshot"), "player presenter applies simulation snapshots")
	var snapshot: Dictionary = {"x": 1200.0, "y": 800.0, "facing_x": 1.0}
	var snapshot_before: String = var_to_str(snapshot)
	player.apply_snapshot(snapshot)
	_assert_equal(var_to_str(snapshot), snapshot_before, "player presenter does not mutate snapshots")
	_assert_vector3_approx(player.global_position, SimSpaceScript.to_world(Vector2(1200.0, 800.0)), "player presenter maps through SimSpace")
	player.queue_free()

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

func _assert_vector2_approx(actual: Vector2, expected: Vector2, label: String, epsilon: float = 0.0001) -> void:
	_assert_approx(actual.x, expected.x, "%s x" % label, epsilon)
	_assert_approx(actual.y, expected.y, "%s y" % label, epsilon)

func _assert_vector3_approx(actual: Vector3, expected: Vector3, label: String, epsilon: float = 0.0001) -> void:
	_assert_approx(actual.x, expected.x, "%s x" % label, epsilon)
	_assert_approx(actual.y, expected.y, "%s y" % label, epsilon)
	_assert_approx(actual.z, expected.z, "%s z" % label, epsilon)
