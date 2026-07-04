# ADR 0009 — Engine target is Godot 4.7 stable

## Decision

The active Godot project targets Godot 4.7 stable. `godot/project.godot`
declares `config/features=PackedStringArray("4.7", "Forward Plus")`, and the
documented verification gate is run with a Godot 4.7 stable binary.

## Why

The local project is already verified on Godot 4.7 stable, and the pulled GitHub
state records the same engine-target decision on the older remote `main` line.
Keeping the active `gizmo-3d` project metadata at `4.6` made cold agents choose
between the runtime, docs, and project config.

## Rules Out

- Treating `4.6` in `project.godot` as the current target.
- Merging the older remote `main` branch into `gizmo-3d` solely to import its
  engine-target metadata.
- Claiming any broader renderer, dependency, or gameplay migration from this ADR.
