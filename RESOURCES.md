# Gizmo Godot Resources

## Knowledge

- [Official Godot 4.6 documentation](https://docs.godotengine.org/en/stable/)
  Primary source for GDScript, scenes/nodes, `Camera3D`, `Control`/`Theme`,
  signals, headless runs. Use for: any Godot concept before teaching it.
- `CONTEXT.md` (repo)
  Orientation keystone — domain language, architecture vocabulary, doc-ownership
  map, environment/engine (§6). Use for: getting oriented; resolving "where does
  this truth live?"; the canonical engine-version statement.
- `design-handoff/NARRATIVE.md` (repo)
  Premise/story canon — Gizmo the clanker, the spark of humanity, dehumanized
  tech, the gouache cosmos of lost tech, system→fiction mapping. Use for: any
  fiction or premise question.
- `docs/godot/BALANCE_MODEL.md` (repo)
  Gizmo-specific balance/tuning model (TTK bands, reward gates). Use for: porting
  spawn/economy/enemy numbers with intent.
- `reference/game-balance-reference.md` (repo)
  Generic, external balance reference. Use for: background on survivors-like
  tuning principles, not Gizmo's exact numbers.
- `GODOT-PORT.md` (repo)
  The port map — what to read and how the Phaser pieces map to Godot. Use for:
  picking the next slice and its target files.
- `docs/godot/PORT_MAP.md` (repo)
  Seed→Godot line anchors. Use for: locating the exact source for a mechanic.
- `docs/godot/LEARNING_PATH.md` (repo)
  Phase spine for the port. Use for: sequencing lessons (re-pitch from-zero).
- `docs/godot/DECISIONS.md` (repo)
  ADRs that are locked (contained `godot/`, headless-first, naming, engine
  target — see `CONTEXT.md` §6). Use for: explaining *why* a constraint exists.
- `docs/godot/ASSET_IMPORT_PLAN.md` / `docs/godot/PLAYTEST_CHECKLIST.md` (repo)
  SVG/font import and feel verification. Use for: the art and polish phases.
- `game-src-phaser/src/game/simulation.ts` (repo)
  Mechanics source of truth (~1,750 lines of pure logic). Use for: the exact
  rules to port.
- `design-system/` + `design-handoff/FUSION-CODEX.md` (repo)
  Look/feel truth — palette, type, motion, components. Use for: theme and juice.
- `docs/godot/answer-key/` (repo)
  Verified reference port. Use for: checking the learner's hand-built work when
  stuck — **never** as copy-paste source.

## Wisdom (Communities)

- [r/godot](https://reddit.com/r/godot) and the official Godot Discord/forums
  Use for: idiom, troubleshooting, "is this the Godot-native way?"
