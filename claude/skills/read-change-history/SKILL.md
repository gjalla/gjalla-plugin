---
name: read-change-history
description: >
  Query semantic change history via gjalla's get_changes tool. Use when
  resuming work and needing to catch up, investigating when a rule or
  element changed, understanding the evolution of a specific component,
  or reviewing what a recent commit touched architecturally.
version: 0.1.0
metadata:
  openclaw:
    emoji: "📜"
    homepage: https://gjalla.io
    tags:
      - history
      - changes
      - traceability
      - architecture
---

# Read Change History

`get_changes` returns semantic change events from gjalla's
`primitive_change_log` — not git diffs, but structured records of what
happened to architecture elements, rules, capabilities, data flows,
and other primitives. Each event carries the change type, the commit,
and (when available) the agent and author who attested it.

---

## Common patterns

**What changed recently?**
```
get_changes(since="7d")
```

**What changed in a specific area?**
```
get_changes(element="architecture.api-server")
```

**What rules changed this month?**
```
get_changes(since="30d", primitive_type="rule")
```

**What did a specific commit touch?**
```
get_changes(commit="9c2f3e1")
```

**Show only agent-attested changes (not analysis-driven)?**
```
get_changes(since="7d", source="attestation")
```

---

## Reading the results

Each change event includes:

- **primitive_type** + **primitive_id** — what changed
  (e.g., `rule` + `rule.no-source-code-in-db`)
- **change_type** — `created`, `modified`, or `deleted`
- **commit_sha** — the git commit (if available)
- **source** — `attestation` (agent-driven) or `live` (analysis-driven)
- **attestation** — agent name, provider, and author email when the
  commit has a matching attestation. `null` for analysis-driven rows.
- **impact_score** — numeric score when the analysis pipeline computed
  one. `null` otherwise.

---

## When to use this

- **Resuming work** — catch up on what evolved since your last session.
  Check before assuming the architecture is the same as last time.
- **Investigating a change** — "when did this rule get added?" or
  "who modified this element?" The attestation data answers both.
- **Understanding velocity** — how many architectural changes happened
  in the last sprint? Are they concentrated in one area?
- **Post-incident** — trace what changed leading up to an issue.
  Filter by element or time window to narrow the blast radius.

---

## CLI equivalent

The same data is available from the terminal:

```
gjalla log --since 7d
gjalla log --type rule --since 30d
gjalla log --element architecture.api-server
gjalla log --json | jq '.changes[0]'
```

Both the CLI `--json` output and the MCP tool return the same
JSON structure.
