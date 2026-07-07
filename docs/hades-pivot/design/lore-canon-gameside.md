# Lore canon — game-side promotion

Game-side reference for the lore the world speaks to the player. Promotes the lab
canon (`gizmo-lore/canon/saints-of-the-church.md`, `.../world-structure.md`) into the
code seams that carry it, so core/design/asset lanes can wire correctly without
reading lab canon. **The lab canon is source; this note is the derived map** — if the
two disagree, lab canon wins and this note is recut.

Provenance: promoted 2026-07-07 (night lore lane, revival wave). Derived from lore
canon; do not edit as source.

---

## 1. The Reverence Law (gate-grade; governs every saint surface)

The benefactor saints are **venerated icons of the church militant** — real saints,
remembered inside the vigil. They are the human inheritance Gizmo keeps. A saint never
grants, sells, buys, scales, summons, or fuels anything: keepsakes and boons are
**kept memories that steady Gizmo's own workings**, remembrance and example, never
intercession-as-fuel.

A surface hitting any of these is recut, not shipped:
- saint names in combat barks, damage text, or humour copy;
- liturgical text, scripture, or paraphrased hagiography in any player-facing string;
- "summon / unlock / buy / equip" a saint; saints as pets, turrets, vendors;
- jokes in a saint's mouth or at a saint's expense;
- "the saints bless your build / run" or any piety-as-power framing.

Runtime surfaces lead with the **role-title** (`the Bearer`). The full saint name
appears only on **ceremony surfaces**: first meeting, keepsake-offer panel, codex
entries, hub icon plaques.

Saint speech register: blessing, counsel, witness. Short, calm, warm. The saint
addresses Gizmo's duty ("keep it"), never the build. Saint VO obeys: ≤12 spoken words;
sentence case; second person allowed but "little keeper" is **Margin's** word alone —
saints say "keeper" or "bearer of the spark". The Company speaks only as "we".

## 2. Saint roster → code seams

Five active `saint_role` ids. Each is present in the hub as an icon shrine
(`scenes/npcs/saint_shrine.tscn`, instanced in `scenes/hub.tscn`) and voiced through
`AudioDirector.play_voice_line`. VO id shape: `saint_<role>_meeting`,
`saint_<role>_offer` (variants `_1.._3`), `saint_<role>_threshold`.

| `saint_role` | ceremony name | keepsake family (fiction) | hub shrine node | VO register |
|---|---|---|---|---|
| `bearer` | Saint Christopher | carrying-through-hazard: dash, guard-while-moving, weight-borne | `ShrineBearer` | deep, slow, river-worn; outsider gentleness |
| `hearthguard` | Saint Demetrios of Thessaloniki | guard, mending, homecoming, sanctuary | `ShrineHearthguard` | steady young-commander warmth |
| `swordbearer` | Saint Mercurius of Caesarea | melee strike, riposte, high-commitment | `ShrineSwordbearer` | bright ringing steel; brisk, disciplined |
| `marksman` | Saint Theodore Stratelates | ranged precision, marked-threat | `ShrineMarksman` | measured, precise, quiet authority |
| `company` | the Forty Martyrs of Sebaste | last-stand, near-death, shared-strength | `ShrineCompany` | small unison chorus; always "we" |

Plaque titles (verbatim, on `SaintShrine.display_title`): `the Bearer - Saint
Christopher`, `the Hearthguard - Saint Demetrios`, `the Swordbearer - Saint Mercurius`,
`the Marksman - Saint Theodore`, `the Company - Forty Martyrs of Sebaste`.

**Reserved, not in the five:** Saint George — capstone figure, held for a future
climactic role (never a utility slot). Ruler-saints (Alexander Nevsky, Dmitri Donskoy)
— separate sanctity category, candidate hub-keeper figures only, never benefactors.

**Open for Shane** (lab canon §2): confirm the five namings, and whether Saint George's
reserved capstone becomes a sixth role or a story figure.

## 3. Region dialects → code seams

Margin speaks one line the first time each region is entered, fired from
`run_orchestrator.gd` AUDIO region (`_maybe_speak_region_entry`, one line per region
per run) as `margin_region_<region_id lowercased>`. Region identity is
`RegionTable.REGIONS` (`scripts/room_graph/region_table.gd`). Each line carries its
region's landmark character.

| `region_id` | display name | landmark | VO id | dialect line |
|---|---|---|---|---|
| `HEARTH` | Hearthwake Basin | The Heart Spire | `margin_region_hearth` | "Hearthwake. Every keeping starts warm. Go while it lasts." |
| `BRASS` | Brasswind Highlands | The Chronarch Keep | `margin_region_brass` | "Brasswind. The keeps still count hours no one lives." |
| `VERDANT` | Verdant Archive | The Memory Tree | `margin_region_verdant` | "The Archive grows. Trees remember gentler librarians." |
| `PRISM` | Prism Reach | The Nebula Prism | `margin_region_prism` | "Prism Reach. Light here forgets which way it was going." |
| `TEMPEST` | Tempest Verge | The Storm Engine | `margin_region_tempest` | "The Verge. The storm engine never learned to rest." |
| `NULL` | The Null Crown | The Last Ember | `margin_region_null` | "The Null Crown. Hold your light close now, little keeper." |
| `RUST` | Rustchain Expanse | The Titan Yard | `margin_region_rust` | "Rustchain. The titans slept before they were finished." |
| `ASH` | Ashfall Foundries | The Ember Crucible | `margin_region_ash` | "Ashfall. The crucible remembers every shape it gave." |

Run spine routes (`RegionTable`): upper = HEARTH→BRASS→VERDANT→PRISM→TEMPEST→NULL;
lower = HEARTH→RUST→ASH→TEMPEST→NULL.

## 4. Physical presence law

Saints are present in the hub **as icons** — a shrine/icon body, not a walking NPC.
Interaction is veneration + address: the remembered witness speaks. **Margin is the
only conversational hub character**; saints do not do smalltalk, shopkeeping, or
quest-giving. The Custodian never personally appears — the boss is titled **THE
PATTERN** on screen; the pattern speaks through the vessel.

## 5. Where each truth lives

- Reverence Law, roster, voice law: `gizmo-lore/canon/saints-of-the-church.md` (source).
- Saint VO scripts: `docs/hades-pivot/design/voice-scripts-v2-saints.md`.
- Threshold + region scripts: `docs/hades-pivot/design/voice-scripts-v3-thresholds.md`.
- Voice seam + manifest: `godot/scripts/audio/audio_director.gd` (VOICE region).
- Shrine behaviour: `scripts/npcs/saint_shrine.gd`; hub placement: `scenes/hub.tscn`.
- Region identity: `scripts/room_graph/region_table.gd`; firing:
  `scripts/room_graph/run_orchestrator.gd` (AUDIO region).
</content>
