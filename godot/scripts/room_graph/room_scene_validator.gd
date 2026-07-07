class_name RoomSceneValidator
extends RefCounted

## Validates a room PackedScene against the room-authoring contract in
## docs/hades-pivot/room-graph-and-camera.md §2.


static func validate(scene: PackedScene) -> Array[String]:
	var violations: Array[String] = []

	if scene == null:
		violations.append("Room scene is null.")
		return violations

	var instance: Node = scene.instantiate()
	if instance == null:
		violations.append("Room scene failed to instantiate.")
		return violations

	var camera_anchor := instance.find_child("CameraAnchor", true, false)
	if camera_anchor == null or not camera_anchor is Marker3D:
		violations.append("Room scene is missing a Marker3D named 'CameraAnchor'.")

	var spawn_marker := instance.find_child("SpawnMarker", true, false)
	if spawn_marker == null or not spawn_marker is Marker3D:
		violations.append("Room scene is missing a Marker3D named 'SpawnMarker'.")

	var has_room_exit := _find_area3d_named(instance, "RoomExit") != null
	var has_room_exit_a := _find_area3d_named(instance, "RoomExitA") != null
	var has_room_exit_b := _find_area3d_named(instance, "RoomExitB") != null

	if not has_room_exit and not has_room_exit_a and not has_room_exit_b:
		violations.append(
			"Room scene is missing an Area3D exit door named 'RoomExit', 'RoomExitA', or 'RoomExitB'."
		)

	if has_room_exit_a and not has_room_exit_b:
		violations.append("Room scene has 'RoomExitA' but is missing the paired 'RoomExitB' Area3D.")

	instance.free()
	return violations


static func _find_area3d_named(root: Node, node_name: String) -> Area3D:
	var node := root.find_child(node_name, true, false)
	if node is Area3D:
		return node
	return null