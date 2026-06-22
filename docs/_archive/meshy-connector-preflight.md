# Meshy Connector Preflight

- Date: 2026-06-20
- Scope: Gizmo Gate 2 first AI asset proof, not the full post-v1 world-building pipeline.
- Project target: Godot 4 3D rogue-lite, fixed Diablo-style camera, curated `.glb` kit pieces under `godot/assets/world_kits/`.

## Verification Summary

The Meshy MCP connector is accessible from Codex in this session.

Verified free/non-credit calls:

| Check | Result | Notes |
|---|---:|---|
| `meshy_list_tasks(limit=5, sort_by=-created_at)` | Passed | Returned valid JSON with `page_count: 0`, `has_more: false`, and queried task endpoints. |
| `meshy_check_balance()` | Passed | Authenticated successfully and returned a positive credit balance. Exact balance is intentionally not recorded in source. |
| `meshy_list_models(limit=5)` | Passed | Returned valid JSON with `page_count: 0`, `has_more: false`. |

Current account state visible to this API key: no existing tasks or workspace models were returned, so the first imported world-kit proof needs a new credit-gated generation task or a manual Meshy export supplied outside Codex.

## Available Connector Operations

Observed through the Codex Meshy MCP tool surface:

### Free / Non-generation Operations

- `meshy_check_balance` — confirms account credits.
- `meshy_list_tasks` — lists recent tasks across text/image/remesh/retexture/image-generation/print endpoints.
- `meshy_list_models` — lists completed workspace models.
- `meshy_get_task_status` — polls or waits for task completion.
- `meshy_cancel_task` — cancels pending/in-progress tasks.
- `meshy_download_model` — downloads a completed task output to local disk.
- `meshy_send_to_slicer` — detects local slicers and can prepare launch commands.
- `meshy_analyze_printability` — free FDM printability analysis for a task or public model URL.

### Credit-Gated Generation / Processing Operations

Do not call these without explicit user confirmation of cost, output format, and intended use:

| Operation | Credit cost | Use in Gizmo |
|---|---:|---|
| `meshy_text_to_3d` | 5 credits with `meshy-5`, 20 credits with `meshy-6/latest` | Generate a first static tile or landmark from a text prompt. |
| `meshy_text_to_3d_refine` | 10 | Add textures/PBR to a completed text-to-3D preview. |
| `meshy_image_to_3d` / `meshy_multi_image_to_3d` | 5-30 | Generate from local concept art references. |
| `meshy_retexture` | 10 | Restyle an existing model. |
| `meshy_remesh` | 5 | Reduce topology or convert formats for game use. |
| `meshy_rig` | 5 | Rig a character; includes walking/running outputs. Not needed for static world-kit props. |
| `meshy_animate` | 3 | Custom animations beyond rigging's included walk/run clips. |
| `meshy_process_multicolor` | 10 | 3D printing only; not part of Gizmo Gate 2. |
| `meshy_text_to_image` / `meshy_image_to_image` | 3-9 | Reference image generation/editing; not needed for first GLB import proof. |
| `meshy_repair_printability` | 10 | 3D printing repair only; not part of Gizmo Gate 2. |

## Required Inputs For First Godot Asset Proof

Recommended first proof asset: one small static world-kit prop or floor tile, not a character.

Suggested prompt target:

> low-poly modular clockwork stone floor tile for a fixed-camera Godot rogue-lite arena, brass rim, teal rune glow, readable silhouette from a Diablo-style camera, square footprint, flat walkable top, no characters, no text, no background

Required choices before spending credits:

1. Generation source: text prompt is cheapest and sufficient for the first seam proof.
2. Model: `meshy-5` for a 5-credit preview, or `meshy-6/latest` for a 20-credit higher-quality preview.
3. Format: `glb` for Godot import.
4. Optional texture pass: skip for cheapest seam proof, or run `meshy_text_to_3d_refine` for 10 more credits if textured Meshy material is required.
5. Optional remesh: skip until import inspection shows topology or scale problems; run `meshy_remesh` for 5 credits only if needed.

## Output Formats And Paths

Godot import rule from the project and Godot asset-pipeline guidance: use glTF/GLB as the primary 3D import format. `.import` sidecars are source and should be committed; `.godot/` imported cache is not source.

Target paths for the first proof:

```text
godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb
godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb.import
godot/scenes/world_kits/clockwork_observatory/clockwork_floor_tile_01.tscn
```

Download plan after a Meshy task succeeds:

```text
meshy_download_model(
  task_id=<completed_task_id>,
  task_type="text-to-3d",
  format="glb",
  save_to="/home/ark/gizmo/godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb"
)
```

Wrapper scene plan:

- Root: `Node3D` named `ClockworkFloorTile01`.
- Child: imported GLB scene instance.
- Collision: add a simple `StaticBody3D` + `CollisionShape3D` in the wrapper unless the imported mesh already provides a reliable collision suffix.
- Scale/orientation: verify in a fixed-camera scene. Target a compact tile footprint that works with the future hand-authored arena seam.
- Materials: accept imported material for proof; if readability is poor, apply a simple Godot material override in the wrapper before spending refine/remesh credits.

## Authentication And Rate-Limit Assumptions

- Auth uses `MESHY_API_KEY` from the Codex MCP process environment or local uncommitted `.env` via `tools/run-meshy-mcp.sh`.
- `.env` and `.env.*` are ignored by git.
- The current session authenticated successfully through MCP.
- The connector exposes asynchronous task IDs; generation should be followed by `meshy_get_task_status(wait=true)`.
- No explicit rate-limit number is exposed by the observed MCP tool schemas. Treat rate limits and concurrent task limits as external Meshy account policy; recover by waiting, cancelling bad in-progress tasks, or manual export.
- Credit costs are enforced as a human confirmation gate before generation/processing calls.

## Failure Modes

Expected failure classes:

- Missing or invalid `MESHY_API_KEY` when Codex starts.
- Insufficient credits.
- User has not confirmed a credit-gated operation.
- `InvalidImageUrl` or `File not found` for image-to-3D inputs.
- `NotFound` for stale task IDs.
- Generation succeeds but output is unusable: wrong silhouette, wrong scale, bad orientation, broken material readability, too many faces, poor collision footprint.
- Download failure; MCP may return URLs instead of a local file.
- Godot import sidecar not generated until the editor/headless import pass touches the GLB.

## Automated-vs-Manual Export Handoff

Preferred automated path:

1. Confirm cost/model/format with the user.
2. Run `meshy_text_to_3d` with `target_formats: ["glb"]`.
3. Wait with `meshy_get_task_status`.
4. Download with `meshy_download_model` directly into `godot/assets/world_kits/clockwork_observatory/`.
5. Open/import in Godot so the `.glb.import` sidecar is generated.
6. Create a wrapper `.tscn` with collision and scale/orientation notes.
7. Verify with Godot load/import checks and, if possible, a fixed-camera screenshot.

Manual fallback path:

1. Generate/export from Meshy web UI outside Codex.
2. Save a single `.glb` into `godot/assets/world_kits/clockwork_observatory/`.
3. Reopen Godot or run an import pass to create the `.import` sidecar.
4. Continue with the same wrapper-scene and verification steps.

## Current Stop Point

The connector preflight is complete. The next step, creating the first AI GLB asset, requires explicit credit confirmation. Cheapest recommended proof: text-to-3D with `meshy-5`, output `glb`, 5 credits, no texture refine/remesh unless inspection shows a real need.
