# GZ-194 — P7: 1.0 release

intent: The road opens outward for real: release builds from the GZ-040 pipeline, an itch.io page speaking the premise in lore-true copy, and a tagged 1.0.
files in scope: `tools/godot/export_v1.sh` extended to versioned release artifacts (checksums, zip layout); store-page assets (screenshots at the gameplay camera, key art = design-handoff/gizmo-hud.png lineage, copy drafted from NARRATIVE.md premise — never rewriting NARRATIVE.md itself); tag `v1.0.0` on gizmo-3d after the full gate.
grounding: GZ-040 pipeline; Boundaries (no exports staged in git; store assets live outside the repo or in an ignored dir); lore copy law for all public text.
decisions made: release checklist IS the AC list — full suite green · GZ-020 + every R-7 + R-NULL-8 green · export both presets · fresh-machine smoke run of the Windows build (manual, evidenced by a run log) · page copy reviewed against lore glossary (validator run on the copy file) · tag pushed only by the human (commit/push law).
executable success criteria: every checklist line checked with evidence in the PR; artifacts reproducible from the tag.
dependencies / order: blockedBy R-NULL-8, GZ-183, GZ-191–193. The last ticket.
model routing: **Sonnet** (checklist execution) with the human on the trigger.
status: deferred:P7
