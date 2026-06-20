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
