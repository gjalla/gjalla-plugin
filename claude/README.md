# gjalla (Claude Code)

Observability for your coding agent sessions. Install this plugin and
session/commit telemetry starts flowing to gjalla cloud automatically —
no manual instrumentation, no commands to run.

## What it collects

Four hooks, all shelling out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| Session starts (`startup`, `resume`, `clear`, `compact`) | `SessionStart` | `gjalla hook session-start` |
| End of each agent turn | `Stop` (async) | `gjalla hook turn-end` |
| Session ends | `SessionEnd` | `gjalla hook session-end` |
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

## Skills, rules, and memory

Not part of this plugin. Skills come from `npx skills add gjalla/engineering`;
context/memory via the MCP server comes from the `gjalla-onboard` skill.
