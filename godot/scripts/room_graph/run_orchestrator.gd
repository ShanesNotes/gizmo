class_name RunOrchestrator
extends Node3D

signal room_loaded(room: RoomNode, room_root: Node3D)
signal doors_bound(connections: Array[RoomConnection])
signal run_completed()
signal player_died()

const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")

@export var auto_start: bool = true
@export var biome_id: String = "hearth"
@export_range(2, 16) var room_count: int = 8
@export var rng_seed: int = 32032
@export var template_pool_paths: Array[String] = [
	"res://resources/room_templates/combat_small.tres",
	"res://resources/room_templates/combat_large.tres",
	"res://resources/room_templates/elite_arena.tres",
	"res://resources/room_templates/shop_small.tres",
	"res://resources/room_templates/boss_arena.tres",
]
@export var enemy_scene: PackedScene = preload("res://scenes/enemies/greybox_enemy.tscn")

@onready var rooms_root: Node3D = get_node("Rooms") as Node3D
@onready var actors_root: Node3D = get_node("Actors") as Node3D
@onready var enemies_root: Node3D = get_node("Actors/Enemies") as Node3D
@onready var player: CharacterBody3D = get_node("Actors/GizmoPlayer") as CharacterBody3D
@onready var camera: RoomCamera = get_node("RoomCamera") as RoomCamera
@onready var run_controller: RunController = get_node("RunController") as RunController
@onready var flow_bridge: RunFlowBridge = get_node("RunFlowBridge") as RunFlowBridge
@onready var hud: Hud = get_node("Hud") as Hud
@onready var boon_draft_ui: BoonDraftUI = get_node("BoonDraft") as BoonDraftUI

var boon_draft: BoonDraft = BoonDraft.new()
var player_vitals: PlayerVitals
var current_room_root: Node3D = null
var current_director: RoomDirector = null
var bound_doors: Dictionary = {}
var spawned_enemies: Dictionary = {}

var _rng: RandomNumberGenerator = null
var _run_active := false
var _transitioning := false

func _ready() -> void:
	_ensure_wiring()
	if auto_start:
		var seeded := RandomNumberGenerator.new()
		seeded.seed = rng_seed
		var pool: Array[RoomTemplate] = []
		start_run(biome_id, pool, room_count, seeded)

func start_run(
	p_biome_id: String = "",
	p_template_pool: Array[RoomTemplate] = [],
	p_room_count: int = -1,
	p_rng: RandomNumberGenerator = null,
) -> RoomGraph:
	_ensure_wiring()
	_cleanup_current_room()
	spawned_enemies.clear()
	bound_doors.clear()
	boon_draft.reset_run()
	if player_vitals != null:
		player_vitals.reset()

	_rng = p_rng
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.seed = rng_seed
	if flow_bridge != null:
		flow_bridge.rng = _rng

	var active_biome := p_biome_id if p_biome_id != "" else biome_id
	var active_room_count := p_room_count if p_room_count > 0 else room_count
	var active_pool := p_template_pool
	if active_pool.is_empty():
		active_pool = load_template_pool()

	var graph := run_controller.start_run(active_biome, active_pool, active_room_count, _rng)
	_run_active = graph != null and run_controller.current_room_id != ""
	_transitioning = false
	if _run_active:
		_load_current_room()
	_render_hud_payloads()
	return graph

func load_template_pool() -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	for path in template_pool_paths:
		var resource := load(path)
		if resource is RoomTemplate:
			pool.append(resource as RoomTemplate)
		else:
			push_error("RunOrchestrator: template path is not a RoomTemplate: %s" % path)
	return pool

func spawned_enemy_count() -> int:
	return spawned_enemies.size()

func active_spawn_ids() -> Array[String]:
	var ids: Array[String] = []
	for spawn_id in spawned_enemies.keys():
		ids.append(String(spawn_id))
	ids.sort()
	return ids

func _ensure_wiring() -> void:
	if player != null:
		player_vitals = _ensure_player_vitals(player)
		if player_vitals != null and not player_vitals.player_died.is_connected(_on_player_vitals_died):
			player_vitals.player_died.connect(_on_player_vitals_died)

	if camera != null:
		camera.target = player

	if run_controller != null:
		if not run_controller.doors_opened.is_connected(_on_doors_opened):
			run_controller.doors_opened.connect(_on_doors_opened)
		if not run_controller.run_completed.is_connected(_on_run_controller_completed):
			run_controller.run_completed.connect(_on_run_controller_completed)

	if flow_bridge != null:
		flow_bridge.configure(
			run_controller,
			boon_draft,
			boon_draft_ui,
			_default_boon_pool(),
			_rng,
			_player_ability_kit()
		)
		if not flow_bridge.exit_completed.is_connected(_on_exit_completed):
			flow_bridge.exit_completed.connect(_on_exit_completed)

func _ensure_player_vitals(target_player: Node) -> PlayerVitals:
	var existing := target_player.get_node_or_null("PlayerVitals")
	if existing is PlayerVitals:
		return existing as PlayerVitals

	var vitals := PlayerVitalsScript.new() as PlayerVitals
	vitals.name = "PlayerVitals"
	target_player.add_child(vitals)
	return vitals

func _player_ability_kit() -> AbilityComponent:
	if player == null:
		return null
	var kit := player.get_node_or_null("AbilityComponent")
	if kit is AbilityComponent:
		return kit as AbilityComponent
	return null

func _load_current_room() -> void:
	if run_controller == null or run_controller.graph == null:
		return

	var room := run_controller.graph.get_room(run_controller.current_room_id)
	if room == null or room.template == null or room.template.scene == null:
		push_error("RunOrchestrator: current room is missing an instantiable template.")
		return

	_cleanup_current_room()
	current_room_root = room.template.scene.instantiate() as Node3D
	if current_room_root == null:
		push_error("RunOrchestrator: room template scene root must be Node3D.")
		return
	rooms_root.add_child(current_room_root)

	_place_player_at_spawn(current_room_root)
	bound_doors = _bind_room_doors(current_room_root)
	if camera != null:
		camera.enter_room(current_room_root)
	_start_room_director(room)
	_render_hud_payloads()
	room_loaded.emit(room, current_room_root)

func _cleanup_current_room() -> void:
	_clear_spawned_enemies()
	if current_room_root != null and is_instance_valid(current_room_root):
		current_room_root.queue_free()
	current_room_root = null
	current_director = null
	bound_doors.clear()

func _place_player_at_spawn(room_root: Node3D) -> void:
	if player == null or room_root == null:
		return
	var spawn := room_root.find_child("SpawnMarker", true, false) as Marker3D
	if spawn == null:
		push_error("RunOrchestrator: room is missing SpawnMarker.")
		return
	player.global_transform = spawn.global_transform
	player.velocity = Vector3.ZERO

func _bind_room_doors(room_root: Node3D) -> Dictionary:
	var doors: Dictionary = {}
	for candidate in _find_area_doors(room_root):
		var door := _replace_with_room_door(candidate)
		if door == null:
			continue
		door.seal()
		if not door.exit_requested.is_connected(_on_door_exit_requested):
			door.exit_requested.connect(_on_door_exit_requested)
		doors[door.name] = door
	if not doors.has("RoomExit") and doors.has("RoomExitA"):
		doors["RoomExit"] = doors["RoomExitA"]
	return doors

func _find_area_doors(room_root: Node) -> Array[Area3D]:
	var doors: Array[Area3D] = []
	_collect_area_doors(room_root, doors)
	return doors

func _collect_area_doors(node: Node, doors: Array[Area3D]) -> void:
	if node is Area3D and String(node.name).begins_with("RoomExit"):
		doors.append(node as Area3D)
	for child in node.get_children():
		_collect_area_doors(child, doors)

func _replace_with_room_door(area: Area3D) -> RoomDoor:
	if area is RoomDoor:
		return area as RoomDoor

	var parent := area.get_parent()
	if parent == null:
		return null

	var index := area.get_index()
	var door := RoomDoorScript.new() as RoomDoor
	door.name = area.name
	door.transform = area.transform
	door.collision_layer = area.collision_layer
	door.collision_mask = area.collision_mask
	door.monitorable = area.monitorable
	door.input_ray_pickable = area.input_ray_pickable

	for child in area.get_children():
		area.remove_child(child)
		door.add_child(child)

	parent.remove_child(area)
	parent.add_child(door)
	parent.move_child(door, index)
	area.queue_free()
	return door

func _start_room_director(room: RoomNode) -> void:
	current_director = RoomDirector.new(room.difficulty_tier, _rng)
	current_director.wave_requested.connect(_on_director_wave_requested)
	current_director.room_cleared.connect(_on_director_room_cleared)
	current_director.start()

func _on_director_wave_requested(_wave_index: int, requests: Array[Dictionary]) -> void:
	if not _run_active:
		return
	for request in requests:
		_spawn_from_request(request)

func _spawn_from_request(request: Dictionary) -> void:
	if enemy_scene == null or player == null:
		return

	var archetype := String(request.get("archetype", RoomDirector.ARCHETYPE_CHAFF))
	for spawn_id_value in request.get("spawn_ids", []):
		var spawn_id := String(spawn_id_value)
		if spawn_id == "":
			continue
		var enemy := enemy_scene.instantiate() as GreyboxEnemy
		if enemy == null:
			push_error("RunOrchestrator: enemy_scene must instantiate GreyboxEnemy.")
			return
		enemies_root.add_child(enemy)
		enemy.global_position = _spawn_position_for(spawned_enemies.size())
		enemy.configure(archetype, spawn_id)
		enemy.set_chase_target(player)
		enemy.died.connect(_on_enemy_died)
		enemy.damage_event.connect(_on_enemy_damage_event)
		spawned_enemies[spawn_id] = enemy

func _spawn_position_for(index: int) -> Vector3:
	var center := Vector3.ZERO
	if current_room_root != null:
		var anchor := current_room_root.find_child("CameraAnchor", true, false) as Marker3D
		if anchor != null:
			center = anchor.global_position
	var radius := 4.0 + float(index % 3)
	var angle := float(index) * 2.399963
	return center + Vector3(cos(angle) * radius, 0.1, sin(angle) * radius)

func _on_enemy_died(spawn_id: String) -> void:
	if current_director != null:
		current_director.notify_kill(spawn_id)
	var enemy := spawned_enemies.get(spawn_id) as Node
	if enemy != null and is_instance_valid(enemy):
		enemy.queue_free()
	spawned_enemies.erase(spawn_id)

func _on_enemy_damage_event(event: Dictionary) -> void:
	if player_vitals == null:
		return
	player_vitals.apply_damage(int(event.get("damage", 0)))
	_render_hud_payloads()

func _on_director_room_cleared() -> void:
	_clear_spawned_enemies()
	if _run_active and run_controller != null:
		run_controller.notify_room_cleared()

func _on_doors_opened(connections: Array[RoomConnection]) -> void:
	for connection in connections:
		var door := bound_doors.get(connection.door_name) as RoomDoor
		if door == null:
			push_error("RunOrchestrator: room has no bound door named '%s'." % connection.door_name)
			continue
		door.open_for(connection, run_controller.exit_reward_type(connection))
	doors_bound.emit(connections)

func _on_door_exit_requested(connection: RoomConnection) -> void:
	if not _run_active or _transitioning:
		return
	flow_bridge.request_exit(connection)

func _on_exit_completed(_connection: RoomConnection, accepted: bool) -> void:
	if not accepted or not _run_active:
		return
	_transitioning = true
	_load_current_room()
	_transitioning = false

func _on_player_vitals_died() -> void:
	if not _run_active:
		return
	_run_active = false
	if current_director != null:
		current_director.wave_requested.disconnect(_on_director_wave_requested)
	for enemy in spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			(enemy as GreyboxEnemy).clear_chase_target()
	player_died.emit()

func _on_run_controller_completed() -> void:
	_run_active = false
	_clear_spawned_enemies()
	run_completed.emit()

func _clear_spawned_enemies() -> void:
	for enemy in spawned_enemies.values():
		if enemy is Node and is_instance_valid(enemy):
			(enemy as Node).queue_free()
	spawned_enemies.clear()

func _render_hud_payloads() -> void:
	if hud == null:
		return
	if player_vitals != null:
		hud.render_guard(player_vitals.guard, player_vitals.max_guard)
	hud.render_boons(boon_draft.picked_boons)
	hud.render_abilities(_ability_states())

func _ability_states() -> Array:
	var states: Array = []
	var kit := _player_ability_kit()
	if kit == null:
		return states
	for ability_id in [&"dash", &"attack", &"special", &"cast"]:
		var ability := kit.get_ability(ability_id)
		if ability == null:
			continue
		var state := {
			"kind": ability.kind,
			"ready": not kit.is_on_cooldown(ability_id),
		}
		if ability.kind == Ability.AbilityKind.CAST:
			state["count"] = kit.cast_ammo()
		states.append(state)
	return states

func _default_boon_pool() -> Array[BoonDef]:
	var pool: Array[BoonDef] = []
	pool.append(_make_default_boon(&"spark_attack", "Spark-Cut", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK))
	pool.append(_make_default_boon(&"gear_dash", "Gyre Step", BoonDef.Rarity.RARE, BoonDef.Slot.DASH))
	pool.append(_make_default_boon(&"core_special", "Brass Overdrive", BoonDef.Rarity.EPIC, BoonDef.Slot.SPECIAL))
	pool.append(_make_default_boon(&"codex_cast", "Codex Shard", BoonDef.Rarity.COMMON, BoonDef.Slot.CAST))
	pool.append(_make_default_boon(&"humanity_guard", "Humanity's Reserve", BoonDef.Rarity.LEGENDARY, BoonDef.Slot.PASSIVE))
	return pool

func _make_default_boon(
	boon_id: StringName,
	display_name: String,
	rarity: BoonDef.Rarity,
	slot: BoonDef.Slot,
) -> BoonDef:
	var boon := BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = display_name
	boon.description = "A run-scoped upgrade for this chamber chain."
	boon.rarity = rarity
	boon.slot = slot
	boon.domain = "spark"
	return boon
