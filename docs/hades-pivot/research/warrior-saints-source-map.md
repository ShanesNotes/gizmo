# Warrior Saints Source Map — research pass for the Gizmo Hades-pivot lore upgrade

Status: research only, not canon. This is a map of what `/home/ark/language-of-creation/`
(hereafter "LOC corpus") actually contains on St. Christopher, warrior saints, and the
symbolic-lens method, gathered so the principal agent can wire the Gizmo lore upgrade
without re-reading the corpus. Canon authority for names/theology/copy stays with
`gizmo-lore` (see `~/gizmo-hades/docs/hades-pivot/creative-direction-saints.md`, which
this document supports but does not supersede). Every claim below is cited to a file path;
where the corpus is silent, that is flagged explicitly as a gap rather than filled in from
general knowledge.

---

## 1. Corpus geography

Where the relevant material actually lives, one line each:

- `corpus/orthodox/topic_guides/warrior_saints/` — the dedicated warrior-saints navigation
  guide (14 JSONL route files + `README.md` + `source_plan.yaml`). This is the single most
  important directory for this research; it is purpose-built for exactly this kind of
  question.
- `corpus/orthodox/topic_guides/warrior_saints/christopher_cynocephalus_source_routes.jsonl`
  — everything the corpus has stratified specifically on St. Christopher (8 source routes:
  OCA recognition, Greek martyrdom candidate, Latin passion candidate, apocryphal
  Christomaios parallels, Copto-Arabic synaxarion, Walter of Speyer).
- `corpus/orthodox/topic_guides/warrior_saints/official_recognition_roster.jsonl` — the OCA
  recognition roster for 13 ancient military martyrs (George, Christopher, Demetrios,
  Nestor, both Theodores, Mercurius, Procopius, Menas, Eustathius, Forty Martyrs, Andrew
  Stratelates), each with feast day and a one-line "military_relevance" tag.
- `corpus/orthodox/topic_guides/warrior_saints/golden_legend_warrior_section_index.jsonl`
  and `golden_legend_routes.jsonl` — exact line-span pointers into the already-local Golden
  Legend text (`sources/orthodox/classics_witnesses/works/medieval/latin/jacobus-de-voragine/the-golden-legend/text.md`)
  for Sebastian, Longinus, George, Victor/Corona, Christopher, Maurice/Theban Legion,
  Eustace/Placidus, Theodore, Demetrius — Western parallel witness only, explicitly marked
  non-governing for Orthodox claims.
- `corpus/orthodox/topic_guides/warrior_saints/ruler_warrior_recognition_review.jsonl` —
  Alexander Nevsky and Dmitri Donskoy as a *distinct* "right-believing warrior-ruler"
  category, separate from martyr-soldiers.
- `corpus/orthodox/topic_guides/warrior_saints/liturgical_source_campaign.jsonl` — the
  Synaxis of All Military Saints (July 8, set by 2019 Ecumenical Patriarchate synod) and
  the open Menaion/service-text campaign; almost entirely blocked-by-rights candidates.
- `corpus/orthodox/topic_guides/warrior_saints/local_witness_index.jsonl`,
  `prepared_witness_routes.jsonl`, `patristic_excerpt_routes.jsonl`,
  `body_witness_review.jsonl`, `sozomen_forty_martyrs_relic_routes.jsonl`,
  `david_scripture_navigation.jsonl`, `david_patristic_extension_routes.jsonl`,
  `anglo_saxon_source_candidates.jsonl` — supporting lanes (David/Psalter material, Forty
  Martyrs patristic reception via John of Damascus and Peter of Damaskos, Sozomen's relic
  history, Anglo-Saxon parallel candidates). Mostly rights-gated candidates, a few
  manifested local excerpts.
- `sources/orthodox/patristics/` and `sources/orthodox/classics_witnesses/` — the actual
  prepared text bodies the routes above point into (patristics organized
  author/work/chapters; classics witnesses are full public-domain works incl. the Golden
  Legend).
- `corpus/orthodox/by_saint.md` / `by_lane.md` — indices of patristic **authors** (Basil,
  Athanasius, Chrysostom, etc.), not saint-*subjects*; useful for finding writings *by* a
  father, not lives *of* a warrior saint. Don't confuse this with the warrior_saints topic
  guide.
- `corpus/pageau/chapters/` (84 chapters) + `wiki/concepts/`, `wiki/sources/` — the Jonathan
  Pageau "Language of Creation" symbolic-method material. This is where the corpus's
  theory of *how to read symbols at all* lives (see §5). Chapter 29 covers Noah's sons and
  Babel/Nimrod geography but the corpus has **no chapter specifically on Babel-as-technique
  or dehumanization** (see §4 gap note).
- `game-seed/` — a **different, adjacent project**: an Old Testament (King David-centric)
  roguelite built on this same corpus. Its `design/MASTER_ARC.md`, `design/acts/act-4-rule.md`,
  and `research/symbolic-world-grammar.md` are not Gizmo canon, but they are the corpus's
  most fully-worked example of turning Babel/counterfeit-authority/dehumanization patterns
  into *roguelite mechanics*, so they're cited in §4–5 as transferable method, clearly
  marked as borrowed, not Gizmo lore.
- `.scratch/repo-maintenance/issues/02-decide-warrior-saints-private-custody.md` — a closed
  housekeeping ticket confirming the warrior-saints topic-guide files are private-substrate
  (git-ignored-by-default, narrow exceptions carved out) and only privacy/custody handling,
  not source content.

---

## 2. The St. Christopher pattern

### 2.1 What the corpus actually has

The corpus does **not** have a prepared, ingested body text of any Christopher life yet.
What it has is a *rights-stratified map* of candidate sources
(`corpus/orthodox/topic_guides/warrior_saints/christopher_cynocephalus_source_routes.jsonl`),
each row tagged with `body_status` and `rights_status`. Laid out in priority order the
corpus itself assigns:

1. **OCA official recognition** (`christopher-oca-cynoscephalai-recognition`) — Martyr
   Christopher of Lycia, with the Martyrs Callinika and Aquilina, feast **May 9**.
   `body_status: not_ingested_rights_blocked`. Route value: "Use for Orthodox title, feast,
   and companions, and the dog-headed/Cynoscephalai identity marker without importing body
   prose." The corpus explicitly forbids quoting OCA body text — recognition metadata only.
   Same roster entry repeated at `official_recognition_roster.jsonl` line `oca-st-christopher`:
   *"martyr; Cynoscephalai or dog-headed tradition; soldiers converted in the martyrdom
   cycle."*

2. **Greek Martyrdom candidate, BHG 309–310c** (`christopher-greek-martyrdom-bhg-309-310c-candidate`)
   — cited as *S. Christophori martyris Acta graeca antiqua, Analecta Bollandiana 1 (1882),
   pp. 121–148*. Not fetched. Corpus flags this as "the main body-acquisition target for
   dog-headed Christopher before relying on later Western or secondary summaries" — i.e.
   the corpus considers the **Eastern dog-headed Greek tradition primary**, and Western
   versions secondary.

3. **Earliest Latin Passion, BHL 1764** — early Latin parallel, not fetched, rights unverified.

4. **Apocryphal Acts of Andrew and Bartholomew / "Christomaios"** — the dog-headed
   ("Kynokephalos") conversion-narrative family this cluster is built around: *"dog-faced
   outsider, angelic intervention, speech/conversion, apostles' fear, missionary aid,
   violent animal imagery, repentance, baptism, and church-order ending"*
   (`christomaios-acts-andrew-bartholomew-eclavis`). Two English translation candidates are
   named (Agnes Smith Lewis 1904 Arabic version; E. A. Wallis Budge 1899–1901 Ethiopic
   version), both public-domain candidates, neither fetched. The corpus is explicit that
   this apocryphal material is *"background/parallel, not a direct Orthodox Christopher
   life"* — do not treat Christomaios as identical to St. Christopher.

5. **Copto-Arabic Synaxarion** — a summary of the Kynokephalos episode attached to
   Bartholomew's commemoration (1 Tout), via Basset, *Patrologia Orientalis* 1 (1904). Not
   fetched.

6. **Walter of Speyer, *Vita et passio sancti Christophori martyris*** (Western Latin,
   Straub 1878 edition) — treats Christopher "as a cynocephalic outsider who undergoes
   conversion and becomes an athlete/soldier of Christ." Not fetched.

7. **Golden Legend (Western, already local, fully readable)** —
   `sources/orthodox/classics_witnesses/works/medieval/latin/jacobus-de-voragine/the-golden-legend/text.md`,
   lines 2424–2440 (`golden-legend-st-christopher-section`). This is the **only Christopher
   body text actually sitting on disk and freely quotable** in the whole corpus. It tells
   the *Western* Reprobus story: giant seeks the greatest lord to serve, serves the Devil,
   abandons him on discovering he fears the Cross, serves an anchorite instead, is set to
   ferry travelers across a river as penance, carries a heavy Christ-child across the
   water, is martyred at Lycia along with Nicaea and Aquilina. The corpus's own caution:
   *"This Western version does not center the dog-headed/Cynoscephalai tradition; use the
   OCA recognition row for that identifier."*

### 2.2 The pattern, as the corpus frames it (not invented here)

Putting the rows together, the corpus's own stratification produces this shape: the
**Orthodox-recognized identity is Christopher of Lycia, feast May 9, martyred alongside two
women converts, carrying the Cynoscephalai (dog-headed) marker** — a monstrous/outsider
figure whose recognized sanctity is that a converted outsider becomes a Christ-bearer and
martyr. The **Western river-carrier story** (the one gaming/pop culture usually means by
"St. Christopher") is a *different, later, parallel* tradition that the corpus keeps
explicitly separate and subordinate to the Orthodox recognition. Both traditions converge
on the same title, "Christ-bearer" (Christophoros), but by different routes: dog-headed
outsider redeemed into martyr-witness (Eastern), vs. giant ferryman who literally carries
the Christ-child's weight across water (Western).

### 2.3 Mapping to Gizmo

`creative-direction-saints.md` already states the seed: *"Gizmo the clanker carrying the
Spark of Humanity — the St. Christopher pattern: the bearer who carries the holy weight
across the dark water."* The corpus supports this in the *Western* register (weight-bearing
across water is literally in the Golden Legend text) but the *Orthodox-recognized* register
adds something the seed doesn't yet use: **Christopher's sanctity begins in monstrosity/
outsider-status** (dog-headed, "not human" by appearance) and is proven by *becoming* a
bearer of Christ despite that. That is a strong, corpus-attested parallel to Gizmo's
premise — *"a robot is the last keeper of what is human"* (`NARRATIVE.md` §2) — the
Christ-bearer pattern in its Orthodox form is specifically about an inhuman-looking outsider
who ends up carrying the sacred weight better than the humans around him did. This is worth
surfacing to the lore canvas as a second, deeper layer under the water-crossing image
already in the seed.

---

## 3. Candidate benefactor roster

For each Hades boon-god slot, candidate saints with what the corpus actually has (not
general knowledge), a proposed one-line boon-domain feel, and citation. **"Corpus-gap"
means: not in the corpus at all — flagged so nobody invents a patristic citation for it.**

| Hades slot | Candidate saint | Corpus evidence (patronage/iconography) | Proposed boon-domain feel | Citation |
|---|---|---|---|---|
| Zeus (sky/authority/lightning) | **St. Michael the Archangel** | Corpus-gap: no dedicated topic-guide entry for Michael found in this pass. General "Archangel" material may exist scattered in patristic works (unchecked beyond this pass). | Command/authority strikes — chain-lightning-style AoE from rank/hierarchy theme | corpus-gap: general knowledge only |
| Poseidon (sea/tidal/knockback) | **St. Christopher** | Water-crossing, river-service, carrying weight across the current — Golden Legend lines 2424–2440 | Tidal knockback / carrying-through-hazard boons (river-service as literal mechanic seed) | `sources/orthodox/classics_witnesses/.../the-golden-legend/text.md:2424-2440`; `christopher_cynocephalus_source_routes.jsonl` |
| Athena (defense/deflection/wisdom) | **St. Basil the Great** | Corpus has extensive Basil material (Hexaemeron, letters, De Spiritu Sancto) but nothing framed as "defense/deflection" — his corpus role here is pastoral/episcopal correspondence to soldiers (see §4). Not a warrior himself. | Wisdom-guard: deflect + counsel-buff feel, if the lore canvas wants a non-martial benefactor | `corpus/orthodox/topic_guides/warrior_saints/prepared_witness_routes.jsonl` (military_authority cluster rows) |
| Ares (aggression/raw damage) | **Great Martyr Mercurius of Caesarea** | OCA recognition only: *"greatmartyr; Roman army soldier; sword and martyr-warfare reception target"*, feast Nov 24. No body text ingested. | Raw sword-damage boons, high-risk/high-reward strikes | `official_recognition_roster.jsonl` (`oca-st-mercurius-caesarea`) |
| Artemis (precision/ranged/hunt) | **Great Martyr Theodore Stratelates** | OCA recognition: *"greatmartyr; general or commander; serpent-slayer tradition"*, feast Feb 8. Golden Legend has a generic "Theodore" section (lines 3896–3906) the corpus explicitly warns not to map onto Stratelates without more evidence. | Precision/serpent-slaying ranged boons (spear-throw, marked target) | `official_recognition_roster.jsonl` (`oca-st-theodore-stratelates`); `golden_legend_warrior_section_index.jsonl` (identity-caution note) |
| Aphrodite (charm/weaken/debuff) | **St. Nicholas** | Corpus-gap: no warrior-saints topic-guide entry; Nicholas is not in the military roster. If used, this slot deliberately breaks the "warrior first" pattern — a mercy/charity boon-giver, debuffing enemies via disarming charity rather than attraction. | Debuff-via-mercy (weakens aggression rather than seduces) | corpus-gap: general knowledge only |
| Dionysus (chaos/poison/frenzy/ego) | **St. Mary of Egypt** | Corpus-gap: not found in warrior-saints or by_saint indices in this pass. Her traditional arc (harlot-turned-desert-ascetic) is thematically close to Dionysian excess-into-transformation, but nothing in the corpus supports it directly. | Excess/purgation boons — frenzy that converts into an ascetic damage-over-time cleanse | corpus-gap: general knowledge only |
| Hermes (speed/utility/luck) | **St. George** | OCA recognition: *"greatmartyr; military commander; dragon or serpent miracle tradition,"* feast April 23. Golden Legend lines 1534–1558 (dragon episode, baptism of a city, renunciation of knighthood, martyrdom, relic reception, English patronage) — corpus flags this section itself as noting uncertain/apocryphal martyrdom traditions. | Given George is the most iconic warrior saint, better suited to a "hero" or capstone slot than utility/speed — flagging this mapping as a poor fit; recommend swapping George into a more central slot (see Open Questions §6) | `official_recognition_roster.jsonl` (`oca-st-george`); `golden_legend_warrior_section_index.jsonl` (`golden-legend-st-george-section`) |
| Demeter (growth/food/sustain) | **St. Menas of Egypt** | OCA recognition only: *"greatmartyr; military officer; protector in wartime reception,"* feast Nov 11, "Egyptian/pilgrimage context." No sustain/growth angle in the corpus; Menas is traditionally a pilgrimage/healing saint (ampullae) but that's outside what's ingested here. | Sustain/regen boons tied to pilgrimage-protection theme | `official_recognition_roster.jsonl` (`oca-st-menas-egypt`) |
| Hestia (hearth/home/final boon) | **St. Demetrios "the Myrrh-gusher" of Thessaloniki** | OCA recognition: *"greatmartyr; commander or proconsul; strongly tied to Nestor and later military protection memory,"* feast Oct 26. Companion Martyr Nestor, feast Oct 27, *"disciple or companion in the Demetrios cycle; combat-arena witness."* Golden Legend lines 4716–4724 (Thessalonican martyr, spear martyrdom, healing miracle reception). Demetrios's strong city-protector/healing-reception profile fits a hearth/home/final-boon role well. | Hearth-guardian / homecoming boon, healing-reception flavor (myrrh) | `official_recognition_roster.jsonl` (`oca-st-demetrios`, `oca-st-nestor-thessalonica`); `golden_legend_warrior_section_index.jsonl` (`golden-legend-st-demetrius-section`) |
| Chaos analog (the deep, formless, adversarial-but-not-evil) | **The Forty Martyrs of Sebaste**, treated as a corporate/collective benefactor rather than a single figure | OCA recognition: *"group of soldier martyrs; high-value patristic and liturgical witness target,"* feast March 9. Reception preserved indirectly via John of Damascus (`sources/orthodox/patristics/john-of-damascus/on-holy-images/chapters/chapter_001.md`, `chapter_003.md`) quoting Basil's (unrecovered) homily: praise of the Forty as *"a unified warrior company, protectors, intercessors, and ecclesial lights"* and *"an invincible army."* Also Sozomen's relic-discovery account (`sources/orthodox/reference/topic_bodies/warrior_saints/sozomen-forty-martyrs-relics/text.md`). Their martyrdom (exposure on a frozen lake, one lapsed, a guard converted to take his place) is a genuinely chaos/threshold-flavored story — a company that becomes whole again only at the point of near-total loss. | A collective, threshold-adjacent benefactor: boons that reward pushing through a near-total-loss state (a "coalition" or "Wheel" mechanic, echoing `game-seed`'s Forty Martyrs framing, see §4) rather than any single boon-god | `official_recognition_roster.jsonl` (`oca-forty-martyrs-sebaste`); `patristic_excerpt_routes.jsonl` (3 Basil-via-John-of-Damascus rows); `body_witness_review.jsonl` (`forty-martyrs-sozomen-history`) |

### 3.1 Non-warrior fits and the ruler-saint category

The corpus draws an explicit **category boundary** the lore canvas should respect: soldier-
martyrs (George, Demetrios, the Theodores, etc.) are one class; **right-believing
warrior-rulers** are a *different* class —

> *"Alexander Nevsky and Dmitri Donskoy are ruler/defender saints, not ancient military
> martyrs; their source handling should preserve ruler sanctity, military defense,
> diplomacy, and church protection as distinct facets."*
> — `corpus/orthodox/topic_guides/warrior_saints/ruler_warrior_recognition_review.jsonl`
> (`ruler-warrior-saint-category-note`)

If Gizmo wants a "final boss ally" or "throne-room" figure distinct from the boon-giver
roster (a Hades-hub-keeper analog, separate from Nyx/Persephone), Alexander Nevsky (feast
Nov 23, Neva victory + Battle on the Ice, OCA recognition only, `st-alexander-nevsky-oca-recognition`)
or Dmitri Donskoy (feast per Azbyka calendar route, Kulikovo victory, blessed by St. Sergius
of Radonezh, warrior-monks Peresvet and Oslyabya as companions, canonized 1988,
`st-dmitri-donskoy-azbyka-calendar-route`) are corpus-attested candidates for that separate
slot — neither has ingested body text, recognition-only.

**St. Basil, St. Nicholas, St. Seraphim, St. Mary of Egypt** — none of these appear in the
warrior-saints topic guide as saints-with-military-patronage. Basil appears extensively but
only as a *correspondent to soldiers* (see §4), not as a warrior-saint subject himself.
Nicholas, Seraphim, and Mary of Egypt do not appear in this topic guide at all in this pass
— genuinely corpus-gap for those three as boon-givers; do not cite patristic material for
them without a fresh search.

---

## 4. The hyperscaler enemy order — what grounds "sophistication scales with dehumanization"

This is the thinnest part of the corpus relative to what the creative-direction seed wants.
There is **no material in the LOC corpus specifically about AI, machines, hyperscalers, or
technology-as-dehumanization**. What exists is:

1. **Babel as the pattern of "false vertical" / power without heaven-given authority.**
   `corpus/pageau/chapters/ch029/reader.md` (Noah's Descendants As Microcosm) covers Nimrod,
   "mighty hunter," founder of Babel/Erech/Accad/Calneh, and frames him structurally: *"the
   descendants of Ham are kingly prototypes credited with building the first cities and
   ruling over powerful empires... This is the expression of power in contrast with
   authority."* (`corpus/pageau/chapters/ch029/reader.md`, page 93 transcript). That's the
   corpus's only direct primary-source touch on Babel, and it's about geography/genealogy,
   not technique or dehumanization per se.

2. **The `game-seed/` project (a separate OT-roguelite, not Gizmo) has already done the
   heavy lifting of turning Babel into an escalating-enemy-sophistication mechanic**, and
   it is worth borrowing as *method*, clearly marked non-canon for Gizmo:
   - `game-seed/design/MASTER_ARC.md` frames Act II's antagonist as **"the Tower-Mass /
     Risen Deep"** — *"A Babel-mass that grows by consuming your named host... You do not
     out-build it; you un-name it — sow confusion so its false unity scatters into
     trash-swarm."* This is functionally a dehumanization-as-scale mechanic already: the
     enemy is a *swarm that grows by assimilation* and the player's answer is disruption of
     false unity, not brute force.
   - The **"counterfeit-authority-antagonist-grammar"** family (referenced in
     `game-seed/research/symbolic-world-grammar.md`, Tier 1) is described as *"Saul as
     counterfeit king; false prophets; the Philistine commanders as inversion-of-the-
     anointed; this grammar family is the primary antagonist architecture."* Counterfeit
     authority — power that mimics legitimate authority while being hollow — is the
     corpus's closest analog to Gizmo's *"machinery that has forgotten the people it was
     built for: hollow, repeating, counterfeit"* (`gizmo-hades/design-handoff/NARRATIVE.md` §2).
   - `game-seed/design/acts/act-4-rule.md`'s Gideon beat: *"reduce your host to a tiny
     refined band... break the jars and the light bursts from the broken vessels; the
     horde turns its swords on itself"* — a corporate/swarm enemy defeated by internal
     confusion/self-destruction rather than direct combat, which is a strong structural
     precedent if Gizmo wants hyperscaler enemies that can be "confused into
     self-cannibalizing" as an ability rather than only tanked down.

3. **Patristic "technique" hits are false positives** — `ch061` (pottery-making technique)
   and `ch080` (bread-leavening technique) are craft-metaphor asides, not commentary on
   technology or dehumanization. Do not cite these as supporting the hyperscaler framing.

**Bottom line for §4:** the corpus gives strong *structural* grammar (false-vertical swarm,
counterfeit authority, defeat-by-disruption-not-damage) but supplies **zero direct
patristic or scriptural material on machines, AI, or "dehumanization" as a term or theme**.
Any copy that frames hyperscalers in explicitly patristic terms would be inventing a
citation. If the lore canvas wants textual grounding for "sophistication scales with
dehumanization," the honest options are: (a) use the Babel/counterfeit-authority grammar
as *structural* inspiration without claiming direct citation, or (b) commission a fresh
corpus search targeted at patristic critiques of idolatry-as-craftsmanship (Isaiah on idols,
Wisdom of Solomon on craftsmen, Athanasius *Against the Heathen* on idol-manufacture) —
none of which were confirmed present in this pass and would need separate verification
before citing.

---

## 5. Symbolic-lens framing rules — how the corpus adapts sacred material without mockery

The corpus is unusually explicit and disciplined about this, because it was built under a
"clean-room" methodology from the start. The rules below are drawn from the corpus's own
governing documents, not inferred:

- **Separate recognition from body-text reuse, always.** Every warrior-saint row splits
  `rights_status` from `orthodox_scope` from `body_ingestion_status`. The rule in practice:
  *"Use for identity, feast, and Orthodox recognition before consulting parallel Golden
  Legend material"* (`official_recognition_roster.jsonl`, repeated on every row). Applied to
  Gizmo: it is fine to *name* a saint's title/feast/iconographic marker as inspiration; it
  is not fine to reproduce OCA or other all-rights-reserved hagiographic prose as flavor
  text.

- **Never let a parallel Western witness (Golden Legend) govern an Orthodox claim.** Stated
  on literally every Golden Legend row: *"Do not treat this as Orthodox recognition or
  liturgical evidence"* / *"Keep separate from the Orthodox [X] cycle until rights-clear
  Orthodox sources are located."* Applied to Gizmo: if the lore canvas wants the more
  vivid, narratively complete Golden Legend stories (dragon-slaying George, river-carrier
  Christopher, Theban Legion), it should be transparent that these are *Western medieval
  parallel* traditions, not the Orthodox-recognized canon — useful as story material, but
  worth naming as such rather than presenting as unified Orthodox hagiography.

- **Do not collapse distinct saints who share a name or theme.** Repeatedly enforced:
  *"keep Theodore Tyro and Theodore Stratelates distinct"* (`official_recognition_roster.jsonl`);
  *"Use with Demetrios rather than as a collapsed duplicate; keep identity and feast
  separate"* (Nestor row); *"Do not merge Western Eustace details into Orthodox Eustathius
  body claims without a direct Orthodox hagiographic or liturgical witness."* Applied to
  Gizmo: if two saints get compressed into one boon-god slot for gameplay reasons, the lore
  canvas should make that compression a conscious, stated design choice — not an accident
  of sloppy research.

- **Ruler-sanctity is not martyr-sanctity — preserve the category boundary.**
  (`ruler_warrior_recognition_review.jsonl`, quoted in §3.1). Applied to Gizmo: don't let
  "warrior saint" become a single undifferentiated bucket; the corpus itself insists on at
  least two distinct sanctity-shapes (martyred-in-combat vs. righteous-ruler-who-defended).

- **Apocryphal/legendary material is background, not governing, and must be labeled as
  such.** The Christomaios dog-headed material is *"a controlled background route for the
  dog-headed motif that may inform Christopher traditions without treating Christomaios as
  identical to St Christopher"* (`christopher_cynocephalus_source_routes.jsonl`). Applied to
  Gizmo: rich, strange material (dog-headed saints, cynocephalic conversion narratives) can
  be creatively generative, but the corpus's discipline is to always keep a clear tag on
  what's core-recognized vs. legendary-adjacent — worth the same discipline in the lore
  canvas's glossary.

- **No interpretive schema gets imposed before the source is read on its own terms.** This
  is the deepest rule in the corpus, stated as the reason the whole project restarted
  clean-room in the first place: *"The prior project encoded categories too early. Those
  categories became pervasive and risk constraining the symbolic interpreter before it
  learns from Pageau sequentially."* (`docs/adr/0001-clean-room-boundary.md`). And on the
  Orthodox layer specifically: *"automatic use of Orthodox witness material as a governing
  symbolic vocabulary"* is explicitly still excluded even after the archive was added
  (`docs/adr/0005-orthodox-witness-source-prep.md`). Applied to Gizmet: resist the urge to
  pre-lock a full 1:1 saint-to-boon mapping before checking whether the *actual* attested
  material (patronage, iconography, martyrdom narrative) supports the gameplay role being
  assigned — several of the roster fits above (Athena/Basil, Hermes/George) are flagged as
  weak precisely because forcing them would be exactly the kind of premature-schema move
  the corpus's own governance rules warn against.

- **A symbol is not a decorative metaphor; the game-seed project's core axiom is worth
  carrying over as design philosophy even though it's not Gizmo canon:** *"A symbol is
  game-ready only when it changes state... A crow that sits is decoration. A crow that
  converts lost to guided is a mechanic."* (`game-seed/research/symbolic-world-grammar.md`).
  Applied to Gizmo: a saint's traditional attribute (Michael's scales, Christopher's staff,
  the Forty Martyrs' shared crown) should earn its place by becoming a mechanic (a state
  change), not just an icon on a boon card.

- **Content the corpus itself suggests should not be gamified casually:** liturgical/service
  texts (Menaion, Synaxarion, Divine Office) are treated as maximally rights- and
  reverence-gated even beyond normal copyright caution — *"Do not scrape or ingest modern
  liturgical service PDFs unless rights and local-only handling are explicit"*
  (`warrior_saints/README.md`); and body-text of currently-living-tradition recognition
  pages (OCA) is repeatedly walled off from reuse even for internal research, let alone
  external game copy. The clear implication for Gizmo: liturgical hymnography (troparia,
  kontakia) and official-source saint-life prose are the material most worth treating as
  reference-only inspiration, never quoted or paraphrased closely into player-facing copy.

---

## 6. Open questions for Shane / the lore canvas

- The corpus's own priority order puts the **dog-headed Eastern Christopher tradition**
  ahead of the river-carrier Western one for Orthodox governance — does the Gizmo lore
  canvas want to lean into that (a stranger, more "monstrous-outsider-becomes-bearer"
  read) or keep the more legible river-crossing image the creative-direction seed already
  uses?
- St. George is the most iconic/legible warrior saint but doesn't cleanly map to any single
  Hades boon-god slot in the roster above (his dragon-slaying/commander profile reads more
  "hero/capstone" than any one Olympian). Should George anchor a central slot (a Zeus- or
  Ares-equivalent) rather than being forced into Hermes?
- The Forty Martyrs of Sebaste are proposed above as a *collective* Chaos-analog rather than
  a single boon-giver — is a corporate/company benefactor mechanically workable in the
  existing `BoonDef` schema, or does canon need a named individual for that slot?
- No corpus material at all supports the "AI hyperscaler as escalating dehumanization"
  enemy-order in patristic terms (§4) — is the lore canvas comfortable treating that framing
  as original Gizmo invention grounded only in *structural* borrowing from Babel/counterfeit-
  authority grammar, or should a follow-up research pass specifically target idol-critique
  patristics (Isaiah, Wisdom of Solomon, Athanasius *Against the Heathen*) for firmer
  grounding?
- Several strong candidate saints (Nicholas, Basil-as-warrior, Seraphim, Mary of Egypt) have
  **no corpus presence** in the warrior-saints topic guide — worth a dedicated follow-up
  search before locking them into any boon-slot, since this pass only confirms their
  absence, not their unsuitability.
- The corpus explicitly separates ruler-saints (Nevsky, Donskoy) from martyr-saints — does
  Gizmo want a distinct hub-keeper/ally role for a ruler-saint, parallel to how Hades uses
  Hades/Persephone/Nyx as non-boon-giver hub figures?

---

*Prepared by a research pass over `/home/ark/language-of-creation/` on 2026-07-06. All
file paths verified to exist at time of writing. No patristic or hagiographic content was
invented; every quote above is copied from a corpus file at the cited path.*
