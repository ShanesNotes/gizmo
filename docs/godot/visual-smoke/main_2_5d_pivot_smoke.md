# Main 2.5D pivot visual smoke

Date: 2026-06-15
Godot: 4.6.2.stable.mono.official
Viewport: 1280×720
Capture: `docs/godot/visual-smoke/main_2_5d_pivot_smoke.png`
Command:

```bash
${GODOT_BIN:-godot} --path godot --script res://tests/capture_main_2_5d_visual_smoke.gd
```

## Checklist

- [x] Canonical scene loads from `godot/scenes/main.tscn`.
- [x] Root is `Node3D` with quiet 3D ground/stage marker.
- [x] `CameraRig/Camera3D` is current and orthographic.
- [x] Player marker is visible through `PlayerAvatar3D`.
- [x] HUD remains screen-space through `CanvasLayer` / `Control` / `Label`.
- [x] Capture saved as a non-empty 1280×720 PNG.

## Notes

This is a smoke record, not pixel parity. It proves the early 2.5D stage renders, the HUD remains screen-space, and the capture path works on the local display driver. Later visual-verdict passes can compare against intentional art references once the 2.5D style target is more specific.
