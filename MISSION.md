# Mission: Rebuild Gizmo in Godot, from zero

## Why
Rebuild **Gizmo** — a designed, playable bullet-heaven where a clanker preserves
the spark of humanity against ever-encroaching dehumanized technology, in a
gouache cosmos of lost tech (premise canon: `design-handoff/NARRATIVE.md`) — in
Godot, *co-developing it with an AI teacher* and deliberately slowing down to
understand each piece, instead of having a finished game handed over. Porting a
real, designed game is the way in; the journey doubles as a from-zero guide for
others on **co-developing a game in Godot with Claude Code and the teach skill.**
For orientation (domain language, architecture, doc map), see `CONTEXT.md`.

## Success looks like
- Comfortable in Godot: creating a project, scenes, and GDScript from scratch
- Ported the headless simulation (movement, spawn, XP/level, the four economies)
  to GDScript I genuinely understand and can explain
- A playable Godot build of the core loop that *feels* like the web seed
- A `lessons/` guide that reads cleanly from zero for someone else

## Constraints
- Engine: Godot **4.6.x stable** (verified locally on 4.6.2; see `CONTEXT.md` §6
  rather than pinning a patch), **GDScript** (not C#)
- **Co-development, paced for understanding.** The AI teaches and writes code
  alongside me; we go slow enough that I can explain every part. The point isn't
  who types — it's that nothing lands as a black box.
- A finished reference port is set aside at `docs/godot/answer-key/`, so we build
  the port together at learning pace rather than starting from the solution.
- Hobby pace. This is a **separate** effort from my WoW-like `game-dev`
  workspace — no shared learning state.
- One win per lesson, each published as a self-contained HTML page.

## Out of scope
- C# / .NET, full 3D mechanics/modeling, and perspective-3D scope creep. Orthographic 2.5D presentation over flat rules is in scope.
- Rewriting the Phaser seed, the root web build, or the design handoff — those
  are reference only (mechanics, look, feel)
- Shipping/publishing the game itself — the port *is* the curriculum
