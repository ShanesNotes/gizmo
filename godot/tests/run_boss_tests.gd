extends SceneTree

# HZ-075 Custodian boss tests.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata-075 --path godot --script res://tests/run_boss_tests.gd

const BossBrainScript := preload("res://scripts/room_graph/boss_brain.gd")
const TelegraphMarkerScript := preload("res://scripts/room_graph/telegraph_marker.gd")
const CustodianBossScript := preload("res://scripts/room_graph/custodian_boss.gd")
const RoomDirectorScript := preload("res://scripts/room_graph/room_director.gd")
const BossArenaScene := preload("res://scenes/rooms/boss_arena.tscn")

const BOSS_HP := 2400.0
const DPS_MODEL := 110.0

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running Custodian boss tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_telegraph_marker_lifecycle_and_shapes()
	_test_boss_brain_phase_ladder_unlocks_and_add_waves_once()
	_test_boss_brain_attack_roster_timing_and_damage_contract()
	_test_boss_brain_seeded_selection_is_no_repeat_with_cooldowns()
	_test_boss_brain_windup_commit_recovery_lifecycle()
	_test_boss_brain_single_large_hit_emits_skipped_thresholds_in_order()
	await _test_custodian_surge_interrupts_windup_and_clears_markers()
	await _test_custodian_live_dps_ttk_crosses_all_phases()
	await _test_custodian_contact_suppression_and_ledger_invariants()
	await _test_custodian_is_snapshot_damageable_enemy()
	await _test_boss_arena_uses_custodian_model()
	await _test_custodian_visual_presides_over_the_arena()
	await _test_custodian_windup_presence_and_death_powerdown()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => boss tests failed to load/compile)" if _passed == 0 else ""]
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

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _check_between(desc: String, value: float, low: float, high: float) -> void:
	_check("%s (%.2f in [%.2f, %.2f])" % [desc, value, low, high], value >= low and value <= high)

func _test_telegraph_marker_lifecycle_and_shapes() -> void:
	var marker = TelegraphMarkerScript.new()
	root.add_child(marker)
	var committed: Array[String] = []
	marker.committed.connect(func(marker_id: String) -> void:
		committed.append(marker_id)
	)

	marker.configure({
		"marker_id": "disc_probe",
		"shape": "disc",
		"radius": 3.0,
		"duration": 0.2,
		"color": Color(1.0, 0.72, 0.22, 0.72),
		"pulse": true,
	})
	var disc_description: Dictionary = marker.describe()
	_check_eq("disc marker records shape", disc_description.get("shape", ""), "disc")
	_check_almost("disc marker records radius", float(disc_description.get("radius", 0.0)), 3.0)
	_check("disc marker owns a visual mesh", marker.visual_mesh() is MeshInstance3D)
	_check("disc marker is alive before duration elapses", not marker.is_queued_for_deletion())

	marker.advance_lifecycle(0.19)
	_check_eq("disc marker does not commit early", committed.size(), 0)
	marker.advance_lifecycle(0.02)
	_check_eq("disc marker commits once at duration", committed, ["disc_probe"])
	_check("disc marker queues itself for cleanup on commit", marker.is_queued_for_deletion())
	marker.queue_free()

	var line_marker = TelegraphMarkerScript.new()
	root.add_child(line_marker)
	line_marker.configure({
		"marker_id": "line_probe",
		"shape": "line",
		"length": 7.5,
		"width": 0.65,
		"duration": 1.0,
		"color": Color(1.0, 0.2, 0.1, 0.8),
	})
	var line_description: Dictionary = line_marker.describe()
	_check_eq("line marker records shape", line_description.get("shape", ""), "line")
	_check_almost("line marker records length", float(line_description.get("length", 0.0)), 7.5)
	_check_almost("line marker records width", float(line_description.get("width", 0.0)), 0.65)
	line_marker.commit()
	_check("line marker queues itself for cleanup on explicit commit", line_marker.is_queued_for_deletion())
	line_marker.queue_free()

func _test_boss_brain_phase_ladder_unlocks_and_add_waves_once() -> void:
	var brain = _new_brain(75)
	var add_waves: Array[Array] = []
	brain.add_wave_requested.connect(func(requests: Array[Dictionary]) -> void:
		add_waves.append(requests.duplicate(true))
	)

	brain.update_health(2400.0, BOSS_HP)
	_check_eq("full HP starts in phase 1", brain.current_phase(), 1)
	_check_eq("phase 1 unlocks two attacks", brain.unlocked_attack_ids(), ["audit_sweep", "compliance_ring"])
	_check_eq("full HP emits no add wave", add_waves.size(), 0)

	brain.update_health(1800.0, BOSS_HP)
	_check_eq("75 percent threshold enters phase 2", brain.current_phase(), 2)
	_check_eq("phase 2 unlocks Overreach Slam", brain.unlocked_attack_ids(), ["audit_sweep", "compliance_ring", "overreach_slam"])
	_assert_requests_eq("75 percent add wave is exactly 2 chaff", add_waves[0], [
		{"archetype": RoomDirectorScript.ARCHETYPE_CHAFF, "count": 2, "spawn_ids": ["boss75:chaff:0", "boss75:chaff:1"]},
	])

	brain.update_health(1200.0, BOSS_HP)
	_check_eq("50 percent threshold enters phase 3", brain.current_phase(), 3)
	_check_eq("phase 3 unlocks Decoy Ping", brain.unlocked_attack_ids(), ["audit_sweep", "compliance_ring", "overreach_slam", "decoy_ping"])
	_assert_requests_eq("50 percent add wave is exactly 1 chaff + 1 bruiser", add_waves[1], [
		{"archetype": RoomDirectorScript.ARCHETYPE_CHAFF, "count": 1, "spawn_ids": ["boss50:chaff:0"]},
		{"archetype": RoomDirectorScript.ARCHETYPE_BRUISER, "count": 1, "spawn_ids": ["boss50:bruiser:0"]},
	])

	brain.update_health(600.0, BOSS_HP)
	_check_eq("25 percent threshold enters phase 4", brain.current_phase(), 4)
	_assert_requests_eq("25 percent add wave is exactly 2 chaff", add_waves[2], [
		{"archetype": RoomDirectorScript.ARCHETYPE_CHAFF, "count": 2, "spawn_ids": ["boss25:chaff:0", "boss25:chaff:1"]},
	])

	brain.update_health(500.0, BOSS_HP)
	brain.update_health(600.0, BOSS_HP)
	_check_eq("threshold add waves are emitted exactly once", add_waves.size(), 3)

func _test_boss_brain_attack_roster_timing_and_damage_contract() -> void:
	var brain = _new_brain(75)
	var expected := {
		"audit_sweep": {"telegraph_seconds": 0.9, "damage": 2, "shape": "line"},
		"compliance_ring": {"telegraph_seconds": 0.8, "damage": 1, "shape": "disc"},
		"overreach_slam": {"telegraph_seconds": 1.2, "damage": 2, "shape": "disc"},
		"decoy_ping": {"telegraph_seconds": 1.4, "damage": 2, "shape": "decoy_discs"},
	}
	for attack_id in expected.keys():
		var attack: Dictionary = brain.attack_definition(String(attack_id))
		var contract: Dictionary = expected[attack_id]
		_check_eq("%s exists in roster" % attack_id, attack.get("id", ""), attack_id)
		_check_almost("%s telegraph duration matches spec" % attack_id, float(attack.get("telegraph_seconds", 0.0)), float(contract["telegraph_seconds"]))
		_check("%s telegraph is at least 0.8s" % attack_id, float(attack.get("telegraph_seconds", 0.0)) >= 0.8)
		_check("%s damage is <= half the shield bar" % attack_id, int(attack.get("damage", 99)) <= 50)
		_check_eq("%s uses the specified marker shape" % attack_id, attack.get("shape", ""), contract["shape"])

	brain.update_health(600.0, BOSS_HP)
	var phase_four_slam: Dictionary = brain.attack_definition("overreach_slam")
	_check_almost("phase 4 applies 0.8x cooldown tempo", float(phase_four_slam.get("cooldown_seconds", 0.0)), 1.28)
func _test_boss_brain_seeded_selection_is_no_repeat_with_cooldowns() -> void:
	var first = _new_brain(1234)
	var second = _new_brain(1234)
	first.update_health(1200.0, BOSS_HP)
	second.update_health(1200.0, BOSS_HP)

	var first_sequence: Array[String] = _selection_sequence(first, 12)
	var second_sequence: Array[String] = _selection_sequence(second, 12)
	_check_eq("seeded boss attack selection is deterministic", first_sequence, second_sequence)
	_check("seeded boss selection covers at least three unlocked attacks", _unique_count(first_sequence) >= 3)
	for index in range(1, first_sequence.size()):
		_check("boss attack selection has no immediate repeat at %d" % index, first_sequence[index] != first_sequence[index - 1])

	var cooldown_brain = _new_brain(5)
	cooldown_brain.update_health(1200.0, BOSS_HP)
	var first_attack: Dictionary = cooldown_brain.begin_next_attack()
	cooldown_brain.force_finish_current_attack()
	var blocked_id := String(first_attack.get("id", ""))
	_check("committed attack starts its cooldown", cooldown_brain.cooldown_remaining(blocked_id) > 0.0)
	var second_attack: Dictionary = cooldown_brain.begin_next_attack()
	_check("next attack respects cooldown/no-repeat", second_attack.is_empty() or String(second_attack.get("id", "")) != blocked_id)

func _test_boss_brain_windup_commit_recovery_lifecycle() -> void:
	var brain = _new_brain(9)
	var started: Array[String] = []
	var committed: Array[String] = []
	brain.attack_windup_started.connect(func(attack: Dictionary) -> void:
		started.append(String(attack.get("id", "")))
	)
	brain.attack_committed.connect(func(attack: Dictionary) -> void:
		committed.append(String(attack.get("id", "")))
	)

	var attack: Dictionary = brain.begin_next_attack()
	var attack_id := String(attack.get("id", ""))
	_check("boss brain begins a windup attack", attack_id != "")
	_check_eq("windup signal carries selected attack", started, [attack_id])
	_check_eq("brain enters windup state", brain.execution_state(), "windup")
	brain.tick(float(attack.get("telegraph_seconds", 0.0)) - 0.01)
	_check_eq("attack does not commit before telegraph finishes", committed.size(), 0)
	brain.tick(0.02)
	_check_eq("attack commits once after telegraph", committed, [attack_id])
	_check_eq("brain enters recovery after commit", brain.execution_state(), "recovery")
	brain.tick(float(attack.get("recovery_seconds", 0.0)) + 0.01)
	_check_eq("brain returns to idle after recovery", brain.execution_state(), "idle")

func _test_boss_brain_single_large_hit_emits_skipped_thresholds_in_order() -> void:
	var brain = _new_brain(75)
	var add_waves: Array[Array] = []
	brain.add_wave_requested.connect(func(requests: Array[Dictionary]) -> void:
		add_waves.append(requests.duplicate(true))
	)

	brain.update_health(BOSS_HP - 1250.0, BOSS_HP)

	_check_eq("single large hit skips directly to phase 3", brain.current_phase(), 3)
	_check_eq("single large hit emits the 75 and 50 add waves once", add_waves.size(), 2)
	if add_waves.size() >= 2:
		_assert_requests_eq("skipped 75 percent add wave fires first", add_waves[0], [
			{"archetype": RoomDirectorScript.ARCHETYPE_CHAFF, "count": 2, "spawn_ids": ["boss75:chaff:0", "boss75:chaff:1"]},
		])
		_assert_requests_eq("skipped 50 percent add wave fires second", add_waves[1], [
			{"archetype": RoomDirectorScript.ARCHETYPE_CHAFF, "count": 1, "spawn_ids": ["boss50:chaff:0"]},
			{"archetype": RoomDirectorScript.ARCHETYPE_BRUISER, "count": 1, "spawn_ids": ["boss50:bruiser:0"]},
		])
	brain.update_health(100.0, BOSS_HP)
	_check_eq("large-hit threshold ladder never duplicates earlier waves", add_waves.size(), 3)

func _test_custodian_surge_interrupts_windup_and_clears_markers() -> void:
	var fixture := Node3D.new()
	fixture.name = "BossInterruptFixture"
	root.add_child(fixture)
	var boss = _new_custodian_fixture(fixture, _seeded_rng(12))
	var player := CharacterBody3D.new()
	player.name = "PlayerProbe"
	fixture.add_child(player)
	player.global_position = Vector3(0.0, 0.1, -2.0)
	await process_frame

	boss.set_chase_target(player)
	if boss.has_method("begin_fight"):
		boss.call("begin_fight")
	var telegraph_before := _audio_event_count(&"boss_telegraph")
	boss._physics_process(0.01)
	var committed_attacks: Array[String] = []
	boss.boss_brain.attack_committed.connect(func(attack: Dictionary) -> void:
		committed_attacks.append(String(attack.get("id", "")))
	)

	_check_eq("Custodian starts the probe attack in windup", boss.boss_brain.execution_state(), BossBrainScript.STATE_WINDUP)
	_check("Custodian windup owns telegraph markers before Surge", _telegraph_markers_under(fixture).size() > 0)
	_check_eq("Custodian telegraph start notifies boss_telegraph once", _audio_event_count(&"boss_telegraph"), telegraph_before + 1)

	boss.stagger(0.35)
	_check_eq("Spark Surge interrupt moves an active windup to recovery", boss.boss_brain.execution_state(), BossBrainScript.STATE_RECOVERY)
	await process_frame
	_check_eq("Spark Surge interrupt frees active telegraph markers", _telegraph_markers_under(fixture).size(), 0)

	boss.boss_brain.tick(2.0)
	_check_eq("interrupted windup never commits its attack", committed_attacks.size(), 0)
	fixture.queue_free()
	await process_frame

func _test_custodian_live_dps_ttk_crosses_all_phases() -> void:
	var fixture := Node3D.new()
	fixture.name = "BossTtkFixture"
	root.add_child(fixture)
	var boss = _new_custodian_fixture(fixture, _seeded_rng(75))
	await process_frame

	var phases_seen: Array[int] = [boss.boss_brain.current_phase()]
	var add_wave_batches: Array[Array] = []
	boss.add_wave_requested.connect(func(requests: Array[Dictionary]) -> void:
		add_wave_batches.append(requests.duplicate(true))
	)

	var elapsed := 0.0
	var dt := 0.10
	while is_instance_valid(boss) and not boss.is_dead() and elapsed < 90.0:
		boss.take_damage(DPS_MODEL * dt)
		var phase: int = int(boss.boss_brain.current_phase())
		if not phases_seen.has(phase):
			phases_seen.append(phase)
		elapsed += dt
		await process_frame

	_check("live Custodian dies under the continuous 110-DPS model", boss.is_dead())
	_check_between("live Custodian TTK under 110 DPS stays in the boss band", elapsed, 10.0, 60.0)
	_check_eq("continuous DPS crosses every Custodian phase", phases_seen, [1, 2, 3, 4])
	_check_eq("continuous DPS fires each add-wave threshold once", add_wave_batches.size(), 3)
	fixture.queue_free()
	await process_frame

func _test_custodian_contact_suppression_and_ledger_invariants() -> void:
	var fixture := Node3D.new()
	fixture.name = "BossContactFixture"
	root.add_child(fixture)
	var boss = _new_custodian_fixture(fixture, _seeded_rng(75))
	var player := CharacterBody3D.new()
	player.name = "PlayerProbe"
	fixture.add_child(player)
	player.global_position = Vector3(0.4, 0.1, 0.0)
	await process_frame

	var damage_events: Array[Dictionary] = []
	var death_events: Array[String] = []
	boss.damage_event.connect(func(event: Dictionary) -> void:
		damage_events.append(event.duplicate(true))
	)
	boss.died.connect(func(spawn_id: String) -> void:
		death_events.append(spawn_id)
	)

	_check_almost("Custodian pins boss-scale max HP", boss.max_hp, BOSS_HP)
	boss.set_chase_target(player)
	for _i in range(40):
		boss.tick_chase(player.global_position, 0.10)
	_check_eq("Custodian contact chase deals zero damage events", damage_events.size(), 0)

	boss.take_damage(BOSS_HP * 2.0)
	boss.take_damage(BOSS_HP * 2.0)
	_check_eq("Custodian died(spawn_id) reaches the ledger exactly once", death_events, ["boss:custodian"])
	fixture.queue_free()
	await process_frame

func _test_custodian_is_snapshot_damageable_enemy() -> void:
	var boss = CustodianBossScript.new()
	var pivot := Node3D.new()
	pivot.name = "VisualPivot"
	boss.add_child(pivot)
	root.add_child(boss)
	await process_frame
	boss.configure_boss("boss:custodian", _seeded_rng(75))

	var damage_events: Array[Array] = []
	var death_events: Array[String] = []
	boss.damage_taken.connect(func(spawn_id: String, amount: float, charges_spark: bool) -> void:
		damage_events.append([spawn_id, amount, charges_spark])
	)
	boss.died.connect(func(spawn_id: String) -> void:
		death_events.append(spawn_id)
	)

	_check("Custodian extends GreyboxEnemy for the combat snapshot seam", boss is GreyboxEnemy)
	_check_eq("Custodian spawn_id is ledger-compatible", boss.spawn_id, "boss:custodian")
	_check_almost("Custodian starts at 2400 HP", boss.max_hp, BOSS_HP)
	_check("Custodian has no spawn windup immunity", not boss.is_spawning())
	boss.take_damage(18.0)
	_check_eq("Custodian damage uses normal damage_taken signal", damage_events.size(), 1)
	_check_eq("Custodian damage_taken reports the boss spawn_id", damage_events[0][0], "boss:custodian")
	_check_almost("Custodian HP drops from player damage", boss.hp, BOSS_HP - 18.0)
	boss.take_damage(BOSS_HP)
	_check_eq("Custodian death reports through died(spawn_id)", death_events, ["boss:custodian"])
	boss.queue_free()
	await process_frame

func _test_boss_arena_uses_custodian_model() -> void:
	var arena := BossArenaScene.instantiate()
	root.add_child(arena)
	await process_frame
	var boss := arena.get_node_or_null("CustodianBoss") as CharacterBody3D
	var pivot := boss.get_node_or_null("VisualPivot") as Node3D if boss != null else null
	var model := pivot.get_node_or_null("CustodianBossModel") as Node3D if pivot != null else null
	var placeholder := pivot.get_node_or_null("Body") as MeshInstance3D if pivot != null else null

	_check("boss arena keeps CustodianBoss body", boss != null)
	_check("boss arena keeps CustodianBoss collision", boss != null and boss.get_node_or_null("CollisionShape3D") is CollisionShape3D)
	_check("boss arena keeps CustodianBoss group", boss != null and boss.is_in_group("boss"))
	_check("boss arena keeps Custodian nameplate", boss != null and boss.get_node_or_null("Nameplate") is Label3D)
	_check("boss arena instances the Custodian GLB model", model != null)
	_check("boss arena hides or removes the greybox boss placeholder", placeholder == null or not placeholder.visible)
	if model != null:
		_check_between("Custodian model reads big at roughly 3-4x player scale", model.scale.y, 3.0, 4.25)
		_check("Custodian model exposes a MeshInstance3D for combat effects", _first_mesh_under(model) != null)
	arena.queue_free()
	await process_frame

func _test_custodian_visual_presides_over_the_arena() -> void:
	# Presiding, not walking: slow levitation, no gait bob tied to speed,
	# no flinch — and the boss script keeps ownership of pivot yaw.
	var arena := BossArenaScene.instantiate()
	root.add_child(arena)
	await process_frame
	var boss := arena.get_node_or_null("CustodianBoss") as CharacterBody3D
	var pivot := boss.get_node_or_null("VisualPivot") as Node3D if boss != null else null
	var model := pivot.get_node_or_null("CustodianBossModel") as Node3D if pivot != null else null
	_check("custodian pivot carries the presiding visual script", pivot != null and pivot.has_method("update_motion"))
	if pivot == null or model == null or not pivot.has_method("update_motion"):
		arena.queue_free()
		await process_frame
		return

	var base_y: float = model.position.y
	var min_y := base_y
	var max_y := base_y
	for i in range(20):
		pivot.call("update_motion", 0.1)
		min_y = minf(min_y, model.position.y)
		max_y = maxf(max_y, model.position.y)
	_check("custodian levitates on a slow cycle", max_y - min_y > 0.05)
	_check("custodian levitation stays stately, never a stomp", max_y - min_y < 0.35)
	_check("custodian survey sway never usurps pivot yaw", absf(model.rotation.y) <= 0.05)

	boss.velocity = Vector3(4.0, 0.0, 0.0)
	for i in range(10):
		pivot.call("update_motion", 0.05)
	_check("custodian inclines faintly while repositioning", model.rotation.x > 0.02)
	boss.velocity = Vector3.ZERO

	arena.queue_free()
	await process_frame

func _test_custodian_windup_presence_and_death_powerdown() -> void:
	# Attack telegraph at boss scale: during brain windup the survey freezes
	# and the monolith rises + leans in. Death is a glacial power-down sink.
	# Both are cosmetic reads of boss_brain/is_dead — no gameplay writes.
	var arena := BossArenaScene.instantiate()
	root.add_child(arena)
	await process_frame
	var boss := arena.get_node_or_null("CustodianBoss") as CharacterBody3D
	var pivot := boss.get_node_or_null("VisualPivot") as Node3D if boss != null else null
	var model := pivot.get_node_or_null("CustodianBossModel") as Node3D if pivot != null else null
	if pivot == null or model == null or not pivot.has_method("update_motion"):
		_check("presence fixture has pivot + model + motion API", false)
		arena.queue_free()
		await process_frame
		return

	# Settle a calm baseline, then arm the windup read. The presence rise
	# (0.24) is compared against the rest height with the levitation sine
	# nearly zero-crossed at the sampled tick, so the check is deterministic.
	for i in range(30):
		pivot.call("update_motion", 0.05)
	var rest_y: float = float(pivot.get("_base_position").y)

	boss.boss_brain._state = "windup"
	for i in range(60):
		pivot.call("update_motion", 0.05)
	_check(
		"custodian rises with presence during windup",
		model.position.y > rest_y + 0.15
	)
	_check("custodian survey freezes during windup (locked attention)", absf(model.rotation.y) < 0.01)
	_check("custodian leans in during windup", model.rotation.x > 0.05)
	boss.boss_brain._state = "idle"

	var base_y: float = float(pivot.get("_base_position").y)
	boss.take_damage(9999999.0, false)
	for i in range(40):
		pivot.call("update_motion", 0.05)
	_check("dead custodian powers down and sinks", model.position.y < base_y - 0.3)
	_check("dead custodian settles into the fallen pitch", model.rotation.x > 0.05)

	arena.queue_free()
	await process_frame

func _new_custodian_fixture(parent: Node, rng: RandomNumberGenerator):
	var boss = CustodianBossScript.new()
	boss.name = "CustodianBoss"
	var pivot := Node3D.new()
	pivot.name = "VisualPivot"
	boss.add_child(pivot)
	var label := Label3D.new()
	label.name = "Nameplate"
	boss.add_child(label)
	parent.add_child(boss)
	boss.configure_boss("boss:custodian", rng)
	boss.global_position = Vector3.ZERO
	return boss

func _telegraph_markers_under(parent: Node) -> Array:
	var markers: Array = []
	_collect_telegraph_markers(parent, markers)
	return markers

func _collect_telegraph_markers(node: Node, markers: Array) -> void:
	if node != null and node.get_script() == TelegraphMarkerScript and not node.is_queued_for_deletion():
		markers.append(node)
	for child in node.get_children():
		_collect_telegraph_markers(child, markers)

func _new_brain(seed: int):
	var brain = BossBrainScript.new()
	brain.configure({
		"rng": _seeded_rng(seed),
		"max_hp": BOSS_HP,
	})
	return brain

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _selection_sequence(brain, count: int) -> Array[String]:
	var result: Array[String] = []
	for _i in range(count):
		var attack: Dictionary = brain.begin_next_attack()
		if attack.is_empty():
			brain.tick(0.25)
			continue
		result.append(String(attack.get("id", "")))
		brain.force_finish_current_attack()
		brain.tick(10.0)
	return result

func _unique_count(values: Array[String]) -> int:
	var seen: Dictionary = {}
	for value in values:
		seen[value] = true
	return seen.size()

func _first_mesh_under(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh_under(child)
		if found != null:
			return found
	return null

func _assert_requests_eq(desc: String, actual: Array, expected: Array) -> void:
	_check_eq(desc, _normalize_requests(actual), _normalize_requests(expected))

func _normalize_requests(requests: Array) -> Array:
	var normalized: Array = []
	for request in requests:
		var item: Dictionary = (request as Dictionary).duplicate(true)
		if item.has("spawn_ids"):
			var spawn_ids: Array = item["spawn_ids"]
			spawn_ids.sort()
			item["spawn_ids"] = spawn_ids
		normalized.append(item)
	normalized.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("archetype", "")) < String(b.get("archetype", ""))
	)
	return normalized

func _audio_event_count(event: StringName) -> int:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return 0
	var desc: Dictionary = director.describe()
	var counts: Dictionary = desc.get("sfx_event_counts", {})
	return int(counts.get(String(event), 0))
