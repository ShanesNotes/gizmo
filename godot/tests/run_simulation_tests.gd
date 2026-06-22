extends SceneTree

# Tiny dependency-free test runner for the ported game logic. Run with:
#   godot --headless --path godot --script res://tests/run_simulation_tests.gd
# Exits 0 if all pass, 1 if any fail (so CI / the terminal can tell).

var _passed := 0
var _failed := 0

# Load by path so this runner works headless without an editor import step
# (a raw --script run doesn't refresh the global class_name cache).
const Sim := preload("res://scripts/simulation.gd")

func _initialize() -> void:
	print("Running simulation tests…")
	# Sparks & leveling (0006)
	_test_next_xp_vectors()
	_test_xp_below_threshold()
	_test_level_up_carries_remainder()
	_test_xp_progress()
	_test_negative_ignored()
	# Run clock & health (0007)
	_test_run_clock()
	_test_dt_is_clamped()
	_test_timer_no_longer_wins()
	_test_damage_and_iframes()
	_test_damage_zero_and_negative()
	_test_negative_dt_does_not_rewind()
	_test_death_is_gameover()
	_test_hp_progress()
	# Enemies (0008)
	_test_enemy_chases_gizmo()
	_test_enemy_contact_damages_player()
	_test_no_spawning_after_run_over()
	_test_contact_grace()
	_test_enemies_separate()
	# Static arena obstacles (0014)
	_test_enemy_pushed_out_of_obstacle()
	_test_enemy_does_not_tunnel_into_obstacle()
	# Pressure director (0010)
	_test_pressure_curve_ramps()
	_test_director_ramps_spawn_rate()
	_test_director_respects_cap()
	_test_no_spawn_when_disabled()
	# Combat & pickups (0009)
	_test_autofire_damages_enemy()
	_test_autofire_range_includes_radius()
	_test_enemy_dies_and_drops_spark()
	_test_collecting_spark_grants_xp()
	_test_sparks_drive_leveling()
	# Combat hardening & events (0009 review)
	_test_dead_enemy_is_not_targeted()
	_test_nearest_of_two_is_targeted()
	_test_pickup_cap_holds()
	_test_combat_events_emitted()
	_test_pickup_and_levelup_events_emitted()
	_test_events_are_snapshot_safe()
	# Beacon rekindle channel (0017) — Dormant→Rekindling→Rekindled, in isolation
	_test_beacon_inert_by_default()
	_test_beacon_entry_is_never_instant()
	_test_beacon_fills_to_rekindled_while_held()
	_test_beacon_pauses_outside_and_is_one_way()
	_test_beacon_resumes_after_returning()
	_test_rekindled_beacon_does_not_win_yet()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL — %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - ", desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s (got %s, expected %s)" % [desc, actual, expected])

# True if last_events carries an event of the given "type".
func _has_event(events: Array, type: String) -> bool:
	for e in events:
		if e.get("type") == type:
			return true
	return false

# --- Sparks & leveling (0006) ---

# Exact vectors pin the formula faithfully (simulation.ts:1721-1725).
func _test_next_xp_vectors() -> void:
	_check_eq("next_xp lvl 1", Sim.next_xp_for_level(1), 92)
	_check_eq("next_xp lvl 2", Sim.next_xp_for_level(2), 188)
	_check_eq("next_xp lvl 3", Sim.next_xp_for_level(3), 291)
	_check_eq("next_xp lvl 5", Sim.next_xp_for_level(5), 595)
	_check_eq("next_xp lvl 10", Sim.next_xp_for_level(10), 1811)

func _test_xp_below_threshold() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(10)
	_check("a few Sparks do not level you", not leveled)
	_check_eq("still level 1", sim.level, 1)
	_check_eq("Sparks banked", sim.xp, 10)

func _test_level_up_carries_remainder() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(100)  # level-1 threshold is 92
	_check("crossing the threshold levels up", leveled)
	_check_eq("now level 2", sim.level, 2)
	_check_eq("remainder carries (100 - 92)", sim.xp, 8)
	_check_eq("next threshold is level 2's", sim.next_xp, Sim.next_xp_for_level(2))

func _test_xp_progress() -> void:
	var sim := Sim.new()
	sim.add_xp(46)  # ~half of 92
	_check("Sparks bar reads ~half full", absf(sim.xp_progress() - 0.5) < 0.05)

func _test_negative_ignored() -> void:
	var sim := Sim.new()
	sim.add_xp(-5)  # pickups are never negative; guard against it
	_check_eq("negative Sparks are ignored", sim.xp, 0)

# --- Run clock & health (0007) ---

func _test_run_clock() -> void:
	var sim := Sim.new()
	sim.run_duration = 1.0
	for i in 5:
		sim.tick(0.05)  # 5 * 0.05 = 0.25s elapsed
	_check("run_progress ~ 0.25", absf(sim.run_progress() - 0.25) < 0.001)
	_check("time_remaining ~ 0.75", absf(sim.time_remaining() - 0.75) < 0.001)

func _test_dt_is_clamped() -> void:
	var sim := Sim.new()
	sim.tick(10.0)  # a huge frame must not skip the whole run
	_check("dt clamped to 0.05", absf(sim.elapsed - 0.05) < 0.0001)

func _test_timer_no_longer_wins() -> void:
	# Path A (ADR 0005): the clock no longer ends the run. Crossing run_duration
	# keeps the run PLAYING — the Beacon channel (lesson 0018) becomes the win.
	var sim := Sim.new()
	sim.run_duration = 0.08
	sim.tick(0.05)
	_check_eq("still playing mid-run", sim.phase, Sim.PHASE_PLAYING)
	sim.tick(0.05)  # elapsed 0.10 >= run_duration — old deadline crossed
	_check_eq("clock elapsing no longer completes the run", sim.phase, Sim.PHASE_PLAYING)
	sim.tick(0.05)
	_check("the run keeps ticking past the old deadline", sim.phase == Sim.PHASE_PLAYING)

func _test_damage_and_iframes() -> void:
	var sim := Sim.new()  # hp 7, invulnerable 0
	sim.spawn_enabled = false  # isolate from enemy contact while we tick
	var landed := sim.take_damage(2)
	_check("first hit lands", landed)
	_check_eq("hp drops by the damage", sim.hp, 5)
	var blocked := sim.take_damage(2)
	_check("i-frames block the next hit", not blocked and sim.hp == 5)
	sim.run_duration = 999.0  # don't let the run complete while we wait out i-frames
	for i in 40:
		sim.tick(0.05)  # 2.0s > 1.58 i-frame window
	sim.take_damage(2)
	_check_eq("damage lands again after i-frames", sim.hp, 3)

func _test_death_is_gameover() -> void:
	var sim := Sim.new()
	sim.take_damage(100)
	_check_eq("hp floors at 0", sim.hp, 0)
	_check_eq("reaching 0 hp is a gameover (lose)", sim.phase, Sim.PHASE_GAMEOVER)
	var landed := sim.take_damage(1)
	_check("no damage applies once the run is over", not landed)

func _test_damage_zero_and_negative() -> void:
	var sim := Sim.new()
	var z := sim.take_damage(0)
	_check("zero damage is a no-op (no free i-frames)", not z and sim.hp == 7 and sim.invulnerable == 0.0)
	var n := sim.take_damage(-5)
	_check("negative damage is a no-op", not n and sim.hp == 7 and sim.invulnerable == 0.0)

func _test_negative_dt_does_not_rewind() -> void:
	var sim := Sim.new()
	sim.tick(0.05)
	sim.tick(-1.0)  # a negative frame must not rewind the clock
	_check("negative dt cannot rewind the clock", absf(sim.elapsed - 0.05) < 0.0001)

func _test_hp_progress() -> void:
	var sim := Sim.new()
	_check("full hp bar reads 1.0", absf(sim.hp_progress() - 1.0) < 0.001)
	sim.take_damage(2)  # 5 / 7
	_check("hp bar reads 5/7 after a hit", absf(sim.hp_progress() - 5.0 / 7.0) < 0.001)

# --- Enemies (0008) — placed by hand with the director off (spawn_enabled = false) ---

func _test_enemy_chases_gizmo() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	var target := Vector3(5.0, 0.0, 0.0)
	sim._spawn_nibbler(target)  # one nibbler on the ring around the target
	var e := sim.enemies[0]
	var before := e.position.distance_to(target)
	sim.tick(0.05, target)
	var after := e.position.distance_to(target)
	_check("enemy moves toward Gizmo", after < before)

func _test_enemy_contact_damages_player() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 9999.0  # isolate: don't let the weapon kill the enemy first
	sim.elapsed = 8.0  # past the 7s contact grace (simulation.ts:722)
	sim._spawn_nibbler(Vector3.ZERO)
	var e := sim.enemies[0]
	var hp_before := sim.hp
	sim.tick(0.05, e.position)  # put Gizmo on the enemy -> contact
	_check_eq("contact costs the player 1 hp", sim.hp, hp_before - 1)
	sim.tick(0.05, e.position)  # immediately again -> blocked by i-frames
	_check_eq("contact respects i-frames", sim.hp, hp_before - 1)

func _test_no_spawning_after_run_over() -> void:
	var sim := Sim.new()
	sim.take_damage(100)  # -> gameover; tick() returns early, so the director never runs
	for i in 10:
		sim.tick(0.05, Vector3.ZERO)
	_check_eq("a dead player spawns no enemies", sim.enemies.size(), 0)

func _test_contact_grace() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 9999.0  # isolate from the weapon
	sim._spawn_nibbler(Vector3.ZERO)
	var e := sim.enemies[0]
	sim.tick(0.05, e.position)  # Gizmo on the enemy, but before 7s -> no damage
	_check_eq("no contact damage before the 7s grace", sim.hp, 7)
	sim.elapsed = 8.0
	sim.tick(0.05, e.position)  # past the grace -> contact lands
	_check("contact damages after the grace", sim.hp < 7)

func _test_enemies_separate() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim._spawn_nibbler(Vector3.ZERO)
	sim._spawn_nibbler(Vector3.ZERO)  # two enemies
	sim.enemies[0].position = Vector3.ZERO
	sim.enemies[1].position = Vector3(0.3, 0.0, 0.0)  # overlapping (radii sum to 2.0)
	var before := sim.enemies[0].position.distance_to(sim.enemies[1].position)
	sim._separate_enemies()
	var after := sim.enemies[0].position.distance_to(sim.enemies[1].position)
	_check("overlapping enemies push apart", after > before)

# --- Static arena obstacles (0014) — circle push-out vs fixed arena geometry ---

func _test_enemy_pushed_out_of_obstacle() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.add_obstacle(Vector3.ZERO, 3.0)               # a pillar, radius 3, at the origin
	sim._spawn_nibbler(Vector3.ZERO)
	sim.enemies[0].position = Vector3(0.5, 0.0, 0.0)  # standing inside the pillar
	sim._resolve_obstacles()
	var d := sim.enemies[0].position.distance_to(Vector3.ZERO)
	_check("enemy is pushed to the pillar's edge", d >= 3.0 + sim.enemies[0].radius - 0.001)

func _test_enemy_does_not_tunnel_into_obstacle() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_damage = 0                             # weapon off: isolate movement so the enemy survives the window
	sim.add_obstacle(Vector3.ZERO, 3.0)
	sim._spawn_nibbler(Vector3(0.6, 0.0, 6.0))        # north of the pillar, slightly off-axis
	var edge := 3.0 + sim.enemies[0].radius
	var min_clearance := INF
	for i in 240:                                     # 12s seeking straight at Gizmo on the far side
		sim.tick(0.05, Vector3(0.0, 0.0, -6.0))
		min_clearance = minf(min_clearance, sim.enemies[0].position.distance_to(Vector3.ZERO))
	_check("a seeking enemy never tunnels into the pillar", min_clearance >= edge - 0.05)

# --- Pressure director (0010) — time-ramped enemy spawning ---

func _test_pressure_curve_ramps() -> void:
	var sim := Sim.new()
	sim.elapsed = 0.0
	_check("pressure starts at zero", absf(sim.pressure()) < 0.001)
	sim.elapsed = sim.run_duration * 0.25
	var quarter := sim.pressure()
	sim.elapsed = sim.run_duration * 0.75
	var late := sim.pressure()
	_check("pressure rises as the run progresses", late > quarter and quarter > 0.0)
	sim.elapsed = sim.run_duration
	_check("time-only pressure reaches 1.0 by the run's end", absf(sim.pressure() - 1.0) < 0.001)

func _test_director_ramps_spawn_rate() -> void:
	# Same one-second window, low pressure vs high pressure -> more spawns under pressure.
	# attack_cooldown huge so we count spawns, not survivors.
	var early := Sim.new()
	early.attack_cooldown = 9999.0
	early.elapsed = 0.0
	for i in 20:
		early.tick(0.05, Vector3.ZERO)
	var late := Sim.new()
	late.attack_cooldown = 9999.0
	late.elapsed = 180.0   # pressure ~0.96
	for i in 20:
		late.tick(0.05, Vector3.ZERO)
	_check("the director spawns faster under high pressure", late.enemies.size() > early.enemies.size())
	_check("high pressure produces a real burst", late.enemies.size() >= 3)

func _test_director_respects_cap() -> void:
	var sim := Sim.new()
	sim.attack_cooldown = 9999.0   # isolate: the weapon would otherwise thin the cap
	sim.hp = 9999                  # isolate: contact must not end the run mid-test
	sim.max_enemies = 5
	sim.elapsed = 200.0            # very high pressure -> the director wants far more than 5
	for i in 60:
		sim.tick(0.05, Vector3.ZERO)
	_check_eq("the director never exceeds the enemy cap", sim.enemies.size(), 5)

func _test_no_spawn_when_disabled() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.elapsed = 200.0            # high pressure, but the director is off
	for i in 20:
		sim.tick(0.05, Vector3.ZERO)
	_check_eq("no enemies spawn when the director is disabled", sim.enemies.size(), 0)

# --- Combat & pickups (0009) ---

func _test_autofire_damages_enemy() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false   # no auto-spawn; we place the enemy
	sim.attack_cooldown = 0.05    # fire on the first tick
	var e := Sim.Enemy.new()
	e.position = Vector3(sim.attack_range * 0.4, 0.0, 0.0)
	e.hp = 5.0
	e.radius = 1.0
	sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)
	_check("auto-fire damages the nearest enemy", e.hp < 5.0)

func _test_autofire_range_includes_radius() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	var near := Sim.Enemy.new()
	near.hp = 5.0
	near.radius = 1.0
	# Place the center just outside pure range but inside range + body radius.
	near.position = Vector3(sim.attack_range + near.radius - 0.1, 0.0, 0.0)
	sim.enemies.append(near)
	var far := Sim.Enemy.new()
	far.hp = 5.0
	far.radius = 1.0
	far.position = Vector3(sim.attack_range + far.radius + 5.0, 0.0, 0.0)
	sim.enemies.append(far)
	sim.tick(0.05, Vector3.ZERO)
	_check("an enemy within range+radius is hit", near.hp < 5.0)
	_check("an out-of-range enemy is untouched", far.hp == 5.0)

func _test_enemy_dies_and_drops_spark() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	sim.pickup_radius = 0.0       # isolate: the dropped Spark must not be auto-collected
	var e := Sim.Enemy.new()
	e.position = Vector3(2.0, 0.0, 0.0)
	e.hp = 1.0            # one shot kills (attack_damage 1)
	e.radius = 1.0
	e.xp_value = Sim.NIBBLER_XP
	sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("a killed enemy is removed", sim.enemies.size(), 0)
	_check_eq("death drops one Spark", sim.pickups.size(), 1)
	_check_eq("the Spark is worth the enemy's xp", sim.pickups[0].value, Sim.NIBBLER_XP)

func _test_collecting_spark_grants_xp() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	var p := Sim.Pickup.new()
	p.position = Vector3(0.5, 0.0, 0.0)  # within pickup_radius (1.8)
	p.value = 10
	sim.pickups.append(p)
	var xp_before := sim.xp
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("collecting a Spark banks its value", sim.xp, xp_before + 10)
	_check_eq("the collected Spark is removed", sim.pickups.size(), 0)

func _test_sparks_drive_leveling() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	for i in 10:                     # 10 Sparks * 10 = 100 xp > level-1 threshold (92)
		var p := Sim.Pickup.new()
		p.position = Vector3.ZERO
		p.value = 10
		sim.pickups.append(p)
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("collecting enough Sparks levels Gizmo up", sim.level, 2)

# --- Combat hardening & events (0009 review) ---

func _test_dead_enemy_is_not_targeted() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	sim.pickup_radius = 0.0       # isolate from collection
	var corpse := Sim.Enemy.new()
	corpse.position = Vector3(2.0, 0.0, 0.0)  # in range, but already dead
	corpse.hp = 0.0
	corpse.radius = 1.0
	corpse.xp_value = Sim.NIBBLER_XP
	sim.enemies.append(corpse)
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("the weapon ignores a corpse (no Spark)", sim.pickups.size(), 0)
	_check_eq("a corpse grants no XP", sim.xp, 0)

func _test_nearest_of_two_is_targeted() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	var near := Sim.Enemy.new()
	near.position = Vector3(2.0, 0.0, 0.0)  # both in range; this one is nearer
	near.hp = 5.0                            # survives one shot
	near.radius = 1.0
	sim.enemies.append(near)
	var far := Sim.Enemy.new()
	far.position = Vector3(5.0, 0.0, 0.0)
	far.hp = 5.0
	far.radius = 1.0
	sim.enemies.append(far)
	sim.tick(0.05, Vector3.ZERO)
	_check("the nearer enemy is hit", near.hp < 5.0)
	_check("the farther enemy is spared (one target per shot)", far.hp == 5.0)

func _test_pickup_cap_holds() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.max_pickups = 3
	for i in 5:                                # 5 uncollected Sparks, far from Gizmo
		var p := Sim.Pickup.new()
		p.position = Vector3(100.0, 0.0, 0.0)  # outside pickup_radius -> never collected
		p.value = i                            # 0,1,2,3,4 -> oldest are 0 and 1
		sim.pickups.append(p)
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("uncollected Sparks are capped", sim.pickups.size(), 3)
	_check_eq("the oldest Sparks are dropped first", sim.pickups[0].value, 2)

func _test_combat_events_emitted() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	sim.pickup_radius = 0.0       # isolate combat events from collection
	var e := Sim.Enemy.new()
	e.position = Vector3(2.0, 0.0, 0.0)
	e.hp = 1.0                    # one shot kills
	e.radius = 1.0
	e.xp_value = Sim.NIBBLER_XP
	sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)
	_check("a shot emits an 'attack' event", _has_event(sim.last_events, "attack"))
	_check("a landed shot emits a 'hit' event", _has_event(sim.last_events, "hit"))
	_check("a kill emits a 'defeat' event", _has_event(sim.last_events, "defeat"))

func _test_pickup_and_levelup_events_emitted() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	for i in 10:                     # 10 * 10 = 100 xp > level-1 threshold (92)
		var p := Sim.Pickup.new()
		p.position = Vector3.ZERO     # on Gizmo -> collected this tick
		p.value = 10
		sim.pickups.append(p)
	sim.tick(0.05, Vector3.ZERO)
	_check("collecting a Spark emits a 'pickup' event", _has_event(sim.last_events, "pickup"))
	_check("crossing the threshold emits a 'levelup' event", _has_event(sim.last_events, "levelup"))

# A consumer that stores last_events must keep that frame's snapshot — tick() builds a
# fresh array (not clear-in-place), matching simulation.ts's fresh GameEvent[] per frame.
func _test_events_are_snapshot_safe() -> void:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	sim.pickup_radius = 0.0       # isolate from collection
	var e := Sim.Enemy.new()
	e.position = Vector3(2.0, 0.0, 0.0)
	e.hp = 1.0
	e.radius = 1.0
	e.xp_value = Sim.NIBBLER_XP
	sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)         # produces attack/hit/defeat
	var snapshot := sim.last_events       # a consumer stores the reference
	var snapshot_size := snapshot.size()
	_check("the first tick produced events", snapshot_size > 0)
	sim.tick(0.05, Vector3.ZERO)         # next frame: no enemies left -> no new events
	_check("a stored snapshot is not emptied by the next tick", snapshot.size() == snapshot_size)
	_check("the live events did reset for the new frame", sim.last_events.size() == 0)

# --- Beacon rekindle channel (0017) ---
# Path A (ADR 0005): reaching the beacon radius starts a Dormant→Rekindling→Rekindled
# channel. It's an AREA-HOLD: progress fills while Gizmo is inside the radius, PAUSES
# when he leaves (slow-decay is the agreed later upgrade — 0017 ships PAUSE), and entry
# is never instant. The win (PHASE_COMPLETE) is NOT wired here — that's 0018; this slice
# proves the machine in isolation, so the run stays un-winnable.

# Author a beacon at the origin so a hand-ticked position can be inside/outside it.
func _place_beacon(sim, radius := 3.0) -> void:
	sim.beacon_position = Vector3.ZERO
	sim.beacon_radius = radius

func _tick_inside(sim, seconds: float) -> void:
	var n := int(round(seconds / 0.05))
	for i in n:
		sim.tick(0.05, Vector3.ZERO)          # at the beacon centre — inside

func _tick_outside(sim, seconds: float) -> void:
	var n := int(round(seconds / 0.05))
	for i in n:
		sim.tick(0.05, Vector3(100.0, 0.0, 0.0))  # far away — outside any radius

func _test_beacon_inert_by_default() -> void:
	# No beacon authored (beacon_radius 0) ⇒ the channel never engages. This is the
	# guard that the balance harness (open floor, no beacon) is untouched by 0017.
	var sim := Sim.new()
	_tick_inside(sim, 10.0)
	_check_eq("a sim with no beacon stays Dormant", sim.beacon_state, Sim.BEACON_DORMANT)
	_check("no beacon ⇒ no channel progress", sim.beacon_channel_progress == 0.0)

func _test_beacon_entry_is_never_instant() -> void:
	var sim := Sim.new()
	_place_beacon(sim)
	sim.tick(0.05, Vector3.ZERO)              # a single tick inside the radius
	_check_eq("entering the radius starts Rekindling", sim.beacon_state, Sim.BEACON_REKINDLING)
	_check("one tick inside makes some progress", sim.beacon_channel_progress > 0.0)
	_check("but entry is never an instant win", sim.beacon_channel_progress < 1.0)
	_check_eq("not Rekindled on entry", sim.beacon_state, Sim.BEACON_REKINDLING)

func _test_beacon_fills_to_rekindled_while_held() -> void:
	var sim := Sim.new()
	_place_beacon(sim)
	_tick_inside(sim, Sim.BEACON_CHANNEL_SECONDS + 0.5)  # hold past the channel duration
	_check("holding the radius fills the channel", sim.beacon_channel_progress >= 1.0)
	_check_eq("a full channel reaches Rekindled", sim.beacon_state, Sim.BEACON_REKINDLED)

func _test_beacon_pauses_outside_and_is_one_way() -> void:
	var sim := Sim.new()
	_place_beacon(sim)
	_tick_inside(sim, 3.0)                    # partway up the channel
	var banked := sim.beacon_channel_progress
	_check("partway is between empty and full", banked > 0.0 and banked < 1.0)
	_tick_outside(sim, 4.0)                   # leave the radius
	_check("leaving PAUSES progress (held, not drained)", absf(sim.beacon_channel_progress - banked) < 0.0001)
	_check_eq("leaving never reverts the state (one-way door)", sim.beacon_state, Sim.BEACON_REKINDLING)

func _test_beacon_resumes_after_returning() -> void:
	var sim := Sim.new()
	_place_beacon(sim)
	_tick_inside(sim, 5.0)                    # most of the channel
	_tick_outside(sim, 3.0)                   # step out — banked progress is preserved
	_tick_inside(sim, 4.0)                    # come back and finish
	_check("a paused channel resumes and completes", sim.beacon_channel_progress >= 1.0)
	_check_eq("returning completes to Rekindled", sim.beacon_state, Sim.BEACON_REKINDLED)

func _test_rekindled_beacon_does_not_win_yet() -> void:
	var sim := Sim.new()
	_place_beacon(sim)
	_tick_inside(sim, Sim.BEACON_CHANNEL_SECONDS + 0.5)
	_check_eq("the channel reached Rekindled", sim.beacon_state, Sim.BEACON_REKINDLED)
	_check_eq("but the run is still un-winnable in 0017", sim.phase, Sim.PHASE_PLAYING)
