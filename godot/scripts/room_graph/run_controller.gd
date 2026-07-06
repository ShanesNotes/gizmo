class_name RunController
extends Node

signal room_entered(room: RoomNode)
signal room_cleared(room: RoomNode)
signal doors_opened(connections: Array[RoomConnection])
signal run_completed()

var graph: RoomGraph
var current_room_id: String = ""

func start_run(
	biome_id: String,
	template_pool: Array[RoomTemplate],
	room_count: int,
	rng: RandomNumberGenerator,
) -> RoomGraph:
	graph = RoomGraphGenerator.generate(biome_id, template_pool, room_count, rng)
	current_room_id = ""
	if graph == null:
		push_error("RunController: RoomGraphGenerator returned null")
		return null
	if graph.entry_room_id == "":
		push_error("RunController: generated graph has no entry room")
		return graph

	_enter_room(graph.entry_room_id)
	return graph

func notify_room_cleared() -> void:
	var room := _current_room()
	if room == null:
		return

	room.state = RoomNode.State.CLEARED
	room_cleared.emit(room)

	if room.template != null and room.template.room_type == RoomTemplate.RoomType.BOSS:
		run_completed.emit()
		return

	var outgoing_connections := graph.get_connections_from(current_room_id)
	for connection in outgoing_connections:
		var destination := graph.get_room(connection.to_room_id)
		if destination != null:
			destination.state = RoomNode.State.AVAILABLE
		else:
			push_error("RunController: outgoing connection targets missing room '%s'" % connection.to_room_id)
	doors_opened.emit(outgoing_connections)

func choose_exit(connection: RoomConnection) -> bool:
	if graph == null:
		push_error("RunController: choose_exit called before start_run")
		return false
	if connection == null:
		push_error("RunController: choose_exit called with null connection")
		return false
	if connection.from_room_id != current_room_id:
		push_error(
			"RunController: rejected exit '%s' from '%s' while current room is '%s'"
			% [connection.door_name, connection.from_room_id, current_room_id]
		)
		return false

	var current_room := _current_room()
	if current_room == null:
		return false

	var destination := graph.get_room(connection.to_room_id)
	if destination == null:
		push_error("RunController: rejected exit to missing room '%s'" % connection.to_room_id)
		return false

	current_room.state = RoomNode.State.REWARDED
	_enter_room(destination.room_id)
	return true

func _enter_room(room_id: String) -> bool:
	if graph == null:
		push_error("RunController: cannot enter room without a graph")
		return false

	var room := graph.get_room(room_id)
	if room == null:
		push_error("RunController: cannot enter missing room '%s'" % room_id)
		return false

	current_room_id = room.room_id
	room.state = RoomNode.State.ENTERED
	room_entered.emit(room)
	return true

func _current_room() -> RoomNode:
	if graph == null:
		push_error("RunController: no active graph")
		return null
	if current_room_id == "":
		push_error("RunController: no current room")
		return null

	var room := graph.get_room(current_room_id)
	if room == null:
		push_error("RunController: current room '%s' is missing from graph" % current_room_id)
	return room
