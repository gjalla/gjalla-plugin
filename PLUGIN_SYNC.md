# Plugin Sync Protocol

Three plugin directories ship the same gjalla functionality in three host formats:

- `claude/` — Claude Code plugin (CLAUDE.md + commands + skills)
- `cursor/` — Cursor plugin (rules/*.mdc + skills, no CLAUDE.md)
- `openclaw/` — OpenClaw plugin (CLAUDE.md + commands + skills)

Content that must be consistent across these three must be updated in sync. This doc defines **what must stay in sync**, **how to verify**, and **how to avoid drift** without building a full fanout tool yet.

---

## Why this exists

An agent landing in any of the three plugins should get the same mental model of gjalla: same value framing, same tool catalog, same workflows, same reference formats. Drift between plugins means "use Claude Code with gjalla" is a different experience from "use Cursor with gjalla," which undermines the cross-agent consistency promise in the agent-onboarding vision.

We are deliberately choosing a **documented sync protocol** over a **content fanout tool** for now. The fanout tool is better long-term but over-engineered for three plugins with five skills each. Revisit if drift becomes chronic or we add more plugins.

---

## What must stay in sync

### 1. Agent instructions — same content, host-native format

| Surface | Canonical shape |
|---|---|
| `claude/CLAUDE.md` | Markdown, single file |
| `openclaw/CLAUDE.md` | Markdown, single file |
| `cursor/rules/gjalla-architecture.mdc` + other `.mdc` files | Cursor rule files, `alwaysApply: true` for the main one |

**Required sections** (all three plugins must cover, in whatever format is host-native):

1. **What is gjalla and what does it take off your plate** — Day-1 value framing, ~5 bullets
2. **Auth and onboarding** — `gjalla auth login` device flow, how to get a key
3. **MCP tool catalog** — full list of available MCP tools with one-line descriptions, grouped by concern (orient / inspect / change / memory / read-history / governance)
4. **Core workflow: orient before working** — call `get_context`, check rules, check memories for the area being touched
5. **Core workflow: attestation on commit** — what attestation is, when to create one
6. **Core workflow: writing memories** — when to create a memory, what metadata to set
7. **Fallback behavior** — what to do when MCP is disconnected

Section order may vary per host format; content must be equivalent.

### 2. MCP tool catalog — identical list

Every plugin's tool catalog must list **all** MCP tools registered in `gjalla_precommit/mcp_server/server.py`. One line per tool with purpose. Grouped by concern.

When a new MCP tool is added to the server, all three plugins get an update in the same PR. Missing a tool in a plugin is a drift bug.

### 3. Skills — same skills, same content

The source of truth is `gjalla/engineering` (the public `npx skills add
gjalla/engineering` channel), specifically its `skills/` directory. The skill
set is whatever that repo currently ships — there is no hard-coded list here;
check `engineering/skills/` directly.

`claude/skills`, `cursor/skills`, and `openclaw/skills` each carry an exact,
byte-for-byte copy of `engineering/skills/`. `scripts/sync-skills.sh` copies
the source into all three and removes anything in them not present in the
source — run it after any change to the source skill set, and nothing else
needs to be kept in sync by hand.

### 4. References — identical YAML files

The four example YAMLs describing gjalla data formats:

- `example-attestation.yaml`
- `example-gjallamap.yaml`
- `example-gjallarules.yaml`
- `example-gjallastate.yaml`

These must be **byte-identical** across the three plugins' `references/` directories. They describe data schemas, and drift is a correctness bug, not a stylistic one.

`references/README.md` may differ if the plugin format requires host-specific phrasing, but the data-format descriptions must match.

### 5. Commands (claude/ and openclaw/ only)

Cursor uses rules + skills instead of commands. The two plugins that do use commands (`claude/commands/` and `openclaw/commands/`) must ship the **same five commands with the same content**:

- `gjalla-setup.md`
- `gjalla-context.md`
- `gjalla-impact.md`
- `gjalla-review.md`
- `gjalla-attest.md`

When the gjalla CLI gains a new first-class command that deserves a plugin command shortcut, add it to both plugins.

### 6. Hooks (all three)

`hooks/hooks.json` in each plugin wires pre-commit and post-commit hooks. The three plugins must have **equivalent hook behavior** — same commands invoked, same failure handling, same environment variables.

Hook configuration syntax may vary per host. Verify behavior equivalence by running `gjalla attest --example` on a test repo under each plugin and comparing output.

---

## How to verify sync (manual, for now)

Before committing a change that touches plugin content, run through this checklist:

1. **If you touched a CLAUDE.md or a cursor rule:** did you update the equivalent sections in the other two plugins? (Two CLAUDE.md files + cursor rule files.)
2. **If you added or renamed an MCP tool:** does it appear in all three plugins' tool catalogs?
3. **If you touched a skill:** does the same skill exist in all three plugins with equivalent content?
4. **If you touched a reference YAML:** did you diff the three plugins' copies of that file to verify they're byte-identical?
5. **If you touched a command:** did you update both `claude/commands/` and `openclaw/commands/`?
6. **If you touched hooks:** did you verify the three hooks.json files all invoke equivalent gjalla CLI commands?

A quick sanity check from the plugin repo root:

```bash
# References should be byte-identical across plugins
diff claude/references/example-attestation.yaml openclaw/references/example-attestation.yaml
diff claude/references/example-attestation.yaml cursor/references/example-attestation.yaml
# Repeat for the other 3 reference files

# Skills should have the same names
ls claude/skills/
ls openclaw/skills/
ls cursor/skills/
```

---

## CI check (recommended, future)

A small GitHub Actions job would make this automatic:

```yaml
- name: Verify plugin reference sync
  run: |
    for f in example-attestation example-gjallamap example-gjallarules example-gjallastate; do
      diff claude/references/$f.yaml openclaw/references/$f.yaml
      diff claude/references/$f.yaml cursor/references/$f.yaml
    done

- name: Verify skill set parity
  run: |
    for plugin in claude cursor openclaw; do
      ls -1 $plugin/skills/ | sort > /tmp/$plugin-skills.txt
    done
    diff /tmp/claude-skills.txt /tmp/cursor-skills.txt  # accounting for file/dir difference
    diff /tmp/claude-skills.txt /tmp/openclaw-skills.txt
```

Not required for v1 — documented here so it's obvious what to automate when we decide it's worth it.

---

## Escalation: when to move to a fanout tool

Move from documented sync to a content-fanout tool if any of these trigger:

1. We add a fourth plugin (cascading updates become infeasible manually)
2. Reference files drift repeatedly despite the CI check
3. Agent instructions grow beyond ~300 lines per plugin and manual parallel edits become error-prone
4. We start shipping more than 10 skills

The fanout tool would probably live at `gjalla-plugin/content/` with source-of-truth files and a `scripts/sync-plugins.sh` that renders each plugin's native format. Out of scope until a trigger fires.
