# gjalla (Claude Code)

Observability for your coding agent sessions. Install this plugin and
session/commit telemetry starts flowing to gjalla cloud automatically —
no manual instrumentation, no commands to run.

## What it collects

Three hooks, all shelling out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| Session starts (`startup`, `resume`, `clear`, `compact`) | `SessionStart` | `gjalla hook session-start` |
| End of each agent turn | `Stop` (async) | `gjalla hook turn-end` |
| Session ends | `SessionEnd` | `gjalla hook session-end` |

The CLI is the collector: it parses the transcript, posts trimmed session
deltas (user/assistant text, tool names and inputs, tool result sizes and
error classes, commits, compactions, interrupts, subagent boundaries) to
wherever `gjalla auth login` configured. See the [root README](../README.md)
for exactly what is and isn't sent.

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
