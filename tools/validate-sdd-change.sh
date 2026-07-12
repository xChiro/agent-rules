#!/usr/bin/env bash
set -euo pipefail

# Validate the structural SDD contract for a change. This intentionally checks
# evidence and ownership, not implementation semantics; repository-native test
# runners remain responsible for executing tests and coverage.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

base_ref="${BASE_REF:-}"
head_ref="${HEAD_REF:-HEAD}"
risk_level="${RISK_LEVEL:-}"
changed_file_list="${CHANGED_FILE_LIST:-}"
context_used="${CONTEXT_USED_PERCENT:-}"
failed=0

usage() {
  cat <<'EOF'
Usage: tools/validate-sdd-change.sh [options]

Options:
  --base <ref>       Compare <ref>...HEAD (useful in pull-request CI).
  --head <ref>       Compare against this ref instead of HEAD.
  --risk <L0|L1|L2|L3>
                     Use an explicit risk level instead of inference.
  --files <file>     Read changed paths from a newline-delimited file.
  --context-used <0-100>
                     Require a context checkpoint when usage is at least 60%.
  --help             Show this help.

Environment equivalents: BASE_REF, HEAD_REF, RISK_LEVEL, CHANGED_FILE_LIST, CONTEXT_USED_PERCENT.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_ref="${2:?missing value for --base}"
      shift 2
      ;;
    --head)
      head_ref="${2:?missing value for --head}"
      shift 2
      ;;
    --risk)
      risk_level="${2:?missing value for --risk}"
      shift 2
      ;;
    --files)
      changed_file_list="${2:?missing value for --files}"
      shift 2
      ;;
    --context-used)
      context_used="${2:?missing value for --context-used}"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$context_used" ]] && { ! [[ "$context_used" =~ ^[0-9]+$ ]] || (( context_used < 0 || context_used > 100 )); }; then
  echo "Context use must be an integer from 0 to 100: $context_used" >&2
  exit 2
fi

fail() {
  echo "FAIL: $*" >&2
  failed=1
}

pass() {
  echo "PASS: $*"
}

read_paths() {
  changed_files=()
  while IFS= read -r path; do
    [[ -n "$path" ]] && changed_files+=("$path")
  done
}

if [[ -n "$changed_file_list" ]]; then
  [[ -f "$changed_file_list" ]] || { echo "Changed-file list not found: $changed_file_list" >&2; exit 2; }
  read_paths < <(sed '/^[[:space:]]*$/d' "$changed_file_list" | sort -u)
elif [[ -n "$base_ref" ]]; then
  git rev-parse --verify "$base_ref" >/dev/null 2>&1 || { echo "Base ref not found: $base_ref" >&2; exit 2; }
  git rev-parse --verify "$head_ref" >/dev/null 2>&1 || { echo "Head ref not found: $head_ref" >&2; exit 2; }
  read_paths < <(
    {
      git diff --name-only --diff-filter=ACMR "$base_ref...$head_ref"
      git status --porcelain=v1 | sed -E 's/^.. //; s/^"//; s/"$//'
    } | sed '/^[[:space:]]*$/d' | sort -u
  )
else
  read_paths < <(
    {
      git diff --name-only --diff-filter=ACMR HEAD
      git status --porcelain=v1 | sed -E 's/^.. //; s/^"//; s/"$//'
    } | sed '/^[[:space:]]*$/d' | sort -u
  )
fi

if [[ "${#changed_files[@]}" -eq 0 ]]; then
  pass "no changed files"
  exit 0
fi

bdd_files=()
for file in "${changed_files[@]}"; do
  if [[ "$file" == */acceptance.feature && -f "$file" ]]; then
    bdd_files+=("$file")
  fi
done
if [[ "${#bdd_files[@]}" -gt 0 ]]; then
  if ! bash tools/validate-bdd-spec.sh "${bdd_files[@]}"; then
    fail "BDD acceptance specification validation failed"
  fi
fi

is_doc_or_agent_file() {
  case "$1" in
    specs/*)
      return 1
      ;;
    *.md|*.markdown|*.adoc|common/*|languages/*/rules/*|languages/*/skills/*|languages/*/workflows/*|clean-architecture-rules/*|react-rules/*|windsurf-skills/*|common/templates/*|tools/windsurf/*|tools/tests/*|tools/validate-sdd-change.sh|tools/create-sdd-context-checkpoint.sh|tools/validate-bdd-spec.sh)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_test_file() {
  case "$1" in
    *_test.go|*Test.cs|*Tests.cs|*.test.ts|*.test.tsx|*.spec.ts|*.spec.tsx|*.test.js|*.test.jsx|*.spec.js|*.spec.jsx|*.test.sh|tools/tests/*|tests/*|test/*|*/tests/*|*/test/*|__tests__/*|*/__tests__/*|*.feature)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_production_file() {
  is_doc_or_agent_file "$1" && return 1
  is_test_file "$1" && return 1
  case "$1" in
    *.go|*.cs|*.tsx|*.ts|*.jsx|*.js|*.py|*.java|*.kt|*.rs|*.rb|*.php|*.sql|*.sh)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

contains_path() {
  local pattern="$1"
  if command -v rg >/dev/null 2>&1; then
    printf '%s\n' "${changed_files[@]}" | rg -q "$pattern"
  else
    printf '%s\n' "${changed_files[@]}" | grep -Eq "$pattern"
  fi
}

infer_risk_level() {
  all_agent_files=1
  has_production=0
  for file in "${changed_files[@]}"; do
    if ! is_doc_or_agent_file "$file"; then
      all_agent_files=0
    fi
    if is_production_file "$file"; then
      has_production=1
    fi
  done

  if [[ "$all_agent_files" -eq 1 ]]; then
    echo "L0"
  elif contains_path '(^|/|[-_])(auth|identity|security|tenant|payment|billing|migration|migrations|schema|secrets|oauth|oidc)(/|[-_.]|$)'; then
    echo "L3"
  elif [[ "$has_production" -eq 1 ]]; then
    echo "L2"
  else
    echo "L1"
  fi
}

inferred_risk_level="$(infer_risk_level)"
if [[ -z "$risk_level" ]]; then
  risk_level="$inferred_risk_level"
else
  case "$risk_level:$inferred_risk_level" in
    L0:L1|L0:L2|L0:L3|L1:L2|L1:L3|L2:L3)
      fail "explicit risk $risk_level is lower than the path-inferred risk $inferred_risk_level"
      ;;
  esac
fi

case "$risk_level" in
  L0|L1|L2|L3) ;;
  *) echo "Invalid risk level: $risk_level" >&2; exit 2 ;;
esac

echo "SDD validation: risk=$risk_level files=${#changed_files[@]}"

if [[ "$risk_level" == "L0" ]]; then
  for file in "${changed_files[@]}"; do
    case "$file" in
      *.sh)
        bash -n "$file" || fail "shell syntax: $file"
        ;;
    esac
  done
  [[ "$failed" -eq 0 ]] && pass "L0 documentation/agent configuration checks"
  exit "$failed"
fi

has_test=0
has_production=0
has_spec=0
has_acceptance=0
has_traceability=0
has_report=0
has_verification=0
has_mutation=0
has_e2e=0
has_handoff=0
has_parallel_tracks=0
has_context_checkpoint=0

for file in "${changed_files[@]}"; do
  is_test_file "$file" && has_test=1
  is_production_file "$file" && has_production=1
  [[ "$file" == specs/features/*/spec.md || "$file" == specs/features/*/change-summary.md || "$file" == specs/features/*/plan.md || "$file" == specs/features/*/spec-adjustment-request.md ]] && has_spec=1
  [[ "$file" == specs/features/*/acceptance.feature ]] && has_acceptance=1
  [[ "$file" == specs/features/*/traceability.yaml ]] && has_traceability=1
  [[ "$file" == specs/features/*/red-green-refactor.md ]] && has_report=1
  [[ "$file" == specs/features/*/verification.md ]] && has_verification=1
  [[ "$file" == specs/features/*/handoffs/* ]] && has_handoff=1
  [[ "$file" == specs/features/*/handoffs/context-checkpoints/* || "$file" == specs/features/*/handoffs/latest-context-handoff.md ]] && has_context_checkpoint=1
  [[ "$file" == specs/features/*/parallel-tracks.md ]] && has_parallel_tracks=1
  [[ "$file" == specs/features/*/mutation-report.md || "$file" == *mutation* ]] && has_mutation=1
  [[ "$file" == specs/features/*/critical-e2e.md || "$file" == *e2e* || "$file" == *playwright* || "$file" == *cypress* ]] && has_e2e=1
done

if [[ "$has_production" -eq 1 ]]; then
  [[ "$has_test" -eq 1 ]] || fail "production behavior changed without a changed unit/component/integration test"
fi

if [[ "$risk_level" == "L2" || "$risk_level" == "L3" ]]; then
  [[ "$has_spec" -eq 1 ]] || fail "L2/L3 change has no changed owning spec artifact under specs/features"
  [[ "$has_acceptance" -eq 1 ]] || fail "L2/L3 change has no acceptance.feature"
  [[ "$has_traceability" -eq 1 ]] || fail "L2/L3 change has no traceability.yaml"
  [[ "$has_report" -eq 1 || "$has_verification" -eq 1 ]] || fail "L2/L3 change has no red-green-refactor.md or verification.md evidence"
fi

if [[ "$risk_level" == "L1" && "$has_production" -eq 1 ]]; then
  [[ "$has_spec" -eq 1 ]] || fail "L1 production change has no owning spec or refactor artifact under specs/features"
  [[ "$has_report" -eq 1 || "$has_verification" -eq 1 ]] || fail "L1 production change has no red-green-refactor.md or manual verification evidence"
fi

if [[ "$has_parallel_tracks" -eq 1 ]]; then
  [[ "$has_handoff" -eq 1 ]] || fail "parallel execution is declared without an append-only role handoff"
fi

if [[ -n "$context_used" && "$context_used" -ge 60 && "$risk_level" != "L0" ]]; then
  [[ "$has_context_checkpoint" -eq 1 ]] || fail "context usage is at least 60% without a context checkpoint handoff"
  [[ "$has_spec" -eq 1 && "$has_verification" -eq 1 ]] || fail "context checkpoint requires changed spec and verification artifacts"
fi

if [[ "$risk_level" == "L3" ]]; then
  [[ "$has_e2e" -eq 1 ]] || fail "L3 change has no critical E2E evidence or test path"
  [[ "$has_mutation" -eq 1 ]] || fail "L3 change has no mutation evidence or mutation workflow path"
  [[ "$has_handoff" -eq 1 ]] || fail "L3 change has no Architect/Tester/Coder/Reviewer handoff evidence"
fi

if [[ "$failed" -eq 0 ]]; then
  pass "SDD structural evidence for risk $risk_level"
else
  echo "Review the risk classification or add the missing spec/test/evidence artifacts before merging." >&2
fi

exit "$failed"
