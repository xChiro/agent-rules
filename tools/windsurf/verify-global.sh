#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
windsurf_home="${WINDSURF_HOME:-$HOME/.codeium/windsurf}"
codeium_home="${CODEIUM_HOME:-$HOME/.codeium}"
system_home="${SYSTEM_WINDSURF_HOME:-/Library/Application Support/Windsurf}"
projects_root="${PROJECTS_ROOT:-$HOME/Projects}"
canonical="$windsurf_home/common"
failed=0

fail() {
  echo "FAIL: $*" >&2
  failed=1
}

pass() {
  echo "PASS: $*"
}

if bash "$repo_root/tools/validate-agent-catalog.sh"; then
  pass "source agent catalog"
else
  fail "source agent catalog"
fi

[[ -d "$canonical/rules" && -d "$canonical/workflows" && -d "$canonical/skills" && -d "$canonical/templates" && -d "$canonical/languages" ]] \
  && pass "canonical Windsurf common tree" \
  || fail "canonical Windsurf common tree"

if shasum -a 256 -c "$canonical/manifest.sha256" >/dev/null 2>&1; then
  pass "canonical installation manifest"
else
  fail "canonical installation manifest"
fi

rules_file="$windsurf_home/memories/global_rules.md"
if [[ -r "$rules_file" ]] && [[ "$(wc -c < "$rules_file" | tr -d ' ')" -le 6000 ]]; then
  pass "global rules are readable and within the 6000-character limit"
else
  fail "global rules missing or larger than 6000 characters"
fi

while IFS= read -r workflow; do
  installed="$windsurf_home/global_workflows/$(basename "$workflow")"
  [[ -f "$installed" ]] && cmp -s "$workflow" "$installed" \
    || fail "workflow not synchronized: $(basename "$workflow")"
done < <(find "$repo_root/common/workflows" "$repo_root/languages" -type f -name '*.workflow.md' | sort)
pass "global workflow catalog checked"

while IFS= read -r skill; do
  name="$(sed -n 's/^name: //p' "$skill" | head -1)"
  installed="$windsurf_home/skills/$name/SKILL.md"
  [[ -n "$name" && -f "$installed" ]] && cmp -s "$skill" "$installed" \
    || fail "skill not synchronized: $skill"
done < <(find "$repo_root/common/skills" "$repo_root/languages" -type f -path '*/skills/*.md' | sort)
pass "global skill catalog checked"

while IFS= read -r template; do
  relative="${template#"$repo_root/common/templates/"}"
  installed="$canonical/templates/$relative"
  [[ -f "$installed" ]] && cmp -s "$template" "$installed" \
    || fail "template not synchronized: $relative"
done < <(find "$repo_root/common/templates" -type f | sort)
pass "global template catalog checked"

if [[ -d "$system_home" ]]; then
  [[ -f "$system_home/rules/agent-rules-global.md" ]] \
    && pass "system-level Windsurf rules" \
    || fail "system-level Windsurf rules"

  system_workflow_failed=0
  while IFS= read -r workflow; do
    system_workflow="$system_home/workflows/$(basename "$workflow")"
    if [[ ! -f "$system_workflow" ]] || ! cmp -s "$workflow" "$system_workflow"; then
      fail "system workflow not synchronized: $(basename "$workflow")"
      system_workflow_failed=1
    fi
  done < <(find "$repo_root/common/workflows" "$repo_root/languages" -type f -name '*.workflow.md' | sort)
  [[ "$system_workflow_failed" -eq 0 ]] && pass "system-level workflow catalog checked"

  system_skill_failed=0
  while IFS= read -r skill; do
    name="$(sed -n 's/^name: //p' "$skill" | head -1)"
    system_skill="$system_home/skills/$name/SKILL.md"
    if [[ -z "$name" || ! -f "$system_skill" ]] || ! cmp -s "$skill" "$system_skill"; then
      fail "system skill not synchronized: $name"
      system_skill_failed=1
    fi
  done < <(find "$repo_root/common/skills" "$repo_root/languages" -type f -path '*/skills/*.md' | sort)
  [[ "$system_skill_failed" -eq 0 ]] && pass "system-level skill catalog checked"

  system_template_failed=0
  while IFS= read -r template; do
    system_template="$system_home/templates/$(basename "$template")"
    if [[ ! -f "$system_template" ]] || ! cmp -s "$template" "$system_template"; then
      fail "system template not synchronized: $(basename "$template")"
      system_template_failed=1
    fi
  done < <(find "$repo_root/common/templates" -type f -name '*.md' | sort)
  [[ "$system_template_failed" -eq 0 ]] && pass "system-level template catalog checked"
else
  echo "WARN: system-level Windsurf catalog unavailable at $system_home; JetBrains workflows require administrator installation."
fi

for shared in common global_workflows skills global_rules.md; do
  [[ -L "$codeium_home/$shared" && -e "$codeium_home/$shared" ]] \
    && pass "JetBrains shared path: $shared" \
    || fail "JetBrains shared path: $shared"
done

[[ -L "$codeium_home/memories/global_rules.md" && -e "$codeium_home/memories/global_rules.md" ]] \
  && pass "JetBrains global rules memory" \
  || fail "JetBrains global rules memory"

mcp_config="$codeium_home/mcp_config.json"
windsurf_mcp_config="$windsurf_home/mcp_config.json"
if [[ "${SKIP_MCP_CONFIG:-0}" == "1" ]]; then
  echo "INFO: skipped MCP configuration verification (SKIP_MCP_CONFIG=1)."
elif [[ -r "$mcp_config" && -r "$windsurf_mcp_config" ]] \
  && jq empty "$mcp_config" >/dev/null 2>&1 \
  && jq empty "$windsurf_mcp_config" >/dev/null 2>&1 \
  && cmp -s "$mcp_config" "$windsurf_mcp_config"; then
  expected_mcp_package="${MCP_FILESYSTEM_PACKAGE:-@modelcontextprotocol/server-filesystem@2026.1.14}"
  expected_mcp_proxy="$repo_root/tools/windsurf/mcp-filesystem-proxy.mjs"
  actual_mcp_proxy="$(jq -r '.mcpServers["hbk-projects"].args[0] // empty' "$mcp_config")"
  actual_mcp_package="$(jq -r '.mcpServers["hbk-projects"].args[1] // empty' "$mcp_config")"
  if [[ "$actual_mcp_package" == "$expected_mcp_package" ]]; then
    if [[ "$actual_mcp_proxy" == "$expected_mcp_proxy" ]]; then
      pass "JetBrains/Windsurf MCP configuration is valid and synchronized"
    else
      fail "MCP filesystem proxy mismatch: expected $expected_mcp_proxy, got ${actual_mcp_proxy:-missing}"
    fi
  else
    fail "MCP filesystem package mismatch: expected $expected_mcp_package, got ${actual_mcp_package:-missing}"
  fi
else
  fail "JetBrains/Windsurf MCP configuration missing, invalid, or not synchronized"
fi

if [[ "${SKIP_MCP_CONFIG:-0}" != "1" ]]; then
  for mcp_root in "${HBK_PROJECTS_ROOT:-$projects_root/HBK}" "${AGENT_RULES_ROOT:-$projects_root/agent-rules}"; do
    if [[ -r "$mcp_config" ]] && jq -e --arg root "$mcp_root" '.mcpServers["hbk-projects"].args[3:] | index($root)' "$mcp_config" >/dev/null 2>&1; then
      pass "MCP root configured: $mcp_root"
    else
      fail "MCP root missing: $mcp_root"
    fi
  done
fi

jetbrains_root="$HOME/Library/Application Support/JetBrains"
for ide in GoLand WebStorm Rider; do
  plugin="$(find "$jetbrains_root" -maxdepth 3 -type d -path "*/${ide}*/plugins/codeium" -print -quit 2>/dev/null || true)"
  [[ -n "$plugin" ]] && pass "$ide Windsurf/Codeium plugin: $plugin" || fail "$ide Windsurf/Codeium plugin not found"
done

if [[ -x "$windsurf_home/bin/devin-desktop" ]]; then
  pass "Devin Desktop Windsurf fallback uses $windsurf_home"
else
  echo "INFO: Devin Desktop binary not found; Devin cloud requires organization/repository Skills & Rules."
fi

local_managed="$(rg -l 'managed-by: agent-rules|RULE-COMMON_SDD|WORKFLOW-COMMON_SDD|WORKFLOW-GO_SDD|WORKFLOW-CSHARP_SDD' "$projects_root" \
  --glob 'AGENTS.md' --glob '.windsurfrules' --glob '.windsurf/**' --glob '.agents/**' 2>/dev/null || true)"
if [[ -z "$local_managed" ]]; then
  pass "no project-local managed agent-rules copies"
else
  fail "project-local managed agent-rules copies found:\n$local_managed"
fi

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi

echo "Global Windsurf access verified."
