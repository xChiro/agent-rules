#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sync-project.sh <project-path>

This cleanup removes project-local files previously managed by agent-rules.
Canonical rules, skills, and workflows are installed globally with
tools/windsurf/install-global.sh.

Project-specific .windsurf files without the marker are preserved.
EOF
}

project_path="${1:-}"
extra_arg="${2:-}"
marker="<!-- managed-by: agent-rules/tools/windsurf/sync-project.sh -->"
managed_ids='^(rule_id: RULE-(COMMON|GO|CSHARP|REACT|WEB)_|workflow_id: WORKFLOW-(COMMON|GO|CSHARP|REACT|WEB)_|skill_id: SKILL-(COMMON|GO|CSHARP|REACT|WEB)_)'

if [[ -z "$project_path" || "$project_path" == "-h" || "$project_path" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$project_path" ]]; then
  echo "Project path does not exist: $project_path" >&2
  exit 1
fi

if [[ -n "$extra_arg" ]]; then
  echo "Profiles are no longer supported. Project-local copies are cleaned, not synced." >&2
  usage
  exit 1
fi

windsurf_dir="$project_path/.windsurf"

remove_managed_files() {
  [[ -d "$windsurf_dir" ]] || return 0

  find "$windsurf_dir/rules" "$windsurf_dir/skills" "$windsurf_dir/workflows" -type f \( -name '*.md' -o -name '*.workflow.md' \) 2>/dev/null | while read -r file; do
    if grep -Fq "$marker" "$file" || grep -Eq "$managed_ids" "$file"; then
      rm -f "$file"
    fi
  done

  rmdir "$windsurf_dir/rules" "$windsurf_dir/skills" "$windsurf_dir/workflows" "$windsurf_dir" 2>/dev/null || true
}

remove_managed_files

count_files() {
  local dir="$1"

  if [[ ! -d "$dir" ]]; then
    echo "0"
    return
  fi

  find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' '
}

rules_count="$(count_files "$windsurf_dir/rules")"
skills_count="$(count_files "$windsurf_dir/skills")"
workflows_count="$(count_files "$windsurf_dir/workflows")"

echo "Cleaned $(basename "$project_path"): $rules_count rules, $skills_count skills, $workflows_count workflows remain"
