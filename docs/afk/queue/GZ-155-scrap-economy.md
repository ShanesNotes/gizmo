# GZ-155 — E5 (sim+UI): Scrap economy + wayside shop seam

intent: The second currency arrives: Scrap drops from elites/caches, banks across the run, and spends at a wayside shop anchor (the scrap_merchant of the audio cue map) — Sparks level you up, Scrap buys sideways.
files in scope: PRIMARY: `godot/scripts/simulation.gd` (scrap drops/balance, `spend_scrap(offer_id)`, shop offer table) — Cluster A; then a minimal shop UI scene (new files, upgrade_draft.tscn pattern); HUD scrap counter (Cluster C); tests across the three suites.
grounding: ADR 0001 (Scrap = secondary salvage currency, distinct from Sparks — never XP); lore glossary (Sparks primary / Scrap secondary — the distinction is validator-enforced lab-side); audio cue `scrap_merchant` exists (ambient set); balance §7 (shops as an offer channel in ExpectedRunPicks — update GZ-019 exhaustion math).
decisions made (v1 of feature): elites drop 3 scrap, brutes 1; shop = one `ShopAnchor` zone-adjacent marker per island (placed near the sanctuary — breath and barter); offers: guard restore-to-full (4 scrap), one reroll token (3), one random unlocked-upgrade rank at draft weight (6); shop UI opens on proximity + interact, pauses like the draft (GZ-012 law, arbitration: shop may not open while awaiting_choice).
executable success criteria: sim tests — drops, banking, each offer's effect, refuse-when-broke; UI test — open/buy/close; HUD counter distinct from Sparks (absence assertion: never rendered as XP); exhaustion math updated; gate green.
dependencies / order: blockedBy GZ-154 (offer surface final), GZ-041 (pause arbitration precedent).
model routing: **Opus** — a new economy touching sim/UI/balance at once.
cross-domain: "Scrap" copy/term usage per lore glossary; shop flavor copy is a lore-lab handoff (consume, or ship with placeholder sentence-case copy and a routed request note).
status: deferred:E5
