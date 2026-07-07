extends SceneTree

# Headless tests for HZ-060 authored room template pool.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_room_pool_tests.gd

const RoomSceneValidator := preload("res://scripts/room_graph/room_scene_validator.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")

const TEMPLATE_DIR := "res://resources/room_templates"

const EXPECTED_TYPES := {
	"combat_small": RoomTemplate.RoomType.COMBAT,
	"combat_large": RoomTemplate.RoomType.COMBAT,
	"elite_arena": RoomTemplate.RoomType.ELITE,
	"boss_arena": RoomTemplate.RoomType.BOSS,
	"rest_alcove": RoomTemplate.RoomType.REST,
	"reward_cache": RoomTemplate.RoomType.REWARD,
	"shop_small": RoomTemplate.RoomType.SHOP,
}

const EXPECTED_EXIT_RANGES := {
	"combat_small": Vector2i(1, 2),
	"combat_large": Vector2i(1, 2),
	"elite_arena": Vector2i(1, 1),
	"boss_arena": Vector2i(1, 1),
	"rest_alcove": Vector2i(1, 1),
	"reward_cache": Vector2i(1, 1),
	"shop_small": Vector2i(1, 1),
}

const EXPECTED_DOORS := {
	"combat_small": ["RoomExitA", "RoomExitB"],
	"combat_large": ["RoomExitA", "RoomExitB"],
	"elite_arena": ["RoomExit"],
	"boss_arena": ["RoomExit"],
	"rest_alcove": ["RoomExit"],
	"reward_cache": ["RoomExit"],
	"shop_small": ["RoomExit"],
}

const EXPECTED_FIXTURES := {
	"rest_alcove": "RestFixture",
	"reward_cache": "RewardFixture",
}

const EXPECTED_FIXTURE_METHODS := {
	"rest_alcove": "refill_guard",
	"reward_cache": "grant_scrap",
}

# The shop is a shop (playtest 2): a safe interior with a merchant fixture and
# three walk-over purchase pedestals wired to the run-scrap economy.
const EXPECTED_SHOP_OFFER_FIXTURES := ["ShopOfferGuard", "ShopOfferAmmo", "ShopOfferReroll"]

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room template pool tests...")
	_test_expected_template_set()
	_test_templates_validate_and_match_metadata()
	_test_combat_templates_carry_spawn_clear_dressing_variants()
	_test_shop_interior_is_a_safe_shop()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => room template pool failed to load/compile)" if _passed == 0 else ""]
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

func _test_expected_template_set() -> void:
	var actual_ids := _template_ids()
	var expected_ids := EXPECTED_TYPES.keys()
	actual_ids.sort()
	expected_ids.sort()

	_check_eq("template pool contains the expected authored fixtures", actual_ids, expected_ids)

func _test_templates_validate_and_match_metadata() -> void:
	for path in _template_paths():
		var template := _load_template(path)
		if template == null:
			continue

		var template_id := path.get_file().get_basename()
		var expected_range: Vector2i = EXPECTED_EXIT_RANGES[template_id]

		_check_eq("%s template_id matches filename" % template_id, template.template_id, template_id)
		_check_eq("%s biome_id is hearth" % template_id, template.biome_id, "hearth")
		_check_eq("%s room_type matches pool contract" % template_id, template.room_type, EXPECTED_TYPES[template_id])
		_check_eq("%s min_exits matches door contract" % template_id, template.min_exits, expected_range.x)
		_check_eq("%s max_exits matches door contract" % template_id, template.max_exits, expected_range.y)
		_check("%s scene is assigned" % template_id, template.scene != null)
		if template.scene == null:
			continue

		var expected_scene_path := "res://scenes/rooms/%s.tscn" % template_id
		_check_eq("%s scene path matches template id" % template_id, template.scene.resource_path, expected_scene_path)

		var violations: Array[String] = RoomSceneValidator.validate(template.scene)
		_check_eq("%s validates cleanly" % template_id, violations, [])

		var instance := template.scene.instantiate()
		_check("%s scene instantiates as Node3D" % template_id, instance is Node3D)
		if instance == null:
			continue

		_assert_scene_authoring_contract(template_id, instance)
		instance.free()

# Landmark dressing (landmark-taxonomy.yaml): combat rooms carry authored
# greybox prop variants; exactly one survives per run room (picked by seed in
# the orchestrator). Props must never intrude on the spawn containment box so
# the containment/separation pins stay green.
const EXPECTED_DRESSING_VARIANTS := {
	"combat_small": 3,
	"combat_large": 3,
}
const SPAWN_KEEP_OUT_MARGIN := 0.25

func _test_combat_templates_carry_spawn_clear_dressing_variants() -> void:
	for template_id in EXPECTED_DRESSING_VARIANTS.keys():
		var template := _load_template("%s/%s.tres" % [TEMPLATE_DIR, template_id])
		if template == null or template.scene == null:
			_check("%s dressing test has a loadable scene" % template_id, false)
			continue
		var instance := template.scene.instantiate()
		_assert_dressing_contract(template_id, instance)
		instance.free()

func _assert_dressing_contract(template_id: String, root_node: Node) -> void:
	var anchor := root_node.find_child("CameraAnchor", true, false) as Marker3D
	_check("%s dressing test finds CameraAnchor" % template_id, anchor != null)
	if anchor == null:
		return
	var keep_out_half := Vector2(
		float(anchor.get_meta("camera_half_extent_x", 0.0)) + SPAWN_KEEP_OUT_MARGIN,
		float(anchor.get_meta("camera_half_extent_z", 0.0)) + SPAWN_KEEP_OUT_MARGIN
	)
	var keep_out_center := Vector2(anchor.position.x, anchor.position.z)

	var variants: Array[Node] = []
	for node in _flatten_nodes(root_node):
		if String(node.name).begins_with("DressingVariant"):
			variants.append(node)
	_check_eq(
		"%s carries the authored dressing variant count" % template_id,
		variants.size(),
		EXPECTED_DRESSING_VARIANTS[template_id]
	)

	for variant in variants:
		var props: Array[CSGBox3D] = []
		for node in _flatten_nodes(variant):
			if node is CSGBox3D:
				props.append(node)
		_check("%s %s has at least two greybox props" % [template_id, variant.name], props.size() >= 2)
		for prop in props:
			_check(
				"%s %s prop %s stays outside the spawn containment box" % [template_id, variant.name, prop.name],
				_prop_outside_keep_out(prop, root_node, keep_out_center, keep_out_half)
			)
			_check(
				"%s %s prop %s keeps collision for readable blocking" % [template_id, variant.name, prop.name],
				prop.use_collision
			)

func _test_shop_interior_is_a_safe_shop() -> void:
	var template := _load_template("%s/shop_small.tres" % TEMPLATE_DIR)
	if template == null or template.scene == null:
		_check("shop interior test has a loadable scene", false)
		return
	var instance := template.scene.instantiate()

	var merchant := instance.find_child("MerchantFixture", true, false)
	_check("shop has a MerchantFixture set-piece", merchant is Node3D)

	for fixture_name in EXPECTED_SHOP_OFFER_FIXTURES:
		var fixture := _find_area3d_named(instance, fixture_name)
		_check("shop has walk-over offer fixture %s" % fixture_name, fixture != null)
		if fixture == null:
			continue
		_check("%s has a CollisionShape3D" % fixture_name, _area_has_collision_shape(fixture))
		_check("%s uses the purchase fixture seam" % fixture_name, fixture.has_method("purchase_offer"))
		_check("%s carries a shop offer id" % fixture_name, String(fixture.get("shop_offer_id")) != "")
		_check("%s shows a price tag" % fixture_name, fixture.find_child("PriceTag", true, false) is Label3D)

	_check_eq("shop has no authored enemy nodes", _count_named_prefix(instance, "Enemy"), 0)
	instance.free()

func _prop_outside_keep_out(prop: CSGBox3D, root_node: Node, center: Vector2, half: Vector2) -> bool:
	var to_room := _room_space_transform(prop, root_node)
	var extents: Vector3 = prop.size * 0.5
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var corner := to_room * Vector3(extents.x * sx, extents.y * sy, extents.z * sz)
				min_x = minf(min_x, corner.x)
				max_x = maxf(max_x, corner.x)
				min_z = minf(min_z, corner.z)
				max_z = maxf(max_z, corner.z)
	return (
		max_x < center.x - half.x
		or min_x > center.x + half.x
		or max_z < center.y - half.y
		or min_z > center.y + half.y
	)

func _room_space_transform(node: Node3D, root_node: Node) -> Transform3D:
	var accumulated := Transform3D.IDENTITY
	var cursor: Node = node
	while cursor != null and cursor != root_node:
		if cursor is Node3D:
			accumulated = (cursor as Node3D).transform * accumulated
		cursor = cursor.get_parent()
	return accumulated

func _load_template(path: String) -> RoomTemplate:
	var resource := load(path)
	_check("%s loads" % path, resource != null)
	if resource == null:
		return null

	_check("%s is RoomTemplate" % path, resource is RoomTemplate)
	if not resource is RoomTemplate:
		return null
	return resource as RoomTemplate

func _assert_scene_authoring_contract(template_id: String, root_node: Node) -> void:
	var floor := root_node.find_child("Floor", true, false)
	_check("%s has a Floor CSGBox3D" % template_id, floor is CSGBox3D)

	var obstacle_count := _count_named_prefix(root_node, "Obstacle")
	_check("%s has at least three obstacle blocks" % template_id, obstacle_count >= 3)

	var anchor := root_node.find_child("CameraAnchor", true, false)
	_check("%s CameraAnchor is a Marker3D" % template_id, anchor is Marker3D)
	if anchor is Marker3D:
		_check("%s CameraAnchor has X half-extent metadata" % template_id, anchor.has_meta("camera_half_extent_x"))
		_check("%s CameraAnchor has Z half-extent metadata" % template_id, anchor.has_meta("camera_half_extent_z"))
		var half_extent_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
		var half_extent_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
		_check("%s CameraAnchor extents are positive" % template_id, half_extent_x > 0.0 and half_extent_z > 0.0)

	var expected_doors: Array = EXPECTED_DOORS[template_id]
	_assert_exact_door_set(template_id, root_node, expected_doors)

	if EXPECTED_FIXTURES.has(template_id):
		var fixture_name: String = EXPECTED_FIXTURES[template_id]
		var fixture := _find_area3d_named(root_node, fixture_name)
		_check("%s has authored Area3D fixture %s" % [template_id, fixture_name], fixture != null)
		if fixture != null:
			_check("%s fixture has a CollisionShape3D" % template_id, _area_has_collision_shape(fixture))
			_check("%s fixture exposes its runtime method" % template_id, fixture.has_method(EXPECTED_FIXTURE_METHODS[template_id]))
		_check_eq("%s has no authored enemy nodes" % template_id, _count_named_prefix(root_node, "Enemy"), 0)
		_check_eq("%s has no authored enemy spawn nodes" % template_id, _count_named_prefix(root_node, "EnemySpawn"), 0)

func _assert_exact_door_set(template_id: String, root_node: Node, expected_doors: Array) -> void:
	for door_name in ["RoomExit", "RoomExitA", "RoomExitB"]:
		var door := _find_area3d_named(root_node, door_name)
		var should_exist := expected_doors.has(door_name)
		_check_eq("%s %s presence" % [template_id, door_name], door != null, should_exist)
		if door != null:
			_check("%s %s has a CollisionShape3D" % [template_id, door_name], _area_has_collision_shape(door))

func _find_area3d_named(root_node: Node, node_name: String) -> Area3D:
	var node := root_node.find_child(node_name, true, false)
	if node is Area3D:
		return node
	return null

func _area_has_collision_shape(area: Area3D) -> bool:
	for child in area.get_children():
		if child is CollisionShape3D and child.shape != null:
			return true
	return false

func _count_named_prefix(root_node: Node, prefix: String) -> int:
	var count := 0
	for node in _flatten_nodes(root_node):
		if String(node.name).begins_with(prefix):
			count += 1
	return count

func _flatten_nodes(root_node: Node) -> Array[Node]:
	var nodes: Array[Node] = [root_node]
	for child in root_node.get_children():
		nodes.append_array(_flatten_nodes(child))
	return nodes

func _template_ids() -> Array:
	var ids := []
	for path in _template_paths():
		ids.append(path.get_file().get_basename())
	return ids

func _template_paths() -> Array[String]:
	var paths: Array[String] = []
	for file_name in DirAccess.get_files_at(TEMPLATE_DIR):
		if file_name.ends_with(".tres"):
			paths.append("%s/%s" % [TEMPLATE_DIR, file_name])
	paths.sort()
	return paths
