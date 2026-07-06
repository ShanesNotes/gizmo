# Ability kit

Design slice for ADR 0010's Hades-style player kit. This scaffolding is deliberately
self-contained: it does not wire into `GameController`, room traversal, camera, or
boon draft.

## Data model

Abilities are authored as Godot `Resource`s:

- `Ability`: shared base data (`ability_id`, kind, `cost`, `resource_key`,
  `cooldown`, `cast_time`, `recovery_time`, `potency`). The `cooldown` field
  is ignored by `CastAbility` per the parity spec; cast uses ammo instead.
- `DashAbility`: dash duration, i-frame duration, speed intent.
- `AttackAbility`: light combo steps, combo reset window, per-step damage/recovery.
- `SpecialAbility`: stronger move that spends `spark_charge` and has its own cooldown.
- `CastAbility`: ammo-with-reclaim cast action, no special-resource cost and no
  time cooldown. It declares `max_ammo` (starts at 1; later meta can upgrade it).

Runtime state lives in `AbilityComponent`, not on those Resources:

- granted abilities keyed by `ability_id`
- cooldown timers per ability
- resource pools keyed by `StringName`
- cast stones: available ammo plus lodged stones awaiting reclaim
- dash i-frame timer
- attack combo step/window
- emitted combat-intent signals such as `dash_started`, `attack_started`,
  `special_started`, and `cast_started`

This keeps authored `.tres` ability data safe to share. When an ability activates,
the component duplicates it into a runtime copy, applies modifiers, spends resources,
starts cooldowns for cooldown-based abilities, and emits the action signal. Cast is
structurally different: firing consumes one available stone, increments lodged
stones, and fails when no stones are available. Stones return only through the
explicit `reclaim_cast_ammo(amount)` API, which emits `cast_ammo_reclaimed` and
updates `cast_ammo_changed`. Actual pickup/enemy-death physics is a later scene
slice.

The earlier scaffold described cast as cooldown-driven. That design is superseded
by `HADES-PARITY-SPEC.md` §3 and §7.1; cooldown-cast is not the active v1 model.

## State machine

`PlayerActionStateMachine` is a small flat FSM owned by or assigned to
`AbilityComponent`.

```text
Idle
  -> Dash    -> Idle
  -> Attack  -> Idle
  -> Special -> Idle
  -> Cast    -> Idle

Attack  -> Dash   (dash-cancel at any point)
Special -> Dash   (dash-cancel during the current special state)
Cast    -> Dash   (dash-cancel during the current cast state)
Any action -> Hitstun -> Idle
Hitstun blocks new ability activations.
Dash does not cancel itself.
Attack combo state is not a separate FSM state: combo step/window is runtime
data on AbilityComponent, so the player returns to Idle between light attacks
while the combo window remains open.
```

The state machine gates action overlap only. Hit detection, projectile spawning,
animation, SFX, and movement displacement should listen to component signals in
later slices.

## Boon extension point

`AbilityModifier` is the boon seam. A future boon system can grant modifier
Resources to `AbilityComponent.ability_modifiers`; activation then applies those
modifiers to a duplicated runtime copy of the selected ability.

Examples that do not require editing core ability code:

- add potency to attack or cast
- reduce dash cooldown
- lower special cost
- shorten cast recovery
- future modifiers/meta can raise cast `max_ammo`

The current modifier is intentionally tiny (`cooldown_multiplier`,
`recovery_multiplier`, `cost_delta`, `potency_delta`). More specific boon effects
such as longer dash i-frames can subclass it or add focused modifier Resources
later without changing the component's activation flow.
