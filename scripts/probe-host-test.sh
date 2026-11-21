#!/usr/bin/env bash
# The cloud-session probe's host (claude/hooks/gjalla.sh -> ~/.gjalla/plugin-status.json):
#   no gjalla-install.json            the SaaS plugin: the CLI's default host, gjalla.io
#   gjalla-install.json with no host  a self-host plugin: no host, both probes skipped
#   gjalla-install.json with a host   that host, if gjalla-install.sh accepts it, else none
#   GJALLA_API_URL + GJALLA_API_KEY   that URL, whatever the install file says
# A sandboxed HOME and a copy of the plugin; `gjalla` and `curl` are stubs, so nothing leaves the machine.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$(pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/gjalla"
printf '#!/bin/sh\necho 401\n' > "$tmp/bin/curl"
chmod 755 "$tmp/bin/gjalla" "$tmp/bin/curl"

fail=0
# probe <case> <expected host> <expected policy_no_key> [ENV=value ...]
probe() {
  local name=$1 want_host=$2 want_probe=$3
  shift 3
  local home="$tmp/home-$name" plugin="$tmp/plugin-$name"
  mkdir -p "$home"
  cp -R "$repo/claude" "$plugin"
  [ -n "${INSTALL_JSON:-}" ] && printf '%s\n' "$INSTALL_JSON" > "$plugin/gjalla-install.json"
  env -i HOME="$home" PATH="$tmp/bin:/usr/bin:/bin" CLAUDE_CODE_REMOTE=true "$@" \
    sh "$plugin/hooks/gjalla.sh" hook session-start </dev/null >/dev/null 2>&1
  local status="$home/.gjalla/plugin-status.json" tries=0
  while [ ! -s "$status" ] && [ "$tries" -lt 50 ]; do sleep 0.1; tries=$((tries + 1)); done  # written in the background
  local got_host got_probe
  got_host=$(sed -n 's/.*"host":"\([^"]*\)".*/\1/p' "$status" 2>/dev/null)
  got_probe=$(sed -n 's/.*"policy_no_key":"\([^"]*\)".*/\1/p' "$status" 2>/dev/null)
  if [ "$got_host" = "$want_host" ] && [ "$got_probe" = "$want_probe" ]; then
    echo "ok   $name: host=$got_host probe=$got_probe"
  else
    echo "FAIL $name: host=$got_host probe=$got_probe, want host=$want_host probe=$want_probe"
    fail=1
  fi
}

INSTALL_JSON='' probe saas-default gjalla.io 401
INSTALL_JSON='{"host":""}' probe selfhost-no-host '' skipped
INSTALL_JSON='{"host":"https://gjalla.corp.example"}' probe selfhost-host gjalla.corp.example 401
# The host is validated by gjalla-install.sh's rule (https, or http only to loopback): an invalid one is never probed.
INSTALL_JSON='{"host":"http://gjalla.corp.example"}' probe selfhost-plain-http '' skipped
INSTALL_JSON='{"host":"http://127.0.0.1:8080"}' probe selfhost-loopback 127.0.0.1:8080 401
# The CLI honours GJALLA_API_URL only together with GJALLA_API_KEY; the probe follows it.
INSTALL_JSON='{"host":"https://gjalla.corp.example"}' probe env-wins gjalla.env.example 401 \
  GJALLA_API_URL=https://gjalla.env.example GJALLA_API_KEY=test-key

exit "$fail"
