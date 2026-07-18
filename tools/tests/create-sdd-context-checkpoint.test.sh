#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
checkpoint_tool="$repo_root/tools/create-sdd-context-checkpoint.sh"
spec_dir="$repo_root/specs/features/.context-checkpoint-test-$$"
state_file="$(mktemp "${TMPDIR:-/tmp}/context-state.XXXXXX")"
had_specs_dir=0
had_features_dir=0
[[ -d "$repo_root/specs" ]] && had_specs_dir=1
[[ -d "$repo_root/specs/features" ]] && had_features_dir=1
cleanup() {
  rm -rf "$spec_dir"
  if [[ "$had_features_dir" -eq 0 ]]; then
    rmdir "$repo_root/specs/features" 2>/dev/null || true
  fi
  if [[ "$had_specs_dir" -eq 0 ]]; then
    rmdir "$repo_root/specs" 2>/dev/null || true
  fi
  rm -f "$state_file"
}
trap cleanup EXIT

mkdir -p "$spec_dir"
printf '%s\n' '---' 'feature_id: FEAT-9999' 'feature_title: Verify context continuity' 'spec_id: SPEC-9999' 'spec_title: Context checkpoint generation' '---' '# Test spec' > "$spec_dir/spec.md"
for artifact in change-summary.md acceptance.feature plan.md tasks.md workflow-routing.md parallel-tracks.md traceability.yaml verification.md; do
  printf '# %s\n' "$artifact" > "$spec_dir/$artifact"
done
printf '%s\n' '# Current state' '- The first microtask is complete.' '- No secrets.' > "$state_file"

bash "$checkpoint_tool" \
  --spec "$spec_dir" \
  --context-used 59 \
  --current-task T-9999-001 \
  --current-task-title 'Prepare the checkpoint evidence' \
  --next-task T-9999-002 \
  --next-task-title 'Resume the implementation task' \
  --state-file "$state_file" | grep -F 'No checkpoint required'

bash "$checkpoint_tool" \
  --spec "$spec_dir" \
  --context-used 60 \
  --current-task T-9999-001 \
  --current-task-title 'Prepare the checkpoint evidence' \
  --next-task T-9999-002 \
  --next-task-title 'Resume the implementation task' \
  --checkpoint-id CHECKPOINT-TEST-001 \
  --state-file "$state_file"

handoff="$spec_dir/handoffs/context-checkpoints/CHECKPOINT-TEST-001.md"
[[ -f "$handoff" ]]
grep -F 'current_task_id: T-9999-001' "$handoff" >/dev/null
grep -F 'artifact_id: ART-9999-CONTEXT-HANDOFF' "$handoff" >/dev/null
grep -F 'next_task_id: T-9999-002' "$handoff" >/dev/null
grep -F 'current_task_title: Prepare the checkpoint evidence' "$handoff" >/dev/null
grep -F 'next_task_title: Resume the implementation task' "$handoff" >/dev/null
grep -F 'Next task: `T-9999-002`' "$handoff" >/dev/null
grep -F 'CHECKPOINT-TEST-001' "$spec_dir/tasks.md" >/dev/null
grep -F 'CHECKPOINT-TEST-001' "$spec_dir/verification.md" >/dev/null
grep -F 'CHECKPOINT-TEST-001' "$spec_dir/change-summary.md" >/dev/null
[[ -f "$spec_dir/handoffs/latest-context-handoff.md" ]]

echo 'PASS: context checkpoint threshold and resumable handoff'
