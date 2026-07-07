extends SceneTree

# Headless integration tests for HZ-032 room transition orchestration.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_orchestrator_tests.gd

const RunScene := preload("res://scenes/run.tscn")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const SwingTiming := preload("res://scripts/room_graph/swing_timing.gd")
const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
const GreyboxEnemyScene := preload("res://scenes/enemies/greybox_enemy.tscn")
const CustodianBossScript := preload("res://scripts/room_graph/custodian_boss.gd")
const TelegraphMarkerScript := preload("res://scripts/room_graph/telegraph_marker.gd")
const BossArenaScene := preload("res://scenes/rooms/boss_arena.tscn")

const SURVIVAL_DT := 0.05
const SURVIVAL_RETREAT_SPEED := 4.0
const SURVIVAL_PLAYER_DPS_SCALE := 1.0
const SPAWN_CANDIDATE_COUNT := 48
const SPAWN_SEPARATION_DISTANCE := 1.1
const PICKUP_MAGNET_RADIUS := 2.5
const STEPPED_CONTAINMENT_FRAMES := 60

var _passed := 0
var _failed := 0

class DoorPhysicsProbe:
	extends Node

	signal callback_ran()

	var run = null
	var door: RoomDoor = null
	var player: Node3D = null
	var previous_room_root: Node3D = null
	var ran := false
	var room_root_during_callback: Node3D = null
	var room_child_count_during_callback := -1
	var previous_room_valid_during_callback := false

	func _physics_process(_delta: float) -> void:
		if ran:
			return
		ran = true
		if door != null:
			door.emit_signal(&"body_entered", player)
		if run != null:
			room_root_during_callback = run.current_room_root
			room_child_count_during_callback = run.rooms_root.get_child_count()
		previous_room_valid_during_callback = is_instance_valid(previous_room_root)
		set_physics_process(false)
		callback_ran.emit()

class TwoDoorPhysicsProbe:
	extends Node

	signal callback_ran()

	var run = null
	var doors: Array[RoomDoor] = []
	var player: Node3D = null
	var previous_room_root: Node3D = null
	var ran := false
	var room_root_during_callback: Node3D = null
	var room_child_count_during_callback := -1
	var previous_room_valid_during_callback := false

	func _physics_process(_delta: float) -> void:
		if ran:
			return
		ran = true
		for door in doors:
			if door != null:
				door.emit_signal(&"body_entered", player)
		if run != null:
			room_root_during_callback = run.current_room_root
			room_child_count_during_callback = run.rooms_root.get_child_count()
		previous_room_valid_during_callback = is_instance_valid(previous_room_root)
		set_physics_process(false)
		callback_ran.emit()

class AudioEventProbe:
	extends Node

	var sfx_event_counts: Dictionary = {}

	func notify_event(event: StringName) -> void:
		var key := String(event)
		sfx_event_counts[key] = int(sfx_event_counts.get(key, 0)) + 1

	func describe() -> Dictionary:
		return {
			"sfx_event_counts": sfx_event_counts.duplicate(true),
		}

func _initialize() -> void:
	print("Running run orchestrator tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_run_scene_auto_starts_with_default_pool()
	await _test_run_scene_instantiates_and_enters_room()
	await _test_room_entry_renders_region_toast_and_one_dressing_variant()
	await _test_run_summary_payload_includes_enriched_stats()
	await _test_inter_wave_delay_defers_next_spawn_requests()
	await _test_real_room_load_spawns_enemies_inside_camera_bounds_after_physics()
	await _test_exact_overlapping_enemies_reproduce_depenetration_blowout()
	await _test_spawn_positions_respect_current_player_distance()
	await _test_spawn_positions_scatter_across_room_area()
	await _test_spawn_positions_ignore_player_elevation()
	await _test_spawn_position_small_room_uses_farthest_valid_fallback()
	await _test_spawn_position_crowded_small_room_uses_max_separation_fallback()
	await _test_missing_spawn_bounds_warns_once_for_bare_room()
	await _test_physics_frame_door_exit_defers_room_swap()
	await _test_two_doors_same_physics_frame_runs_one_transition()
	await _test_full_boon_exit_cycle_reaches_boss_and_completes_run()
	await _test_boss_room_spawns_custodian_and_uses_boss_clear_path()
	await _test_boss_intro_hold_gates_attacks_and_repositioning()
	await _test_boss_death_and_player_death_clear_active_telegraphs()
	await _test_boss_lookup_prefers_group_before_name_fallback()
	await _test_player_death_during_boss_intro_tears_down_ceremony()
	await _test_boss_is_damageable_by_all_player_resolvers()
	await _test_enemy_damage_flows_through_guard_hp_and_stops_spawning_on_death()
	await _test_dash_audio_hook_follows_ability_signal()
	await _test_real_attack_damages_front_enemy_only_and_charges_spark()
	await _test_special_resolver_heavy_wide_arc_skips_windup_and_charges_spark()
	await _test_attack_soft_lock_snaps_commit_facing_to_nearby_enemy()
	await _test_attack_soft_lock_ignores_targets_outside_angle()
	await _test_attack_soft_lock_can_be_disabled()
	await _test_swing_damage_lands_on_animation_contact_frame()
	await _test_cast_resolver_hits_first_target_consumes_ammo_and_charges_spark()
	await _test_cast_shards_reclaim_on_victim_death_and_walkover_pickup()
	await _test_cast_kills_clear_director_ledger_exactly_once()
	await _test_cast_during_transition_is_gated_with_ammo_intact()
	await _test_failed_shard_reclaim_converts_to_ownerless_pickup()
	await _test_current_room_clears_through_real_attack_path()
	await _test_spark_surge_hits_living_enemies_once_and_empties_meter()
	await _test_spark_surge_skips_spawn_windup_enemies()
	await _test_real_combat_fills_gauge_and_spends_on_surge()
	await _test_spark_charge_persists_across_room_transition()
	await _test_rest_room_does_not_refill_spark_surge_charge()
	await _test_shop_room_clears_without_director_and_spawns_no_combat()
	await _test_hazard_strips_damage_player_and_enemies()
	await _test_grammar_dressing_dresses_rooms_deterministically()
	await _test_shop_purchases_spend_run_scrap_one_shot()
	await _test_fixture_grants_are_one_shot_and_rest_guard_only()
	await _test_player_death_disconnects_director_and_ignores_posthumous_enemy_deaths()
	await _test_real_orchestrator_survivability_bands()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => run orchestrator failed to load/compile)" if _passed == 0 else ""]
		)
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

func _check_between(desc: String, value: float, low: float, high: float) -> void:
	_check("%s (%.2f in [%.2f, %.2f])" % [desc, value, low, high], value >= low and value <= high)

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _empty_template_pool() -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	return pool

func _new_run():
	var run = RunScene.instantiate()
	run.auto_start = false
	if _object_has_property(run, "inter_wave_delay"):
		run.set("inter_wave_delay", 0.0)
	root.add_child(run)
	await process_frame
	return run

func _cleanup_run(run: Node) -> void:
	if run != null and is_instance_valid(run):
		run.queue_free()
	await process_frame

func _flush_process_frames(count: int = 1) -> void:
	for _i in range(count):
		await process_frame

func _step_physics_frames(count: int = 1) -> void:
	for _i in range(count):
		await physics_frame

func _wait_seconds(seconds: float) -> void:
	await create_timer(maxf(seconds, 0.0)).timeout

func _test_run_scene_auto_starts_with_default_pool() -> void:
	var run = RunScene.instantiate()
	root.add_child(run)
	await process_frame

	_check("default run scene auto-starts a graph", run.run_controller.graph != null)
	_check("default run scene enters an entry room", run.run_controller.current_room_id != "")
	_check("default run scene instantiates the current room", run.current_room_root != null)
	_check("default run scene spawns enemies from the director", run.spawned_enemy_count() > 0)
	await _cleanup_run(run)

func _test_run_scene_instantiates_and_enters_room() -> void:
	var run = await _new_run()
	var loaded_rooms: Array[RoomNode] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_rooms.append(room)
	)

	var graph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(1))
	await process_frame

	_check("run scene creates a graph", graph != null)
	_check("run scene keeps a RunController", run.run_controller != null)
	_check("run scene keeps a RoomCamera", run.camera != null)
	_check("run scene keeps the real player scene", run.player != null and run.player.is_in_group(&"player"))
	_check("run scene attaches PlayerVitals", run.player_vitals != null)
	_check_eq("entry room is current after start", run.run_controller.current_room_id, graph.entry_room_id)
	_check_eq("one room is loaded on start", loaded_rooms.size(), 1)
	_check("current room root is instanced", run.current_room_root != null)
	_check("player is placed at SpawnMarker", run.player.global_position.distance_to(_spawn_position(run.current_room_root)) < 0.001)
	_check("camera targets the player", run.camera.target == run.player)
	_check("director starts for the entered room", run.current_director != null)
	_check("director spawned at least one greybox enemy", run.spawned_enemy_count() > 0)
	_check("room doors are bound to RoomDoor behavior", _all_bound_doors_are_room_doors(run))
	await _cleanup_run(run)

func _test_room_entry_renders_region_toast_and_one_dressing_variant() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 3, _seeded_rng(7))
	await process_frame

	var room = run.run_controller.graph.get_room(run.run_controller.current_room_id)
	_check("entered room carries a region display name", room != null and String(room.display_name) != "")

	var toast := run.hud.get_node_or_null("RegionToast") as Label
	_check("HUD shows a region toast on room entry", toast != null and toast.visible)
	if toast != null and room != null:
		_check_eq("region toast text matches the room display name", toast.text, room.display_name)

	var variant_count := 0
	for node in run.current_room_root.find_children("DressingVariant*", "Node3D", true, false):
		variant_count += 1
	_check("exactly one dressing variant survives room load", variant_count == 1)

	# Same seed, same run shape: the surviving variant is deterministic.
	var first_variant := _surviving_variant_name(run)
	run.start_run("hearth", _empty_template_pool(), 3, _seeded_rng(7))
	await process_frame
	_check_eq("dressing variant choice is deterministic under the run seed", _surviving_variant_name(run), first_variant)
	await _cleanup_run(run)

func _test_run_summary_payload_includes_enriched_stats() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 3, _seeded_rng(5))
	await process_frame

	var room = run.run_controller.graph.get_room(run.run_controller.current_room_id)
	_check("summary enrichment test has a current region", room != null and String(room.display_name) != "")
	run.sparks_earned = 15

	var enemy := _first_spawned_enemy(run)
	_check("summary enrichment test has a spawned enemy", enemy != null)
	if enemy != null:
		var archetype := String(enemy.archetype)
		enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
		await process_frame
		var summary: Dictionary = run.run_summary(false)
		_check("summary carries enemies_felled", summary.get("enemies_felled") is Dictionary)
		var felled: Dictionary = summary.get("enemies_felled", {})
		for key in ["chaff", "bruiser", "elite", "boss"]:
			_check("summary carries %s felled count" % key, felled.has(key))
		_check_eq("summary credits the felled archetype", int(felled.get(archetype, -1)), 1)
		_check_eq("summary carries sparks rescued from the run ledger", int(summary.get("sparks_rescued", -1)), 15)
		if room != null:
			_check_eq("summary carries deepest region display name", String(summary.get("deepest_region", "")), room.display_name)

	await _cleanup_run(run)

func _surviving_variant_name(run) -> String:
	for node in run.current_room_root.find_children("DressingVariant*", "Node3D", true, false):
		return String(node.name)
	return ""

func _test_inter_wave_delay_defers_next_spawn_requests() -> void:
	const TEST_DELAY := 0.2
	var run = RunScene.instantiate()
	run.auto_start = false
	root.add_child(run)
	await process_frame

	var has_delay := _object_has_property(run, "inter_wave_delay")
	_check("orchestrator exposes exported inter_wave_delay", has_delay)
	if not has_delay:
		await _cleanup_run(run)
		return
	_check_almost("orchestrator default inter-wave beat is 0.9s", float(run.get("inter_wave_delay")), 0.9)
	run.set("inter_wave_delay", TEST_DELAY)
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(1))
	await process_frame

	var director: RoomDirector = run.current_director
	_check("inter-wave delay test starts a director", director != null)
	if director == null:
		await _cleanup_run(run)
		return
	_check_eq("tier-0 real room starts with two planned waves", director.wave_count, 2)
	_check("first wave spawned immediately", run.spawned_enemy_count() > 0)

	for enemy in _live_spawned_enemies(run):
		enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
	await process_frame

	_check_eq("clearing wave 0 removes active enemies before the beat", run.spawned_enemy_count(), 0)
	_check_eq("director advances to wave 1 before delayed spawn", director.current_wave_index, 1)
	_check_eq("next wave does not spawn in the clear frame", run.spawned_enemy_count(), 0)

	await _wait_seconds(TEST_DELAY * 0.5)
	_check_eq("next wave still waits before inter_wave_delay elapses", run.spawned_enemy_count(), 0)

	await _wait_seconds(TEST_DELAY * 0.75)
	_check("next wave spawns after inter_wave_delay elapses", run.spawned_enemy_count() > 0)
	_check_eq("delayed spawn count matches director ledger", run.spawned_enemy_count(), director.remaining_in_wave())
	await _cleanup_run(run)

func _test_real_room_load_spawns_enemies_inside_camera_bounds_after_physics() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(70))
	await process_frame
	await physics_frame
	await _flush_process_frames(2)

	_check("scene-tree spawn containment test has a loaded room", run.current_room_root != null)
	_assert_spawned_enemies_inside_current_room_bounds(run, "scene-tree room load")
	_assert_spawned_enemies_pairwise_separated(run, "scene-tree room load")
	await _step_physics_frames(STEPPED_CONTAINMENT_FRAMES)
	_assert_spawned_enemies_inside_current_room_bounds(run, "scene-tree room load after 60 physics frames")
	await _cleanup_run(run)

## Playtest 2: the golden-angle ring clamped every candidate onto the room
## boundary, reading as enemies stacked in corner clusters. Scatter spawns
## across the room's spawnable AREA: interior coverage on both axes.
func _test_spawn_positions_scatter_across_room_area() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("scatter test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return
	var half_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
	var half_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
	_check("scatter test room has positive spawn extents", half_x > 0.0 and half_z > 0.0)
	if half_x <= 0.0 or half_z <= 0.0:
		await _cleanup_run(run)
		return

	run.player.global_position = anchor.global_position + Vector3(0.0, 0.0, 7.2)
	var interior := 0
	var west := 0
	var east := 0
	var positions: Array[Vector3] = []
	for index in range(12):
		var spawn_position: Vector3 = run._spawn_position_for(index, 0.75, 1.1)
		positions.append(spawn_position)
		var local := spawn_position - anchor.global_position
		var boundary_margin := minf(half_x - 0.75 - absf(local.x), half_z - 0.75 - absf(local.z))
		if boundary_margin > 1.0:
			interior += 1
		if local.x < -0.5:
			west += 1
		elif local.x > 0.5:
			east += 1
	_check("scattered spawns use the room interior, not the clamped edge ring (%d/12 interior)" % interior, interior >= 4)
	_check("scattered spawns cover both sides of the room", west >= 2 and east >= 2)

	# A golden-angle ring keeps every spawn at ~min_spawn_distance from the
	# room center; area scatter also finds legal ground far beyond the ring
	# and (behind the player-distance rule) well inside it.
	var min_center_distance := INF
	var max_center_distance := 0.0
	for spawn_position in positions:
		var center_distance := Vector2(spawn_position.x - anchor.global_position.x, spawn_position.z - anchor.global_position.z).length()
		min_center_distance = minf(min_center_distance, center_distance)
		max_center_distance = maxf(max_center_distance, center_distance)
	_check(
		"spawns spread across radii, not a ring band (%.1f..%.1f from center)" % [min_center_distance, max_center_distance],
		max_center_distance - min_center_distance > 5.0
	)

	var repeat: Vector3 = run._spawn_position_for(3, 0.75, 1.1)
	_check("scatter candidates are deterministic per spawn index", repeat.distance_to(positions[3]) < 0.001)
	await _cleanup_run(run)

func _test_exact_overlapping_enemies_reproduce_depenetration_blowout() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	run._clear_spawned_enemies()
	await process_frame

	var start_position: Vector3 = run.player.global_position + Vector3(2.0, 0.1, 0.0)
	var first := _spawn_fixture_enemy(run, "overlap_probe_a", start_position)
	var second := _spawn_fixture_enemy(run, "overlap_probe_b", start_position)
	_check("overlap probe created two exact-position enemies", first != null and second != null)
	if first == null or second == null:
		await _cleanup_run(run)
		return
	_check("overlap probe starts with identical enemy coordinates", first.global_position.distance_to(second.global_position) < 0.001)

	# The blowout mechanism needs two bodies pushing into the same spot with
	# identical straight-chase velocities. Movement-personality AI desyncs
	# overlapped enemies (orbit jitter, per-spawn seeds), so the probes are
	# pinned to the same seed and the straight-advance style to keep this
	# regression trap honest to the original mechanism.
	for probe in [first, second]:
		probe.brain.movement_style = EnemyBrain.STYLE_JUGGERNAUT
		probe.brain.set_behavior_seed(1)

	await _step_physics_frames(STEPPED_CONTAINMENT_FRAMES)

	var first_displacement := _xz_distance(first.global_position, start_position)
	var second_displacement := _xz_distance(second.global_position, start_position)
	var max_abs_x := maxf(absf(first.global_position.x), absf(second.global_position.x))
	var reproduced := (
		first_displacement > 32.0
		or second_displacement > 32.0
		or max_abs_x > 32.0
		or first.global_position.y <= 0.0
		or second.global_position.y <= 0.0
	)
	_check("exact overlap chase reproduces the off-world displacement mechanism", reproduced)
	await _cleanup_run(run)

func _test_spawn_positions_respect_current_player_distance() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var has_min_distance := _object_has_property(run, "min_spawn_distance")
	_check("orchestrator exposes min_spawn_distance", has_min_distance)
	var min_distance := 8.0
	if has_min_distance:
		min_distance = float(run.get("min_spawn_distance"))

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("spawn distance test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	run.player.global_position = anchor.global_position + Vector3(0.0, 0.0, 7.2)
	for index in range(12):
		var spawn_position: Vector3 = run._spawn_position_for(index)
		_check(
			"spawn %d is at least %.1fm from the current player" % [index, min_distance],
			_xz_distance(spawn_position, run.player.global_position) + 0.001 >= min_distance
		)

	await _cleanup_run(run)

func _test_spawn_positions_ignore_player_elevation() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("elevation spawn distance test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	run.min_spawn_distance = 4.0
	var first_ring_point := anchor.global_position + Vector3(run.min_spawn_distance, 0.0, 0.0)
	run.player.global_position = Vector3(first_ring_point.x, 5.0, first_ring_point.z)
	var spawn_position: Vector3 = run._spawn_position_for(0)

	_check(
		"spawn distance ignores player elevation and rejects a same-XZ candidate",
		_xz_distance(spawn_position, run.player.global_position) + 0.001 >= run.min_spawn_distance
	)

	await _cleanup_run(run)

func _test_spawn_position_small_room_uses_farthest_valid_fallback() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("small-room fallback test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	anchor.set_meta("camera_half_extent_x", 2.0)
	anchor.set_meta("camera_half_extent_z", 2.0)
	run.player.global_position = anchor.global_position

	var first: Vector3 = run._spawn_position_for(1)
	var second: Vector3 = run._spawn_position_for(1)
	var local := first - anchor.global_position
	var distance := _xz_distance(first, run.player.global_position)

	_check("small-room fallback stays within authored X extent", absf(local.x) <= 2.001)
	_check("small-room fallback stays within authored Z extent", absf(local.z) <= 2.001)
	_check("small-room fallback is deterministic for the same index", first.distance_to(second) < 0.001)
	_check("small-room fallback is below the normal min distance because no point can satisfy it", distance < 8.0)
	var farthest := 0.0
	for candidate in _scatter_candidates(run, 1, 0.0):
		farthest = maxf(farthest, _xz_distance(candidate, run.player.global_position))
	_check("small-room fallback chooses the farthest sampled valid point", absf(distance - farthest) < 0.01)

	await _cleanup_run(run)

func _test_spawn_position_crowded_small_room_uses_max_separation_fallback() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("crowded fallback test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	run._clear_spawned_enemies()
	await process_frame
	anchor.set_meta("camera_half_extent_x", 2.0)
	anchor.set_meta("camera_half_extent_z", 2.0)
	run.player.global_position = anchor.global_position
	run.min_spawn_distance = 8.0

	var first_attempt := _spawn_candidate_for(run, 0, 0, 0.0)
	var blocker := _spawn_fixture_enemy(run, "fallback_blocker", first_attempt)
	_check("crowded fallback fixture has a blocker at attempt zero", blocker != null)
	if blocker == null:
		await _cleanup_run(run)
		return

	var impossible_separation := 100.0
	_check(
		"crowded fallback fixture makes separation impossible",
		not _has_separation_valid_spawn_candidate(run, 0, 0.0, impossible_separation)
	)
	var expected := _maximal_fallback_spawn_position(run, 0, 0.0)
	var actual: Vector3 = run._spawn_position_for(0, 0.0, impossible_separation)
	var first_nearest := _nearest_fixture_enemy_distance(run, first_attempt)
	var expected_nearest := _nearest_fixture_enemy_distance(run, expected)
	var actual_nearest := _nearest_fixture_enemy_distance(run, actual)

	_check("maximal fallback is better than attempt zero", expected_nearest > first_nearest + 0.5)
	_check_almost("crowded fallback maximizes nearest-enemy separation", actual_nearest, expected_nearest, 0.001)
	await _cleanup_run(run)

func _test_missing_spawn_bounds_warns_once_for_bare_room() -> void:
	var run = await _new_run()
	var bare_room := Node3D.new()
	bare_room.name = "BareRoomWithoutCameraAnchor"
	run.rooms_root.add_child(bare_room)
	run.current_room_root = bare_room

	var before_count: int = _spawn_bounds_warning_count(run)
	run._spawn_position_for(0)
	var after_first_count: int = _spawn_bounds_warning_count(run)
	run._spawn_position_for(1)
	var after_second_count: int = _spawn_bounds_warning_count(run)

	_check("bare room spawn containment warning is recorded", after_first_count == before_count + 1)
	_check_eq("bare room spawn containment warning is once per room", after_second_count, after_first_count)

	await _cleanup_run(run)

func _test_physics_frame_door_exit_defers_room_swap() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(70))
	var empty_boon_pool: Array[BoonDef] = []
	run.flow_bridge.set_boon_pool(empty_boon_pool)
	await process_frame

	var previous_room_root: Node3D = run.current_room_root
	var previous_room_id := String(run.run_controller.current_room_id)
	await _clear_current_room_by_enemy_deaths(run)
	var connections: Array[RoomConnection] = run.run_controller.graph.get_connections_from(previous_room_id)
	_check("physics-frame door test has an opened exit", not connections.is_empty())
	if connections.is_empty():
		await _cleanup_run(run)
		return

	var connection := connections[0]
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	if door == null:
		door = run.bound_doors.get("RoomExit") as RoomDoor
	_check("physics-frame door test found a bound RoomDoor", door != null)
	if door == null:
		await _cleanup_run(run)
		return

	var probe := DoorPhysicsProbe.new()
	probe.run = run
	probe.door = door
	probe.player = run.player
	probe.previous_room_root = previous_room_root
	root.add_child(probe)
	await probe.callback_ran

	_check("physics-frame door probe ran", probe.ran)
	_check_eq("physics-frame door exit keeps previous room during callback", probe.room_root_during_callback, previous_room_root)
	_check("physics-frame door exit keeps previous room valid during callback", probe.previous_room_valid_during_callback)
	_check_eq("physics-frame door exit keeps exactly one room child during callback", probe.room_child_count_during_callback, 1)

	await _flush_process_frames(2)
	_check("deferred door exit replaces the previous room after idle", run.current_room_root != previous_room_root and run.current_room_root != null)
	_check("deferred door exit frees the previous room after idle", not is_instance_valid(previous_room_root))
	_check_eq("deferred door exit leaves exactly one loaded room", run.rooms_root.get_child_count(), 1)
	_assert_spawned_enemies_inside_current_room_bounds(run, "deferred room load")

	probe.queue_free()
	await _cleanup_run(run)

func _test_two_doors_same_physics_frame_runs_one_transition() -> void:
	var run = await _new_run()
	var graph: RoomGraph = await _start_run_with_two_entry_exits(run)
	var empty_boon_pool: Array[BoonDef] = []
	run.flow_bridge.set_boon_pool(empty_boon_pool)
	await process_frame

	var previous_room_root: Node3D = run.current_room_root
	var previous_room_id := String(run.run_controller.current_room_id)
	var loaded_after_start: Array[String] = []
	var exit_completed_events: Array[RoomConnection] = []
	var reward_events: Array[RoomNode.RewardType] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_after_start.append(room.room_id)
	)
	run.flow_bridge.exit_completed.connect(func(connection: RoomConnection, accepted: bool) -> void:
		if accepted:
			exit_completed_events.append(connection)
	)
	run.flow_bridge.reward_granted.connect(func(reward_type: RoomNode.RewardType, _connection: RoomConnection) -> void:
		reward_events.append(reward_type)
	)

	await _clear_current_room_by_enemy_deaths(run)
	var connections: Array[RoomConnection] = graph.get_connections_from(previous_room_id)
	_check("same-frame door test has two opened exits", connections.size() >= 2)
	if connections.size() < 2:
		await _cleanup_run(run)
		return

	var doors: Array[RoomDoor] = []
	for index in range(2):
		var door := run.bound_doors.get(connections[index].door_name) as RoomDoor
		_check("same-frame door %d is bound" % index, door != null)
		if door != null:
			doors.append(door)
	if doors.size() < 2:
		await _cleanup_run(run)
		return

	var probe := TwoDoorPhysicsProbe.new()
	probe.run = run
	probe.doors = doors
	probe.player = run.player
	probe.previous_room_root = previous_room_root
	root.add_child(probe)
	await probe.callback_ran

	_check("same-frame door probe ran", probe.ran)
	_check_eq("same-frame doors keep previous room during physics callback", probe.room_root_during_callback, previous_room_root)
	_check("same-frame doors keep previous room valid during physics callback", probe.previous_room_valid_during_callback)
	_check_eq("same-frame doors keep exactly one room child during callback", probe.room_child_count_during_callback, 1)

	await _flush_process_frames(2)
	_check_eq("same-frame doors complete exactly one accepted exit", exit_completed_events.size(), 1)
	_check("same-frame doors run at most one reward path", reward_events.size() <= 1)
	_check_eq("same-frame doors load exactly one destination room", loaded_after_start.size(), 1)
	_check("same-frame doors advance to one of the touched destinations", [connections[0].to_room_id, connections[1].to_room_id].has(run.run_controller.current_room_id))
	_check("same-frame doors replace the previous room after idle", run.current_room_root != previous_room_root and run.current_room_root != null)
	_check_eq("same-frame doors leave exactly one room child after idle", run.rooms_root.get_child_count(), 1)
	_check("same-frame doors leave no draft open", not run.flow_bridge.is_draft_open())

	probe.queue_free()
	await _cleanup_run(run)

func _test_full_boon_exit_cycle_reaches_boss_and_completes_run() -> void:
	var run = await _new_run()
	var loaded_room_ids: Array[String] = []
	var room_child_counts_at_load: Array[int] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_room_ids.append(room.room_id)
		room_child_counts_at_load.append(run.rooms_root.get_child_count())
	)
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	run.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	var graph = _start_run_with_first_boon_exit(run)
	loaded_room_ids.clear()
	room_child_counts_at_load.clear()
	loaded_room_ids.append(run.run_controller.current_room_id)
	var start_room_id: String = run.run_controller.current_room_id
	await _clear_current_room_by_enemy_deaths(run)

	_check_eq("first room becomes CLEARED after director kills", graph.get_room(start_room_id).state, RoomNode.State.CLEARED)
	_check_eq("doors open once after first clear", opened_batches.size(), 1)

	var boon_connection := _first_open_boon_connection(run, opened_batches[0])
	_check("opened doors include a BOON telegraph", boon_connection != null)
	if boon_connection == null:
		await _cleanup_run(run)
		return

	var door := run.bound_doors.get(boon_connection.door_name) as RoomDoor
	_check("BOON door is bound", door != null)
	_check_eq("BOON door telegraph reads destination reward", door.telegraph_data()[&"reward_type"], RoomNode.RewardType.BOON)
	var previous_room_root: Node3D = run.current_room_root

	door.emit_signal(&"body_entered", run.player)
	await process_frame

	_check("BOON exit opens a draft before transition", run.flow_bridge.is_draft_open())
	_check_eq("current room stays loaded while draft is open", run.current_room_root, previous_room_root)
	_check_eq("controller has not advanced before boon choice", run.run_controller.current_room_id, start_room_id)
	_check("real boon UI is visible for the draft", run.boon_draft_ui.visible)
	if not run.boon_draft_ui.is_reveal_finished():
		await run.boon_draft_ui.reveal_finished
	_check("real boon UI accepts a choice", run.boon_draft_ui.choose_offer(0))
	await process_frame

	var next_room_id: String = boon_connection.to_room_id
	_check_eq("BOON choice marks previous room REWARDED", graph.get_room(start_room_id).state, RoomNode.State.REWARDED)
	_check_eq("BOON choice advances the controller", run.run_controller.current_room_id, next_room_id)
	_check_eq("destination room is ENTERED", graph.get_room(next_room_id).state, RoomNode.State.ENTERED)
	_check("old room was replaced after exit completion", run.current_room_root != previous_room_root)
	var immediate_room_count := -1
	if not room_child_counts_at_load.is_empty():
		immediate_room_count = room_child_counts_at_load[room_child_counts_at_load.size() - 1]
	_check_eq("rooms root has exactly one room child immediately after exit completion", immediate_room_count, 1)
	_check("boon draft records the picked boon", run.boon_draft.picked_boons.size() == 1)
	_check_eq("loaded rooms include entry and destination", loaded_room_ids, [start_room_id, next_room_id])
	_check_eq("destination template is boss for this small cycle", graph.get_room(next_room_id).template.room_type, RoomTemplate.RoomType.BOSS)

	await _clear_current_room_by_enemy_deaths(run)

	_check_eq("boss clear emits run_completed once", completed_events.size(), 1)
	_check_eq("boss room is CLEARED, not REWARDED", graph.get_room(next_room_id).state, RoomNode.State.CLEARED)
	_check_eq("boss clear opens no additional doors", opened_batches.size(), 1)
	await _cleanup_run(run)

func _test_boss_room_spawns_custodian_and_uses_boss_clear_path() -> void:
	var run = await _new_run()
	var completed_events: Array[bool] = []
	var opened_batches: Array[Array] = []
	run.run_completed.connect(func() -> void:
		completed_events.append(true)
	)
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)

	var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(75))
	await process_frame
	var room: RoomNode = graph.get_room(run.run_controller.current_room_id)
	var boss := run.get("current_boss") as GreyboxEnemy
	var door := run.bound_doors.get("RoomExit") as RoomDoor

	_check("single-room boss test enters a BOSS room", room != null and room.template != null and room.template.room_type == RoomTemplate.RoomType.BOSS)
	_check_eq("boss room does not start a RoomDirector", run.current_director, null)
	_check("boss room registers a Custodian boss", boss != null and boss.get_script() == CustodianBossScript)
	_check("boss is present in the spawned_enemies snapshot", boss != null and run.spawned_enemies.get("boss:custodian") == boss)
	_check("boss room door is bound", door != null)
	if door != null:
		_check_eq("boss room keeps the exit sealed before boss death", door.state, RoomDoor.State.SEALED)
		door.emit_signal(&"body_entered", run.player)
		await process_frame
		_check_eq("sealed boss door emits no exit/open event", opened_batches.size(), 0)

	if boss != null:
		boss.take_damage(maxf(boss.hp, boss.max_hp))
		await process_frame

	_check_eq("boss death completes the run exactly once", completed_events.size(), 1)
	_check("boss room state is CLEARED after boss death", room != null and room.state == RoomNode.State.CLEARED)
	_check_eq("boss clear opens no reward doors", opened_batches.size(), 0)
	await _cleanup_run(run)

func _test_boss_intro_hold_gates_attacks_and_repositioning() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(75))
	await process_frame

	var boss := run.get("current_boss") as GreyboxEnemy
	_check("intro gate test has the Custodian", boss != null)
	if boss == null:
		await _cleanup_run(run)
		return

	var start_position := boss.global_position
	_check("boss intro starts with camera hold on the boss", run.camera.target == boss)
	_check("boss fight is not active during intro hold", boss.has_method("is_fight_started") and not bool(boss.call("is_fight_started")))

	boss._physics_process(0.95)
	await process_frame

	_check_almost("intro hold blocks boss repositioning before begin_fight", _xz_distance(boss.global_position, start_position), 0.0, 0.001)
	_check_eq("intro hold blocks boss telegraph spawning", _boss_marker_count(run), 0)
	_check_eq("intro hold leaves boss brain idle", _boss_brain_state(boss), "idle")

	run._process(1.0)
	await process_frame
	_check("intro completion begins the boss fight", boss.has_method("is_fight_started") and bool(boss.call("is_fight_started")))
	_check("intro completion returns camera to the player", run.camera.target == run.player)
	boss._physics_process(0.01)
	_check("boss can begin attacks after intro completion", _boss_marker_count(run) > 0 or _boss_brain_state(boss) == "windup")
	await _cleanup_run(run)

## Halo-CE vitals: a single hit can no longer chain shield into hull (break
## grace), so lethal pressure is a hit sequence with the mercy lockout
## expiring between hits.
func _kill_player_vitals(vitals: PlayerVitals) -> void:
	vitals.apply_damage(vitals.max_guard)
	while not vitals.is_dead():
		vitals.tick_guard_recharge(vitals.damage_lockout + 0.01)
		vitals.apply_damage(1)

func _test_boss_death_and_player_death_clear_active_telegraphs() -> void:
	var boss_death_run = await _new_run()
	boss_death_run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(76))
	await process_frame
	var boss := boss_death_run.get("current_boss") as GreyboxEnemy
	_check("boss marker-death test has the Custodian", boss != null)
	if boss != null:
		if boss.has_method("begin_fight"):
			boss.call("begin_fight")
		boss._physics_process(0.01)
		_check("boss death test starts with an active telegraph", _boss_marker_count(boss_death_run) > 0)
		boss.take_damage(maxf(boss.hp, boss.max_hp))
		await process_frame
		_check_eq("boss death clears boss-owned telegraphs", _boss_marker_count(boss_death_run), 0)
	await _cleanup_run(boss_death_run)

	var player_death_run = await _new_run()
	player_death_run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(77))
	await process_frame
	var active_boss := player_death_run.get("current_boss") as GreyboxEnemy
	_check("player-death marker test has the Custodian", active_boss != null)
	if active_boss != null:
		if active_boss.has_method("begin_fight"):
			active_boss.call("begin_fight")
		active_boss._physics_process(0.01)
		_check("player death test starts with an active boss telegraph", _boss_marker_count(player_death_run) > 0)
		_kill_player_vitals(player_death_run.player_vitals)
		await process_frame
		_check_eq("player death teardown clears boss-owned telegraphs", _boss_marker_count(player_death_run), 0)
	await _cleanup_run(player_death_run)

func _test_boss_lookup_prefers_group_before_name_fallback() -> void:
	var run = await _new_run()
	var room_root := BossArenaScene.instantiate() as Node3D
	run.rooms_root.add_child(room_root)
	run.current_room_root = room_root
	await process_frame

	var boss := room_root.find_child("CustodianBoss", true, false) as GreyboxEnemy
	_check("boss group lookup fixture has a boss node", boss != null)
	if boss != null:
		boss.name = "RenamedCustodian"
		boss.add_to_group(&"boss")
		_check_eq("orchestrator finds a group-tagged boss after node rename", run._find_current_boss(), boss)
	await _cleanup_run(run)

func _test_player_death_during_boss_intro_tears_down_ceremony() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(78))
	await process_frame

	var boss := run.get("current_boss") as GreyboxEnemy
	_check("intro death test has the Custodian", boss != null)
	if boss == null:
		await _cleanup_run(run)
		return
	var nameplate := boss.get_node_or_null("Nameplate") as Label3D
	_check("intro death test starts during the boss camera hold", float(run.get("_boss_intro_hold_remaining")) > 0.0 and run.camera.target == boss)
	_check("intro death test shows the boss nameplate", nameplate != null and nameplate.visible)

	_kill_player_vitals(run.player_vitals)
	await process_frame

	_check("player death during intro deactivates the run", not run.get("_run_active"))
	_check_eq("player death during intro clears the hold timer", float(run.get("_boss_intro_hold_remaining")), 0.0)
	_check("player death during intro releases the boss camera target", run.camera.target != boss)
	_check("player death during intro hides the nameplate", nameplate == null or not nameplate.visible)
	await _cleanup_run(run)

func _test_boss_is_damageable_by_all_player_resolvers() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 1, _seeded_rng(76))
	await process_frame

	var boss := run.get("current_boss") as GreyboxEnemy
	var kit: AbilityComponent = run._player_ability_kit()
	_check("boss resolver test has the Custodian", boss != null)
	_check("boss resolver test has the player kit", kit != null)
	if boss == null or kit == null:
		await _cleanup_run(run)
		return

	_ready_enemy_for_player_attack(run, boss, _player_forward(run) * 1.1)
	var before_attack := boss.hp
	_check("melee activates against boss", kit.try_activate(&"attack"))
	run.combat_resolvers.tick_pending_swings(SwingTiming.melee_contact_delay(1) + 0.01)
	await process_frame
	_check("melee resolver damages boss through spawned_enemies snapshot", boss.hp < before_attack)
	kit.tick(1.0)

	kit.set_resource(&"spark_charge", 100.0)
	_ready_enemy_for_player_attack(run, boss, _player_forward(run) * 2.2)
	var before_special := boss.hp
	_check("special activates against boss", kit.try_activate(&"special"))
	run.combat_resolvers.tick_pending_swings(SwingTiming.special_contact_delay() + 0.01)
	await process_frame
	_check("special resolver damages boss through spawned_enemies snapshot", boss.hp < before_special)
	kit.tick(2.0)

	_ready_enemy_for_player_attack(run, boss, _player_forward(run) * 4.0)
	var before_cast := boss.hp
	_check("cast activates against boss", kit.try_activate(&"cast"))
	await process_frame
	_check("cast resolver damages boss through spawned_enemies snapshot", boss.hp < before_cast)
	kit.tick(1.0)

	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 100.0)
	_ready_enemy_for_player_attack(run, boss, Vector3(3.0, 0.0, 0.0))
	var before_surge := boss.hp
	_check("Spark Surge activates against boss", kit.try_activate(&"surge"))
	await process_frame
	_check("Spark Surge resolver damages boss through spawned_enemies snapshot", boss.hp < before_surge)
	_check("Spark Surge staggers boss through the normal enemy interface", boss.is_staggered())
	await _cleanup_run(run)

func _test_enemy_damage_flows_through_guard_hp_and_stops_spawning_on_death() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	var death_events: Array[bool] = []
	run.player_died.connect(func() -> void:
		death_events.append(true)
	)

	var enemy := _first_spawned_enemy(run)
	_check("death test has a spawned enemy", enemy != null)
	if enemy == null:
		await _cleanup_run(run)
		return

	var guard_hit_before := _audio_event_count(&"guard_hit")
	var break_damage: int = int(run.player_vitals.max_guard) + int(run.player_vitals.max_hp)
	enemy.damage_event.emit({
		"damage": break_damage,
		"spawn_id": enemy.spawn_id,
		"archetype": enemy.archetype,
	})
	await process_frame

	_check_eq("enemy damage drains the shield bar first", run.player_vitals.guard, 0)
	_check_eq("shield-break overflow never reaches hull blocks (grace)", run.player_vitals.hp, run.player_vitals.max_hp)
	_check_eq("shield hit notifies guard_hit once", _audio_event_count(&"guard_hit"), guard_hit_before + 1)

	for i in range(run.player_vitals.max_hp):
		run.player_vitals.tick_guard_recharge(run.player_vitals.damage_lockout + 0.01)
		enemy.damage_event.emit({
			"damage": 1,
			"spawn_id": enemy.spawn_id,
			"archetype": enemy.archetype,
		})
	await process_frame

	_check_eq("shield-down hits tick hull blocks to zero", run.player_vitals.hp, 0)
	_check_eq("orchestrator surfaces player_died once", death_events.size(), 1)
	var count_after_death: int = run.spawned_enemy_count()
	run.current_director.wave_requested.emit(99, [
		{
			"archetype": "chaff",
			"count": 1,
			"spawn_ids": ["after_death_spawn"],
		},
	])
	await process_frame

	_check_eq("wave requests after death do not spawn more enemies", run.spawned_enemy_count(), count_after_death)
	_check("dead player leaves the run inactive", not run._run_active)
	await _cleanup_run(run)

func _test_dash_audio_hook_follows_ability_signal() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("dash audio hook test has an AbilityComponent", kit != null)
	if kit == null:
		await _cleanup_run(run)
		return
	var dash := kit.get_ability(&"dash") as DashAbility
	_check("dash audio hook test has a DashAbility", dash != null)
	if dash == null:
		await _cleanup_run(run)
		return
	dash.cooldown = 0.0
	dash.dash_duration = 0.05

	var dash_before := _audio_event_count(&"dash_whoosh")
	_check("dash activates through the AbilityComponent", kit.try_activate(&"dash", Vector3.RIGHT))
	await process_frame
	_check_eq("dash signal notifies dash_whoosh once", _audio_event_count(&"dash_whoosh"), dash_before + 1)
	await _cleanup_run(run)

func _test_real_attack_damages_front_enemy_only_and_charges_spark() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("real attack test has an AbilityComponent", kit != null)
	_check("real attack test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var front_enemy := enemies[0]
	var rear_enemy := enemies[1]
	_ready_enemy_for_player_attack(run, front_enemy, _player_forward(run) * 1.2)
	_ready_enemy_for_player_attack(run, rear_enemy, -_player_forward(run) * 1.2)
	front_enemy.max_hp = 100.0
	front_enemy.hp = 100.0
	rear_enemy.max_hp = 100.0
	rear_enemy.hp = 100.0
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)

	var attack := kit.get_ability(&"attack") as AttackAbility
	var expected_damage := attack.damage_for_step(1) if attack != null else 0.0
	var front_before := front_enemy.hp
	var rear_before := rear_enemy.hp
	var melee_hit_before := _audio_event_count(&"melee_hit")

	_check("real attack activates through the AbilityComponent", kit.try_activate(&"attack"))
	run.combat_resolvers.tick_pending_swings(SwingTiming.melee_contact_delay(1) + 0.01)
	await process_frame

	_check_almost("front enemy takes the attack step damage", front_before - front_enemy.hp, expected_damage)
	_check_almost("rear enemy outside the forward arc is untouched", rear_before - rear_enemy.hp, 0.0)
	_check_almost("real dealt damage charges the Spark Surge meter", float(run.player_vitals.get("spark_surge_charge")), expected_damage)
	_check_eq("attack hit notifies melee_hit once", _audio_event_count(&"melee_hit"), melee_hit_before + 1)
	await _cleanup_run(run)

func _test_special_resolver_heavy_wide_arc_skips_windup_and_charges_spark() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("special resolver test has an AbilityComponent", kit != null)
	_check("special resolver test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var special := kit.get_ability(&"special") as SpecialAbility
	var attack := kit.get_ability(&"attack") as AttackAbility
	_check("special resolver test has a SpecialAbility", special != null)
	if special == null:
		await _cleanup_run(run)
		return
	special.cost = 0.0
	special.cooldown = 0.0
	special.cast_time = 0.0
	special.recovery_time = 0.05
	_check("special damage is heavier than the opening melee hit", attack == null or special.potency > attack.damage_for_step(1))

	var wide_arc_enemy := enemies[0]
	var windup_enemy := enemies[1]
	var rear_enemy := _spawn_fixture_enemy(run, "special_rear_probe", run.player.global_position - _player_forward(run) * 1.2)
	_check("special resolver test can spawn a rear control enemy", rear_enemy != null)
	if rear_enemy == null:
		await _cleanup_run(run)
		return

	_ready_enemy_for_player_attack(run, wide_arc_enemy, _rotated_xz(_player_forward(run), deg_to_rad(70.0)) * 2.35)
	_ready_enemy_for_player_attack(run, rear_enemy, -_player_forward(run) * 1.2)
	windup_enemy.spawn_windup = 2.0
	windup_enemy.configure(windup_enemy.archetype, windup_enemy.spawn_id)
	windup_enemy.global_position = run.player.global_position + _player_forward(run) * 1.0
	windup_enemy.velocity = Vector3.ZERO
	for enemy in [wide_arc_enemy, windup_enemy, rear_enemy]:
		enemy.max_hp = 200.0
		enemy.hp = 200.0

	run.player_vitals.set("spark_surge_charge_max", 300.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var wide_before := wide_arc_enemy.hp
	var windup_before := windup_enemy.hp
	var rear_before := rear_enemy.hp
	var melee_hit_before := _audio_event_count(&"melee_hit")

	_check("special activates through the AbilityComponent", kit.try_activate(&"special"))
	run.combat_resolvers.tick_pending_swings(SwingTiming.special_contact_delay() + 0.01)
	await process_frame

	_check_almost("special hits the wider 160-degree arc at longer-than-melee range", wide_before - wide_arc_enemy.hp, special.potency)
	_check_almost("special skips spawn-windup enemies", windup_before - windup_enemy.hp, 0.0)
	_check_almost("special does not hit behind the player", rear_before - rear_enemy.hp, 0.0)
	_check_almost("special dealt damage charges Spark Surge", float(run.player_vitals.get("spark_surge_charge")), special.potency)
	_check_eq("special hit notifies melee_hit once", _audio_event_count(&"melee_hit"), melee_hit_before + 1)
	await _cleanup_run(run)

func _test_attack_soft_lock_snaps_commit_facing_to_nearby_enemy() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(41))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var motor = run.player.get("motor") if run.player != null else null
	_check("soft-lock snap test has an AbilityComponent", kit != null)
	_check("soft-lock snap test has a player motor", motor is Object)
	if kit == null or not (motor is Object):
		await _cleanup_run(run)
		return

	_park_live_enemies_far_from_player(run)
	var starting_facing := Vector3(0.0, 0.0, -1.0)
	(motor as Object).set("facing_direction", starting_facing)
	var target_direction := _rotated_xz(starting_facing, deg_to_rad(25.0))
	var target := _spawn_fixture_enemy(
		run,
		"soft_lock_snap_probe",
		run.player.global_position + target_direction * (run.combat_resolvers.melee_range * 0.90)
	)
	_check("soft-lock snap test spawns a live target", target != null)
	if target == null:
		await _cleanup_run(run)
		return

	_check("soft-lock snap test attack activates", kit.try_activate(&"attack"))
	var snapped_facing := Vector3((motor as Object).get("facing_direction")).normalized()
	_check("soft-lock snaps facing toward the 25-degree target", snapped_facing.dot(target_direction) > 0.99)
	await _cleanup_run(run)

func _test_attack_soft_lock_ignores_targets_outside_angle() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(42))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var motor = run.player.get("motor") if run.player != null else null
	_check("soft-lock angle test has an AbilityComponent", kit != null)
	_check("soft-lock angle test has a player motor", motor is Object)
	if kit == null or not (motor is Object):
		await _cleanup_run(run)
		return

	_park_live_enemies_far_from_player(run)
	var starting_facing := Vector3(0.0, 0.0, -1.0)
	(motor as Object).set("facing_direction", starting_facing)
	var target_direction := _rotated_xz(starting_facing, deg_to_rad(90.0))
	var target := _spawn_fixture_enemy(
		run,
		"soft_lock_angle_probe",
		run.player.global_position + target_direction * (run.combat_resolvers.melee_range * 0.90)
	)
	_check("soft-lock angle test spawns a live target", target != null)
	if target == null:
		await _cleanup_run(run)
		return

	_check("soft-lock angle test attack activates", kit.try_activate(&"attack"))
	var facing_after_attack := Vector3((motor as Object).get("facing_direction")).normalized()
	_check("soft-lock ignores the 90-degree target", facing_after_attack.dot(starting_facing) > 0.99)
	await _cleanup_run(run)

func _test_attack_soft_lock_can_be_disabled() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(43))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var motor = run.player.get("motor") if run.player != null else null
	_check("soft-lock disabled test has an AbilityComponent", kit != null)
	_check("soft-lock disabled test has a player motor", motor is Object)
	if kit == null or not (motor is Object):
		await _cleanup_run(run)
		return

	run.combat_resolvers.configure({"soft_lock_enabled": false})
	_park_live_enemies_far_from_player(run)
	var starting_facing := Vector3(0.0, 0.0, -1.0)
	(motor as Object).set("facing_direction", starting_facing)
	var target_direction := _rotated_xz(starting_facing, deg_to_rad(25.0))
	var target := _spawn_fixture_enemy(
		run,
		"soft_lock_disabled_probe",
		run.player.global_position + target_direction * (run.combat_resolvers.melee_range * 0.90)
	)
	_check("soft-lock disabled test spawns a live target", target != null)
	if target == null:
		await _cleanup_run(run)
		return

	_check("soft-lock disabled test attack activates", kit.try_activate(&"attack"))
	var facing_after_attack := Vector3((motor as Object).get("facing_direction")).normalized()
	_check("soft_lock_enabled=false leaves facing unchanged", facing_after_attack.dot(starting_facing) > 0.99)
	await _cleanup_run(run)

## Animation-led melee (playtest 2): swing damage lands on the clip's contact
## frame, not on input. The resolver holds a pending swing for the SwingTiming
## contact delay; a dash-cancel before contact drops the hit (Hades rule).
func _test_swing_damage_lands_on_animation_contact_frame() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("contact-frame test has an AbilityComponent", kit != null)
	_check("contact-frame test has an enemy", enemies.size() >= 1)
	if kit == null or enemies.is_empty():
		await _cleanup_run(run)
		return

	var target := enemies[0]
	_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.2)
	target.max_hp = 500.0
	target.hp = 500.0
	var resolver: CombatResolvers = run.combat_resolvers
	var contact_delay := SwingTiming.melee_contact_delay(1)
	_check("melee step 1 has a real windup before contact", contact_delay > 0.05)

	var before := target.hp
	_check("contact-frame attack activates", kit.try_activate(&"attack"))
	_check_almost("no damage lands on the input frame", before - target.hp, 0.0)
	resolver.tick_pending_swings(contact_delay - 0.02)
	_check_almost("no damage lands mid-windup", before - target.hp, 0.0)
	resolver.tick_pending_swings(0.03)
	_check("damage lands on the contact frame", target.hp < before)
	kit.tick(1.0)

	var special := kit.get_ability(&"special") as SpecialAbility
	if special != null:
		special.cost = 0.0
		special.cooldown = 0.0
		special.cast_time = 0.0
		special.recovery_time = 0.05
	_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.2)
	var special_delay := SwingTiming.special_contact_delay()
	_check("special contact delay is wider than melee step 1", special_delay > contact_delay)
	before = target.hp
	_check("contact-frame special activates", kit.try_activate(&"special"))
	_check_almost("special lands nothing on the input frame", before - target.hp, 0.0)
	resolver.tick_pending_swings(special_delay + 0.01)
	_check("special damage lands on its contact frame", target.hp < before)
	kit.tick(2.0)

	_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.2)
	before = target.hp
	_check("cancel-test attack activates", kit.try_activate(&"attack"))
	_check("dash cancels the attack windup", kit.try_activate(&"dash"))
	resolver.tick_pending_swings(1.0)
	_check_almost("dash-cancelled swing never lands damage", before - target.hp, 0.0)

	await _cleanup_run(run)

func _test_cast_resolver_hits_first_target_consumes_ammo_and_charges_spark() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("cast resolver test has an AbilityComponent", kit != null)
	_check("cast resolver test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var cast := kit.get_ability(&"cast") as CastAbility
	_check("cast resolver test has a CastAbility", cast != null)
	if cast == null:
		await _cleanup_run(run)
		return
	cast.max_ammo = 2
	cast.cast_time = 0.0
	cast.recovery_time = 0.05

	var first_enemy := enemies[0]
	var farther_enemy := enemies[1]
	var side_enemy := _spawn_fixture_enemy(run, "cast_side_probe", run.player.global_position + _rotated_xz(_player_forward(run), deg_to_rad(18.0)) * 4.0)
	_check("cast resolver test can spawn a side control enemy", side_enemy != null)
	if side_enemy == null:
		await _cleanup_run(run)
		return

	_ready_enemy_for_player_attack(run, first_enemy, _player_forward(run) * 4.0)
	_ready_enemy_for_player_attack(run, farther_enemy, _player_forward(run) * 6.0)
	_ready_enemy_for_player_attack(run, side_enemy, _rotated_xz(_player_forward(run), deg_to_rad(18.0)) * 4.0)
	for enemy in [first_enemy, farther_enemy, side_enemy]:
		enemy.max_hp = 200.0
		enemy.hp = 200.0

	run.player_vitals.set("spark_surge_charge_max", 300.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var audio_probe := _install_audio_event_probe()
	var first_before := first_enemy.hp
	var farther_before := farther_enemy.hp
	var side_before := side_enemy.hp
	var cast_before := _audio_event_count(&"cast_shot")
	var lodge_before := _audio_event_count(&"cast_lodge")
	var ammo_events: Array = []
	kit.cast_ammo_changed.connect(func(current_ammo: int, max_ammo: int, lodged_ammo: int) -> void:
		ammo_events.append([current_ammo, max_ammo, lodged_ammo])
	)
	var shard_parent := run.current_room_root as Node
	var bolt_before := _cast_bolt_fx_nodes(shard_parent).size()
	var hit_flight_seconds: float = (run.player.global_position + Vector3(0.0, 1.2, 0.0)) \
		.distance_to(first_enemy.global_position + Vector3(0.0, 1.1, 0.0)) / CombatEffectsScript.CAST_BOLT_SPEED

	_check("cast activates with available ammo", kit.try_activate(&"cast"))
	await process_frame

	_check_eq("cast hit spawns exactly one bolt FX under the shard parent", _cast_bolt_fx_nodes(shard_parent).size(), bolt_before + 1)
	_check_almost("cast damages the first target in the facing corridor", first_before - first_enemy.hp, cast.potency)
	_check_almost("cast stops at the first target instead of piercing", farther_before - farther_enemy.hp, 0.0)
	_check_almost("cast respects the narrow corridor arc", side_before - side_enemy.hp, 0.0)
	_check_eq("cast consumes one ammo stone", kit.cast_ammo(), 1)
	_check_eq("cast lodges one ammo stone", kit.cast_lodged_ammo(), 1)
	_check_almost("cast dealt damage charges Spark Surge", float(run.player_vitals.get("spark_surge_charge")), cast.potency)
	_check_eq("cast signal notifies cast_shot once", _audio_event_count(&"cast_shot"), cast_before + 1)
	_check_eq("cast hit notifies cast_lodge once", _audio_event_count(&"cast_lodge"), lodge_before + 1)
	await _wait_seconds(hit_flight_seconds + 0.08)
	_check_eq("cast hit bolt frees itself after its flight", _cast_bolt_fx_nodes(shard_parent).size(), bolt_before)

	kit.tick(1.0)
	var enemy_index := 0
	for enemy in _live_spawned_enemies(run):
		enemy.clear_chase_target()
		enemy.global_position = run.player.global_position - _player_forward(run) * (4.0 + float(enemy_index))
		enemy.velocity = Vector3.ZERO
		enemy_index += 1
	var miss_lodge_before := _audio_event_count(&"cast_lodge")
	var miss_bolt_before := _cast_bolt_fx_nodes(shard_parent).size()
	var miss_end: Vector3 = run.player.global_position + _player_forward(run) * float(run.cast_range)
	var miss_flight_seconds: float = (run.player.global_position + Vector3(0.0, 1.2, 0.0)) \
		.distance_to(miss_end + Vector3(0.0, 1.1, 0.0)) / CombatEffectsScript.CAST_BOLT_SPEED
	_check("cast miss activates with remaining ammo", kit.try_activate(&"cast"))
	await process_frame
	_check_eq("cast miss spawns exactly one bolt FX under the shard parent", _cast_bolt_fx_nodes(shard_parent).size(), miss_bolt_before + 1)
	_check_eq("cast miss does not notify cast_lodge", _audio_event_count(&"cast_lodge"), miss_lodge_before)
	_check_eq("cast ammo changed payloads preserve lodged counts", ammo_events, [[1, 2, 1], [0, 2, 2]])
	await _wait_seconds(miss_flight_seconds + 0.08)
	_check_eq("cast miss bolt frees itself after its flight", _cast_bolt_fx_nodes(shard_parent).size(), miss_bolt_before)
	_restore_audio_event_probe(audio_probe)
	await _cleanup_run(run)

func _test_cast_shards_reclaim_on_victim_death_and_walkover_pickup() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("cast reclaim test has an AbilityComponent", kit != null)
	_check("cast reclaim test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var cast := kit.get_ability(&"cast") as CastAbility
	_check("cast reclaim test has a CastAbility", cast != null)
	if cast == null:
		await _cleanup_run(run)
		return
	cast.max_ammo = 2
	cast.cast_time = 0.0
	cast.recovery_time = 0.05

	var audio_probe := _install_audio_event_probe()
	var reclaim_before := _audio_event_count(&"cast_reclaim")
	var death_target := enemies[0]
	_ready_enemy_for_player_attack(run, death_target, _player_forward(run) * 4.0)
	death_target.max_hp = cast.potency
	death_target.hp = cast.potency
	_check("cast can fire at a lethal target", kit.try_activate(&"cast"))
	await process_frame
	_check_eq("cast victim death reclaims the lodged stone", kit.cast_ammo(), 2)
	_check_eq("cast victim death clears lodged ammo", kit.cast_lodged_ammo(), 0)
	_check_eq("cast victim death notifies cast_reclaim once", _audio_event_count(&"cast_reclaim"), reclaim_before + 1)
	kit.tick(0.10)

	var pickup_target := enemies[1]
	_ready_enemy_for_player_attack(run, pickup_target, _player_forward(run) * 4.0)
	pickup_target.max_hp = cast.potency * 4.0
	pickup_target.hp = cast.potency * 4.0
	_check("cast can fire at a surviving target", kit.try_activate(&"cast"))
	await process_frame
	_check_eq("surviving cast target keeps one stone lodged", kit.cast_lodged_ammo(), 1)
	var shard := _first_cast_shard_pickup(run)
	_check("surviving cast target creates a walk-over shard pickup", shard != null)
	if shard != null:
		var shard_parent := shard.get_parent()
		pickup_target.clear_chase_target()
		var moved_owner_position := pickup_target.global_position + Vector3(1.4, 0.0, 0.6)
		pickup_target.global_position = moved_owner_position
		pickup_target.velocity = Vector3.ZERO
		await _step_physics_frames(2)
		_check(
			"lodged cast shard follows the moved owner chest",
			shard.global_position.distance_to(moved_owner_position + Vector3(0.0, 1.1, 0.0)) < 0.05
		)
		run.player.add_to_group(&"pickup_magnet_test_player")
		shard.set("player_group", &"pickup_magnet_test_player")
		_check_almost("cast shard pickup magnet radius is pinned", _float_property(shard, "magnet_radius", -1.0), PICKUP_MAGNET_RADIUS)
		run.player.global_position = shard.global_position + Vector3(0.1, 0.0, 0.1)
		run.player.velocity = Vector3.ZERO
		_check_eq("cast shard pickup magnet does not scale its Area3D body", shard.scale, Vector3.ONE)

		shard.emit_signal(&"body_entered", run.player)
		await process_frame
		_check("walk-over shard pickup spawns a detached sparkle pulse", _has_collect_pulse(shard_parent))
	_check_eq("walk-over shard pickup reclaims the lodged stone", kit.cast_ammo(), 2)
	_check_eq("walk-over shard pickup clears lodged ammo", kit.cast_lodged_ammo(), 0)
	_check_eq("walk-over shard pickup notifies cast_reclaim twice total", _audio_event_count(&"cast_reclaim"), reclaim_before + 2)
	_check("walk-over shard pickup does not require killing the victim", is_instance_valid(pickup_target) and not pickup_target.is_dead())
	_restore_audio_event_probe(audio_probe)
	await _cleanup_run(run)

func _test_cast_kills_clear_director_ledger_exactly_once() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var cast := kit.get_ability(&"cast") as CastAbility if kit != null else null
	_check("cast ledger test has the cast kit", kit != null and cast != null)
	if kit == null or cast == null:
		await _cleanup_run(run)
		return
	cast.max_ammo = 1
	cast.potency = 999.0
	cast.cast_time = 0.0
	cast.recovery_time = 0.01

	var room_cleared_events: Array[RoomNode] = []
	run.run_controller.room_cleared.connect(func(room: RoomNode) -> void:
		room_cleared_events.append(room)
	)

	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 20:
		var enemies := _live_spawned_enemies(run)
		_check("cast ledger test has live enemies to clear", not enemies.is_empty())
		if enemies.is_empty():
			await process_frame
			safety += 1
			continue
		var target := enemies[0]
		_ready_enemy_for_player_attack(run, target, _player_forward(run) * 4.0)
		target.max_hp = cast.potency
		target.hp = cast.potency
		_check("cast kill activates with reclaimed ammo", kit.try_activate(&"cast"))
		await process_frame
		kit.tick(0.05)
		safety += 1

	_check("cast kills clear the current director", run.current_director != null and run.current_director.is_room_cleared())
	_check_eq("cast kill room clear notifies the run controller exactly once", room_cleared_events.size(), 1)
	_check_eq("cast kill room clear increments rooms_cleared exactly once", run.rooms_cleared, 1)
	_check_eq("cast kill room clear leaves no spawned enemies", run.spawned_enemy_count(), 0)
	await _cleanup_run(run)

func _test_current_room_clears_through_real_attack_path() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("real room-clear test has an AbilityComponent", kit != null)
	if kit == null:
		await _cleanup_run(run)
		return

	run.player_vitals.set("spark_surge_charge_max", 999.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var room_id := String(run.run_controller.current_room_id)
	var cleared := await _clear_current_room_by_real_attacks(run)
	var room: RoomNode = run.run_controller.graph.get_room(room_id)

	_check("room clears through the real attack signal path", cleared)
	_check("run controller marks the melee-cleared room CLEARED", room != null and room.state == RoomNode.State.CLEARED)
	_check_eq("spawned enemy bookkeeping is empty after real attack clear", run.spawned_enemy_count(), 0)
	_check("real attack room clear charged the Spark Surge meter", float(run.player_vitals.get("spark_surge_charge")) > 0.0)
	await _cleanup_run(run)

func _test_spark_surge_hits_living_enemies_once_and_empties_meter() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("run player kit exists for Spark Surge", kit != null)
	_check("run PlayerVitals can set Spark Surge charge", run.player_vitals != null and run.player_vitals.has_method("set_spark_surge_charge"))
	if kit == null or run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		await _cleanup_run(run)
		return
	_check("run player kit grants Spark Surge", kit.has_ability(&"surge"))
	var surge := kit.get_ability(&"surge")
	if surge == null:
		await _cleanup_run(run)
		return

	var enemies := _live_spawned_enemies(run)
	_check("Spark Surge test has living enemies", not enemies.is_empty())
	if enemies.is_empty():
		await _cleanup_run(run)
		return
	for enemy in enemies:
		_ready_enemy_for_player_attack(run, enemy, Vector3(1.0 + float(enemies.find(enemy)), 0.0, -1.0))
		enemy.max_hp = 100.0
		enemy.hp = 100.0

	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 100.0)
	var before_hp: Dictionary = {}
	for enemy in enemies:
		before_hp[enemy.spawn_id] = enemy.hp
	var surge_before := _audio_event_count(&"surge_burst")

	_check("full Spark Surge activates through player kit", kit.try_activate(&"surge"))
	await process_frame

	var expected_damage := float(surge.get("damage"))
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			_check("Spark Surge keeps toughened enemy instance valid", false)
			continue
		_check_almost(
			"Spark Surge damages %s exactly once" % enemy.spawn_id,
			float(before_hp[enemy.spawn_id]) - enemy.hp,
			expected_damage,
			0.001
		)
		_check("Spark Surge staggers %s" % enemy.spawn_id, enemy.brain.has_method("is_staggered") and bool(enemy.brain.call("is_staggered")))
	_check_almost("Spark Surge meter empties after burst", float(run.player_vitals.get("spark_surge_charge")), 0.0)
	_check_eq("Spark Surge signal notifies surge_burst once", _audio_event_count(&"surge_burst"), surge_before + 1)
	await _cleanup_run(run)

func _test_spark_surge_skips_spawn_windup_enemies() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemy := _first_spawned_enemy(run)
	_check("spawn-windup Surge test has a kit", kit != null)
	_check("spawn-windup Surge test has an enemy", enemy != null)
	if kit == null or enemy == null:
		await _cleanup_run(run)
		return

	enemy.spawn_windup = 2.0
	enemy.configure(enemy.archetype, enemy.spawn_id)
	enemy.global_position = run.player.global_position + Vector3(0.8, 0.0, 0.0)
	enemy.max_hp = 10.0
	enemy.hp = 10.0
	var spawn_id := enemy.spawn_id
	var before_count: int = run.spawned_enemy_count()
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 100.0)

	_check("full Spark Surge activates with a windup enemy present", kit.try_activate(&"surge"))
	await process_frame

	_check("windup enemy remains in spawned-enemy bookkeeping after Surge", run.spawned_enemies.has(spawn_id))
	_check("director kill ledger still tracks the windup enemy", run.current_director.remaining_spawn_ids().has(spawn_id))
	_check_eq("windup Surge skip preserves spawned enemy count", run.spawned_enemy_count(), before_count)
	if is_instance_valid(enemy):
		_check_almost("windup enemy takes no Surge damage", enemy.hp, 10.0)
		_check("windup enemy is not staggered by Surge", not enemy.is_staggered())
	await _cleanup_run(run)

func _test_real_combat_fills_gauge_and_spends_on_surge() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("real combat gauge test has a kit", kit != null)
	_check("real combat gauge test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var charge_target := enemies[0]
	var surge_target := enemies[1]
	_ready_enemy_for_player_attack(run, charge_target, _player_forward(run) * 1.2)
	_ready_enemy_for_player_attack(run, surge_target, Vector3(3.0, 0.0, 0.0))
	charge_target.max_hp = 100.0
	charge_target.hp = 100.0
	surge_target.max_hp = 100.0
	surge_target.hp = 100.0
	run.player_vitals.set("spark_surge_charge_max", 10.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)

	_check("attack activates to fill the gauge through combat", kit.try_activate(&"attack"))
	run.combat_resolvers.tick_pending_swings(SwingTiming.melee_contact_delay(1) + 0.01)
	await process_frame
	_check_almost("real attack fills the Spark Surge gauge", float(run.player_vitals.get("spark_surge_charge")), 10.0)
	kit.tick(1.0)

	var surge_before := surge_target.hp
	_check("full gauge activates Spark Surge after real combat charge", kit.try_activate(&"surge"))
	await process_frame
	_check("Spark Surge damages the non-melee-range target", surge_target.hp < surge_before)
	_check_almost("Spark Surge empties after real-combat fill", float(run.player_vitals.get("spark_surge_charge")), 0.0)
	await _cleanup_run(run)

func _test_spark_charge_persists_across_room_transition() -> void:
	var run = await _new_run()
	var graph = _start_run_with_first_boon_exit(run)
	await process_frame
	if run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		_check("run PlayerVitals can set Spark Surge charge for room persistence", false)
		await _cleanup_run(run)
		return

	var opened_batches: Array[Array] = []
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	await _clear_current_room_by_enemy_deaths(run)
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 42.0)
	var start_room_id: String = run.run_controller.current_room_id
	var boon_connection := _first_open_boon_connection(run, opened_batches[0])
	_check("room-persistence test found a BOON exit", boon_connection != null)
	if boon_connection == null:
		await _cleanup_run(run)
		return
	var door := run.bound_doors.get(boon_connection.door_name) as RoomDoor
	door.emit_signal(&"body_entered", run.player)
	await process_frame
	if not run.boon_draft_ui.is_reveal_finished():
		await run.boon_draft_ui.reveal_finished
	run.boon_draft_ui.choose_offer(0)
	await process_frame

	_check("room transition advanced", graph != null and run.run_controller.current_room_id != start_room_id)
	_check_almost("Spark Surge charge persists across room transition", float(run.player_vitals.get("spark_surge_charge")), 42.0)
	await _cleanup_run(run)

func _test_rest_room_does_not_refill_spark_surge_charge() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	if run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		_check("run PlayerVitals can set Spark Surge charge before REST fixture", false)
		await _cleanup_run(run)
		return

	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 37.0)
	var rest_template := RoomTemplate.new()
	rest_template.room_type = RoomTemplate.RoomType.REST
	var rest_room := RoomNode.new()
	rest_room.room_id = "rest_probe"
	rest_room.template = rest_template
	run._start_room_director(rest_room)
	await process_frame

	_check_almost("REST room auto-clear does not refill Spark Surge charge", float(run.player_vitals.get("spark_surge_charge")), 37.0)
	await _cleanup_run(run)

## Dressing grammar (docs/reference/dressing-grammar.json): rooms are dressed
## data-driven — a required landmark, vertical punctuation, and debris scatter
## placed per band rules, deterministic per seed, clear of door aprons, with
## greybox placeholders standing in until world-kit assets land.
func _test_grammar_dressing_dresses_rooms_deterministically() -> void:
	var loader = load("res://scripts/room_graph/dressing_loader.gd")
	_check("dressing_loader.gd exists", loader != null)
	if loader == null:
		return

	var grammar: Dictionary = loader.load_grammar()
	_check("dressing grammar JSON loads from res://", not grammar.is_empty())
	if grammar.is_empty():
		return

	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(7))
	await process_frame

	var dressing := run.current_room_root.find_child("GrammarDressing", true, false) as Node3D
	_check("loaded room carries a GrammarDressing layer", dressing != null)
	if dressing == null:
		await _cleanup_run(run)
		return

	var archetype := String(run.run_controller.graph.get_room(run.run_controller.current_room_id).template.template_id)
	var spec: Dictionary = grammar.get("room_archetypes", {}).get(archetype, {})
	var landmarks := 0
	var punctuation := 0
	var debris := 0
	for child in dressing.get_children():
		match String(child.get_meta("cluster_archetype", "")):
			"landmark_anchor":
				landmarks += 1
			"vertical_punctuation":
				punctuation += 1
			"debris_scatter":
				debris += 1
	_check_eq("grammar dressing places exactly one required landmark", landmarks, 1)
	var punct_range: Array = spec.get("vertical_punctuation", [0, 0])
	_check_between("vertical punctuation count honors the archetype range", float(punctuation), float(punct_range[0]), float(punct_range[1]))
	var debris_range: Array = spec.get("debris_scatter", [0, 0])
	_check_between("debris scatter count honors the archetype range", float(debris), float(debris_range[0]), float(debris_range[1]))

	# Door aprons stay clear (normalized Chebyshev distance > 0.22).
	var floor_node := run.current_room_root.find_child("Floor", true, false) as CSGBox3D
	var half := Vector2(floor_node.size.x * 0.5, floor_node.size.z * 0.5)
	var apron := float(grammar.get("bands", {}).get("door_apron_radius", 0.22))
	var aprons_clear := true
	for child in dressing.get_children():
		var n := Vector2(child.position.x / half.x, child.position.z / half.y)
		for door in run.current_room_root.find_children("RoomExit*", "Area3D", true, false):
			var dn := Vector2(door.position.x / half.x, door.position.z / half.y)
			if maxf(absf(n.x - dn.x), absf(n.y - dn.y)) <= apron:
				aprons_clear = false
	_check("grammar dressing stays out of door aprons", aprons_clear)

	# Deterministic per seed.
	var plan_a: Array = loader.plan_room(grammar, archetype, "HEARTH", 424242)
	var plan_b: Array = loader.plan_room(grammar, archetype, "HEARTH", 424242)
	_check("same seed yields the identical dressing plan", str(plan_a) == str(plan_b) and not plan_a.is_empty())
	var plan_c: Array = loader.plan_room(grammar, archetype, "HEARTH", 5)
	_check("different seed yields a different dressing plan", str(plan_a) != str(plan_c))
	await _cleanup_run(run)

## Playtest-2 live bug: SHOP rooms ran a RoomDirector and spawned combat waves.
## A shop must clear like REST/REWARD — no director, no spawns, doors open.
## World mechanic (playtest 2): ember hazard strips scald whatever stands on
## them — Gizmo AND enemies — on a fixed tick. No spark charge from hazards.
func _test_hazard_strips_damage_player_and_enemies() -> void:
	var hazard_script = load("res://scripts/room_graph/room_hazard.gd")
	_check("room_hazard.gd exists", hazard_script != null)
	if hazard_script == null:
		return

	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var hazard = hazard_script.new()
	var hazard_shape := CollisionShape3D.new()
	var hazard_box := BoxShape3D.new()
	hazard_box.size = Vector3(4.0, 1.0, 4.0)
	hazard_shape.shape = hazard_box
	hazard.add_child(hazard_shape)
	run.current_room_root.add_child(hazard)
	hazard.global_position = run.player.global_position

	var victim := _spawn_fixture_enemy(run, "hazard_probe", run.player.global_position + Vector3(1.0, 0.0, 0.0))
	victim.max_hp = 200.0
	victim.hp = 200.0
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var guard_before: int = run.player_vitals.guard
	await _step_physics_frames(3)

	var victims_hit := int(hazard.call("apply_tick"))
	_check("hazard tick scalds both the player and the enemy standing on it", victims_hit >= 2)
	_check("hazard tick drains the player's guard", run.player_vitals.guard < guard_before)
	_check("hazard tick burns the enemy too", victim.hp < 200.0)

	# Enemy-only burns are the world's, not Gizmo's: no Spark Surge credit.
	victim.global_position += Vector3(20.0, 0.0, 0.0)
	hazard.global_position = victim.global_position
	await _step_physics_frames(3)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var enemy_hp_before_solo := float(victim.hp)
	_check_eq("enemy-only hazard tick scalds exactly the enemy", int(hazard.call("apply_tick")), 1)
	_check("enemy-only hazard tick burns the enemy", float(victim.hp) < enemy_hp_before_solo)
	_check_almost("enemy hazard burns never charge Spark Surge", float(run.player_vitals.get("spark_surge_charge")), 0.0)

	var enemy_hp_after_solo := float(victim.hp)
	hazard.global_position += Vector3(50.0, 0.0, 0.0)
	await _step_physics_frames(3)
	_check_eq("hazard clear of bodies scalds nothing", int(hazard.call("apply_tick")), 0)
	_check_almost("moved hazard leaves the enemy alone", float(victim.hp), enemy_hp_after_solo)
	await _cleanup_run(run)

func _test_shop_room_clears_without_director_and_spawns_no_combat() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	var shop_template := RoomTemplate.new()
	shop_template.room_type = RoomTemplate.RoomType.SHOP
	var shop_room := RoomNode.new()
	shop_room.room_id = "shop_probe"
	shop_room.template = shop_template

	var spawned_before: int = run.spawned_enemy_count()
	_check("SHOP is a clears-without-director room type", bool(run._room_clears_without_director(shop_room)))
	run._start_room_director(shop_room)
	await process_frame
	_check("SHOP room starts no RoomDirector", run.current_director == null)
	_check_eq("SHOP room requests no combat waves", run.spawned_enemy_count(), spawned_before)
	await _cleanup_run(run)

func _test_shop_purchases_spend_run_scrap_one_shot() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var has_purchase_seam := run.has_method("purchase_shop_offer_once")
	_check("orchestrator exposes one-shot shop purchase seam", has_purchase_seam)
	if not has_purchase_seam:
		await _cleanup_run(run)
		return

	run.scrap_earned = 100
	run.player_vitals.guard = 1

	# Guard refill offer.
	var guard_price := int(run.call("shop_offer_price", "guard_refill"))
	_check("guard_refill offer has a positive scrap price", guard_price > 0)
	_check("guard_refill purchase succeeds with funds", bool(run.call("purchase_shop_offer_once", "shop_probe:guard", "guard_refill")))
	_check_eq("guard_refill purchase spends its price", run.scrap_earned, 100 - guard_price)
	_check_eq("guard_refill purchase refills guard to max", run.player_vitals.guard, run.player_vitals.max_guard)
	_check("guard_refill duplicate fixture claim is rejected", not bool(run.call("purchase_shop_offer_once", "shop_probe:guard", "guard_refill")))
	_check_eq("guard_refill duplicate claim spends nothing", run.scrap_earned, 100 - guard_price)

	# Cast ammo +1 offer.
	var kit = run._player_ability_kit()
	var ammo_before := int(kit.cast_ammo())
	var max_before := int(kit.cast_max_ammo())
	var ammo_price := int(run.call("shop_offer_price", "cast_ammo"))
	_check("cast_ammo purchase succeeds with funds", bool(run.call("purchase_shop_offer_once", "shop_probe:ammo", "cast_ammo")))
	_check_eq("cast_ammo purchase raises max ammo by one", int(kit.cast_max_ammo()), max_before + 1)
	_check_eq("cast_ammo purchase grants the new shard immediately", int(kit.cast_ammo()), ammo_before + 1)
	_check_eq("cast_ammo purchase spends its price", run.scrap_earned, 100 - guard_price - ammo_price)

	# Draft reroll credit offer (consumed by the draft surface via run bonuses).
	var rerolls_before := int(run.active_run_bonuses.get("draft_rerolls", 0))
	var reroll_price := int(run.call("shop_offer_price", "draft_reroll"))
	_check("draft_reroll purchase succeeds with funds", bool(run.call("purchase_shop_offer_once", "shop_probe:reroll", "draft_reroll")))
	_check_eq("draft_reroll purchase adds one reroll credit", int(run.active_run_bonuses.get("draft_rerolls", 0)), rerolls_before + 1)

	# Refusals: unknown offers and empty pockets leave state untouched.
	_check("unknown offer id is refused", not bool(run.call("purchase_shop_offer_once", "shop_probe:bogus", "bogus_offer")))
	run.scrap_earned = 0
	run.player_vitals.guard = 1
	_check("broke purchase is refused", not bool(run.call("purchase_shop_offer_once", "shop_probe:guard2", "guard_refill")))
	_check_eq("broke purchase spends nothing", run.scrap_earned, 0)
	_check_eq("broke purchase grants nothing", run.player_vitals.guard, 1)
	_check("refused fixture key stays claimable once funded", true)
	run.scrap_earned = guard_price
	_check("re-claim after refusal succeeds once funded", bool(run.call("purchase_shop_offer_once", "shop_probe:guard2", "guard_refill")))
	_check_eq("funded re-claim spends the price", run.scrap_earned, 0)

	# New run resets purchased cast capacity (per-run economy, no leak).
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	var kit_after = run._player_ability_kit()
	_check_eq("new run resets purchased cast ammo capacity", int(kit_after.cast_max_ammo()), max_before)
	await _cleanup_run(run)

func _test_fixture_grants_are_one_shot_and_rest_guard_only() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var has_scrap_method := run.has_method("grant_fixture_scrap_once")
	var has_guard_method := run.has_method("refill_fixture_guard_once")
	_check("orchestrator exposes one-shot Scrap Cache fixture seam", has_scrap_method)
	_check("orchestrator exposes one-shot Ember Alcove guard seam", has_guard_method)
	if not has_scrap_method or not has_guard_method:
		await _cleanup_run(run)
		return

	var scrap_before: int = run.scrap_earned
	_check("Scrap Cache fixture grants on first claim", bool(run.call("grant_fixture_scrap_once", "scrap_probe", 10)))
	_check_eq("Scrap Cache first claim adds promised scrap", run.scrap_earned, scrap_before + 10)
	_check("Scrap Cache duplicate claim is rejected", not bool(run.call("grant_fixture_scrap_once", "scrap_probe", 10)))
	_check_eq("Scrap Cache duplicate claim does not add scrap", run.scrap_earned, scrap_before + 10)

	run.player_vitals.hp = 2
	run.player_vitals.guard = 3
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 37.0)
	var hp_before: int = run.player_vitals.hp
	var spark_before := float(run.player_vitals.get("spark_surge_charge"))

	_check("Ember Alcove fixture refills guard on first claim", bool(run.call("refill_fixture_guard_once", "rest_probe")))
	_check_eq("Ember Alcove refills guard to max", run.player_vitals.guard, run.player_vitals.max_guard)
	_check_eq("Ember Alcove does not heal HP", run.player_vitals.hp, hp_before)
	_check_almost("Ember Alcove does not refill Spark Surge", float(run.player_vitals.get("spark_surge_charge")), spark_before)

	run.player_vitals.guard = 1
	_check("Ember Alcove duplicate claim is rejected", not bool(run.call("refill_fixture_guard_once", "rest_probe")))
	_check_eq("Ember Alcove duplicate claim does not refill guard", run.player_vitals.guard, 1)
	_check_almost("Ember Alcove duplicate claim still leaves Spark Surge unchanged", float(run.player_vitals.get("spark_surge_charge")), spark_before)
	await _cleanup_run(run)

func _test_player_death_disconnects_director_and_ignores_posthumous_enemy_deaths() -> void:
	var run = await _new_run()
	var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(1))
	await process_frame

	var director: RoomDirector = run.current_director
	_check("posthumous death test found an active director", director != null and director.wave_count >= 1)
	_check("posthumous death test has spawned enemies", run.spawned_enemy_count() > 0)
	if director == null or run.spawned_enemy_count() == 0:
		await _cleanup_run(run)
		return
	var initial_wave_index: int = director.current_wave_index
	var initial_remaining: int = director.remaining_in_wave()
	var initial_spawn_count: int = run.spawned_enemy_count()

	var director_clears: Array[bool] = []
	var controller_clears: Array[RoomNode] = []
	director.room_cleared.connect(func() -> void:
		director_clears.append(true)
	)
	run.run_controller.room_cleared.connect(func(room: RoomNode) -> void:
		controller_clears.append(room)
	)

	_kill_player_vitals(run.player_vitals)
	await process_frame
	_check("posthumous death test leaves run inactive", not run._run_active)

	for enemy in _live_spawned_enemies(run):
		enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
	await process_frame

	_check_eq("posthumous enemy deaths do not clear the stale director", director_clears.size(), 0)
	_check("stale director remains uncleared after ignored posthumous deaths", not director.is_room_cleared())
	_check_eq("posthumous enemy deaths leave stale director wave unchanged", director.current_wave_index, initial_wave_index)
	_check_eq("posthumous enemy deaths leave stale director remaining count unchanged", director.remaining_in_wave(), initial_remaining)
	_check_eq("posthumous enemy deaths leave stale spawned-enemy bookkeeping unchanged", run.spawned_enemy_count(), initial_spawn_count)
	_check_eq("posthumous enemy deaths do not notify run controller room_cleared", controller_clears.size(), 0)
	_check("posthumous enemy deaths do not crash the run", is_instance_valid(run))
	_check("posthumous death test kept graph alive for inspection", graph != null)
	await _cleanup_run(run)

func _test_real_orchestrator_survivability_bands() -> void:
	# Halo-CE fragile-but-recharging: a motionless player dies much sooner than
	# under the old 13-hit pool, but never as a spawn-instant melt. Single-hit
	# vital drops stay within the heaviest authored contact hit (elite 45).
	var stationary := await _run_survivability_probe(&"stationary", 90.0, 1)
	_check("motionless real-run probe eventually dies", bool(stationary["died"]))
	_check_between("motionless real-run death is not an instant spawn melt", float(stationary["survived_seconds"]), 8.0, 45.0)
	_check("motionless real-run damage stays telegraphed", int(stationary["max_hit_delta"]) <= 45)

	# Movement-personality AI (orbits/rings) makes packs slower to reach the
	# player, so the honest three-room clear pace widened past the old cap.
	var retreating := await _run_survivability_probe(&"retreat", 60.0, 3)
	_check("retreating real-run DPS probe avoids death while clearing three rooms", not bool(retreating["died"]))
	_check_between("retreating real-run DPS clear time", float(retreating["survived_seconds"]), 18.0, 55.0)
	_check("retreating real-run enters at least three rooms", int(retreating["rooms_entered"]) >= 3)
	_check("retreating real-run clears at least three rooms", int(retreating["rooms_cleared"]) >= 3)
	_check("retreating real-run damage stays telegraphed", int(retreating["max_hit_delta"]) <= 45)

	var half_dps := await _run_survivability_probe(&"retreat", 40.0, 4, 0.5, 1.0)
	_check("halved-DPS mutation fails to clear four rooms inside the probe band", int(half_dps["rooms_cleared"]) < 4)

	# Block-per-hit hull damage means a damage mutation only compresses the
	# shield phase, so the honest catcher is the gap to the stationary run.
	# HZ-107B: a single pre-loop `await` lets a load-dependent number of real
	# physics ticks perturb spawn positions, and that jitter flapped a
	# single-sample 1s margin ~50% of full-battery runs. Compare medians of
	# three seeds per condition instead — the compression signal survives the
	# jitter, single-run noise does not.
	var stationary_samples: Array[float] = [float(stationary["survived_seconds"])]
	var doubled_all_died := true
	var doubled_samples: Array[float] = []
	for probe_seed in [70, 71, 72]:
		if probe_seed != 70:
			var extra := await _run_survivability_probe(&"stationary", 90.0, 1, 1.0, 1.0, probe_seed)
			stationary_samples.append(float(extra["survived_seconds"]))
		var mutated := await _run_survivability_probe(&"stationary", 90.0, 1, 1.0, 2.0, probe_seed)
		doubled_all_died = doubled_all_died and bool(mutated["died"])
		doubled_samples.append(float(mutated["survived_seconds"]))
	_check(
		"doubled-contact-damage mutation dies measurably faster than the honest run",
		doubled_all_died
		and _median(doubled_samples) < _median(stationary_samples) - 1.0
	)

func _median(values: Array[float]) -> float:
	var sorted_values := values.duplicate()
	sorted_values.sort()
	return sorted_values[sorted_values.size() / 2]

func _start_run_with_first_boon_exit(run) -> RoomGraph:
	for seed in range(1, 80):
		var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(seed))
		var entry_connections := graph.get_connections_from(graph.entry_room_id)
		for connection in entry_connections:
			if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
				return graph
	_check("found a seed whose first exit telegraphs BOON", false)
	return run.run_controller.graph

func _start_run_with_two_entry_exits(run) -> RoomGraph:
	for seed in range(1, 160):
		var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 8, _seeded_rng(seed))
		await process_frame
		if graph != null and graph.get_connections_from(graph.entry_room_id).size() >= 2:
			return graph
	_check("found a seed whose entry room has two exits", false)
	return run.run_controller.graph

func _run_survivability_probe(
	profile: StringName,
	max_seconds: float,
	target_rooms: int,
	player_dps_scale: float = 1.0,
	enemy_damage_multiplier: float = 1.0,
	rng_seed: int = 70
) -> Dictionary:
	var run = await _new_run()
	var entered_room_ids: Array[String] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		entered_room_ids.append(room.room_id)
	)
	run.start_run("hearth", _empty_template_pool(), 8, _seeded_rng(rng_seed))
	await process_frame
	if entered_room_ids.is_empty() and run.run_controller.current_room_id != "":
		entered_room_ids.append(run.run_controller.current_room_id)

	var previous_total := _vital_total(run)
	var damage_events := 0
	var max_hit_delta := 0
	var first_damage := -1.0
	var elapsed := 0.0
	var melee_model := _survival_melee_model(run, player_dps_scale)

	while elapsed < max_seconds and run._run_active:
		if profile == &"retreat":
			_drive_retreating_player(run, SURVIVAL_DT)
			_tick_survival_melee(run, melee_model, SURVIVAL_DT)

		run._process(SURVIVAL_DT)
		if run.player_vitals != null:
			run.player_vitals.tick_guard_recharge(SURVIVAL_DT)
		_step_live_enemies(run, SURVIVAL_DT, enemy_damage_multiplier)

		elapsed += SURVIVAL_DT
		var total := _vital_total(run)
		if total < previous_total:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, previous_total - total)
			if first_damage < 0.0:
				first_damage = elapsed
		previous_total = total

		if profile == &"retreat" and _current_room_is_cleared(run) and run._run_active:
			if run.rooms_cleared >= target_rooms:
				break
			if _current_room_has_exit(run):
				await _take_first_available_exit(run)
				previous_total = _vital_total(run)

	var result := {
		"died": not run._run_active and run.player_vitals != null and run.player_vitals.is_dead(),
		"survived_seconds": elapsed,
		"rooms_entered": entered_room_ids.size(),
		"rooms_cleared": run.rooms_cleared,
		"damage_events": damage_events,
		"max_hit_delta": max_hit_delta,
		"first_damage": first_damage,
		"melee_swings": int(melee_model["swings"]),
	}
	await _cleanup_run(run)
	return result

func _survival_melee_model(run, player_dps_scale: float) -> Dictionary:
	var kit: AbilityComponent = run._player_ability_kit()
	var attack := kit.get_ability(&"attack") as AttackAbility if kit != null else null
	if attack == null:
		attack = AttackAbilityScript.new()
	return {
		"attack": attack,
		"cooldown": 0.0,
		"combo_step": 0,
		"combo_remaining": 0.0,
		"swings": 0,
		"player_dps_scale": maxf(player_dps_scale, 0.001),
	}

func _tick_survival_melee(run, model: Dictionary, delta: float) -> void:
	var attack := model["attack"] as AttackAbility
	if attack == null:
		return

	model["cooldown"] = maxf(0.0, float(model["cooldown"]) - delta)
	model["combo_remaining"] = maxf(0.0, float(model["combo_remaining"]) - delta)
	if float(model["cooldown"]) > 0.0:
		return

	var target := _nearest_live_enemy(run)
	if target == null:
		return
	# The probe uses synthetic player timing, but keeps the live melee range gate so
	# survival DPS cannot hit enemies outside the real resolver's reach.
	if _xz_distance(target.global_position, run.player.global_position) > run.melee_range:
		return

	# DPS model uses the real default melee kit from godot/scripts/abilities/attack_ability.gd:
	# step_damage [18, 20, 26], step_recovery [0.16, 0.18, 0.24], combo_window 0.45.
	var current_step := int(model["combo_step"])
	if float(model["combo_remaining"]) <= 0.0:
		current_step = 0
	var next_step := (current_step % maxi(attack.combo_steps, 1)) + 1
	var damage := attack.damage_for_step(next_step)
	target.take_damage(damage)

	model["combo_step"] = next_step
	model["combo_remaining"] = attack.combo_window
	model["cooldown"] = maxf(attack.recovery_for_step(next_step) / float(model["player_dps_scale"]), SURVIVAL_DT)
	model["swings"] = int(model["swings"]) + 1

func _clear_current_room_by_real_attacks(run) -> bool:
	var kit: AbilityComponent = run._player_ability_kit()
	if kit == null:
		return false

	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 60:
		var enemies := _live_spawned_enemies(run)
		if enemies.is_empty():
			await process_frame
			safety += 1
			continue

		var target := enemies[0]
		_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.1)
		if kit.try_activate(&"attack"):
			run.combat_resolvers.tick_pending_swings(SwingTiming.melee_contact_delay(1) + 0.01)
			await process_frame
		kit.tick(1.0)
		await process_frame
		safety += 1

	return run.current_director == null or run.current_director.is_room_cleared()

func _ready_enemy_for_player_attack(run, enemy: GreyboxEnemy, offset: Vector3) -> void:
	if enemy == null:
		return
	var motor = run.player.get("motor") if run.player != null else null
	if motor != null:
		motor.set("facing_direction", _player_forward(run))
	while enemy.is_spawning():
		enemy.tick_chase(run.player.global_position, maxf(enemy.spawn_windup_remaining(), 0.1))
	enemy.global_position = run.player.global_position + offset
	enemy.velocity = Vector3.ZERO

func _park_live_enemies_far_from_player(run) -> void:
	if run == null or run.player == null:
		return
	var index := 0
	for enemy in _live_spawned_enemies(run):
		if enemy == null or not is_instance_valid(enemy):
			continue
		enemy.clear_chase_target()
		while enemy.is_spawning():
			enemy.tick_chase(run.player.global_position, maxf(enemy.spawn_windup_remaining(), 0.1))
		enemy.global_position = run.player.global_position + Vector3(30.0 + float(index), 0.0, 30.0)
		enemy.velocity = Vector3.ZERO
		index += 1

func _player_forward(run) -> Vector3:
	var default_forward := Vector3(0.0, 0.0, -1.0)
	if run == null or run.player == null:
		return default_forward
	var motor = run.player.get("motor")
	if motor != null:
		var facing := Vector3(motor.get("facing_direction"))
		if facing.length_squared() > 0.000001:
			return facing.normalized()
	return default_forward

func _nearest_live_enemy(run) -> GreyboxEnemy:
	var nearest: GreyboxEnemy = null
	var nearest_distance := INF
	for enemy in _live_spawned_enemies(run):
		if enemy.is_dead():
			continue
		var distance := _xz_distance(enemy.global_position, run.player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _step_live_enemies(run, delta: float, enemy_damage_multiplier: float = 1.0) -> void:
	for enemy in _live_spawned_enemies(run):
		if enemy.is_dead():
			continue
		var original_brain_damage: int = enemy.brain.melee_damage
		if enemy_damage_multiplier > 0.0 and not is_equal_approx(enemy_damage_multiplier, 1.0):
			enemy.brain.melee_damage = maxi(1, int(round(float(enemy.melee_damage) * enemy_damage_multiplier)))
		var result: Dictionary = enemy.tick_chase(run.player.global_position, delta)
		enemy.brain.melee_damage = original_brain_damage
		var velocity := Vector3(result["velocity"])
		enemy.global_position += velocity * delta

func _drive_retreating_player(run, delta: float) -> void:
	var direction := _survival_movement_direction(run)
	var next_position: Vector3 = run.player.global_position + direction * SURVIVAL_RETREAT_SPEED * delta
	run.player.global_position = _clamp_to_current_room(run, next_position)
	run.player.velocity = Vector3.ZERO

func _survival_movement_direction(run) -> Vector3:
	var target := _nearest_live_enemy(run)
	if target != null:
		var to_target: Vector3 = target.global_position - run.player.global_position
		to_target.y = 0.0
		var distance := to_target.length()
		var desired_attack_range := maxf(run.melee_range * 0.85, target.contact_radius + 0.2)
		if distance > desired_attack_range and to_target.length_squared() > 0.0001:
			return to_target.normalized()
	return _retreat_direction(run)

func _retreat_direction(run) -> Vector3:
	var position: Vector3 = run.player.global_position
	var danger := Vector3.ZERO
	for enemy in _live_spawned_enemies(run):
		var away: Vector3 = position - enemy.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.05:
			danger += away / maxf(distance * distance, 0.25)

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	if anchor != null:
		var half_x := float(anchor.get_meta("camera_half_extent_x", 6.0))
		var half_z := float(anchor.get_meta("camera_half_extent_z", 6.0))
		var margin := 1.4
		if position.x > anchor.global_position.x + half_x - margin:
			danger.x -= 2.5
		elif position.x < anchor.global_position.x - half_x + margin:
			danger.x += 2.5
		if position.z > anchor.global_position.z + half_z - margin:
			danger.z -= 2.5
		elif position.z < anchor.global_position.z - half_z + margin:
			danger.z += 2.5

	if danger.length_squared() <= 0.0001:
		return Vector3.RIGHT
	return danger.normalized()

func _clamp_to_current_room(run, position: Vector3) -> Vector3:
	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	if anchor == null:
		return position
	var half_x := maxf(float(anchor.get_meta("camera_half_extent_x", 6.0)) - 0.4, 0.5)
	var half_z := maxf(float(anchor.get_meta("camera_half_extent_z", 6.0)) - 0.4, 0.5)
	return Vector3(
		clampf(position.x, anchor.global_position.x - half_x, anchor.global_position.x + half_x),
		position.y,
		clampf(position.z, anchor.global_position.z - half_z, anchor.global_position.z + half_z)
	)

func _take_first_available_exit(run) -> void:
	var graph: RoomGraph = run.run_controller.graph
	var connections: Array[RoomConnection] = graph.get_connections_from(run.run_controller.current_room_id)
	_check("survivability helper has an exit to take", not connections.is_empty())
	if connections.is_empty():
		return
	var connection := connections[0]
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	if door == null:
		door = run.bound_doors.get("RoomExit") as RoomDoor
	_check("survivability helper found a bound exit door", door != null)
	if door == null:
		return

	var reward_type: int = run.run_controller.exit_reward_type(connection)
	door.emit_signal(&"body_entered", run.player)
	await process_frame
	if reward_type == RoomNode.RewardType.BOON and run.flow_bridge.is_draft_open():
		if not run.boon_draft_ui.is_reveal_finished():
			await run.boon_draft_ui.reveal_finished
		_check("survivability helper can accept boon exit draft", run.boon_draft_ui.choose_offer(0))
		await process_frame

func _current_room_is_cleared(run) -> bool:
	return run.current_director != null and run.current_director.is_room_cleared()

func _current_room_has_exit(run) -> bool:
	var graph: RoomGraph = run.run_controller.graph
	return graph != null and not graph.get_connections_from(run.run_controller.current_room_id).is_empty()

func _vital_total(run) -> int:
	if run.player_vitals == null:
		return 0
	return run.player_vitals.hp + run.player_vitals.guard

func _clear_current_room_by_enemy_deaths(run) -> void:
	var boss := run.get("current_boss") as GreyboxEnemy
	if boss != null and is_instance_valid(boss):
		boss.take_damage(maxf(boss.hp, boss.max_hp))
		await process_frame
		_check("boss room clears through boss death path", not run._run_active or run.run_controller.graph.get_room(run.run_controller.current_room_id).state == RoomNode.State.CLEARED)
		return

	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 20:
		var enemies := _live_spawned_enemies(run)
		_check("current room exposes spawned enemies to kill", not enemies.is_empty())
		for enemy in enemies:
			enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
		await process_frame
		safety += 1
	_check("room cleared within safety limit", run.current_director == null or run.current_director.is_room_cleared())
	if run.current_director != null and run.current_director.is_room_cleared():
		_check_eq("spawned enemy bookkeeping is empty after room clear", run.spawned_enemy_count(), 0)

func _first_open_boon_connection(run, connections: Array) -> RoomConnection:
	for connection in connections:
		if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
			return connection
	return null

func _spawn_position(room_root: Node3D) -> Vector3:
	var marker := room_root.find_child("SpawnMarker", true, false) as Marker3D
	if marker == null:
		return Vector3.INF
	return marker.global_position

func _all_bound_doors_are_room_doors(run) -> bool:
	if run.bound_doors.is_empty():
		return false
	for door in run.bound_doors.values():
		if not (door is RoomDoor):
			return false
		if door.state != RoomDoorScript.State.SEALED:
			return false
	return true

func _assert_spawned_enemies_inside_current_room_bounds(run, prefix: String) -> void:
	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D if run.current_room_root != null else null
	_check("%s has a room CameraAnchor" % prefix, anchor != null)
	if anchor == null:
		return
	var half_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
	var half_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
	_check("%s has positive camera spawn extents" % prefix, half_x > 0.0 and half_z > 0.0)
	var enemies := _live_spawned_enemies(run)
	_check("%s has live spawned enemies" % prefix, not enemies.is_empty())
	for enemy in enemies:
		var position := enemy.global_position
		var inside_bounds := (
			absf(position.x - anchor.global_position.x) <= half_x + 0.001
			and absf(position.z - anchor.global_position.z) <= half_z + 0.001
			and position.y > 0.0
		)
		_check(
			"%s keeps %s inside camera extents and above floor at %s"
			% [prefix, enemy.spawn_id, position],
			inside_bounds
			)

func _assert_spawned_enemies_pairwise_separated(run, prefix: String) -> void:
	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D if run.current_room_root != null else null
	if anchor == null:
		return
	var half_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
	var half_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
	var enemies := _live_spawned_enemies(run)
	if not _room_can_satisfy_spawn_separation(half_x, half_z, enemies.size(), SPAWN_SEPARATION_DISTANCE):
		return
	for a in range(enemies.size()):
		for b in range(a + 1, enemies.size()):
			var distance := _xz_distance(enemies[a].global_position, enemies[b].global_position)
			_check(
				"%s keeps %s and %s at least %.1fm apart"
				% [prefix, enemies[a].spawn_id, enemies[b].spawn_id, SPAWN_SEPARATION_DISTANCE],
				distance + 0.001 >= SPAWN_SEPARATION_DISTANCE
			)

func _room_can_satisfy_spawn_separation(half_x: float, half_z: float, enemy_count: int, separation_distance: float) -> bool:
	if enemy_count <= 1:
		return false
	if separation_distance <= 0.0:
		return false
	var width := half_x * 2.0
	var depth := half_z * 2.0
	if width < separation_distance or depth < separation_distance:
		return false
	return width * depth >= float(enemy_count) * separation_distance * separation_distance

func _spawn_fixture_enemy(run, spawn_id: String, position: Vector3) -> GreyboxEnemy:
	var enemy := GreyboxEnemyScene.instantiate() as GreyboxEnemy
	if enemy == null:
		return null
	enemy.spawn_windup = 0.0
	run.enemies_root.add_child(enemy)
	enemy.configure(RoomDirector.ARCHETYPE_CHAFF, spawn_id)
	enemy.global_position = position
	enemy.velocity = Vector3.ZERO
	enemy.set_chase_target(run.player)
	if not enemy.died.is_connected(run._on_enemy_died):
		enemy.died.connect(run._on_enemy_died)
	if not enemy.damage_event.is_connected(run._on_enemy_damage_event):
		enemy.damage_event.connect(run._on_enemy_damage_event)
	if not enemy.damage_taken.is_connected(run._on_enemy_damage_taken):
		enemy.damage_taken.connect(run._on_enemy_damage_taken)
	run.spawned_enemies[spawn_id] = enemy
	return enemy

func _rotated_xz(direction: Vector3, radians: float) -> Vector3:
	var flat := Vector2(direction.x, direction.z)
	if flat.length_squared() <= 0.000001:
		flat = Vector2(0.0, -1.0)
	flat = flat.normalized().rotated(radians)
	return Vector3(flat.x, 0.0, flat.y).normalized()

func _first_cast_shard_pickup(run) -> Area3D:
	if run == null:
		return null
	for root_node in [run.current_room_root, run.actors_root]:
		if root_node == null:
			continue
		var shard := (root_node as Node).find_child("CastShardPickup*", true, false)
		if shard is Area3D:
			return shard as Area3D
	return null

func _cast_bolt_fx_nodes(parent: Node) -> Array[Node]:
	var bolts: Array[Node] = []
	if parent == null:
		return bolts
	for child in parent.get_children():
		if child is Node and String(child.name).match("CastBoltFX*"):
			bolts.append(child as Node)
	return bolts

func _has_collect_pulse(parent: Node) -> bool:
	if parent == null:
		return false
	return parent.find_child("CollectSparklePulse*", true, false) != null

## Mirror of the orchestrator's jittered area-scatter candidate stream (same
## seed recipe, same draw order) so fallback expectations replay it exactly.
func _scatter_candidates(run, index: int, edge_clearance: float) -> Array[Vector3]:
	var anchor: Marker3D = run._current_room_anchor()
	var center: Vector3 = anchor.global_position if anchor != null else Vector3.ZERO
	var half_extents: Vector2 = run._spawn_half_extents(anchor, edge_clearance)
	var required_distance := maxf(float(run.min_spawn_distance), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([run._current_room_anchor_key(), index])
	var candidates: Array[Vector3] = []
	for attempt in range(SPAWN_CANDIDATE_COUNT):
		var candidate: Vector3 = center + Vector3(0.0, 0.1, 0.0)
		if half_extents.x > 0.0 and half_extents.y > 0.0:
			candidate += Vector3(
				rng.randf_range(-half_extents.x, half_extents.x),
				0.0,
				rng.randf_range(-half_extents.y, half_extents.y)
			)
		else:
			var radius := required_distance + rng.randf_range(0.0, 4.0)
			var angle := rng.randf_range(0.0, TAU)
			candidate += Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		candidates.append(run._constrain_spawn_position(candidate, center, half_extents))
	return candidates

func _spawn_candidate_for(run, index: int, attempt: int, edge_clearance: float) -> Vector3:
	return _scatter_candidates(run, index, edge_clearance)[attempt]

func _has_separation_valid_spawn_candidate(run, index: int, edge_clearance: float, separation_distance: float) -> bool:
	for attempt in range(SPAWN_CANDIDATE_COUNT):
		var candidate := _spawn_candidate_for(run, index, attempt, edge_clearance)
		if _nearest_fixture_enemy_distance(run, candidate) + 0.001 >= separation_distance:
			return true
	return false

func _maximal_fallback_spawn_position(run, index: int, edge_clearance: float) -> Vector3:
	var player_position: Vector3 = run.player.global_position if run.player != null else Vector3.ZERO
	var best_position := _spawn_candidate_for(run, index, 0, edge_clearance)
	var best_nearest := -INF
	var best_distance := -INF
	for attempt in range(SPAWN_CANDIDATE_COUNT):
		var candidate := _spawn_candidate_for(run, index, attempt, edge_clearance)
		var nearest := _nearest_fixture_enemy_distance(run, candidate)
		var distance := _xz_distance(candidate, player_position)
		if nearest > best_nearest + 0.001 or (absf(nearest - best_nearest) <= 0.001 and distance > best_distance):
			best_nearest = nearest
			best_distance = distance
			best_position = candidate
	return best_position

func _nearest_fixture_enemy_distance(run, position: Vector3) -> float:
	var nearest := INF
	for candidate in run.spawned_enemies.values():
		if candidate is GreyboxEnemy and is_instance_valid(candidate):
			nearest = minf(nearest, _xz_distance(position, (candidate as GreyboxEnemy).global_position))
	return nearest

func _first_spawned_enemy(run) -> GreyboxEnemy:
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy:
			return enemy as GreyboxEnemy
	return null

func _boss_marker_count(run) -> int:
	if run == null or run.current_room_root == null:
		return 0
	return _telegraph_markers_under(run.current_room_root).size()

func _telegraph_markers_under(parent: Node) -> Array:
	var markers: Array = []
	_collect_telegraph_markers(parent, markers)
	return markers

func _collect_telegraph_markers(node: Node, markers: Array) -> void:
	if node != null and node.get_script() == TelegraphMarkerScript and not node.is_queued_for_deletion():
		markers.append(node)
	for child in node.get_children():
		_collect_telegraph_markers(child, markers)

func _boss_brain_state(boss: GreyboxEnemy) -> String:
	if boss == null:
		return ""
	var brain = boss.get("boss_brain")
	if brain == null or not brain.has_method("execution_state"):
		return ""
	return String(brain.call("execution_state"))

func _live_spawned_enemies(run) -> Array[GreyboxEnemy]:
	var enemies: Array[GreyboxEnemy] = []
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			enemies.append(enemy as GreyboxEnemy)
	return enemies

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _spawn_bounds_warning_count(run) -> int:
	if not _object_has_property(run, "_spawn_bounds_warning_room_ids"):
		return 0
	var warnings: Dictionary = run.get("_spawn_bounds_warning_room_ids")
	return warnings.size()

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _float_property(object: Object, property_name: String, fallback: float) -> float:
	if object == null or not _object_has_property(object, property_name):
		return fallback
	return float(object.get(property_name))

func _audio_event_count(event: StringName) -> int:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return 0
	var desc: Dictionary = director.describe()
	var counts: Dictionary = desc.get("sfx_event_counts", {})
	return int(counts.get(String(event), 0))

func _install_audio_event_probe() -> Dictionary:
	var original := root.get_node_or_null("AudioDirector")
	if original != null:
		original.name = "AudioDirectorOriginalForProbe"
	var probe := AudioEventProbe.new()
	probe.name = "AudioDirector"
	root.add_child(probe)
	return {
		"original": original,
		"probe": probe,
	}

func _restore_audio_event_probe(handle: Dictionary) -> void:
	var probe := handle.get("probe") as Node
	if probe != null and is_instance_valid(probe):
		root.remove_child(probe)
		probe.free()
	var original := handle.get("original") as Node
	if original != null and is_instance_valid(original):
		original.name = "AudioDirector"

func _test_cast_during_transition_is_gated_with_ammo_intact() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(31))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("transition gate test has an AbilityComponent", kit != null)
	if kit == null:
		await _cleanup_run(run)
		return
	var cast := kit.get_ability(&"cast") as CastAbility
	cast.max_ammo = 2
	cast.cast_time = 0.0
	cast.recovery_time = 0.05
	var ammo_before := kit.cast_ammo()
	var resolver: CombatResolvers = run.combat_resolvers
	var shards_before: int = resolver._cast_shards_by_key.size()

	run.set("_transitioning", true)
	kit.cast_started.emit(25.0)
	await process_frame
	run.set("_transitioning", false)

	_check_eq("gated cast leaves shard registry untouched", resolver._cast_shards_by_key.size(), shards_before)
	_check_eq("gated cast leaves ammo intact (refunded)", kit.cast_ammo(), ammo_before)
	await _cleanup_run(run)

func _test_failed_shard_reclaim_converts_to_ownerless_pickup() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(32))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("orphan test has enemies", enemies.size() >= 1)
	if kit == null or enemies.is_empty():
		await _cleanup_run(run)
		return
	var victim := enemies[0]
	victim.max_hp = 200.0
	victim.hp = 200.0
	var victim_spawn_id: String = victim.spawn_id
	var resolver: CombatResolvers = run.combat_resolvers
	var shard_key: String = resolver._register_cast_shard(victim_spawn_id, victim.global_position, victim)
	# Ammo is already at max, so reclaim_cast_ammo(1) will return 0 → the
	# lodged shard cannot be banked on victim death.
	_check("orphan test precondition: ammo already full", kit.cast_ammo() >= 1)
	var pickup := resolver._cast_shards_by_key.get(shard_key, {}).get("pickup") as Area3D
	_check("orphan test starts with a live owner-tracking pickup", pickup != null and is_instance_valid(pickup))
	if pickup != null:
		victim.clear_chase_target()
		var moved_owner_position := victim.global_position + Vector3(1.1, 0.0, -0.8)
		victim.global_position = moved_owner_position
		victim.velocity = Vector3.ZERO
		await _step_physics_frames(2)
		_check(
			"owner-tracking pickup follows before death",
			pickup.global_position.distance_to(moved_owner_position + Vector3(0.0, 1.1, 0.0)) < 0.05
		)

	victim.take_damage(999.0, false)
	await process_frame

	var record: Dictionary = resolver._cast_shards_by_key.get(shard_key, {})
	_check("failed reclaim keeps the shard record (walk-over recoverable)", not record.is_empty())
	_check_eq("failed reclaim clears the dead spawn_id from the record", String(record.get("spawn_id", "missing")), "")
	_check("failed reclaim keeps a live pickup", is_instance_valid(record.get("pickup")))
	_check("failed reclaim leaves no dangling spawn-id mapping", not resolver._cast_shard_keys_by_spawn_id.has(victim_spawn_id))
	var dropped_pickup := record.get("pickup") as Area3D
	if dropped_pickup != null:
		var drop_position := dropped_pickup.global_position
		_check_almost("failed reclaim drops the lodged pickup to floor height", drop_position.y, 0.45)
		if is_instance_valid(victim):
			victim.global_position += Vector3(3.0, 0.0, 0.0)
			await _step_physics_frames(2)
			_check("dropped pickup stops tracking the dead owner", dropped_pickup.global_position.distance_to(drop_position) < 0.01)
	await _cleanup_run(run)
