#!/usr/bin/env bash
# Fails if any harness directory's hooks.json invokes a different set of
# gjalla commands than expected. The three collector commands
# (session-start, turn-end, session-end) must be identical everywhere a
# hooks.json ships; only the event-name casing and hook-schema wrapper
# differ per harness. Claude Code additionally carries the commit-capture
# row (PostToolUse on Bash, piping the payload into `gjalla attest add
# --from-hook --agent claude-code`), checked byte-for-byte against the
# string below, which is COMMIT_CAPTURE_COMMAND from gjalla-precommit's
# agents/claude_code.py without its hidden `--user` flag. Codex and Cursor
# carry no commit-capture row until their harness is confirmed to expose a
# PostToolUse shell command (PLUGIN-2 section 2, pending CLI B7.4).
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

  got=$(grep -oE 'gjalla hook [a-z-]+' "$f" | sort -u || true)
  if [ "$got" != "$collector" ]; then
    echo "DRIFT in $f (collector commands):"
    diff <(echo "$collector") <(echo "$got") || true
    fail=1
  fi

  attest_rows=$(grep -c 'gjalla attest' "$f" || true)
  case "$f" in
    claude/hooks/hooks.json)
      exact=$(grep -cF -- "$commit_capture" "$f" || true)
      if [ "$attest_rows" -ne 1 ] || [ "$exact" -ne 1 ]; then
        echo "DRIFT in $f (commit capture): expected exactly one row equal to:"
        echo "  $commit_capture"
        grep 'gjalla attest' "$f" | sed 's/^/  got: /' || echo "  got: (none)"
        fail=1
      fi
      ;;
    *)
      if [ "$attest_rows" -ne 0 ]; then
        echo "DRIFT in $f (commit capture): no commit-capture row expected here yet"
        grep 'gjalla attest' "$f" | sed 's/^/  got: /'
        fail=1
      fi
      ;;
  esac
done

if [ "$fail" -eq 0 ]; then
  echo "OK: all hooks.json files invoke the same three collector commands; Claude Code carries the commit-capture row."
fi
exit $fail
