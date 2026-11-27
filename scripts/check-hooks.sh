#!/usr/bin/env bash
# Fails if any harness directory's hooks.json invokes a different set of
# gjalla commands than expected. The three collector commands
# (session-start, turn-end, session-end) must be identical everywhere a
# hooks.json ships; only the event-name casing and hook-schema wrapper
# differ per harness. No harness carries a commit-capture row: commits come
# from the CLI's transcript parser, so a row piping into `gjalla attest` is
# drift.
#
# Claude Code alone also carries two rows the CLI's file-based install writes
# for it: Notification -> `gjalla attention record` and PostToolUse on
# ExitPlanMode -> `gjalla ledger mark spec-approved`. Codex and Cursor have
# no equivalent events (no plan-mode tool, no attention notification) and
# the CLI writes neither row for them, so they must not carry these.
#
# Claude Code runs every gjalla command through hooks/gjalla.sh (it installs
# the CLI in cloud sessions). Its rows are compared with that wrapper read
# as `gjalla`, and a row that calls `gjalla` directly is drift.
set -euo pipefail
cd "$(dirname "$0")/.."

collector="gjalla hook session-end
gjalla hook session-start
gjalla hook turn-end"

fail=0
for f in claude/hooks/hooks.json codex/hooks/hooks.json cursor/hooks/hooks.json; do
  [ -f "$f" ] || { echo "MISSING: $f"; fail=1; continue; }

  body=$(cat "$f")
  if [ "$f" = claude/hooks/hooks.json ]; then
    if grep -E '[" |]gjalla (hook|rules|attest|attention|ledger) ' "$f"; then
      echo "DRIFT in $f: the rows above call gjalla directly, not through hooks/gjalla.sh"
      fail=1
    fi
    sh -n claude/hooks/gjalla.sh || { echo "DRIFT: claude/hooks/gjalla.sh is missing or not valid sh"; fail=1; }
    # Under dash, `sh <missing file>` exits 2, which blocks the tool call: every
    # PreToolUse row must exit 0 first when the wrapper isn't there.
    # shellcheck disable=SC2016  # the literal text in hooks.json, not an expansion
    guard='[ -f \"${CLAUDE_PLUGIN_ROOT}/hooks/gjalla.sh\" ] || exit 0; '
    pre_rows=$(grep -c 'rules context' "$f" || true)
    guarded=$(grep -F -- "\"command\": \"$guard" "$f" | grep -c 'rules context' || true)
    if [ "$pre_rows" -ne 3 ] || [ "$guarded" -ne 3 ]; then
      echo "DRIFT in $f: expected 3 rules-context rows, each starting with: $guard"
      fail=1
    fi
    for row in 'attention record --from-hook --agent claude-code' \
              'ledger mark spec-approved --from-hook --agent claude-code'; do
      want_row="\"command\": \"$guard"'GJALLA_FROM_PLUGIN=1 sh \"${CLAUDE_PLUGIN_ROOT}/hooks/gjalla.sh\" '"$row\","
      if [ "$(grep -cF -- "$want_row" "$f" || true)" -ne 1 ]; then
        echo "DRIFT in $f: expected exactly one guarded GJALLA_FROM_PLUGIN=1 row for: gjalla $row"
        fail=1
      fi
    done
    body=$(sed -E -e 's#\[ -f \\"\$\{CLAUDE_PLUGIN_ROOT\}/hooks/gjalla\.sh\\" \] \|\| exit 0; ##g' \
      -e 's#sh \\"\$\{?CLAUDE_PLUGIN_ROOT\}?/hooks/gjalla\.sh\\" #gjalla #g' "$f")
    # Whatever is left naming a script is a wrapper path that doesn't match.
    if grep -E '\.sh' <<<"$body"; then
      echo "DRIFT in $f: the rows above don't run \${CLAUDE_PLUGIN_ROOT}/hooks/gjalla.sh"
      fail=1
    fi
    if [ "$(grep -cE 'gjalla hook [a-z-]+ --harness claude-code"' <<<"$body" || true)" -ne 3 ]; then
      echo "DRIFT in $f: every collector row must pass --harness claude-code"
      fail=1
    fi
  fi

  got=$(grep -oE 'gjalla hook [a-z-]+' <<<"$body" | sort -u || true)
  if [ "$got" != "$collector" ]; then
    echo "DRIFT in $f (collector commands):"
    diff <(echo "$collector") <(echo "$got") || true
    fail=1
  fi

  if [ "$f" != claude/hooks/hooks.json ] && grep -qE 'gjalla (attention|ledger) ' "$f"; then
    echo "DRIFT in $f: attention/ledger rows are Claude Code only"
    fail=1
  fi

  if grep -q 'gjalla attest' <<<"$body"; then
    echo "DRIFT in $f (commit capture): no commit-capture row expected here"
    grep 'gjalla attest' <<<"$body" | sed 's/^/  got: /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: all hooks.json files invoke the same three collector commands; none carries a commit-capture row; Claude Code also carries the attention and spec-approved rows."
fi
exit $fail
