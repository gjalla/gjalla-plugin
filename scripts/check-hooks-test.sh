#!/usr/bin/env bash
# Exercises scripts/check-hooks.sh: the shipped tree passes, and each kind
# of drift fails. Runs against a throwaway copy of the tree.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fresh() {
  rm -rf "$tmp/tree"
  mkdir -p "$tmp/tree/scripts"
  cp -R claude codex cursor "$tmp/tree/"
  cp scripts/check-hooks.sh "$tmp/tree/scripts/"
}

pass=0
fail=0
expect() {
  local want="$1" name="$2"
  if bash "$tmp/tree/scripts/check-hooks.sh" >/dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $name (expected $want, got $got)"
  fi
}

fresh
expect pass "shipped tree passes"

fresh
perl -ni -e 'print unless /gjalla attest add/' "$tmp/tree/claude/hooks/hooks.json"
expect fail "claude missing commit-capture row"

fresh
perl -pi -e 's/--agent claude-code/--agent codex-cli/' "$tmp/tree/claude/hooks/hooks.json"
expect fail "claude commit-capture row with wrong --agent"

fresh
perl -pi -e 's/--from-hook --agent claude-code/--from-hook --agent claude-code --user/' "$tmp/tree/claude/hooks/hooks.json"
expect fail "claude commit-capture row with --user"

fresh
perl -pi -e 's/case \\"\$p\\" in \*\\"git commit\\"\*\|/case \\"\$p\\" in /' "$tmp/tree/claude/hooks/hooks.json"
expect fail "claude commit-capture wrapper edited"

fresh
perl -pi -e 's/"command": "gjalla hook session-end --harness codex-cli"/"command": "gjalla attest add --from-hook --agent codex-cli"/' "$tmp/tree/codex/hooks/hooks.json"
expect fail "codex carrying a commit-capture row before section 2"

fresh
perl -pi -e 's/gjalla hook turn-end --harness cursor/gjalla hook turn-ended --harness cursor/' "$tmp/tree/cursor/hooks/hooks.json"
expect fail "cursor collector command renamed"

fresh
rm "$tmp/tree/codex/hooks/hooks.json"
expect fail "codex hooks.json missing"

echo "check-hooks-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
