class_name KeeperRank
extends RefCounted

## Keeper Rank — the run-end tally that converts a run's deeds into spark-shards
## and the lifetime shard total into a rank. Pure math over the run-summary
## dictionary; owns no state. The Mirror spends shards via MetaState.

const SHARDS_PER_ROOM: int = 10
const SHARDS_PER_KILL: int = 1
const SHARDS_PER_FLAWLESS_ROOM: int = 25
const VICTORY_BONUS: int = 150

## Rank r is reached at 100 * r * (r + 1) / 2 lifetime shards (100, 300, 600, …).
const RANK_STEP: int = 100

const RANK_TITLES: Array[String] = [
	"Cold Chassis",
	"Ember Bearer",
	"Lamplighter",
	"Hearthwright",
	"Warden of the Kept",
	"Keeper of the First Spark",
]

static func shards_for_run(summary: Dictionary) -> int:
	var rooms := maxi(0, int(summary.get("rooms_cleared", 0)))
	var kills := maxi(0, int(summary.get("kills_total", 0)))
	var flawless := maxi(0, int(summary.get("flawless_rooms", 0)))
	var shards := rooms * SHARDS_PER_ROOM + kills * SHARDS_PER_KILL + flawless * SHARDS_PER_FLAWLESS_ROOM
	if bool(summary.get("victory", false)):
		shards += VICTORY_BONUS
	return shards

static func rank_for_lifetime(lifetime_shards: int) -> int:
	var shards := maxi(0, lifetime_shards)
	var rank := 0
	while shards >= threshold_for_rank(rank + 1):
		rank += 1
	return rank

static func threshold_for_rank(rank: int) -> int:
	if rank <= 0:
		return 0
	return RANK_STEP * rank * (rank + 1) / 2

## Shards still needed from `lifetime_shards` to reach the next rank.
static func shards_to_next_rank(lifetime_shards: int) -> int:
	var rank := rank_for_lifetime(lifetime_shards)
	return threshold_for_rank(rank + 1) - maxi(0, lifetime_shards)

static func title_for_rank(rank: int) -> String:
	return RANK_TITLES[clampi(rank, 0, RANK_TITLES.size() - 1)]
