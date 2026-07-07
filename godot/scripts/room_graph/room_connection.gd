class_name RoomConnection
extends Resource

## One directed door between two RoomNodes in a run's RoomGraph. Hades rooms
## don't allow backtracking, so connections are one-way by default.

@export var from_room_id: String = ""
@export var to_room_id: String = ""

## Matches the Marker3D/Area3D name in the "from" room's scene that the player
## walks through to trigger this transition (RoomRunner looks this up by name).
@export var door_name: String = "RoomExit"
