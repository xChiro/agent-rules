#!/usr/bin/env bash
set -euo pipefail

source_root="${WINDSURF_HOME:-$HOME/.codeium/windsurf}"
system_home="${SYSTEM_WINDSURF_HOME:-/Library/Application Support/Windsurf}"

if [[ ! -d "$source_root/global_workflows" || ! -d "$source_root/skills" || ! -d "$source_root/common/templates" ]]; then
  echo "Windsurf user catalog is missing: $source_root" >&2
  exit 1
fi

mkdir -p "$system_home/rules" "$system_home/workflows" "$system_home/skills" "$system_home/templates"
cp "$source_root/memories/global_rules.md" "$system_home/rules/agent-rules-global.md"
cp "$source_root/global_workflows"/*.workflow.md "$system_home/workflows/"
cp "$source_root/common/templates"/*.md "$system_home/templates/"

while IFS= read -r skill_dir; do
  name="$(basename "$skill_dir")"
  mkdir -p "$system_home/skills/$name"
  cp "$skill_dir/SKILL.md" "$system_home/skills/$name/SKILL.md"
done < <(find "$source_root/skills" -mindepth 1 -maxdepth 1 -type d | sort)

echo "Installed system-level Windsurf assets at: $system_home"
