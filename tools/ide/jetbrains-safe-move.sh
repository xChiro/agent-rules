#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  jetbrains-safe-move.sh --ide <rider|goland|intellij|webstorm> \
    --source <path> --destination <path> [--apply] \
    [--timeout-seconds <seconds>] [--verify-command <command>]

The script never runs mv or git mv. With --apply it opens the source file in
the selected JetBrains IDE and invokes the native Move refactoring (F6). The
destination directory is copied to the clipboard. The user confirms the
destination and Update Usages in the IDE dialog. After the dialog closes, the
script verifies the resulting path and git diff.

Without --apply, the command only performs a safe preflight and prints the
native IDE action that must be confirmed.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

ide=""
source_path=""
destination_path=""
verify_command=""
timeout_seconds=180
apply=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ide)
      [[ $# -ge 2 ]] || fail "--ide requires a value"
      ide="$2"
      shift 2
      ;;
    --source)
      [[ $# -ge 2 ]] || fail "--source requires a value"
      source_path="$2"
      shift 2
      ;;
    --destination)
      [[ $# -ge 2 ]] || fail "--destination requires a value"
      destination_path="$2"
      shift 2
      ;;
    --verify-command)
      [[ $# -ge 2 ]] || fail "--verify-command requires a value"
      verify_command="$2"
      shift 2
      ;;
    --timeout-seconds)
      [[ $# -ge 2 ]] || fail "--timeout-seconds requires a value"
      timeout_seconds="$2"
      shift 2
      ;;
    --apply)
      apply=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ "$ide" == "rider" || "$ide" == "goland" || "$ide" == "intellij" || "$ide" == "webstorm" ]] || fail "--ide must be rider, goland, intellij, or webstorm"
[[ -n "$source_path" ]] || fail "--source is required"
[[ -n "$destination_path" ]] || fail "--destination is required"
[[ "$timeout_seconds" =~ ^[0-9]+$ ]] || fail "--timeout-seconds must be a non-negative integer"
[[ "$(uname -s)" == "Darwin" ]] || fail "native JetBrains UI automation currently requires macOS"
command -v git >/dev/null 2>&1 || fail "git is required"
command -v open >/dev/null 2>&1 || fail "macOS open is required"
command -v osascript >/dev/null 2>&1 || fail "osascript is required"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$repo_root" ]] || fail "run this command inside a Git project"

absolute_path() {
  local path="$1"
  local parent
  local name

  if [[ "$path" == /* ]]; then
    parent="$(dirname "$path")"
    name="$(basename "$path")"
  else
    parent="$repo_root/$(dirname "$path")"
    name="$(basename "$path")"
  fi

  [[ -d "$parent" ]] || fail "parent directory does not exist: $parent"
  printf '%s/%s\n' "$(cd "$parent" && pwd -P)" "$name"
}

source_abs="$(absolute_path "$source_path")"
destination_abs="$(absolute_path "$destination_path")"
destination_dir="$(dirname "$destination_abs")"

[[ -f "$source_abs" ]] || fail "source is not a regular file: $source_abs"
[[ ! -e "$destination_abs" ]] || fail "destination already exists: $destination_abs"
[[ "$(basename "$source_abs")" == "$(basename "$destination_abs")" ]] || fail "native Move changes the directory, not the filename; rename separately with the IDE"
[[ "$source_abs" != "$destination_abs" ]] || fail "source and destination are identical"

case "$source_abs" in
  "$repo_root"/*) ;;
  *) fail "source is outside the Git project: $source_abs" ;;
esac
case "$destination_abs" in
  "$repo_root"/*) ;;
  *) fail "destination is outside the Git project: $destination_abs" ;;
esac

case "$ide" in
  rider)
    app_name="Rider"
    process_name="Rider"
    ;;
  goland)
    app_name="GoLand"
    process_name="GoLand"
    ;;
  intellij)
    app_name="IntelliJ IDEA"
    process_name="IntelliJ IDEA"
    ;;
  webstorm)
    app_name="WebStorm"
    process_name="WebStorm"
    ;;
esac

source_rel="${source_abs#"$repo_root"/}"
destination_rel="${destination_abs#"$repo_root"/}"

echo "IDE: $app_name"
echo "Source: $source_rel"
echo "Destination: $destination_rel"
echo "Operation: native Refactor -> Move with Update Usages"

if [[ "$apply" -ne 1 ]]; then
  echo "DRY RUN: add --apply to open the IDE and invoke its native Move action."
  exit 0
fi

[[ -t 0 ]] || fail "--apply requires an interactive terminal so the native IDE dialog can be confirmed"

open -a "$app_name" "$source_abs"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$destination_dir" | pbcopy
fi

osascript - "$process_name" <<'APPLESCRIPT'
on run argv
  set processName to item 1 of argv
  tell application "System Events"
    if not (exists process processName) then
      error "The IDE process is not available: " & processName
    end if
    tell process processName
      set frontmost to true
      delay 0.8
      -- F6 is the JetBrains native Refactor -> Move action.
      key code 97
    end tell
  end tell
end run
APPLESCRIPT

cat <<EOF

The native Move dialog is open in $app_name.
1. Set the destination directory to:
   $destination_dir
2. Keep Update Usages/references enabled.
3. Review the preview and click Refactor/Move in the IDE.
4. If the terminal is interactive, return here and press Enter. A non-interactive
   Cascade terminal will wait automatically for the expected destination.
EOF

if [[ -t 0 ]]; then
  read -r
else
  deadline=$((SECONDS + timeout_seconds))
  while [[ "$SECONDS" -lt "$deadline" ]]; do
    [[ -f "$destination_abs" && ! -e "$source_abs" ]] && break
    sleep 1
  done
fi

[[ -f "$destination_abs" ]] || fail "native Move did not create the expected destination: $destination_abs"
[[ ! -e "$source_abs" ]] || fail "source still exists; the move was not completed: $source_abs"

git diff --check

if [[ -n "$verify_command" ]]; then
  echo "Running verification: $verify_command"
  bash -lc "$verify_command"
fi

echo "PASS: native IDE move completed and verification passed."
