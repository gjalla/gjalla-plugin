# gjalla Hermes plugin

Sends your Hermes Agent session events to gjalla Observe.

## Install

Credentials come from `gjalla auth login` (`~/.gjalla/config.yaml`); no
plugin-specific config is required. `GJALLA_API_KEY` env var still wins if set.

```
pip install gjalla
gjalla auth login
hermes plugins install gjalla/gjalla-plugin/hermes
hermes plugins enable gjalla
```

(`gjalla/gjalla-plugin` is a multi-harness repo — `claude/`, `codex/`,
`cursor/`, `hermes/` each hold their own manifest, so the subdirectory is
required; `hermes plugins install gjalla/gjalla-plugin` on its own clones
the repo root, where there is no `plugin.yaml`, and finds nothing. See
`findings-PLUGIN-3.md` for how this was verified against a real Hermes
install.)

Manual alternative — copy the directory into your Hermes plugins folder
directly, e.g. from an unpublished checkout:

```
cp -r hermes ~/.hermes/plugins/gjalla
cd ~/.hermes/plugins/gjalla
pip install gjalla-observe
hermes plugins enable gjalla
```

## What is sent

Session start/end, user messages (subject to your local capture-prompts
policy), assistant replies with token usage, and tool calls/results -
mapped to gjalla's event-schema-v2. No tool result bodies are sent, only
size and error status.

## Where to look

Observe > Sessions, harness "hermes".
