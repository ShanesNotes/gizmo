# Workspace established: co-development Gizmo→Godot port, from-zero guide

This workspace runs a **co-development** rebuild of Gizmo in Godot — a
slow-down-and-learn effort. The AI and learner build together; the AI explains
and writes code, paced so the learner can explain every piece. The aim is
understanding, not who types.

A finished reference port (a codex pre-pass) was **set aside** at
`docs/godot/answer-key/` (`project.godot`, `scenes/main.tscn`,
`scripts/simulation.gd`, headless tests — passing on Godot 4.6.2), so we rebuild
the port together at learning pace rather than from the solution. `godot/` was
left an empty skeleton so lesson 0001 starts from scratch.

No prior Godot knowledge is assumed in the lessons. The learner has separate
experience in another workspace, deliberately not imported, so the published
guide reads from zero. Compute the zone of proximal development from this
directory's records only — starting here; begin lesson 0001 at beginner level.

Two principles that steer every lesson: **editor-first** — lessons are real actions
in the Godot editor (lesson 0001 = open Godot and hit **Create**), not CLI
file-authoring; and **the seed is the teacher's grounding** — the Phaser/TS seed
and port framework let the AI teach efficiently (saving tokens), not a spec the
learner reconstructs. The outcome to optimize for is teaching how to co-develop a
game in Godot with Claude Code + the teach skill — the game seed is the vehicle.

Grounding to lean on (not re-derive): `GODOT-PORT.md`, `docs/godot/PORT_MAP.md`,
`docs/godot/LEARNING_PATH.md` (a candidate lesson spine), and
`docs/godot/DECISIONS.md`. See [[MISSION.md]].
