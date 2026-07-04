# GZ-151 — E5 decision: ADR 0011 — score/combo disposition

intent: One session, one ruling: does the Phaser score/combo layer survive the 3D design? Produces `docs/adr/0011-score-and-combo-disposition.md` and unblocks the juice band.
files in scope: PRIMARY (new): `docs/adr/0011-score-and-combo-disposition.md`. No code.
grounding: Phaser score sinks throughout simulation.ts (combo ts:1009, close-call ts:749–757, clutch ts:768–792, surge ts:639–644); the re-centering directive (the fun loop is the product; XP/draft/beacon ARE the reward structure); ADR 0001 (Sparks are the currency, score was never one of the three quantities).
decisions made (RECOMMENDED DEFAULT — ratify or overrule with rationale, then it's law):
- **Cut score and combo as player-facing numbers.** The 3D loop's reward loop is draft + beacon; a score readout competes with the objective cue and reintroduces "how long/how much" framing adjacent to the retired countdown.
- **Keep the underlying risk-reward FEEL hooks as non-numeric mechanics:** close-call dash-cooldown refund (ts:750) and clutch-window dash refund (ts:782) port later as GZ-152; surge/jackpot's score halves die with score.
- Consequence line for the lore lab: end-screen and Codex ceremony celebrate level/kills/sparks + Beacon, never points.
executable success criteria: the ADR file exists, follows docs/adr/ house format, records decision + alternatives + consequences; `tools/godot/run_all_checks.sh` still green (no code changed).
dependencies / order: none within P2 (frontier of the band). Blocks GZ-152, GZ-156.
model routing: **Opus** — a design ruling with cascading consequences.
cross-domain: consequence note routed to lore (copy) — as text in the ADR, not a lab edit.
status: deferred:E5
