# Demo polish backlog — Fable director's playthrough, 2026-07-06 evening

Full merged-tree playthrough (hub → run → 3 waves → all four abilities → death → end
screen). Survived 3:31, zero engine errors, full kit verified live. Findings ranked by
demo impact; tickets HZ-080…HZ-084.

## What already reads as a demo
Brass hub mood; Gizmo's real body with facing/bob; guard pips + recharge pacing; the
Spark gauge charging and firing; cast's full lodge→reclaim economy in one visible shot;
death → RUN LOST → hub loop, all error-free.

## P0 — demo killers
1. **Combat feedback is nonexistent (HZ-084, Fable-owned).** Surge emptied the gauge and
   staggered three enemies and the screen did not change. No hit reaction, no death
   effect, no burst visual, no stagger read. This is the single largest gap between
   "works" and "demo". Full spec in the HZ-084 ticket; implementation reserved for the
   principal.
2. **First-room pressure (HZ-081).** Tier-0 budget still produces 3 waves × 3 chaff in
   room 1 with ZERO beat between waves — the concurrency cap fixed simultaneity, not
   totals or pacing. Demo opening should be 1–2 waves with a ~0.8s inter-wave beat.
3. **Hub identity (HZ-080).** The hub still uses the placeholder capsule (not gizmo.glb)
   and the three anchors (RunDoor pad, Mirror, Codex) are unlabeled colored primitives —
   nothing tells a first-time player what anything is. Doorway also physically lets the
   player walk into the void when the run surface fails (see 4).
4. **Stale-import brick (HZ-082).** A fresh pull without `--import` leaves class_name
   registrations stale → run_orchestrator parse-fails → run door silently no-ops (shell
   correctly refuses) and the open doorway drops the player out of the world. Needs: a
   physical blocker behind the door volume, a visible hub error surface when the run
   surface fails, and an import note in export.md + sync ritual.

## P1 — feel/polish
5. **Combat-room baseline lighting (HZ-083)** reads as unlit greybox next to the brass
   hub — warm the neutral baseline ~15% toward the palette.
6. Hub SCRAP readout is bare floating text vs the brass panel style in-run.
7. Kills grant nothing visible mid-fight (sparks/scrap only move at exits by design —
   revisit after feedback kit lands; may be solved by death effects alone).

## Process note
Merged-checkout sync ritual now includes `--import` after every pull (class-name cache).
