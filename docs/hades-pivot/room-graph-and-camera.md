# Room-graph data model + fixed isometric camera

Design-only slice under ADR 0010 (Hades-clone structural pivot). Scaffolds the
room-graph Resource types and specifies the camera rig; does **not** wire
either into the existing `GameController`/`Simulation` — those stay
reference-only per the ADR until a later implementation slice.

## What this replaces

- **`pressure_clock` / whole-island pressure (ADR 0003, ADR 0006).** The
  temporal × spatial pressure model survives as *combat* math, but its scope
  shrinks from "the whole island, one clock" to "one room, one clock." Each
  room gets its own director instance seeded by `RoomNode.difficulty_tier`
  instead of a run-wide `elapsed / pressure_clock` ramp. `PressureZone` nodes
  (ADR 0006) become optional per-room set dressing rather than a
  run-spanning spatial field — a room is small enough that "near the door" vs
  "room center" is the whole spatial story, if it's needed at all.
- **The single traversed island (`main.tscn`, Path A spec, CONTEXT.md's
  "Path A" section).** Replaced by a run-scoped graph of discrete room
  scenes connected by one-way doors. `WalkableRegion` (ADR 0006) becomes a
  per-room concern (each room scene defines its own walkable footprint) —
  it no longer needs to describe one large irregular island shape.
- **`camera_rig.gd`'s unbounded Diablo-follow.** The follow-lerp core
  survives (Hades' camera does track the player), but it gains per-room
  **bounds clamping** (see §2) — the camera can no longer drift anywhere the
  player goes; each room's authored bounds pin it, and it *cuts* (not pans)
  between rooms. The ~45° pitch the old `offset` encoded is kept as the
  framing convention.
- **Guard-over-HP (ADR 0007)** and **`GameController`'s obstacle
  registration** are unaffected structurally — they still apply, just inside
  whatever room is currently loaded instead of across one island.

## 1. Room-graph data model

### Why Resources

Per `resource-pattern`: a room graph is data (which rooms exist, how they
connect, what state each is in) with no per-frame behavior, so it's modeled
as `Resource` subclasses. The *behavior* that builds and walks the graph
(the generator, the run controller) stays in plain classes/Nodes — resources
never get `_process` or scene-tree access.

Two families of resource, deliberately kept separate:

| Resource | Shared or per-run? | Role |
|---|---|---|
| `RoomTemplate` | Shared, authored, read-only | One hand-built room layout + its scene |
| `RoomNode` / `RoomConnection` / `RoomGraph` | Per-run, generated at run start | This run's specific sequence + state |

A `RoomTemplate` is loaded once from a `.tres` and never mutated (same
anti-pattern the skill warns about — mutable shared Resources need
`duplicate()`; templates are read-only so they don't need it).
`RoomGraph`/`RoomNode` are built fresh in memory every run by
`RoomGraphGenerator` and are never saved to disk as authored content (a
future save-system slice could serialize a *paused* run's `RoomGraph` for
resume, distinct from this authoring model).

### Scripts (scaffolded, not wired in)

```
godot/scripts/room_graph/
  room_template.gd        # RoomTemplate   — authored, shared
  room_node.gd             # RoomNode       — per-run instance + state
  room_connection.gd        # RoomConnection — one-way door between two RoomNodes
  room_graph.gd              # RoomGraph     — the run's rooms + connections + lookups
  room_graph_generator.gd     # RoomGraphGenerator — builds a RoomGraph (logic, not data)
```

`RoomTemplate` (`godot/scripts/room_graph/room_template.gd`):

```gdscript
class_name RoomTemplate
extends Resource

enum RoomType { COMBAT, ELITE, BOSS, REWARD, SHOP, REST }

@export var template_id: String = ""
@export var biome_id: String = ""
@export var room_type: RoomType = RoomType.COMBAT
@export var scene: PackedScene
@export_range(0, 3) var min_exits: int = 1
@export_range(0, 3) var max_exits: int = 1
@export var tags: Array[String] = []
```

`RoomNode` (`room_node.gd`) — per-run instance state:

```gdscript
class_name RoomNode
extends Resource

enum State { LOCKED, AVAILABLE, ENTERED, CLEARED, REWARDED }
enum RewardType { BOON, SCRAP, SPARKS, HAMMER, HEAL, SHOP }

@export var room_id: String = ""
@export var template: RoomTemplate
@export var state: State = State.LOCKED
@export var reward_type: RewardType = RewardType.BOON
@export_range(0.0, 1.0) var difficulty_tier: float = 0.0
```

`RoomConnection` (`room_connection.gd`) — a one-way door:

```gdscript
class_name RoomConnection
extends Resource

@export var from_room_id: String = ""
@export var to_room_id: String = ""
@export var door_name: String = "RoomExit"
```

`RoomGraph` (`room_graph.gd`) — the run's graph + lookups:

```gdscript
class_name RoomGraph
extends Resource

@export var biome_id: String = ""
@export var entry_room_id: String = ""
@export var rooms: Array[RoomNode] = []
@export var connections: Array[RoomConnection] = []

func get_room(room_id: String) -> RoomNode: ...
func get_connections_from(room_id: String) -> Array[RoomConnection]: ...
func get_next_room_ids(room_id: String) -> Array[String]: ...
func mark_state(room_id: String, new_state: RoomNode.State) -> void: ...
```

`RoomGraphGenerator` (`room_graph_generator.gd`) — a `RefCounted`, not a
`Resource` (it's logic, not data):

```gdscript
class_name RoomGraphGenerator
extends RefCounted

static func generate(
    biome_id: String,
    template_pool: Array[RoomTemplate],
    room_count: int,
    rng: RandomNumberGenerator,
) -> RoomGraph: ...
```

### Procedural vs fixed: procedural, from an authored template pool

**Decision: procedural**, generated at run start from a curated pool of
hand-built `RoomTemplate`s per biome — matching how Hades actually builds a
run (a curated room pool assembled into a run-specific sequence, not one
fixed level layout, and not a fully-open floor-plan generator either). A
fixed graph would fight the stated mandate (Hades-structural clone implies
replayable per-run sequencing) and a from-scratch procedural floor-plan
generator is out of proportion for v1 — the templates themselves are still
hand-authored scenes, only their *order* is generated.

**v1 scope now includes branching and generation-time rewards.** Per
`HADES-PARITY-SPEC.md` §2.1, §2.2, §2.4, and §7.3-7.4, the old linear-only
generator was an integration scaffold, not the active v1 target.
`RoomGraphGenerator.generate()` now emits `room_count` indexed rooms with a
linear backbone plus seeded branch/rejoin skip edges: each non-terminal room has
1-2 exits, a 2-exit branch rejoins within one step, and the last slot is still
forced to a `BOSS` template. Each `RoomNode` also receives a `reward_type` at
generation time, with exactly one `SHOP` reward and at least one mid-biome
`ELITE` room-type fixture per run when the template pool contains the required
fixtures. Door telegraphs should read the destination room's `reward_type`;
rolling rewards on room clear is not the active design.

### Room-transition flow

1. A `RunController` node (future implementation slice; not scaffolded here)
   owns one `RoomGraph` for the run and a `current_room_id`.
2. Entering a room: instantiate `RoomNode.template.scene`, position Gizmo at
   its spawn marker, set `RoomNode.state = ENTERED`, and spin up a
   per-room `RoomDirector` seeded from `difficulty_tier` (the ADR
   0003/0006 pressure math, scoped to this room — see "What this replaces").
3. Clearing a room: the `RoomDirector` signals "room clear" (last enemy
   dead). `RunController` sets `state = CLEARED`, unlocks
   `graph.get_next_room_ids(current_room_id)` (→ `AVAILABLE`), and opens the
   door(s) named by each outgoing `RoomConnection.door_name` in the current
   room scene (e.g. enables a `RoomExit` `Area3D`, previously inert). Each door
   telegraphs the connected room's pre-generated `reward_type`.
4. Reward/boon draft: walking into the open door triggers the transition —
   but before loading the next scene, `RunController` shows a full-screen
   boon-draft overlay (own future slice; out of scope here beyond this
   seam). On selection, mark the *current* room `REWARDED`, free the current
   room scene, then proceed to step 2 for the connection's `to_room_id`.
5. `RoomGraph` never needs "go back" support — `RoomConnection` is one-way by
   construction, matching Hades' no-backtrack rooms.

## 2. Fixed isometric camera

### Framing choice: bounds-clamped soft follow, cutting between rooms

**Correction (verification pass, 2026-07-05):** an earlier draft of this doc
claimed Hades' camera holds a static framing per room. That's wrong — Hades
uses a **soft-follow camera clamped to per-room bounds**. Small rooms *look*
static because the clamp pins the camera against the room's edges; larger
arenas (Elysium, the Asphodel barges) visibly track Zagreus. A hard-static
camera would force every room to fit one screenful or let the player walk
offscreen, so the rig below is a bounded follow, not a snap-and-hold.

The rig therefore keeps `camera_rig.gd`'s lerp-follow core (target position +
`Vector3(0, 12, 10)` offset, ≈ 50° down-angle) and adds two things:
1. **Per-room clamp bounds** — the camera's target is clamped to an authored
   XZ rect before the lerp, so the camera stops at room edges instead of
   showing out-of-bounds void.
2. **Cut on transition** — crossing into a new room teleports the camera to
   its clamped position instantly (no cross-room pan), matching Hades' hard
   cut between rooms.

**Bounds source: authored per room, not computed.** Each room scene places
one `Marker3D` named `CameraAnchor` (the default/center framing, used for
the transition cut and as the clamp rect's center) plus two exported floats
(or a small `CameraBounds` node) giving the clamp rect's XZ half-extents.
Authored beats computed (deriving from the walkable footprint) because
irregular rooms fight bounding-box math and designers want per-room framing
control — a corridor clamps tight, an arena clamps loose. A room whose
half-extents are zero degenerates to the static-camera case for free.

### Rig spec

A single reusable camera, not one Camera3D per room:

```gdscript
# godot/scripts/room_graph/room_camera.gd (future implementation slice —
# not scaffolded in this pass; spec only)
class_name RoomCamera
extends Camera3D

var _follow_target: Node3D          # Gizmo
var _clamp_center: Vector3          # from the room's CameraAnchor
var _clamp_half_extents: Vector2    # authored XZ half-extents (0,0 = static)

## Called once per room transition: re-anchor the clamp rect and hard-cut.
func enter_room(room_scene_root: Node3D) -> void:
    # read CameraAnchor + bounds, then global_position = clamped target (no lerp)

func _physics_process(delta: float) -> void:
    # target = player position clamped to the XZ rect, + the 45° offset;
    # lerp toward it (same smoothing constant as camera_rig.gd)
```

- `RunController` calls `enter_room()` right after instantiating a room
  scene; between transitions the camera soft-follows inside the clamp.
- `physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF` still
  applies (carried over from `camera_rig.gd`) so the transition cut isn't
  smoothed by the engine's own interpolation.
- Convention: every `RoomTemplate.scene` must contain a `Marker3D` named
  `CameraAnchor` (+ bounds extents); this is a room-authoring contract, not
  code-enforced here (a later `validate`-style check could assert it at
  import time).
- Room bounds for *gameplay* (walkable footprint, ADR 0006) remain a
  separate authored concern from the camera clamp rect — they usually agree
  but don't have to (e.g. letting the camera show a scenic ledge the player
  can't walk on).

## Open questions resolved in this pass

- **Branching now vs. later:** resolved by the parity spec in favor of now.
  v1 generation emits branch/rejoin structure and generation-time rewards; the
  data model's many-connection shape is now exercised, not merely reserved.
- **Save/resume of a paused run's graph:** explicitly deferred — noted in
  §1 as a distinct future concern, not solved here, since this slice is
  graph-shape + camera only.
- **Camera bounds: authored vs. computed:** resolved in favor of authored
  `CameraAnchor` markers + clamp extents (see §2) — cheaper, gives designers
  direct control, and matches how Hades' own rooms are camera-blocked.
- **Static vs. follow camera:** an earlier draft chose a hard-static per-room
  camera on a false premise about Hades; corrected in the verification pass
  to a bounds-clamped soft follow (see §2's correction note).
