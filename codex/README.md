# gjalla (Codex CLI)

Observability for your coding agent sessions. Three hooks, all shelling
out to the `gjalla` CLI:

| Event | Hook | Command |
|---|---|---|
| Session starts (`startup`, `resume`, `clear`, `compact`) | `SessionStart` | `gjalla hook session-start` |
| End of each turn | `Stop` (async) | `gjalla hook turn-end` |
| Session ends | `SessionEnd` (3s budget) | `gjalla hook session-end` |

The CLI is the collector — see the [root README](../README.md) for exactly
what is and isn't sent.

## Setup

```
pip install gjalla
gjalla auth login
```

## Trusting the plugin's hooks

Codex does not auto-trust plugin-bundled hooks. After installing this
plugin, run `/hooks` in the Codex CLI, find the three `gjalla` entries
(they'll show as "untrusted, pending review"), and trust them. Until you
do, Codex silently skips them — including under `codex exec`, which does
not prompt (see [openai/codex#46210](https://github.com/openai/codex/issues/46210)).
If a session isn't showing up in gjalla, check `/hooks` first.
