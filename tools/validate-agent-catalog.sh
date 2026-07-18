#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="${AGENT_CATALOG_ROOT:-$(cd "$script_dir/.." && pwd)}"
catalog_failed=0
catalog_ids=()
skill_names=()

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  catalog_failed=1
}

to_constant() {
  printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_'
}

metadata_value() {
  local metadata_key="$1" catalog_file="$2"
  awk -v key="$metadata_key" '
    NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    index($0, key ":") == 1 {
      value = $0; sub(/^[^:]+:[[:space:]]*/, "", value); print value; exit
    }
  ' "$catalog_file"
}

validate_frontmatter() {
  local catalog_file="$1"
  [[ "$(sed -n '1p' "$catalog_file")" == '---' ]] || fail "$catalog_file does not start with YAML frontmatter"
  awk 'NR > 1 && $0 == "---" { found=1; exit } END { exit !found }' "$catalog_file" || fail "$catalog_file has no closing frontmatter delimiter"
  [[ -n "$(metadata_value description "$catalog_file")" ]] || fail "$catalog_file has no frontmatter description"
  rg -q '^# [^#]' "$catalog_file" || fail "$catalog_file has no human-readable H1 title"
}

validate_rule() {
  local catalog_file="$1" file_name stem expected_id actual_id trigger
  file_name="${catalog_file##*/}"
  stem="${file_name%.md}"
  expected_id="RULE-$(to_constant "$stem")"
  validate_frontmatter "$catalog_file"
  actual_id="$(metadata_value rule_id "$catalog_file")"
  trigger="$(metadata_value trigger "$catalog_file")"
  [[ "$actual_id" == "$expected_id" ]] || fail "$catalog_file expected rule_id $expected_id, found ${actual_id:-missing}"
  [[ "$trigger" == 'always_on' || "$trigger" == 'model_decision' ]] || fail "$catalog_file has invalid rule trigger ${trigger:-missing}"
  catalog_ids+=("$actual_id")
}

validate_workflow() {
  local catalog_file="$1" file_name stem expected_id actual_id trigger
  file_name="${catalog_file##*/}"
  stem="${file_name%.workflow.md}"
  expected_id="WORKFLOW-$(to_constant "$stem")_WORKFLOW"
  validate_frontmatter "$catalog_file"
  actual_id="$(metadata_value workflow_id "$catalog_file")"
  trigger="$(metadata_value trigger "$catalog_file")"
  [[ "$actual_id" == "$expected_id" ]] || fail "$catalog_file expected workflow_id $expected_id, found ${actual_id:-missing}"
  [[ "$trigger" == 'manual' || "$trigger" == 'model_decision' || "$trigger" == 'automatic' ]] || fail "$catalog_file has invalid workflow trigger ${trigger:-missing}"
  catalog_ids+=("$actual_id")
}

validate_skill() {
  local catalog_file="$1" file_name stem expected_id expected_name actual_id actual_name trigger
  file_name="${catalog_file##*/}"
  stem="${file_name%.md}"
  expected_id="SKILL-$(to_constant "$stem")"
  expected_name="${file_name%-skill.md}"
  validate_frontmatter "$catalog_file"
  actual_id="$(metadata_value skill_id "$catalog_file")"
  actual_name="$(metadata_value name "$catalog_file")"
  trigger="$(metadata_value trigger "$catalog_file")"
  [[ "$actual_id" == "$expected_id" ]] || fail "$catalog_file expected skill_id $expected_id, found ${actual_id:-missing}"
  [[ "$actual_name" == "$expected_name" ]] || fail "$catalog_file expected name $expected_name, found ${actual_name:-missing}"
  [[ "$trigger" == 'always_on' || "$trigger" == 'model_decision' ]] || fail "$catalog_file has invalid skill trigger ${trigger:-missing}"
  catalog_ids+=("$actual_id")
  skill_names+=("$actual_name")
}

while IFS= read -r catalog_file; do
  validate_rule "$catalog_file"
done < <(find "$repo_root/common/rules" "$repo_root/languages" -type f -path '*/rules/*.md' | sort)

while IFS= read -r catalog_file; do
  validate_workflow "$catalog_file"
done < <(find "$repo_root/common/workflows" "$repo_root/languages" -type f -name '*.workflow.md' | sort)

while IFS= read -r catalog_file; do
  validate_skill "$catalog_file"
done < <(find "$repo_root/common/skills" "$repo_root/languages" -type f -path '*/skills/*.md' | sort)

duplicate_ids="$(printf '%s\n' "${catalog_ids[@]}" | sort | uniq -d)"
[[ -z "$duplicate_ids" ]] || fail "duplicate catalog IDs: $duplicate_ids"
duplicate_skill_names="$(printf '%s\n' "${skill_names[@]}" | sort | uniq -d)"
[[ -z "$duplicate_skill_names" ]] || fail "duplicate skill names: $duplicate_skill_names"
validate_id_references() {
  local label="$1"
  local reference_pattern="$2"
  local metadata_key="$3"
  local undefined_ids

  undefined_ids="$(comm -23 \
    <(rg -o --no-filename -P "$reference_pattern" "$repo_root/README.md" "$repo_root/common" "$repo_root/languages" "$repo_root/tools/windsurf/global-rules.md" | sort -u) \
    <(rg -o --no-filename "^${metadata_key}:[[:space:]]*[A-Z]+-[A-Z0-9_]+" "$repo_root/common" "$repo_root/languages" | sed -E "s/^${metadata_key}:[[:space:]]*//" | sort -u))"
  [[ -z "$undefined_ids" ]] || fail "undefined $label ID references: $undefined_ids"
}
validate_id_references rule '(?<![A-Z0-9_-])RULE-[A-Z0-9]+(?:_[A-Z0-9]+)+(?![A-Z0-9_-])' rule_id
validate_id_references workflow '(?<![A-Z0-9_-])WORKFLOW-[A-Z0-9]+(?:_[A-Z0-9]+)+_WORKFLOW(?![A-Z0-9_-])' workflow_id
validate_id_references skill '(?<![A-Z0-9_-])SKILL-[A-Z0-9]+(?:_[A-Z0-9]+)+_SKILL(?![A-Z0-9_-])' skill_id
undefined_catalog_files="$(comm -23 \
  <(rg -o --no-filename -P '\x60(?:common|go|csharp|react|web)-[^\x60 ]+\.md\x60' "$repo_root/README.md" "$repo_root/common" "$repo_root/languages" "$repo_root/tools/windsurf/global-rules.md" | sed 's/^.//; s/.$//' | sort -u) \
  <(find "$repo_root/common" "$repo_root/languages" -type f -name '*.md' -exec basename {} \; | sort -u))"
[[ -z "$undefined_catalog_files" ]] || fail "undefined catalog filename references: $undefined_catalog_files"
while IFS= read -r markdown_file; do
  markdown_dir="$(dirname "$markdown_file")"
  while IFS= read -r raw_link; do
    relative_link="${raw_link#<}"
    relative_link="${relative_link%>}"
    relative_link="${relative_link%%#*}"
    [[ -e "$markdown_dir/$relative_link" ]] || fail "$markdown_file has broken relative link $raw_link"
  done < <(perl -ne 'while (/\]\(((?:<)?\.\.?\/[^)#]+(?:>)?)(?:#[^)]*)?\)/g) { print "$1\n" }' "$markdown_file")
done < <(find "$repo_root" -type f -name '*.md' ! -path '*/.git/*' | sort)

always_on_lines=0
while IFS= read -r always_on_file; do
  file_lines="$(wc -l < "$always_on_file" | tr -d ' ')"
  always_on_lines=$((always_on_lines + file_lines))
done < <(rg -l '^trigger: always_on$' "$repo_root/common" "$repo_root/languages")
[[ "$always_on_lines" -le 2500 ]] || fail "always_on catalog footprint is $always_on_lines lines; limit is 2500"
global_rule_bytes="$(wc -c < "$repo_root/tools/windsurf/global-rules.md" | tr -d ' ')"
[[ "$global_rule_bytes" -le 6000 ]] || fail "global-rules.md is $global_rule_bytes bytes; limit is 6000"
if rg -n -P '^(?:description|globs): (?!".*"$)' "$repo_root/common" "$repo_root/languages" >/dev/null; then
  fail 'description and globs frontmatter values must be quoted YAML strings'
fi
if rg -n '≤150|150 lines or less|exceed 150' "$repo_root/common" "$repo_root/languages" >/dev/null; then
  fail 'file-size wording conflicts with the canonical <150 physical-line limit'
fi

if rg -n -P 'Gate[ _-]?4|GATE[ _-]?4|Gates?\s*1\s*[–—-]\s*4|WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW|common-sdd-complete-spec\.workflow\.md' \
  "$repo_root/README.md" "$repo_root/common" "$repo_root/languages" "$repo_root/tools/windsurf/global-rules.md" >/dev/null; then
  fail 'legacy completion lifecycle conflicts with stable-path final validation'
fi

if [[ "$catalog_failed" -ne 0 ]]; then
  exit 1
fi

printf 'PASS: agent catalog metadata, IDs, links, loading budget, and shared thresholds\n'
