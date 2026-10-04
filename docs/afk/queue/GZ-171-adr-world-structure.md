# GZ-171 — P3 decision: ADR 0010 — run/world structure

intent: The biggest unmade call, made once: how ten regions become a rogue-lite. Produces `docs/adr/0010-run-and-world-structure.md`; every P3–P6 ticket hangs off it.
files in scope: PRIMARY (new): `docs/adr/0010-run-and-world-structure.md`; GLOSSARY.md truth-map line updated to point at it (the one anchor edit this band is licensed to make).
grounding: region graph (10 regions, 3 acts, 3 routes: upper HEARTH→BRASS→VERDANT→PRISM→TEMPEST→NULL; lower HEARTH→RUST→ASH→TEMPEST→NULL; mystery HEARTH→RUNE→OBS→NULL; 9 critical + 6 optional connections); path-a spec §1 (Path B = connected streamed islands, deferred until Path A proves traversal); rogue-lite genre law (runs end; the world persists); balance §13.1 (meta = bounded additive + difficulty escalation).
decisions made (RECOMMENDED DEFAULT for ratification):
- **One run = one island traversal** (the proven Path A shape). Winning a region's run rekindles ITS beacon.
- **The macro map is META, not mid-run:** between runs, Gizmo stands at a world map (the Codex motif as its frame — lore's UI/memory/ceremony reading) and picks the next region among those connected to any rekindled one — the routes become the player's strategic layer. Act gates: Act 2 opens at 3 rekindled + carried-warmth threshold (ADR 0012); Act 3 at 7.
- **Losses cost the run, never a rekindled beacon** (rogue-lite, not roguehard); region difficulty scales by threat tier × act multiplier (§13.1).
- **Path B streaming is REJECTED for 1.0** — scene-per-region with map transitions; "road opens outward" is the transition ceremony, not seamless streaming. Revisit post-1.0 only.
executable success criteria: ADR exists (decision, alternatives incl. mega-run and streaming, consequences per phase); GLOSSARY.md pointer updated; no other code.
dependencies / order: blockedBy GZ-020 (v1 loop proven — the ADR cites its evidence). Blocks GZ-172–175, GZ-161, all REGION-*.
model routing: **Opus** — the architecture ruling of the whole game.
status: deferred:P3
