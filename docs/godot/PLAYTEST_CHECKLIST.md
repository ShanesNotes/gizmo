# Godot/Web validation and playtest checklist

## Preflight
```bash
git status --short
```
Do not touch unrelated dirty work. As of initial setup, unrelated `design-handoff/*` edits and `tmp/` may exist.

## Static artifact checks

Doc spine plus the bare `godot/` shell (ADR-012 from-zero reset). The shell asserts
only what a freshly-created lesson-0001 project actually contains; the live
simulation/player/presentation scripts now live in `docs/godot/answer-key/`
(asserted in the REFERENCE block below), not in `godot/`.
```bash
for f in \
  CLAUDE.md \
  MISSION.md \
  NOTES.md \
  RESOURCES.md \
  docs/godot/PORT_MAP.md \
  docs/godot/LEARNING_PATH.md \
  docs/godot/TRUST_BOUNDARIES.md \
  docs/godot/PLAYTEST_CHECKLIST.md \
  docs/godot/DECISIONS.md \
  docs/godot/ASSET_IMPORT_PLAN.md \
  godot/project.godot \
  godot/scripts/.gitkeep \
  godot/scenes/.gitkeep \
  godot/tests/.gitkeep \
  godot/ui/.gitkeep; do
  test -f "$f" || { echo "missing $f"; exit 1; }
done

test "$(wc -l < CLAUDE.md)" -le 200
grep -R "simulation.ts\|GODOT-PORT.md\|design-system\|npx serve" CLAUDE.md MISSION.md NOTES.md RESOURCES.md docs/godot/*.md
grep -E "AGENTS\.md|import" CLAUDE.md
find godot -type f | grep -E '/[A-Z][A-Za-z0-9_]*\.(gd|tscn|tres)$' && exit 1 || true
grep -E "godot/\.godot/|\*\.translation" .gitignore
! grep -E "\*\.uid|\*\.import" .gitignore
# Generated Godot cache may exist after import, but it must be ignored and not staged.
if git status --short | grep -E "(^\?\? godot/\.godot|^A  godot/\.godot|^ M godot/\.godot)"; then
  echo "godot/.godot cache is unignored or staged"; exit 1
fi
# Optional evidence when Godot has imported the project:
git status --short --ignored | grep -E "^!! godot/\.godot" || true
```

## Web seed checks
```bash
cd game-src-phaser
npm ci
npm run build
```
Pass: TypeScript and Vite build succeed. If dependency install is skipped or network is unavailable, record the exact blocker.

Manual feel check:
```bash
npx serve .
```
Pass: start run, move, collect Spark/XP, level up, and see HUD updates.

## Godot checks — the learner's `godot/` workspace

These gates apply to the **growing `godot/` shell**. Always-applicable: version +
import + parse-whatever-exists + runtime smoke. The shell starts with no `.gd`
files, so the parse loop is a no-op until the learner adds scripts.
```bash
${GODOT_BIN:-godot} --version
${GODOT_BIN:-godot} --headless --path godot --import
find godot -path godot/.godot -prune -o -name '*.gd' -print | sort | while read -r file; do
  ${GODOT_BIN:-godot} --headless --path godot --check-only --script "res://${file#godot/}"
done
${GODOT_BIN:-godot} --headless --path godot --quit-after 1
```
Pass: Godot reports 4.7.x stable by default, imports the shell clean, parses every
GDScript file the learner has built, and runtime smoke exits 0. Engine target is
4.7.x stable (ADR-017); the last recorded green setup verification used
`4.6.2.stable.mono.official` — re-verify on 4.7 and record the patch.

Run the test runners **only once the learner has built the matching files** in
`godot/` (rebuilt from the answer-key during co-development — InputMap → Simulation
movement → SimSpace → PlayerAvatar3D → Main wiring). Until then they do not exist in
`godot/` and these lines are expected to be skipped:
```bash
${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd
${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_player_scene_tests.gd
${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_presentation_3d_tests.gd
${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_ui_smoke_tests.gd
```
If Godot creates `.uid` sidecars for scripts/resources, keep them with the project and move them with their source files. If Godot is missing, record the blocker and continue static checks only.

## Godot checks — REFERENCE port (`docs/godot/answer-key/`)

These gates apply to the **verified reference port**, not to `godot/`. The
answer-key is the finished early 2.5D implementation set aside by the from-zero
reset (ADR-012); its four runners are the real, currently-passing test gates.
```bash
${GODOT_BIN:-godot} --headless --path docs/godot/answer-key --import
${GODOT_BIN:-godot} --headless --path docs/godot/answer-key --script res://tests/run_simulation_tests.gd
${GODOT_BIN:-godot} --headless --path docs/godot/answer-key --script res://tests/run_player_scene_tests.gd
${GODOT_BIN:-godot} --headless --path docs/godot/answer-key --script res://tests/run_presentation_3d_tests.gd
${GODOT_BIN:-godot} --headless --path docs/godot/answer-key --script res://tests/run_ui_smoke_tests.gd
```
Pass: the answer-key imports and all four `run_*_tests.gd` exit 0 (verified on
`4.6.2.stable.mono.official`). The `tests/capture_*_visual_smoke.gd` captures need a
real display and are out of scope for headless gates. Consult this port to check
direction or unblock — never paste it wholesale into a lesson.

## Teaching-flow dry run
Ask Claude Code: “Use `/teach` for lesson 1.” Expected:
- explains the Godot concept,
- cites `GODOT-PORT.md` and `simulation.ts`,
- proposes one tiny exercise/edit,
- runs or names the exact verification command,
- appends a short next step to `docs/godot/LESSON_LOG.md`.
