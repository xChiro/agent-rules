---
workflow_id: WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW
trigger: manual
description: Mandatory final code-quality review for every completed SDD spec, with Clean Code analysis, naming and size checks, architecture validation, and controlled refactoring.
---

# Common SDD Code Quality Gate Workflow

Run this workflow after the behavior is Green and before the final security, coverage, and Gate 4 completion steps. It is mandatory for every completed SDD spec. The gate reviews every file created or modified by the spec and may schedule behavior-preserving refactoring when quality findings require it.

Load `common-code-quality-guardrails.md`, the applicable language rules, `common-architecture-guardrails.md`, and `common-sdd-refactor-lifecycle.workflow.md`. This workflow is language-neutral. Delegate implementation details to `go-sdd-refactor-code`, `csharp-sdd-refactor-code`, or the applicable React/Web workflow while keeping this common workflow as the quality-gate owner.

## Quality Gate Principles

1. Review the complete spec change set, not only the production files that caused the feature to pass.
2. Apply repository and language rules first; common thresholds are the minimum review baseline.
3. A file-size or naming violation is evidence to investigate, not a reason for blind micro-splitting.
4. Refactoring is allowed only when behavior remains unchanged, tests are green, and the refactor lifecycle approvals are satisfied.
5. If the finding requires a behavior, contract, security, data, or architecture decision change, stop and return to spec evolution instead of hiding it in a refactor.
6. The final security and coverage gates run after this gate so they validate the final post-refactor code.

## Phase 1: Establish The Review Scope

Read:

- The active spec, `change-summary.md`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, history, and the latest AI snapshot.
- The approved baseline commit and the complete Git diff from that baseline.
- Every file created or modified by the spec: production code, unit tests, HTTP integration tests, component/page tests, contracts, schemas, configuration, CI/IaC, migrations, documentation, generated files, and scripts.
- `common-code-quality-guardrails.md`, language Clean Code/SOLID/architecture/testing rules, and local repository conventions.

Create or update the human-readable artifact:

```text
specs/features/<number>-<slug>/code-quality-review.md
```

Use stable metadata:

```yaml
feature_id: FEAT-0001
spec_id: SPEC-0001
artifact_id: ART-0001-CODE-QUALITY-REVIEW
quality_review_id: QUAL-0001-001
status: proposed
baseline: <commit-or-reference>
scope: <affected-file-list-or-manifest>
```

Record:

- The exact review scope and exclusions. Generated/vendor files require a documented reason.
- The language, project conventions, and rules loaded for each affected path.
- The actual file list, line counts, primary responsibility, primary symbol, and ownership for every created/modified source and test file.
- The quality commands, tool versions, configuration, and reports that will be used.
- Parallel tracks and agent slots. Default `max_parallel_agents: 1`; quality review and refactor ownership must not overlap.

## Phase 2: Analyze Files, Names, And Ownership

For every created or modified file, check:

- File name matches the primary type/component/hook/command/query/policy/adapter/schema/test and follows the language/project convention.
- Folder/package/namespace communicates business ownership instead of generic technical grouping.
- Exported symbols, functions, methods, variables, tests, and spec task names use intent-revealing names and consistent terminology.
- No unexplained abbreviations or vague `Manager`, `Helper`, `Utils`, `Common`, `Base`, `Data`, or `Service` names hide the responsibility.
- One primary responsibility and one reason to change are visible. One type per file applies where the language rule requires it.
- File, function, method, handler, component, and test sizes remain within the common or stricter language thresholds.
- New files are not duplicate copies of an existing rule, mapper, validator, permission check, error mapping, fixture, or adapter.
- Tests are behavior-oriented, ATDD-style where practical, stable-ID traceable, and do not assert private implementation details.
- Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`: every assertion API must be in the test's final `Then/Assert` section; setup/action helpers must not assert.

Record each issue as `QUALITY-FINDING-*` with:

```text
finding_id: QUALITY-FINDING-0001-001
severity: blocker | high | medium | low
category: naming | file-size | function-size | responsibility | duplication | complexity | architecture | cqrs | test-quality | dead-code | dependency | documentation
file: <path>
evidence: <metric, rule, or concrete observation>
action: refactor | remove | rename | add-test | document-exception | block
task_id: T-0001-001
```

## Phase 3: Analyze Clean Code, Architecture, And CQRS

Run the repository-native checks that exist:

- Formatter, compiler/typechecker, linter, unused-code/import/dependency checks.
- Architecture/dependency direction and cycle checks.
- Complexity/CRAP checks; target CRAP <= 8 for modified high-risk functions when supported.
- Static analysis and duplication detection when supported.
- Test structure checks and the relevant unit/HTTP/component test suite.

Review manually where tools do not provide deterministic evidence:

- SOLID responsibility and interface ownership.
- Clean Architecture dependency direction and adapter boundaries.
- CQRS command/query separation, projection ownership, state mutation, and naming.
- REST/Lambda handlers, controllers, composition roots, and adapters remain thin.
- Business rules, authorization, mapping, validation, and error decisions have one owning layer.
- No speculative abstractions, dead branches, commented-out code, magic values, or hidden side effects were introduced.
- Nested/repeated `if`/`else`, `switch`/`case`, ternary, or type/status branches are reviewed as conditional-complexity smells; record the Fowler transformation or the reason the simple branch is clearer.
- Documentation, contracts, CI, and spec artifacts use the same names and IDs as the implementation.

## Phase 4: Decide Whether Refactoring Is Required

Classify the result:

### Pass

No blocker/high finding remains, all medium/low findings are either fixed or explicitly accepted with owner and expiry, and no behavior-preserving refactor is needed. Continue to Phase 6.

### Refactor Required

One or more findings require a structural improvement that preserves behavior. The gate is not complete with a list of findings: every `blocker`/`high` and every unapproved `medium` finding must be remediated before the gate can pass. The agent must execute the refactor through the lifecycle below unless the user or an authorized owner explicitly blocks or approves an exception. Before editing:

1. Add a small `T-*` refactor task and `CHG-*` change-summary row.
2. Link every finding to a User Story/requirement/scenario when relevant, a `TEST-*` protection test, track, owned files, and verification command.
3. Update `plan.md`, `tasks.md`, `parallel-tracks.md`, `workflow-routing.md`, and `traceability.yaml`.
4. Add an append-only history entry explaining the quality finding and non-goal.
5. Invoke `common-sdd-refactor-lifecycle.workflow.md` and the language refactor adapter. Do not edit production code directly from this gate.

### Spec Or Behavior Change Required

Stop the quality gate and return to `common-sdd-evolve-spec.workflow.md` and the normal SDD lifecycle if the proposed change would alter:

- User-visible behavior, an acceptance scenario, a public REST/Lambda/UI contract, authorization, security, data semantics, migration behavior, event semantics, or CQRS command/query responsibilities.
- A test expectation rather than the structure that implements the existing expectation.

The quality gate must never turn a behavior change into a refactor to avoid the RED and approval gates.

## Phase 5: Controlled Refactoring Loop

When refactoring is required:

- Confirm existing acceptance, unit, HTTP integration, or component evidence protects the behavior. Add characterization/unit protection first when it does not.
- Obtain the refactor lifecycle Gate 1 and Gate 2 approvals before creating or modifying protection tests.
- Invoke `common-sdd-review-test-evidence.workflow.md` and obtain Gate 3 before production structure changes. Passing characterization evidence is acceptable when RED is not applicable; document why.
- Make one rename, extraction, responsibility move, duplication removal, or boundary correction at a time.
- For conditional smells, use one named Fowler refactoring at a time and record the before/after decision owner; do not replace a simple guard or closed classification with pattern ceremony.
- Keep Clean Architecture dependency direction, SOLID, CQRS, error identity, cancellation, resource ownership, and public contracts unchanged.
- Run the smallest relevant tests after each change. Stop if any test fails unexpectedly.
- Do not mix framework upgrades, broad formatting, migrations, security changes, or unrelated cleanup.

After every refactor wave, rerun the complete quality analysis. A finding is not closed because a file became smaller; it is closed only when ownership, readability, architecture, and tests are demonstrably better.

## Phase 6: Re-Verify The Final Code Set

Review the final diff again and record:

- Final file list, line counts, names, primary ownership, and any documented exclusions.
- Clean Code, SOLID, Clean Architecture, CQRS, dependency, complexity, duplication, and dead-code results.
- Unit, HTTP integration, component/page, build, typecheck, lint, and formatter results that apply.
- Refactor tasks, actual files changed, tests protecting behavior, and any remaining accepted quality exceptions.
- Whether security or public-contract surfaces changed during refactoring. If yes, rerun the security gate or return to spec evolution as appropriate.

Update `code-quality-review.md` to `status: passed` only when no blocker/high finding remains, all lower findings are fixed or approved, and the final code set is verified. Record the exact commands, versions, scopes, metrics, exceptions, and reports in `verification.md` and `change-summary.md`.

## Phase 7: Human Quality Verification

Show the user:

- `code-quality-review.md`, complete file scope, limits, names, ownership, findings, and exclusions.
- Quality commands and concise results.
- Refactors performed, tests protecting unchanged behavior, and remaining exceptions.
- Confirmation that no behavior, contract, security, data, or CQRS meaning changed under the quality gate.

Ask explicitly:

```text
The final code-quality review is complete and all required refactors are verified. May I record the quality gate as passed and continue to the security gate, coverage gate, and Gate 4?
```

If rejected, update only the authorized spec, review, test, or refactor artifacts, rerun the relevant evidence, and request verification again.

## Phase 8: Record And Route Completion

Update:

- `code-quality-review.md` with the final status, metrics, findings, refactors, exceptions, and decision.
- `verification.md` with `WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW`, commands, results, file scope, and human decision.
- `change-summary.md` with quality findings, refactor changes, and evidence rows.
- `workflow-routing.md` and `traceability.yaml` with the quality gate, refactor workflows, `QUAL-*`, `QUALITY-FINDING-*`, `T-*`, and `TEST-*` IDs.
- `history/` with any structural ownership or refactor decision.

Only after this gate passes may the completion workflow run the final security gate, coverage gate, Gate 4, snapshot, and move to `specs/features/completed/`.

## Definition Of Done

- Every spec-created or spec-modified file was reviewed or explicitly excluded with evidence.
- File names, symbols, folders, responsibilities, and test names follow the applicable language and project conventions.
- File/function/type limits, duplication, complexity, dead code, Clean Code, SOLID, Clean Architecture, and CQRS checks pass or have approved exceptions.
- Any necessary refactor followed `common-sdd-refactor-lifecycle.workflow.md`, with tests green and Gate 3 evidence before production structure changes.
- No behavior, contract, security, data, or authorization change was hidden as a quality refactor.
- `code-quality-review.md`, `verification.md`, `change-summary.md`, routing, traceability, history, and code converge.
- Security and coverage gates run against the final post-refactor code before Gate 4.
