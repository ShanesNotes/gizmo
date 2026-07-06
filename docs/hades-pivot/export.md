# Gizmo Hades Pivot Export

The Godot project root is `godot/`; export presets live at `godot/export_presets.cfg`.

## Presets

- `Linux/X11` -> `godot/exports/linux/gizmo.x86_64`
- `Windows Desktop` -> `godot/exports/windows/Gizmo.exe`
- `Web` -> `godot/exports/web/index.html`

All presets use `export_filter="all_resources"` with `exclude_filter` entries for
tests, docs/reference/design-handoff patterns, and Markdown files. Web exports have
thread support disabled so local static hosting does not require COOP/COEP headers.

## Commands

Run from the repository root:

```bash
mkdir -p godot/exports/linux godot/exports/windows godot/exports/web

GODOT_USER_DATA_DIR="${GODOT_USER_DATA_DIR:-/tmp/codex-godot-userdata-export}"
mkdir -p "$GODOT_USER_DATA_DIR"

godot --headless --user-data-dir="$GODOT_USER_DATA_DIR" \
  --log-file "$GODOT_USER_DATA_DIR/export-linux.log" \
  --path godot --export-debug "Linux/X11" exports/linux/gizmo.x86_64

godot --headless --user-data-dir="$GODOT_USER_DATA_DIR" \
  --log-file "$GODOT_USER_DATA_DIR/export-windows.log" \
  --path godot --export-debug "Windows Desktop" exports/windows/Gizmo.exe

godot --headless --user-data-dir="$GODOT_USER_DATA_DIR" \
  --log-file "$GODOT_USER_DATA_DIR/export-web.log" \
  --path godot --export-debug "Web" exports/web/index.html
```

Use `--export-release` with the same preset names and output paths for release
artifacts after debug dry-runs are clean.

## Dry-Run Result

On 2026-07-06, dry-runs were executed with Godot
`4.7.stable.official.5b4e0cb0f` and `GODOT_USER_DATA_DIR=/tmp/codex-godot-userdata-106`.
Each preset parsed and reached export validation, then failed because export templates
are not installed locally:

- `Linux/X11`: missing `linux_debug.x86_64` and `linux_release.x86_64`.
- `Windows Desktop`: missing `windows_debug_x86_64.exe` and `windows_release_x86_64.exe`.
- `Web`: missing `web_nothreads_debug.zip` and `web_nothreads_release.zip`.

Godot also reported editor debug-server socket and editor-settings save warnings in
the sandboxed headless run; those happened after preset validation and did not change
the template-missing result.
