#!/usr/bin/env bash
set -euo pipefail

# Validate the language boundary of business scenarios. This is intentionally
# small: it checks structure and obvious implementation leakage, not meaning.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

failed=0
files=()

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  while IFS= read -r file; do
    [[ -n "$file" ]] && files+=("$file")
  done < <(
    {
      git diff --name-only --diff-filter=ACMR HEAD
      git status --porcelain=v1 | sed -E 's/^.. //; s/^"//; s/"$//'
    } | sed '/^[[:space:]]*$/d' | sort -u | awk '/(^|\/)acceptance\.feature$/ { print }'
  )
fi

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "PASS: no acceptance.feature files to validate"
  exit 0
fi

fail() {
  echo "FAIL: $*" >&2
  failed=1
}

for file in "${files[@]}"; do
  [[ -f "$file" ]] || { fail "acceptance file not found: $file"; continue; }

  report=""
  if ! report="$(awk '
    function issue(message) {
      print "line " NR ": " message
      errors++
    }
    function finish_scenario() {
      if (scenario == 0) return
      if (!scenario_tags) issue("scenario requires @US-*, @REQ-*, and @SCN-* tags")
      if (!given) issue("scenario requires Given")
      if (!when) issue("scenario requires When")
      if (!then) issue("scenario requires Then")
    }
    BEGIN {
      feature = 0
      scenario = 0
      scenario_tags = 0
      pending_tags = 0
      given = 0
      when = 0
      then = 0
      errors = 0
    }
    /^[[:space:]]*Feature:/ {
      feature = 1
      next
    }
    /^[[:space:]]*@/ {
      if ($0 ~ /@US-[0-9]+-[0-9]+/ && $0 ~ /@REQ-[0-9]+-[0-9]+/ && $0 ~ /@SCN-[0-9]+-[0-9]+/) {
        pending_tags = 1
      }
      next
    }
    /^[[:space:]]*Scenario( Outline)?:/ {
      finish_scenario()
      scenario++
      scenario_tags = pending_tags
      pending_tags = 0
      given = 0
      when = 0
      then = 0
      next
    }
    /^[[:space:]]*(Given|When|Then|And|But)[[:space:]]/ {
      text = tolower($0)
      if (text ~ /(^|[^a-z0-9_])(screen|browser|button|click|page|selector|element|endpoint|http|api|database|sql|framework|component|mock|stub|cucumber|playwright|cypress|appium)([^a-z0-9_]|$)/ || text ~ /status[[:space:]]+code/) {
        issue("step contains delivery or implementation language")
      }
      if ($0 ~ /^[[:space:]]*Given[[:space:]]/) given = 1
      if ($0 ~ /^[[:space:]]*When[[:space:]]/) when = 1
      if ($0 ~ /^[[:space:]]*Then[[:space:]]/) then = 1
      next
    }
    END {
      finish_scenario()
      if (!feature) issue("missing Feature")
      if (!scenario) issue("missing Scenario")
      if (errors > 0) exit 1
    }
  ' "$file")"; then
    fail "$(printf '%s\n%s' "$file" "$report")"
  else
    echo "PASS: BDD structure and language boundary: $file"
  fi
done

exit "$failed"
