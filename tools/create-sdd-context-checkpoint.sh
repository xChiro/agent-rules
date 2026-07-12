#!/usr/bin/env bash
set -euo pipefail

# Create an append-only continuation handoff when an AI context reaches the
# configured threshold. The agent supplies the factual state; this tool only
# validates the spec folder and records the checkpoint metadata.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

spec_dir=""
context_used="${CONTEXT_USED_PERCENT:-}"
current_task=""
next_task=""
state_file=""
checkpoint_id=""

usage() {
  cat <<'EOF'
Usage: tools/create-sdd-context-checkpoint.sh [options]

Options:
  --spec <directory>       Active specs/features/<number>-<slug> directory.
  --context-used <0-100>   Observed or conservatively estimated context use.
  --current-task <T-ID>    Current microtask.
  --next-task <T-ID|BLOCKED>
                           Exact next task or blocker state.
  --state-file <file>      Concise factual state to include in the handoff.
  --checkpoint-id <id>     Optional stable CHECKPOINT-* ID.
  --help                   Show this help.

Environment: CONTEXT_USED_PERCENT may provide --context-used.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec)
      spec_dir="${2:?missing value for --spec}"
      shift 2
      ;;
    --context-used)
      context_used="${2:?missing value for --context-used}"
      shift 2
      ;;
    --current-task)
      current_task="${2:?missing value for --current-task}"
      shift 2
      ;;
    --next-task)
      next_task="${2:?missing value for --next-task}"
      shift 2
      ;;
    --state-file)
      state_file="${2:?missing value for --state-file}"
      shift 2
      ;;
    --checkpoint-id)
      checkpoint_id="${2:?missing value for --checkpoint-id}"
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

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -n "$spec_dir" ]] || fail "--spec is required"
[[ -n "$context_used" ]] || fail "--context-used or CONTEXT_USED_PERCENT is required"
[[ -n "$current_task" ]] || fail "--current-task is required"
[[ -n "$next_task" ]] || fail "--next-task is required"
[[ -n "$state_file" ]] || fail "--state-file is required"

if ! [[ "$context_used" =~ ^[0-9]+$ ]] || (( context_used < 0 || context_used > 100 )); then
  fail "context use must be an integer from 0 to 100"
fi

if (( context_used < 60 )); then
  echo "No checkpoint required: context use is ${context_used}% (threshold: 60%)."
  exit 0
fi

if [[ "$spec_dir" != /* ]]; then
  spec_dir="$repo_root/$spec_dir"
fi
if [[ "$state_file" != /* ]]; then
  state_file="$repo_root/$state_file"
fi

case "$spec_dir" in
  "$repo_root"/specs/features/*) ;;
  *) fail "spec must be inside specs/features" ;;
esac

[[ -d "$spec_dir" ]] || fail "active spec directory not found: $spec_dir"
[[ -s "$state_file" ]] || fail "state file is missing or empty: $state_file"

for required in spec.md change-summary.md acceptance.feature plan.md tasks.md workflow-routing.md parallel-tracks.md traceability.yaml verification.md; do
  [[ -f "$spec_dir/$required" ]] || fail "required spec artifact is missing: $required"
done

case "$current_task" in
  T-[A-Za-z0-9._-]*) ;;
  *) fail "current task must be a T-* ID" ;;
esac

case "$next_task" in
  T-[A-Za-z0-9._-]*|BLOCKED) ;;
  *) fail "next task must be a T-* ID or BLOCKED" ;;
esac

if command -v rg >/dev/null 2>&1; then
  secret_found=0
  rg -n -i '(aws_secret_access_key|private_key|client_secret|password[[:space:]]*:|bearer[[:space:]]+[A-Za-z0-9._~-]{20,})' "$state_file" >/dev/null && secret_found=1 || true
else
  secret_found=0
  grep -Eiq '(aws_secret_access_key|private_key|client_secret|password[[:space:]]*:|bearer[[:space:]]+[A-Za-z0-9._~-]{20,})' "$state_file" && secret_found=1 || true
fi
[[ "$secret_found" -eq 0 ]] || fail "state file appears to contain a secret; redact it before checkpointing"

frontmatter_value() {
  local key="$1"
  sed -n "s/^${key}:[[:space:]]*//p" "$spec_dir/spec.md" | head -1
}

feature_id="$(frontmatter_value feature_id)"
spec_id="$(frontmatter_value spec_id)"
feature_id="${feature_id:-FEAT-UNKNOWN}"
spec_id="${spec_id:-SPEC-UNKNOWN}"

timestamp="$(date -u +%Y%m%d-%H%M%S)"
checkpoint_id="${checkpoint_id:-CHECKPOINT-$timestamp}"
case "$checkpoint_id" in
  CHECKPOINT-[A-Za-z0-9._-]*) ;;
  *) fail "checkpoint ID must start with CHECKPOINT-" ;;
esac

handoff_id="HANDOFF-${feature_id#FEAT-}-CONTEXT-$timestamp"
artifact_id="ART-${feature_id#FEAT-}-CONTEXT-HANDOFF"
handoff_dir="$spec_dir/handoffs/context-checkpoints"
handoff_path="$handoff_dir/$checkpoint_id.md"
latest_path="$spec_dir/handoffs/latest-context-handoff.md"
mkdir -p "$handoff_dir"
[[ ! -e "$handoff_path" ]] || fail "checkpoint already exists: $handoff_path"

template="$repo_root/common/templates/context-handoff.md"
[[ -f "$template" ]] || fail "context handoff template not found: $template"

tmp_handoff="$(mktemp "$handoff_dir/.context-handoff.XXXXXX")"
tmp_latest="$(mktemp "$spec_dir/.latest-context-handoff.XXXXXX")"
cleanup() {
  rm -f "$tmp_handoff" "$tmp_latest"
}
trap cleanup EXIT

{
  awk \
    -v handoff_id="$handoff_id" \
    -v feature_id="$feature_id" \
    -v spec_id="$spec_id" \
    -v artifact_id="$artifact_id" \
    -v checkpoint_id="$checkpoint_id" \
    -v context_used="$context_used" \
    -v current_task="$current_task" \
    -v next_task="$next_task" '
      {
        gsub(/HANDOFF-<FEAT>-CONTEXT-<NNN>/, handoff_id)
        gsub(/FEAT-<NNNN>/, feature_id)
        gsub(/SPEC-<NNNN>/, spec_id)
        gsub(/ART-<FEAT>-CONTEXT-HANDOFF/, artifact_id)
        gsub(/CHECKPOINT-<YYYYMMDD>-<HHMMSS>/, checkpoint_id)
        gsub(/<PERCENT>/, context_used)
        gsub(/CURRENT-TASK-ID/, current_task)
        gsub(/NEXT-TASK-ID/, next_task)
        print
      }
    ' "$template"
  printf '\n## Agent State\n\n'
  cat "$state_file"
  printf '\n\n## Generated Checkpoint Metadata\n\n'
  printf -- '- Generated at (UTC): `%s`\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf -- '- Current task: `%s`\n' "$current_task"
  printf -- '- Next task: `%s`\n' "$next_task"
  printf -- '- Context use observed/estimated: `%s%%`\n' "$context_used"
} > "$tmp_handoff"
mv "$tmp_handoff" "$handoff_path"

spec_relative="${spec_dir#"$repo_root/"}"
handoff_relative="${handoff_path#"$repo_root/"}"
{
  printf '# Latest Context Handoff\n\n'
  printf -- '- Checkpoint: `%s`\n' "$checkpoint_id"
  printf -- '- Handoff: [%s](./context-checkpoints/%s.md)\n' "$handoff_relative" "$checkpoint_id"
  printf -- '- Current task: `%s`\n' "$current_task"
  printf -- '- Next task: `%s`\n' "$next_task"
  printf -- '- Context use: `%s%%`\n' "$context_used"
  printf -- '- Read this file first, then the active spec at `%s`.\n' "$spec_relative"
} > "$tmp_latest"
mv "$tmp_latest" "$latest_path"

append_record() {
  local target="$1"
  if command -v rg >/dev/null 2>&1; then
    rg -F -q "$checkpoint_id" "$target" && return 0 || true
  else
    grep -F -q "$checkpoint_id" "$target" && return 0 || true
  fi
  {
    printf '\n\n## Context Checkpoint `%s`\n\n' "$checkpoint_id"
    printf -- '- Context use observed/estimated: `%s%%`\n' "$context_used"
    printf -- '- Current task: `%s`\n' "$current_task"
    printf -- '- Next task: `%s`\n' "$next_task"
    printf -- '- Handoff: `%s`\n' "$handoff_relative"
  } >> "$target"
}

append_record "$spec_dir/verification.md"
append_record "$spec_dir/change-summary.md"
append_record "$spec_dir/tasks.md"

if ! git -C "$repo_root" diff --check -- "$spec_relative"; then
  fail "git diff --check failed after writing the checkpoint"
fi

trap - EXIT
cleanup
echo "Context checkpoint created: $handoff_relative"
echo "Spec continuity records updated: verification.md and change-summary.md"
echo "Pause and request a new context before starting another task."
