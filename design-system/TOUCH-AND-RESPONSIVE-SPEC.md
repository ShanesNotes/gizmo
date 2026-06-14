# Touch & Responsive Spec — Gizmo (reverse-engineered from the shipping Phaser build)

The game canvas is **fluid full-viewport**, not a fixed resolution. This spec pins the exact geometry so the design-system `Joystick`, `BoostButton`, `TouchControls`, and the portrait HUD match the real build **1:1** — and so the input scheme stays *documented-as-is* rather than re-decided. The design layer only **re-skins** what already ships (ink + gold-leaf page-apparatus language); it does not change behavior.

## Canvas & viewport
- Canvas fills the viewport: `width:100%; height:100%; touch-action:none;`.
- Honor the notch/home-bar with `env(safe-area-inset-top|right|bottom|left)` on every fixed overlay.
- Design portrait to a **390 × 844 reference**, but keep the layout **fluid** — anchor to edges + safe-area, don't hard-size the frame.

## Breakpoints (use the build's, verbatim)
| Trigger | Meaning | Effect |
|---|---|---|
| `(min-width: 981px)` | desktop | full desktop HUD (1280×720 stage) |
| `max-width: 980px` | tablet / large phone landscape | condense panels, shrink type |
| `max-width: 560px` | phone portrait | stack HUD, mobile cluster sizing |
| `max-height: 620px` | short viewport (landscape phone) | collapse vertical chrome, smaller controls |
| `(hover: none) and (pointer: coarse)` | **touch device** | show `TouchControls`; hide hover-only affordances |

The touch cluster is gated on `(hover:none) and (pointer:coarse)` — never on width alone (a small desktop window must NOT get a joystick).

## Joystick (fixed bottom-left thumbstick)
| Part | Default | Small screen (`≤560px` or `max-height:620px`) |
|---|---|---|
| Ring (base) | **112px** | **94px** |
| Knob | **52px** | **44px** (never below — honors the 44px min touch target) |
| Anchor | `left: calc(env(safe-area-inset-left) + 22px)`; `bottom: calc(env(safe-area-inset-bottom) + 22px)` | same, 16px gap |
| Knob travel | knob center moves up to `(ring−knob)/2` from center | — |

- `variant="fixed"` — ring is always drawn at the anchor (default, what ships).
- `variant="floating"` — ring is invisible until first touch, then it spawns centered on the touch point and the knob tracks from there. **Expose this prop so a floating stick can be A/B-tested in playtest without a rebuild.** Decision stays open.

## Boost (right-side button — it is the **Snap Boost** mechanic, keep it a button, not a gesture)
Size: **84px** ring (→ **72px** small). Anchor mirrors the joystick on the right. Six states (the timing loop):

| State | Read | Skin |
|---|---|---|
| `default` | ready, idle | surge gold fill, gold-leaf border, "BOOST / Snap Seal" |
| `snap-window` | **hit now** — timing window open | pulsing gold ring (`0 0 0 6px` → `0 0 0 12px` surge α), label "SNAP" |
| `queued` | input registered, resolving | held/dim, oxblood inner tint, label "SET" |
| `scooping` | active — pulling sparks | **mint (Flow)** fill + mint glow, label "SCOOP" |
| `cooling` | cooldown | dark glass + radial sweep showing `cooldown` 0→1, dim |
| `disabled` | unavailable | flat, 45% opacity, no glow |

## Component mapping
- `Joystick` — the thumbstick. Props: `size`, `variant`, knob offset `dx`/`dy` (−1..1) for static display, `interactive` for live drag.
- `BoostButton` — props: `state` (the six above), `cooldown` (0..1, drives the cooling sweep), `size`.
- `TouchControls` — composes both into the safe-area bottom band; `variant` passes to the joystick. Gate its render on the touch media query in the consuming layout.
- Portrait HUD — `ui_kits/lumen-codex/HudPortrait.jsx`: score + breath (top), bounty **verdict chip** (`VerdictBar compact`), four-covenant cluster (condensed), `TouchControls` (bottom).

## Honored invariants
Min touch target **44px**; warm:cool ≈ 9:1; gold = light / red = cost / ink = official; charged empty space frames the payoff. The cluster never hides game state — it telegraphs it (Boost state is legible at a glance, paired with color **and** label, never color alone).
