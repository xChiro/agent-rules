#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
windsurf_home="${WINDSURF_HOME:-$HOME/.codeium/windsurf}"
codeium_home="${CODEIUM_HOME:-$HOME/.codeium}"
system_home="${SYSTEM_WINDSURF_HOME:-/Library/Application Support/Windsurf}"
backup_root="$windsurf_home/agent-rules-backups/$(date +%Y%m%d-%H%M%S)"
canonical="$windsurf_home/common"

bash "$repo_root/tools/validate-agent-catalog.sh"

archive_path() {
  local path="$1"
  local label="$2"

  if [[ -L "$path" ]]; then
    rm "$path"
    return
  fi

  if [[ -e "$path" ]]; then
    mkdir -p "$backup_root"
    mv "$path" "$backup_root/$label"
  fi
}

replace_with_symlink() {
  local path="$1"
  local target="$2"
  local label="$3"

  archive_path "$path" "$label"
  ln -s "$target" "$path"
}

archive_path "$canonical" "windsurf-common"
archive_path "$windsurf_home/global_workflows" "windsurf-global-workflows"
archive_path "$windsurf_home/skills" "windsurf-skills"
archive_path "$windsurf_home/memories/global_rules.md" "windsurf-global-rules-memory.md"
archive_path "$windsurf_home/global_rules.md" "windsurf-global-rules-legacy.md"

mkdir -p "$canonical/rules" "$canonical/workflows" "$canonical/skills" "$canonical/templates" "$canonical/languages"
cp -R "$repo_root/common/rules/." "$canonical/rules/"
cp -R "$repo_root/common/workflows/." "$canonical/workflows/"
cp -R "$repo_root/common/skills/." "$canonical/skills/"
cp -R "$repo_root/common/templates/." "$canonical/templates/"
cp -R "$repo_root/languages/." "$canonical/languages/"
cp "$repo_root/README.md" "$canonical/README.md"

mkdir -p "$windsurf_home/global_workflows"
while IFS= read -r workflow; do
  cp "$workflow" "$windsurf_home/global_workflows/$(basename "$workflow")"
done < <(find "$repo_root/common/workflows" "$repo_root/languages" -type f -name '*.workflow.md' | sort)

mkdir -p "$windsurf_home/skills"
while IFS= read -r skill; do
  name="$(sed -n 's/^name: //p' "$skill" | head -1)"
  if [[ -z "$name" ]]; then
    echo "Skill is missing required name metadata: $skill" >&2
    exit 1
  fi

  mkdir -p "$windsurf_home/skills/$name"
  cp "$skill" "$windsurf_home/skills/$name/SKILL.md"
done < <(find "$repo_root/common/skills" "$repo_root/languages" -type f -path '*/skills/*.md' | sort)

# JetBrains Cascade discovers system-level assets on macOS. Keep this catalog
# derived from the same source so projects do not need .windsurf copies. A
# managed macOS account may need an administrator to create this directory.
system_installable=1
install_system_assets() {
  mkdir -p "$system_home/rules" "$system_home/workflows" "$system_home/skills" "$system_home/templates"
  cp "$script_dir/global-rules.md" "$system_home/rules/agent-rules-global.md"
  cp "$windsurf_home/global_workflows"/*.workflow.md "$system_home/workflows/"
  cp "$canonical/templates"/*.md "$system_home/templates/"
  while IFS= read -r skill_dir; do
    name="$(basename "$skill_dir")"
    mkdir -p "$system_home/skills/$name"
    cp "$skill_dir/SKILL.md" "$system_home/skills/$name/SKILL.md"
  done < <(find "$windsurf_home/skills" -mindepth 1 -maxdepth 1 -type d | sort)
}

if ! install_system_assets 2>/dev/null; then
  system_installable=0
  echo "WARN: cannot write $system_home; run tools/windsurf/install-system.sh with administrator privileges for JetBrains global workflows." >&2
fi

mkdir -p "$windsurf_home/memories"
cp "$script_dir/global-rules.md" "$windsurf_home/memories/global_rules.md"
ln -s "memories/global_rules.md" "$windsurf_home/global_rules.md"

if [[ "${SKIP_MCP_CONFIG:-0}" == "1" ]]; then
  echo "Skipped MCP JSON configuration (SKIP_MCP_CONFIG=1)."
else
  "$script_dir/configure-mcp.sh"
fi

archive_path "$codeium_home/common" "codeium-common"
archive_path "$codeium_home/global_workflows" "codeium-global-workflows"
archive_path "$codeium_home/skills" "codeium-skills"
archive_path "$codeium_home/global_rules.md" "codeium-global-rules-legacy.md"
archive_path "$codeium_home/memories/global_rules.md" "codeium-global-rules-memory.md"

mkdir -p "$codeium_home/memories"
replace_with_symlink "$codeium_home/common" "$canonical" "codeium-common"
replace_with_symlink "$codeium_home/global_workflows" "$windsurf_home/global_workflows" "codeium-global-workflows"
replace_with_symlink "$codeium_home/skills" "$windsurf_home/skills" "codeium-skills"
replace_with_symlink "$codeium_home/global_rules.md" "$windsurf_home/memories/global_rules.md" "codeium-global-rules-legacy.md"
replace_with_symlink "$codeium_home/memories/global_rules.md" "$windsurf_home/memories/global_rules.md" "codeium-global-rules-memory.md"

source_revision="uncommitted"
if git -C "$repo_root" rev-parse --verify HEAD >/dev/null 2>&1; then
  source_revision="$(git -C "$repo_root" rev-parse HEAD)"
fi

{
  echo "source=$repo_root"
  echo "revision=$source_revision"
  echo "installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$canonical/install-info.txt"

find "$canonical" "$windsurf_home/global_workflows" "$windsurf_home/skills" -type f ! -name 'manifest.sha256' -print0 \
  | sort -z \
  | xargs -0 shasum -a 256 \
  > "$canonical/manifest.sha256"

if [[ -d "$backup_root" ]]; then
  echo "Previous global customizations archived at: $backup_root"
fi

echo "Installed canonical assets at: $canonical"
echo "Published workflows at: $windsurf_home/global_workflows"
echo "Published skills at: $windsurf_home/skills"
echo "Published global rules at: $windsurf_home/memories/global_rules.md"
if [[ "$system_installable" -eq 0 ]]; then
  echo "JetBrains system-level publication was skipped; an administrator can run tools/windsurf/install-system.sh."
fi
