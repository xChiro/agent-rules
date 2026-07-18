#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  migrate-hbk-completed-specs.sh [--root PATH] [--apply]

Without --apply the command only reports the folders and files that would
change. The migration removes the legacy -completed suffix, updates path and
workflow references, and normalizes top-level lifecycle statuses.
EOF
}

root="${HBK_ROOT:-$HOME/Projects/HBK}"
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 ]] || { echo "--root requires a path" >&2; exit 2; }
      root="$2"
      shift 2
      ;;
    --apply)
      apply=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -d "$root" ]] || { echo "HBK root does not exist: $root" >&2; exit 1; }

map_file="$(mktemp)"
files_file="$(mktemp)"
trap 'rm -f "$map_file" "$files_file"' EXIT

while IFS= read -r -d '' source; do
  destination="${source%-completed}"
  if [[ -e "$destination" ]]; then
    echo "Collision: $destination already exists for $source" >&2
    exit 1
  fi
  printf '%s\0%s\0' "$source" "$destination" >> "$map_file"
done < <(find "$root" -type d -name '*-completed' -print0 | sort -z)

if [[ ! -s "$map_file" ]]; then
  echo "No -completed spec folders found under $root."
  exit 0
fi

while IFS= read -r -d '' source && IFS= read -r -d '' destination; do
  if [[ "$apply" -eq 1 ]]; then
    mv "$source" "$destination"
  else
    printf 'RENAME %s -> %s\n' "$source" "$destination"
  fi
done < "$map_file"

if [[ "$apply" -ne 1 ]]; then
  echo "Dry run only. Re-run with --apply to perform the migration."
  exit 0
fi

rg -l -0 --hidden \
  --glob '!.git/**' \
  --glob '!node_modules/**' \
  --glob '!dist/**' \
  --glob '!build/**' \
  --glob '!coverage/**' \
  --glob '!*.map' \
  '(-completed|WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW|common-sdd-complete-spec)' \
  "$root" > "$files_file" || true

while IFS= read -r -d '' file; do
  perl -0pi -e '
    s/-completed//g;
    s/WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW/WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW/g;
    s/common-sdd-complete-spec/common-sdd-verify-spec/g;
  ' "$file"
done < "$files_file"

while IFS= read -r -d '' source && IFS= read -r -d '' destination; do
  for name in spec.md change-summary.md verification.md; do
    file="$destination/$name"
    [[ -f "$file" ]] || continue
    perl -0pi -e '
      s{(\*\*Status:\*\*\s*)completed}{$1 . "verified"}gie;
      s{(\*\*status\*\*:\s*)completed}{$1 . "verified"}gie;
      s{(^status:\s*)completed\s*$}{$1 . "verified"}gim;
      s{(\*\*Status:\*\*\s*)active-completed}{$1 . "implemented"}gie;
      s{(\*\*status\*\*:\s*)active-completed}{$1 . "implemented"}gie;
      s{(^status:\s*)active-completed\s*$}{$1 . "implemented"}gim;
      s{(\*\*Status:\*\*\s*)active}{$1 . "implemented"}gie;
      s{(\*\*status\*\*:\s*)active}{$1 . "implemented"}gie;
      s{(^status:\s*)active\s*$}{$1 . "implemented"}gim;
    ' "$file"
  done
done < "$map_file"

echo "Migration applied under $root."
