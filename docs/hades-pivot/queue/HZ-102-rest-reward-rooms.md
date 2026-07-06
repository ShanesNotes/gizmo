# HZ-102 — REST/REWARD room types (generation side)

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-061 (shipped)
**Parallel-safety fence:** may NOT touch `run_orchestrator.gd`, `room_director.gd`,
`enemies/`, `player/` (HZ-070 owns them concurrently). If orchestrator wiring is needed,
print the exact diff in the summary; the orchestrator applies it at commit time.

Hades parity (spec §2.1): runs punctuate combat with non-combat rooms. Add two room types
to the generator's vocabulary:
- **REST** (Ember Alcove): no enemies; a one-use restoration fixture (guard refill —
  actual heal behavior is orchestrator-side, out of scope; generation + template + door
  telegraph only).
- **REWARD** (Scrap Cache): no enemies; a guaranteed pickup fixture of the door's promised
  reward type.

## Scope
1. `room_graph_generator.gd`: REST and REWARD in the room-type vocabulary with generation
   rules — at most one REST per biome, placed in the back half; REWARD replaces a combat
   room at low weight; never first room, never adjacent to SHOP, never boss-adjacent
   substitution for the guaranteed shop/elite fixtures.
2. `room_door.gd`: telegraph tint/text entries for REST and REWARD.
3. `run_flow_bridge.gd`: draft rules — REST/REWARD doors never open a boon draft.
4. New greybox templates: `rest_alcove.tres`/`.tscn`, `reward_cache.tres`/`.tscn`
   (validator-clean, spawn-free).
5. Red-first tests in the graph/door/flow-bridge suites; seed-sweep invariant for rule 1.

## Acceptance
Failing-test-first for the generation rules; full graph/door/bridge/pool suites green;
--check-only clean on touched scripts.
