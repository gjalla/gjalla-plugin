#!/bin/sh
# Installs or upgrades the standalone gjalla CLI binary: sh gjalla-install.sh <plugin root>
#
# Self-hosted installs only: runs when the plugin carries gjalla-install.json (written per install by the server's
# install.sh), started in the background by gjalla.sh at session start. Linux/WSL and macOS; native Windows uses
# gjalla-install.ps1. The download URL comes only from that file, never from the environment:
#   <host>/downloads/gjalla-<cli_version>-<os>-<arch>, checked against <same URL>.sha256 before it is installed.
# Installs to ~/.local/bin/gjalla and records the version in ~/.gjalla/cli-binary-version. A gjalla this script
# did not install (pip, uv, MDM) is never replaced. Failures print one line to stderr and exit non-zero.

root=${1:?usage: gjalla-install.sh <plugin root>}
manifest="$root/gjalla-install.json"
[ -f "$manifest" ] || exit 0

fail() { echo "gjalla-install: $*" >&2; exit 1; }
field() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$manifest" | head -1; }

host=$(field host)
host=${host%/}
version=$(field cli_version)
# https only; plain http just for a loopback host.
printf '%s' "$host" | grep -Eq '^(https://[A-Za-z0-9.-]+(:[0-9]+)?|http://(127\.0\.0\.1|localhost)(:[0-9]+)?)$' \
  || fail "host in gjalla-install.json must be an https origin: '$host'"
printf '%s' "$version" | grep -Eq '^[0-9A-Za-z][0-9A-Za-z.+-]{0,31}$' || fail "bad cli_version: '$version'"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=macos ;;
  *) fail "unsupported OS: $(uname -s)" ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=x64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) fail "unsupported architecture: $(uname -m)" ;;
esac

bindir="$HOME/.local/bin"
target="$bindir/gjalla"
state="$HOME/.gjalla"
marker="$state/cli-binary-version"
if [ -e "$target" ]; then
  [ -f "$marker" ] || exit 0                        # not ours
  [ "$(cat "$marker" 2>/dev/null)" = "$version" ] && exit 0
elif command -v gjalla >/dev/null 2>&1; then
  exit 0                                            # the user's own gjalla wins
fi

mkdir -p "$bindir" "$state" || fail "cannot create $bindir"
lock="$state/cli-install.lock"
# A lock older than 10 minutes belongs to an install that was killed.
find "$lock" -maxdepth 0 -mmin +10 -exec rmdir {} \; 2>/dev/null
mkdir "$lock" 2>/dev/null || exit 0                 # another session is installing
tmp=$(mktemp -d "$bindir/.gjalla-download.XXXXXX") || { rmdir "$lock"; fail "cannot create a temp dir"; }
trap 'rm -rf "$tmp"; rmdir "$lock" 2>/dev/null' EXIT

asset="gjalla-$version-$os-$arch"
url="$host/downloads/$asset"
fetch() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --max-time 300 -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -T 300 -O "$2" "$1"
  else
    fail "needs curl or wget"
  fi
}
fetch "$url.sha256" "$tmp/sum" || fail "download failed: $url.sha256"
fetch "$url" "$tmp/gjalla" || fail "download failed: $url"

expected=$(awk '{print tolower($1); exit}' "$tmp/sum")
printf '%s' "$expected" | grep -Eq '^[0-9a-f]{64}$' || fail "no SHA-256 in $url.sha256"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$tmp/gjalla" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$tmp/gjalla" | awk '{print $1}')
fi
[ "$actual" = "$expected" ] || fail "checksum mismatch for $asset: expected $expected, got $actual; not installed"

chmod 755 "$tmp/gjalla" || fail "cannot chmod the download"
mv -f "$tmp/gjalla" "$target" || fail "cannot install to $target"
printf '%s\n' "$version" > "$marker"
echo "gjalla-install: installed $asset to $target" >&2
# The binary unpacks itself once per version; doing it here keeps that off the next hook's clock.
"$target" --version </dev/null >/dev/null 2>&1 || fail "installed $target, but it did not run"
