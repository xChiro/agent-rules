#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
validator="$repo_root/tools/validate-sdd-change.sh"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/validate-sdd-change.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
project_root="$tmp_dir/project"
mkdir -p "$project_root/specs/features/0001-notification-policy" \
  "$project_root/specs/features/0002-tenant-policy/handoffs" \
  "$project_root/src/domain" "$project_root/src/auth"

failed=0

assert_status() {
  local expected="$1"
  local name="$2"
  local list_file="$3"
  shift 3

  local output
  local actual
  set +e
  output="$(bash "$validator" --root "$project_root" --files "$list_file" "$@" 2>&1)"
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

write_file() {
  local path="$1"
  shift
  mkdir -p "$(dirname "$project_root/$path")"
  printf '%s\n' "$@" > "$project_root/$path"
}

write_backend_evidence() {
  local feature="$1"
  local directory="specs/features/$feature"

  write_file "$directory/spec.md" '# Notification policy'
  write_file "$directory/spec-adjustment-request.md" '# Adjustment'
  write_file "$directory/acceptance.feature" \
    'Feature: Notification retry policy' \
    '  @US-0001-001 @REQ-0001-001 @SCN-0001-001' \
    '  Scenario: Reject a retry after the configured limit' \
    '    Given a notification exhausted its retry allowance' \
    '    When delivery is requested again' \
    '    Then the retry is rejected'
  write_file "$directory/plan.md" \
    '# Domain Model And Business Policy' \
    '- Business capability: notification delivery' \
    '- Bounded context: notifications' \
    '- Ubiquitous language: retry allowance means remaining delivery attempts' \
    '- Policy owner: Notification aggregate' \
    '- Invariant: exhausted notifications cannot retry' \
    '- Domain event: NotificationRetryRejected becomes true after rejection' \
    '- Counterexample: a notification with allowance may retry' \
    '' \
    'layer_scope:' \
    '  domain: affected' \
    '  application: affected' \
    '  boundary: affected' \
    '  infrastructure: affected' \
    '  interface: affected' \
    '  composition: affected'
  write_file "$directory/invariants.md" \
    '# Notification invariants' \
    '- Exhausted notifications cannot retry.'
  write_file "$directory/tasks.md" \
    '- development_layer: domain' \
    '  test_layer: domain' \
    '  depends_on_test_layer: none' \
    '- development_layer: application' \
    '  test_layer: application' \
    '  depends_on_test_layer: none' \
    '- development_layer: boundary' \
    '  test_layer: boundary' \
    '  depends_on_test_layer: none' \
    '  depends_on: LAYER-GATE-APPLICATION' \
    '- development_layer: infrastructure' \
    '- development_layer: interface' \
    '- development_layer: composition' \
    '  outcome: Add module-owned DI with NewModule'
  write_file "$directory/workflow-routing.md" \
    '- Gate 3-DOMAIN' \
    '- Gate 3-APPLICATION' \
    '- Gate 3-BOUNDARY' \
    '- LAYER-GATE-APPLICATION' \
    '- module-owned DI'
  write_file "$directory/traceability.yaml" 'feature_id: FEAT-0001'
  write_file "$directory/red-green-refactor.md" '# RED Green Refactor'
  write_file "$directory/verification.md" '# Verification'
}

write_backend_evidence '0001-notification-policy'
write_backend_evidence '0002-tenant-policy'
write_file 'src/domain/notification-policy.go' 'package domain'
write_file 'src/domain/notification-policy_test.go' 'package domain'
write_file 'src/auth/tenant-policy.go' 'package auth'
write_file 'src/auth/tenant-policy_test.go' 'package auth'

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
  src/domain/notification-policy.go \
  src/domain/notification-policy_test.go \
  specs/features/0001-notification-policy/spec.md \
  specs/features/0001-notification-policy/spec-adjustment-request.md \
  specs/features/0001-notification-policy/acceptance.feature \
  specs/features/0001-notification-policy/invariants.md \
  specs/features/0001-notification-policy/plan.md \
  specs/features/0001-notification-policy/tasks.md \
  specs/features/0001-notification-policy/workflow-routing.md \
  specs/features/0001-notification-policy/traceability.yaml \
  specs/features/0001-notification-policy/red-green-refactor.md)"
assert_status 0 "L2 change with SDD evidence" "$l2_list" --risk L2

l2_missing_invariants_list="$(write_list l2-missing-invariants \
  src/domain/notification-policy.go \
  src/domain/notification-policy_test.go \
  specs/features/0001-notification-policy/spec.md \
  specs/features/0001-notification-policy/acceptance.feature \
  specs/features/0001-notification-policy/plan.md \
  specs/features/0001-notification-policy/tasks.md \
  specs/features/0001-notification-policy/workflow-routing.md \
  specs/features/0001-notification-policy/traceability.yaml \
  specs/features/0001-notification-policy/red-green-refactor.md)"
assert_status 1 "domain change without invariants artifact is rejected" "$l2_missing_invariants_list" --risk L2

l2_missing_layer_plan_list="$(write_list l2-missing-layer-plan \
  src/domain/notification-policy.go \
  src/domain/notification-policy_test.go \
  specs/features/0001-notification-policy/spec.md \
  specs/features/0001-notification-policy/acceptance.feature \
  specs/features/0001-notification-policy/traceability.yaml \
  specs/features/0001-notification-policy/red-green-refactor.md)"
assert_status 1 "L2 change without inside-out tasks and routing" "$l2_missing_layer_plan_list" --risk L2

write_file 'specs/features/0001-notification-policy/plan.md' \
  '# Domain Model And Business Policy' \
  '- Business capability: notification delivery' \
  '- Ubiquitous language: retry allowance means remaining delivery attempts' \
  '- Policy owner: Notification aggregate' \
  '- Invariant: exhausted notifications cannot retry' \
  '- Domain event: NotificationRetryRejected' \
  '- Counterexample: a notification with allowance may retry' \
  'layer_scope:' \
  '  domain: affected' \
  '  application: affected' \
  '  boundary: not_affected' \
  '  infrastructure: not_affected' \
  '  interface: not_affected' \
  '  composition: not_affected'
write_file 'specs/features/0001-notification-policy/tasks.md' \
  '- development_layer: domain' \
  '  test_layer: domain' \
  '  depends_on_test_layer: none' \
  '- development_layer: application' \
  '  test_layer: application' \
  '  depends_on_test_layer: none'
write_file 'specs/features/0001-notification-policy/workflow-routing.md' \
  '- Gate 3-DOMAIN' \
  '- Gate 3-APPLICATION'
assert_status 0 "core-only change does not manufacture Boundary RED" "$l2_list" --risk L2
write_backend_evidence '0001-notification-policy'

write_file 'specs/features/0001-notification-policy/tasks.md' \
  '- development_layer: domain' \
  '- development_layer: application' \
  '  depends_on: LAYER-GATE-APPLICATION' \
  '- development_layer: infrastructure' \
  '- development_layer: interface' \
  '- development_layer: composition' \
  '  outcome: Add module-owned DI with NewModule'
assert_status 1 "outer change without Boundary task is rejected" "$l2_list" --risk L2
write_backend_evidence '0001-notification-policy'

bad_order_tasks='specs/features/0001-notification-policy/tasks-bad-order.md'
write_file "$bad_order_tasks" \
  '- development_layer: application' \
  '- development_layer: domain' \
  '- development_layer: boundary' \
  '- development_layer: infrastructure'
cp "$project_root/$bad_order_tasks" "$project_root/specs/features/0001-notification-policy/tasks.md"
assert_status 1 "L2 change with out-of-order layer tasks" "$l2_list" --risk L2
write_backend_evidence '0001-notification-policy'

missing_domain_plan='specs/features/0001-notification-policy/plan.md'
write_file "$missing_domain_plan" \
  '# Technical Plan' \
  'layer_scope:' \
  '  domain: affected' \
  '  application: affected' \
  '  boundary: affected' \
  '  infrastructure: affected' \
  '  interface: affected' \
  '  composition: affected'
assert_status 1 "L2 change without domain model evidence" "$l2_list" --risk L2
write_backend_evidence '0001-notification-policy'

write_file 'src/domain/NotificationPolicy.cs' 'namespace Notifications.Domain;'
write_file 'src/domain/NotificationPolicyTests.cs' 'namespace Notifications.Domain.Tests;'
write_file 'specs/features/0001-notification-policy/workflow-routing.md' \
  '- Gate 3-DOMAIN' \
  '- Gate 3-APPLICATION' \
  '- Gate 3-BOUNDARY' \
  '- LAYER-GATE-APPLICATION' \
  '- module-owned DI' \
  '- AddNotificationsDomain' \
  '- AddNotificationsApplication' \
  '- AddNotificationsInfrastructure' \
  '- AddNotificationsInterface' \
  '- AddNotificationsModule'
csharp_l2_list="$(write_list csharp-l2 \
  src/domain/NotificationPolicy.cs \
  src/domain/NotificationPolicyTests.cs \
  specs/features/0001-notification-policy/spec.md \
  specs/features/0001-notification-policy/acceptance.feature \
  specs/features/0001-notification-policy/invariants.md \
  specs/features/0001-notification-policy/plan.md \
  specs/features/0001-notification-policy/tasks.md \
  specs/features/0001-notification-policy/workflow-routing.md \
  specs/features/0001-notification-policy/traceability.yaml \
  specs/features/0001-notification-policy/red-green-refactor.md)"
assert_status 0 "C# composition declares every module layer extension" "$csharp_l2_list" --risk L2
write_file 'specs/features/0001-notification-policy/workflow-routing.md' \
  '- Gate 3-BOUNDARY' \
  '- LAYER-GATE-APPLICATION' \
  '- module-owned DI' \
  '- AddNotificationsDomain' \
  '- AddNotificationsApplication' \
  '- AddNotificationsInfrastructure' \
  '- AddNotificationsModule'
assert_status 1 "C# composition without interface extension is rejected" "$csharp_l2_list" --risk L2
write_backend_evidence '0001-notification-policy'

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
  specs/features/0002-tenant-policy/invariants.md \
  specs/features/0002-tenant-policy/plan.md \
  specs/features/0002-tenant-policy/tasks.md \
  specs/features/0002-tenant-policy/workflow-routing.md \
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

write_file 'go.mod' \
  'module example.test/project' \
  'go 1.24' \
  'require github.com/stretchr/testify v1.10.0'
legacy_go_list="$(write_list legacy-go README.md)"
assert_status 0 "unchanged legacy Go test dependency does not block docs" "$legacy_go_list" --risk L0

write_file 'src/domain/legacy_test.go' \
  'package domain' \
  'import "github.com/stretchr/testify/assert"'
prohibited_go_test_list="$(write_list prohibited-go-test src/domain/legacy_test.go)"
assert_status 0 "changed Go test may import testify assertions" "$prohibited_go_test_list" --risk L1

prohibited_go_mod_list="$(write_list prohibited-go-mod go.mod)"
assert_status 0 "new Go module may add testify assertions" "$prohibited_go_mod_list" --risk L1

if [[ "$failed" -ne 0 ]]; then
  exit 1
fi
