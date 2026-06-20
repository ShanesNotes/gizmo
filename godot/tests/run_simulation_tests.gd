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
	_test_run_completes()
	_test_damage_and_iframes()
	_test_damage_zero_and_negative()
	_test_negative_dt_does_not_rewind()
	_test_death_is_gameover()
	_test_hp_progress()
	# Enemies (0008)
	_test_enemy_spawns_on_cadence()
	_test_enemy_chases_gizmo()
	_test_enemy_contact_damages_player()
	_test_no_spawning_after_run_over()
	_test_contact_grace()
	_test_enemies_separate()
	_test_enemy_cap()
	# Combat & pickups (0009)
	_test_autofire_damages_enemy()
	_test_autofire_range_includes_radius()
	_test_enemy_dies_and_drops_spark()
	_test_collecting_spark_grants_xp()
	_test_sparks_drive_leveling()
	print("")
	if _failed == 0:
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

func _test_run_completes() -> void:
	var sim := Sim.new()
	sim.run_duration = 0.08
	sim.tick(0.05)
	_check_eq("still playing mid-run", sim.phase, Sim.PHASE_PLAYING)
	sim.tick(0.05)  # elapsed 0.10 >= 0.08
	_check_eq("run completes (a win) when the timer elapses", sim.phase, Sim.PHASE_COMPLETE)
	var before := sim.elapsed
	sim.tick(0.05)
	_check("tick is a no-op once the run is over", sim.elapsed == before)

func _test_damage_and_iframes() -> void:
	var sim := Sim.new()  # hp 7, invulnerable 0
	sim.spawn_interval = 9999.0  # isolate from enemy contact while we tick
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

# --- Enemies (0008) ---

func _test_enemy_spawns_on_cadence() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.2
	_check_eq("no enemies at the start", sim.enemies.size(), 0)
	for i in 4:
		sim.tick(0.05, Vector3.ZERO)  # 4 * 0.05 = 0.20s -> one spawn
	_check_eq("one enemy after one interval", sim.enemies.size(), 1)
	for i in 4:
		sim.tick(0.05, Vector3.ZERO)
	_check_eq("two enemies after two intervals", sim.enemies.size(), 2)

func _test_enemy_chases_gizmo() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	var target := Vector3(5.0, 0.0, 0.0)
	sim.tick(0.05, target)  # spawns one nibbler on the ring around the target
	var e := sim.enemies[0]
	var before := e.position.distance_to(target)
	sim.tick(0.05, target)
	var after := e.position.distance_to(target)
	_check("enemy moves toward Gizmo", after < before)

func _test_enemy_contact_damages_player() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	sim.attack_cooldown = 9999.0  # isolate: don't let the weapon kill the enemy first
	sim.elapsed = 8.0  # past the 7s contact grace (simulation.ts:722)
	sim.tick(0.05, Vector3.ZERO)  # spawn one enemy on the ring
	var e := sim.enemies[0]
	var hp_before := sim.hp
	sim.tick(0.05, e.position)  # put Gizmo on the enemy -> contact
	_check_eq("contact costs the player 1 hp", sim.hp, hp_before - 1)
	sim.tick(0.05, e.position)  # immediately again -> blocked by i-frames
	_check_eq("contact respects i-frames", sim.hp, hp_before - 1)

func _test_no_spawning_after_run_over() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	sim.take_damage(100)  # -> gameover
	for i in 10:
		sim.tick(0.05, Vector3.ZERO)
	_check_eq("a dead player spawns no enemies", sim.enemies.size(), 0)

func _test_contact_grace() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	sim.attack_cooldown = 9999.0  # isolate from the weapon
	sim.tick(0.05, Vector3.ZERO)  # elapsed ~0.05, before the grace; spawn an enemy
	var e := sim.enemies[0]
	sim.tick(0.05, e.position)  # Gizmo on the enemy, but before 7s -> no damage
	_check_eq("no contact damage before the 7s grace", sim.hp, 7)
	sim.elapsed = 8.0
	sim.tick(0.05, e.position)  # past the grace -> contact lands
	_check("contact damages after the grace", sim.hp < 7)

func _test_enemies_separate() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	sim.tick(0.05, Vector3.ZERO)
	sim.tick(0.05, Vector3.ZERO)  # two enemies
	sim.enemies[0].position = Vector3.ZERO
	sim.enemies[1].position = Vector3(0.3, 0.0, 0.0)  # overlapping (radii sum to 2.0)
	var before := sim.enemies[0].position.distance_to(sim.enemies[1].position)
	sim._separate_enemies()
	var after := sim.enemies[0].position.distance_to(sim.enemies[1].position)
	_check("overlapping enemies push apart", after > before)

func _test_enemy_cap() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 0.05
	sim.attack_cooldown = 9999.0  # isolate: the weapon would otherwise thin the cap
	sim.max_enemies = 3
	for i in 60:
		sim.tick(0.05, Vector3.ZERO)  # 3.0s, before the grace -> no deaths
	_check_eq("spawning stops at the cap", sim.enemies.size(), 3)

# --- Combat & pickups (0009) ---

func _test_autofire_damages_enemy() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 9999.0   # no auto-spawn; we place the enemy
	sim.attack_cooldown = 0.05    # fire on the first tick
	var e := Sim.Enemy.new()
	e.position = Vector3(2.0, 0.0, 0.0)  # within attack_range (6)
	e.hp = 5.0
	e.radius = 1.0
	sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)
	_check("auto-fire damages the nearest enemy", e.hp < 5.0)

func _test_autofire_range_includes_radius() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 9999.0
	sim.attack_cooldown = 0.05
	# centre at 6.5m, radius 1.0 -> body within range+radius (7.0); should be hit
	var near := Sim.Enemy.new()
	near.position = Vector3(6.5, 0.0, 0.0)
	near.hp = 5.0
	near.radius = 1.0
	sim.enemies.append(near)
	var far := Sim.Enemy.new()
	far.position = Vector3(20.0, 0.0, 0.0)  # well out of reach
	far.hp = 5.0
	far.radius = 1.0
	sim.enemies.append(far)
	sim.tick(0.05, Vector3.ZERO)
	_check("an enemy within range+radius is hit", near.hp < 5.0)
	_check("an out-of-range enemy is untouched", far.hp == 5.0)

func _test_enemy_dies_and_drops_spark() -> void:
	var sim := Sim.new()
	sim.spawn_interval = 9999.0
	sim.attack_cooldown = 0.05
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
	sim.spawn_interval = 9999.0
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
	sim.spawn_interval = 9999.0
	for i in 10:                     # 10 Sparks * 10 = 100 xp > level-1 threshold (92)
		var p := Sim.Pickup.new()
		p.position = Vector3.ZERO
		p.value = 10
		sim.pickups.append(p)
	sim.tick(0.05, Vector3.ZERO)
	_check_eq("collecting enough Sparks levels Gizmo up", sim.level, 2)
