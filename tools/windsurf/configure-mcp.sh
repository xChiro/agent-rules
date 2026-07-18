#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
codeium_home="${CODEIUM_HOME:-$HOME/.codeium}"
windsurf_home="${WINDSURF_HOME:-$codeium_home/windsurf}"
projects_root="${PROJECTS_ROOT:-$HOME/Projects}"
filesystem_package="${MCP_FILESYSTEM_PACKAGE:-@modelcontextprotocol/server-filesystem@2026.1.14}"
node_command="${NODE_COMMAND:-/opt/homebrew/bin/node}"
npx_command="${NPX_COMMAND:-/opt/homebrew/bin/npx}"
proxy_script="$repo_root/tools/windsurf/mcp-filesystem-proxy.mjs"

roots=(
  "${HBK_PROJECTS_ROOT:-$projects_root/HBK}"
  "${AGENT_RULES_ROOT:-$projects_root/agent-rules}"
)

for root in "${roots[@]}"; do
  if [[ ! -d "$root" ]]; then
    echo "MCP root does not exist: $root" >&2
    exit 1
  fi
done

if [[ ! -r "$proxy_script" ]]; then
  echo "MCP filesystem proxy does not exist: $proxy_script" >&2
  exit 1
fi

mkdir -p "$codeium_home" "$windsurf_home"

roots_json="$(printf '%s\n' "${roots[@]}" | jq -R -s 'split("\n") | map(select(length > 0))')"
merged_config='{}'
for config in "$codeium_home/mcp_config.json" "$windsurf_home/mcp_config.json"; do
  if [[ -e "$config" ]]; then
    jq empty "$config" >/dev/null 2>&1 || {
      echo "Refusing to replace invalid MCP configuration: $config" >&2
      exit 1
    }
    merged_config="$(jq -s '.[0] * .[1]' <(printf '%s\n' "$merged_config") "$config")"
  fi
done

config_json="$(jq \
  --arg command "$node_command" \
  --arg proxy "$proxy_script" \
  --arg package "$filesystem_package" \
  --arg npx "$npx_command" \
  --argjson roots "$roots_json" \
  '.mcpServers = (.mcpServers // {})
   | .mcpServers["hbk-projects"] = {command:$command,args:([$proxy, $package, $npx] + $roots)}' \
  <(printf '%s\n' "$merged_config"))"

backup_timestamp="$(date -u +%Y%m%d-%H%M%S)"
for config in "$codeium_home/mcp_config.json" "$windsurf_home/mcp_config.json"; do
  if [[ -e "$config" ]]; then
    cp "$config" "$config.backup-$backup_timestamp"
  fi
  tmp_config="$(mktemp "$(dirname "$config")/.mcp_config.XXXXXX")"
  printf '%s\n' "$config_json" | jq . > "$tmp_config"
  mv "$tmp_config" "$config"
done

echo "Configured JetBrains/Windsurf MCP filesystem roots:"
printf '  %s\n' "${roots[@]}"
echo "Configured filesystem package: $filesystem_package"
