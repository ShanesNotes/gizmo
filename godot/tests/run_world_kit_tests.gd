extends SceneTree

# Headless tests for landmark/world-kit wrapper states and threshold kit-bashes.
# Run with:
#   godot --headless --path godot --script res://tests/run_world_kit_tests.gd

const BeaconLandmarkScript := preload("res://assets/landmarks/beacon_01/beacon_landmark.gd")
const GearGateScript := preload("res://assets/world_kits/clockwork_observatory/gear_gate_01/gear_gate.gd")

const BEACON_SCENE := "res://assets/landmarks/beacon_01/beacon_01.tscn"
const GEAR_GATE_SCENE := "res://assets/world_kits/clockwork_observatory/gear_gate_01/gear_gate_01.tscn"
const BRIDGE_ARCH_SCENE := "res://assets/world_kits/clockwork_observatory/bridge_arch_01/bridge_arch_01.tscn"

const CORRIDOR_MIN := Vector3(-1.2, 0.1, -1.0)
const CORRIDOR_MAX := Vector3(1.2, 2.4, 1.0)

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running world kit tests...")
	_test_beacon_state_driving()
	_test_gear_gate_open_state()
	_test_bridge_arch_collision_clearance()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => world kit tests failed to load/compile)" if _passed == 0 else ""]
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

func _test_beacon_state_driving() -> void:
	var instance := _instantiate_scene(BEACON_SCENE)
	if instance == null:
		return

	_check("beacon_01 instantiates as Node3D", instance is Node3D)
	_check("beacon_01 root uses BeaconLandmark script", instance.get_script() == BeaconLandmarkScript)

	var hearth_light := instance.get_node_or_null("HearthLight") as OmniLight3D
	_check("beacon_01 has HearthLight OmniLight3D", hearth_light != null)
	if hearth_light != null:
		_check("beacon_01 DORMANT sets HearthLight energy to 0", is_equal_approx(hearth_light.light_energy, 0.0))
		instance.set("state", BeaconLandmarkScript.BeaconState.REKINDLED)
		_check("beacon_01 REKINDLED raises HearthLight energy", hearth_light.light_energy > 0.0)
	instance.free()

func _test_gear_gate_open_state() -> void:
	var instance := _instantiate_scene(GEAR_GATE_SCENE)
	if instance == null:
		return

	_check("gear_gate_01 instantiates as Node3D", instance is Node3D)
	_check("gear_gate_01 root uses GearGate script", instance.get_script() == GearGateScript)

	var body_shape := instance.get_node_or_null("Collision/BodyShape") as CollisionShape3D
	var model := instance.get_node_or_null("Model") as Node3D
	_check("gear_gate_01 has BodyShape collision", body_shape != null)
	_check("gear_gate_01 has Model node", model != null)
	if body_shape != null:
		_check("gear_gate_01 starts closed with BodyShape enabled", not body_shape.disabled)
	if body_shape != null and model != null:
		instance.set("open", true)
		_check("gear_gate_01 open disables BodyShape outside tree", body_shape.disabled)
		_check("gear_gate_01 open sinks Model outside tree", model.position.y < 0.0)
	instance.free()

func _test_bridge_arch_collision_clearance() -> void:
	var instance := _instantiate_scene(BRIDGE_ARCH_SCENE)
	if instance == null:
		return

	_check("bridge_arch_01 instantiates as Node3D", instance is Node3D)
	var node3d_children := 0
	for child in instance.get_children():
		if child is Node3D:
			node3d_children += 1
	_check("bridge_arch_01 has at least three Node3D children", node3d_children >= 3)

	var blocking_shapes: Array[String] = []
	for node in _flatten_nodes(instance):
		if not node is CollisionShape3D:
			continue
		var collision_shape := node as CollisionShape3D
		if collision_shape.disabled or collision_shape.shape == null:
			continue
		var half_extents := _shape_half_extents(collision_shape.shape)
		_check(
			"bridge_arch_01 %s has supported shape extents" % instance.get_path_to(collision_shape),
			half_extents.x >= 0.0
		)
		if half_extents.x < 0.0:
			blocking_shapes.append(String(instance.get_path_to(collision_shape)))
			continue
		if _shape_overlaps_corridor(collision_shape, instance, half_extents):
			blocking_shapes.append(String(instance.get_path_to(collision_shape)))

	_check_eq("bridge_arch_01 keeps the walk-through corridor collision-clear", blocking_shapes, [])
	instance.free()

func _instantiate_scene(path: String) -> Node:
	var scene := _load_scene(path)
	if scene == null:
		return null
	var instance := scene.instantiate()
	_check("%s instantiates" % path, instance != null)
	return instance

func _load_scene(path: String) -> PackedScene:
	var resource := load(path)
	_check("%s loads" % path, resource != null)
	if resource == null:
		return null

	_check("%s is PackedScene" % path, resource is PackedScene)
	if not resource is PackedScene:
		return null
	return resource as PackedScene

func _shape_half_extents(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		return (shape as BoxShape3D).size * 0.5
	if shape is SphereShape3D:
		var sphere := shape as SphereShape3D
		return Vector3.ONE * sphere.radius
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		return Vector3(cylinder.radius, cylinder.height * 0.5, cylinder.radius)
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		return Vector3(capsule.radius, capsule.height * 0.5, capsule.radius)
	return Vector3(-1.0, -1.0, -1.0)

func _shape_overlaps_corridor(collision_shape: CollisionShape3D, root_node: Node, half_extents: Vector3) -> bool:
	var to_root := _root_space_transform(collision_shape, root_node)
	var basis := to_root.basis
	var world_half := Vector3(
		absf(basis.x.x) * half_extents.x + absf(basis.y.x) * half_extents.y + absf(basis.z.x) * half_extents.z,
		absf(basis.x.y) * half_extents.x + absf(basis.y.y) * half_extents.y + absf(basis.z.y) * half_extents.z,
		absf(basis.x.z) * half_extents.x + absf(basis.y.z) * half_extents.y + absf(basis.z.z) * half_extents.z
	)
	var shape_min := to_root.origin - world_half
	var shape_max := to_root.origin + world_half
	return _boxes_overlap(shape_min, shape_max, CORRIDOR_MIN, CORRIDOR_MAX)

func _boxes_overlap(min_a: Vector3, max_a: Vector3, min_b: Vector3, max_b: Vector3) -> bool:
	return (
		min_a.x <= max_b.x
		and max_a.x >= min_b.x
		and min_a.y <= max_b.y
		and max_a.y >= min_b.y
		and min_a.z <= max_b.z
		and max_a.z >= min_b.z
	)

func _root_space_transform(node: Node3D, root_node: Node) -> Transform3D:
	var accumulated := Transform3D.IDENTITY
	var cursor: Node = node
	while cursor != null and cursor != root_node:
		if cursor is Node3D:
			accumulated = accumulated * (cursor as Node3D).transform
		cursor = cursor.get_parent()
	return accumulated

func _flatten_nodes(root_node: Node) -> Array[Node]:
	var nodes: Array[Node] = [root_node]
	for child in root_node.get_children():
		nodes.append_array(_flatten_nodes(child))
	return nodes
