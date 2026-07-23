#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sync-hbk-spec-status-suffixes.sh [--root PATH] [--apply]

Synchronizes every HBK feature-spec folder with the lifecycle status declared
in its spec.md. The status is encoded as the final folder suffix and every
textual path reference under HBK is updated accordingly.
EOF
}

root="${HBK_ROOT:-$HOME/Projects/HBK}"
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) [[ $# -ge 2 ]] || { echo "--root requires a path" >&2; exit 2; }; root="$2"; shift 2 ;;
    --apply) apply=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -d "$root" ]] || { echo "HBK root does not exist: $root" >&2; exit 1; }

declare -a mappings=()
while IFS= read -r -d '' spec; do
  folder="${spec%/spec.md}"
  base="${folder##*/}"
  line="$(rg -i -m1 '^[[:space:]-]*[*`_]*[[:space:]]*status[*`_]*[[:space:]]*:' "$spec" || true)"
  status="$(printf '%s' "$line" | sed -E 's/.*:[[:space:]]*//' | tr -cd '[:alpha:]_-' | tr '[:upper:]' '[:lower:]')"
  case "$status" in
    draft|proposed|approved|active|implemented|verified|superseded|retired) ;;
    *) echo "Unsupported or missing status '$status' in $spec" >&2; exit 1 ;;
  esac

  stem="$base"
  for known in draft proposed approved active implemented verified superseded retired; do
    suffix="-$known"
    [[ "$stem" == *"$suffix" ]] && stem="${stem%$suffix}" && break
  done
  destination="${folder%/*}/${stem}-${status}"
  [[ "$folder" == "$destination" ]] && continue
  [[ -e "$destination" ]] && { echo "Collision: $destination" >&2; exit 1; }
  mappings+=("$folder"$'\t'"$destination")
done < <(find "$root" -type f \( -path '*/specs/features/*/spec.md' -o -path '*/docs/specs/features/*/spec.md' \) -print0 | sort -z)

if [[ "${#mappings[@]}" -gt 0 ]]; then
  for mapping in "${mappings[@]}"; do
    old="${mapping%%$'\t'*}"; new="${mapping#*$'\t'}"
    if [[ "$apply" -eq 1 ]]; then
      mv "$old" "$new"
    else
      printf 'RENAME %s -> %s\n' "$old" "$new"
    fi
  done
fi

if [[ "$apply" -eq 0 ]]; then
  echo "Dry run only. Re-run with --apply to perform the migration."
  exit 0
fi

if [[ "${#mappings[@]}" -gt 0 ]]; then
  for mapping in "${mappings[@]}"; do
    old="${mapping%%$'\t'*}"; new="${mapping#*$'\t'}"
    old_name="${old##*/}"; new_name="${new##*/}"
    while IFS= read -r -d '' file; do
      OLD_NAME="$old_name" NEW_NAME="$new_name" perl -0pi -e 's#\Q$ENV{OLD_NAME}\E#${ENV{NEW_NAME}}#g' "$file"
    done < <(rg -l -0 --hidden --glob '!.git/**' --glob '!node_modules/**' --glob '!dist/**' --glob '!build/**' --glob '!coverage/**' "$old_name" "$root" || true)
  done
fi

echo "Synchronized ${#mappings[@]} HBK spec folder(s) with their declared statuses."
