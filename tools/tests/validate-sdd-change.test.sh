#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
validator="$repo_root/tools/validate-sdd-change.sh"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/validate-sdd-change.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

failed=0

assert_status() {
  local expected="$1"
  local name="$2"
  local list_file="$3"
  shift 3

  local output
  local actual
  set +e
  output="$(bash "$validator" --files "$list_file" "$@" 2>&1)"
  actual=$?
  set -e

  if [[ "$actual" -ne "$expected" ]]; then
    echo "FAIL: $name (expected status $expected, got $actual)" >&2
    echo "$output" >&2
    failed=1
  else
    echo "PASS: $name"
  fi
}

write_list() {
  local name="$1"
  shift
  local path="$tmp_dir/$name"
  printf '%s\n' "$@" > "$path"
  printf '%s\n' "$path"
}

l0_list="$(write_list l0 \
  README.md \
  common/rules/common-change-risk-classification.md \
  common/workflows/common-sdd-validate-change.workflow.md)"
assert_status 0 "L0 catalog change" "$l0_list" --risk L0

l1_list="$(write_list l1 \
  src/ui/NotificationBell.tsx)"
assert_status 1 "L1 production change without evidence" "$l1_list" --risk L1

l2_list="$(write_list l2 \
  src/domain/notification-policy.ts \
  src/domain/notification-policy.test.ts \
  specs/features/0001-notification-policy/spec.md \
  specs/features/0001-notification-policy/spec-adjustment-request.md \
  specs/features/0001-notification-policy/acceptance.feature \
  specs/features/0001-notification-policy/traceability.yaml \
  specs/features/0001-notification-policy/red-green-refactor.md)"
assert_status 0 "L2 change with SDD evidence" "$l2_list" --risk L2
assert_status 1 "context checkpoint is required at 60 percent" "$l2_list" --risk L2 --context-used 60
printf '%s\n' \
  specs/features/0001-notification-policy/verification.md \
  specs/features/0001-notification-policy/handoffs/context-checkpoints/CHECKPOINT-TEST-001.md \
  >> "$l2_list"
assert_status 0 "L2 change with context handoff" "$l2_list" --risk L2 --context-used 60

l3_list="$(write_list l3 \
  src/auth/tenant-policy.go \
  src/auth/tenant-policy_test.go \
  specs/features/0002-tenant-policy/spec.md \
  specs/features/0002-tenant-policy/acceptance.feature \
  specs/features/0002-tenant-policy/traceability.yaml \
  specs/features/0002-tenant-policy/red-green-refactor.md \
  specs/features/0002-tenant-policy/mutation-report.md \
  specs/features/0002-tenant-policy/critical-e2e.md \
  specs/features/0002-tenant-policy/handoffs/HANDOFF-0002-001.md)"
assert_status 0 "L3 critical change with all gates" "$l3_list" --risk L3

lower_risk_list="$(write_list lower-risk \
  src/auth/tenant-policy.go \
  src/auth/tenant-policy_test.go)"
assert_status 1 "lower explicit risk is rejected" "$lower_risk_list" --risk L2

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
