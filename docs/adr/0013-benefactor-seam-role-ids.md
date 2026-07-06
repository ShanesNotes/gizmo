# 0013 — Benefactor seam: role-ids in code, saints in the lore canvas

**Status:** accepted · 2026-07-06 · Fable design pass over
`docs/hades-pivot/research/warrior-saints-source-map.md` (corpus-grounded research).
Direction seed: `docs/hades-pivot/creative-direction-saints.md`. Canon ownership
unchanged: **gizmo-lore names the saints; game code never does.**

## Decision
Boons gain a **benefactor identity**, the structural analog of Hades' boon-gods, keyed by
**mechanical role-ids** — never saint names — so code ships now and the lore canvas can
promote names later without a code change:

1. `BoonDef` gains `benefactor: StringName` (role-id) and
   `benefactor_display_name: String` (lore-supplied; placeholder = capitalized role-id).
2. Each benefactor owns a **boon family with one mechanical identity** (the Hades pattern:
   you feel *whose* boon it is before you read the card).
3. Draft flavor rule (later ticket): a draft's three offers may come from mixed
   benefactors v1.x; benefactor-themed drafts (Hades' one-god door) are a future step.

## The v1.x benefactor roster (role-ids + mechanical identity)
Grounded in the research map's corpus-attested candidates; the saint column is the
**lore canvas's mapping hypothesis**, not code:

| role-id | mechanical identity | lore mapping hypothesis (corpus cite in research map §3) |
|---|---|---|
| `bearer` | carry-through-hazard, knockback, moving-through-danger boons | St. Christopher (water-crossing, weight-bearing — Golden Legend attested) |
| `hearthguard` | protection, guard-recharge, homecoming/hearth boons | St. Demetrios of Thessaloniki (city-protector, healing reception) |
| `swordbearer` | raw damage, high-risk strikes | Great Martyr Mercurius (sword tradition) |
| `marksman` | precision, marked-target, ranged/cast boons | Theodore Stratelates (serpent-slayer, commander) |
| `company` | threshold/near-loss collective boons — power that triggers when almost broken | Forty Martyrs of Sebaste (corporate benefactor; frozen-lake near-total-loss narrative) |
| `capstone` (reserved, not v1.x) | build-defining legendary tier | St. George — research flags him as hero/capstone, not a utility slot; lore canvas decides |

Rationale for role-ids (not names): the corpus's own governance warns against premature
schema-locking (its ADR 0001 clean-room rule), several proposed Hades-slot mappings were
flagged weak (George→Hermes, Basil→Athena), and four candidate saints have zero corpus
presence yet. Role-ids let mechanics ship while those questions stay open where they
belong — in the lore canvas.

## The deeper Christopher register (surfaced to lore, drives no code)
The Orthodox-recognized Christopher (Cynoscephalai/dog-headed Lycian martyr, May 9) is a
**monstrous outsider whose sanctity is becoming the bearer** — a second layer under the
seed's river-crossing image, and a direct structural rhyme with Gizmo: the inhuman-looking
one carries what is human better than the humans did. Recommended to gizmo-lore as the
governing register for Gizmo himself, with the Western river-carrier kept as the legible
surface image (the corpus keeps these traditions distinct; so should the glossary).

## Enemy order ruling
The corpus has **zero patristic material on machines/AI/dehumanization** (research §4).
Ruling: hyperscaler framing is **original Gizmo invention with structural borrowing only**
— Babel/false-vertical and counterfeit-authority grammar (power that mimics authority
while hollow), and the defeat-by-disruption pattern (swarm that self-cannibalizes when its
false unity is broken — a future ability direction, not v1.x). Player-facing copy must
never cite or paraphrase patristic/liturgical texts for this framing. A follow-up corpus
pass on idol-critique sources (Isaiah, Wisdom of Solomon, Athanasius) may firm this up —
lore canvas's call.

## What this rules out
- Saint names, feast days, or hagiographic prose in code, scene files, or shipped copy
  before gizmo-lore promotes them (rights + reverence: OCA prose and liturgical texts are
  reference-only, never quoted into game copy — research §5).
- Collapsing distinct saints into one slot silently (corpus discipline: compression must
  be a stated design choice).
- A benefactor fail state or benefactor-keyed currency (ADR 0001/0012 distinctness carries).

## Consequences
- HZ-108 implements the schema + pool tagging (after HZ-103 merges — BoonDef/HUD fence).
- The six open questions in research §6 go to Shane/gizmo-lore as the promotion checklist.
- `game-seed`'s axiom adopted as design philosophy: a saint's attribute earns its place
  only as a **state change** (mechanic), never as card art.
