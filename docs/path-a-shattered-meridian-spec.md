# Path A — Hearthwake / Shattered Meridian first island

**Status:** accepted spec · 2026-06-21 · supersedes the "static arena + countdown"
framing for the first level.

> **Telos.** Path A is not "the first level." It is the **first small enactment of the
> whole world pattern**: *warm origin → broken route → discernment branch → landmark
> memory → sanctuary breath → cold Beacon rekindled → road opens outward.* Build it as a
> **microcosm of the Shattered Meridian**, not a prettier survival arena.

This spec is the build target. Decisions are pinned as ADRs 0005–0008; this document ties
them to the island and the symbolic structure they serve. Source grammar (vendored into
the repo for reproducibility): `docs/reference/shattered-meridian-region-graph.json` — the
**HEARTH / Hearthwake Basin** region — used as *high-level grammar, not an implementation
mandate*. (External original, optional archaeology:
`~/Downloads/gizmo_shattered_meridian_region_graph_optimized.json`.)

## 1. What Path A proves
One large, procedurally **dressed** (not procedurally authored) living island
that proves: the painterly terrain kit, the exploration feel, the **place-aware pressure
director**, the **anchors**, and the **sanctuary / route grammar** — while keeping the
existing v1 code path (Gizmo movement, combat sim, Diablo camera) alive. Path B
(connected, streamed islands) waits until Path A proves traversal, navigation, encounter
pacing, and kit readability.

## 2. The symbolic spine (pattern-true, not label-heavy)
Meaning lives in **route structure, pressure, sanctuary, landmark, and transformation** —
never in on-screen labels. HEARTH's canon (from the world graph):

- **Region question:** *Can a made machine keep a human warmth alive instead of imitating
  humanity hollowly?*
- **Transformation:** Gizmo wakes a fragile keeper; the player learns warmth must be
  **carried, protected, and returned** to places built for it.
- **Corruption form:** comfort become idle automation — devices repeating care-like
  motions **without care**. (Path A's swarm reads as hollow machines going through the
  motions; the Beacon is care that must be *actively* restored.)
- **Sanctuary expression:** Brass Sphere workshop, the Heart Spire, safe calibration
  pads, repaired lights answering Gizmo's core.
- **Palette:** warm brass · soft teal · violet spark · deep indigo void.
- **Landmark shape:** a vertical heart-spire over a circular workshop basin.

The directed spine (one explorable axis, **not a hallway**):

```
warm origin → discernment branch → landmark / memory → trial / pressure
            → sanctuary / breath → cold Beacon (rekindled) → road opens outward
```

## 3. The loop (ADR 0005)
- **Win = Beacon Rekindled. Lose = HP 0.** No timer win, no countdown.
- Reaching the `ObjectiveBeaconAnchor` starts the climax. Beacon state machine:
  **`Dormant → Rekindling → Rekindled`**. `beacon_channel_progress` fills while Gizmo
  holds the radius (**area-hold** — he keeps moving and fighting), and pauses or slowly
  decays outside (tuning knob; slow decay is the on-theme default). While `Rekindling`,
  exposure is forced to **peak** (the siege). Channel complete → `PHASE_COMPLETE`.
- The old `run_duration` becomes the **`pressure_clock`**: director fuel + debug only,
  never a player-facing clock.
- Canon: *"The Beacon is not a finish line; it is a hearth that must be rekindled while
  the cold world pushes back."*

## 4. Place-aware pressure (ADR 0006)
`pressure = temporal_ramp × spatial_exposure(pos)` + local mods, with the `Rekindling`
peak override. Exposure is authored as **`PressureZone` nodes** (promoted from
`main.tscn`'s `LevelZones`), blended smoothly with a spawn→beacon distance fallback. It
is a **modifier, not a zero-floor** — time always matters; the island shapes how cruel it
becomes.

Live coordinate authority: `godot/scenes/main.tscn` is the current blockout source for
marker positions. The scene's header documents the promoted route blockout; the
`LevelZones` nodes at the end of the scene carry the live marker coordinates. Values
below are descriptive snapshots for implementation orientation, not a separate layout
source.

Initial zone mapping (live `LevelZones` markers → roles; exposure is the authored knob,
tune live):

| Marker (today) | Role | Spine beat | Exposure |
|---|---|---|---|
| `SouthLandingZone` (`Vector3(0, 0, 17)`) | `spawn` | warm origin / hearth | very low |
| `EastGearAlcoveZone` (`Vector3(18, 0, -4)`) / `WestScrapAlcoveZone` (`Vector3(-20, 0, -4)`) | `spur` / `branch` | discernment branch (Brasswind / Rustchain previews) | medium / medium-hot |
| `CentralGearPlazaZone` (`Vector3(0, 0, -12)`) | `landmark` | gear-henge memory | medium |
| *(add)* `SanctuaryAnchor` near `SanctuaryBreath` (`x ≈ 15, z ≈ -31`) | `sanctuary` | breath before the Beacon | relief (`relief_multiplier`) |
| `NorthBeaconDaisZone` (`Vector3(0, 0, -42)`) | `beacon` | cold Beacon | high → peak during `Rekindling` |

**Anchor ↔ zone (one place, two readings).** The required *gameplay* anchors the baker
emits (ADR 0008) sit **inside** these exposure zones — there is **one beacon node, not
two**: the **`ObjectiveBeaconAnchor`** (rekindle trigger) is co-located at / promoted from
`NorthBeaconDaisZone`; the **`SanctuaryAnchor`** is the `sanctuary`-role zone;
**`PlayerSpawn`** sits in `SouthLandingZone`. The `PressureZone` is the exposure field; the
anchor is the interaction it sits in.

Canon: *"The island tells the director how dangerous each place is."*

Current scene note: `main.tscn` already contains a `LevelCollision` layer for player
collision and a `DesignProbe_ExposureRanks` visual legend. The legend is explicitly
non-shipping; do not convert it into player-facing UI or an exposure meter.

## 5. Survival: guard over HP (ADR 0007)
Recoverable **guard / shield** over **fixed mortal HP**. Damage hits guard first; HP is
one-way attrition. Guard recharges after a damage-delay; the Sanctuary shortens the delay
/ boosts the rate; recovery is capped; the rising `pressure_clock` defeats camping. If too
large for the first commit, ship Sanctuary as **relief-only** with the recharge seam named
— never bake "sanctuary heals HP." Canon: *"The Sanctuary does not undo mortality; it lets
Gizmo regain his protective light before pushing back into danger."*

## 6. Navigation & containment (ADR 0006)
The sim owns a **`WalkableRegion`** (authored XZ island footprint). Ring-spawns validate
(sample → reject out-of-region → reject obstacle overlap → nearest-valid fallback);
enemies soft-clamp inside post-move; obstacles stay push-out circles; **no scene
navmesh**. Swarm bunching is accepted for Path A. Verticality is **presentation, not
traversal**: cliffs, waterfalls, hanging chains, lower islets, spires, gear henges,
bridges-over-void — bridges behave as **flat connectors**; nothing walkable occludes
Gizmo, so the fixed Diablo camera needs no occlusion work. Canon: *"The island owns where
combat may exist; the sim still owns how the swarm moves."*

## 7. HUD / player-facing (ADR 0005)
- **Guard-over-HP:** cyan/teal recoverable guard bar above a smaller warm mortal HP bar.
- **Objective cue:** "Reach the Beacon" / "Rekindle the Beacon" + subtle world-space
  beacon glow / direction marker. No heavy minimap or distance UI yet.
- **Rekindle indicator:** appears only near/inside the Beacon radius —
  `Dormant → Rekindling → Rekindled` + channel fill.
- **Keep** Level / Sparks / XP (the future Core Matrix runway).
- **No player-facing countdown. No exposure/danger meter** — pressure is *felt* through
  swarm density, audio, and zone mood.
- **End-screen:** win = "Beacon Rekindled"; lose = "Gizmo's light failed" — not "time
  survived." Canon: *"The HUD no longer asks 'how long can you last?' It asks 'can you
  carry your guarded light to the Beacon and rekindle it?'"*

## 8. Authoring pipeline (ADR 0008)
Image refs → Meshy kit → Blender cleanup → Godot wrapper scenes (metadata) → Python baker
(approved pieces only) → validators → human curation. The baker is a **stagehand**: it
places approved kit pieces from a recipe, emits `WalkableRegion` + `PressureZone`s +
anchors, and writes a **manifest JSON** (recipe version, asset ids + transforms, zones,
footprint, soundtrack cue ids, validation results). It must not call AI/Meshy, decide
beats, invent landmarks, overwrite curated nodes, or ship an unvalidated/untraceable
scene.

**Validators (gate every scene):** reachable anchors · camera readability · enemy pressure
does not trap spawn · clear loopback · one visible landmark at most major sightlines · no
player-facing round counter. **Five acceptance questions per scene:** which visual refs;
which soundtrack cues; what three visible choices came from those cues; did they improve
readability; did any mood choice harm clarity?

## 9. Soundtrack as mood grammar (real files)
Use the composition `.md` as **mood grammar, not fake audio analysis**. The composer's
12-segment arc already traces this spine. Cue ids map to **real source files** under
`/home/ark/gizmo-audio-canon/sources/soundtrack/`:

| Spine beat | Mood cue (real file) |
|---|---|
| Spawn / awakening | `1.1-Clockwork_Heartbeat.mp4`, `1.2-Sunlight_on_Brass.mp4` |
| First steps / roam | `2.1-Clockwork_Wanderer.mp4`, `2.2-The_Brass_Sentinel.mp4` |
| Gear plaza / landmark (gear-henge) | `4.1-Brass_Pendulum.mp4`, `4.2-The_Gearbox_Prayer.mp4` |
| Trial / late pressure | `9.1-Before_the_Beacon_Falls.mp4`, `9.2-Turning_the_Clockwork_Key.mp4` |
| Sanctuary | `Ambient-B-Map-Sanctuary_of_Fallen_Stars.mp4` |
| Beacon approach | `10.1-The_Final_Ascent.mp4`, `10.2-Steps_Toward_The_Beacon.mp4` |
| Pre-beacon room | `final-room-ambient.mp4` |
| Rekindle siege | `11.1-The_Iron_Threshold.mp4`, `11.2-Clockwork_at_the_Gate.mp4` |

> The "wave" wording in the older composition notes predates the no-wave correction
> (ADR 0003): take the **mood**, not the wave framing.

## 10. Out of scope / deferred
- **World-emitter `EnemyPressureAnchors`** — stubbed as data the exposure field reads;
  emitter spawning is a later upgrade.
- **Core Matrix draft** — the Sanctuary is reserved as its future home; not built here.
- **Path B** (connected/streamed islands), gentle multi-level walkable tiers, jumping/
  platforming.
- **Procedural reroll** — permitted only *later* and only for *peripheral / non-spine*
  dressing (side-pocket props, scatter, optional caches). The spine, landmarks, anchors,
  and curated beats are **never** rerolled (Q2; ADR 0008).
- **Spark-of-Humanity fuel** for the rekindle — neutral until ADR 0001's pending pass.
- A guardian/boss at the Beacon — the swarm-at-peak is the Path A boss; (c) bespoke
  guardian is the named later upgrade.

## 11. Decision index
| Q | Decision | Pinned in |
|---|---|---|
| Q1 / Q6 | Traverse-to-Beacon; rekindle channel; win = rekindled, lose = HP 0; `pressure_clock` fuels not wins | ADR 0005 |
| Q2 | Authored frozen scene is the author; procedural is a brush | ADR 0008 |
| Q3 | Flat combat layer + non-walkable vertical scenery; fixed camera intact | §6 |
| Q4 | Directed, explorable spine | §2 |
| Q5 / Q7 | Place-aware pressure via authored `PressureZone`s | ADR 0006 |
| Q8 | Guard over fixed HP; sanctuary recharge | ADR 0007 |
| Q9 | Walkable region in the sim; no navmesh | ADR 0006 |
| Q10 | Stagehand baker + manifest + validators + soundtrack mood grammar | ADR 0008 |
| Q11 | Guard-over-HP HUD; objective cue; rekindle indicator; no clock/exposure meter | ADR 0005, §7 |

## 12. Canon phrases (preserve verbatim)
- *The swarm follows Gizmo, yet the island decides how cruel the swarm becomes.*
- *The Beacon is not a finish line; it is a hearth that must be rekindled while the cold
  world pushes back.*
- *The island owns where combat may exist; the sim still owns how the swarm moves.*
- *The baker is a disciplined stagehand.*
