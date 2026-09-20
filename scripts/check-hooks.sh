#!/usr/bin/env bash
# Fails if any harness directory's hooks.json invokes a different set of
# gjalla hook commands than the others. The three collector commands
# (session-start, turn-end, session-end) must be identical everywhere a
# hooks.json ships; only the event-name casing and hook-schema wrapper
# differ per harness.
set -euo pipefail
cd "$(dirname "$0")/.."

expected="gjalla hook session-end
gjalla hook session-start
gjalla hook turn-end"

fail=0
for f in claude/hooks/hooks.json codex/hooks/hooks.json cursor/hooks/hooks.json; do
  [ -f "$f" ] || { echo "MISSING: $f"; fail=1; continue; }
  got=$(grep -oE 'gjalla hook [a-z-]+' "$f" | sort -u)
  if [ "$got" != "$expected" ]; then
    echo "DRIFT in $f:"
    diff <(echo "$expected") <(echo "$got") || true
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: all hooks.json files invoke the same three commands."
fi
exit $fail
