---
rule_id: RULE-COMMON_CODE_QUALITY_GUARDRAILS
trigger: model_decision
description: "Cross-language Clean Code, naming, strict maintained-file size, complexity, duplication, SOLID, Clean Architecture, CQRS, and Fowler refactoring guardrails."
---

# Common Clean Up Guardrails

Load this rule for the final clean-up gate. The gate reviews every file created or modified by the SDD spec, including production code, tests, contracts, configuration, CI, documentation, and generated artifacts. The language rules and repository conventions remain authoritative when they are stricter.

## Review Scope And Exceptions

- Determine the exact baseline commit and changed file set from the spec, `change-summary.md`, and Git diff. Do not silently review only the files that are convenient.
- Review all created files and every modified file that belongs to the spec. Review adjacent files only when needed to prove a dependency, naming, ownership, or architecture violation.
- Generated, vendor, third-party, binary, and formatter-owned files may be excluded from the size threshold only when the repository identifies them and the exclusion is recorded with path, reason, owner, and explicit human approval in `code-quality-review.md`. Maintained source, test, configuration, CI, and script files have no other size exception.
- A quality exception needs a reason, owner, expiry or follow-up spec, and explicit human approval. The agent cannot approve an exception for its own change.
- Do not use line counts as a reason for mechanical micro-splitting. A split must improve naming, ownership, testability, or boundary clarity.

## File And Function Limits

Use native repository metrics when available. Otherwise count physical lines with `wc -l` (including blank and comment lines) for every newly created or materially changed source, test, configuration, CI, and script file:

| Surface | Target | Mandatory review threshold |
|---|---:|---:|
| Any in-scope source, test, configuration, CI, or script file | < 150 lines | >= 150 lines |
| Function/method/handler | <= 20 lines | > 30 lines |
| Type/class/component responsibility | one primary responsibility | multiple unrelated actors or reasons to change |

The mandatory threshold means the gate must produce a blocker finding and refactor the file before final validation. An in-scope maintained file with exactly 150 lines fails because the requirement is fewer than 150 lines. Do not satisfy the limit with blind micro-splitting: each extracted file must improve naming, ownership, testability, or boundary clarity. Generated, vendor, third-party, binary, and formatter-owned files may be excluded only with a documented path, reason, owner, and human approval.

## Naming And File Ownership

- Names reveal the domain behavior, actor, command, query, policy, boundary, or UI purpose. Avoid unexplained abbreviations and vague names such as `Manager`, `Helper`, `Utils`, `Common`, `Base`, `Data`, or `Service` unless the domain meaning is explicit.
- A file has one clear owner and one reason to change. Its name matches the primary public type, component, hook, command, query, policy, adapter, schema, or behavior it owns.
- Use the language and repository convention consistently: Go files/packages use the existing lower-case/snake-case convention; C# types and members use the existing PascalCase/camelCase convention; React/Web components and types use the established PascalCase convention and hooks use `useX` names.
- Commands, queries, handlers, policies, DTOs, ports, adapters, events, and tests use names that distinguish intent and side effects. Do not hide a command inside a query name or a query inside a command name.
- Test names describe Given/When/Then behavior and map to stable `TEST-*` IDs. Do not name tests after private methods, line numbers, or implementation trivia.
- File names, folder names, namespaces/packages, exported symbols, and spec task names must agree. Do not add a file with a misleading generic name to avoid moving or splitting ownership.
- Domain/Application naming must remain technology-neutral. Reject provider names such as `DynamoDB`, `Cosmos`, `Kafka`, `SQS`, `SNS`, `Redis`, `PostgreSQL`, `EF Core`, or `AWS` in inner-layer file names, namespaces/packages, types, ports, methods, DTOs, events, and errors; keep those names in outer adapters, mapping, and composition.

## Clean Code And SOLID

- Apply SRP at the module boundary as Robert C. Martin defines it in *Clean Architecture*: a module should be responsible to one, and only one, actor. Record the actor and its reasons to change. Functions and methods should remain cohesive, but SRP does not require one statement, one method, or artificial micro-splitting.
- Separate parsing, authorization, business decisions, persistence, mapping, transport, logging, and orchestration when they serve different actors or change for different reasons.
- Remove dead code, unused imports/dependencies, commented-out code, speculative branches, duplicate constants, magic values, and unused extension points.
- Prefer simple control flow, guard clauses, explicit data transformations, and domain names over comments that explain confusing code.
- Avoid `if/else` trees and `switch`/`case` chains as an extensibility mechanism. Simple guard clauses, validation/error checks, and small closed classifications are allowed when they are the clearest code.
- Repeated, nested, type/status-driven, or policy-heavy branching is a refactoring smell: move variation to a named function, decision object, strategy/dispatch map, polymorphism, state, or special case only when a real boundary or variation exists.
- Keep error handling at the correct boundary. Do not swallow errors, duplicate mapping decisions, leak provider details, or log the same failure repeatedly.
- Apply all five SOLID principles as mandatory design checks: actor-based SRP, OCP at real variation boundaries, LSP-compatible ports/adapters, ISP through focused consumer-owned interfaces, and DIP from policy/use cases toward abstractions with details implementing them. The implementation must remain idiomatic and must not add speculative abstractions or SOLID theater.
- Do not add generic repositories, mediators, factories, wrappers, registries, or abstractions solely to satisfy a metric or hypothetical future use.
- Remove duplication of business rules, validation, authorization, mapping, error decisions, session handling, and infrastructure setup. Keep intentional duplication when an abstraction would couple unrelated actors and record the reason.
- Review duplication both textually and semantically across the complete changed scope and adjacent owners. Remove meaningful duplication, give the rule one owner, and record the detector/search command, removals, exclusions, and intentionally retained similarities in `code-quality-review.md`.

## Spaghetti Code And Code Smells

- Search changed code and its neighboring owners for spaghetti code and actionable smells, not only formatter or lint violations.
- Treat long/deeply nested control flow, mixed policy/I/O/mapping, god functions or types, hidden mutable state, temporal coupling, feature envy, shotgun surgery, primitive obsession at boundaries, boolean flags that change behavior, duplicated branches, dead code, and catch-all `Manager`/`Helper`/`Utils` abstractions as review findings.
- For each finding record the concrete evidence, affected actor, owning boundary, selected behavior-preserving Fowler refactoring, and focused verification. Clean blocker/high findings and unapproved medium findings before the gate passes.
- Prefer guard clauses, Extract Function, Decompose Conditional, Move Function, Split Phase, Replace Conditional with Polymorphism/State/Strategy, or Introduce Special Case only when the code has a real responsibility or variation boundary. Do not add ceremony or micro-split merely to reduce line count.

## Clean Architecture And CQRS

- Backend projects must follow Clean Architecture: Domain owns business policy; Application owns named use cases and consumer-owned ports; Infrastructure implements those ports and performs I/O; Interface adapters translate public input/output; Composition wires the concrete graph last. Dependencies point inward.
- Every actor-visible backend behavior is owned by a named Application use case. A use case orchestrates the workflow through Domain behavior and Application ports; it must not know HTTP, persistence models, cloud SDKs, framework types, or deployment details.
- Domain and application remain independent from transport, persistence, framework, cloud SDK, UI, logging implementation, and deployment details.
- This independence includes names: inner-layer symbols describe business intent or a port capability, not a concrete provider. A provider-specific adapter may implement the neutral port, but the provider name must not leak inward.
- Interface adapters translate requests, sessions, DTOs, errors, and responses; they do not own business policy.
- Infrastructure implements application-owned ports and performs I/O; it does not move business decisions outward.
- Commands change state and own authorization/validation decisions; queries read explicit projections and do not mutate state.
- Do not share command-side mutable state with query projections without an explicit consistency and ownership decision.
- Check dependency direction, cycles, forbidden references, package/module ownership, and composition-root registration.
- For every changed module and use case, record the actor, reasons to change, use-case owner, port ownership, and evidence for SRP, OCP, LSP, ISP, and DIP. A missing principle review is a clean-up finding.
- For REST/Lambda changes, handlers remain thin and the public boundary is covered by the existing HTTP integration suite.

## Complexity, Tests, And Verification

- Run formatter, compiler/typechecker, linter, architecture/dependency checks, and repository-native complexity/CRAP checks when available.
- Prefer CRAP <= 8 for modified high-risk functions when the repository supports CRAP measurement. A high score requires meaningful tests, reduced branching, or both.
- Do not use coverage padding to pass this gate. The mandatory >=90% coverage gate remains separate and must be rerun after any refactor.
- Tests should assert observable behavior, edge partitions, authorization, errors, state transitions, events, projections, HTTP responses, or UI outcomes. Avoid private internals and brittle call-order assertions.
- Refactor only with relevant tests green. If behavior or a public contract changes, stop the clean-up gate and return to SDD spec evolution.

## Conditional Complexity And Fowler Refactoring

Use this decision map; do not replace a clear two-way decision with ceremony:

| Smell | First refactoring direction |
| --- | --- |
| Nested `if/else` | Replace Nested Conditional with Guard Clauses; Decompose Conditional |
| Same predicate/outcome repeated | Consolidate Conditional Expression; Extract Function |
| Type/status selects changing behavior | Replace Conditional with Polymorphism; Replace Type Code with State/Strategy |
| Missing/default branch dominates | Introduce Special Case/Null Object |
| Boolean flag changes behavior | Replace Parameter with Explicit Methods |
| Branch mixes policy, I/O, mapping, or transport | Extract Function; move decision to its owning boundary |

Rules: identify the smell, protect behavior with tests, apply one behavior-preserving transformation, run focused tests, then continue. In Go use functions, tables, or consumer-owned strategies; in C# use strategies/polymorphism or a closed switch expression; in React use composition, discriminated strategy maps, or explicit variants. Do not add interfaces, HOCs, registries, or patterns without real variation and tests.

Reference: Martin Fowler's `Refactoring` uses small behavior-preserving transformations; its official catalog covers conditional decomposition, guard clauses, polymorphism, state/strategy, and special cases.

- [Refactoring by Martin Fowler](https://martinfowler.com/books/refactoring.html)
- [Official refactoring catalog](https://refactoring.com/catalog/index.html)

## Refactoring Rule

The clean-up gate must identify and complete the required refactoring; a findings-only review does not pass. The actual edit follows `common-sdd-refactor-lifecycle.workflow.md` and the language refactor adapter. Before production refactoring:

1. Protect current behavior with existing characterization tests, the relevant unit suite, or the applicable integration scope; frontend component tests remain in their project scope.
2. Ask for the refactor workflow approvals required by the repository's SDD gates.
3. Make one structural change at a time.
4. Run focused tests after each change, then all affected tests and gates.
5. Update the spec, task, traceability, history, documentation, and review report.

Never change acceptance expectations, business behavior, public contracts, or security policy under the label of clean up.
