---
workflow_id: WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW
trigger: manual
description: Diagnose and fix a defect through SDD, BDD/ATDD, TDD, Clean Architecture, CQRS, deterministic verification, and spec convergence.
---

# Common SDD Fix Bug Workflow

Use this workflow for a production defect, a regression in a completed spec, a wrong acceptance expectation, a broken test or harness, a flaky test, or an HTTP/local-resource defect. A bug is a controlled change to an existing behavior contract; it is not permission to weaken the spec or delete a failing test.

This workflow is language-neutral. Route implementation details to the applicable `go-sdd-implement-change`, `csharp-sdd-implement-change`, `react-implement-feature`, or `web-implement-frontend-change` workflow. Use this common workflow as the parent and keep one traceable bug diagnosis and one convergence owner.

## Core Decision Rules

1. Reproduce and classify the defect before changing a spec, test, or production file.
2. Preserve the approved behavior contract. Never change an acceptance scenario only to make the current implementation pass.
3. If the intended behavior is wrong or ambiguous, stop and obtain product-owner verification through the SDD spec-evolution gate.
4. Write the regression acceptance evidence first, then the focused ATDD-style unit/component test, and obtain Gate 3 approval before production code.
5. Fix the smallest root cause in the owning architectural layer. Do not hide a domain defect in an HTTP handler, adapter, query projection, or test fixture.
6. Keep commands and queries separate where CQRS is used: commands own state changes and domain decisions; queries read explicit projections and must not mutate state.
7. Use HTTP integration tests only for the real public boundary and local resources. Do not create a second infrastructure test suite or replace domain/application unit tests with HTTP coverage.
8. Do not mix an unrelated cleanup, migration, architecture rewrite, or speculative abstraction into a bug fix.
9. A bug fix is complete only when the regression is green, the root cause is documented, affected tests and gates pass, the mandatory coverage gate reaches at least 90% when production code is in scope, and the owning spec converges.

## Defect Classification

Assign one `bug_kind` after evidence is collected. The classification is part of the spec and may change only with recorded evidence.

| `bug_kind` | Meaning | Default action |
|---|---|---|
| `production-behavior` | Code violates an already-approved User Story, invariant, contract, or scenario. | Keep the contract, add missing regression evidence, and fix production code test-first. |
| `spec-contract` | The written User Story, requirement, scenario, or contract does not represent the verified product intent. | Obtain product verification, evolve the spec first, then implement the approved behavior change. |
| `test-or-harness` | The test, fixture, parser, fake, acceptance harness, or assertion is wrong or coupled to an implementation detail. | Protect the intended behavior, fix only the test/harness after RED evidence, and prove production behavior was not weakened. |
| `flaky-or-nondeterministic` | The same evidence changes across repeated runs without an intended behavior change. | Capture frequency and environment, isolate shared state/time/concurrency, and fix determinism before changing expectations. |
| `http-or-local-resource` | The public HTTP boundary, Lambda/API Gateway mapping, DI, persistence, or local resource wiring is wrong. | Keep business policy in domain/application, reproduce through HTTP, and fix the adapter/composition/resource boundary. |
| `duplicate-or-not-reproducible` | The defect is already fixed, duplicated, or cannot be reproduced with the supplied evidence. | Do not invent a code change; record the evidence, link the owning item, and close or request more evidence. |

Use `bug_kind` for diagnosis and `work_type` for the concrete task. A backend bug task still uses one canonical `work_type`, such as `domain-rule`, `application-command`, `application-query`, `rest-endpoint`, `lambda-rest-endpoint`, `sns-publisher`, `sqs-consumer`, `http-integration-test`, or `documentation`; route boundary work through its supporting workflow.

## Phase 0: Read-Only Diagnosis And SDD Plan

Inspect without writing files:

- Current repository state, branch, relevant Git history, blame, and recent changes when they help locate a regression.
- The latest relevant AI snapshot, active specs, completed owning spec, acceptance scenarios, contracts, decisions, and verification history.
- The exact observed behavior, expected behavior, actor, entry point, command/query, boundary, and business impact.
- Reproduction command, commit/build version, environment, input/state, frequency, logs, HTTP request/response, and resource setup.
- Candidate root cause and at least one alternative hypothesis.

Prepare and show:

- `BUG-*`, `FEAT-*`, `SPEC-*`, `US-*`, `REQ-*`, `SCN-*`, `REG-*`, `TEST-*`, `T-*`, `TRK-*`, and `CHG-*` IDs.
- The owning active spec, or a new active defect spec linked to `source_feature_id` and `source_spec_id` when the source is completed or ownership is unclear.
- The exact artifacts to create or modify. A defect spec normally includes `bug-report.md`, `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and one append-only `history/` entry.
- The defect classification, expected behavior, reproduction evidence, suspected root cause, non-goals, risks, rollback, and stop conditions.
- The architecture impact: SOLID responsibility, Clean Architecture boundary, CQRS command/query side, HTTP/local-resource boundary, persistence, events, UI, or CI.
- The test strategy: acceptance/public-boundary regression, focused unit/component test, HTTP integration only when applicable, and deterministic gates.
- Sequential and parallel tasks, exact ownership, execution waves, `max_parallel_agents`, agent slots, dependencies, `can_run_with`, and merge order. Default `max_parallel_agents: 1`.
- `workflow-routing.md` entries for diagnosis, spec update, RED, Gate 3, language implementation, coverage, documentation, and completion.

Do not create or modify any spec artifact during this phase.

## Phase 1: Human Gate 1 - Approve Diagnosis And Spec Writes

Show the complete diagnosis and ask explicitly:

```text
The defect has been classified and the proposed SDD artifacts and history are ready.
May I create or modify the listed spec folders and files?
```

Gate 1 must cover:

- Actual versus expected behavior and the evidence supporting the classification.
- User Story, BDD Given/When/Then regression scenario, and out-of-scope.
- Whether the source spec is preserved, evolved, or linked from a new defect spec.
- Proposed tests before production code and the exact Gate 3 evidence.
- Root-cause hypotheses, architecture constraints, parallel tracks, and risks.

Approval to diagnose is not approval to write spec files, tests, or production code.

## Phase 2: Anchor The Defect In The Spec

After Gate 1 approval:

1. For an active owner, use `common-sdd-evolve-spec.workflow.md` semantics and append a history entry. Do not rewrite prior history.
2. For a completed owner, create a new active defect folder using the next feature number, for example `specs/features/0017-fix-notification-summary-502/`, and link the source feature/spec. Do not edit the completed spec folder to conceal the regression.
3. For a test/harness-only defect, keep the intended behavior explicit and record why production code must remain unchanged.
4. Create or update `bug-report.md` with:

```yaml
bug_id: BUG-0017-001
bug_kind: production-behavior
severity: high
status: proposed
source_feature_id: FEAT-0012
source_spec_id: SPEC-0012
found_in: <version-or-commit>
```

Record reproduction steps, actual result, expected result, impact, frequency, evidence, environment, suspected root cause, alternatives rejected, and links to `US-*`, `REQ-*`, `SCN-*`, `REG-*`, and `TEST-*`.

5. Add a new history entry describing the defect and why the chosen owner/spec path is correct.
6. Update `change-summary.md` with a `CHG-*` row for every planned test, production, infrastructure, documentation, CI, contract, migration, and operational change.

## Phase 3: Define The Regression Contract

The defect must have a behavior contract before implementation:

- User Story: `US-*`, including actor, capability, and business outcome.
- Requirement or invariant: `REQ-*` or `INV-*` that the defect violates or corrects.
- Regression ID: `REG-*` describing the previously failing behavior.
- BDD scenario in `acceptance.feature`, using observable Given/When/Then behavior.
- Expected result, error/status behavior, authorization behavior, state transition, emitted event, projection, or UI outcome.
- Boundary and resource assumptions, including HTTP status, headers, payload, persistence, local resource, or Lambda mapping when applicable.
- Non-regression cases: valid behavior that must remain unchanged.
- Out-of-scope and rollback behavior.

Do not encode the suspected class, method, table, adapter, or mock in the acceptance scenario. Those details belong in `plan.md` and tests only when they are necessary to protect an architectural boundary.

For CQRS defects, state separately:

- Command-side behavior: authorization, validation, aggregate/domain decision, state change, and domain event.
- Query-side behavior: read model/projection, filtering, ordering, mapping, and consistency expectation.
- The boundary that proves each side without making a query mutate state or a command depend on a query projection accidentally.

## Phase 4: Plan Small Root-Cause Tasks And Tracks

Create small tasks in dependency order. Each task has one reproducible outcome, `done_when`, a narrow verification command, and one next step. A recommended defect sequence is:

```text
T001 Diagnose and record BUG-* evidence.
T002 Add or update the BDD/public-boundary regression test.
T003 Add the focused ATDD-style unit/component test for the owning rule.
T004 Review RED evidence at Gate 3.
T005 Implement the smallest root-cause fix in the owning layer.
T006 Run targeted tests and relevant HTTP integration tests.
T007 Refactor only with tests green.
T008 Run coverage and deterministic quality gates.
T009 Update documentation and converge all SDD artifacts.
T010 Complete the spec, snapshot it, and move it to `specs/features/completed/<number>-<slug>/` after Gate 4.
```

Split further when a task crosses unrelated scenarios, actors, bounded contexts, architecture boundaries, or ownership. Every task declares `story_id`, `requirement_id`, `scenario_id` or `regression_id`, `test_id` when applicable, `change_id`, `track_id`, `workflow_id`, `workflow_phase`, `supporting_workflow_ids`, `work_type`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, owned files/modules, execution wave, agent slot, and verification method.

Update the task, verification, and change-summary records after each microtask. If consumed context reaches 60%, stop starting new diagnosis/fix tasks and invoke `common-sdd-context-checkpoint.workflow.md` before requesting a new context.

Parallelism rules:

- Diagnosis, spec editing, test writing, and production implementation are sequential by default.
- Independent evidence collection may run in parallel only when it owns disjoint files and does not change conclusions silently.
- Acceptance-test authoring and unit-test authoring may be separate tracks only after Gate 2 and only when they own different files; both must finish before Gate 3.
- Production implementation has one owner for the affected behavior. Do not have two agents edit the same domain/application boundary, public contract, migration, generated artifact, or test fixture.
- The convergence agent owns `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, `change-summary.md`, history, documentation, snapshot, and the final merge.
- Merge parallel tracks sequentially and rerun the regression plus affected tests after every merge.

## Phase 5: Human Gate 2 - Approve RED

After the approved artifacts exist, show:

- The final bug classification, User Story, regression scenario, expected behavior, and non-regression cases.
- Actual versus expected reproduction evidence and the suspected root cause.
- Files created/modified, traceability, task/track table, agent slots, and workflow routing.
- The acceptance/public-boundary test and focused ATDD-style unit/component test that will be written first.

Ask explicitly:

```text
The defect spec and regression plan are written. May I create and run the acceptance and focused unit/component tests in RED?
```

Do not create, modify, or run test code before this approval.

## Phase 6: Acceptance/Public-Boundary RED

Create or update the regression evidence first:

- Prefer the existing acceptance harness or a real HTTP endpoint for backend public behavior.
- Use HTTP integration when the defect crosses REST, Lambda/API Gateway, auth/session, DI, persistence, schema, or local-resource wiring.
- Use a component/page interaction test for React/Web user-visible behavior.
- Use the closest deterministic executable boundary for CLI or tooling defects.
- Use a manual checklist only when automation is unavailable, with explicit pass/fail steps and an automation-gap note.

Run the regression evidence and capture:

- Command, environment, commit/version, repeat count, and concise failure output.
- Why the failure proves the reported defect rather than a missing dependency or invalid fixture.
- `BUG-*`, `REG-*`, `SCN-*`, and `TEST-*` mapping.

If it passes before the fix, stop. Investigate whether the bug is already fixed, the assertion is weak, the scenario uses the wrong boundary, or the defect is non-reproducible. Do not continue by inventing a production change.

## Phase 7: Unit-Level ATDD/TDD RED

After the regression evidence exists, write the smallest focused test for the owning policy, use case, command handler, query handler, component, or boundary translation.

The test must:

- Have a stable `TEST-*` ID and map to `REG-*` or the violated `REQ-*`.
- Read as Given, When, Then where practical.
- Assert the observable business outcome, returned error, state transition, event, projection, response, or UI result.
- Cover the failing partition and at least the nearest non-regression partition when the rule has a boundary.
- Avoid private implementation details, call-order assertions, snapshot-only evidence, and shallow coverage theater.
- Use deterministic fakes/spies for outgoing ports and real values for business inputs.

Run it and confirm it fails for the intended reason. Before production code, apply `common-sdd-review-test-evidence.workflow.md`.

## Phase 8: Human Gate 3 - Review Test Evidence Before Green

Show the actual acceptance/public-boundary and focused unit/component tests, stable IDs, commands, concise RED output, assertions, fixtures, resource isolation, architecture boundary, and confirmation that production files remain unchanged.

Ask explicitly:

```text
The regression and focused ATDD-style tests are written and RED for the intended reason. May I modify production code and continue to Green?
```

If the user rejects the evidence, modify only the authorized spec/test/harness artifacts, rerun RED, and request Gate 3 again. If the classification changes, return to Gate 1 and update the spec before continuing.

## Phase 9: Green - Fix The Root Cause

After Gate 3 approval:

1. Implement only the smallest change that makes the focused test pass.
2. Keep domain and application policy independent from REST, Lambda, persistence, framework, cloud SDK, UI, and deployment details.
3. Keep handlers/controllers/adapters/composition roots thin and put decisions in the owning domain/application or frontend behavior boundary.
4. Preserve SOLID: narrow responsibilities, consumer-owned interfaces, dependency inversion, and substitutable adapters.
5. Preserve CQRS: command and query responsibilities, projections, consistency, and events remain explicit.
6. Do not change the expected acceptance result, remove a regression test, broaden retries, or swallow an error to make the suite green.
7. For `test-or-harness`, change test/harness code only and prove the production behavior remains protected.
8. Rerun the focused test after each meaningful change, then the regression evidence.

If the root cause reveals a new requirement, public contract, data migration, security constraint, or architecture decision, stop and return to Gate 1. Do not extend the bug fix silently.

## Phase 10: Refactor Only While Green

Use `common-sdd-refactor-lifecycle.workflow.md` semantics for behavior-preserving cleanup:

- Remove the smallest duplication or boundary leak exposed by the fix.
- Keep commands, queries, policies, mappings, and adapters cohesive.
- Avoid unrelated renames, layer moves, framework upgrades, or broad formatting churn.
- Run the focused regression and unit tests after each structural change.
- Record any changed ownership, dependency, architecture note, or repository map.

## Phase 11: Verify And Harden

Run checks matching the defect surface:

- Focused unit tests and the full affected unit suite.
- Regression acceptance/public-boundary evidence.
- HTTP integration tests for REST/Lambda/local-resource/DI/persistence wiring.
- Build, typecheck, lint, format, architecture/dependency, schema, security, performance, and observability checks when applicable.
- Mandatory `common-sdd-code-quality-gate.workflow.md` for every created/modified file; any behavior-preserving cleanup uses the refactor lifecycle.
- Mandatory `common-sdd-security-gate.workflow.md` with declared `security_role`, changed trust boundaries, and no unresolved Critical/High findings.
- Mandatory `common-sdd-coverage-gate.workflow.md` with `>= 90%` aggregate coverage for the complete project production scope and no affected-scope regression when production code is in scope.
- CRAP/complexity and mutation testing or targeted mutation review for high-risk business rules when available.
- Repeat-run evidence for a `flaky-or-nondeterministic` defect, including the deterministic condition that is now protected.

Record exact commands, tool versions, scope, results, exclusions, and residual risk in `verification.md` and the human-readable `change-summary.md`.

## Phase 12: Converge And Complete

Before reporting completion:

- `bug-report.md` records classification, reproduction, root cause, fix, and evidence.
- `spec.md` and `acceptance.feature` represent the verified intended behavior.
- `change-summary.md` records all planned and actual changes and deviations.
- `plan.md` reflects the actual Clean Architecture/CQRS boundaries.
- `tasks.md`, `parallel-tracks.md`, `workflow-routing.md`, and `traceability.yaml` reflect actual tracks, agents, workflows, tests, and merge order.
- Any context checkpoint is recorded with its handoff path and exact resume action; no unfinished diagnosis is left only in chat context.
- `verification.md` records Gate 1, Gate 2, Gate 3, the mandatory coverage result, and all relevant gates.
- Documentation uses `common-sdd-update-documentation.workflow.md`, or the explicit `no_documentation_change_reason` is recorded.
- Completed active defect specs use `common-sdd-complete-spec.workflow.md` for Gate 4, AI snapshot, index update, and `git mv` to `specs/features/completed/<number>-<slug>/`.
- A completed source spec is never rewritten to erase the bug history; links and append-only history explain the relationship.

## Stop Conditions

Stop and ask for a new decision when:

- The expected behavior is ambiguous or conflicts with the current approved User Story.
- The defect cannot be reproduced and no deterministic evidence exists.
- The acceptance regression passes before the fix without a documented explanation.
- The proposed fix requires weakening, deleting, or broadening an acceptance assertion.
- The root cause requires a new contract, migration, architecture exception, or unrelated refactor.
- Two tracks need to edit the same file, public contract, migration, generated artifact, or ownership boundary.
- A required coverage result remains below 90%, a critical gate fails, or a test is flaky without a verified cause.

## Bug-Fix Definition Of Done

- `BUG-*` is classified and linked to an owning `FEAT-*`/`SPEC-*`.
- Actual and expected behavior, reproduction evidence, impact, and root cause are recorded.
- User Story and BDD Given/When/Then regression evidence exist.
- Acceptance/public-boundary regression was RED before the fix and GREEN after it, or a documented boundary exception is approved.
- Focused ATDD-style unit/component test was RED before production code and drove the fix.
- Gate 3 approved the actual test evidence before production code.
- The smallest root-cause fix preserves SOLID, Clean Architecture, CQRS, and public contracts.
- Relevant unit and HTTP integration suites pass; no second backend infrastructure suite was added.
- Final code-quality review passes for all created/modified files and any necessary refactor is traceable.
- Final security review passes with a declared role, no unresolved Critical/High findings, and documented OAuth/OIDC or web-session evidence when applicable.
- Coverage is measured at `>= 90%` for the complete project production scope when production code is in scope, and the affected scope does not regress.
- Documentation, spec, history, traceability, verification, and workflow routing converge.
- Gate 4 completes the active defect spec, creates the AI snapshot, and moves it to `specs/features/completed/<number>-<slug>/`.
