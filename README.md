# gjalla plugin

Observability for agentic engineering. This plugin is collection only:
install it and session/commit telemetry starts flowing to gjalla cloud
automatically, harness by harness, with no per-repo setup and nothing to
run by hand.

Skills and the MCP server (context, memory, rules) are **not** part of
this plugin. Skills come from `npx skills add gjalla/engineering`; the
MCP server is installed by the `gjalla-onboard` skill for teams that want
live context and memory. This repo is telemetry only.

## What it collects

A trimmed transcript, as ordered events: user and assistant text, tool
names and inputs, tool result sizes and error classes, commits, context
compactions, interrupts, and subagent boundaries.

## What it never collects

Tool result bodies, or file contents.

## The three hooks

Every supported harness wires the same three points to the `gjalla` CLI
(the collector):

| Event | Command | Notes |
|---|---|---|
| Session start | `gjalla hook session-start` | drains the outbox, sweeps missed deltas |
| End of each turn | `gjalla hook turn-end` | posts the turn's delta; async where the harness supports it |
| Session end | `gjalla hook session-end` | posts the final delta, `status: ended` |

The hooks post to wherever `gjalla auth login` configured
(`GJALLA_API_KEY`/`GJALLA_API_URL`, or the CLI's own config). This repo
carries no URL.

## Install per harness

| Harness | Directory | Status |
|---|---|---|
| Claude Code | [`claude/`](claude/) | plugin manifest + hooks + README |
| Codex CLI | [`codex/`](codex/) | plugin manifest + hooks + README — hooks need trusting via `/hooks`, see its README |
| Cursor | [`cursor/`](cursor/) | plugin manifest + hooks + README, but not yet listed in the marketplace — no Cursor transcript parser exists yet, hooks currently no-op, see its README |
| OpenClaw | [`openclaw/`](openclaw/) | README only — no hook surface to attach to, see its README |
| Devin | — | no local surface; a server-side pull through Devin's enterprise sessions API is planned, not built |

```
pip install gjalla
gjalla auth login
```

Then install the plugin for your harness (Claude Code: `claude plugin add
gjalla`; Codex: install then trust via `/hooks`, see `codex/README.md`).
Cursor isn't published to the marketplace yet — see `cursor/README.md`.

## License

MIT
