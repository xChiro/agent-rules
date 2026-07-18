#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

bash "$repo_root/tools/validate-agent-catalog.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
fixture_root="$tmp_dir/catalog"
mkdir -p "$fixture_root"
cp -R "$repo_root/." "$fixture_root"

printf '\nThe parent owns Gates 1–4.\n' >> "$fixture_root/languages/web/workflows/web-implement-frontend-change.workflow.md"
if AGENT_CATALOG_ROOT="$fixture_root" bash "$repo_root/tools/validate-agent-catalog.sh" >"$tmp_dir/stdout" 2>"$tmp_dir/stderr"; then
  echo "FAIL: legacy Gates 1-4 wording was accepted" >&2
  exit 1
fi
rg -q 'legacy completion lifecycle' "$tmp_dir/stderr"

echo "PASS: catalog validator rejects legacy lifecycle wording"
