#!/bin/sh
# Runs the gjalla CLI for a plugin hook: sh gjalla.sh <gjalla args...>
#
# Local machines: runs `gjalla` if it is installed, and does nothing if it is not (setup is `pip install gjalla`).
# Self-hosted installs (the plugin carries gjalla-install.json): session-start installs the standalone binary from
# the server in the background (gjalla-install.sh, on Linux/WSL and on native Windows under Git Bash).
# Cloud sessions (Claude Code on the web, Cowork cloud; CLAUDE_CODE_REMOTE=true): the container starts without the
# CLI, so `hook session-start` installs it first (uv tool install, about 8 s, once per container). Other hooks never
# install; they no-op until the CLI is there. Pin a version with GJALLA_CLI_SPEC (default: gjalla, the latest).
#
# In a cloud session, session-start also writes ~/.gjalla/plugin-status.json in the background: CLI version, install
# result, destination host, where the key came from, and HTTP status codes for the ingest policy endpoint with and
# without the key. No key or content is written. `cat ~/.gjalla/plugin-status.json` in the session reads it.
# The CLI's session-start (local and cloud) writes the session's entrypoint, app (claude-code or cowork) and which key
# its data uses to the same file first; the cloud probe keeps those fields.
#
# A hook must never block or fail the agent: every failure here exits 0, except gjalla's own exit status.

# Appended, and only when gjalla isn't already on PATH: the user's own gjalla always wins.
command -v gjalla >/dev/null 2>&1 || PATH="$PATH:$HOME/.local/bin"
export PATH
remote="${CLAUDE_CODE_REMOTE:-}"
start=0
[ "$1" = "hook" ] && [ "$2" = "session-start" ] && start=1

# Self-hosted installs: the plugin carries gjalla-install.json (its host is the trust anchor). session-start installs
# or upgrades the standalone CLI binary from that host in the background, so the hook's budget holds; the session
# after the install has the CLI. The plugin root is this script's own location, never an env var.
root=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
if [ "$start" = 1 ] && [ "$remote" != "true" ] && [ -f "$root/gjalla-install.json" ]; then
  pinned=$(sed -n 's/.*"cli_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/gjalla-install.json" | head -1)
  installed=$(awk '{print $1; exit}' "$HOME/.gjalla/cli-binary-version" 2>/dev/null)
  # The usual case, the pinned version already installed, starts no process.
  if [ -z "$pinned" ] || [ "$pinned" != "$installed" ] \
    || { [ ! -e "$HOME/.local/bin/gjalla" ] && [ ! -e "$HOME/.local/bin/gjalla.exe" ]; }; then
    mkdir -p "$HOME/.gjalla" 2>/dev/null
    sh "$root/hooks/gjalla-install.sh" "$root" </dev/null >/dev/null 2>"$HOME/.gjalla/cli-install.log" &
  fi
fi

install_status="present"
install_s=0
if ! command -v gjalla >/dev/null 2>&1; then
  install_status="absent"
  if [ "$remote" = "true" ] && [ "$start" = 1 ]; then
    t0=$(date +%s)
    lock="${TMPDIR:-/tmp}/gjalla-cli-install.lock"
    # A lock older than the hook timeout belongs to an install that was killed.
    find "$lock" -maxdepth 0 -mmin +3 -exec rmdir {} \; 2>/dev/null
    if ! mkdir "$lock" 2>/dev/null; then
      install_status="busy"  # another session-start is installing
    else
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
    if command -v gjalla >/dev/null 2>&1; then
      install_status="installed"
    elif [ "$install_status" != "busy" ]; then
      install_status="install_failed"
    fi
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
    if [ -z "$url" ]; then
      if [ -f "$root/gjalla-install.json" ]; then
        # A per-install plugin (self-host): its host or nothing, never a default.
        url=$(sed -n 's/.*"host"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/gjalla-install.json" | head -1)
      else
        # No install file: the SaaS plugin, so the CLI's own default host (config/settings.py).
        url="https://gjalla.io"
      fi
    fi
    # No host (an install file without one): nothing to probe.
    policy="${url%/}/api/ingest/v1/policy"
    # Without a key: 401 means reachable; 000 means blocked (egress allowlist); 200 means a proxy added credentials.
    no_key="skipped"
    [ -n "$url" ] && no_key=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$policy" </dev/null 2>/dev/null)
    with_key="skipped"
    if [ -n "$url" ] && [ -n "${GJALLA_API_KEY:-}" ]; then
      # The header goes through stdin, so the key never appears in a process argument list.
      with_key=$(printf 'x-api-key: %s\n' "$GJALLA_API_KEY" | curl -s -o /dev/null -w '%{http_code}' --max-time 5 -H @- "$policy" 2>/dev/null)
    fi
    version=$(gjalla --version 2>/dev/null | sed 's/.*version //')
    host=$(printf '%s' "$url" | sed 's#^[a-z]*://##; s#/.*##')
    # Keep the fields the CLI's session-start just wrote (entrypoint, app, session_key): one flat JSON line.
    cli_fields=$(sed -n 's/^{\("entrypoint".*\)}$/,\1/p' "$dir/plugin-status.json" 2>/dev/null | head -1)
    printf '{"at":"%s","remote":true,"env_type":"%s","cli":"%s","install":"%s","install_s":%s,"host":"%s","key_source":"%s","policy_no_key":"%s","policy_with_key":"%s","hook_rc":%s%s}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_CODE_REMOTE_ENVIRONMENT_TYPE:-}" "${version:-none}" "$install_status" \
      "$install_s" "$host" "$key_source" "${no_key:-000}" "$with_key" "$rc" "$cli_fields" > "$dir/plugin-status.json" 2>/dev/null
  ) </dev/null >/dev/null 2>&1 &
fi

exit "$rc"
