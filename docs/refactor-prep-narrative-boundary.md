# Refactor prep — NARRATIVE boundary review

Status: hygiene sidecar for the Path A refactor. This file documents contradictions in
`design-handoff/NARRATIVE.md` without editing that premise-canon file.

## Boundary

Do **not** rewrite `design-handoff/NARRATIVE.md` in the refactor-prep hygiene pass.
The active project rules still treat it as premise/story canon, while `CONTEXT.md` and
accepted ADRs supersede stale mechanics language.

## Proposed retired-marker targets

| NARRATIVE location | Current stale wording | Why retired | Active replacement |
|---|---|---|---|
| `design-handoff/NARRATIVE.md:13-16` | Logline frames the game as increasingly difficult **waves of enemies, elites, and bosses**. | ADR 0003 forbids player-facing wave-round structure; `CONTEXT.md` says older waves/elites/bosses language means generic escalation only. | Director-driven enemy pressure under Path A; the run can crest into threats without teaching waves. |
| `design-handoff/NARRATIVE.md:26-31` | Spark of Humanity is carried through objectives like **Carry the Spark to the Beacon**. | ADR 0001 keeps HP, Sparks, and Spark of Humanity distinct; ADR 0005 says the Beacon objective is a rekindle channel, not Spark-of-Humanity fuel. | Gizmo guards the Spark thematically; Path A mechanically rekindles the Beacon through an area-hold channel. |
| `design-handoff/NARRATIVE.md:63` | **Waves → elites → bosses** maps enemy roles to escalating wave forms. | ADR 0003 retires wave ladders; ADR 0006 makes pressure place-aware rather than round-indexed. | Enemy roles are dehumanized-tech pressure shapes / special threats controlled by director pressure. |
| `design-handoff/NARRATIVE.md:67` | **All waves cleared (run complete)** = the Hush pushed back for one vigil. | ADR 0005 replaces survive/clear-run completion with Beacon Rekindled; loss remains HP 0. | Run complete = Beacon Rekindled; the pressure clock only fuels the director. |

## Suggested marker pattern if the user later authorizes NARRATIVE edits

Use inline notes, not rewrites, so premise canon stays intact. Suggested wording:

```md
<!-- Retired mechanics wording: predates ADR 0003/0005. Read "waves/elites/bosses"
as generic director-pressure escalation; active Path A win = Beacon Rekindled. -->
```

For the Spark objective line:

```md
<!-- Retired mechanics wording: predates ADR 0001/0005. The Spark of Humanity,
Sparks currency, HP, and Beacon rekindle channel stay distinct. -->
```

## Refactor implication

When the Path A loop refactor touches simulation/HUD/end-screen copy, prefer the
active phrasing from `CONTEXT.md` and ADRs 0001/0003/0005/0006. Do not use
NARRATIVE's wave or carry-the-Spark objective text as implementation authority.
