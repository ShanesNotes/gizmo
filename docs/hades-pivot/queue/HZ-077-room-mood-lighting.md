# HZ-077 — Room mood lighting per type (gouache-lit greybox)

**Status:** ready-for-agent · **Worker:** Codex · **Deps:** none (room-scene fence)
Art direction: gouache cosmos, brass warmth (`design-handoff/ART_DIRECTION.md`). Greybox
stays greybox — this is LIGHT and ENVIRONMENT only, the cheapest possible mood pass.

## Scope
Per room template scene, tune WorldEnvironment (ambient color/energy, optional subtle fog)
and the DirectionalLight (color temperature, energy, angle) to give each room type an
instantly readable mood:
- combat_small / combat_large — neutral cool dusk (baseline).
- elite_arena — low red-amber threat (dimmer ambient, warmer key light).
- shop_small — warm brass interior glow.
- rest_alcove — ember warmth (soft orange, gentle).
- reward_cache — faint gold shimmer (brighter key on the fixture).
- boss_arena — dramatic: darkest ambient, hard key light, highest contrast.
Plus: hub.tscn gets the brass-home treatment (warmest of all).

## Constraints
- Scene-file edits only (light/environment nodes + properties). No shaders, no post FX
  beyond Environment properties, no new assets.
- Headless safety: suites must stay green (environment nodes are inert headless).
- Keep player/enemy readability: floors stay light enough that grey enemies contrast.
- Validator: if room_scene_validator checks node sets, ensure additions pass (extend
  validator expectations ONLY if it hard-fails on new node types — note it in summary).

## Fence
godot/scenes/rooms/*.tscn, godot/scenes/hub.tscn, run_room_validator_tests.gd (only if
needed), run_hub_tests.gd (only if needed). Do NOT touch scripts, templates (.tres),
project.godot, or any suite logic beyond validator expectations.
