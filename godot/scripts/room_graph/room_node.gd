class_name RoomNode
extends Resource

## One instantiated room within a single run's RoomGraph. Distinct from
## RoomTemplate: the template is shared authored data, this is per-run state
## (ADR 0010 replaces the whole-island `pressure_clock` with per-room state).

enum State { LOCKED, AVAILABLE, ENTERED, CLEARED, REWARDED }
enum RewardType { BOON, SCRAP, SPARKS, HAMMER, HEAL, SHOP, REST, REWARD }

## Unique within one run's graph (e.g. "room_03"), not shared across runs.
@export var room_id: String = ""
@export var template: RoomTemplate
@export var state: State = State.LOCKED
@export var reward_type: RewardType = RewardType.BOON

## Per-room difficulty knob for the RoomDirector (ADR 0003/0006 pressure math,
## now scoped to this room instead of a run-wide clock). 0.0 = easiest, 1.0 = hardest.
@export_range(0.0, 1.0) var difficulty_tier: float = 0.0
