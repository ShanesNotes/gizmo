# Issue Tracker Configuration

This repo uses **GitHub issues**, not a local markdown tracker.

- Issue root: GitHub issues on `github.com/ShanesNotes/gizmo`. Create, claim, and close issues there.
- Triage state: the issue's open/closed state plus the house labels (`needs-triage` · `needs-info` · `ready-for-agent` · `ready-for-human` · `wontfix`)
- Comments go on the GitHub issue.
- `.scratch/` is **gitignored** here (see `.gitignore`) — it holds local scratch and backups, never durable tracker state. Anything that must survive the machine goes in a GitHub issue or in `docs/`.
- ADRs live in `docs/adr/`; domain context is `CONTEXT.md`.
- Use `gh issue list`, `gh issue create`, `gh issue comment` from the repo root; `gh` is authenticated as `ShanesNotes`.

## Wayfinding operations (`/wayfinder`)

- **Map**: one GitHub issue labelled `wayfinder:map`, body sectioned Destination / Notes / Decisions-so-far / Not-yet-specified / Out-of-scope
- **Child ticket**: one GitHub issue per question, with a `Type:` line recording `research` / `prototype` / `grilling` / `task`
- **Blocking**: a `Blocked by: #NN, #NN` line near the top of the body; a ticket is unblocked when every listed issue is closed
- **Frontier**: open, unblocked, unassigned issues — lowest number wins
- **Claim**: assign yourself before any work
- **Resolve**: append the answer as a comment, close the issue, then add a one-line gist + link to the map issue's Decisions-so-far
- **HITL discipline** (house rule, 2026-07-10): grilling/prototype tickets are never self-answered by an agent. Technical calls may go through a Claude+Codex+Grok pseudo-grill with dissents recorded on the ticket; taste/policy/rights/destructive calls get label `ready-for-human` and blocking edges re-wired around them.
