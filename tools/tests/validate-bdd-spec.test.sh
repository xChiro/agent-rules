#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
validator="$repo_root/tools/validate-bdd-spec.sh"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/validate-bdd-spec.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

valid="$tmp_dir/valid.feature"
invalid="$tmp_dir/invalid.feature"

printf '%s\n' \
  'Feature: Reserve a resource' \
  '' \
  '@US-0001-001 @REQ-0001-001 @SCN-0001-001' \
  'Scenario: A qualified actor completes a reservation' \
  '  Given the resource is available' \
  '  When the actor confirms the reservation' \
  '  Then the reservation is recorded' \
  > "$valid"

printf '%s\n' \
  'Feature: Reserve a resource' \
  '' \
  'Scenario: A qualified actor clicks a button' \
  '  Given the browser shows the resource' \
  '  When the actor clicks the button' \
  '  Then the status code is successful' \
  > "$invalid"

bash "$validator" "$valid"
if bash "$validator" "$invalid"; then
  echo 'FAIL: invalid BDD language was accepted' >&2
  exit 1
fi

echo 'PASS: BDD language boundary'
