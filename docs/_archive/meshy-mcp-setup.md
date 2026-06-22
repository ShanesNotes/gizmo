# Meshy MCP Setup

Claude previously reached Meshy through `@meshy-ai/meshy-mcp-server`, not through raw REST `curl` calls. The raw endpoint is useful for debugging, but Codex needs an MCP server registration.

Current connector preflight evidence is recorded in [`docs/meshy-connector-preflight.md`](meshy-connector-preflight.md).

Claude log evidence from this machine:

- Server package: `@meshy-ai/meshy-mcp-server`
- Observed server version: `0.2.1`
- Transport: stdio
- Registered tools: text-to-3d, text-to-3d-refine, image-to-3d, multi-image-to-3d, status/list/cancel/download, list models, remesh, retexture, rig, animate, text-to-image, image-to-image, slicer/printability tools, and balance check

## Register With Codex

Run this from your own terminal so your API key stays in your shell, not in chat or git:

```bash
cd /home/ark/gizmo
export MESHY_API_KEY="your_key_here"
codex mcp add meshy -- bash /home/ark/gizmo/tools/run-meshy-mcp.sh
codex mcp get meshy
```

Then restart the Codex session so the new MCP server is loaded.

If you want to pin the exact package version Claude observed:

```bash
export MESHY_MCP_PACKAGE="@meshy-ai/meshy-mcp-server@0.2.1"
```

Otherwise the runner uses `@meshy-ai/meshy-mcp-server`.

## Local `.env`

The runner also supports a local `.env` file:

```bash
MESHY_API_KEY=your_key_here
```

Do not commit `.env`. The runner only reads it locally to launch the MCP server.

## Why Not Use The Curl Directly?

The curl command calls Meshy's REST API. The MCP server wraps that API and exposes the tool surface Codex/Claude can use in-agent, including generation, task status, downloads, rigging, and animation.
