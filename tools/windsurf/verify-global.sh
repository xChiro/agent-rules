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

  while IFS= read -r workflow; do
    system_workflow="$system_home/workflows/$(basename "$workflow")"
    [[ -f "$system_workflow" ]] && cmp -s "$workflow" "$system_workflow" \
      || fail "system workflow not synchronized: $(basename "$workflow")"
  done < <(find "$repo_root/common/workflows" "$repo_root/languages" -type f -name '*.workflow.md' | sort)
  pass "system-level workflow catalog checked"

  while IFS= read -r skill; do
    name="$(sed -n 's/^name: //p' "$skill" | head -1)"
    system_skill="$system_home/skills/$name/SKILL.md"
    [[ -n "$name" && -f "$system_skill" ]] && cmp -s "$skill" "$system_skill" \
      || fail "system skill not synchronized: $name"
  done < <(find "$repo_root/common/skills" "$repo_root/languages" -type f -path '*/skills/*.md' | sort)
  pass "system-level skill catalog checked"

  while IFS= read -r template; do
    system_template="$system_home/templates/$(basename "$template")"
    [[ -f "$system_template" ]] && cmp -s "$template" "$system_template" \
      || fail "system template not synchronized: $(basename "$template")"
  done < <(find "$repo_root/common/templates" -type f -name '*.md' | sort)
  pass "system-level template catalog checked"
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
