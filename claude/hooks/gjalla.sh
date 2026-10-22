#!/bin/sh
# Runs the gjalla CLI for a plugin hook: sh gjalla.sh <gjalla args...>
#
# Local machines: runs `gjalla` if it is installed, and does nothing if it is not (setup is `pip install gjalla`).
# Cloud sessions (Claude Code on the web, Cowork cloud; CLAUDE_CODE_REMOTE=true): the container starts without the
# CLI, so `hook session-start` installs it first (uv tool install, about 8 s, once per container). Other hooks never
# install; they no-op until the CLI is there. Pin a version with GJALLA_CLI_SPEC (default: gjalla, the latest).
#
# In a cloud session, session-start also writes ~/.gjalla/plugin-status.json in the background: CLI version, install
# result, destination host, where the key came from, and HTTP status codes for the ingest policy endpoint with and
# without the key. No key or content is written. `cat ~/.gjalla/plugin-status.json` in the session reads it.
#
# A hook must never block or fail the agent: every failure here exits 0, except gjalla's own exit status.

PATH="$HOME/.local/bin:$PATH"
export PATH
remote="${CLAUDE_CODE_REMOTE:-}"
start=0
[ "$1" = "hook" ] && [ "$2" = "session-start" ] && start=1

install_status="present"
install_s=0
if ! command -v gjalla >/dev/null 2>&1; then
  install_status="absent"
  if [ "$remote" = "true" ] && [ "$start" = 1 ]; then
    t0=$(date +%s)
    lock="${TMPDIR:-/tmp}/gjalla-cli-install.lock"
    if mkdir "$lock" 2>/dev/null; then
      spec="${GJALLA_CLI_SPEC:-gjalla}"
      if command -v uv >/dev/null 2>&1; then
        uv tool install -q "$spec" </dev/null >/dev/null 2>&1 || true
      fi
      if ! command -v gjalla >/dev/null 2>&1; then
        python3 -m pip install -q --user --break-system-packages "$spec" </dev/null >/dev/null 2>&1 || true
      fi
      rmdir "$lock" 2>/dev/null
    fi
    install_s=$(( $(date +%s) - t0 ))
    if command -v gjalla >/dev/null 2>&1; then install_status="installed"; else install_status="install_failed"; fi
  fi
fi

if command -v gjalla >/dev/null 2>&1; then
  gjalla "$@"
  rc=$?
else
  cat >/dev/null 2>&1  # drain the hook payload so the harness never sees a broken pipe
  rc=0
fi

if [ "$remote" = "true" ] && [ "$start" = 1 ]; then
  (
    dir="$HOME/.gjalla"
    mkdir -p "$dir" 2>/dev/null
    url="${GJALLA_API_URL:-}"
    key_source="none"
    if [ -n "${GJALLA_API_KEY:-}" ]; then
      key_source="env"
    elif [ -f "$dir/config.yaml" ] && grep -q '^api_key: *[^ ]' "$dir/config.yaml" 2>/dev/null; then
      key_source="config"
    fi
    if [ -z "$url" ] || [ -z "${GJALLA_API_KEY:-}" ]; then
      url=$(sed -n 's/^api_url: *//p' "$dir/config.yaml" 2>/dev/null | head -1)
    fi
    url="${url:-https://gjalla.io}"
    policy="${url%/}/api/ingest/v1/policy"
    # Without a key: 401 means reachable; 000 means blocked (egress allowlist); 200 means a proxy added credentials.
    no_key=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$policy" </dev/null 2>/dev/null)
    with_key="skipped"
    if [ -n "${GJALLA_API_KEY:-}" ]; then
      # The header goes through stdin, so the key never appears in a process argument list.
      with_key=$(printf 'x-api-key: %s\n' "$GJALLA_API_KEY" | curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H @- "$policy" 2>/dev/null)
    fi
    version=$(gjalla --version 2>/dev/null | sed 's/.*version //')
    host=$(printf '%s' "$url" | sed 's#^[a-z]*://##; s#/.*##')
    printf '{"at":"%s","remote":true,"env_type":"%s","cli":"%s","install":"%s","install_s":%s,"host":"%s","key_source":"%s","policy_no_key":"%s","policy_with_key":"%s","hook_rc":%s}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE:-}" "${version:-none}" "$install_status" \
      "$install_s" "$host" "$key_source" "${no_key:-000}" "$with_key" "$rc" > "$dir/plugin-status.json" 2>/dev/null
  ) </dev/null >/dev/null 2>&1 &
fi

exit "$rc"
