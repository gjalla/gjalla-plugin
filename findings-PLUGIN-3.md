# Findings — COWORK Brief PLUGIN-3: Hermes Agent joins the plugin repo

## 1. Move — done

`gjalla/observe/python/plugins/hermes/{plugin.yaml,__init__.py,README.md}`
moved to `gjalla-plugin/hermes/`, unchanged except the README install
section (see section 3 below — the exact command in the brief had to be
corrected after real testing). `python/plugins/` deleted from `observe`
in a separate commit there. `python/README.md` in `observe` had **no**
Hermes install paragraph to remove — checked directly with `grep -i
hermes python/README.md`, no match. The brief assumed one existed; it
didn't, so no edit was made there. (The brief also assumed the adapter's
docstring in `gjalla_observe/adapters/hermes.py` "already points at the
plugin repo" — it doesn't; its docstring is one line, `"Hermes adapter
(B10.4): register(ctx) wires 7 hooks to Session calls."` Not acted on,
since nothing in the brief required changing it, but flagging the
inaccuracy.)

## 2. Discovery verification — real, done, with a correction to the brief

**Installed the real `hermes-agent` package from PyPI** (`pip install
hermes-agent`, resolved to `0.19.0`, published by Nous Research — real
project, matches the B10.4 findings' docs reference at
`hermes-agent.nousresearch.com`) into an isolated venv, with an isolated
`HERMES_HOME` so nothing touched a real Hermes install.

**Read the actual installer source** (`hermes_cli/plugins_cmd.py`,
`_resolve_git_url` / `_install_plugin_core`) rather than trusting the
docs page B10.4 cited. The real mechanism:

- `hermes plugins install <identifier>` always `git clone --depth 1`s a
  URL. A subdirectory within that clone is used **only** if you tell it
  one explicitly: `owner/repo/path/to/plugin` shorthand, a
  `<url>#path/to/plugin` fragment (any scheme, including `file://`), or
  the `.git/path` boundary form for full GitHub URLs. There is **no**
  automatic scan of "root, or one level down" for a Git install — that
  description (from B10.4's findings, sourced from the docs page) turns
  out to describe the *bundled/user/project directory* discovery path
  (`~/.hermes/plugins/<name>/`, scanned by `PluginManager._scan_directory`
  in `hermes_cli/plugins.py`), not the `plugins install` Git-clone path.

**Verified this end-to-end against a real local clone of this branch**,
after committing `hermes/` (`git clone` needs a real commit, not just a
staged/working-tree file):

- `hermes plugins install "file:///…/gjalla-plugin"` (the bare-repo
  equivalent of `hermes plugins install gjalla/gjalla-plugin`, the exact
  command the brief specified for the README) — **clones the repo root,
  finds no `plugin.yaml` there, warns "doesn't contain plugin.yaml or
  __init__.py", and installs an empty, useless plugin directory.** This
  command as literally specified in the brief does not work.
- `hermes plugins install "file:///…/gjalla-plugin#hermes"` (the local
  equivalent of `hermes plugins install gjalla/gjalla-plugin/hermes`) —
  **clones cleanly, resolves the `hermes` subdir, and installs correctly**
  to `~/.hermes/plugins/gjalla` (name taken from `plugin.yaml`'s `name:
  gjalla`, not the repo/subdir name).
- `hermes plugins list` (with `--enable` on install) shows:
  ```
  gjalla | enabled | 0.1.0 | Sends Hermes session events to gjalla Observe (Observe > Sessions) | user
  ```
  and `~/.hermes/plugins/gjalla/plugin.yaml` on disk matches the source
  exactly, with all 7 hooks (`on_session_start`, `pre_llm_call`,
  `post_api_request`, `pre_tool_call`, `post_tool_call`,
  `api_request_error`, `on_session_end`).
- **`python_dependencies` (`gjalla-observe>=0.1,<0.2`) was NOT installed
  by `hermes plugins install`.** `pip show gjalla-observe` after install
  came back "not found." Grepped the installed `hermes-agent` 0.19.0
  package for `python_dependencies` handling in `hermes_cli/plugins.py`
  and `hermes_cli/plugins_cmd.py` — zero references. The only
  `python_dependencies`-adjacent code in the package is in
  `hermes_cli/main.py`, and it's Hermes' own optional-extras installer
  for `hermes update`/`hermes postinstall` (`.[all]` pip extras), unrelated
  to a plugin manifest's declared deps. Either this pip-published version
  doesn't implement plugin `python_dependencies` auto-install, or it's
  gated behind a path this environment didn't trigger (no real gateway
  restart, no `hermes doctor`/`hermes chat` run). Not chased further —
  out of scope for section 2, but worth flagging: **installing this
  plugin today may require `pip install gjalla-observe` by hand**, same
  as the manual README path already says.

**Conclusion for section 2**: the layout resolves — `hermes/plugin.yaml`
one level down in `gjalla-plugin` **is** installable — but only with an
explicit subdirectory in the install command, not by automatic discovery.
The brief's literal README text (`hermes plugins install
gjalla/gjalla-plugin`) is wrong and was corrected to `hermes plugins
install gjalla/gjalla-plugin/hermes` in `hermes/README.md`. This isn't
the "stop, Ellie decides between `plugins/hermes/` and a separate repo"
branch the brief described — the repo doesn't need restructuring, the
install command just needs the subdirectory, which is a one-line fix.

## 3. Root README — done

Added the Hermes row to the per-harness table and the sentence under "The
hooks" per the brief's exact wording. Diff:

```diff
 Every supported harness wires the same three collection points to the
-`gjalla` CLI (the collector). Claude Code and Codex wire a fourth, commit capture:
+`gjalla` CLI (the collector). Claude Code and Codex wire a fourth, commit
+capture. Hermes is the one harness whose hooks are Python callbacks rather
+than `gjalla` CLI commands — its plugin API hands over structured events
+directly, so there is no transcript to parse:

 | OpenClaw | [`openclaw/`](openclaw/) | README only — no hook surface to attach to, see its README |
+| Hermes Agent | [`hermes/`](hermes/) | plugin manifest + README; hooks call the `gjalla-observe` SDK adapter, no CLI hooks, no backfill |
 | Devin | — | no local surface; a server-side pull through Devin's enterprise sessions API is planned, not built |
```

## 4. One real session — blocked, needs Ellie

Not achievable in this environment. This step requires:

- `gjalla auth login` against the real dev backend (interactive OAuth/API-key
  flow this sandboxed session has no credentials or browser access for), and
- an interactive Hermes CLI chat session with a real tool call, which
  needs a configured LLM provider (`hermes model` / API keys) on top of
  the plugin install already verified in section 2.

I did not fabricate a session paste. What's real from section 2 stands on
its own as the discovery smoke test; the Sessions-row / trajectory /
attribution paste from an actual `gjalla auth login` + live chat session
is the piece only Ellie (with real dev credentials and a real Hermes
chat) can produce. Once available, drop it in this file under a "Section
4" heading, replacing this note.

## Deviations / judgment calls, summarized

1. **README install command corrected**, not shipped as literally
   specified in the brief — `hermes plugins install gjalla/gjalla-plugin`
   was tested against real `hermes-agent` 0.19.0 and does not work
   (installs an empty plugin). Changed to `hermes plugins install
   gjalla/gjalla-plugin/hermes`, verified working. The manual
   copy-into-`~/.hermes/plugins/` path was kept as documented, with its
   `cp -r` source path updated from `python/plugins/hermes` (its old
   location) to `hermes` (its new one relative to this repo's root).
2. **No `python/README.md` edit** — the paragraph the brief asked to
   remove didn't exist.
3. **Section 4 not attempted beyond documenting the block** — no
   fabricated output.
