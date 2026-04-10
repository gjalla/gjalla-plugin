---
description: Show recent semantic change history
allowed-tools: Read
argument-hint: "[since: 7d|30d|2w] [type: rule|element|capability|...]"
---

Show semantic change history for this project — what architecture elements,
rules, capabilities, and other primitives changed, when, and by whom.

1. Use the `get_changes` MCP tool.
   - Default: `get_changes(since="7d")` — last 7 days.
   - If the user specified a time window ($1), pass it: `get_changes(since="$1")`
   - If the user specified a type ($2), pass it: `get_changes(primitive_type="$2")`
   - For a specific element: `get_changes(element="architecture.api-server")`
   - For a specific commit: `get_changes(commit="abc1234")`

2. Present the changes as a timeline:
   - Group by commit (same commit SHA = one group)
   - Show date, short SHA, source (attestation vs analysis), author if available
   - For each change: primitive type, primitive id, change type (created/modified/deleted)
   - Highlight any rule changes — these affect constraints for future work

3. Suggested follow-ups:
   - "To understand a specific element's current state: /gjalla-context architecture"
   - "To see the impact of your uncommitted changes: /gjalla-impact"

If gjalla MCP tools are not available, suggest:
```
gjalla log --since 7d
gjalla log --type rule --since 30d
```
