# HZ-072 — REST/REWARD runtime behavior + live traversal coverage

**Status:** ready-for-agent · **Worker:** Codex · **Deps:** HZ-102 (shipped)
**Source:** Fable strategic gate 2026-07-06.

HZ-102 shipped generation-side only. Two runtime gaps:
1. **Scrap Cache grants nothing** — `_apply_exit_reward` falls through `_: pass` for
   REWARD; the door telegraphs a cache, the room is empty. Contract: entering the REWARD
   room grants its promised pickup once (fixture interaction or on-entry grant — pick the
   simpler, Hades uses a physical pickup).
2. **Ember Alcove heals nothing** — REST fixture behavior (one-use guard refill per ADR
   0007 sanctuary language) was explicitly deferred; implement it (one use per visit,
   never refills Spark Surge per ADR 0012).

Plus coverage: no test traverses a REST/REWARD room at runtime. Extend the integration
gate: force a graph containing both types, traverse live — doors open at entry (already-
inside player path), no director, audio zone CLEARED, fixture grants exactly once,
re-entry does not re-grant.

## Fence
run_orchestrator.gd, new fixture script(s) under room_graph/ or rooms' scenes,
rest_alcove/reward_cache scenes, integration gate + orchestrator suites. Safe parallel
with HZ-103? NO — both touch run_orchestrator.gd; sequence after HZ-103 merges.
