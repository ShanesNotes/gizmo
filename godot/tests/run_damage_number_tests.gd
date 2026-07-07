extends SceneTree

# Headless tests for pooled/tiered damage numbers.
# Run with:
#   godot --headless --path godot --user-data-dir /tmp/godot-night-core --script res://tests/run_damage_number_tests.gd

const DamageNumbersScript := preload("res://scripts/fx/damage_numbers.gd")
const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")
const GreyboxEnemyScene := preload("res://scenes/enemies/greybox_enemy.tscn")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running damage number tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_pop_acquires_and_releases()
	await _test_pool_cap_drops_overflow()
	await _test_merge_window_sums_same_origin()
	await _test_tier_mapping()
	await _test_reuse_reset()
	await _test_enemy_take_damage_routes_opts_to_group()
	await _test_enemy_take_damage_falls_back_without_group()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => damage number tests failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("OK ", desc)
	else:
		_failed += 1
		printerr("FAIL %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _new_fx() -> Node:
	var fx := DamageNumbersScript.new() as Node
	fx.name = "DamageNumbersFx"
	root.add_child(fx)
	await process_frame
	return fx

func _new_enemy():
	var enemy = GreyboxEnemyScene.instantiate()
	root.add_child(enemy)
	await process_frame
	return enemy

func _cleanup(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	await process_frame

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout
	await process_frame

func _pop(fx: Node, origin: Vector3, amount: float, opts: Dictionary = {}) -> void:
	fx.call("pop", origin, amount, opts)

func _available_count(fx: Node) -> int:
	return int(fx.call("available_count"))

func _in_use_count(fx: Node) -> int:
	return int(fx.call("in_use_count"))

func _total_count(fx: Node) -> int:
	return int(fx.call("total_count"))

func _test_pop_acquires_and_releases() -> void:
	var fx = await _new_fx()
	var available_before := _available_count(fx)
	_pop(fx, Vector3(1.0, 0.0, 1.0), 7.0)
	_check_eq("pop acquires one label from the pool", _in_use_count(fx), 1)
	_check_eq("pop removes one available label", _available_count(fx), available_before - 1)
	await _wait(0.8)
	_check_eq("finished tween releases the label", _in_use_count(fx), 0)
	_check_eq("released label returns to available pool", _available_count(fx), _total_count(fx))
	await _cleanup(fx)

func _test_pool_cap_drops_overflow() -> void:
	var fx = await _new_fx()
	for i in range(60):
		_pop(fx, Vector3(float(i), 0.0, 2.0), 1.0)
	_check_eq("sixty rapid pops never allocate past pool cap", _total_count(fx), 48)
	_check_eq("overflow pops are dropped while cap labels remain active", _in_use_count(fx), 48)
	# Perf gate (HZ-107B stretch): the scene tree itself stays bounded — the pool
	# cap must hold at the tree level, not just in the pool's own ledger.
	var tree_nodes := PerfProbe.count_nodes(fx)
	_check("pop flood keeps the fx subtree at or under cap + host (got %d)" % tree_nodes, tree_nodes <= 49)
	await _cleanup(fx)

func _test_merge_window_sums_same_origin() -> void:
	var fx = await _new_fx()
	_pop(fx, Vector3.ZERO, 10.0)
	_pop(fx, Vector3(0.2, 0.0, 0.2), 5.0)
	var label := _first_active_label(fx)
	_check_eq("two nearby pops inside merge window use one active label", _in_use_count(fx), 1)
	_check_eq("merged damage number sums text", label.text if label != null else "", "15")
	await _cleanup(fx)

func _test_tier_mapping() -> void:
	var crit_fx = await _new_fx()
	_pop(crit_fx, Vector3.ZERO, 9.0, {"crit": true})
	var crit_label := _first_active_label(crit_fx)
	_check_eq("crit damage number uses biggest font", crit_label.font_size if crit_label != null else -1, 110)
	_check_eq("crit damage number uses ember identity color", crit_label.modulate if crit_label != null else Color.BLACK, CombatEffectsScript.FX_IDENTITY)
	await _cleanup(crit_fx)

	var boosted_fx = await _new_fx()
	_pop(boosted_fx, Vector3.ZERO, 9.0, {"boosted": true})
	var boosted_label := _first_active_label(boosted_fx)
	_check_eq("boosted damage number uses keepsake font", boosted_label.font_size if boosted_label != null else -1, 84)
	_check_eq("boosted damage number uses rim amber color", boosted_label.modulate if boosted_label != null else Color.BLACK, CombatEffectsScript.FX_IDENTITY_RIM)
	await _cleanup(boosted_fx)

	var player_fx = await _new_fx()
	_pop(player_fx, Vector3.ZERO, 9.0, {"player_hit": true, "crit": true, "boosted": true})
	var player_label := _first_active_label(player_fx)
	_check_eq("player-hit damage number ignores crit font", player_label.font_size if player_label != null else -1, 64)
	_check_eq("player-hit damage number uses red color", player_label.modulate if player_label != null else Color.BLACK, CombatEffectsScript.PLAYER_HIT_NUMBER_COLOR)
	await _cleanup(player_fx)

	var shielded_fx = await _new_fx()
	_pop(shielded_fx, Vector3.ZERO, 9.0, {"shielded": true, "player_hit": true, "crit": true, "boosted": true})
	var shielded_label := _first_active_label(shielded_fx)
	_check_eq("shielded damage number uses compact shield font", shielded_label.font_size if shielded_label != null else -1, 54)
	_check_eq("shielded damage number uses grey-blue color", shielded_label.modulate if shielded_label != null else Color.BLACK, CombatEffectsScript.SHIELDED_NUMBER_COLOR)
	await _cleanup(shielded_fx)

func _test_reuse_reset() -> void:
	var fx = await _new_fx()
	var origin := Vector3(4.0, 0.0, 4.0)
	_pop(fx, origin, 3.0)
	var dirty := _first_active_label(fx)
	if dirty != null:
		dirty.text = "dirty"
		dirty.scale = Vector3.ONE * 3.0
		dirty.modulate = Color(0.0, 1.0, 0.0, 0.2)
		dirty.outline_modulate = Color(1.0, 0.0, 1.0, 0.1)
		dirty.global_position = Vector3(50.0, 5.0, 50.0)
	await _wait(0.8)
	_pop(fx, origin + Vector3(2.0, 0.0, 0.0), 8.0)
	var clean := _first_active_label(fx)
	_check_eq("reused label receives fresh text", clean.text if clean != null else "", "8")
	_check_eq("reused label resets scale", clean.scale if clean != null else Vector3.ZERO, Vector3.ONE)
	_check_eq("reused label resets color", clean.modulate if clean != null else Color.BLACK, CombatEffectsScript.DAMAGE_NUMBER_COLOR)
	_check_almost("reused label resets outline alpha", clean.outline_modulate.a if clean != null else -1.0, 0.9)
	_check_eq("reused label resets position before motion starts", clean.global_position if clean != null else Vector3.ZERO, origin + Vector3(2.0, 0.0, 0.0))
	await _cleanup(fx)

func _test_enemy_take_damage_routes_opts_to_group() -> void:
	await _clear_damage_number_groups()
	var fx = await _new_fx()
	var enemy = await _new_enemy()
	enemy.configure("bruiser", "damage-number:crit")
	enemy.take_damage(12.0, true, {"crit": true})
	var label := _first_active_label(fx)
	_check_eq("enemy.take_damage routes crit opts to DamageNumbers", label.font_size if label != null else -1, 110)
	_check_eq("group-routed enemy pop uses pooled label", _in_use_count(fx), 1)
	await _cleanup(enemy)
	await _cleanup(fx)

func _test_enemy_take_damage_falls_back_without_group() -> void:
	await _clear_damage_number_groups()
	var enemy = await _new_enemy()
	enemy.configure("bruiser", "damage-number:fallback")
	var remaining: float = enemy.take_damage(10.0, true, {"crit": true})
	_check("fallback take_damage still applies damage without a group node", remaining < enemy.max_hp)
	_check_eq("fallback path does not create a damage_numbers group", get_first_node_in_group("damage_numbers"), null)
	for label in _all_labels(root):
		label.queue_free()
	await _cleanup(enemy)

func _clear_damage_number_groups() -> void:
	for node in get_nodes_in_group("damage_numbers"):
		if node != null and is_instance_valid(node):
			node.queue_free()
	await process_frame

func _first_active_label(node: Node) -> Label3D:
	for label in _visible_labels(node):
		return label
	return null

func _visible_labels(node: Node) -> Array[Label3D]:
	var found: Array[Label3D] = []
	if node is Label3D and (node as Label3D).visible:
		found.append(node as Label3D)
	for child in node.get_children():
		found.append_array(_visible_labels(child))
	return found

func _all_labels(node: Node) -> Array[Label3D]:
	var found: Array[Label3D] = []
	if node is Label3D:
		found.append(node as Label3D)
	for child in node.get_children():
		found.append_array(_all_labels(child))
	return found
