class_name RoomFixture
extends Area3D

enum FixtureKind { SCRAP_CACHE, EMBER_ALCOVE, SHOP_OFFER }

@export var fixture_kind: FixtureKind = FixtureKind.SCRAP_CACHE
@export_range(0, 999, 1) var scrap_amount: int = 10
## Offer id for SHOP_OFFER fixtures (must exist in RunOrchestrator.SHOP_OFFERS).
@export var shop_offer_id: String = ""
@export var player_group: StringName = &"player"
@export_range(0.0, 10.0, 0.1) var magnet_radius: float = 2.5
@export_range(0.0, 30.0, 0.1) var magnet_lerp_speed: float = 8.0

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
	_magnet_toward_player(_delta)
	_claim_first_overlapping_player()

func grant_scrap(body: Node3D = null) -> bool:
	return _claim(FixtureKind.SCRAP_CACHE, body)

func refill_guard(body: Node3D = null) -> bool:
	return _claim(FixtureKind.EMBER_ALCOVE, body)

func purchase_offer(body: Node3D = null) -> bool:
	return _claim(FixtureKind.SHOP_OFFER, body)

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
		FixtureKind.SHOP_OFFER:
			return purchase_offer(body)
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
		FixtureKind.SHOP_OFFER:
			granted = bool(orchestrator.call("purchase_shop_offer_once", fixture_key, shop_offer_id))
		_:
			granted = false

	if granted:
		_claimed = true
		_spawn_collect_pulse()
		set_deferred("monitoring", false)
		set_physics_process(false)
		_hide_visuals(self)
	return granted

func _find_orchestrator() -> Node:
	var cursor: Node = self
	while cursor != null:
		if cursor.has_method("grant_fixture_scrap_once") and cursor.has_method("refill_fixture_guard_once"):
			return cursor
		if fixture_kind == FixtureKind.SHOP_OFFER and cursor.has_method("purchase_shop_offer_once"):
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

func _magnet_toward_player(delta: float) -> void:
	var player := _nearest_player_in_magnet_radius()
	if player == null:
		return
	var target := player.global_position
	target.y = global_position.y
	var weight := clampf(delta * magnet_lerp_speed, 0.0, 1.0)
	global_position = global_position.lerp(target, weight)

func _nearest_player_in_magnet_radius() -> Node3D:
	if magnet_radius <= 0.0 or not is_inside_tree():
		return null
	var nearest: Node3D = null
	var nearest_distance_sq := magnet_radius * magnet_radius
	for candidate in get_tree().get_nodes_in_group(String(player_group)):
		if not (candidate is Node3D) or not is_instance_valid(candidate):
			continue
		var candidate_body := candidate as Node3D
		var distance_sq := global_position.distance_squared_to(candidate_body.global_position)
		if distance_sq <= nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = candidate_body
	return nearest

func _spawn_collect_pulse() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "CollectSparklePulse"
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	pulse.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.78, 0.38, 0.65)
	material.emission_enabled = true
	material.emission = Color(0.95, 0.58, 0.16, 1.0)
	material.emission_energy_multiplier = 1.15
	material.roughness = 0.55
	pulse.material_override = material
	parent.add_child(pulse)
	pulse.global_position = global_position
	pulse.scale = Vector3.ONE * 0.35
	var tween := pulse.create_tween()
	tween.tween_property(pulse, "scale", Vector3.ONE * 1.25, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(pulse.queue_free)

func _hide_visuals(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).visible = false
		_hide_visuals(child)
