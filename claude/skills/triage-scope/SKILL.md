---
name: triage-scope
description: >
  Triage issues discovered during implementation — decide what to fix now, what to note for later,
  and what to leave alone. This is a "scope filtering" process that senior engineers do continuously
  while coding: they notice problems that aren't part of the current task and make disciplined decisions
  about each one. Use this skill whenever you encounter code quality issues, bugs, tech debt, or
  improvement opportunities while working. Also trigger when you feel the urge to refactor something
  you're reading or to "quickly fix" something unrelated to the task. Scope discipline is one of the
  most important and least taught engineering skills.
---

# Triage Scope

While implementing a feature, a senior engineer constantly notices things: a poorly named
variable, a missing error handler, a duplicated function, an outdated comment, a potential
race condition in code they're reading but not changing. For each one, they make a split-second
decision: fix it, note it, or leave it alone.

This sounds simple, but getting it wrong in either direction is expensive. Fix too much and
you create scope creep — your "add a button" PR becomes a 40-file refactor that's impossible
to review and risky to deploy. Fix too little and you walk past problems that would have taken
5 minutes to address, leaving them to cost someone hours later.

The skill is the filter — knowing which category each issue falls into, and having the
discipline to follow through on that categorization.

---

## The Three Buckets

### System Context for Scope Decisions

Scope decisions improve significantly when you know what the team has already identified.

**If gjalla is available**, query these tools first:

- `get_context(scope="capabilities")` — check whether the issue you noticed is already tracked as
  a known capability gap, a proposed feature, or a deprecated component. If it's already
  tracked, you can reference it in your "Note for Later" instead of creating a duplicate.
- `get_impact` — understand the neighborhood of the issue using the current git diff. A "quick
  fix" in a file with 40 dependents is not actually quick.
- `get_context(scope="rules")` — check for any rules about scope discipline (e.g., "refactoring
  changes must be in separate PRs from feature work").

**If gjalla is not available**, use your judgment about blast radius and check for existing
tickets before creating new ones.

---

Every issue you encounter during implementation goes into one of three buckets:

### Fix Now

Fix it immediately as part of the current work. These are issues that:

- Are directly in your path (you're already editing this file or function)
- Take less than 5 minutes to fix
- Would make your own change harder to review or test if left unfixed
- Are genuine bugs that could affect users now (not theoretical risks)
- Would cause your code to be inconsistent with its surroundings

**Examples:**
- A typo in a variable name in the function you're modifying
- An unused import in a file you're editing
- A missing null check on a code path your feature uses
- An outdated comment directly above code you're changing
- A minor formatting inconsistency in code you're touching

**The key constraint: keep it in scope.** If you fix something, it should be a small,
obviously-correct change that a reviewer won't have to think hard about. If fixing it
requires thought, testing, or discussion, it belongs in the next bucket.

### Note for Later

Track it, but don't fix it now. These are issues that:

- Would take more than 5 minutes to fix properly
- Are outside the files you're actively changing
- Require their own testing or review
- Might have non-obvious side effects
- Are important enough that someone should eventually address them
- Would expand your PR's blast radius if included

**How to note them:**

1. **Add a TODO/FIXME comment** in the code if the issue is localized:
   ```
   // TODO: This function doesn't handle the case where amount is negative.
   // See [ticket/issue link if applicable]
   ```

2. **Create a ticket/issue** if the issue is significant:
   - Brief description of the problem
   - Where you found it (file, line, context)
   - Why it matters (impact on users, maintainability, performance)
   - Suggested approach if you have one

3. **Add to the tech debt inventory** if the issue is part of a pattern:
   - Use the manage-tech-debt skill for systematic tracking

4. **Mention it in your PR description** if it's relevant context:
   ```
   ## Noticed but not addressed
   - The `UserService` has no retry logic for database calls.
     This is pre-existing and out of scope, but worth a follow-up.
   ```

### Leave Alone

Don't fix it, don't note it. These are issues that:

- Are cosmetic and not in your path (formatting in a file you're not editing)
- Reflect a deliberate choice you disagree with but that works fine
- Are in legacy code that nobody maintains and nobody reads
- Would require a codebase-wide convention change to fix properly
- Are technically suboptimal but cause no practical problems

**This bucket is important.** Not everything that *could* be better *should* be improved.
Engineering time is finite. A senior engineer's judgment about what to leave alone is just
as valuable as their judgment about what to fix.

---

## Decision Framework

When you encounter an issue, run through this quick filter:

```
Is it in a file I'm already editing?
  ├── Yes: Can I fix it in under 5 minutes with no risk?
  │     ├── Yes → Fix Now
  │     └── No → Note for Later
  └── No: Is it a bug that affects users right now?
        ├── Yes → Note for Later (high priority ticket)
        └── No: Is it important enough that someone should know about it?
              ├── Yes → Note for Later (ticket or TODO)
              └── No → Leave Alone
```

### Calibrating by Context

The thresholds shift depending on context:

**During a hotfix or urgent work:**
- Raise the bar for "Fix Now" — only fix things that are blocking the fix
- Lower the bar for "Leave Alone" — almost everything that isn't the immediate problem
  gets left alone
- "Note for Later" still applies for things you discover that could cause the next incident

**During a refactoring task:**
- Lower the bar for "Fix Now" — the whole point is cleanup, so more things qualify
- But still maintain scope — if the refactoring task is "extract service X", don't also
  restructure service Y

**During feature work:**
- The default thresholds apply
- Be especially disciplined about not expanding the PR scope — feature PRs should be
  reviewable and deployable

**During exploration / spike work:**
- Be liberal with "Note for Later" — you're specifically looking for problems
- Don't fix anything yet — the point is to understand the landscape

---

## The Scope Creep Trap

The most common failure mode isn't ignoring problems — it's fixing too many of them. Scope
creep happens gradually:

1. You notice a poorly named function while implementing your feature
2. You rename it (5 minutes — reasonable)
3. But renaming it means updating 8 call sites across 5 files
4. While updating those files, you notice they have inconsistent error handling
5. You "quickly" fix the error handling in one of them
6. But now that file is inconsistent with the other 4...

Each individual step felt reasonable. But you've gone from "add a feature" to "rename a
function, update 5 files, and fix error handling" — and you're not done with any of it.

**The discipline**: when you notice the scope expanding, stop. Commit what you have for
the current task. Create a separate PR or ticket for the cleanup work. This is harder
than it sounds because the cleanup work is *right there* and it feels wasteful to step
away from it. But separable changes should be separated — it makes each one safer,
reviewable, and deployable.

---

## Output

This skill produces two things:

1. **Clean, focused PRs** — your implementation contains only the changes needed for the
   task, plus small obvious improvements in files you touched.

2. **A trail of notes** — TODOs in code, tickets for follow-up, mentions in PR descriptions.
   This trail ensures that the things you noticed don't disappear, even though you (correctly)
   chose not to address them right now.

When presenting your work, briefly mention the triage decisions you made:

```
## Scope Notes
- Fixed: renamed `proc()` to `processPayment()` in `payment_service.ts` (was already editing)
- Noted: `UserService` has no retry logic for DB calls — created ticket PROJ-456
- Left alone: `legacy_importer.py` formatting — not in scope, nobody maintains this
```

This signals to reviewers that you *noticed* these things and made deliberate choices about
them, rather than missing them.

### Attestation: Scope Decisions

The scope notes above *are* the attestation. They document what the agent noticed, what it
decided, and why. This is critical for accountability — a reviewer should be able to see
that the agent was aware of adjacent issues and made disciplined decisions about each one,
rather than being oblivious to them.

If gjalla was used, the attestation can include references:

```
## Scope Attestation

**Issues triaged**: [count — how many things you noticed outside the task scope]
**Fixed now**: [list with justification — small, in-path, low-risk]
**Noted for later**: [list with ticket/capability references from gjalla]
**Left alone**: [list with reasoning]
**Rules respected**: [scope-related ADRs or principles from get_context(scope="rules")]
```
