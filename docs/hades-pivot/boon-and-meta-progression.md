# Boon draft + meta-progression

Slice 3 under ADR 0010. This adds the data and headless seams for Hades-style
boon drafts plus death-and-return meta progression. It does not build a boon UI,
hub scene, room-transition controller, lore names, art, or audio.

## Data model

### BoonDef

`godot/scripts/boons/boon_def.gd` is an authored `Resource` for one boon:

- `boon_id: StringName` - stable machine id, unique within the boon table.
- `display_name: String` - player-facing label.
- `description: String` - player-facing effect text.
- `rarity: Rarity` - `Common`, `Rare`, `Epic`, or `Legendary`.
- `slot: Slot` - one of `Attack`, `Special`, `Cast`, `Dash`, or `Passive`.
- `domain: String` - generic grouping key such as `spark`, `scrap`, or `guard`.
- `ability_modifiers: Array[AbilityModifier]` - authored modifiers to apply on pick.

The `domain` field is deliberately generic. It is the extension seam for a later
Gizmo-lore pass to map draft groupings to named patrons, factions, relic families,
or other fiction. This slice must not invent those characters or lore labels.

`BoonDef` consumes the ability-kit seam from
`godot/scripts/abilities/ability_modifier.gd`. On pickup, the draft duplicates
each selected `AbilityModifier` before installing it on
`AbilityComponent.ability_modifiers`, so authored boon Resources and authored
ability Resources stay shared/read-only. The actual ability mutation still
happens inside `AbilityComponent` when it creates a duplicated runtime `Ability`
copy for activation.

Per `HADES-PARITY-SPEC.md` §4 and §7.5, kit-slot boons are exclusive: one
selected boon owns each slot. Accepting a boon in an occupied slot is allowed and
replaces the previous boon in that slot. Replacement removes the previous boon's
runtime modifiers before installing the new boon's modifiers. Draft offers still
include boons for occupied slots; the replacement is a player choice, not a
candidate-filter rule.

### BoonDraft

`godot/scripts/boons/boon_draft.gd` is run-scoped state plus draft rolling logic:

- `picked_boons` / `picked_boon_ids` are reset every run.
- `picked_boons_by_slot` tracks the current boon for each exclusive slot.
- `roll_offer(pool, offer_count, rng, already_picked_ids)` returns up to N unique,
  eligible boons. It excludes already-picked boon ids, not occupied slots.
- `offer_between_rooms(graph, current_room_id, pool, rng, offer_count)` is the
  room-graph trigger seam. It only emits a draft if the current `RoomNode` is
  `CLEARED` and has outgoing `RoomConnection`s.
- `accept_boon(boon, ability_kit)` applies the boon to the target kit and records
  it for this run only; if its slot is occupied, it swaps the old boon and its
  modifiers out first.

Signals:

- `draft_offered(room, next_room_ids, offers)` - future UI/RunController seam.
- `boon_accepted(boon)` - future HUD/loadout seam.
- `draft_reset()` - death/new-run reset seam.

## Draft weighting

Offers are weighted random selection without replacement. Already-picked boon ids
and duplicate ids in the pool are excluded before rolling. Occupied slots are not
excluded, because slot replacement is an intentional draft choice.

Current v1 weights:

| Rarity | Weight |
|---|---:|
| Common | 60 |
| Rare | 25 |
| Epic | 10 |
| Legendary | 3 |

Algorithm:

1. Filter null, empty-id, already-picked, and duplicate-id entries.
2. Sum rarity weights across eligible candidates.
3. Draw one weighted candidate.
4. Remove it from the candidate list.
5. Repeat until N offers are produced or the eligible pool is empty.

This is intentionally simple. Future Hades texture such as prerequisites, pity,
domain affinity, forced legendary gates, or meta unlock weighting can layer onto
the candidate filter and weight function without changing `BoonDef`.

## Meta save/load format

`godot/scripts/meta/meta_state.gd` is a persistent `Resource` data container, but
it serializes through `ConfigFile` instead of saving a `.tres`/`.res` player save.
That keeps player-controlled save data in a simple key/value format and avoids
loading untrusted Resource files.

Default path:

```text
user://saves/meta_state.cfg
```

Schema version: `1`.

Config sections:

```ini
[meta]
schema_version=1

[currency]
scrap_banked=0
sparks_banked=0

[unlocks]
boon_ids=["spark_special_boost", "guard_dash"]
```

Fields:

- `scrap_banked` - persistent Scrap banked across deaths.
- `sparks_banked` - persistent Sparks banked across deaths.
- `unlocked_boon_ids` - persistent ids that make boons eligible for a future pool
  builder.

Run-picked boons are not saved here. They are part of `BoonDraft` and reset on
death.

## Death/reset flow

`godot/scripts/meta/run_lifecycle.gd` is a small non-scene orchestration seam:

1. `start_new_run(entry_room_id)` clears run-scoped currency and boon draft state,
   then moves to `RUNNING`.
2. During a run, `add_run_currency(scrap, sparks)` tracks currency earned but not
   yet banked.
3. On death, `handle_player_death(save_path)`:
   - copies remaining run Scrap/Sparks into `MetaState.bank_currency()`;
   - clears run currency, current room id, and `BoonDraft` picks;
   - returns to `HUB`;
   - optionally writes `MetaState` to disk when a save path is supplied;
   - emits `player_died`, `returned_to_hub`, and `run_reset`.
4. The hub can then call `start_new_run()` to begin a clean run with the same
   persistent `MetaState`.

No scene is wired yet. HZ-041/HZ-042 can consume this seam when the hub and
transition controller exist.
