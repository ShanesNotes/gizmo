class_name NodePool
extends RefCounted

## Generic node pool for combat FX / damage-number reuse. Factory must return a
## Node; parent holds inactive instances as children (hidden, process disabled).

var _factory: Callable = Callable()
var _parent: Node = null
var _max_size: int = 32
var _available: Array[Node] = []
var _in_use: Dictionary = {}

func _init(factory: Callable, parent: Node, max_size: int = 32) -> void:
	_factory = factory
	_parent = parent
	_max_size = maxi(max_size, 1)

func prewarm(count: int) -> void:
	var target := mini(maxi(count, 0), _max_size - _total_count())
	for _i in target:
		var node := _create_node()
		if node == null:
			break
		_available.append(node)

func acquire() -> Node:
	var node: Node = null
	if not _available.is_empty():
		node = _available.pop_back()
	elif _total_count() < _max_size:
		node = _create_node()
	else:
		return null
	if node == null:
		return null
	_prepare_for_use(node)
	_in_use[node.get_instance_id()] = node
	return node

func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var instance_id := node.get_instance_id()
	if not _in_use.has(instance_id):
		return
	_in_use.erase(instance_id)
	_prepare_for_pool(node)
	if _available.size() < _max_size:
		_available.append(node)
	else:
		node.queue_free()

func available_count() -> int:
	return _available.size()

func in_use_count() -> int:
	return _in_use.size()

func total_count() -> int:
	return _total_count()

func max_size() -> int:
	return _max_size

func _total_count() -> int:
	return _available.size() + _in_use.size()

func _create_node() -> Node:
	if not _factory.is_valid():
		push_error("NodePool: factory Callable is invalid.")
		return null
	var node := _factory.call() as Node
	if node == null:
		push_error("NodePool: factory returned null.")
		return null
	if _parent != null and is_instance_valid(_parent) and node.get_parent() != _parent:
		_parent.add_child(node)
	_prepare_for_pool(node)
	return node

func _prepare_for_use(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		(node as CanvasItem).show()
	elif node is Node3D:
		(node as Node3D).visible = true

func _prepare_for_pool(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).hide()
	elif node is Node3D:
		(node as Node3D).visible = false