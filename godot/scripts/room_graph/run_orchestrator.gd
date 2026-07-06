class_name RunOrchestrator
extends Node3D

signal room_loaded(room: RoomNode, room_root: Node3D)
signal doors_bound(connections: Array[RoomConnection])
signal run_completed()
signal player_died()

const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const CombatResolversScript := preload("res://scripts/room_graph/combat_resolvers.gd")
const CustodianBossScript := preload("res://scripts/room_graph/custodian_boss.gd")

const SCRAP_REWARD_VALUE := 10
const SPARKS_REWARD_VALUE := 5
const SPAWN_GOLDEN_ANGLE := 2.399963
const SPAWN_CANDIDATE_COUNT := 48
const SPAWN_EDGE_CLEARANCE := 0.75
const SPAWN_SEPARATION_DISTANCE := 1.1
const ZONE_STATE_COMBAT: StringName = &"COMBAT"
const ZONE_STATE_CLEARED: StringName = &"CLEARED"
const BOSS_INTRO_HOLD_SECONDS := 1.0

@export var auto_start: bool = true
@export var biome_id: String = "hearth"
@export_range(2, 16) var room_count: int = 8
@export var rng_seed: int = 32032
@export_range(0.0, 64.0, 0.1) var min_spawn_distance: float = 8.0
@export_range(0.0, 5.0, 0.05) var inter_wave_delay: float = 0.9
@export_range(0.1, 8.0, 0.05) var melee_range: float = 2.0
@export_range(1.0, 360.0, 1.0) var melee_arc_degrees: float = 120.0
@export_range(0.1, 8.0, 0.05) var special_range: float = 2.75
@export_range(1.0, 360.0, 1.0) var special_arc_degrees: float = 160.0
@export_range(0.1, 24.0, 0.1) var cast_range: float = 8.0
@export_range(1.0, 90.0, 0.5) var cast_arc_degrees: float = 20.0
@export var template_pool_paths: Array[String] = [
	"res://resources/room_templates/combat_small.tres",
	"res://resources/room_templates/combat_large.tres",
	"res://resources/room_templates/elite_arena.tres",
	"res://resources/room_templates/rest_alcove.tres",
	"res://resources/room_templates/reward_cache.tres",
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
@onready var audio_director: Node = get_node_or_null("/root/AudioDirector")

var boon_draft: BoonDraft = BoonDraft.new()
var player_vitals: PlayerVitals
var current_room_root: Node3D = null
var current_director: RoomDirector = null
var bound_doors: Dictionary = {}
var spawned_enemies: Dictionary = {}
var rooms_cleared: int = 0
var boons_taken: int = 0
var elapsed_seconds: float = 0.0
var scrap_earned: int = 0
var sparks_earned: int = 0
var active_run_bonuses: Dictionary = {}
var combat_resolvers: CombatResolvers = null
var current_boss = null

var _rng: RandomNumberGenerator = null
var _run_active := false
var _transitioning := false
var _death_teardown_complete := false
var _cleared_room_ids: Dictionary = {}
var _rewarded_exit_keys: Dictionary = {}
var _claimed_fixture_keys: Dictionary = {}
var _spawn_index_in_room: int = 0
var _spawn_bounds_warning_room_ids: Dictionary = {}
var _boss_intro_hold_remaining: float = 0.0
var _wave_spawn_generation: int = 0

func _ready() -> void:
	_ensure_wiring()
	if auto_start:
		var seeded := RandomNumberGenerator.new()
		seeded.seed = rng_seed
		var pool: Array[RoomTemplate] = []
		start_run(biome_id, pool, room_count, seeded)

func _process(delta: float) -> void:
	if _run_active and not _death_teardown_complete:
		elapsed_seconds += maxf(delta, 0.0)
	_tick_boss_intro(delta)

func start_new_run(run_bonuses: Dictionary = {}) -> RoomGraph:
	active_run_bonuses = run_bonuses.duplicate(true)
	return start_run()

func start_run(
	p_biome_id: String = "",
	p_template_pool: Array[RoomTemplate] = [],
	p_room_count: int = -1,
	p_rng: RandomNumberGenerator = null,
) -> RoomGraph:
	_ensure_wiring()
	_cleanup_current_room()
	_reset_run_stats()
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
	_death_teardown_complete = false
	if _run_active:
		_load_current_room()
	_render_hud_payloads()
	return graph

func run_summary(victory: bool = false) -> Dictionary:
	return {
		"victory": victory,
		"rooms_cleared": rooms_cleared,
		"boons_taken": boons_taken,
		"scrap_banked": scrap_earned,
		"sparks_banked": sparks_earned,
		"survived_seconds": elapsed_seconds,
		"elapsed": elapsed_seconds,
	}

func grant_fixture_scrap_once(fixture_key: String, amount: int = SCRAP_REWARD_VALUE) -> bool:
	if not _run_active or _death_teardown_complete or _transitioning:
		return false
	if not _claim_fixture_key(fixture_key):
		return false

	scrap_earned += maxi(amount, 0)
	_render_hud_payloads()
	return true

func refill_fixture_guard_once(fixture_key: String) -> bool:
	if not _run_active or _death_teardown_complete or _transitioning or player_vitals == null:
		return false
	if not _claim_fixture_key(fixture_key):
		return false

	player_vitals.refill_guard()
	_render_hud_payloads()
	return true

func reclaim_cast_shard_once(shard_key: String) -> bool:
	var resolver := _ensure_combat_resolvers()
	if resolver == null:
		return false
	return resolver.reclaim_cast_shard_once(shard_key)

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
	var resolver := _ensure_combat_resolvers()
	if player != null:
		player_vitals = _ensure_player_vitals(player)
		if player_vitals != null and not player_vitals.player_died.is_connected(_on_player_vitals_died):
			player_vitals.player_died.connect(_on_player_vitals_died)
		if player_vitals != null and not player_vitals.vitals_changed.is_connected(_on_player_vitals_changed):
			player_vitals.vitals_changed.connect(_on_player_vitals_changed)
		if player_vitals != null and not player_vitals.spark_surge_changed.is_connected(_on_player_spark_surge_changed):
			player_vitals.spark_surge_changed.connect(_on_player_spark_surge_changed)
		var kit := _player_ability_kit()
		if kit != null:
			kit.bind_player_vitals(player_vitals)
			if resolver != null:
				resolver.bind_ability_kit(kit)

	if camera != null:
		camera.target = player

	if run_controller != null:
		if not run_controller.room_cleared.is_connected(_on_run_controller_room_cleared):
			run_controller.room_cleared.connect(_on_run_controller_room_cleared)
		if not run_controller.doors_opened.is_connected(_on_doors_opened):
			run_controller.doors_opened.connect(_on_doors_opened)
		if not run_controller.run_completed.is_connected(_on_run_controller_completed):
			run_controller.run_completed.connect(_on_run_controller_completed)

	if not boon_draft.boon_accepted.is_connected(_on_boon_accepted):
		boon_draft.boon_accepted.connect(_on_boon_accepted)

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
		if not flow_bridge.reward_granted.is_connected(_on_flow_bridge_reward_granted):
			flow_bridge.reward_granted.connect(_on_flow_bridge_reward_granted)

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

func _ensure_combat_resolvers() -> CombatResolvers:
	if combat_resolvers != null and is_instance_valid(combat_resolvers):
		_configure_combat_resolvers(combat_resolvers)
		return combat_resolvers

	var existing := get_node_or_null("CombatResolvers")
	if existing is CombatResolvers:
		combat_resolvers = existing as CombatResolvers
	else:
		combat_resolvers = CombatResolversScript.new() as CombatResolvers
		combat_resolvers.name = "CombatResolvers"
		add_child(combat_resolvers)
	_configure_combat_resolvers(combat_resolvers)
	return combat_resolvers

func _configure_combat_resolvers(resolver: CombatResolvers) -> void:
	if resolver == null:
		return
	resolver.configure({
		"melee_range": melee_range,
		"melee_arc_degrees": melee_arc_degrees,
		"special_range": special_range,
		"special_arc_degrees": special_arc_degrees,
		"cast_range": cast_range,
		"cast_arc_degrees": cast_arc_degrees,
		"player_provider": Callable(self, "_combat_player"),
		"ability_kit_provider": Callable(self, "_player_ability_kit"),
		"enemy_snapshot_provider": Callable(self, "_spawned_enemy_snapshot"),
		"shard_parent_provider": Callable(self, "_cast_shard_parent"),
		"run_state_provider": Callable(self, "_combat_run_state"),
		"render_hud_payloads": Callable(self, "_render_hud_payloads"),
	})

func _combat_player() -> CharacterBody3D:
	return player

func _spawned_enemy_snapshot() -> Array:
	return spawned_enemies.values()

func _cast_shard_parent() -> Node:
	if current_room_root != null and is_instance_valid(current_room_root):
		return current_room_root
	return actors_root

func _combat_run_state() -> Dictionary:
	return {
		"run_active": _run_active,
		"death_teardown_complete": _death_teardown_complete,
		"transitioning": _transitioning,
	}

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
	_spawn_index_in_room = 0

	_place_player_at_spawn(current_room_root)
	bound_doors = _bind_room_doors(current_room_root)
	if camera != null:
		camera.enter_room(current_room_root)
	_start_room_director(room)
	_render_hud_payloads()
	room_loaded.emit(room, current_room_root)

func _cleanup_current_room() -> void:
	_invalidate_pending_wave_spawns()
	if combat_resolvers != null and is_instance_valid(combat_resolvers):
		combat_resolvers.clear_for_room_cleanup(true)
	_disconnect_current_boss()
	_clear_spawned_enemies()
	_disconnect_current_director()
	if current_room_root != null and is_instance_valid(current_room_root):
		var parent := current_room_root.get_parent()
		if parent != null:
			parent.remove_child(current_room_root)
		current_room_root.queue_free()
	current_room_root = null
	current_director = null
	current_boss = null
	bound_doors.clear()
	_boss_intro_hold_remaining = 0.0

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
	_disconnect_current_director()
	_disconnect_current_boss()
	if _room_is_boss(room):
		current_director = null
		_set_audio_zone_state(ZONE_STATE_COMBAT)
		_start_boss_room()
		return
	if _room_clears_without_director(room):
		current_director = null
		_set_audio_zone_state(ZONE_STATE_CLEARED)
		if run_controller != null:
			run_controller.notify_room_cleared()
		return
	var room_kind := RoomDirector.ROOM_KIND_COMBAT
	if room.template != null and room.template.room_type == RoomTemplate.RoomType.ELITE:
		room_kind = RoomDirector.ROOM_KIND_ELITE
	current_director = RoomDirector.new(room.difficulty_tier, _rng, room_kind)
	current_director.wave_requested.connect(_on_director_wave_requested)
	current_director.room_cleared.connect(_on_director_room_cleared)
	_set_audio_zone_state(ZONE_STATE_COMBAT)
	current_director.start()

func _room_is_boss(room: RoomNode) -> bool:
	return room != null and room.template != null and room.template.room_type == RoomTemplate.RoomType.BOSS

func _start_boss_room() -> void:
	current_boss = _find_current_boss()
	if current_boss == null:
		push_error("RunOrchestrator: boss room is missing CustodianBoss.")
		return
	if not (current_boss is GreyboxEnemy):
		push_error("RunOrchestrator: CustodianBoss must extend GreyboxEnemy for the combat snapshot seam.")
		current_boss = null
		return

	var boss_enemy := current_boss as GreyboxEnemy
	if boss_enemy.has_method("configure_boss"):
		boss_enemy.call("configure_boss", "boss:custodian", _rng)
	boss_enemy.set_chase_target(player)
	_connect_boss_signal(boss_enemy.died, Callable(self, "_on_boss_died"))
	_connect_boss_signal(boss_enemy.damage_event, Callable(self, "_on_enemy_damage_event"))
	_connect_boss_signal(boss_enemy.damage_taken, Callable(self, "_on_enemy_damage_taken"))
	if current_boss.has_signal("add_wave_requested"):
		_connect_boss_signal(current_boss.add_wave_requested, Callable(self, "_on_boss_add_wave_requested"))

	# Snapshot decision: the boss is a specialized GreyboxEnemy stored in
	# spawned_enemies, so melee/special/cast/surge use the HZ-079 resolver's
	# existing enemy-snapshot path and died(spawn_id) ledger contract.
	spawned_enemies[boss_enemy.spawn_id] = boss_enemy
	_start_boss_intro()

func _find_current_boss():
	if current_room_root == null:
		return null
	for boss in get_tree().get_nodes_in_group(&"boss"):
		if boss is GreyboxEnemy and (boss == current_room_root or current_room_root.is_ancestor_of(boss)):
			return boss
	var boss := current_room_root.find_child("CustodianBoss", true, false)
	if boss != null and boss.get_script() == CustodianBossScript:
		return boss
	return null

func _connect_boss_signal(boss_signal: Signal, callback: Callable) -> void:
	if not boss_signal.is_connected(callback):
		boss_signal.connect(callback)

func _start_boss_intro() -> void:
	_boss_intro_hold_remaining = BOSS_INTRO_HOLD_SECONDS
	if current_boss != null and is_instance_valid(current_boss):
		if current_boss.has_method("show_nameplate"):
			current_boss.call("show_nameplate", true)
		if camera != null:
			camera.target = current_boss

func _tick_boss_intro(delta: float) -> void:
	if _boss_intro_hold_remaining <= 0.0:
		return
	if not _run_active or _death_teardown_complete:
		_finish_boss_intro(false)
		return
	_boss_intro_hold_remaining = maxf(0.0, _boss_intro_hold_remaining - maxf(delta, 0.0))
	if _boss_intro_hold_remaining > 0.0:
		return
	_finish_boss_intro(true)

func _finish_boss_intro(begin_fight: bool) -> void:
	_boss_intro_hold_remaining = 0.0
	if current_boss != null and is_instance_valid(current_boss) and current_boss.has_method("show_nameplate"):
		current_boss.call("show_nameplate", false)
	if begin_fight and current_boss != null and is_instance_valid(current_boss) and current_boss.has_method("begin_fight"):
		current_boss.call("begin_fight")
	if camera != null and camera.target == current_boss:
		camera.target = player

func _on_director_wave_requested(_wave_index: int, requests: Array[Dictionary]) -> void:
	if not _run_active or _death_teardown_complete:
		return
	if _wave_index > 0 and inter_wave_delay > 0.0:
		_spawn_requests_after_inter_wave_delay(_wave_index, requests, _wave_spawn_generation)
		return
	_spawn_requests(requests)

func _spawn_requests_after_inter_wave_delay(wave_index: int, requests: Array[Dictionary], generation: int) -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(maxf(inter_wave_delay, 0.0)).timeout
	if (
		generation != _wave_spawn_generation
		or not _run_active
		or _death_teardown_complete
		or current_director == null
		or current_director.current_wave_index != wave_index
		or current_director.is_room_cleared()
	):
		return
	_spawn_requests(requests)

func _spawn_requests(requests: Array[Dictionary]) -> void:
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
		enemy.global_position = _spawn_position_for(
			_spawn_index_in_room,
			SPAWN_EDGE_CLEARANCE,
			SPAWN_SEPARATION_DISTANCE
		)
		_spawn_index_in_room += 1
		enemy.configure(archetype, spawn_id)
		enemy.set_chase_target(player)
		enemy.died.connect(_on_enemy_died)
		enemy.damage_event.connect(_on_enemy_damage_event)
		enemy.damage_taken.connect(_on_enemy_damage_taken)
		spawned_enemies[spawn_id] = enemy

func _spawn_position_for(index: int, edge_clearance: float = 0.0, separation_distance: float = 0.0) -> Vector3:
	var anchor := _current_room_anchor()
	var center := anchor.global_position if anchor != null else Vector3.ZERO
	var half_extents := _spawn_half_extents(anchor, edge_clearance)
	var player_position := player.global_position if player != null else center
	var required_distance := maxf(min_spawn_distance, 0.0)
	var best_valid_position := center + Vector3(0.0, 0.1, 0.0)
	var best_valid_score := -INF
	var has_valid_position := false
	var best_fallback_position := best_valid_position
	var best_fallback_nearest_enemy_distance := -INF
	var best_fallback_player_distance := -INF

	for attempt in range(SPAWN_CANDIDATE_COUNT):
		var radius := required_distance + float((index + attempt) % 3)
		var angle := (float(index) + float(attempt)) * SPAWN_GOLDEN_ANGLE
		var candidate := center + Vector3(cos(angle) * radius, 0.1, sin(angle) * radius)
		candidate = _constrain_spawn_position(candidate, center, half_extents)
		var distance := _xz_distance(candidate, player_position)
		var nearest_enemy_distance := _nearest_spawned_enemy_distance(candidate)
		var separation_ok := separation_distance <= 0.0 or nearest_enemy_distance + 0.001 >= separation_distance
		if (
			nearest_enemy_distance > best_fallback_nearest_enemy_distance + 0.001
			or (
				absf(nearest_enemy_distance - best_fallback_nearest_enemy_distance) <= 0.001
				and distance > best_fallback_player_distance
			)
		):
			best_fallback_nearest_enemy_distance = nearest_enemy_distance
			best_fallback_player_distance = distance
			best_fallback_position = candidate
		if not separation_ok:
			continue
		var score := distance + minf(nearest_enemy_distance, maxf(separation_distance, 0.0))
		if not has_valid_position or score > best_valid_score:
			has_valid_position = true
			best_valid_score = score
			best_valid_position = candidate
		if distance + 0.001 >= required_distance and separation_ok:
			return candidate

	return best_valid_position if has_valid_position else best_fallback_position

func _current_room_anchor() -> Marker3D:
	if current_room_root == null:
		return null
	return current_room_root.find_child("CameraAnchor", true, false) as Marker3D

func _spawn_half_extents(anchor: Marker3D, edge_clearance: float = 0.0) -> Vector2:
	if anchor == null:
		_warn_missing_spawn_bounds("missing CameraAnchor")
		return Vector2.ZERO
	var half_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
	var half_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
	if half_x <= 0.0 or half_z <= 0.0:
		_warn_missing_spawn_bounds("CameraAnchor lacks positive camera_half_extent_x/z metadata")
		return Vector2.ZERO
	var clearance := maxf(edge_clearance, 0.0)
	return Vector2(maxf(half_x - clearance, 0.001), maxf(half_z - clearance, 0.001))

func _constrain_spawn_position(position: Vector3, center: Vector3, half_extents: Vector2) -> Vector3:
	if half_extents.x <= 0.0 or half_extents.y <= 0.0:
		return position
	return Vector3(
		clampf(position.x, center.x - half_extents.x, center.x + half_extents.x),
		position.y,
		clampf(position.z, center.z - half_extents.y, center.z + half_extents.y)
	)

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _nearest_spawned_enemy_distance(position: Vector3) -> float:
	var nearest := INF
	for candidate in spawned_enemies.values():
		if candidate is GreyboxEnemy and is_instance_valid(candidate):
			nearest = minf(nearest, _xz_distance(position, (candidate as GreyboxEnemy).global_position))
	return nearest

func _warn_missing_spawn_bounds(reason: String) -> void:
	var room_key := 0
	var room_name := "<no room>"
	if current_room_root != null and is_instance_valid(current_room_root):
		room_key = current_room_root.get_instance_id()
		room_name = String(current_room_root.name)
	if _spawn_bounds_warning_room_ids.has(room_key):
		return
	_spawn_bounds_warning_room_ids[room_key] = true
	push_warning("RunOrchestrator: spawn containment disabled for %s: %s." % [room_name, reason])

func _on_enemy_died(spawn_id: String) -> void:
	if not _run_active or _death_teardown_complete:
		return
	if combat_resolvers != null and is_instance_valid(combat_resolvers):
		combat_resolvers.reclaim_cast_shards_for_spawn_id(spawn_id)
	var enemy := spawned_enemies.get(spawn_id) as Node
	if enemy != null and is_instance_valid(enemy):
		if enemy.has_method(&"play_death_pop_then_free"):
			enemy.call(&"play_death_pop_then_free")
		else:
			enemy.queue_free()
	spawned_enemies.erase(spawn_id)
	if current_director == null:
		# Boss-room adds are pressure only: without a RoomDirector, add deaths
		# must never clear the boss room or advance the run.
		return
	current_director.notify_kill(spawn_id)

func _on_boss_died(spawn_id: String) -> void:
	if not _run_active or _death_teardown_complete:
		return
	if combat_resolvers != null and is_instance_valid(combat_resolvers):
		combat_resolvers.reclaim_cast_shards_for_spawn_id(spawn_id)
	var boss := spawned_enemies.get(spawn_id) as Node
	if boss != null and is_instance_valid(boss):
		_clear_boss_telegraphs(boss)
		if boss.has_method(&"play_death_pop_then_free"):
			boss.call(&"play_death_pop_then_free")
		else:
			boss.queue_free()
	spawned_enemies.erase(spawn_id)
	current_boss = null
	_boss_intro_hold_remaining = 0.0
	if camera != null:
		camera.target = player
	_set_audio_zone_state(ZONE_STATE_CLEARED)
	if run_controller != null:
		run_controller.notify_room_cleared()

func _on_boss_add_wave_requested(requests: Array[Dictionary]) -> void:
	if not _run_active or _death_teardown_complete:
		return
	for request in requests:
		_spawn_from_request(request)

func _on_enemy_damage_event(event: Dictionary) -> void:
	if player_vitals == null:
		return
	player_vitals.apply_damage(int(event.get("damage", 0)))
	_render_hud_payloads()

func _on_enemy_damage_taken(_spawn_id: String, amount: float, charges_spark: bool) -> void:
	if not charges_spark or player_vitals == null:
		return
	player_vitals.record_damage_dealt(amount)
	_render_hud_payloads()

func _on_director_room_cleared() -> void:
	if not _run_active or _death_teardown_complete:
		return
	_clear_spawned_enemies()
	_set_audio_zone_state(ZONE_STATE_CLEARED)
	if run_controller != null:
		run_controller.notify_room_cleared()

func _on_doors_opened(connections: Array[RoomConnection]) -> void:
	var ordinal := 0
	for connection in connections:
		var door := _bound_door_for_connection(connection, ordinal, connections.size())
		if door == null:
			push_error("RunOrchestrator: room has no bound door named '%s'." % connection.door_name)
			ordinal += 1
			continue
		door.open_for(connection, run_controller.exit_reward_type(connection))
		ordinal += 1
	doors_bound.emit(connections)

func _bound_door_for_connection(connection: RoomConnection, ordinal: int, connection_count: int) -> RoomDoor:
	if connection == null:
		return null

	var existing := bound_doors.get(connection.door_name) as RoomDoor
	if existing != null:
		return existing

	var fallback := bound_doors.get("RoomExit") as RoomDoor
	if fallback == null:
		return null
	if connection_count <= 1:
		bound_doors[connection.door_name] = fallback
		return fallback

	return _create_runtime_branch_door(fallback, connection.door_name, ordinal, connection_count)

func _create_runtime_branch_door(
	fallback: RoomDoor,
	door_name: String,
	ordinal: int,
	connection_count: int
) -> RoomDoor:
	var parent := fallback.get_parent()
	if parent == null:
		return null

	var door := RoomDoorScript.new() as RoomDoor
	door.name = door_name
	door.transform = fallback.transform
	var center_offset := float(ordinal) - (float(connection_count) - 1.0) * 0.5
	door.position.x += center_offset * 2.4
	door.collision_layer = fallback.collision_layer
	door.collision_mask = fallback.collision_mask
	door.monitorable = fallback.monitorable
	door.input_ray_pickable = fallback.input_ray_pickable

	for child in fallback.get_children():
		if child is CollisionShape3D:
			var source_shape := child as CollisionShape3D
			var shape := CollisionShape3D.new()
			shape.name = source_shape.name
			shape.transform = source_shape.transform
			shape.shape = source_shape.shape
			shape.disabled = source_shape.disabled
			door.add_child(shape)

	parent.add_child(door)
	door.seal()
	if not door.exit_requested.is_connected(_on_door_exit_requested):
		door.exit_requested.connect(_on_door_exit_requested)
	bound_doors[door.name] = door
	return door

func _on_door_exit_requested(connection: RoomConnection) -> void:
	if not _run_active or _transitioning:
		return
	flow_bridge.request_exit(connection)

func _on_exit_completed(_connection: RoomConnection, accepted: bool) -> void:
	if not accepted or not _run_active:
		return
	if Engine.is_in_physics_frame():
		_transitioning = true
		_defer_from_physics_frame(&"_complete_exit_transition", [_connection])
		return
	_complete_exit_transition(_connection)

func _complete_exit_transition(connection: RoomConnection) -> void:
	if not _run_active:
		_transitioning = false
		return
	_apply_exit_reward(connection)
	_transitioning = true
	_load_current_room()
	_transitioning = false

func _defer_from_physics_frame(method_name: StringName, args: Array = []) -> bool:
	if not Engine.is_in_physics_frame():
		return false
	call_deferred(&"_call_after_process_frame", method_name, args)
	return true

func _call_after_process_frame(method_name: StringName, args: Array) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	callv(method_name, args)

func _on_flow_bridge_reward_granted(reward_type: RoomNode.RewardType, connection: RoomConnection) -> void:
	if connection == null or run_controller == null:
		return
	if run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON and reward_type == RoomNode.RewardType.SCRAP:
		_apply_reward_type_for_exit(reward_type, connection)

func _on_player_vitals_died() -> void:
	if not _run_active:
		return
	_run_active = false
	_death_teardown_complete = true
	_boss_intro_hold_remaining = 0.0
	_invalidate_pending_wave_spawns()
	_disconnect_current_director()
	for enemy in spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			(enemy as GreyboxEnemy).clear_chase_target()
			_clear_boss_telegraphs(enemy as Node)
	if current_boss != null and is_instance_valid(current_boss) and current_boss.has_method("show_nameplate"):
		current_boss.call("show_nameplate", false)
	if camera != null and camera.target == current_boss:
		camera.target = player
	player_died.emit()

func _on_run_controller_completed() -> void:
	_run_active = false
	_invalidate_pending_wave_spawns()
	_disconnect_current_director()
	_disconnect_current_boss()
	_clear_spawned_enemies()
	run_completed.emit()

func _on_run_controller_room_cleared(room: RoomNode) -> void:
	if room == null or _cleared_room_ids.has(room.room_id):
		return
	_cleared_room_ids[room.room_id] = true
	rooms_cleared += 1

func _on_boon_accepted(_boon: BoonDef) -> void:
	boons_taken += 1
	_render_hud_payloads()

func _on_player_vitals_changed(hp: int, max_hp: int, guard: int, max_guard: int) -> void:
	_render_vitals_payloads(hp, max_hp, guard, max_guard)

func _on_player_spark_surge_changed(charge: float, charge_max: float) -> void:
	if hud != null:
		hud.render_spark(charge, charge_max)

func _apply_exit_reward(connection: RoomConnection) -> void:
	if connection == null or run_controller == null:
		return
	_apply_reward_type_for_exit(run_controller.exit_reward_type(connection), connection)

func _apply_reward_type_for_exit(reward_type: RoomNode.RewardType, connection: RoomConnection) -> void:
	if connection == null:
		return
	var key := _connection_key(connection)
	if _rewarded_exit_keys.has(key):
		return

	match reward_type:
		RoomNode.RewardType.SCRAP:
			scrap_earned += SCRAP_REWARD_VALUE
		RoomNode.RewardType.SPARKS:
			sparks_earned += SPARKS_REWARD_VALUE
		_:
			pass
	_rewarded_exit_keys[key] = true

func _room_clears_without_director(room: RoomNode) -> bool:
	if room == null or room.template == null:
		return false
	return [
		RoomTemplate.RoomType.REST,
		RoomTemplate.RoomType.REWARD,
	].has(room.template.room_type)

func _set_audio_zone_state(state: StringName) -> void:
	if audio_director == null or not is_instance_valid(audio_director):
		audio_director = get_node_or_null("/root/AudioDirector")
	if audio_director == null:
		return
	if audio_director.has_method(&"set_zone_state"):
		audio_director.call(&"set_zone_state", state)

func _clear_spawned_enemies() -> void:
	for enemy in spawned_enemies.values():
		if enemy is Node and is_instance_valid(enemy):
			_clear_boss_telegraphs(enemy as Node)
			(enemy as Node).queue_free()
	spawned_enemies.clear()
	current_boss = null

func _disconnect_current_director() -> void:
	if current_director == null:
		return
	if current_director.wave_requested.is_connected(_on_director_wave_requested):
		current_director.wave_requested.disconnect(_on_director_wave_requested)
	if current_director.room_cleared.is_connected(_on_director_room_cleared):
		current_director.room_cleared.disconnect(_on_director_room_cleared)

func _disconnect_current_boss() -> void:
	if current_boss == null or not is_instance_valid(current_boss):
		current_boss = null
		return
	var boss_enemy := current_boss as GreyboxEnemy
	if boss_enemy != null:
		var died_callback := Callable(self, "_on_boss_died")
		var damage_event_callback := Callable(self, "_on_enemy_damage_event")
		var damage_taken_callback := Callable(self, "_on_enemy_damage_taken")
		if boss_enemy.died.is_connected(died_callback):
			boss_enemy.died.disconnect(died_callback)
		if boss_enemy.damage_event.is_connected(damage_event_callback):
			boss_enemy.damage_event.disconnect(damage_event_callback)
		if boss_enemy.damage_taken.is_connected(damage_taken_callback):
			boss_enemy.damage_taken.disconnect(damage_taken_callback)
	if current_boss.has_signal("add_wave_requested"):
		var add_wave_callback := Callable(self, "_on_boss_add_wave_requested")
		if current_boss.add_wave_requested.is_connected(add_wave_callback):
			current_boss.add_wave_requested.disconnect(add_wave_callback)
	if current_boss.has_method("show_nameplate"):
		current_boss.call("show_nameplate", false)
	_clear_boss_telegraphs(current_boss)
	current_boss = null

func _clear_boss_telegraphs(candidate: Node) -> void:
	if candidate != null and is_instance_valid(candidate) and candidate.has_method("clear_telegraph_markers"):
		candidate.call("clear_telegraph_markers")

func _render_hud_payloads() -> void:
	if hud == null:
		return
	if player_vitals != null:
		_render_vitals_payloads(player_vitals.hp, player_vitals.max_hp, player_vitals.guard, player_vitals.max_guard)
		hud.render_spark(player_vitals.spark_surge_charge, player_vitals.spark_surge_charge_max)
	hud.render_boons(boon_draft.picked_boons)
	hud.render_abilities(_ability_states())

func _render_vitals_payloads(hp: int, max_hp: int, guard: int, max_guard: int) -> void:
	if hud == null:
		return
	hud.render_guard(guard, max_guard)
	_render_hp_payload(hp, max_hp)

func _render_hp_payload(hp: int, max_hp: int) -> void:
	var hp_bar := hud.get_node_or_null("Root/Nameplate/Margin/VBox/HpRow/HpBar") as ProgressBar
	if hp_bar != null:
		hp_bar.value = 0.0 if max_hp <= 0 else clampf(float(hp) / float(max_hp), 0.0, 1.0) * 100.0

	var hp_label := hud.get_node_or_null("Root/Nameplate/Margin/VBox/HpRow/HpLabel") as Label
	if hp_label != null:
		hp_label.text = "%d / %d" % [maxi(0, hp), maxi(0, max_hp)]

func _reset_run_stats() -> void:
	rooms_cleared = 0
	boons_taken = 0
	elapsed_seconds = 0.0
	scrap_earned = 0
	sparks_earned = 0
	_cleared_room_ids.clear()
	_rewarded_exit_keys.clear()
	_claimed_fixture_keys.clear()
	if combat_resolvers != null and is_instance_valid(combat_resolvers):
		combat_resolvers.reset_for_run()
	_spawn_index_in_room = 0
	_spawn_bounds_warning_room_ids.clear()
	_invalidate_pending_wave_spawns()

func _invalidate_pending_wave_spawns() -> void:
	_wave_spawn_generation += 1

func _claim_fixture_key(fixture_key: String) -> bool:
	var key := fixture_key.strip_edges()
	if key == "" or _claimed_fixture_keys.has(key):
		return false
	_claimed_fixture_keys[key] = true
	return true

func _connection_key(connection: RoomConnection) -> String:
	if connection == null:
		return ""
	return "%s>%s:%s" % [connection.from_room_id, connection.to_room_id, connection.door_name]

func _ability_states() -> Array:
	var states: Array = []
	var kit := _player_ability_kit()
	if kit == null:
		return states
	for ability_id in [&"dash", &"attack", &"special", &"cast", &"surge"]:
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
	pool.append(_make_default_boon(&"spark_attack", "Spark-Cut", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK, &"swordbearer"))
	pool.append(_make_default_boon(&"gear_dash", "Gyre Step", BoonDef.Rarity.RARE, BoonDef.Slot.DASH, &"bearer"))
	pool.append(_make_default_boon(&"core_special", "Brass Overdrive", BoonDef.Rarity.EPIC, BoonDef.Slot.SPECIAL, &"swordbearer"))
	pool.append(_make_default_boon(&"codex_cast", "Codex Shard", BoonDef.Rarity.COMMON, BoonDef.Slot.CAST, &"marksman"))
	pool.append(_make_default_boon(&"humanity_guard", "Humanity's Reserve", BoonDef.Rarity.LEGENDARY, BoonDef.Slot.PASSIVE, &"company"))
	pool.append(_make_default_boon(&"ember_attack", "Ember Teeth", BoonDef.Rarity.RARE, BoonDef.Slot.ATTACK, &"swordbearer"))
	pool.append(_make_default_boon(&"brass_dash", "Brass Wake", BoonDef.Rarity.COMMON, BoonDef.Slot.DASH, &"bearer"))
	pool.append(_make_default_boon(&"gear_special", "Gearbreak Pulse", BoonDef.Rarity.RARE, BoonDef.Slot.SPECIAL, &"swordbearer"))
	pool.append(_make_default_boon(&"spark_cast", "Warmth Shard", BoonDef.Rarity.EPIC, BoonDef.Slot.CAST, &"marksman"))
	pool.append(_make_default_boon(&"codex_passive", "Codex Margin", BoonDef.Rarity.COMMON, BoonDef.Slot.PASSIVE, &"hearthguard"))
	return pool

func _make_default_boon(
	boon_id: StringName,
	display_name: String,
	rarity: BoonDef.Rarity,
	slot: BoonDef.Slot,
	benefactor: StringName,
) -> BoonDef:
	var boon := BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = display_name
	boon.description = "A run-scoped upgrade for this chamber chain."
	boon.rarity = rarity
	boon.slot = slot
	boon.benefactor = benefactor
	boon.domain = "spark"
	boon.validate_benefactor()
	return boon
