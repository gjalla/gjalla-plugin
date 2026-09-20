---
name: gjalla-debug
description: Investigate a reported problem down to its root cause, with evidence, before proposing a fix. Use when something is broken, behaving unexpectedly, or a user reports an issue you can't immediately explain.
---

# Debug

Your job here is not to fix anything yet. It is to find out what is actually true, and to be able to show your work. A confident wrong diagnosis is more expensive than no diagnosis, because everything built on top of it has to be unwound.

The failure mode to guard against throughout: forming a theory early, then reading only what confirms it. A partial investigation feels exactly like a complete one from the inside.

## Process

### 1. Establish the symptom precisely

Before touching code, pin down what is actually observed. Who saw it, on what surface, with what inputs, how often, and starting when. "It's broken" and "the second save in a session returns stale data" lead to completely different investigations.

If the report is vague, the first useful output is a sharper description of the problem, not a fix.

### 2. Reproduce it, or say plainly that you couldn't

Run the thing. Do not reason about what the code would do when you have the option of observing what it does. Tracing a flow by reading is how bugs hide behind conditional branches, stale comments that describe code that no longer exists, and data shapes that only occur in production.

If you cannot reproduce it, say so explicitly and switch to evidence that doesn't require reproduction: logs, telemetry, database state, error reports. An unreproduced bug can still be diagnosed, but the confidence level is different and you should report it as different.

### 3. Check that what you're reading is current

Cheap, and it invalidates whole investigations when skipped. Confirm the checkout matches what's deployed, that you're not reading a stale worktree or vendored copy, and that any cached artifact you're consulting was regenerated recently. Grep results from an abandoned branch look identical to grep results from live code.

### 4. Gather context before theorizing

Check gjalla for what's already known: rules, memories, and change history often contain the exact gotcha you're about to rediscover, and the architecture tells you which components are actually in the path. Someone may have hit this before and written down why it happens.

### 5. Separate what you observed from what you inferred

Keep these distinct in your own notes and in your report. "The response body is empty" is an observation. "The serializer is dropping the field" is an inference. Inferences need to be confirmed against the code or the data before they get promoted, and an inference that never gets confirmed should be labeled as such when you report.

### 6. Find the root cause, not the first thing that would make the symptom go away

Ask why the broken state was reachable at all, not just which line produced it. A missing guard is usually the symptom of a mechanism that doesn't naturally enforce the invariant.

Before reversing any limit, timeout, retry count, or budget, check git history and comments for intent. Those numbers are often deliberate, and a previous incident is the reason they exist.

### 7. Enumerate the shape of the bug across the tree

Once you know what the defect looks like, grep for its shape repo-wide: the method called without its guard, the helper not used, the pattern repeated. Then report the count. Fixing the one instance you found while three others survive is a fix that will be reported again next month.

Check other repos too if the pattern crosses a service boundary.

### 8. Prove it

The proof that you found the real cause is a test that fails now and passes after the fix, for the right reason. Write it before the fix where you can. If a proposed fix doesn't change that test's result, you have the wrong cause, however plausible the story is.

## Output

- **Symptom**: what is observed, precisely, and under what conditions.
- **Root cause**: the mechanism, with file:line evidence.
- **Why it was reachable**: what allowed this state to exist, not just where it surfaced.
- **Blast radius**: every other place this shape occurs, enumerated with a count.
- **Confidence**: what you verified directly, what you inferred, and what you could not determine.
- **Proposed fix**: including the test that proves it.

If the fix is non-trivial or touches a system primitive, stop here and hand off to `gjalla-spec` rather than implementing directly.

## Principles

- **Evidence beats reasoning.** When you can run it, observe it, or query it, do that instead of arguing from the code.
- **Report what you don't know.** "I could not reproduce this and the diagnosis rests on a log line" is a useful, honest finding. Quiet confidence is not.
- **The bug is rarely where it surfaced.** The stack trace tells you where it became visible, which is often several layers downstream of where it became wrong.
- **Save what you learn.** A non-obvious cause is exactly the kind of thing that should go into gjalla memory so the next agent, or the next you, doesn't rediscover it: `gjalla memory add "<the fact>" -n "<short-name>"`.
