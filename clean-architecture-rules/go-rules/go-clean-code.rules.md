---
trigger: always_on
description: 
globs: 
---

# Go Clean Code Rules

Principles:
- Code must be readable first.
- Prefer clarity over cleverness.
- Every file <=150 lines.
- Every function <=20 lines (soft limit).
- High cohesion, low coupling.

Naming:
- Use descriptive names.
- Avoid abbreviations unless universal (ID, URL).
- Structs: Nouns (Order, Customer).
- Methods: Verbs (CreateOrder, Confirm).
- Interfaces: capability names (Reader, Repository).
- Packages: short, lowercase, domain-oriented.

Structure:
- One responsibility per file.
- One concept per function.
- Avoid utility packages dumping unrelated logic.
- Prefer composition over inheritance.

Comments:
- Avoid redundant comments.
- Code must explain itself.
- Use comments only for:
  - domain intent
  - invariants
  - non‑obvious decisions

Functions:
- Small, focused, intention revealing.
- Avoid boolean flags.
- Prefer explicit functions over condition switches.

Error Handling:
- Return explicit errors.
- Do not hide failures.
- Wrap errors with context.

Formatting:
- Standard gofmt.
- Keep vertical density low.
- Separate logical blocks with whitespace.

Refactoring Rules:
- Rename aggressively for clarity.
- Extract functions when intent becomes unclear.
- Remove dead code immediately.