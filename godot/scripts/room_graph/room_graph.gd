class_name RoomGraph
extends Resource

## The run-scoped graph of RoomNodes + RoomConnections. One instance is built
## per run (by RoomGraphGenerator) and owned by the RunController node; it is
## never shared between runs and never saved as a shipped .tres.

@export var biome_id: String = ""
@export var entry_room_id: String = ""
@export var rooms: Array[RoomNode] = []
@export var connections: Array[RoomConnection] = []

func get_room(room_id: String) -> RoomNode:
	for room in rooms:
		if room.room_id == room_id:
			return room
	return null

func get_connections_from(room_id: String) -> Array[RoomConnection]:
	var result: Array[RoomConnection] = []
	for connection in connections:
		if connection.from_room_id == room_id:
			result.append(connection)
	return result

## Rooms reachable immediately after clearing `room_id`; RunController unlocks
## these (RoomNode.State.AVAILABLE) once the room's director signals it's clear.
func get_next_room_ids(room_id: String) -> Array[String]:
	var ids: Array[String] = []
	for connection in get_connections_from(room_id):
		ids.append(connection.to_room_id)
	return ids

func mark_state(room_id: String, new_state: RoomNode.State) -> void:
	var room := get_room(room_id)
	if room != null:
		room.state = new_state
