extends SceneTree

# Keeper Rank meta-progression suite. Run with:
#   godot --headless --path godot --script res://tests/run_keeper_rank_tests.gd

const MetaStateScript := preload("res://scripts/meta/meta_state.gd")
const KeeperRankScript := preload("res://scripts/meta/keeper_rank.gd")

const TEST_SAVE_PATH := "user://saves/test_keeper_rank_meta.cfg"

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running keeper rank tests…")
	_test_shard_tally()
	_test_rank_curve()
	_test_meta_state_ledger()
	_test_shard_grade_purchases()
	_test_save_load_round_trip()
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

func _check_eq(desc: String, got: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, got, expected], got == expected)

func _test_shard_tally() -> void:
	_check_eq("empty summary tallies zero shards", KeeperRankScript.shards_for_run({}), 0)
	_check_eq(
		"rooms + kills + flawless tally per the rate table",
		KeeperRankScript.shards_for_run({"rooms_cleared": 4, "kills_total": 30, "flawless_rooms": 2}),
		4 * 10 + 30 * 1 + 2 * 25
	)
	_check_eq(
		"victory adds the victory bonus",
		KeeperRankScript.shards_for_run({"rooms_cleared": 1, "victory": true}),
		10 + 150
	)
	_check_eq(
		"negative summary values never mint shards",
		KeeperRankScript.shards_for_run({"rooms_cleared": -5, "kills_total": -1, "flawless_rooms": -2}),
		0
	)

func _test_rank_curve() -> void:
	_check_eq("rank 0 below the first threshold", KeeperRankScript.rank_for_lifetime(99), 0)
	_check_eq("rank 1 at 100 lifetime shards", KeeperRankScript.rank_for_lifetime(100), 1)
	_check_eq("rank 1 holds until 300", KeeperRankScript.rank_for_lifetime(299), 1)
	_check_eq("rank 2 at 300 lifetime shards", KeeperRankScript.rank_for_lifetime(300), 2)
	_check_eq("rank 3 threshold is 600", KeeperRankScript.threshold_for_rank(3), 600)
	_check_eq("shards to next from zero", KeeperRankScript.shards_to_next_rank(0), 100)
	_check_eq("shards to next mid-band", KeeperRankScript.shards_to_next_rank(150), 150)
	_check("negative lifetime clamps to rank 0", KeeperRankScript.rank_for_lifetime(-50) == 0)
	_check_eq("rank 0 title", KeeperRankScript.title_for_rank(0), "Cold Chassis")
	_check(
		"titles clamp past the table end",
		KeeperRankScript.title_for_rank(99) == KeeperRankScript.RANK_TITLES[KeeperRankScript.RANK_TITLES.size() - 1]
	)

func _test_meta_state_ledger() -> void:
	var state = MetaStateScript.new()
	_check_eq("fresh state has zero lifetime shards", state.lifetime_spark_shards, 0)
	state.bank_spark_shards(120)
	_check_eq("banking accrues lifetime", state.lifetime_spark_shards, 120)
	_check_eq("banking accrues spendable", state.spendable_spark_shards, 120)
	_check_eq("keeper rank derives from lifetime", state.keeper_rank(), 1)
	state.bank_spark_shards(-40)
	_check_eq("negative banking is ignored", state.lifetime_spark_shards, 120)
	state.record_run_finished()
	state.record_run_finished()
	_check_eq("runs finished counter ticks", state.runs_finished, 2)

func _test_shard_grade_purchases() -> void:
	var state = MetaStateScript.new()
	state.bank_spark_shards(120)
	_check("shard purchase succeeds at rank price 100", state.purchase_grade_with_shards("guard_max"))
	_check_eq("shard purchase spends spendable only", state.spendable_spark_shards, 20)
	_check_eq("lifetime shards never regress on spend", state.lifetime_spark_shards, 120)
	_check_eq("grade actually rose", state.get_stat_grade("guard_max"), 1)
	_check("second grade refused while short 200", not state.purchase_grade_with_shards("guard_max"))
	state.bank_spark_shards(200)
	_check("second grade purchasable at 200", state.purchase_grade_with_shards("guard_max"))
	_check("cap refuses a third grade", not state.purchase_grade_with_shards("guard_max"))
	_check("unknown stat refused", not state.purchase_grade_with_shards("no_such_stat"))
	# Scrap path is untouched by the shard ledger.
	state.scrap_banked = 50
	_check("scrap purchase path still works beside shards", state.purchase_grade("dash_charges"))

func _test_save_load_round_trip() -> void:
	var state = MetaStateScript.new()
	state.bank_spark_shards(350)
	state.purchase_grade_with_shards("draft_rerolls")
	state.record_run_finished()
	_check_eq("round-trip fixture saves", state.save_to_path(TEST_SAVE_PATH), OK)

	var loaded = MetaStateScript.load_from_path(TEST_SAVE_PATH)
	_check_eq("lifetime shards round-trip", loaded.lifetime_spark_shards, 350)
	_check_eq("spendable shards round-trip", loaded.spendable_spark_shards, 250)
	_check_eq("runs finished round-trip", loaded.runs_finished, 1)
	_check_eq("keeper rank recomputes after load", loaded.keeper_rank(), 2)
	_check_eq("shard-bought grade round-trips", loaded.get_stat_grade("draft_rerolls"), 1)

	# Pre-v3 saves (no [keeper] section) load with zeroed ledger.
	var legacy := ConfigFile.new()
	legacy.set_value("meta", "schema_version", 2)
	legacy.set_value("currency", "scrap_banked", 75)
	var legacy_path := "user://saves/test_keeper_rank_legacy.cfg"
	legacy.save(legacy_path)
	var migrated = MetaStateScript.load_from_path(legacy_path)
	_check_eq("v2 save migrates with zero shards", migrated.lifetime_spark_shards, 0)
	_check_eq("v2 save keeps its scrap", migrated.scrap_banked, 75)
	_check_eq("migrated save reports current schema", migrated.schema_version, MetaStateScript.CURRENT_SCHEMA_VERSION)
