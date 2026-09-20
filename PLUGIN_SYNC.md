# Plugin Sync

The plugin is collection only. Every harness directory (`claude/`, `codex/`,
`cursor/`) ships exactly a plugin manifest, a `hooks/hooks.json`, and a
README — nothing else. `openclaw/` is a README-only stub (no hook surface
to attach to; see `openclaw/README.md`).

**The one rule:** the three hook commands — `gjalla hook session-start`,
`gjalla hook turn-end`, `gjalla hook session-end` — are identical across
every `hooks/hooks.json`. Event names and the hook-schema wrapper differ
per harness (Claude Code/Codex use PascalCase `SessionStart`/`Stop`/
`SessionEnd` inside `{"hooks": {...}}`; Cursor uses camelCase
`sessionStart`/`stop`/`sessionEnd` inside `{"version": 1, "hooks": {...}}`)
— that's expected. The commands invoked are not.

`scripts/check-hooks.sh` enforces this: it greps every `hooks/hooks.json`
for `gjalla hook <name>` and fails if any directory's set differs from the
other two.
