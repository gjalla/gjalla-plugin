#!/usr/bin/env bash
# Exercises the self-host CLI install (claude/hooks/gjalla.sh -> gjalla-install.sh) against a local HTTP server:
# a verified binary that runs is installed; a checksum mismatch, a binary that doesn't run, a missing platform
# entry and a plain-http host are refused; the URL comes only from gjalla-install.json; a gjalla the installer
# didn't put there is never replaced; the install runs in the background so session-start returns at once.
# CI runs it on Linux and on Windows (Git Bash), where the stand-in binaries are real .exe files. On macOS (no
# binary is built for it) `uname` and `sha256sum` are stubbed so the Linux path runs. Needs python3 (the server).
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$(pwd)

py=$(command -v python3 || command -v python)
tmp=$(mktemp -d)
server_pid=""
windows=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) windows=1 ;; esac

cleanup() {
  [ -n "$server_pid" ] && kill "$server_pid" 2>/dev/null || true
  if [ "$windows" = 1 ]; then  # drop the temp bin dir the installer added to the user PATH
    powershell.exe -NoProfile -NonInteractive -Command "
      \$k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', \$true)
      \$p = [string]\$k.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
      \$k.SetValue('Path', ((\$p -split ';') | Where-Object { \$_ -and \$_ -notlike '$(cygpath -w "$tmp")*' }) -join ';', 'ExpandString')
    " >/dev/null 2>&1 || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

mkdir -p "$tmp/stubs" "$tmp/www/downloads"
if [ "$windows" = 1 ]; then
  platform=win-x64; exe=.exe
elif [ "$(uname -s)" = Darwin ]; then
  platform=linux-x64; exe=""
  # shellcheck disable=SC2016  # literal script text
  printf '#!/bin/sh\ncase "$1" in -m) echo x86_64 ;; *) echo Linux ;; esac\n' > "$tmp/stubs/uname"
  # shellcheck disable=SC2016
  printf '#!/bin/sh\nexec shasum -a 256 "$@"\n' > "$tmp/stubs/sha256sum"
  chmod 755 "$tmp/stubs/uname" "$tmp/stubs/sha256sum"
else
  platform=linux-x64; exe=""
fi

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
"$py" "$tmp/server.py" "$tmp/www" "$tmp/requests" "$tmp/delay" "$tmp/port" &
server_pid=$!
for _ in $(seq 50); do [ -s "$tmp/port" ] && break; sleep 0.1; done
good_host="http://127.0.0.1:$(cat "$tmp/port")"
dead_host="http://127.0.0.1:9"

hash_of() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | awk '{print $1}'; }

# publish <version> [<exit code>]: a stand-in binary that prints its version and exits with <exit code> (0).
# Windows: a real console .exe, compiled by PowerShell. Prints the published file's SHA-256.
publish() {
  local out="$tmp/www/downloads/gjalla-$1-$platform$exe" code="${2:-0}"
  if [ "$windows" = 1 ]; then
    powershell.exe -NoProfile -NonInteractive -Command "Add-Type -OutputType ConsoleApplication \
      -OutputAssembly '$(cygpath -w "$out")' -TypeDefinition 'public static class P { public static int Main() { \
      System.Console.WriteLine(\"fake gjalla $1\"); return $code; } }'" >/dev/null
  else
    printf '#!/bin/sh\n# fake gjalla %s\ncat >/dev/null 2>&1\nexit %s\n' "$1" "$code" > "$out"
  fi
  hash_of "$out"
}

pass=0
fail=0
check() {  # check <name> <command...>
  local name="$1"; shift
  if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $name"; fi
}

# fresh <host> <version> [<sha256 for this platform>]: a new HOME and an installed plugin with that manifest.
fresh() {
  rm -rf "${tmp:?}/home" "$tmp/plugin" "$tmp/requests" "$tmp/delay"
  mkdir -p "$tmp/home" "$tmp/plugin"
  cp -R "$repo/claude/." "$tmp/plugin/"
  manifest "$@"
  : > "$tmp/requests"
}
manifest() {
  local entry=""
  [ -n "${3:-}" ] && entry=$(printf ',\n    "%s": "%s"' "$platform" "$3")
  printf '{\n  "host": "%s",\n  "cli_version": "%s",\n  "sha256": {\n    "other-x64": "%s"%s\n  }\n}\n' \
    "$1" "$2" "$(printf 'f%.0s' $(seq 64))" "$entry" > "$tmp/plugin/gjalla-install.json"
}

home_env() {
  local up="$tmp/home"
  [ "$windows" = 1 ] && up=$(cygpath -w "$tmp/home")
  local base="/usr/bin:/bin"
  [ "$windows" = 1 ] && base="$PATH"
  env -u GJALLA_API_URL -u CLAUDE_PLUGIN_ROOT HOME="$tmp/home" USERPROFILE="$up" \
    PATH="$tmp/stubs:${extra_path:-}$(dirname "$(command -v curl)"):$base" "$@"
}

start_hook() {  # runs the plugin's session-start hook; prints its wall time in ms
  local t0 t1
  t0=$("$py" -c 'import time; print(int(time.time()*1000))')
  # Its exit status is the CLI's (a stand-in here), so only the timing and the side effects are checked.
  echo '{}' | home_env "$@" sh "$tmp/plugin/hooks/gjalla.sh" hook session-start --harness claude-code >/dev/null 2>&1 || true
  t1=$("$py" -c 'import time; print(int(time.time()*1000))')
  echo $((t1 - t0))
}

rc=0
install_direct() {  # runs the installer in the foreground; sets $rc, stderr to $tmp/err
  rc=0
  home_env sh "$tmp/plugin/hooks/gjalla-install.sh" "$tmp/plugin" 2>"$tmp/err" || rc=$?
}

target="$tmp/home/.local/bin/gjalla$exe"
marker="$tmp/home/.gjalla/cli-binary-version"
wait_for() { for _ in $(seq 300); do [ -e "$1" ] && return 0; sleep 0.1; done; return 1; }
installer_done() { for _ in $(seq 300); do [ -d "$tmp/home/.gjalla/cli-install.lock" ] || return 0; sleep 0.1; done; return 1; }
settle() { sleep 1; installer_done; }
same_bytes() { cmp -s "$1" "$2"; }
published() { echo "$tmp/www/downloads/gjalla-$1-$platform$exe"; }

# 1. A verified binary that runs is installed, with its version and hash recorded.
sha123=$(publish 1.2.3)
fresh "$good_host" 1.2.3 "$sha123"
install_direct
check "install: exit 0" test "$rc" -eq 0
check "install: the published bytes" same_bytes "$target" "$(published 1.2.3)"
check "install: version and hash recorded" grep -qx "1.2.3 $sha123" "$marker"
check "install: only the binary was fetched (no .sha256)" test "$(cat "$tmp/requests")" = "/downloads/gjalla-1.2.3-$platform$exe"

# 2. A checksum mismatch is refused.
fresh "$good_host" 1.2.3 "$(printf '0%.0s' $(seq 64))"
install_direct
check "mismatch: non-zero exit" test "$rc" -ne 0
check "mismatch: says why" grep -q 'checksum mismatch' "$tmp/err"
check "mismatch: nothing installed" test ! -e "$target"
check "mismatch: no version recorded" test ! -e "$marker"

# 3. A binary that doesn't run is refused, and the one already installed stays.
sha123=$(publish 1.2.3)
fresh "$good_host" 1.2.3 "$sha123"
install_direct
sha140=$(publish 1.4.0 3)
manifest "$good_host" 1.4.0 "$sha140"
install_direct
check "broken binary: non-zero exit" test "$rc" -ne 0
check "broken binary: says why" grep -q 'did not run' "$tmp/err"
check "broken binary: the installed one kept" same_bytes "$target" "$(published 1.2.3)"
check "broken binary: record unchanged" grep -qx "1.2.3 $sha123" "$marker"

# 4. No sha256 for this platform: nothing is fetched or installed, and the log says so.
fresh "$good_host" 1.2.3
install_direct
check "no platform hash: non-zero exit" test "$rc" -ne 0
check "no platform hash: says why" grep -q "no sha256 for $platform" "$tmp/err"
check "no platform hash: nothing fetched" test ! -s "$tmp/requests"
start_hook >/dev/null
settle
check "no platform hash: logged from the hook" grep -q "no sha256 for $platform" "$tmp/home/.gjalla/cli-install.log"

# 5. The URL comes only from gjalla-install.json: env pointing at a good server changes nothing.
fresh "$dead_host" 1.2.3 "$sha123"
start_hook GJALLA_API_URL="$good_host" GJALLA_INSTALL_HOST="$good_host" >/dev/null
settle
check "env host ignored: no request reached the env host" test ! -s "$tmp/requests"
check "env host ignored: nothing installed" test ! -e "$target"
# ...and so is CLAUDE_PLUGIN_ROOT: the manifest is read beside the script, not from an env-named dir.
mkdir -p "$tmp/evil"
printf '{"host": "%s", "cli_version": "1.2.3", "sha256": {"%s": "%s"}}\n' "$good_host" "$platform" "$sha123" \
  > "$tmp/evil/gjalla-install.json"
start_hook CLAUDE_PLUGIN_ROOT="$tmp/evil" >/dev/null
settle
check "env plugin root ignored" test ! -s "$tmp/requests"

# 6. A plain-http host that isn't loopback is refused.
fresh "http://gjalla.example.com" 1.2.3 "$sha123"
install_direct
check "plain-http host: non-zero exit" test "$rc" -ne 0
check "plain-http host: says why" grep -q 'must be an https origin' "$tmp/err"

# 7. It runs in the background: with a slow server, session-start still returns well inside 2 s.
fresh "$good_host" 1.2.3 "$sha123"
echo 3 > "$tmp/delay"
ms=$(start_hook)
check "background: session-start returned in ${ms} ms (< 2000) while the download was in flight" test "$ms" -lt 2000
check "background: not installed yet when the hook returned" test ! -e "$marker"
check "background: the install finished afterwards" wait_for "$marker"
installer_done
rm -f "$tmp/delay"

# 8. Already on the pinned version: session-start starts no installer at all.
echo sentinel > "$tmp/home/.gjalla/cli-install.log"
: > "$tmp/requests"
start_hook >/dev/null
settle
check "pinned version installed: no installer started" grep -qx sentinel "$tmp/home/.gjalla/cli-install.log"

# 9. Upgrade: the binary this installer recorded is replaced when the pin changes.
sha130=$(publish 1.3.0)
manifest "$good_host" 1.3.0 "$sha130"
start_hook >/dev/null
settle
check "upgrade: the new bytes" same_bytes "$target" "$(published 1.3.0)"
check "upgrade: record updated" grep -qx "1.3.0 $sha130" "$marker"

# 10. Only what we installed is replaced: a gjalla put at the same path since (pip, pipx), with our record still
# there, is kept.
cp "$(published 1.2.3)" "$target.users"
mv -f "$target.users" "$target"   # different bytes from the recorded 1.3.0
sha140=$(publish 1.4.0)
manifest "$good_host" 1.4.0 "$sha140"
: > "$tmp/requests"
start_hook >/dev/null
settle
check "replaced since: kept" same_bytes "$target" "$(published 1.2.3)"
check "replaced since: nothing fetched" test ! -s "$tmp/requests"

# ...nor one at that path with no record at all,
fresh "$good_host" 1.3.0 "$sha130"
mkdir -p "$tmp/home/.local/bin"
cp "$(published 1.2.3)" "$target"
start_hook >/dev/null
settle
check "no record: kept" same_bytes "$target" "$(published 1.2.3)"
check "no record: nothing fetched" test ! -s "$tmp/requests"

# ...nor one elsewhere on PATH.
fresh "$good_host" 1.3.0 "$sha130"
mkdir -p "$tmp/own"
cp "$(published 1.2.3)" "$tmp/own/gjalla$exe"
chmod 755 "$tmp/own/gjalla$exe"
extra_path="$tmp/own:" start_hook >/dev/null
settle
check "gjalla on PATH: nothing installed" test ! -e "$target"

# 11. No gjalla-install.json (SaaS install): nothing runs.
fresh "$good_host" 1.3.0 "$sha130"
rm "$tmp/plugin/gjalla-install.json"
start_hook >/dev/null
settle
check "no manifest: nothing fetched" test ! -s "$tmp/requests"

# 12. Windows: the bin dir lands on the user PATH, as REG_EXPAND_SZ.
if [ "$windows" = 1 ]; then
  fresh "$good_host" 1.3.0 "$sha130"
  install_direct
  winbin=$(cygpath -w "$tmp/home/.local/bin")
  reg=$(powershell.exe -NoProfile -NonInteractive -Command "
    \$k = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
    \$k.GetValueKind('Path'); \$k.GetValue('Path', '', 'DoNotExpandEnvironmentNames')" | tr -d '\r')
  check "user PATH: value kind ExpandString" grep -qx ExpandString <<<"$(head -1 <<<"$reg")"
  check "user PATH: has the bin dir" grep -qiF "$winbin" <<<"$reg"
fi

echo "install-cli-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
