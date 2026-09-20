---
name: gjalla-cleanup-audit
description: Audit a codebase for dead code, unreachable branches, duplicated logic, and vestigial abstractions, then remove them safely with proof. Use to reduce sprawl, pay down tech debt, or clean up after a feature is retired or migrated.
---

# Cleanup Audit

Find the code that is costing us in maintenance costs, causing confusion to agents and humans who onboard. Usually this is due to being unused, duplicated, or overengineered.

**You must prove something is dead before deleting it.** Grep does not see every reference, and removing code with a full confidence verification will result in production incidents.

## Process

### Phase 1: Orient

Establish your boundary. Within the repo is great, make sure that you consider cross-repo interoperability when assessing impact. gjalla can help you with this.
Briefly review recent changes to give you an idea of hotspots, though no areas should be ignored.
Check architecture, rules, learnings, and system evolution in gjalla.

### Phase 2: Investigate

Find dead code, duplicated logic (or very similar but drifted), overengineering, code that doesn't follow intended architectural patterns (therefore causing spaghetti code), additions that are chaotic, etc.

### Phase 3: Verify

For every candidate, enumerate references across the whole boundary, including ways that references can hide from grep. For example, be especially careful with public API endpoints because you cannot see all callers.

### Phase 4: Classify

| Tier | Description | Action |
|------|-------------|--------|
| **Tier 1** | Provably dead: zero references after full enumeration, no dynamic or external reach | Delete, with its tests |
| **Tier 2** | Dead in code but leaves data behind (orphaned rows, columns) | Delete code now; decide on data separately and deliberately |
| **Tier 3** | Duplication with a clear owner | Consolidate to one implementation, keep the best-tested one |
| **Tier 4** | Suspicious but unproven, or reachable from outside the boundary | Report, do not delete. Name what would settle it |
| **Stale claims** | Comments, docs, specs asserting things that aren't true | Correct immediately — cheapest and highest-value fix in the audit |

### Phase 5: Remove in waves

Leaf-first, so nothing breaks midway: tests, then callers, then the implementation, then the data file or module. Run the relevant suite between waves. Keep each wave independently revertible, and don't mix a deletion wave with a refactor.

## Output

1. **Tier 1 deletions**: file paths, line counts, and the enumeration that proves each is dead.
2. **Tier 3 consolidations**: which copies exist, which survives, what test pins the behavior.
3. **Tier 4 unproven**: what you suspect and what evidence would settle it.
4. **Stale claims corrected**: what was asserted, what is actually true.
5. **Impact**: what gets simpler, what risk you accepted, what you deliberately left alone.

## Principles

- **Proof, not confidence.** "I couldn't find a caller" and "there is no caller" are different claims. Report which one you have.
- **Deletion is the best refactor.** Code that doesn't exist has no bugs, needs no tests, and confuses nobody.
- **Don't delete data on a code audit.** Rows outlive the code that wrote them and may have been edited since. Removing the writer is a code decision; removing what it wrote is a product decision, and it belongs to a human.
- **Fix the misleading thing first.** A stale comment or a spec claiming finished work will cause a wrong decision faster than dead code will.
- **One concern per change.** A cleanup that also "improves things while in there" is impossible to review and impossible to revert cleanly.
