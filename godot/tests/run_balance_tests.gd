extends SceneTree

# 0013 balance sweep. Run with:
#   godot --headless --path godot --script res://tests/run_balance_tests.gd
# These are deterministic profile proxies, not a claim that the game is "done".
# They pin the v1 prototype curve from reference/game-balance-reference.md:
# - no cheap early deaths and no one-shot contact spikes (§3.4)
# - bruiser TTK band §5.4 (brute/warden 1–3s). Trash TTK sits ~0.70s, ABOVE the
#   strict ≤0.5s "incidental AoE" band — a deliberate v1 tradeoff for the slower
#   single-target auto-fire cadence (0.7s), not AoE clear.
# - pressure vs clear-pressure is measurable (§5.3); bands are deterministic, so
#   tight — a careless retune of speed/range/fire/BUDGET trips a red check.
# - spawn/kill/level telemetry exists for tuning (§6.1, §11.1)
#
# WEAPON PROGRESSION (ADR 0004): Gizmo now STARTS with a rudimentary melee auto-attack;
# the ranged Spark Chain is a later DRAFT. The full-run profiles below explicitly set
# attack_range = ATTACK_RANGE so they keep pinning the (retained, draftable) ranged
# weapon's curve; the new opening tests pin the melee start on the default config.
# Full-run balance UNDER melee-only (no drafts) is intentionally deferred until the
# Core Matrix draft system exists — so it is NOT asserted here.

const Sim := preload("res://scripts/simulation.gd")
const DT := 0.05
const ARENA_HALF_EXTENT := 8.0
const GIZMO_SPEED := 3.6
const DECENT_SENSE_RADIUS := 5.5
const DECENT_REACTION_INTERVAL := 0.2

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running balance tests…")
	# Weapon progression — the melee start (ADR 0004, lesson 0015)
	_test_gizmo_starts_with_rudimentary_melee()
	_test_opening_single_mob_is_a_clean_kill()
	_test_melee_start_makes_standing_still_lethal()
	# Draftable ranged Spark Chain + the 0013 curve (pinned explicitly at ATTACK_RANGE)
	_test_enemy_roles_match_ttk_bands()
	_test_leveling_increases_spark_chain_output()
	_test_pressure_probe_at_60s()
	_test_stationary_profile_is_lethal_but_not_cheap()
	_test_mistake_kite_can_still_lose_naturally()
	_test_decent_kite_survives_the_clock()
	# The Beacon is reachable by fair play (0018)
	_test_seek_and_hold_can_rekindle()
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

func _check_between(desc: String, value: float, low: float, high: float) -> void:
	_check("%s (%0.2f in [%0.2f, %0.2f])" % [desc, value, low, high], value >= low and value <= high)

func _profile_position(profile: String, elapsed: float) -> Vector3:
	match profile:
		"stationary":
			return Vector3.ZERO
		"mistake_kite":
			# Plausible but weak routing: survives long enough to learn, then loses as
			# pressure outgrows circular autopilot movement.
			return Vector3(cos(elapsed * 0.85), 0.0, sin(elapsed * 0.85)) * 3.0
		_:
			return Vector3.ZERO

func _run_fixed_profile(profile: String) -> Dictionary:
	var sim := Sim.new()
	sim.attack_range = Sim.ATTACK_RANGE   # pin the draftable ranged Spark Chain (ADR 0004); the melee start is tested separately
	var first_damage := -1.0
	var damage_events := 0
	var max_hit_delta := 0
	var prev_hp := sim.hp
	var max_alive := 0
	for i in 6000:
		var pos := _profile_position(profile, sim.elapsed)
		sim.tick(DT, pos)
		if sim.hp < prev_hp:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, prev_hp - sim.hp)
			if first_damage < 0.0:
				first_damage = sim.elapsed
			prev_hp = sim.hp
		max_alive = maxi(max_alive, sim.enemies.size())
		if sim.phase != Sim.PHASE_PLAYING:
			break
	return _summary(sim, first_damage, damage_events, max_hit_delta, max_alive)

func _run_decent_kite_profile() -> Dictionary:
	var sim := Sim.new()
	sim.attack_range = Sim.ATTACK_RANGE   # pin the draftable ranged Spark Chain (ADR 0004)
	var pos := Vector3.ZERO
	var dir := Vector3.RIGHT
	var next_reaction := 0.0
	var first_damage := -1.0
	var damage_events := 0
	var max_hit_delta := 0
	var prev_hp := sim.hp
	var max_alive := 0
	for i in 6000:
		if sim.elapsed >= next_reaction:
			dir = _choose_lagged_kite_direction(sim, pos, DECENT_SENSE_RADIUS, dir)
			next_reaction = sim.elapsed + DECENT_REACTION_INTERVAL
		var movement := _move_in_arena(pos, dir, GIZMO_SPEED)
		pos = movement["position"]
		dir = movement["direction"]
		sim.tick(DT, pos)
		if sim.hp < prev_hp:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, prev_hp - sim.hp)
			if first_damage < 0.0:
				first_damage = sim.elapsed
			prev_hp = sim.hp
		max_alive = maxi(max_alive, sim.enemies.size())
		if sim.phase != Sim.PHASE_PLAYING:
			break
	return _summary(sim, first_damage, damage_events, max_hit_delta, max_alive)

# 0018: a seek-and-hold driver. Unlike the decent kite (pure evasion — it steers AWAY
# from enemies and so never approaches an objective), this walks to the Beacon and HOLDS
# its radius to rekindle it. It proves the new win is reachable by fair play. The hold
# lands early (low pressure), so this is a REACHABILITY proof, not a climax — making the
# rekindle a real siege under peak pressure is 0023 (Rekindling overrides exposure).
const SEEK_BEACON := Vector3(0.0, 0.0, 5.0)
const SEEK_BEACON_RADIUS := 3.0

func _run_seek_and_hold_profile() -> Dictionary:
	var sim := Sim.new()
	sim.attack_range = Sim.ATTACK_RANGE        # the draftable ranged Spark Chain (ADR 0004)
	sim.beacon_position = SEEK_BEACON
	sim.beacon_radius = SEEK_BEACON_RADIUS
	var pos := Vector3.ZERO
	var first_damage := -1.0
	var damage_events := 0
	var max_hit_delta := 0
	var prev_hp := sim.hp
	var max_alive := 0
	for i in 6000:
		var to_beacon := SEEK_BEACON - pos
		to_beacon.y = 0.0
		if to_beacon.length() > 0.4:           # seek the centre, then hold there
			pos += to_beacon.normalized() * GIZMO_SPEED * DT
		sim.tick(DT, pos)
		if sim.hp < prev_hp:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, prev_hp - sim.hp)
			if first_damage < 0.0:
				first_damage = sim.elapsed
			prev_hp = sim.hp
		max_alive = maxi(max_alive, sim.enemies.size())
		if sim.phase != Sim.PHASE_PLAYING:
			break
	return _summary(sim, first_damage, damage_events, max_hit_delta, max_alive)

func _choose_lagged_kite_direction(sim: Sim, pos: Vector3, sense_radius: float, fallback: Vector3) -> Vector3:
	var danger := Vector3.ZERO
	for e in sim.enemies:
		var away: Vector3 = pos - e.position
		away.y = 0.0
		var dist := away.length()
		if dist > 0.05 and dist <= sense_radius:
			danger += away / maxf(dist * dist, 0.1)
	if danger.length() > 0.001:
		var dir := danger.normalized()
		var margin := 2.0
		if pos.x > ARENA_HALF_EXTENT - margin:
			dir.x -= 1.2
		if pos.x < -ARENA_HALF_EXTENT + margin:
			dir.x += 1.2
		if pos.z > ARENA_HALF_EXTENT - margin:
			dir.z -= 1.2
		if pos.z < -ARENA_HALF_EXTENT + margin:
			dir.z += 1.2
		return dir.normalized()
	return fallback.normalized() if fallback.length() > 0.001 else Vector3.RIGHT

func _move_in_arena(pos: Vector3, dir: Vector3, speed: float) -> Dictionary:
	var next_dir := dir.normalized() if dir.length() > 0.001 else Vector3.RIGHT
	var next := pos + next_dir * speed * DT
	if next.x > ARENA_HALF_EXTENT:
		next.x = ARENA_HALF_EXTENT
		next_dir.x = -absf(next_dir.x)
	elif next.x < -ARENA_HALF_EXTENT:
		next.x = -ARENA_HALF_EXTENT
		next_dir.x = absf(next_dir.x)
	if next.z > ARENA_HALF_EXTENT:
		next.z = ARENA_HALF_EXTENT
		next_dir.z = -absf(next_dir.z)
	elif next.z < -ARENA_HALF_EXTENT:
		next.z = -ARENA_HALF_EXTENT
		next_dir.z = absf(next_dir.z)
	return {"position": next, "direction": next_dir.normalized()}

func _summary(sim: Sim, first_damage: float, damage_events: int, max_hit_delta: int, max_alive: int) -> Dictionary:
	return {
		"phase": sim.phase,
		"elapsed": sim.elapsed,
		"hp": sim.hp,
		"level": sim.level,
		"xp": sim.xp,
		"next_xp": sim.next_xp,
		"kills": sim.kills,
		"spawned_count": sim.spawned_count,
		"spawned_by_kind": sim.spawned_by_kind.duplicate(),
		"first_damage": first_damage,
		"damage_events": damage_events,
		"max_hit_delta": max_hit_delta,
		"max_alive": max_alive,
		"alive": sim.enemies.size(),
		"beacon_state": sim.beacon_state,
		"beacon_progress": sim.beacon_channel_progress,
	}

func _run_pressure_probe(until: float) -> Dictionary:
	var sim := Sim.new()
	sim.attack_range = Sim.ATTACK_RANGE   # pin the draftable ranged Spark Chain (ADR 0004)
	sim.hp = 999
	sim.max_hp = 999
	var first_damage := -1.0
	var damage_events := 0
	var max_hit_delta := 0
	var prev_hp := sim.hp
	var max_alive := 0
	while sim.elapsed < until and sim.phase == Sim.PHASE_PLAYING:
		sim.tick(DT, Vector3.ZERO)
		if sim.hp < prev_hp:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, prev_hp - sim.hp)
			if first_damage < 0.0:
				first_damage = sim.elapsed
			prev_hp = sim.hp
		max_alive = maxi(max_alive, sim.enemies.size())
	return _summary(sim, first_damage, damage_events, max_hit_delta, max_alive)

func _time_to_kill(hp: float) -> float:
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.pickup_radius = 0.0
	var e := Sim.Enemy.new()
	e.position = Vector3(2.0, 0.0, 0.0)
	e.hp = hp
	e.radius = 1.0
	e.xp_value = 1
	sim.enemies.append(e)
	while sim.elapsed < 10.0 and not sim.enemies.is_empty():
		sim.tick(DT, Vector3.ZERO)
	return sim.elapsed

func _test_enemy_roles_match_ttk_bands() -> void:
	_check_between("trash nibbler TTK is pinned", _time_to_kill(Sim.NIBBLER_HP), 0.66, 0.74)
	_check_between("dasher remains trash TTK", _time_to_kill(Sim.DASHER_HP), 0.66, 0.74)
	_check_between("brute is a bruiser priority target", _time_to_kill(Sim.BRUTE_HP), 2.72, 2.88)
	_check_between("warden is between trash and brute", _time_to_kill(Sim.WARDEN_HP), 2.02, 2.18)

# --- Weapon progression: the melee start (ADR 0004) ---

func _test_gizmo_starts_with_rudimentary_melee() -> void:
	var sim := Sim.new()
	_check("Gizmo starts at melee reach, not the ranged Spark Chain", absf(sim.attack_range - Sim.MELEE_RANGE) < 0.001)
	_check("the melee start is shorter than the draftable ranged weapon", Sim.MELEE_RANGE < Sim.ATTACK_RANGE)

func _test_opening_single_mob_is_a_clean_kill() -> void:
	# The first-level promise (ADR 0004): a lone trash mob dies before it can land a hit,
	# even with contact LIVE. Non-tautological — a too-short melee reach would let the mob
	# touch first, costing HP (this is the check that pins MELEE_RANGE big enough).
	var sim := Sim.new()
	sim.spawn_enabled = false
	sim.elapsed = Sim.CONTACT_GRACE + 0.1                  # past grace, so a hit COULD land
	sim._spawn_nibbler(Vector3(0.0, 0.0, Sim.SPAWN_RING))  # one nibbler, 9 m out
	var hp0 := sim.hp
	var t := 0.0
	while sim.phase == Sim.PHASE_PLAYING and not sim.enemies.is_empty() and t < 12.0:
		sim.tick(DT, Vector3.ZERO)
		t += DT
	_check("the opening trash mob dies", sim.enemies.is_empty())
	_check("Gizmo kills the lone mob without taking a hit", sim.hp == hp0)

func _test_melee_start_makes_standing_still_lethal() -> void:
	# With only melee reach you cannot clear the board while standing still — movement
	# matters from the first level. (Contrast the ranged profile, which farms safely for
	# ~60s.) Bound it well under that so a regression toward "ranged-easy" trips red.
	var sim := Sim.new()
	var t := 0.0
	while sim.phase == Sim.PHASE_PLAYING and t < 90.0:
		sim.tick(DT, Vector3.ZERO)
		t += DT
	_check("standing still with the melee start naturally loses", sim.phase == Sim.PHASE_GAMEOVER)
	_check_between("melee standstill dies in the opening window, not the ranged farm", t, 20.0, 45.0)

func _test_leveling_increases_spark_chain_output() -> void:
	var sim := Sim.new()
	sim.attack_range = Sim.ATTACK_RANGE   # the Spark Chain is the ranged DRAFT (ADR 0004); test it at its reach
	sim.spawn_enabled = false
	sim.attack_cooldown = 0.05
	sim.level = 2
	for i in 2:
		var e := Sim.Enemy.new()
		e.position = Vector3(2.0 + i, 0.0, 0.0)
		e.hp = 2.0
		e.radius = 1.0
		sim.enemies.append(e)
	sim.tick(0.05, Vector3.ZERO)
	_check("level 2 Spark Chain hits two targets", sim.enemies[0].hp < 2.0 and sim.enemies[1].hp < 2.0)
	_check("level scaling keeps a cooldown floor", sim.current_attack_cooldown() >= 0.01)

func _test_pressure_probe_at_60s() -> void:
	var result := _run_pressure_probe(60.0)
	_check_between("60s pressure spawns stay in tuning band", result["spawned_count"], 73.0, 81.0)
	_check_between("60s pressure kills stay in tuning band", result["kills"], 63.0, 73.0)
	_check_between("60s pressure has real board presence", result["max_alive"], 7.0, 11.0)
	_check("contact damage never one-shots during pressure probe", result["max_hit_delta"] <= 1)
	var by_kind: Dictionary = result["spawned_by_kind"]
	_check_between("dashers are present by 60s", int(by_kind.get(Sim.ENEMY_DASHER, 0)), 14.0, 19.0)

func _test_stationary_profile_is_lethal_but_not_cheap() -> void:
	var result := _run_fixed_profile("stationary")
	_check("standing still naturally loses", result["phase"] == Sim.PHASE_GAMEOVER)
	_check_between("standing first damage has breathing room", result["first_damage"], 49.0, 58.0)
	_check_between("standing death proves baseline lethality", result["elapsed"], 60.0, 67.0)
	_check("standing damage is chip, not a one-shot", result["max_hit_delta"] <= 1)

func _test_mistake_kite_can_still_lose_naturally() -> void:
	var result := _run_fixed_profile("mistake_kite")
	_check("mistake kite naturally loses", result["phase"] == Sim.PHASE_GAMEOVER)
	_check_between("mistake kite loss timing is pinned", result["elapsed"], 93.0, 108.0)
	_check_between("mistake kite first hit comes from rising pressure", result["first_damage"], 27.0, 35.0)
	_check_between("mistake kite levels before death", result["level"], 2.0, 4.0)
	_check_between("mistake kite loss happens under real board pressure", result["max_alive"], 7.0, 12.0)
	_check("mistake kite damage is chip, not a one-shot", result["max_hit_delta"] <= 1)
	var by_kind: Dictionary = result["spawned_by_kind"]
	_check("mistake kite survives into brute pressure", int(by_kind.get(Sim.ENEMY_BRUTE, 0)) > 0)

func _test_decent_kite_survives_the_clock() -> void:
	# Path A (ADR 0005): the timer-win is gone; the Beacon channel win returns in
	# lesson 0018. Until then a competent kite can no longer WIN — but the board
	# pressure must stay fair, so it still SURVIVES the full pressure clock.
	var result := _run_decent_kite_profile()
	_check("decent kite no longer wins (no Beacon yet)", result["phase"] == Sim.PHASE_PLAYING)
	_check("decent kite survives the full clock", result["hp"] >= 1)
	_check_between("decent kite takes some but not lethal damage", result["damage_events"], 2.0, 6.0)
	_check("decent kite reaches several level-ups", result["level"] >= 6)
	_check_between("decent kite first damage is not instant", result["first_damage"], 15.0, 60.0)
	_check_between("decent kite board pressure remains bounded", result["max_alive"], 10.0, 25.0)
	_check("decent kite damage is chip, not a one-shot", result["max_hit_delta"] <= 1)
	var by_kind: Dictionary = result["spawned_by_kind"]
	_check("director unlocks dashers", int(by_kind.get(Sim.ENEMY_DASHER, 0)) > 0)
	_check("director unlocks brutes", int(by_kind.get(Sim.ENEMY_BRUTE, 0)) > 0)
	_check("director unlocks wardens", int(by_kind.get(Sim.ENEMY_WARDEN, 0)) > 0)

func _test_seek_and_hold_can_rekindle() -> void:
	var result := _run_seek_and_hold_profile()
	_check("a seek-and-hold run rekindles the Beacon (win reachable by fair play)", result["phase"] == Sim.PHASE_COMPLETE)
	_check("the Beacon reached Rekindled", result["beacon_state"] == Sim.BEACON_REKINDLED)
	_check("the channel actually filled", result["beacon_progress"] >= 1.0)
	_check("seek-and-hold survives the rekindle", result["hp"] >= 1)
	_check_between("rekindle completes on the channel timer, not instantly", result["elapsed"], 8.0, 20.0)
