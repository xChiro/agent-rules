#!/usr/bin/env bash
set -euo pipefail

# Validate the structural SDD contract for a change, including domain-model
# evidence, canonical layer scope, inside-out task order, and gate routing.
# Repository-native test runners remain responsible for behavior and coverage.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
policy_root="$(cd "$script_dir/.." && pwd)"
project_root="${PROJECT_ROOT:-$policy_root}"

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
  --root <directory> Validate paths and Git state in this project root.
  --context-used <0-100>
                     Require a context checkpoint when usage is at least 60%.
  --help             Show this help.

Environment equivalents: BASE_REF, HEAD_REF, RISK_LEVEL, CHANGED_FILE_LIST, PROJECT_ROOT, CONTEXT_USED_PERCENT.
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
    --root)
      project_root="${2:?missing value for --root}"
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

[[ -d "$project_root" ]] || { echo "Project root not found: $project_root" >&2; exit 2; }
project_root="$(cd "$project_root" && pwd)"
cd "$project_root"

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
  bdd_absolute_files=()
  for file in "${bdd_files[@]}"; do
    bdd_absolute_files+=("$project_root/$file")
  done
  if ! bash "$policy_root/tools/validate-bdd-spec.sh" "${bdd_absolute_files[@]}"; then
    fail "BDD acceptance specification validation failed"
  fi
fi

# Go permits the popular testify/assert and testify/require assertion helpers.
# Mocking frameworks and generated mocks remain prohibited for the standard
# unit-test policy.
go_test_dependency_pattern='github.com/stretchr/testify/mock|github.com/golang/mock|go.uber.org/mock|github.com/vektra/mockery|github.com/onsi/gomega|github.com/smartystreets/goconvey'
for go_mod_file in "${changed_files[@]}"; do
  [[ "$go_mod_file" == "go.mod" || "$go_mod_file" == */go.mod ]] || continue
  [[ -f "$go_mod_file" ]] || continue
  added_go_mod_lines=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git ls-files --error-unmatch "$go_mod_file" >/dev/null 2>&1; then
    if [[ -n "$base_ref" ]]; then
      added_go_mod_lines="$(git diff --unified=0 "$base_ref...$head_ref" -- "$go_mod_file"; git diff --unified=0 -- "$go_mod_file")"
    else
      added_go_mod_lines="$(git diff --unified=0 -- "$go_mod_file")"
    fi
    if printf '%s\n' "$added_go_mod_lines" | rg '^\+[^+].*('"$go_test_dependency_pattern"')' | rg -v '//[[:space:]]*indirect' >/dev/null; then
      fail "$go_mod_file adds a prohibited direct third-party mocking/assertion dependency"
    fi
  elif rg -n "$go_test_dependency_pattern" "$go_mod_file" | rg -v '//[[:space:]]*indirect' >/dev/null; then
    fail "new $go_mod_file contains a prohibited direct third-party mocking/assertion dependency"
  fi
done
for file in "${changed_files[@]}"; do
  if [[ "$file" == *_test.go && -f "$file" ]] && rg -n "$go_test_dependency_pattern" "$file" >/dev/null; then
    fail "Go test imports a prohibited mocking/assertion library: $file"
  fi
done

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
has_backend_production=0
has_go_production=0
has_csharp_production=0
has_spec=0
has_acceptance=0
has_traceability=0
has_tasks=0
has_workflow_routing=0
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
  if is_production_file "$file"; then
    case "$file" in
      *.go|*.cs|*/domain/*|*/application/*|*/infrastructure/*|*/interface/*|*/composition/*)
        has_backend_production=1
        ;;
    esac
    [[ "$file" == *.go ]] && has_go_production=1
    [[ "$file" == *.cs ]] && has_csharp_production=1
  fi
  [[ "$file" == specs/features/*/spec.md || "$file" == specs/features/*/change-summary.md || "$file" == specs/features/*/plan.md || "$file" == specs/features/*/spec-adjustment-request.md ]] && has_spec=1
  [[ "$file" == specs/features/*/acceptance.feature ]] && has_acceptance=1
  [[ "$file" == specs/features/*/traceability.yaml ]] && has_traceability=1
  [[ "$file" == specs/features/*/tasks.md ]] && has_tasks=1
  [[ "$file" == specs/features/*/workflow-routing.md ]] && has_workflow_routing=1
  [[ "$file" == specs/features/*/red-green-refactor.md ]] && has_report=1
  [[ "$file" == specs/features/*/verification.md ]] && has_verification=1
  [[ "$file" == specs/features/*/handoffs/* ]] && has_handoff=1
  [[ "$file" == specs/features/*/handoffs/context-checkpoints/* || "$file" == specs/features/*/handoffs/latest-context-handoff.md ]] && has_context_checkpoint=1
  [[ "$file" == specs/features/*/parallel-tracks.md ]] && has_parallel_tracks=1
  [[ "$file" == specs/features/*/mutation-report.md || "$file" == *mutation* ]] && has_mutation=1
  [[ "$file" == specs/features/*/critical-e2e.md || "$file" == *e2e* || "$file" == *playwright* || "$file" == *cypress* ]] && has_e2e=1
done

changed_paths_matching() {
  local pattern="$1"
  local file
  for file in "${changed_files[@]}"; do
    [[ "$file" == $pattern ]] && printf '%s\n' "$file"
  done
  return 0
}

layer_status() {
  local layer="$1"
  local plan_file="$2"
  sed -nE "s/^[[:space:]-]*${layer}:[[:space:]]*(affected|not_affected)[[:space:]]*$/\\1/p" "$plan_file" | head -1
}

validate_domain_first_plan() {
  local plan_file="$1"
  local domain_status
  local status
  [[ -f "$plan_file" ]] || { fail "inside-out plan file does not exist: $plan_file"; return; }

  rg -q 'Domain Model And Business Policy' "$plan_file" || fail "$plan_file has no Domain Model And Business Policy section"
  rg -qi 'business capability|bounded context' "$plan_file" || fail "$plan_file does not identify the business capability or bounded context"
  rg -qi 'ubiquitous (language|terms)' "$plan_file" || fail "$plan_file does not define ubiquitous language"

  for layer in domain application boundary infrastructure interface composition; do
    status="$(layer_status "$layer" "$plan_file")"
    [[ -n "$status" ]] || fail "$plan_file has no canonical layer_scope status for $layer"
  done

  domain_status="$(layer_status domain "$plan_file")"
  if [[ "$domain_status" == "affected" ]]; then
    rg -qi 'policy owner|aggregate|value object|domain service' "$plan_file" || fail "$plan_file does not identify the domain policy owner"
    rg -qi 'invariant' "$plan_file" || fail "$plan_file does not record domain invariants"
    rg -qi 'domain event' "$plan_file" || fail "$plan_file does not record domain events"
    rg -qi 'counterexample' "$plan_file" || fail "$plan_file does not record domain counterexamples"
  elif [[ "$domain_status" == "not_affected" ]]; then
    rg -q '^domain_not_affected_reason:[[:space:]]*[^[:space:]].*$' "$plan_file" || fail "$plan_file has domain: not_affected without domain_not_affected_reason"
  fi
}

validate_inside_out_tasks() {
  local task_file="$1"
  local routing_file="$2"
  local plan_file="$3"
  local last_rank=0
  local rank=0
  local layer
  local layers=()
  local outer_affected=0
  local boundary_status

  [[ -f "$task_file" ]] || { fail "inside-out task file does not exist: $task_file"; return; }
  [[ -f "$routing_file" ]] || { fail "workflow routing file does not exist: $routing_file"; return; }

  while IFS= read -r layer; do
    [[ -n "$layer" ]] && layers+=("$layer")
  done < <(rg -o 'development_layer:[[:space:]`]*(domain|application|boundary|infrastructure|interface|composition|verification|documentation)' "$task_file" | sed -E 's/.*(domain|application|boundary|infrastructure|interface|composition|verification|documentation)$/\1/')

  [[ "${#layers[@]}" -gt 0 ]] || { fail "$task_file has no development_layer declarations"; return; }

  for layer in "${layers[@]}"; do
    case "$layer" in
      domain) rank=1 ;;
      application) rank=2 ;;
      boundary) rank=3 ;;
      infrastructure) rank=4 ;;
      interface) rank=5 ;;
      composition) rank=6 ;;
      verification|documentation) continue ;;
    esac
    if (( rank < last_rank )); then
      fail "$task_file violates domain -> application -> boundary -> infrastructure -> interface -> composition order at $layer"
      break
    fi
    last_rank="$rank"
  done

  if rg -q 'test_layer:' "$task_file" && ! rg -q 'depends_on_test_layer:[[:space:]`]*none' "$task_file"; then
    fail "$task_file has test work without depends_on_test_layer: none"
  fi

  for layer in boundary infrastructure interface composition; do
    [[ "$(layer_status "$layer" "$plan_file")" == "affected" ]] && outer_affected=1
  done
  boundary_status="$(layer_status boundary "$plan_file")"

  if [[ "$outer_affected" -eq 1 ]]; then
    [[ "$boundary_status" == "affected" ]] || fail "$plan_file must mark boundary: affected when outer production is affected"
    printf '%s\n' "${layers[@]}" | rg -q '^boundary$' || fail "$task_file has affected outer production without a boundary task"
    rg -q 'LAYER-GATE-APPLICATION' "$task_file" "$routing_file" || fail "outer production lacks LAYER-GATE-APPLICATION dependency evidence"
    rg -q 'Gate 3-BOUNDARY|gate_scope:[[:space:]]*boundary' "$routing_file" || fail "$routing_file does not route Gate 3-BOUNDARY for affected outer production"
  elif printf '%s\n' "${layers[@]}" | rg -q '^boundary$'; then
    fail "$task_file declares a boundary implementation task while every outer layer is not_affected"
  fi

  if [[ "$(layer_status composition "$plan_file")" == "affected" ]]; then
    rg -qi 'module-owned|module composition|module DI|Add<Module>Module|NewModule' "$task_file" "$routing_file" || fail "affected composition has no module-owned DI task or routing evidence"
    if [[ "$has_csharp_production" -eq 1 ]]; then
      for method_suffix in Domain Application Infrastructure Interface Module; do
        rg -q "Add([A-Za-z0-9]+|<Module>)${method_suffix}" "$task_file" "$routing_file" || fail "C# composition evidence is missing Add<Module>${method_suffix}"
      done
    fi
    if [[ "$has_go_production" -eq 1 ]]; then
      rg -qi 'NewModule|module initializer|module output|internal/.*/di' "$task_file" "$routing_file" || fail "Go composition evidence is missing the module-owned di initializer/output"
    fi
  fi
}

validate_backend_sdd_content() {
  local feature_dir
  local invariants_file
  local plan_file
  local task_file
  local routing_file
  local plan_files=()

  while IFS= read -r plan_file; do
    [[ -n "$plan_file" ]] && plan_files+=("$plan_file")
  done < <(changed_paths_matching 'specs/features/*/plan.md')

  [[ "${#plan_files[@]}" -gt 0 ]] || { fail "backend production change has no changed plan.md with domain-first evidence"; return; }

  for plan_file in "${plan_files[@]}"; do
    feature_dir="${plan_file%/plan.md}"
    task_file="$feature_dir/tasks.md"
    routing_file="$feature_dir/workflow-routing.md"
    printf '%s\n' "${changed_files[@]}" | rg -Fxq "$task_file" || { fail "$feature_dir has no changed tasks.md"; continue; }
    printf '%s\n' "${changed_files[@]}" | rg -Fxq "$routing_file" || { fail "$feature_dir has no changed workflow-routing.md"; continue; }
    validate_domain_first_plan "$plan_file"
    if [[ "$(layer_status domain "$plan_file")" == "affected" ]]; then
      invariants_file="$feature_dir/invariants.md"
      printf '%s\n' "${changed_files[@]}" | rg -Fxq "$invariants_file" || fail "$feature_dir has domain: affected without a changed invariants.md"
      [[ -f "$invariants_file" ]] || fail "domain invariant artifact does not exist: $invariants_file"
    fi
    validate_inside_out_tasks "$task_file" "$routing_file" "$plan_file"
  done
}

if [[ "$has_production" -eq 1 ]]; then
  [[ "$has_test" -eq 1 ]] || fail "production behavior changed without a changed unit/component/integration test"
fi

if [[ "$has_backend_production" -eq 1 ]]; then
  validate_backend_sdd_content
fi

if [[ "$risk_level" == "L2" || "$risk_level" == "L3" ]]; then
  [[ "$has_spec" -eq 1 ]] || fail "L2/L3 change has no changed owning spec artifact under specs/features"
  [[ "$has_acceptance" -eq 1 ]] || fail "L2/L3 change has no acceptance.feature"
  [[ "$has_traceability" -eq 1 ]] || fail "L2/L3 change has no traceability.yaml"
  [[ "$has_tasks" -eq 1 ]] || fail "L2/L3 change has no inside-out tasks.md"
  [[ "$has_workflow_routing" -eq 1 ]] || fail "L2/L3 change has no workflow-routing.md for scoped Gate 3 and layer gates"
  [[ "$has_report" -eq 1 || "$has_verification" -eq 1 ]] || fail "L2/L3 change has no red-green-refactor.md or verification.md evidence"
fi

if [[ "$risk_level" == "L1" && "$has_production" -eq 1 ]]; then
  [[ "$has_spec" -eq 1 ]] || fail "L1 production change has no owning spec or refactor artifact under specs/features"
  [[ "$has_tasks" -eq 1 ]] || fail "L1 production change has no inside-out tasks.md"
  [[ "$has_workflow_routing" -eq 1 ]] || fail "L1 production change has no workflow-routing.md for scoped Gate 3 and layer gates"
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
