# GZ-193 — P7 (game): accessibility & readability pass

intent: The fixed camera's last exam: verified readability at 1280×720 baseline, plus the three cheapest high-value accessibility levers.
files in scope: audit half read-only (screenshot evidence at the gameplay camera across regions); fix half: PRIMARY `godot/scripts/style_director.gd` + hud.gd parameters; settings additions to GZ-191's menu; tests per fix.
grounding: design-system inherited canon (1280×720 baseline; camera is the harsh judge); their responsive-ui skill for stretch/aspect verification; WCAG-adjacent contrast targets for HUD text (4.5:1 body) measured against the theme, evidence-honest (measured, not claimed).
decisions made: the three levers — (1) reduce-flash toggle (caps GZ-021 effect emission spikes), (2) enemy-outline toggle (thin rim on hostiles — readability under swarm density; must pass a design-system named-betrayal check: an extraction note, since outlines touch look canon), (3) HUD scale 1.0/1.25. Colorblind-safe check on guard-vs-HP bar hues (measured; if the theme pair fails, the finding routes to design-system as evidence, NOT a local hex edit — seam law).
executable success criteria: an evidence file (screenshot set + contrast measurements) attached to the PR; each toggle has a test; failed measurements filed as routed findings, not silently patched. Gate green.
dependencies / order: blockedBy GZ-191, GZ-133, one act-2 region green (real density evidence).
model routing: **Sonnet** — audit discipline + small parameter work.
status: deferred:P7
