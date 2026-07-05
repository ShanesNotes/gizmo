# AFK fleet runbook — running this queue cold

How a coding agent (Codex/Opus/Sonnet/Haiku session) picks up any GZ ticket with zero questions.

## Per-ticket session prompt template
```
You are an AFK coding agent for Gizmo (Godot 4.7 3D rogue-lite), repo /home/ark/gizmo,
branch off gizmo-3d (NEVER main). Your entire assignment is the single ticket file:
  docs/afk/queue/GZ-0XX-<slug>.md
Read, in order: that ticket → docs/afk/queue/SPEC-fun-loop-v1.md (only the FL sections the
ticket cites) → docs/afk/queue/API-CONTRACT.md (your inherited sim surface) →
docs/afk/queue/LANDING-ORDER.md (if your ticket names a cluster). Respect files-in-scope
exactly; decisions are already made — implement, don't redesign. TDD where the ticket adds
logic (red→green→refactor). Verify with the ticket's exact commands; tools/godot/run_all_checks.sh
must exit 0 before you claim done. Commit on a branch named gz-0XX-<slug>; end the commit
message with the Co-Authored-By line naming your model. Do not push, do not touch sibling
folders (GZ-030/031 run INSIDE their labs instead — boot there with the lab's AGENTS.md).
If an AC cannot pass without exceeding files-in-scope, STOP and write a blocker note into
docs/afk/queue/BLOCKERS.md naming the gap — do not improvise scope.
```

## Dispatcher loop (human or orchestrator, once per session batch)
1. Frontier = tickets with `status: ready-for-agent` whose blockedBy are all merged.
2. Launch at most ONE ticket per file-cluster (Clusters A/B/C in LANDING-ORDER.md); anything
   touching disjoint files can run in parallel.
3. On merge: flip downstream `blocked:GZ-0XX` tickets whose blockers are now all merged to
   `ready-for-agent` (edit the ticket's status line), append the merge to PROGRESS.md.
4. On red gate after landing: revert the landing, move the ticket to BLOCKERS.md with the log.
5. Model per ticket = its `model routing` line. Don't upgrade tiers without a failure reason.

## Batch plan (expected)
- Batch 1: GZ-001 [Opus] + GZ-010, GZ-014, GZ-017, GZ-018 [cheap] + GZ-030/031 in their labs.
- Batch 2: GZ-002, GZ-011 (then 012), GZ-013 (after 005 later — skip), GZ-016 after 002.
- Batches 3–6: sim lane marches 003→009 while cluster-B tickets land between sim merges
  (LANDING-ORDER.md order). GZ-019 after 009; GZ-032/033 as service lanes deliver.
- Final: GZ-020 (ship gate) → GZ-040 (export) → tag v1.0.0-pathA on gizmo-3d.
- Post-v1: open EPICS.md, decompose the chosen epic's seeds into GZ-1xx files with the same schema.

## Import to GitHub (when reachable)
`for f in docs/afk/queue/GZ-*.md; do gh issue create -R ShanesNotes/gizmo -F "$f" \
  -t "$(head -1 "$f" | sed 's/^# //')" -l "$(grep -oP '(?<=^status: ).*' "$f" | sed 's/ .*//')"; done`
(ready-for-agent / blocked:* map to the repo's label conventions; blocked issues get the label
`needs-info` replaced by nothing — blockedBy lives in the body.)
