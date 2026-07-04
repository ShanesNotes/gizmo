# GZ-141 — E4 (all labs): Meridian Concordance promotion wave

intent: The cross-domain binding table (visual ↔ lore/level/audio/asset ids) moves from candidate to promoted: each sibling ratifies its half per gates G13/G14, so every surface provably tells the same truth.
files in scope: four lab-side passes, one per sibling (lore, level-design, audio-canon, asset-pipeline), each ratifying or rejecting the entries citing ITS ids in `gizmo-design-system/canon/concordance.yaml`; design-system merges rulings. NO game-repo writes.
grounding: concordance.yaml (X-L/X-S/X-A/X-P bindings); evidence ledger `extraction/cross-domain-binding-ledger.md`; open items D6/D7 in `extraction/reconciliation-2026-07-03-concordance.md`; design-system ADR 0003 (projection, not ownership — sibling ids are read-only citations).
decisions made: run as FOUR sequential sub-sessions (lore → level → audio → asset), each one-session-sized, each ending with an extraction note in its own lab + a status flip PR to design-system; D6/D7 resolved first (they gate the rest).
executable success criteria: per sub-session — that lab's validators green AND the corresponding concordance entries flip candidate→promoted (or rejected with a named reason); final — design-system `make validate` green with G13/G14 passing.
dependencies / order: blockedBy GZ-131 (visual half needs the hollowed ruling). Sub-sessions serialize.
model routing: **Opus** per sub-session — canon adjudication across domains.
cross-domain: this ticket IS the cross-domain protocol, executed by the book.
status: deferred:E4
