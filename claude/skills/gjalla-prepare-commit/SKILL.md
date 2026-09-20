---
name: gjalla-prepare-and-commit
description: Make sure your code is ready to commit, then stage changes into clean, atomic commit. Use before committing.
---

# Make your changes commit-ready

Turn a working change into a committable change that reviewers and future readers can trust.

## 1. Review what you implemented
- Are all verification criteria and expected outcomes met?
- Is the implementation complete (no dummy data or placeholder stubs left)?
- Are all of the gjalla rules met?
- Does this elegantly build on top of / within the existing state/architecture/properties?
- Does it match the plan / gjalla spec?
- Are positive, negative, and edge cases saliently tested?
- Has the code review process been completed?

If the answer to any of these questions is no, determine what changes are needed. We absolutely cannot tolerate any whack-a-mole changes. It's better to take a step back and design the elegant and sustainable solution to any issues. If a tradeoff needs human review, you may prompt your user.

Once you can confidently answer 'yes', note what you verified (which suite ran, exit code, DoD items) so your change summary carries evidence, not just claims.

## 2. Present the process (the second human gate)
- Write a short change report for the human: the phases you went through, the evidence for each (reviews, test runs, DoD), and the system impact.

- The report is the human gate: "here are the phases I went through, the evidence for each (reviews, test runs, milestones), and the system impact." Present it — or its key points — to the human before sealing, unless they've given you standing approval for low-risk changes.

## 3. Make a commit plan
- One logical change per commit. If the diff does two unrelated things, don't be afraid to split it (`git add -p`).
- Stage exact files — bulk-staging (`git add -A`/`-u`/`.`) is how unrelated in-flight work ends up in your commit.
- Ensure you're committing to the right branch and/or following the expected branching strategy.
- Prepare what you will report to git (code-level changes) and to gjalla (system-level changes)
- Ensure gjalla git hooks are in place already. If they're not, your attestation and spec will not get sync'd into the master source of truth.

## 4. Commit
- Write your gjalla attestation. `gjalla attest --example` will show you the format, make sure to view the full output (do not run the command and pipe it 2>/dev/null for example)
- Write your commit message and run your commit. Your gjalla attestation and spec will be sync'd with gjalla as part of the git hooks, no additional work required from you.
- Unless the user has given you blanket permission, you should likely ask the user before pushing the commit.
