# Windsurf Tooling

Cleanup helpers for old project-local Windsurf rules, skills, and workflows.

Canonical content lives under `common/` and `languages/`. Rules, workflows, skills, and evidence templates are published from the common catalog so Windsurf and JetBrains integrations, including WebStorm, resolve one source of truth. Do not keep duplicated rule copies in local projects.

## Workflow Resolution

Resolve by exact `workflow_id` and then open the matching `.md` file:

| Scope | Canonical path |
|---|---|
| Common workflow | `~/.codeium/windsurf/common/workflows/<workflow-file>.workflow.md` |
| Language workflow | `~/.codeium/windsurf/common/languages/<language>/workflows/<workflow-file>.workflow.md` |
| Published fallback | `~/.codeium/windsurf/global_workflows/<workflow-file>.workflow.md` |
| JetBrains system fallback | `/Library/Application Support/Windsurf/workflows/<workflow-file>.workflow.md` |

Examples:

- `WORKFLOW-CSHARP_SDD_IMPLEMENT_CHANGE_WORKFLOW` -> `common/languages/csharp/workflows/csharp-sdd-implement-change.workflow.md`
- `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` -> `common/workflows/common-rest-api-design.workflow.md`
- `WORKFLOW-CSHARP_REST_API_WORKFLOW` -> `common/languages/csharp/workflows/csharp-rest-api.workflow.md`

Do not search for language workflows directly under `common/workflows/`, and do not invent `csharp-rest-api.workflow.md` under the common catalog. If the canonical file cannot be opened, report the exact attempted paths and stop before implementation rather than continuing from IDs alone.

## JetBrains MCP Access

`configure-mcp.sh` merges the shared MCP entry consumed by Cascade in
Rider, GoLand, and WebStorm. It keeps `~/.codeium/mcp_config.json` and
`~/.codeium/windsurf/mcp_config.json` synchronized and pins the filesystem
server to the JetBrains-compatible version. The local proxy handles the
JetBrains `roots/list` request and returns the HBK projects directory plus this
repository, while preserving every unrelated top-level option and MCP server.
Existing files are backed up with a UTC timestamp before the synchronized
configuration is replaced atomically. Invalid existing JSON blocks the update
instead of being discarded. Fully restart the IDEs
after changing the configuration so their language-server processes reload it.

To publish only rules, workflows, skills, templates, and IDE compatibility links without reading or rewriting MCP JSON configuration, run `SKIP_MCP_CONFIG=1 bash tools/windsurf/install-global.sh`.

## Project-Local Cleanup

Use `sync-project.sh` to remove files previously copied into a project by this repository.

```bash
tools/windsurf/sync-project.sh /path/to/project
```

The script removes only files containing this marker:

```text
<!-- managed-by: agent-rules/tools/windsurf/sync-project.sh -->
```

Project-specific `.windsurf` files without the marker are preserved by the helper. If a local project still has unmarked rule copies, delete them manually and move any reusable content into `common/` or the appropriate `languages/<profile>/` folder.
