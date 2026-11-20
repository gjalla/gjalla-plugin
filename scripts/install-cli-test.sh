#!/usr/bin/env bash
# Exercises the self-host CLI install (claude/hooks/gjalla.sh -> gjalla-install.sh, or gjalla-install.ps1 under
# Git Bash on Windows) against a local HTTP server: a verified download installs, a checksum mismatch is refused,
# the URL comes only from gjalla-install.json, a gjalla the installer didn't put there is left alone, and the
# install runs in the background so session-start returns at once. Needs python3 (the test server) and curl.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$(pwd)

py=$(command -v python3 || command -v python)
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) windows=1; asset_suffix="win-x64.exe"; exe=".exe" ;;
  *)
    windows=0; exe=""
    case "$(uname -s)" in Linux) os=linux ;; Darwin) os=macos ;; esac
    case "$(uname -m)" in x86_64|amd64) arch=x64 ;; *) arch=arm64 ;; esac
    asset_suffix="$os-$arch" ;;
esac

tmp=$(mktemp -d)
server_pid=""
cleanup() {
  [ -n "$server_pid" ] && kill "$server_pid" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

# Serves $tmp/www; logs each request path to $tmp/requests; sleeps $tmp/delay seconds per request when present.
cat > "$tmp/server.py" <<'EOF'
import functools, http.server, os, sys, time
root, log, delay, portfile = sys.argv[1:5]
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        with open(log, "a") as f:
            f.write(self.path + "\n")
        if os.path.exists(delay):
            time.sleep(float(open(delay).read()))
        super().do_GET()
    def log_message(self, *a):
        pass
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(H, directory=root))
open(portfile, "w").write(str(srv.server_address[1]))
srv.serve_forever()
EOF
mkdir -p "$tmp/www/downloads"
"$py" "$tmp/server.py" "$tmp/www" "$tmp/requests" "$tmp/delay" "$tmp/port" &
server_pid=$!
for _ in $(seq 50); do [ -s "$tmp/port" ] && break; sleep 0.1; done
port=$(cat "$tmp/port")
good_host="http://127.0.0.1:$port"
dead_host="http://127.0.0.1:9"

sha() { if command -v sha256sum >/dev/null; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }

publish() {  # publish <version> [<checksum override>]
  local name="gjalla-$1-$asset_suffix"
  # A runnable stand-in (POSIX); on Windows the bytes are only checked, never run as an .exe.
  printf '#!/bin/sh\n# fake gjalla %s\ncat >/dev/null 2>&1\nexit 0\n' "$1" > "$tmp/www/downloads/$name"
  printf '%s  %s\n' "${2:-$(sha "$tmp/www/downloads/$name")}" "$name" > "$tmp/www/downloads/$name.sha256"
}

pass=0
fail=0
check() {  # check <name> <condition...>
  local name="$1"; shift
  if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $name"; fi
}

fresh() {  # fresh <host> <version>: a new HOME and an installed plugin whose gjalla-install.json names <host>
  rm -rf "${tmp:?}/home" "$tmp/plugin" "$tmp/requests" "$tmp/delay"
  mkdir -p "$tmp/home" "$tmp/plugin"
  cp -R "$repo/claude/." "$tmp/plugin/"
  printf '{\n  "host": "%s",\n  "cli_version": "%s"\n}\n' "$1" "$2" > "$tmp/plugin/gjalla-install.json"
  : > "$tmp/requests"
}

home_env() {
  local h="$tmp/home"
  local up="$h"
  [ "$windows" = 1 ] && up=$(cygpath -w "$h")
  # PATH without any real gjalla; plus whatever the case adds in front.
  env -u GJALLA_API_URL -u CLAUDE_PLUGIN_ROOT HOME="$h" USERPROFILE="$up" PATH="${extra_path:-}$(dirname "$(command -v curl)"):/usr/bin:/bin$( [ "$windows" = 1 ] && printf ':%s' "$PATH")" "$@"
}

start_hook() {  # runs the plugin's session-start hook; prints its wall time in ms
  local t0 t1
  t0=$("$py" -c 'import time; print(int(time.time()*1000))')
  # Its exit status is the CLI's (a stand-in here), so only the timing and the side effects are checked.
  echo '{}' | home_env "$@" sh "$tmp/plugin/hooks/gjalla.sh" hook session-start --harness claude-code || true
  t1=$("$py" -c 'import time; print(int(time.time()*1000))')
  echo $((t1 - t0))
}

target="$tmp/home/.local/bin/gjalla$exe"
marker="$tmp/home/.gjalla/cli-binary-version"

wait_for() {  # wait_for <file>: up to 30 s
  for _ in $(seq 300); do [ -e "$1" ] && return 0; sleep 0.1; done
  return 1
}
installer_done() {  # no lock dir left: the background installer finished
  for _ in $(seq 300); do [ -d "$tmp/home/.gjalla/cli-install.lock" ] || return 0; sleep 0.1; done
  return 1
}
settle() { sleep 1; installer_done; }

# 1. A verified download installs, and records its version.
publish 1.2.3
fresh "$good_host" 1.2.3
start_hook >/dev/null
check "verified binary installed" wait_for "$marker"
check "installed bytes are the published ones" grep -q 'fake gjalla 1.2.3' "$target"
check "version recorded" grep -qx '1.2.3' "$marker"

# 2. A checksum mismatch is refused: nothing installed, the log says why.
publish 2.0.0 "$(printf '0%.0s' $(seq 64))"
fresh "$good_host" 2.0.0
start_hook >/dev/null
settle
check "mismatch: binary fetched" grep -q "/downloads/gjalla-2.0.0-$asset_suffix\$" "$tmp/requests"
check "mismatch: nothing installed" test ! -e "$target"
check "mismatch: no version recorded" test ! -e "$marker"
check "mismatch: logged" grep -q 'checksum mismatch' "$tmp/home/.gjalla/cli-install.log"

# 3. The URL comes only from gjalla-install.json: env pointing at a good server changes nothing.
publish 1.2.3
fresh "$dead_host" 1.2.3
start_hook GJALLA_API_URL="$good_host" GJALLA_INSTALL_HOST="$good_host" >/dev/null
settle
check "env host ignored: no request reached the env host" test ! -s "$tmp/requests"
check "env host ignored: nothing installed" test ! -e "$target"

# ...and so is CLAUDE_PLUGIN_ROOT: the manifest is read beside the script, not from an env-named dir.
rm -rf "$tmp/evil" && mkdir -p "$tmp/evil"
printf '{"host": "%s", "cli_version": "1.2.3"}\n' "$good_host" > "$tmp/evil/gjalla-install.json"
start_hook CLAUDE_PLUGIN_ROOT="$tmp/evil" >/dev/null
settle
check "env plugin root ignored" test ! -s "$tmp/requests"

# 4. A non-https host for a non-loopback name is refused.
fresh "http://gjalla.example.com" 1.2.3
start_hook >/dev/null
settle
check "plain-http host refused" grep -q 'must be an https origin' "$tmp/home/.gjalla/cli-install.log"

# 5. It runs in the background: with a slow server, session-start still returns well inside 2 s.
publish 1.2.3
fresh "$good_host" 1.2.3
echo 3 > "$tmp/delay"
ms=$(start_hook)
check "session-start returned in ${ms} ms (< 2000) while the download was in flight" test "$ms" -lt 2000
check "not installed yet when the hook returned" test ! -e "$marker"
check "the background install finished afterwards" wait_for "$marker"
installer_done

# 6. Upgrade: a binary this installer put there is replaced when the pinned version changes.
publish 1.3.0
sed -i.bak 's/1\.2\.3/1.3.0/' "$tmp/plugin/gjalla-install.json"
rm -f "$tmp/delay"
start_hook >/dev/null
settle
check "upgraded to the pinned version" grep -qx '1.3.0' "$marker"
check "upgraded bytes" grep -q 'fake gjalla 1.3.0' "$target"

# 7. A gjalla the installer didn't put there is never replaced (no version marker).
fresh "$good_host" 1.3.0
mkdir -p "$tmp/home/.local/bin"
printf 'users own gjalla\n' > "$target"
start_hook >/dev/null
settle
check "foreign gjalla at the install path kept" grep -q 'users own gjalla' "$target"
check "foreign gjalla: nothing fetched" test ! -s "$tmp/requests"

# ...and nor is one elsewhere on PATH.
fresh "$good_host" 1.3.0
mkdir -p "$tmp/own"
printf '#!/bin/sh\nexit 0\n' > "$tmp/own/gjalla$exe"
chmod 755 "$tmp/own/gjalla$exe"
extra_path="$tmp/own:" start_hook >/dev/null
settle
check "gjalla on PATH: nothing installed" test ! -e "$target"

# 8. No gjalla-install.json (SaaS install): nothing runs.
fresh "$good_host" 1.3.0
rm "$tmp/plugin/gjalla-install.json"
start_hook >/dev/null
settle
check "no manifest: nothing fetched" test ! -s "$tmp/requests"

echo "install-cli-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
