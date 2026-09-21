# gjalla (Codex CLI)

Observability for your coding agent sessions. Four hooks, all shelling
out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| Session starts (`startup`, `resume`, `clear`, `compact`) | `SessionStart` | `gjalla hook session-start --harness codex-cli` |
| End of each turn | `Stop` (async) | `gjalla hook turn-end --harness codex-cli` |
| Session ends | `SessionEnd` (3s budget) | `gjalla hook session-end --harness codex-cli` |
| After each `git commit` | `PostToolUse` (matcher `Bash`) | `gjalla attest add --from-hook --agent codex-cli` |

The CLI is the collector — see the [root README](../README.md) for exactly
what is and isn't sent: user and assistant text, tool names and inputs,
tool result sizes and error classes, commits, with the attestation the
agent writes for them (task type, summary), compactions, interrupts,
subagent boundaries.

The commit-capture hook is an `sh -c` wrapper that ignores anything but a
successful `git commit`, records HEAD for the session, and prints a nudge
to write the attestation when there is none. Codex matches shell calls as
`Bash` and sends the command in `tool_input.command`, the same shape as
Claude Code (Codex hooks docs, `learn.chatgpt.com/docs/hooks`). A user who
also ran `gjalla setup hooks` has the same row at user level; the CLI
records a commit once, so both may be installed.

## Setup

```
pip install gjalla
gjalla auth login
```

## Trusting the plugin's hooks

Codex does not auto-trust plugin-bundled hooks. After installing this
plugin, run `/hooks` in the Codex CLI, find the four `gjalla` entries
(they'll show as "untrusted, pending review"), and trust them. Until you
do, Codex silently skips them — including under `codex exec`, which does
not prompt (see [openai/codex#46210](https://github.com/openai/codex/issues/46210)).
If a session isn't showing up in gjalla, check `/hooks` first.

## Harness tagging

Codex sessions are tagged and parsed correctly via `--harness codex-cli`
(gjalla-precommit B7.3).
