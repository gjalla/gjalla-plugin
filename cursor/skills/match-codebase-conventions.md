# Match Codebase Conventions

When a senior engineer joins a new project, the first thing they do isn't write code — it's
*read* code. They're not reading for understanding (that comes later). They're reading for
*patterns*. How does this team name things? How do they structure files? Where do they put
tests? How do they handle errors? What abstractions do they use?

This process is so automatic that most seniors can't articulate the conventions they've
absorbed — they just "feel" when something looks wrong. This skill makes that pattern
detection explicit and systematic.

The underlying principle is simple: **consistency is more important than personal preference.**
A codebase where everything follows the same patterns — even imperfect ones — is easier to
navigate, review, and maintain than a codebase where each file reflects a different author's
style.

---

## Step 0: Load Team Conventions from System State

Before scanning files manually, check whether the team's conventions have been codified.
Manually scanning 3-5 files works, but if the team has already documented their conventions
as ADRs, principles, or architecture decisions, those are the authoritative source.

**If gjalla is available**, query these tools first:

- `get_context(scope="rules")` — load active ADRs and principles. These are the
  conventions the team chose to write down — naming standards, architecture patterns,
  error handling strategies. They take precedence over patterns you observe in code
  (code might be inconsistent; the rules represent intent).
- `get_context(scope="architecture")` — load the system's architecture. This tells you
  how components are organized, which patterns are used (MVC, hexagonal, event-driven),
  and how relationships between components are structured.
- `get_file_context(file_path="...")` — before editing a specific file, get its
  architectural role so you understand how it fits into the larger structure.

**If gjalla is not available**, proceed with the file-scanning approach below. Look for
`CONTRIBUTING.md`, `.editorconfig`, linter configs, or `docs/style-guide.md`.

---

## Convention Detection Checklist

Before writing new code, scan the codebase for patterns in each of these categories. You
don't need to document all of them — just enough to write code that blends in.

### Naming

- **Variables and functions**: camelCase, snake_case, or something else? Are booleans
  prefixed with `is`/`has`/`should`? Are callbacks prefixed with `on`/`handle`?
- **Files and directories**: kebab-case, PascalCase, snake_case? Do filenames match the
  exported class/function name?
- **Classes and types**: PascalCase? Suffixed with the pattern (e.g., `OrderService`,
  `UserRepository`, `PaymentHandler`)?
- **Constants**: UPPER_SNAKE_CASE? Where are they defined — in the file, in a constants
  file, in environment variables?
- **Database columns and tables**: singular or plural table names? snake_case columns?
  Do foreign keys follow `<table>_id` convention?
- **API endpoints**: RESTful nouns or action verbs? Plural or singular resources? How are
  nested resources structured?

### Architecture Patterns

- **Code organization**: feature folders vs. layer folders? Where do new files go?
  ```
  Feature folders:    src/orders/controller.ts, src/orders/service.ts, src/orders/model.ts
  Layer folders:      src/controllers/orders.ts, src/services/orders.ts, src/models/orders.ts
  ```
- **Dependency injection**: constructor injection, parameter injection, service locator,
  or direct imports?
- **Data access**: ORM, query builder, raw SQL, or repository pattern? Are database calls
  in the service layer or a separate data layer?
- **API structure**: controller → service → repository? Or something flatter/different?
- **Configuration**: environment variables, config files, feature flags? Where do they live?

### Error Handling

- **Strategy**: throw exceptions, return Result/Either types, return error codes, or
  callback-style errors?
- **Custom error classes**: does the project define domain-specific error types, or does
  it use generic errors?
- **Error responses**: what shape do API error responses have? Is there a standard error
  formatter?
- **Logging**: what gets logged on errors? What level? What context fields?

### Testing

- **Framework**: Jest, pytest, Go testing, JUnit? What assertion style?
- **File location**: co-located with source (`foo.test.ts` next to `foo.ts`) or in a
  separate test directory?
- **Naming**: `describe/it`, `test_<function>_<scenario>`, or something else?
- **Fixtures and factories**: how is test data created? Is there a factory pattern, fixture
  files, or inline test data?
- **Mocking**: what gets mocked? How? Are there shared mock helpers?
- **Coverage**: is there a coverage threshold? Which kinds of tests exist (unit, integration,
  e2e)?

### Code Style

- **Formatting**: is there a formatter config (Prettier, Black, gofmt)? Follow it exactly.
- **Linting**: is there a linter config (ESLint, pylint, golangci-lint)? What rules are
  enabled?
- **Comments**: does the project use JSDoc/docstrings/godoc? How detailed? Are inline
  comments common or rare?
- **Imports**: absolute or relative paths? Grouped by type? Specific ordering?

### Patterns You Might Not Think to Check

- **How are feature flags used?** Is there a standard pattern for checking flags?
- **How are database migrations structured?** What tool is used? Naming convention?
- **How are background jobs defined?** Is there a job framework? How are retries handled?
- **How are events/messages published?** Event names, payload shapes, serialization format?
- **How are permissions checked?** Middleware, decorators, inline checks?
- **How are external API calls made?** Shared HTTP client, per-service wrappers, retry logic?

---

## How to Scan Efficiently

You don't need to read the entire codebase. Follow this process:

1. **Find a recent, well-reviewed file similar to what you're building.** Look at recent
   PRs or recently modified files in the area you're working in. These represent the team's
   current conventions (which may differ from older code).

2. **Read 3-5 files of the same type.** If you're writing a new service, read 3 existing
   services. If you're writing a new API endpoint, read 3 existing endpoints. Look for the
   patterns they share.

3. **Check for explicit style guides.** Look for `CONTRIBUTING.md`, `.editorconfig`,
   linter configs, or a `docs/style-guide.md`. These are the rules the team chose to write
   down.

4. **When in doubt, match the surrounding code.** If the conventions aren't clear or are
   inconsistent across the codebase, match the conventions of the *nearest* code — the files
   in the same directory or the same feature area.

---

## When Conventions Conflict With Best Practices

Sometimes the codebase conventions are genuinely bad. Maybe error handling is inconsistent,
or the naming is confusing, or there's a pattern that creates bugs.

**Default to matching existing conventions anyway.** Consistency has value even when the
convention isn't ideal. A codebase with one consistent (imperfect) pattern is easier to
work with than a codebase with two patterns where "the new way is better."

**Exception: when the convention is actively harmful.** If following the convention would
introduce a security vulnerability, data corruption risk, or performance problem, deviate
from it — and document why. Add a TODO or a note in the PR explaining that this deviates
from the existing pattern and why.

If you believe a convention should change project-wide, that's a separate effort. Don't
try to reform the codebase one file at a time during feature work — that creates
inconsistency, which is worse than a bad but consistent convention.

---

## Output

This skill doesn't produce a standalone document. Instead, it ensures that every file you
create follows the patterns of the codebase it lives in. The output is code that looks like
it was written by someone who's been on the team for months, not by an outsider.

If you discover that conventions are unclear or inconsistent, note this to the user — it
may be worth establishing explicit conventions (a `CONTRIBUTING.md` or linter rules) to
prevent the inconsistency from growing.

### Attestation: Conventions Followed

In the PR description, document which conventions you matched and any deviations:

```
## Conventions Attestation

**Rules checked**: [ADRs/principles from get_context(scope="rules") that applied]
**Conventions matched**: [specific patterns you followed — naming, architecture, error handling]
**Conventions deviated from**: [any deviations, with justification]
**Conventions discovered (not yet codified)**: [patterns you observed in code that aren't
in any formal rule — worth discussing with the team]
```

This attestation serves two purposes: it proves the agent respected the team's conventions,
and it surfaces uncodified conventions that the team might want to formalize.
