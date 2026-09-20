# gjalla (Cursor)

Observability for your coding agent sessions. Three hooks, all shelling
out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| A new composer conversation starts | `sessionStart` (fire-and-forget) | `gjalla hook session-start` |
| The agent loop ends | `stop` | `gjalla hook turn-end` |
| A composer conversation ends | `sessionEnd` (fire-and-forget) | `gjalla hook session-end` |

The CLI is the collector — see the [root README](../README.md) for exactly
what is and isn't sent.

## Setup

```
pip install gjalla
gjalla auth login
```

## A note on `stop`

Unlike Claude Code and Codex, Cursor's hook system has no `async` flag —
`stop` runs synchronously and briefly holds up the end of your turn while
`gjalla hook turn-end` posts. A 5-second timeout caps the worst case; in
practice it's single-digit milliseconds after the first turn (the CLI
only parses what's new). `sessionStart` and `sessionEnd` are fire-and-forget
by Cursor's own design, so they never block.
