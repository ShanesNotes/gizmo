extends SceneTree

# Headless tests for the generic NodePool utility.
# Run with:
#   godot --headless --path godot --user-data-dir /tmp/grok-opt2 --script res://tests/run_node_pool_tests.gd

const NodePoolScript := preload("res://scripts/util/node_pool.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running node pool tests...")
	_test_acquire_creates_via_factory()
	_test_release_acquire_reuses_same_instance()
	_test_prewarm_stocks_n()
	_test_max_size_cap_drops_excess_on_release()
	_test_node3d_factory_headless()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL - %d passed, %d failed" % [_passed, _failed])
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

func _make_host() -> Node:
	var host := Node.new()
	host.name = "PoolHost"
	root.add_child(host)
	return host

func _counter_factory(counter: Dictionary, make_node: Callable) -> Callable:
	return func() -> Node:
		counter["created"] = int(counter.get("created", 0)) + 1
		return make_node.call()

func _node3d_factory(counter: Dictionary) -> Callable:
	return _counter_factory(counter, func() -> Node3D:
		var node := Node3D.new()
		node.name = "PooledNode3D"
		return node
	)

func _test_acquire_creates_via_factory() -> void:
	var host := _make_host()
	var counter := {"created": 0}
	var pool := NodePoolScript.new(_node3d_factory(counter), host, 4)
	var node := pool.acquire()
	_check("acquire returns a node from the factory", node != null)
	_check_eq("factory called once on first acquire", counter["created"], 1)
	_check_eq("acquired node is parented under the pool host", node.get_parent(), host)
	_check_eq("node is tracked in use", pool.in_use_count(), 1)
	host.queue_free()

func _test_release_acquire_reuses_same_instance() -> void:
	var host := _make_host()
	var counter := {"created": 0}
	var pool := NodePoolScript.new(_node3d_factory(counter), host, 4)
	var first := pool.acquire() as Node3D
	var first_id := first.get_instance_id()
	pool.release(first)
	var second := pool.acquire() as Node3D
	_check_eq("release then acquire reuses the same instance", second.get_instance_id(), first_id)
	_check_eq("reuse avoids a second factory call", counter["created"], 1)
	host.queue_free()

func _test_prewarm_stocks_n() -> void:
	var host := _make_host()
	var counter := {"created": 0}
	var pool := NodePoolScript.new(_node3d_factory(counter), host, 8)
	pool.prewarm(5)
	_check_eq("prewarm(5) stocks five available nodes", pool.available_count(), 5)
	_check_eq("prewarm factory calls match requested count", counter["created"], 5)
	_check_eq("prewarmed nodes stay parented under host", host.get_child_count(), 5)
	host.queue_free()

func _test_max_size_cap_drops_excess_on_release() -> void:
	var host := _make_host()
	var counter := {"created": 0}
	var pool := NodePoolScript.new(_node3d_factory(counter), host, 2)
	pool.prewarm(2)
	var a := pool.acquire()
	var b := pool.acquire()
	_check_eq("pool reaches max_size in use", pool.in_use_count(), 2)
	_check_eq("no spare slots while fully checked out", pool.available_count(), 0)
	pool.release(a)
	pool.release(b)
	_check_eq("released nodes refill available up to max_size", pool.available_count(), 2)
	var c := pool.acquire()
	var d := pool.acquire()
	_check_eq("cannot exceed max_size while fully checked out", pool.acquire(), null)
	pool.release(c)
	pool.release(d)
	_check_eq("factory only created max_size nodes", counter["created"], 2)
	_check_eq("host child count stays capped at max_size", host.get_child_count(), 2)
	host.queue_free()

func _test_node3d_factory_headless() -> void:
	var host := _make_host()
	var counter := {"created": 0}
	var pool := NodePoolScript.new(_node3d_factory(counter), host, 3)
	pool.prewarm(1)
	var pooled := host.get_child(0) as Node3D
	_check("prewarmed Node3D is hidden", not pooled.visible)
	_check_eq("prewarmed Node3D process disabled", pooled.process_mode, Node.PROCESS_MODE_DISABLED)
	var active := pool.acquire() as Node3D
	_check("acquired Node3D is visible", active.visible)
	_check_eq("acquired Node3D process enabled", active.process_mode, Node.PROCESS_MODE_INHERIT)
	pool.release(active)
	_check("released Node3D is hidden again", not active.visible)
	_check_eq("released Node3D process disabled again", active.process_mode, Node.PROCESS_MODE_DISABLED)
	host.queue_free()