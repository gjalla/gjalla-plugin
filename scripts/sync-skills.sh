#!/usr/bin/env bash
# Syncs skills from the canonical source (../engineering/skills, the
# `npx skills add gjalla/engineering` channel) into this plugin's three
# skill directories: claude/skills, cursor/skills, openclaw/skills.
#
# Each target ends up with exactly what the source ships — copied byte for
# byte, with anything not present in the source removed. Run this whenever
# the source skill set changes; there is nothing else to keep in sync.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/../engineering/skills"
TARGETS=(
  "$ROOT_DIR/claude/skills"
  "$ROOT_DIR/cursor/skills"
  "$ROOT_DIR/openclaw/skills"
)

if [ ! -d "$SOURCE_DIR" ]; then
  echo "error: source skills directory not found at $SOURCE_DIR" >&2
  exit 1
fi

for target in "${TARGETS[@]}"; do
  mkdir -p "$target"
  # Remove anything in the target not present in the source.
  for existing in "$target"/*; do
    [ -e "$existing" ] || continue
    name="$(basename "$existing")"
    if [ ! -e "$SOURCE_DIR/$name" ]; then
      rm -rf "$existing"
    fi
  done
  # Copy the source set in, byte for byte.
  for src in "$SOURCE_DIR"/*; do
    [ -e "$src" ] || continue
    cp -R "$src" "$target/"
  done
done

echo "Synced skills into ${TARGETS[*]}:"
ls "$SOURCE_DIR"
