# GZ-040 — Ship: export pipeline for v1

intent: v1 isn't shipped until a build leaves the editor: Windows desktop + Web export presets, produced headless, smoke-checked. CLAUDE.md names `export-pipeline` as the v1 ship phase.

files in scope:
- PRIMARY (new): `godot/export_presets.cfg`
- also (new): `tools/godot/export_v1.sh` (headless export wrapper, mirrors run_all_checks.sh conventions)
- DO NOT touch: game scripts/scenes; do not commit export artifacts or templates (Boundaries: no exports staged — .gitignore the output dir `godot/build/` in the same diff).

grounding:
- CLAUDE.md "v1 ship | export-pipeline"; engine Godot 4.7 Forward+ (ADR 0009) — note: Web export on 4.x requires the Compatibility renderer; DECISION below.
- Ground every export claim in godot-prompter:export-pipeline / official 4.7 docs before writing presets — never guess template names.

decisions made:
- Two presets: `windows-v1` (primary, Forward+) and `web-v1` (secondary; if Forward+ web export is unsupported on 4.7, the web preset ships with the Compatibility renderer feature override and a recorded note — do NOT change the project's main renderer, ADR 0009).
- `export_v1.sh`: checks templates installed (fail with instructions, not silence) → `--headless --export-release` per preset → asserts artifact exists and is > 10 MB.
- Version string `v1.0.0-pathA` in project settings, shown nowhere in-game yet (no UI scope).

executable success criteria:
1. `bash tools/godot/export_v1.sh` exits 0 on a machine with 4.7 templates, producing `godot/build/windows/gizmo.exe` (and web bundle if supported); exits non-zero with a clear message when templates are missing.
2. `tools/godot/run_all_checks.sh` exits 0 (presets file must not break import).

acceptance / done: one command yields a distributable build of the fun loop; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-020 (ship gate green first). Parallel-safe (new files only).
model routing: **Sonnet** — config + script against documented export flow; must consult docs, not invent.
cross-domain: none.
status: blocked:GZ-020
format: one issue per file (gh import later).
