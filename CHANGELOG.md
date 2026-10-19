# Changelog

## v1.0.0 — 2026-10

- First public release.
- `install.ps1`: installs uv, Node.js LTS, the pyRevit MCP extension, the bridge files and a Desktop shortcut. Works from a downloaded copy or as a one-liner (`irm … | iex`, pinned to this release).
- `src/pyrevit_bridge.py`: re-exposes the pyRevit MCP tools to MCP SuperAssistant, `READ_ONLY` switch, two read-only custom tools: `wt_count_by_category`, `wt_list_instances`.
- Docs: Full Guide and step-by-step PowerShell commands.
