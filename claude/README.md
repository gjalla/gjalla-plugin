# gjalla (Claude Code)

Observability for your coding agent sessions. Install this plugin and
session/commit telemetry starts flowing to gjalla cloud automatically —
no manual instrumentation, no commands to run.

## What it collects

Four hooks, all shelling out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| Session starts (`startup`, `resume`, `clear`, `compact`) | `SessionStart` | `gjalla hook session-start --harness claude-code` |
| End of each agent turn | `Stop` (async) | `gjalla hook turn-end --harness claude-code` |
| Session ends | `SessionEnd` | `gjalla hook session-end --harness claude-code` |
| After each `git commit` | `PostToolUse` (matcher `Bash`) | `gjalla attest add --from-hook --agent claude-code` |

The CLI is the collector: it parses the transcript, posts trimmed session
deltas (user/assistant text, tool names and inputs, tool result sizes and
error classes, commits, with the attestation the agent writes for them
(task type, summary), compactions, interrupts, subagent boundaries) to
wherever `gjalla auth login` configured. See the [root README](../README.md)
for exactly what is and isn't sent.

The commit-capture hook is an `sh -c` wrapper that ignores anything but a
successful `git commit`, records HEAD for the session, and prints a nudge
to write the attestation when there is none. A user who also ran
`gjalla setup hooks` has the same row at user level; the CLI records a
commit once, so both may be installed.

## Setup

```
pip install gjalla
gjalla auth login
```

That's it — no per-repo setup. The `SessionStart` hook picks up the
connection on the next session.

Every hook runs through `hooks/gjalla.sh`, which runs `gjalla` if it is
installed and does nothing if it is not, so an install without the CLI never
breaks a session.

## Cloud sessions (Claude Code on the web, Cowork)

The container starts without the CLI or a login. The wrapper handles the CLI:
in a cloud session (`CLAUDE_CODE_REMOTE=true`), `SessionStart` installs it
with `uv tool install gjalla` (a few seconds, once per container; pin a
version with `GJALLA_CLI_SPEC=gjalla==X.Y.Z`). The rest is set on the cloud
environment, not in this plugin:

1. Network access: Custom, with your gjalla host allowed (`gjalla.io`, or
   `dev.gjalla.io` for dev). The default Trusted list does not include it.
2. Environment variables: `GJALLA_API_KEY` and `GJALLA_API_URL`. The key
   decides the team and the space the sessions land in.

Turn-end posts carry the session as it goes. Session-end may not run when an
idle container is reclaimed.

To check a cloud session: `cat ~/.gjalla/plugin-status.json`. It records the
CLI version and install result, the destination host, where the key came
from (`env`, `config`, `none`), and the HTTP status of the ingest policy
endpoint without and with the key: `000` is blocked by the network setting,
`401` is reachable without a key, `200` with the key means it works. It never
records the key.

On every machine, local too, the same file records the session's
`entrypoint`, its `app` (`claude-code` or `cowork`) and `session_key`: which
key its data is sent with (`cowork key (env)`, `cowork key (config)` or
`default key`). A Cowork session uses `GJALLA_COWORK_API_KEY` (with
`GJALLA_COWORK_API_URL`), else `cowork_api_key` (and `cowork_api_url`) in
`~/.gjalla/config.yaml`, so it lands in that key's space.

## Skills, rules, and memory

Not part of this plugin. Skills come from `npx skills add gjalla/engineering`;
context/memory via the MCP server comes from the `gjalla-onboard` skill.
