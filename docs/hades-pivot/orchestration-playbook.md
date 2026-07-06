# Orchestration playbook — Hades-clone rebuild (attempt 2)

Written 2026-07-05 by the Fable orchestrator. Attempt 1 ran partly under Sonnet 5
and surfaced real limits in each teammate; attempt 2 encodes them so delegation
stops rediscovering them. This doc governs **process**; `HADES-PARITY-SPEC.md`
governs **design**.

## The per-slice pipeline (mandatory from attempt 2 on)

1. **Pick** — orchestrator selects the highest-value `ready-for-agent` ticket(s)
   from `docs/hades-pivot/queue/INDEX.md`; parallel workers only on disjoint files.
2. **Decompose** — if the slice is bigger than one cold session, the worker's first
   act is its `/decompose` skill (spec → tickets → slices) with MODE: plan-only,
   feeding new tickets back into the queue INDEX. Single-session tickets skip
   straight to 3 (feature-ship's Phase 0 size gate is the backstop).
3. **Ship** — worker runs its `/feature-ship` skill on exactly one ticket, with the
   orchestrator-supplied anchor pack (ticket text, governing spec sections, file
   anchors, test commands, constraints).
4. **Audit** — orchestrator runs the adversarial-audit loop (finders → refuters →
   reproducers, per `/home/ark/prompts/adversarial-audit.md`) over the worker's diff.
   Confirmed defects go back **to the same worker** as a corrections handoff with
   failing-test anchors; orchestrator never patches worker code silently.
5. **Record** — queue INDEX status flip, ADR if canon moved, Daily ledger entry.

## Teammate capability map (learned, attempt 1)

### Codex CLI — GPT-5.5 xhigh (`codex exec`)
- **Route here:** all nontrivial engineering — new systems, GDScript architecture,
  spec-correction batches, test rewrites. It handled a 5-item spec-correction batch
  (cast rework, FSM dash-cancel, branching generator, reward assignment, boon slots)
  in one job, coherently, with tests grown 100→248 checks.
- **Limits/quirks:**
  - Sandbox: crashes opening `user://logs` — every headless Godot invocation needs
    `--user-data-dir /tmp/...`. Cannot write outside worktree (no `~/memory`) —
    orchestrator owns Daily/vault writes; tell Codex to put exit artifacts in the
    ticket/queue, not the vault.
  - Long-running (10–40 min at xhigh); harness can't track it — launch
    `nohup … &`, poll log + `pgrep`, pair with a scheduled wakeup.
  - Killed mid-job it leaves **coherent partial state** (it commits to disk as it
    goes) — audit what landed before re-delegating, don't assume loss.
  - Invocation: `codex exec -C <worktree> -s workspace-write --skip-git-repo-check "$(cat prompt)"`.
- **Skills:** has `decompose`, `feature-ship`, `adversarial-audit` in `~/.codex/skills/`.

### Grok Build CLI — Composer 2.5 fast (`grok -p`)
- **Route here:** mechanical, judgment-free volume — queue/doc rewrites to a dictated
  outline, boilerplate `.tres`, repetitive test scaffolds, find/replace refactors.
  Its attempt-1 queue rewrite was structurally fine but needed orchestrator passes
  for anything factual (statuses, counts).
- **Limits/quirks:**
  - `--effort` / reasoningEffort unsupported on composer-2.5-fast (400 error).
  - `--permission-mode auto --always-approve` is **policy-denied** (unsandboxed
    approval-free loop); use `--permission-mode acceptEdits`.
  - Invocation: `grok -p "$(cat prompt)" --cwd <worktree> --permission-mode acceptEdits --output-format plain`, nohup'd like Codex.
  - Never send design judgment or factual game-reference claims.
- **Skills:** has the same trio in `~/.grok/skills/`.

### Claude subagents (Sonnet scouts, Explore, godot-prompter specialists)
- **Route here:** research fan-out, codebase questions, design *drafts*.
- **Limit (the attempt-1 lesson):** Sonnet asserted a false fact about the reference
  game (static per-room camera) with full confidence. **Any factual claim about how
  Hades works must be verified by the orchestrator or a dedicated research pass
  before it enters a spec.** Design authority stays Fable-authored
  (`HADES-PARITY-SPEC.md`).

### Harness mechanics
- nohup-inside-background-Bash double-detaches: the harness reports "completed" when
  the *launcher* exits. Poll logs; use ScheduleWakeup (≥1200s for long jobs).
- **Liveness checks lie:** `pgrep -f "codex exec"` matches the polling shell's own
  command string — a permanent false ALIVE. Use `pgrep -x codex` / `pgrep -x grok`
  plus **log mtime** as the real signal.
- Grok (attempt-2 lesson): may finish its edits but exit silently before the
  feature-ship ship phase (no commit, no status flip) and its `--output-format plain`
  log is near-empty. Treat uncommitted-but-green work as recoverable: audit the
  diff, then the orchestrator commits on the worker's behalf with attribution.
- Codex sandbox addendum: some headless runs also need `--log-file /tmp/...` on top
  of `--user-data-dir` (Codex discovered this itself during HZ-002).
- Verification gate before any status flip: three suites
  (`run_room_graph_tests`, `run_ability_kit_tests`, `run_boon_meta_tests`) +
  `--check-only` on touched scripts, all with the user-data-dir redirect.

## Commit policy (attempt 2)
Workers make conventional commits per slice **on `hades-clone` only**; never push;
orchestrator commits doc/queue reconciliations. Rationale: per-slice commits give
the audit stage a clean diff boundary; the worktree isolates all risk from
`gizmo-3d`.
