#!/bin/sh
# Installs or upgrades the standalone gjalla CLI binary: sh gjalla-install.sh <plugin root>
#
# Self-hosted installs only: runs when the plugin carries gjalla-install.json, started in the background by
# gjalla.sh at session start. One installer for Linux/WSL and native Windows (Git Bash, which the hooks need there
# anyway). Everything comes from gjalla-install.json, never from the environment: the binary is
# <host>/downloads/gjalla-<cli_version>-<platform>, and it must match the manifest's sha256 for <platform>.
# Installs to ~/.local/bin/gjalla[.exe] and records "<version> <sha256>" in ~/.gjalla/cli-binary-version; an
# existing binary is replaced only when its hash is the recorded one, so a gjalla from pip, pipx, uv or MDM is never
# overwritten. Failures print one line to stderr and exit non-zero.

root=${1:?usage: gjalla-install.sh <plugin root>}
manifest="$root/gjalla-install.json"
[ -f "$manifest" ] || exit 0

fail() { echo "gjalla-install: $*" >&2; exit 1; }
# The manifest's only writer is the server's install.sh, one "key": "value" per line.
field() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$manifest" | head -1; }
sha256() { sha256sum "$1" | awk '{print $1}'; }

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    platform=win-x64; exe=.exe
    # Windows' own curl.exe uses Schannel, i.e. the Windows certificate store (a company CA included); Git Bash's
    # curl uses its own CA bundle.
    curl="$(cygpath -u "${SYSTEMROOT:-C:\\Windows}")/System32/curl.exe" ;;
  Linux)
    [ "$(uname -m)" = x86_64 ] || fail "no binary is built for $(uname -m)"
    platform=linux-x64; exe=""; curl=curl ;;
  *) fail "no binary is built for $(uname -s)" ;;
esac

host=$(field host)
host=${host%/}
version=$(field cli_version)
expected=$(field "$platform" | tr 'A-F' 'a-f')
# https only; plain http just for a loopback host.
printf '%s' "$host" | grep -Eq '^(https://[A-Za-z0-9.-]+(:[0-9]+)?|http://(127\.0\.0\.1|localhost)(:[0-9]+)?)$' \
  || fail "host in gjalla-install.json must be an https origin: '$host'"
printf '%s' "$version" | grep -Eq '^[0-9A-Za-z][0-9A-Za-z.+-]{0,31}$' || fail "bad cli_version: '$version'"
printf '%s' "$expected" | grep -Eq '^[0-9a-f]{64}$' || fail "gjalla-install.json has no sha256 for $platform; not installing"

bindir="$HOME/.local/bin"
target="$bindir/gjalla$exe"
state="$HOME/.gjalla"
marker="$state/cli-binary-version"
if [ -e "$target" ]; then
  # Ours only if it is byte for byte what this installer recorded.
  recorded=$(awk '{print $2}' "$marker" 2>/dev/null)
  if [ -z "$recorded" ] || [ "$(sha256 "$target")" != "$recorded" ]; then
    exit 0
  fi
  [ "$recorded" = "$expected" ] && exit 0            # already the pinned binary
elif command -v gjalla >/dev/null 2>&1; then
  exit 0                                             # the user's own gjalla wins
fi

mkdir -p "$bindir" "$state" || fail "cannot create $bindir"
lock="$state/cli-install.lock"
# A lock older than 10 minutes belongs to an install that was killed.
find "$lock" -maxdepth 0 -mmin +10 -exec rmdir {} \; 2>/dev/null
mkdir "$lock" 2>/dev/null || exit 0                  # another session is installing
tmp=$(mktemp -d "$bindir/.gjalla-download.XXXXXX") || { rmdir "$lock"; fail "cannot create a temp dir"; }
trap 'rm -rf "$tmp"; rmdir "$lock" 2>/dev/null' EXIT

asset="gjalla-$version-$platform$exe"
url="$host/downloads/$asset"
proto=""
case "$host" in https://*) proto="--proto =https --proto-redir =https" ;; esac
# shellcheck disable=SC2086  # $proto is two flags or none
"$curl" -fsSL $proto --max-time 300 -o "$tmp/gjalla$exe" "$url" || fail "download failed: $url"

actual=$(sha256 "$tmp/gjalla$exe")
[ "$actual" = "$expected" ] || fail "checksum mismatch for $asset: expected $expected, got $actual; not installed"
chmod 755 "$tmp/gjalla$exe" || fail "cannot chmod the download"
# It must run before it replaces anything. This also does the binary's one-time unpack off the next hook's clock.
"$tmp/gjalla$exe" --version </dev/null >/dev/null 2>&1 || fail "$asset did not run; not installed"

# A running gjalla.exe can't be overwritten on Windows but can be renamed.
rm -f "$target.old" 2>/dev/null
[ -e "$target" ] && { mv -f "$target" "$target.old" || fail "cannot move the old $target aside"; }
if ! mv -f "$tmp/gjalla$exe" "$target"; then
  [ -e "$target.old" ] && mv -f "$target.old" "$target"
  fail "cannot install to $target"
fi
printf '%s %s\n' "$version" "$expected" > "$marker"
echo "gjalla-install: installed $asset to $target" >&2

if [ "$platform" = win-x64 ]; then
  # gjalla.sh finds ~/.local/bin itself; git hooks and new terminals need it on the user PATH.
  powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass \
    -File "$(cygpath -w "$root/hooks/add-to-user-path.ps1")" "$(cygpath -w "$bindir")" \
    || fail "installed, but could not add $bindir to the user PATH"
fi
