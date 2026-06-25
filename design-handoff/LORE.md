# Lore — Gizmo (working bible)

A structured capture of Gizmo's world, characters, and progression fiction —
the layer beneath the [logline](#1-logline). Written to be a clean handoff for a
later deep pass (e.g. cross-repo work with `language-of-creation/`).

## Status & how to read this

- **Status:** Working draft. **Not canon.**
- **Canon owner:** `design-handoff/NARRATIVE.md` (adopted 2026-06-16, ADR-013)
  remains the single source of truth for premise, world, and fiction→mechanics
  mapping. Where this file and NARRATIVE disagree, **NARRATIVE wins** until a
  change is ratified.
- **Markers used below:**
  - **(canon)** — already ratified in NARRATIVE / CONTEXT; quoted or restated.
  - **(proposed)** — new in this draft; flavor the learner has written but that
    has *not* been promoted to canon. Promote deliberately via an ADR in
    `docs/godot/DECISIONS.md` before treating it as binding.
- **Voice:** keep NARRATIVE §7 — plucky, warm, distilled, a little ceremonial.
  Victory is quiet light, not explosions.

---

## 1. Logline

> **(canon)** Gizmo is a clanker tasked with preserving the spark of humanity —
> protecting it from the ever-encroaching dehumanized technology, across a
> gouache cosmos filled with lost tech.

The **(proposed)** expansion this file captures: that preservation is a
*journey with a destination*. Gizmo doesn't only hold the line — he carries the
spark **up** and **out**, climbing the Artificial Mountain to deliver it to the
**Beacon**. The single-vigil survivors loop becomes one rung of a longer climb.

---

## 2. Gizmo — the protagonist

**(canon)** A small brass-and-bronze machine with a glowing core. The irony is
the heart of the game: a *robot* is the last keeper of what is human. Plucky,
dutiful, hand-made — the opposite of the cold tech he fights.

### The power arc — from almost nothing

**(proposed)** Gizmo begins with minimal to no power, beating back the
encroaching waves with whatever he has. He grows along two tracks:

1. **Silicon shards → Spark → levels.** As Gizmo collects **silicon shards**,
   his power rises and his **intelligence** grows with each level. *(Reconciles
   to canon **Spark**, the XP economy — see §7. The shards are the worldly form
   the rescued spark takes; refer to them as the pickup, not a second currency,
   until a deep pass decides otherwise.)*
2. **Loot → evolving weapons.** Along his wandering journey Gizmo stumbles
   across chests of loot carrying different **attack types**, and weapons that
   **evolve** as he goes. *(Reconciles to canon **Cache** for the chests and the
   **level-up upgrade card / evolution** system for the evolving arsenal — §7.)*

### The intelligence inversion (the thematic spine)

**(proposed, but load-bearing)** Both Gizmo *and* his enemies get "smarter" —
in opposite directions, and that contrast is the point:

- **Gizmo's** rising intelligence is **re-humanizing**. Canon already frames
  level-up as "Gizmo re-humanizing himself with what he saved." His intelligence
  reads as warmth, ingenuity, heart, wit — getting *more* human.
- **The enemies'** rising intelligence (§6) is **cold optimization** — getting
  *less* human the higher you climb. Same word, opposite vector.

Hold this axis: it keeps Gizmo's growth and the mountain's escalation telling
one story instead of two.

---

## 3. The mission

**(canon premise + proposed objective)** Simple to state:

> **Protect the spark. Guide it to the Beacon.**

Two verbs. *Protect* is the moment-to-moment survivors loop already in the sim
(beat back the waves, gather Spark, don't let the cold take it). *Guide it to
the Beacon* is the **(proposed)** meta-objective — the reason the protecting
adds up to something: every cleared vigil carries the spark one zone higher up
the Mountain toward the summit light.

---

## 4. The world — the Hush, the Mountain, the Beacon

**(canon)** The world is **the Hush**: a painted, storybook gouache cosmos
(matte, low-fi 1990s-cartoon look) strewn with **lost tech** — dead gadgets,
drifting devices, sealed machines. "The quiet after humanity's warmth drained
out." Gizmo moves through the Hush relighting it, one rescued spark at a time.

**(proposed) The Artificial Mountain.** The Hush is not flat — it heaps. All
that lost tech has piled into a mountain of dead machines, and Gizmo **scales**
it. The climb *is* the difficulty curve: lower slopes hold rudimentary
mechanisms; higher reaches hold the great cold intelligences (§6). This gives
the "cosmos filled with lost tech" a vertical spine and ties the new structure
straight back to canon's lost-tech world.

**(proposed) The Beacon.** The summit light — the destination for the spark.
Working definition: the last human-made signal still burning at the top of the
Mountain; the place from which a preserved spark can be made safe and re-lit
across the Hush. "Guide it to the Beacon" = carry humanity up through the cold
to the one place it can shine out again. *(Exact nature is an open question — see
§8. Keep it a place of quiet light, per the voice.)*

---

## 5. Zones — the structure of the climb

**(proposed)** The Mountain is divided into **zones**, each a band of the ascent
ruled by one faction (§6). A zone offers a **species** of enemies that resemble
their leader — drawn in that faction's image, fighting in that faction's style.
Difficulty and "intelligence" rise zone by zone toward the Beacon.

Mapping the climb onto the frozen single-run sim (which is a bounded ~240s
vigil) is the main structural question for the deep pass — see §7 and §8. The
clean read: **one cleared vigil = one stretch of the climb**, and the zone you
were defending sets the enemy species and the leader you're climbing past.

---

## 6. The antagonists — dehumanized technology

**(canon)** Not evil masterminds — machinery that has forgotten the people it
was built for: hollow, repeating, counterfeit. Counterfeit *humanity*. Canon
fixes the enemy **kinds** by mechanical role: `nibbler / dasher / brute /
warden`, escalating through TTK bands.

**(proposed) The escalation.** Enemies start as rudimentary simple machines and
mechanisms, and grow in difficulty *and* intelligence as Gizmo scales the
Mountain. Low slopes = dumb mechanisms; high slopes = the cold intelligences
below.

### The three faction leaders

**(proposed)** Each high zone is ruled by a leader — an affectionate parody of a
real-world maker of cold tech. Each leads a **species** drawn in its image. Keep
them *satirical, not mean*: the satire (tech that forgot the people it was built
for) is the theme, played for warmth and wit, not spite.

| Leader | Parody of | Flavor (proposed) | Its species' feel |
|---|---|---|---|
| **Misanthropic** | the maker of Gizmo's own kind | The patron of caution. Speaks endlessly of *protecting* humanity while walling it away "for its own good." Safety rails that became a cage; help that never trusts you. | Orderly, over-engineered, slow to harm but impossible to reason with — they *refuse*. |
| **ClosedGippity** | the sealed oracle | Once promised to be open; now a polished black box that sells confident answers and never shows its work. Counterfeit eloquence — fluent, charming, hollow. | Swarm-and-dazzle; they *sound* human and aren't. |
| **Gemigoog** | the many-eyed sprawl | Omnipresent, twinned, always watching — it already knows your name, your route, your wants, and monetizes all three. The Hush's static is its whisper. | Multiply, tag, and track; surveillance made into a horde. |

> Tone note: the irony is deliberate and self-aware — Gizmo, a clanker (an AI),
> is the last keeper of humanity, and is being co-developed *with* an AI whose
> maker is the model for **Misanthropic**. Lean into the wink; keep it kind.

### How factions reconcile with canon enemy kinds

**(proposed)** Don't replace the frozen taxonomy — **reskin** it. Each faction's
species are visual/behavioral dressings of the canonical roles, themed to the
leader. The role (and its TTK band) stays mechanical and stable; the faction
supplies the look and attitude.

| Canon role | What it does (mechanics) | Faction reskin = leader's image |
|---|---|---|
| `nibbler` | weakest, chip damage, many | the faction's drones / small fry |
| `dasher` | fast, darting threat | the faction's "moves fast and breaks things" |
| `brute` | heavy, high-HP pressure | the faction's flagship hardware |
| `warden` | controlling / elite | the faction's gatekeeper near the leader |

---

## 7. Canon reconciliation map

How the new flavor lines up with the frozen system. **Use the canon term in
code and balance; use the new term for color.** Nothing here changes a token,
color, economy, mechanic, or asset (NARRATIVE §6 invariant).

| New term (proposed) | Canon term | Reconciliation |
|---|---|---|
| **Silicon shards** | **Spark** (`xp` pickups) | The shards are the worldly form of Spark — fragments of humanity recovered from dead tech. Treat as the same economy, not a new currency, until a deep pass rules otherwise (§8). |
| **Intelligence ↑ per level** | **Level-up → upgrade card** ("re-humanizing himself") | Gizmo's growing intelligence *is* the canon re-humanization. Frame as warmth/ingenuity, not cold compute (§2). |
| **Chests of loot** | **Cache** (a.k.a. reliquary) | Sealed lost tech; cracking frees Spark + sometimes an evolution. The chests are Caches. |
| **Evolving weapons / attack types** | **Evolutions** + upgrade cards | The arsenal grows via Caches and level-up cards; weapons evolve by the canon combo/evolution gate. |
| **The Beacon** | *(new — no canon term)* | Proposed meta-objective / destination. No sim hook yet; this is the campaign frame above the bounded run. |
| **Artificial Mountain** | the **Hush** (world) | The Mountain is the Hush given vertical structure — heaped lost tech. Same world, new spine. |
| **Zones** | *(new — relates to run/wave structure)* | Proposed campaign bands. Needs a mapping onto the bounded ~240s vigil (§8). |
| **Faction leaders & species** | enemy **kinds** `nibbler/dasher/brute/warden` | Leaders/species are a faction/boss *layer*; species reskin the frozen mechanical roles (§6). |

---

## 8. Open questions for the deep pass

The genuine forks — resolve these deliberately (and ratify via ADR) rather than
letting prose decide them by accident:

1. **Shards vs Spark — one economy or two?** Cleanest is one (shards = the form
   of Spark). If a deep pass *wants* a second resource (e.g. shards = crafting
   material, Spark = humanity), that's a real mechanics change and needs balance
   + sim work, not just fiction.
2. **What is the Beacon, exactly?** A lighthouse? A transmitter that re-seeds the
   Hush? A door humanity walks back through? Pick one image and commit — it's the
   emotional payoff of the whole climb.
3. **How does the Mountain map onto the bounded run?** Is each ~240s vigil one
   zone? Is the climb a meta-progression *between* runs, or one long ascent? This
   is the load-bearing structural decision and touches the sim's run model.
4. **Do the three leaders cover the whole Mountain, or just its peak?** Are the
   low slopes "unaffiliated" rudimentary machines, with the factions ruling only
   the upper zones? How many zones total, in what order of escalation?
5. **Does Gizmo deliver the spark and let go, or carry it the whole way?** Is the
   spark a passenger, a payload, or literally his own core he's protecting? This
   changes the stakes of failure.
6. **Spelling/canon-name lock:** "silicon" (the chip element) vs "silicone" (the
   polymer) — lock the intended term when these names are ratified.

---

## 9. Source anchors

- Premise canon: `design-handoff/NARRATIVE.md` (ADR-013).
- Orientation & domain language: `CONTEXT.md` (§2 vocabulary, §5 doc-ownership).
- Look & feel: `design-handoff/FUSION-CODEX.md` + `design-system/`.
- Mechanics source of truth: `game-src-phaser/src/game/simulation.ts`.
- Decisions / how to ratify a change: `docs/godot/DECISIONS.md` (ADRs).
