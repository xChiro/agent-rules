#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
configure="$repo_root/tools/windsurf/configure-mcp.sh"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/configure-mcp.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

codeium_home="$tmp_dir/codeium"
windsurf_home="$codeium_home/windsurf"
projects_root="$tmp_dir/projects"
mkdir -p "$windsurf_home" "$projects_root/HBK" "$projects_root/agent-rules"

printf '%s\n' '{"theme":"dark","mcpServers":{"existing-a":{"command":"a"}}}' \
  > "$codeium_home/mcp_config.json"
printf '%s\n' '{"telemetry":false,"mcpServers":{"existing-b":{"command":"b"}}}' \
  > "$windsurf_home/mcp_config.json"

CODEIUM_HOME="$codeium_home" \
WINDSURF_HOME="$windsurf_home" \
PROJECTS_ROOT="$projects_root" \
NODE_COMMAND=/usr/bin/node \
NPX_COMMAND=/usr/bin/npx \
  bash "$configure" >/dev/null

cmp -s "$codeium_home/mcp_config.json" "$windsurf_home/mcp_config.json"
jq -e '.theme == "dark" and .telemetry == false' "$codeium_home/mcp_config.json" >/dev/null
jq -e '.mcpServers["existing-a"].command == "a"' "$codeium_home/mcp_config.json" >/dev/null
jq -e '.mcpServers["existing-b"].command == "b"' "$codeium_home/mcp_config.json" >/dev/null
jq -e '.mcpServers["hbk-projects"].args[3:] | length == 2' "$codeium_home/mcp_config.json" >/dev/null
find "$codeium_home" -name 'mcp_config.json.backup-*' | grep -q .

invalid_home="$tmp_dir/invalid"
mkdir -p "$invalid_home/windsurf"
printf '%s\n' '{invalid' > "$invalid_home/mcp_config.json"
set +e
CODEIUM_HOME="$invalid_home" \
WINDSURF_HOME="$invalid_home/windsurf" \
PROJECTS_ROOT="$projects_root" \
  bash "$configure" >/dev/null 2>&1
status=$?
set -e
[[ "$status" -ne 0 ]]
grep -F '{invalid' "$invalid_home/mcp_config.json" >/dev/null

echo 'PASS: MCP configuration merges, backs up, synchronizes, and preserves invalid input'
