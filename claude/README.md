# gjalla (Claude Code)

Observability for your coding agent sessions. Install this plugin and
session/commit telemetry starts flowing to gjalla cloud automatically —
no manual instrumentation, no commands to run.

## What it collects

The hooks all shell out to the `gjalla` CLI; see the
[hooks table in the root README](../README.md#the-hooks).

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

## Self-hosted installs

A self-hosted server serves this plugin per install, with a
`gjalla-install.json` at the plugin root (written by the server's
`install.sh`). The file is the trust anchor for the host: nothing in the
environment can change where the CLI comes from.

```json
{
  "host": "https://gjalla.example.internal",
  "cli_version": "0.11.6"
}
```

### The CLI without Python

When that file is present, `SessionStart` installs the standalone `gjalla`
binary in the background (the session after the install has it), and
upgrades it when `cli_version` changes:

- Downloads `<host>/downloads/gjalla-<cli_version>-<os>-<arch>` (`linux-x64`
  for WSL, `win-x64.exe` for native Windows) and its `.sha256` beside it, and
  refuses the binary on a checksum mismatch. `host` must be `https://`.
- Installs to `~/.local/bin/gjalla` (`%USERPROFILE%\.local\bin\gjalla.exe` on
  Windows, added to the user `PATH`), recording the version in
  `~/.gjalla/cli-binary-version`. A `gjalla` it didn't install (pip, uv, MDM)
  is never replaced.
- Linux/WSL: `hooks/gjalla-install.sh` (curl or wget). Native Windows:
  `hooks/gjalla-install.ps1` (Windows PowerShell, Windows certificate store),
  started with `-ExecutionPolicy Bypass`; a Group Policy that forces
  `AllSigned` blocks it, and then the CLI is installed by MDM instead.
- The last result is in `~/.gjalla/cli-install.log`.

### Remote MCP instead of a local `gjalla mcp serve`

Claude Code plugins can declare a remote HTTP MCP server, and `${VAR}`
expands from the environment in its `url` and `headers`, so with the
managed-settings `env` block (`GJALLA_API_KEY`) the per-install
`plugin.json` points MCP at the server and only the hooks need the binary:

```json
"mcpServers": {
  "gjalla": {
    "type": "http",
    "url": "https://gjalla.example.internal/mcp/stream",
    "headers": {
      "x-api-key": "${GJALLA_API_KEY}",
      "X-Gjalla-Person": "${CLAUDE_CODE_USER_EMAIL:-}"
    }
  }
}
```

The server's `install.sh` writes this entry in place of the default stdio
one; the default in this repo stays `gjalla mcp serve`. `X-Gjalla-Person`
comes only from `CLAUDE_CODE_USER_EMAIL` here (the CLI's `.claude.json`
fallback doesn't apply to a remote server). The Claude Code docs
don't say in so many words that managed `env` reaches this expansion: the
canary confirms the MCP server connects before a wider rollout.

### Native Windows needs Git for Windows

Claude Code runs `command` hooks through Git Bash on Windows (PowerShell only
when Git Bash isn't installed). Every row here, and the commit-capture row's
`sh -c` wrapper, runs `sh`, so native Windows needs Git for Windows, which
ships both. Without it the hooks don't run (they never block a session).

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
