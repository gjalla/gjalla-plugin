#!/usr/bin/env bash
# Fails if any harness directory's hooks.json invokes a different set of
# gjalla commands than expected. The three collector commands
# (session-start, turn-end, session-end) must be identical everywhere a
# hooks.json ships; only the event-name casing and hook-schema wrapper
# differ per harness. Claude Code additionally carries the commit-capture
# row (PostToolUse on Bash, piping the payload into `gjalla attest add
# --from-hook --agent claude-code`), checked byte-for-byte against the
# string below, which is COMMIT_CAPTURE_COMMAND from gjalla-precommit's
# agents/claude_code.py without its hidden `--user` flag. Codex carries the
# same row with `--agent codex-cli` (its PostToolUse matches shell calls as
# `Bash`; CLI B7.4). Cursor carries no commit-capture row: no PostToolUse
# shell command is confirmed for it.
#
# Claude Code runs every gjalla command through hooks/gjalla.sh (it installs
# the CLI in cloud sessions). Its rows are compared with that wrapper read
# as `gjalla`, and a row that calls `gjalla` directly is drift.
set -euo pipefail
cd "$(dirname "$0")/.."

collector="gjalla hook session-end
gjalla hook session-start
gjalla hook turn-end"

commit_capture=$(cat <<'EOF'
sh -c 'p=$(cat); case \"$p\" in *\"git commit\"*|*\"git\"*\"commit\"*) printf %s \"$p\" | gjalla attest add --from-hook --agent claude-code 2>/dev/null || true;; esac'
EOF
)

fail=0
for f in claude/hooks/hooks.json codex/hooks/hooks.json cursor/hooks/hooks.json; do
  [ -f "$f" ] || { echo "MISSING: $f"; fail=1; continue; }

  body=$(cat "$f")
  if [ "$f" = claude/hooks/hooks.json ]; then
    if grep -E '[" |]gjalla (hook|rules|attest) ' "$f"; then
      echo "DRIFT in $f: the rows above call gjalla directly, not through hooks/gjalla.sh"
      fail=1
    fi
    sh -n claude/hooks/gjalla.sh || { echo "DRIFT: claude/hooks/gjalla.sh is missing or not valid sh"; fail=1; }
    # Under dash, `sh <missing file>` exits 2, which blocks the tool call: every
    # PreToolUse row must exit 0 first when the wrapper isn't there.
    # shellcheck disable=SC2016  # the literal text in hooks.json, not an expansion
    guard='[ -f \"${CLAUDE_PLUGIN_ROOT}/hooks/gjalla.sh\" ] || exit 0; '
    pre_rows=$(grep -c 'rules context' "$f" || true)
    guarded=$(grep -cF -- "\"command\": \"$guard" "$f" || true)
    if [ "$pre_rows" -ne 3 ] || [ "$guarded" -ne 3 ]; then
      echo "DRIFT in $f: expected 3 rules-context rows, each starting with: $guard"
      fail=1
    fi
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

  attest_rows=$(grep -c 'gjalla attest' <<<"$body" || true)
  case "$f" in
    claude/hooks/hooks.json) want="$commit_capture" ;;
    codex/hooks/hooks.json)  want="${commit_capture/--agent claude-code/--agent codex-cli}" ;;
    *)                       want="" ;;
  esac
  if [ -n "$want" ]; then
    exact=$(grep -cF -- "$want" <<<"$body" || true)
    if [ "$attest_rows" -ne 1 ] || [ "$exact" -ne 1 ]; then
      echo "DRIFT in $f (commit capture): expected exactly one row equal to:"
      echo "  $want"
      grep 'gjalla attest' <<<"$body" | sed 's/^/  got: /' || echo "  got: (none)"
      fail=1
    fi
  elif [ "$attest_rows" -ne 0 ]; then
    echo "DRIFT in $f (commit capture): no commit-capture row expected here"
    grep 'gjalla attest' "$f" | sed 's/^/  got: /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "OK: all hooks.json files invoke the same three collector commands; Claude Code and Codex carry the commit-capture row."
fi
exit $fail
