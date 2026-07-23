---
workflow_id: WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW
trigger: manual
description: "Mandatory final clean-up gate before an SDD spec can enter verified status, with Clean Code analysis, Fowler refactoring, ownership checks, and a strict source-file size limit."
---

# Common SDD Clean Up Gate Workflow

Run this workflow after the behavior is Green and before the final security, coverage, and validation review. It is mandatory before an SDD spec enters verified status. The gate reviews every file created or modified by the spec and performs the behavior-preserving refactoring required to leave the change clean, understandable, and below the source-file size limit.

Load `common-code-quality-guardrails.md`, the applicable language rules, `common-architecture-guardrails.md`, and `common-sdd-refactor-lifecycle.workflow.md`. This workflow is language-neutral. Delegate implementation details to `go-sdd-refactor-code`, `csharp-sdd-refactor-code`, or the applicable React/Web workflow while keeping this common workflow as the clean-up gate owner.

## Clean Up Gate Principles

1. Review the complete spec change set, not only the production files that caused the feature to pass.
2. Apply repository and language rules first; common thresholds are the minimum review baseline.
3. Every in-scope source, test, configuration, CI, and script file must stay below 150 physical lines. A file at 150 lines or more is a blocker until it is refactored or explicitly excluded as generated/vendor/third-party/binary with human approval.
4. Refactoring is part of this gate, not merely a recommendation. It is allowed only when behavior remains unchanged, tests are green, and the refactor lifecycle approvals are satisfied.
5. If the finding requires a behavior, contract, security, data, or architecture decision change, stop and return to spec evolution instead of hiding it in a refactor.
6. The final security and coverage gates run after this gate so they validate the final post-clean-up code.

## Phase 1: Establish The Review Scope

Read:

- The active spec, `change-summary.md`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and history.
- The approved baseline commit and the complete Git diff from that baseline.
- Every file created or modified by the spec: production code, unit tests, HTTP integration tests, component/page tests, contracts, schemas, configuration, CI/IaC, migrations, documentation, generated files, and scripts.
- `common-code-quality-guardrails.md`, language Clean Code/SOLID/architecture/testing rules, and local repository conventions.

Create or update the human-readable artifact:

```text
specs/features/<number>-<slug>-<status>/code-quality-review.md
```

Use stable metadata:

```yaml
feature_id: FEAT-0001
feature_title: Enforce notification retry limits
spec_id: SPEC-0001
spec_title: Notification retry-limit behavior
artifact_id: ART-0001-CODE-QUALITY-REVIEW
artifact_title: Notification retry-limit code-quality review
quality_review_id: QUAL-0001-001
quality_review_title: Review notification retry-limit implementation quality
status: proposed
baseline: <commit-or-reference>
scope: <affected-file-list-or-manifest>
```

Record:

- The exact review scope and exclusions. Generated/vendor files require a documented reason.
- The language, project conventions, and rules loaded for each affected path.
- The actual file list, line counts, primary responsibility, primary symbol, and ownership for every created/modified source and test file.
- The actor served by each module/type and the concrete reasons that actor could require a change.
- The duplicate-code review scope, including changed files, adjacent implementations, generated-code exclusions, and the detection method used.
- The quality commands, tool versions, configuration, and reports that will be used.
- Parallel tracks and agent slots. Default `max_parallel_agents: 1`; quality review and refactor ownership must not overlap.

## Phase 2: Analyze Files, Names, And Ownership

For every created or modified file, check:

- File name matches the primary type/component/hook/command/query/policy/adapter/schema/test and follows the language/project convention.
- Folder/package/namespace communicates business ownership instead of generic technical grouping.
- Exported symbols, functions, methods, variables, tests, and spec task names use intent-revealing names and consistent terminology.
- Domain/Application names are technology-neutral and describe business intent or consumer-owned capabilities. Reject provider names such as `DynamoDB`, `Cosmos`, `Kafka`, `SQS`, `SNS`, `Redis`, `PostgreSQL`, `EF Core`, or `AWS` in inner-layer files, packages, ports, types, DTOs, events, methods, and errors; provider names remain in outer adapters, mapping, and composition.
- No unexplained abbreviations or vague `Manager`, `Helper`, `Utils`, `Common`, `Base`, `Data`, or `Service` names hide the responsibility.
- One primary actor and one reason to change are visible at module/type boundaries. One type per file applies where the language rule requires it.
- File, function, method, handler, component, and test sizes remain within the common or stricter language thresholds.
- New files are not duplicate copies of an existing rule, mapper, validator, permission check, error mapping, fixture, or adapter.
- Search changed code and its neighboring modules for both textual duplication and semantic duplication; record every meaningful duplicate as `QUALITY-FINDING-*` or document why the similarity is intentional.
- Detect and clean spaghetti code and code smells: long or deeply nested control flow, mixed policy/I/O/mapping, god functions or types, hidden mutable state or temporal coupling, feature envy, shotgun surgery, primitive obsession at boundaries, boolean-flag branching, duplicated branches, dead code, and catch-all `Manager`/`Helper`/`Utils` abstractions.
- Tests are behavior-oriented, ATDD-style where practical, stable-ID traceable, and do not assert private implementation details.
- Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`: every assertion API must be in the test's final `// Assert` section; setup/action helpers must not assert.
- Apply `RULE-COMMON_TEST_DATA_AND_DOUBLE_PATTERNS`: review Object Mothers, Test Data Builders, SUT factories, fixtures, and doubles for fresh state, single ownership, explicit dependencies, and correct layer boundaries. Test helpers must not assert or contain business policy.
- Verify every automated test uses Given/When/Then behavior naming and the exact code sections `// Arrange`, `// Act`, and `// Assert`; `// Act` must contain exactly one executable statement on one physical line, and that statement must execute the layer-appropriate SUT/use case/public boundary. Record any violation as a test-quality finding and fix it before the gate passes.
- For Go tests, search the complete changed test scope for `require.NoError(t, err)` and remove every occurrence. Replace it with an explicit context-rich `if err != nil` check and `t.Fatalf` when continuation is unsafe, or `assert.NoError` when continuation is safe; keep the replacement in `// Assert` and preserve behavior.

Record each issue as `QUALITY-FINDING-*` with:

```text
finding_id: QUALITY-FINDING-0001-001
finding_title: Split retry policy from transport mapping
severity: blocker | high | medium | low
category: naming | file-size | function-size | responsibility | duplication | complexity | architecture | cqrs | test-quality | dead-code | dependency | documentation
file: <path>
evidence: <metric, rule, or concrete observation>
action: refactor | remove | rename | add-test | document-exception | block
task_id: T-0001-001
task_title: Extract the retry policy into its owning boundary
```

## Phase 3: Analyze Clean Code, Duplication, Architecture, And CQRS

Run the repository-native checks that exist:

- Formatter, compiler/typechecker, linter, unused-code/import/dependency checks.
- Architecture/dependency direction and cycle checks.
- Complexity/CRAP checks; target CRAP <= 8 for modified high-risk functions when supported.
- Static analysis and duplication detection when supported. Run the repository's native duplicate-code detector when available; otherwise perform a deterministic search of changed code and adjacent owners and record the exact patterns reviewed.
- Test structure checks and the relevant `unit` suite or `integration/http` / `integration/infrastructure` scope; frontend component tests remain within their applicable project scope and are not a backend runtime suite.

Review manually where tools do not provide deterministic evidence:

- SOLID and interface ownership. Apply all five principles: SRP using Robert C. Martin's *Clean Architecture* definition — **a module should be responsible to one, and only one, actor** — plus OCP, LSP, ISP, and DIP. Identify the actor, reasons to change, variation boundary, substitutability contract, interface consumer, and inward dependency for each affected module; do not reduce SRP to one method, one statement, or one function per class.
- Clean Architecture has two distinct views: ownership/development progresses Domain policy → Application use case/ports → Infrastructure/Interface → Composition; compile-time dependencies point inward as Composition/Interface/Infrastructure → Application → Domain. Verify both, plus a named use-case owner for every actor-visible backend behavior.
- Provider-neutral inner-layer naming is part of the same boundary check. A port such as `EventPublisher` or `NotificationStore` may be implemented by `KafkaEventPublisher` or `DynamoNotificationStore` only in Infrastructure; the concrete provider name must not appear in Domain/Application symbols, paths, DTOs, events, or errors.
- CQRS command/query separation, projection ownership, state mutation, and naming.
- REST/Lambda handlers, controllers, composition roots, and adapters remain thin.
- Business rules, authorization, mapping, validation, and error decisions have one owning layer.
- Duplicated code is removed when it represents the same business rule, validation, authorization, mapping, error decision, session policy, or infrastructure setup. Extract only to the correct owner; do not create a shared abstraction merely because two snippets look alike.
- No speculative abstractions, dead branches, commented-out code, magic values, or hidden side effects were introduced.
- Nested/repeated `if`/`else`, `switch`/`case`, ternary, or type/status branches are reviewed as conditional-complexity smells; record the Fowler transformation or the reason the simple branch is clearer.
- Spaghetti code and actionable smells are not findings-only work: record the concrete evidence, actor/owner, behavior-preserving Fowler refactoring, and focused verification. Block final validation until blocker/high smells are refactored or explicitly approved; do not add abstractions or mechanically micro-split without a real ownership or variation boundary.
- Documentation, contracts, CI, and spec artifacts use the same names and IDs as the implementation.

## Phase 4: Decide Whether Refactoring Is Required

Classify the result:

### Pass

No blocker/high finding remains, all medium/low findings are either fixed or explicitly accepted with owner and expiry, every in-scope maintained source, test, configuration, CI, and script file is below 150 physical lines, and the clean-up pass is verified. Continue to Phase 6.

### Clean Up Required

One or more findings require a structural improvement that preserves behavior, or a file is at/above the 150-line limit. The gate does not pass with a list of findings: every blocker/high finding, every unapproved medium finding, and every file-size violation must be remediated before the gate can pass. The agent must execute the clean-up through the lifecycle below unless the user or an authorized owner explicitly blocks or approves an exception. Before editing:

1. Add a small `T-*` refactor task and `CHG-*` change-summary row.
2. Link every finding to a User Story/requirement/scenario when relevant, a `TEST-*` protection test, track, owned files, and verification command.
3. Update `plan.md`, `tasks.md`, `parallel-tracks.md`, `workflow-routing.md`, and `traceability.yaml`.
4. Add an append-only history entry explaining the quality finding and non-goal.
5. Invoke `common-sdd-refactor-lifecycle.workflow.md` and the language refactor adapter. Do not edit production code directly from this gate.

### Spec Or Behavior Change Required

Stop the clean-up gate and return to `common-sdd-spec.workflow.md` and the normal SDD lifecycle if the proposed change would alter:

- User-visible behavior, an acceptance scenario, a public REST/Lambda/UI contract, authorization, security, data semantics, migration behavior, event semantics, or CQRS command/query responsibilities.
- A test expectation rather than the structure that implements the existing expectation.

The clean-up gate must never turn a behavior change into a refactor to avoid the RED and approval gates.

## Phase 5: Controlled Refactoring Loop

When refactoring is required:

- Confirm existing acceptance, unit, HTTP integration, or component evidence protects the behavior. Add characterization/unit protection first when it does not.
- Obtain the refactor lifecycle Gate 1 and Gate 2 approvals before creating or modifying protection tests.
- Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before production structure changes. Passing characterization evidence is acceptable when RED is not applicable; document why.
- Make one rename, extraction, responsibility move, duplication removal, or boundary correction at a time.
- For conditional smells, use one named Fowler refactoring at a time and record the before/after decision owner; prefer Extract Function, Decompose Conditional, Replace Nested Conditional with Guard Clauses, Consolidate Conditional Expression, Replace Conditional with Polymorphism/State/Strategy, Introduce Special Case, or Replace Parameter with Explicit Methods when the smell and domain variation justify them. Do not replace a simple guard or closed classification with pattern ceremony.
- Keep Clean Architecture dependency direction, SOLID, CQRS, error identity, cancellation, resource ownership, and public contracts unchanged.
- Run the smallest relevant tests after each change. Stop if any test fails unexpectedly.
- Do not mix framework upgrades, broad formatting, migrations, security changes, or unrelated cleanup.

After every refactor wave, rerun the complete clean-up analysis. A finding is not closed because a file became smaller; it is closed only when ownership, readability, architecture, and tests are demonstrably better.

## Phase 6: Re-Verify The Final Code Set

Review the final diff again and record:

- Final file list, line counts, names, primary ownership, and any documented exclusions.
- Clean Code, all five SOLID principles, actor-based SRP, named use cases, Clean Architecture dependency direction, CQRS, dependency, complexity, duplication, and dead-code results.
- Duplicate-code detector command or deterministic manual search, scope, findings, removals, intentional similarities, and exclusions.
- Unit, HTTP integration, component/page, build, typecheck, lint, and formatter results that apply.
- Refactor tasks, actual files changed, tests protecting behavior, and any remaining accepted quality exceptions.
- Whether security or public-contract surfaces changed during refactoring. If yes, rerun the security gate or return to spec evolution as appropriate.

Update `code-quality-review.md` to `status: passed` only when no blocker/high finding remains, all lower findings are fixed or approved, every in-scope maintained source, test, configuration, CI, and script file is below 150 physical lines, and the final change set is verified. Record the exact commands, versions, scopes, metrics, exceptions, and reports in `verification.md` and `change-summary.md`.

## Phase 7: Human Quality Verification

Show the user:

- `code-quality-review.md`, complete file scope, limits, names, ownership, findings, and exclusions.
- Quality commands and concise results.
- Refactors performed, tests protecting unchanged behavior, and remaining exceptions.
- Confirmation that no behavior, contract, security, data, or CQRS meaning changed under the clean-up gate.

Ask explicitly:

```text
The final clean-up gate is verified and all required Fowler-style refactors are evidenced. May I record the clean-up gate as passed and continue to the security gate, coverage gate, and final validation review?
```

If rejected, update only the authorized spec, review, test, or refactor artifacts, rerun the relevant evidence, and request verification again.

## Phase 8: Record And Route Validation

Update:

- `code-quality-review.md` with the final status, metrics, findings, refactors, exceptions, and decision.
- `verification.md` with `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW`, commands, results, file scope, and human decision.
- `change-summary.md` with quality findings, refactor changes, and evidence rows.
- `workflow-routing.md` and `traceability.yaml` with the clean-up gate, refactor workflows, `QUAL-*`, `QUALITY-FINDING-*`, `T-*`, and `TEST-*` IDs.
- `history/` with any structural ownership or refactor decision.

Only after this gate passes may the final security gate, coverage gate, and `common-sdd-verify-spec.workflow.md` run.

## Definition Of Done

- Every spec-created or spec-modified file was reviewed or explicitly excluded with evidence.
- File names, symbols, folders, responsibilities, and test names follow the applicable language and project conventions.
- Every in-scope source, test, configuration, CI, and script file is below 150 physical lines; generated/vendor/third-party/binary exclusions are documented and approved.
- Duplication, complexity, dead code, Clean Code, all five SOLID principles, actor-based SRP, named use cases, Clean Architecture, and CQRS checks pass or have approved exceptions.
- Spaghetti code and actionable code smells were removed, or each remaining exception has evidence, an owner, an expiry, and human approval.
- Every meaningful duplicate in changed or adjacent code was removed, assigned one owning module, or documented as intentional with an explicit coupling rationale and human approval.
- Any necessary refactor followed `common-sdd-refactor-lifecycle.workflow.md`, used a named behavior-preserving Fowler transformation where applicable, and kept tests green with Gate 3 evidence before production structure changes.
- No behavior, contract, security, data, or authorization change was hidden as a quality refactor.
- `code-quality-review.md`, `verification.md`, `change-summary.md`, routing, traceability, history, and code converge.
- Security and coverage gates run against the final post-refactor code before final validation.
