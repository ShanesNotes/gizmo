class_name RoomFixture
extends Area3D

enum FixtureKind { SCRAP_CACHE, EMBER_ALCOVE }

@export var fixture_kind: FixtureKind = FixtureKind.SCRAP_CACHE
@export_range(0, 999, 1) var scrap_amount: int = 10
@export var player_group: StringName = &"player"

var _claimed := false
var _overlap_check_generation := 0

func _init() -> void:
	monitoring = true

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	set_physics_process(true)
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func _physics_process(_delta: float) -> void:
	if _claimed:
		set_physics_process(false)
		return
	_claim_first_overlapping_player()

func grant_scrap(body: Node3D = null) -> bool:
	return _claim(FixtureKind.SCRAP_CACHE, body)

func refill_guard(body: Node3D = null) -> bool:
	return _claim(FixtureKind.EMBER_ALCOVE, body)

func is_claimed() -> bool:
	return _claimed

func _on_body_entered(body: Node3D) -> void:
	_claim_from_body(body)

func _check_for_already_overlapping_player(generation: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if generation != _overlap_check_generation or _claimed:
		return
	_claim_first_overlapping_player()

func _claim_first_overlapping_player() -> bool:
	for body in get_overlapping_bodies():
		if _claim_from_body(body as Node3D):
			return true
	return false

func _claim_from_body(body: Node3D) -> bool:
	match fixture_kind:
		FixtureKind.SCRAP_CACHE:
			return grant_scrap(body)
		FixtureKind.EMBER_ALCOVE:
			return refill_guard(body)
		_:
			return false

func _claim(expected_kind: FixtureKind, body: Node3D) -> bool:
	if _claimed or fixture_kind != expected_kind or not _is_player_body(body):
		return false

	var orchestrator := _find_orchestrator()
	if orchestrator == null:
		return false

	var fixture_key := _fixture_key(orchestrator)
	var granted := false
	match fixture_kind:
		FixtureKind.SCRAP_CACHE:
			granted = bool(orchestrator.call("grant_fixture_scrap_once", fixture_key, scrap_amount))
		FixtureKind.EMBER_ALCOVE:
			granted = bool(orchestrator.call("refill_fixture_guard_once", fixture_key))
		_:
			granted = false

	if granted:
		_claimed = true
		set_deferred("monitoring", false)
		set_physics_process(false)
		_hide_visuals(self)
	return granted

func _find_orchestrator() -> Node:
	var cursor: Node = self
	while cursor != null:
		if cursor.has_method("grant_fixture_scrap_once") and cursor.has_method("refill_fixture_guard_once"):
			return cursor
		cursor = cursor.get_parent()
	push_warning("RoomFixture '%s' found no RunOrchestrator ancestor; grants disabled." % name)
	return null

func _fixture_key(orchestrator: Node) -> String:
	var room_id := ""
	var controller = orchestrator.get("run_controller")
	if controller != null:
		room_id = String(controller.get("current_room_id"))
	return "room_fixture:%s:%d:%s" % [room_id, int(fixture_kind), String(name)]

func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	return body is CharacterBody3D and body.is_in_group(player_group)

func _hide_visuals(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).visible = false
		_hide_visuals(child)
