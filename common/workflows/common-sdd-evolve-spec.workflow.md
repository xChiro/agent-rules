---
workflow_id: WORKFLOW-COMMON_SDD_EVOLVE_SPEC_WORKFLOW
trigger: manual
description: Evolve an existing SDD spec with append-only history, verification, updated acceptance scenarios, tasks, and convergence.
---

# Common SDD Evolve Spec Workflow

Use this workflow when a feature already has a spec and the requested change alters behavior, contracts, risk, architecture, or verification. Active specs are mutable living baselines; completed specs are audit evidence and are not silently reopened. For a reported defect, use `common-sdd-fix-bug.workflow.md` first; it decides whether this workflow is needed for a `spec-contract` correction or a behavior change discovered during diagnosis.

## Phase 1: Find The Owning Spec

1. Search `specs/features/` for the feature.
2. Read `spec.md`, `change-summary.md`, `acceptance.feature`, `plan.md`, `tasks.md`, `workflow-routing.md`, `parallel-tracks.md`, `traceability.yaml`, `verification.md`, and latest `history/` entries.
3. If no spec exists, switch to `common-sdd-create-spec.workflow.md`.
4. If multiple specs might own the change, include the ownership decision in Gate 1 before editing.

## Dynamic Discovery Rule

Use this rule whenever new evidence appears during diagnosis, RED, Green, Refactor, review, or convergence—not only when the user explicitly requests a spec change.

1. Pause the current microtask and preserve the last approved baseline.
2. Classify the discovery: clarification, behavior/contract, architecture/boundary, risk/security, test/harness, scope, or sequencing.
3. Analyze impact on User Stories/BDD, requirements, plan, tasks/tracks, ownership, contracts/data, tests, gates, documentation, rollback, and context budget.
4. Fill `common/templates/spec-adjustment-request.md` with evidence, proposed delta, alternatives, affected IDs/files, gates to repeat, and the exact resume action.
5. Show the analysis and request human approval. Do not edit spec artifacts, production code, acceptance expectations, or risk classification to absorb the finding silently.
6. After approval, continue this workflow: append history, update affected artifacts and traceability, rebaseline tasks, and repeat Gate 1/2/3 when intent, behavior, architecture, contract, risk, or test strategy changed.

## Phase 2: Show The SDD Modification Plan And Ask To Write

Before modifying any existing spec artifact, show:

- Files and sections proposed for modification or creation.
- IDs, User Stories, requirements, and Given/When/Then scenarios affected.
- Proposed history entry.
- Architecture, contract, data, test, and quality-gate impact.
- Tasks becoming sequential or parallel, including `track_id`, dependencies, ownership, `can_run_with`, execution waves, merge order, and proposed `max_parallel_agents`.
- Proposed workflow routing: primary workflow for each phase/task, supporting workflow IDs, and the reason for each selection.
- If this is a discovery-driven adjustment: the `spec-adjustment-request` artifact, evidence, impact analysis, affected IDs/files, alternatives, approval status, and gate reset.

Ask explicitly for approval to modify those spec artifacts. Do not write the history entry or any other spec file until approval.

## Phase 3: Record The Change Intent

Before production code changes, create a new history entry:

```text
specs/features/<feature>/history/YYYY-MM-DD-<change-slug>.md
```

Record:

- Reason for change.
- History artifact ID.
- User Stories added, changed, or removed.
- Requirements added, changed, or removed.
- Scenarios added, changed, or removed.
- Parallel tracks or maximum agent count changed.
- Workflow routing changed, including the reason and affected task/phase IDs.
- Verification requested or assumption made.
- Expected implementation impact.
- Risk and rollback notes.
- Discovery adjustment ID and the approved delta when this evolution was triggered by new evidence.

History is append-only. Do not edit old history to make the current change look planned.

## Phase 4: Update The Spec

Update only the affected spec files:

- `spec.md` for requirements, out-of-scope, edge cases, non-functional constraints, open questions, and metadata IDs.
- `change-summary.md` for every planned and actual change, affected files, workflows, tests, documentation, and deviations.
- `spec.md` for User Stories when actor, capability, or business outcome changes.
- `acceptance.feature` for BDD Given/When/Then observable scenarios and scenario/test IDs.
- `invariants.md` when domain rules change, with artifact metadata.
- `contracts/` when public APIs/events/schemas change, each with a stable artifact ID.
- `plan.md` when architecture, data, boundaries, or verification strategy changes, with artifact metadata.
- `tasks.md` for small executable tasks, each with one outcome, `done_when`, verification command, canonical backend `work_type`, `track_id`, `parallelizable`, dependencies, ownership, and `TEST-*` dependencies before production tasks.
- `workflow-routing.md` for the primary and supporting workflow IDs selected for each phase and task.
- `parallel-tracks.md` when task ownership, merge order, or concurrent agent count changes.
- `traceability.yaml` for artifact/requirement/scenario/task/track/test links.
- `verification.md` for expected gates and manual QA.

Mark unresolved behavior as `[NEEDS CLARIFICATION]`.

Keep the updated plan aligned with SOLID, Clean Architecture, CQRS, and the local project architecture. Any proposed architecture exception must be explicit in Gate 1 and reconfirmed at Gate 2 before RED.
Do not update only `plan.md`: synchronize every affected artifact, and do not continue until the approved adjustment is represented in `tasks.md`, `traceability.yaml`, `verification.md`, and `change-summary.md`.

## Phase 5: Show The Updated Spec And Ask To Start RED

Show the user/product owner:

- Files and sections modified.
- Final User Stories, requirements, Given/When/Then scenarios, and out-of-scope.
- Sequential and parallel task table, execution waves, tracks, ownership, dependencies, merge order, and `max_parallel_agents`.
- Traceability and history entry.
- First acceptance/HTTP/component RED test and first focused unit RED test planned.
- Workflow routing table for spec evolution, implementation, RED review, verification, documentation, and convergence.
- Contract, compatibility, security, privacy, operational, and architecture impact.
- Discovery adjustment analysis, proposed delta, gate reset, and human decision when applicable.
- Context budget and continuity plan: the current microtask, exact next task, and the 60% checkpoint workflow.
- Open questions, assumptions, and risks.

Ask explicitly for approval to continue to RED. Do not create, modify, or execute test code until approval. This gate is mandatory even for low-risk work.

## Phase 6: Acceptance RED

Create or update the acceptance test/scenario first.

Run it and confirm:

- It fails before implementation.
- The failure demonstrates the intended missing behavior.
- It maps to a User Story and BDD Given/When/Then scenario.
- It uses the public boundary or acceptance harness where available.

If it cannot be automated yet, record manual verification steps and the automation gap in `verification.md`.

## Phase 7: ATDD-Style Test RED

Create or update the smallest unit/component/domain/application test that drives the next rule.

The test code should use ATDD style where practical:

- Given: business context and fixtures.
- When: actor action or command/query.
- Then: observable result, state transition, event, response, or UI outcome.

Assign or map the test to a stable `TEST-*` ID in `traceability.yaml`.

Run it and confirm it fails for the intended reason. Do not edit production code until this failing unit-level test exists.

## Phase 8: Gate 3 Before Green

After the acceptance/public-boundary and focused unit-level tests are RED, invoke `common-sdd-review-test-evidence.workflow.md`.

Show the actual test files, `TEST-*` IDs, commands, failures, assertions, fixtures, isolation strategy, and confirmation that production files are unchanged. Ask explicitly for approval to edit production code. Record the decision in `verification.md`.

## Phase 9: Implement And Refactor

Implement through the SDD lifecycle:

1. Make the failing test pass.
2. Rerun acceptance and unit tests.
3. Refactor only while tests are green.
4. Rerun tests after each meaningful refactor.
5. Update tasks as they complete.
6. Keep work inside the current track ownership from `parallel-tracks.md`.
7. Use the primary workflow recorded for the task and invoke supporting workflows explicitly when required.
8. Update `verification.md` and `change-summary.md` before starting the next microtask.

If consumed context reaches 60%, stop starting new tasks and invoke `common-sdd-context-checkpoint.workflow.md`; leave the active spec ready for another AI before requesting a new context.

Do not change the spec to match an easier implementation without verification. If implementation evidence reveals a real mismatch, pause and invoke the Dynamic Discovery Rule instead of changing acceptance or plan silently.

## Phase 10: Gates And Hardening

Run checks that match the changed surface:

- Targeted unit tests.
- Acceptance/public-boundary test.
- Backend HTTP integration tests or frontend component/page tests.
- Build/lint/typecheck/format.
- Architecture/dependency checks.
- Coverage for touched critical code.
- CRAP/complexity where available.
- Mutation testing or mutation review for high-risk rules.
- Security/performance/observability checks when specified.
- Mandatory `WORKFLOW-COMMON_SDD_CODE_QUALITY_GATE_WORKFLOW` for every created/modified file, with required refactors completed through the refactor lifecycle before security and coverage completion gates.
- Mandatory `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` with a declared security role, changed-boundary review, and no unresolved findings before completion.
- Mandatory `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW` with `>= 90%` project-wide production coverage and no affected-scope regression after quality and security review when production code is in scope.
- `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` when the context threshold or compaction warning applies.

Record results in `verification.md`.

## Phase 11: Converge

Before reporting done:

- `tasks.md` reflects completed and remaining tasks.
- `parallel-tracks.md` reflects the actual maximum agent count, ownership, merge order, and conflicts resolved.
- `traceability.yaml` points to actual artifact IDs, tests, contracts, metrics, and history entry.
- `workflow-routing.md` points to valid primary/supporting workflow IDs for every phase and task.
- `verification.md` lists commands run and manual checks.
- `plan.md` reflects architecture actually used.
- `spec.md` and `acceptance.feature` match implemented behavior.
- Any docs or repository maps affected by structure changes are updated.
- A documentation task used `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, or `no_documentation_change_reason` is recorded in `spec.md` and `verification.md`.
- Code-quality review was executed and recorded in `code-quality-review.md`, `verification.md`, and `change-summary.md` before completion.
- Security review was executed and recorded in `security-review.md`, `verification.md`, and `change-summary.md` before completion.
- Coverage was executed for every completion and recorded at `>= 90%` when production code is in scope, or `coverage_scope: none` for docs-only specs.
- If a context handoff occurred, its checkpoint path and exact resume action are recorded in the active spec.
- Any discovery adjustment has an append-only history entry, approved request, synchronized artifacts, and repeated gates required by impact.
- When the feature is fully verified, invoke `WORKFLOW-COMMON_SDD_COMPLETE_SPEC_WORKFLOW`; do not rename the folder manually.

## Done

The change is done only when:

- The spec was changed before code.
- The active spec remained mutable through explicit, evidence-based adjustment requests; no plan or intent drift was silent.
- A history entry records why.
- User Stories and BDD Given/When/Then scenarios describe the behavior.
- Every changed spec artifact has a stable `ART-*` ID.
- Acceptance evidence was red before implementation and green after.
- Unit-level ATDD-style tests were red before production code and drove implementation.
- Parallel tracks were defined and respected.
- Refactor happened only with tests green.
- Gates pass or unrun gates are explicitly justified with risk.
- Spec, tasks, traceability, verification, and code converge.
- Gate 1 approved the spec modifications before they were written.
- Every changed task explicitly records sequential/parallel execution and track ownership.
- Gate 2 approved starting RED before test code was created, modified, or run.
- Gate 3 approved the actual RED evidence before production code was created or modified.
- Discovery-driven changes received the required re-approval and gate reset before continuation.
- Documentation tasks use `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` and update the affected SDD/project documentation before convergence is reported.
