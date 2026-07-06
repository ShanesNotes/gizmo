# ADR 0011: Ability Input Router Is A Node

Date: 2026-07-06

## Status

Accepted

## Decision

`AbilityInputRouter` is a `Node`, not a `RefCounted`.

The router still keeps its testable core free of direct `Input` singleton polling:
tests call `handle_action_pressed()` and `tick()` directly. The node wrapper owns
only Godot lifecycle integration: `_unhandled_input()` for InputMap events and
`_process()` for buffer expiry.

## Consequences

- Scenes can attach the router beside or under `AbilityComponent` without an
  autoload or controller rewrite.
- Headless tests remain pure and deterministic because injected action presses
  drive the core path.
- A later player scene can provide movement/aim direction to
  `handle_action_pressed()` without changing the ability kit.
