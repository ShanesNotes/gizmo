# Backdrop wiring — the gouache cosmos sky

Design-system handoff, 2026-07-07. Assets installed under `godot/assets/sky/`
(no scene edits made — game side wires). The backdrop is the "where" of the vigil:
a violet-void cosmos (canon D7 world surface) with drifting islands, a faced
crescent moon (M6), gilt stars, and a warm ember horizon (M8). No teal (G6).

## Delivered

| File | What |
|---|---|
| `gizmo_cosmos_panorama.jpg` | Painted hero backdrop (AI-gen, provenance sidecar alongside) |
| `gizmo_cosmos_sky_panorama.tres` | `Sky` resource mounting it as `PanoramaSkyMaterial` |
| `gizmo_cosmos_sky.gdshader` | Procedural fallback: token gradient + starfield + ember band |
| `gizmo_cosmos_sky_procedural.tres` | `Sky` resource with the shader, token values preset |

## Wiring (per Environment — run.tscn and each room template)

Rooms currently use `background_mode = 1` (flat `#0b0d11` — the black void). Change to:

```
environment.background_mode = Environment.BG_SKY        # = 2
environment.sky = load("res://assets/sky/gizmo_cosmos_sky_panorama.tres")
environment.sky_rotation = Vector3(0.0, <aim>, 0.0)
environment.background_energy_multiplier = 0.9
```

- **`sky_rotation.y` is the composition control.** The fixed Diablo camera never
  yaws, so it always sees the same ~50° sector of the panorama. Rotate the moon /
  ember horizon into (or out of) view per room mood; point the ember sector toward
  the run's Beacon end where possible (warmth = destination, X-S3). The procedural
  sky has the same control as the `ember_azimuth` shader parameter.
- **Keep `fog_sky_affect = 0.0`** (already set) so fog never mattes over the cosmos.
- **Ambient:** keep `ambient_light_source = 2` (fixed warm color). Switching to
  sky-sourced ambient would cool every actor toward violet and fight the warm-key /
  cool-fill law from the silhouette probe. Do not change it for the backdrop.

## Energy vs the gouache grade (CanvasLayer -1)

The grade shader split-tones the 3D frame: highlights lean parchment-warm, corners
vignette to warm ink. Two consequences:

1. Sky luma sits low-mid by design, so the grade's highlight warmth barely touches
   it — the backdrop stays subdued under actors (the Hades value ladder: background
   never competes). Keep `background_energy_multiplier` ≤ 1.0 (0.9 recommended);
   if the moon blooms under `glow_enabled`, drop to 0.8 rather than disabling glow.
2. The vignette already darkens sky corners — do not add a second darkening pass.

## Panorama vs procedural — when to use which

- **Panorama (hero):** hub, title backdrop, vista/rest rooms. Caveat: the image is
  1376px across 360°, so the visible sector is soft when panorama-mapped. That reads
  as painterly haze, which suits gouache — but if a room wants a crisp sky feature,
  either use the procedural sky or request a 4k regeneration from design-system.
- **Procedural (fallback/workhorse):** combat rooms and anywhere resolution or
  variety matters — it is resolution-independent and each room can re-aim
  `ember_azimuth` / retint via shader parameters (all token-locked; don't invent hex).

The hub's existing placeholder `ProceduralSkyMaterial` should be replaced by one of
these so the whole game shares a single canonical cosmos.
