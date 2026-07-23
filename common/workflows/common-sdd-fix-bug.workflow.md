---
workflow_id: WORKFLOW-COMMON_SDD_FIX_BUG_WORKFLOW
trigger: manual
description: "Diagnose and fix a defect through SDD, BDD/ATDD, TDD, Clean Architecture, CQRS, deterministic verification, and spec convergence."
---

# Common SDD Fix Bug Workflow

Use this workflow for a production defect, a regression in a verified or retired behavior, a wrong acceptance expectation, a broken test or harness, a flaky test, or an HTTP/local-resource defect. A bug is a controlled change to an existing behavior contract; it is not permission to weaken the spec or delete a failing test.

This workflow is language-neutral. Route implementation details to the applicable `go-sdd-implement-change`, `csharp-sdd-implement-change`, `react-implement-feature`, or `web-implement-frontend-change` workflow. Use this common workflow as the parent and keep one traceable bug diagnosis and one convergence owner.

## Core Decision Rules

1. Reproduce and classify the defect before changing a spec, test, or production file.
2. Preserve the approved behavior contract. Never change an acceptance scenario only to make the current implementation pass.
3. If the intended behavior is wrong or ambiguous, stop and obtain product-owner verification through the SDD spec-evolution gate.
4. Preserve diagnostic reproduction evidence, then write regression tests inside-out at the owning layer and obtain scoped Gate 3 approval before that production scope.
5. Fix the smallest root cause in the owning architectural layer. Do not hide a domain defect in an HTTP handler, adapter, query projection, or test fixture.
6. Keep commands and queries separate where CQRS is used: commands own state changes and domain decisions; queries read explicit projections and must not mutate state.
7. Use the canonical `integration` suite: `integration/http` for the real public HTTP/message/CLI/worker boundary and `integration/infrastructure` for use-case-driven real local adapter/resource wiring. Do not create a third infrastructure suite or replace domain/application unit tests with integration coverage.
8. Do not mix an unrelated cleanup, migration, architecture rewrite, or speculative abstraction into a bug fix.
9. A bug fix is ready for final validation only when the regression is green, the root cause is documented, affected tests and gates pass, the mandatory coverage gate reaches at least 90% when production code is in scope, and the owning spec converges.

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

Use `bug_kind` for diagnosis and `work_type` for the concrete task. A backend bug task still uses one canonical `work_type`, such as `domain-rule`, `application-command`, `application-query`, `rest-endpoint`, `lambda-rest-endpoint`, `sns-publisher`, `sqs-consumer`, `boundary-integration-test`, or `documentation`; route boundary work through its supporting workflow.

## Phase 0: Read-Only Diagnosis And SDD Plan

Inspect without writing files:

- Current repository state, branch, relevant Git history, blame, and recent changes when they help locate a regression.
- The latest relevant context summary when the project maintains one, active specs, verified owning spec, acceptance scenarios, contracts, decisions, and verification history.
- The exact observed behavior, expected behavior, actor, entry point, command/query, boundary, and business impact.
- Reproduction command, commit/build version, environment, input/state, frequency, logs, HTTP request/response, and resource setup.
- Candidate root cause and at least one alternative hypothesis.

Prepare and show:

- `BUG-*`, `FEAT-*`, `SPEC-*`, `US-*`, `REQ-*`, `SCN-*`, `REG-*`, `TEST-*`, `T-*`, `TRK-*`, and `CHG-*` IDs, each paired with its canonical human-readable title.
- The owning active spec, or a new active defect spec linked to `source_feature_id` and `source_spec_id` when the source is verified, retired, or ownership is unclear.
- The exact artifacts to create or modify. A defect spec normally includes `bug-report.md`, `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and one append-only `history/` entry.
- The defect classification, expected behavior, reproduction evidence, suspected root cause, non-goals, risks, rollback, and stop conditions.
- The architecture impact: SOLID responsibility, Clean Architecture boundary, CQRS command/query side, HTTP/local-resource boundary, persistence, events, UI, or CI.
- The test strategy: acceptance/public-boundary regression, focused unit/component test, HTTP integration only when applicable, and deterministic gates.
- The mandatory documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE`, with a `documentation` task routed to `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` for the defect record, regression evidence, affected project/SDD docs, and append-only history.
- Sequential and parallel tasks, exact ownership, execution waves, `max_parallel_agents`, agent slots, dependencies, `can_run_with`, and merge order. Default `max_parallel_agents: 1`.
- `workflow-routing.md` entries for diagnosis, spec update, RED, Gate 3, language implementation, coverage, documentation, and final validation.

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

1. For an active owner, use `common-sdd-spec.workflow.md` semantics and append a history entry. Do not rewrite prior history.
2. For a verified, superseded, or retired owner that no longer owns the change, create a new defect folder using the next feature number, for example `specs/features/0017-fix-notification-summary-502-proposed/`, and link the source feature/spec. Never rewrite source history to conceal the regression.
3. For a test/harness-only defect, keep the intended behavior explicit and record why production code must remain unchanged.
4. Create or update `bug-report.md` with:

```yaml
bug_id: BUG-0017-001
bug_title: Notification summary returns 502 for an empty projection
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

- User Story: `US-* — <business capability>`, including actor, capability, and business outcome.
- Requirement or invariant: `REQ-* — <required behavior>` or `INV-* — <invariant>` that the defect violates or corrects.
- Regression: `REG-* — <previously failing observable behavior>`.
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
T-<FEAT>-001 — Diagnose and record the bug evidence
T-<FEAT>-002 — Add the focused Domain RED when policy owns the defect
T-<FEAT>-003 — Pass the Domain gate and add Application RED
T-<FEAT>-004 — Pass the Application/core gate
T-<FEAT>-005 — Add public-boundary regression evidence after the core gate
T-<FEAT>-006 — Implement affected outer layers in dependency order
T-<FEAT>-007 — Refactor the fix with tests green
T-<FEAT>-008 — Run coverage and deterministic quality gates
T-<FEAT>-009 — Update documentation and converge SDD artifacts
T-<FEAT>-010 — Run final validation and record the defect spec as verified
```

Split further when a task crosses unrelated scenarios, actors, bounded contexts, architecture boundaries, or ownership. Every task declares `story_id`, `requirement_id`, `scenario_id` or `regression_id`, `test_id` when applicable, `change_id`, `track_id`, `workflow_id`, `workflow_phase`, `supporting_workflow_ids`, `work_type`, `parallelizable`, `depends_on`, `blocked_by`, `can_run_with`, owned files/modules, execution wave, agent slot, and verification method.

Update the task, verification, and change-summary records after each microtask. If consumed context reaches 60%, stop starting new diagnosis/fix tasks and invoke `common-sdd-context-checkpoint.workflow.md` before requesting a new context.

Parallelism rules:

- Diagnosis, spec editing, test writing, and production implementation are sequential by default.
- Independent evidence collection may run in parallel only when it owns disjoint files and does not change conclusions silently.
- Domain and application regression-test work remains sequential across layer gates. Boundary-test work starts only after the affected core gate; parallel work is allowed only within the same opened layer with disjoint ownership.
- Production implementation has one owner for the affected behavior. Do not have two agents edit the same domain/application boundary, public contract, migration, generated artifact, or test fixture.
- The convergence agent owns `tasks.md`, `workflow-routing.md`, `traceability.yaml`, `verification.md`, `change-summary.md`, history, documentation, and the final merge.
- Merge parallel tracks sequentially and rerun the regression plus affected tests after every merge.

## Phase 5: Human Gate 2 - Approve RED

After the approved artifacts exist, show:

- The final bug classification, User Story, regression scenario, expected behavior, and non-regression cases.
- Actual versus expected reproduction evidence and the suspected root cause.
- Files created/modified, traceability, task/track table, agent slots, and workflow routing.
- The first affected domain/application/component RED, its scoped Gate 3, layer gates, and the later public-boundary regression evidence.

Ask explicitly:

```text
The defect spec and inside-out regression plan are written. May I create and run the first affected layer test in RED?
```

Do not create, modify, or run test code before this approval.

## Phase 6: First Affected Inner-Layer RED

Existing public-boundary reproduction gathered during diagnosis remains evidence, but new backend regression test code starts at the smallest owning layer:

- Domain RED for a violated invariant, value object, entity transition, or domain service.
- Application RED for use-case orchestration when domain is unchanged or after `LAYER-GATE-DOMAIN`.
- Component RED for frontend-only behavior.
- Boundary RED immediately only when domain/application are evidence-backed `not_affected` and the defect belongs to delivery, infrastructure, or composition.

Write the smallest focused regression test for that scope.

The test must:

- Have a stable `TEST-*` ID and map to `REG-*` or the violated `REQ-*`.
- Read as Given, When, Then where practical.
- Assert the observable business outcome, returned error, state transition, event, projection, response, or UI result.
- Cover the failing partition and at least the nearest non-regression partition when the rule has a boundary.
- Avoid private implementation details, call-order assertions, snapshot-only evidence, and shallow coverage theater.
- Use real domain values and deterministic hand-written fakes/spies only for outgoing application ports.

Run it and confirm it fails for the intended reason. If it passes, investigate whether the bug is already fixed, the assertion is weak, the wrong layer is under test, or the defect is non-reproducible. Do not invent a production change.

## Phase 7: Scoped Gate 3 And Core GREEN

Invoke `common-sdd-review-test-evidence.workflow.md` for the current `domain` or `application` scope. Show the actual test, stable IDs, command, concise RED output, assertions, fixtures/doubles, architecture boundary, prior layer gates, and confirmation that production files for this scope remain unchanged.

Ask explicitly:

```text
The <domain|application> regression test is RED for the intended reason. May I modify production code for this scope and continue to Green?
```

After approval, implement the smallest core fix, refactor while green, and pass the corresponding domain/application layer gate. Repeat for application after domain when both are affected. If the user rejects the evidence, modify only the authorized spec/test artifacts, rerun RED, and request the scoped Gate 3 again. If classification changes, return to Gate 1.

## Phase 8: Public-Boundary Regression And Gate

After `LAYER-GATE-APPLICATION`, add or update public regression evidence:

- Use HTTP integration when the defect crosses REST, Lambda/API Gateway, auth/session, DI, persistence, schema, or local-resource wiring.
- Use a component/page interaction test for React/Web user-visible behavior.
- Use the closest deterministic executable boundary for CLI or tooling defects.
- Use a manual checklist only when automation is unavailable, with explicit pass/fail steps and an automation-gap note.

When outer behavior must change, confirm Boundary RED and obtain Gate 3-BOUNDARY. When the core fix already makes the public regression GREEN, record outer layers as `not_affected`; do not invent adapter or wiring changes merely to produce RED.

## Phase 9: Outer GREEN And Root-Cause Validation

After Gate 3-BOUNDARY when outer production is affected:

1. Implement only the smallest infrastructure, delivery interface, and composition/IaC changes, in that order.
2. Keep domain and application policy independent from REST, Lambda, persistence, framework, cloud SDK, UI, and deployment details.
3. Keep handlers/controllers/adapters/composition roots thin and put decisions in the owning domain/application or frontend behavior boundary.
4. Preserve SOLID: narrow responsibilities, consumer-owned interfaces, dependency inversion, and substitutable adapters.
5. Preserve CQRS: command and query responsibilities, projections, consistency, and events remain explicit.
6. Do not change the expected acceptance result, remove a regression test, broaden retries, or swallow an error to make the suite green.
7. For `test-or-harness`, change test/harness code only and prove the production behavior remains protected.
8. Rerun the focused tests and public regression evidence after each meaningful change.

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
- Boundary integration tests for REST/Lambda, message, CLI, or worker entry, including local-resource, DI, and persistence wiring when applicable.
- Build, typecheck, lint, format, architecture/dependency, schema, security, performance, and observability checks when applicable.
- Mandatory `common-sdd-clean-up-gate.workflow.md` for every created/modified file; any behavior-preserving clean up uses the refactor lifecycle and the <150-line maintained-file check for source, tests, configuration, CI, and scripts.
- Mandatory `common-sdd-security-gate.workflow.md` with declared `security_role`, changed trust boundaries, and no unresolved Critical/High findings.
- Mandatory `common-sdd-coverage-gate.workflow.md` with `>= 90%` aggregate coverage for the complete project production scope and no affected-scope regression when production code is in scope.
- Mandatory `common-sdd-update-documentation.workflow.md` through `RULE-COMMON_SDD_DOCUMENTATION_GATE` after the fix and regression evidence are green and before final validation; inspect the defect record, regression contract, SDD artifacts, project docs, and operational guidance.
- CRAP/complexity and mutation testing or targeted mutation review for high-risk business rules when available.
- Repeat-run evidence for a `flaky-or-nondeterministic` defect, including the deterministic condition that is now protected.

Record exact commands, tool versions, scope, results, exclusions, and residual risk in `verification.md` and the human-readable `change-summary.md`.

## Phase 12: Converge And Validate

Before reporting final validation:

- `bug-report.md` records classification, reproduction, root cause, fix, and evidence.
- `spec.md` and `acceptance.feature` represent the verified intended behavior.
- `change-summary.md` records all planned and actual changes and deviations.
- `plan.md` reflects the actual Clean Architecture/CQRS boundaries.
- `tasks.md`, `parallel-tracks.md`, `workflow-routing.md`, and `traceability.yaml` reflect actual tracks, agents, workflows, tests, and merge order.
- Any context checkpoint is recorded with its handoff path and exact resume action; no unfinished diagnosis is left only in chat context.
- `verification.md` records Gate 1, Gate 2, every applicable scoped Gate 3, all layer gates, the mandatory coverage result, and all relevant gates.
- The documentation gate passed through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; if no project documentation surface is affected, its workflow analysis and `no_documentation_change_reason` are recorded in `spec.md`, `verification.md`, and `change-summary.md`.
- Active defect specs use `common-sdd-verify-spec.workflow.md` to record `status: verified` at the stable path.
- A superseded source spec is never rewritten to erase the bug history; links and append-only history explain the relationship.

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
- Domain/application regression was RED before its fix and GREEN after; public-boundary evidence is GREEN, with Boundary RED recorded when outer behavior changed or an approved exception documented.
- Focused ATDD-style unit/component test was RED before production code and drove the fix.
- Each applicable scoped Gate 3 approved actual test evidence before production code for that scope.
- The smallest root-cause fix preserves SOLID, Clean Architecture, CQRS, and public contracts.
- Relevant unit and integration scopes pass; no third backend infrastructure/message suite was added.
- Final clean-up gate passes for all created/modified files, every in-scope maintained source, test, configuration, CI, and script file is below 150 physical lines, and any necessary refactor is traceable.
- Final security review passes with a declared role, no unresolved Critical/High findings, and documented OAuth/OIDC or web-session evidence when applicable.
- Coverage is measured at `>= 90%` for the complete project production scope when production code is in scope, and the affected scope does not regress.
- Documentation, spec, history, traceability, verification, and workflow routing converge through `RULE-COMMON_SDD_DOCUMENTATION_GATE`.
- Final validation records the active defect spec as `verified` only after all required evidence passes.
