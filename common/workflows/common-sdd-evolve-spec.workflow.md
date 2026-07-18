---
workflow_id: WORKFLOW-COMMON_SDD_EVOLVE_SPEC_WORKFLOW
trigger: manual
description: "Evolve an existing SDD spec with append-only history, verification, updated acceptance scenarios, tasks, and convergence."
---

# Common SDD Evolve Spec Workflow

Use this workflow when a feature already has a spec and the requested change alters behavior, contracts, risk, architecture, or verification. Specs remain living baselines at stable paths; a verified spec may evolve only through explicit approval and append-only history. For a reported defect, use `common-sdd-fix-bug.workflow.md` first; it decides whether this workflow is needed for a `spec-contract` correction or a behavior change discovered during diagnosis.

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
- IDs and canonical human-readable titles, User Stories, requirements, and Given/When/Then scenarios affected.
- Proposed history entry.
- Architecture, contract, data, test, and quality-gate impact.
- Tasks becoming sequential or parallel, including `track_id`, dependencies, ownership, `can_run_with`, execution waves, merge order, and proposed `max_parallel_agents`.
- Proposed workflow routing: primary workflow for each phase/task, supporting workflow IDs, and the reason for each selection.
- Proposed documentation gate: `RULE-COMMON_SDD_DOCUMENTATION_GATE` and a `documentation` task routed to `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`, including affected project/SDD documentation surfaces or the evidence needed for an explicit no-change outcome.
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
- `tasks.md` for small executable tasks, each with a stable ID, action-oriented human title, `development_layer`, `layer_gate`, one outcome, `done_when`, verification command, canonical backend `work_type`, `track_id`, `parallelizable`, dependencies, ownership, and same-layer `TEST-*` evidence before production tasks.
- `workflow-routing.md` for the primary and supporting workflow IDs selected for each phase and task.
- `parallel-tracks.md` when task ownership, merge order, or concurrent agent count changes.
- `traceability.yaml` for artifact/requirement/scenario/task/track/test links.
- Preserve or deliberately update the canonical title for every affected ID across all defining artifacts; a wording-only title improvement keeps the ID stable and is recorded in history.
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
- First affected domain/application unit RED, layer gates, and later acceptance/HTTP/message/component boundary evidence planned.
- Workflow routing table for spec evolution, implementation, RED review, verification, documentation, and convergence.
- Contract, compatibility, security, privacy, operational, and architecture impact.
- Discovery adjustment analysis, proposed delta, gate reset, and human decision when applicable.
- Context budget and continuity plan: the current microtask, exact next task, and the 60% checkpoint workflow.
- Open questions, assumptions, and risks.

Ask explicitly for approval to continue to RED. Do not create, modify, or execute test code until approval. This gate is mandatory even for low-risk work.

## Phase 6: Inside-Out Core RED

For backend behavior, create or update the smallest domain test first when domain policy changes, then the smallest application use-case test when orchestration changes. For frontend-only behavior, use the closest component-level test. Do not create new executable HTTP/message production scaffolding to start RED.

The test code should use ATDD style where practical:

- Given: business context and fixtures.
- When: actor action or command/query.
- Then: observable result, state transition, event, response, or UI outcome.

Assign or map the test to a stable `TEST-*` ID in `traceability.yaml`.

Run the current test and confirm it fails for the intended reason. Do not edit production code for that scope until the failing test exists.

## Phase 7: Scoped Gate 3 And Core GREEN

Invoke `common-sdd-review-test-evidence.workflow.md` as Gate 3-DOMAIN or Gate 3-APPLICATION. Show the actual test files, `TEST-*` IDs, commands, failures, assertions, fixtures, isolation strategy, and confirmation that production files are unchanged. Ask explicitly for approval to edit production code and record the decision in `verification.md`.

After approval, implement/refactor that core scope and record its layer gate before moving outward.

## Phase 8: Boundary RED And Outer GREEN

After `LAYER-GATE-APPLICATION`, create executable acceptance/public-boundary RED when boundary or wiring behavior changes, invoke Gate 3-BOUNDARY, then implement infrastructure, delivery interfaces, and composition/IaC in that order. If outer behavior is unchanged, record its layer gates as `not_affected` and run existing/new boundary evidence GREEN without inventing outer changes.

If boundary evidence cannot be automated, record manual verification steps and the automation gap in `verification.md`.

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
- Backend integration tests or frontend component/page tests.
- Build/lint/typecheck/format.
- Architecture/dependency checks.
- Coverage for touched critical code.
- CRAP/complexity where available.
- Mutation testing or mutation review for high-risk rules.
- Security/performance/observability checks when specified.
- Mandatory `WORKFLOW-COMMON_SDD_CLEAN_UP_GATE_WORKFLOW` for every created/modified file, with required refactors executed through the refactor lifecycle before security and coverage validation gates.
- Mandatory `WORKFLOW-COMMON_SDD_SECURITY_GATE_WORKFLOW` with a declared security role, changed-boundary review, and no unresolved findings before validation.
- Mandatory `WORKFLOW-COMMON_SDD_COVERAGE_GATE_WORKFLOW` with `>= 90%` project-wide production coverage and no affected-scope regression after quality and security review when production code is in scope.
- `WORKFLOW-COMMON_SDD_CONTEXT_CHECKPOINT_WORKFLOW` when the context threshold or compaction warning applies.
- Mandatory `RULE-COMMON_SDD_DOCUMENTATION_GATE`: invoke `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW` after the evolved behavior and tests are green and before final quality/security/coverage validation.

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
- The documentation gate was executed through `WORKFLOW-COMMON_SDD_UPDATE_DOCUMENTATION_WORKFLOW`; if its surface analysis finds no affected project documentation, record `no_documentation_change_reason` in `spec.md`, `verification.md`, and `change-summary.md`.
- Clean-up was executed and recorded in `code-quality-review.md`, `verification.md`, and `change-summary.md` before validation.
- Security review was executed and recorded in `security-review.md`, `verification.md`, and `change-summary.md` before validation.
- Coverage was executed before final validation and recorded at `>= 90%` when production code is in scope, or `coverage_scope: none` for documentation-only specs.
- If a context handoff occurred, its checkpoint path and exact resume action are recorded in the active spec.
- Any discovery adjustment has an append-only history entry, approved request, synchronized artifacts, and repeated gates required by impact.
- When the feature is fully verified, invoke `WORKFLOW-COMMON_SDD_VERIFY_SPEC_WORKFLOW`; keep the stable folder path.

## Done

The change is done only when:

- The spec was changed before code.
- The active spec remained mutable through explicit, evidence-based adjustment requests; no plan or intent drift was silent.
- A history entry records why.
- User Stories and BDD Given/When/Then scenarios describe the behavior.
- Every changed spec artifact has a stable `ART-*` ID.
- Domain/application evidence was red before its production scope and drove inside-out implementation.
- Executable acceptance evidence is green; Boundary RED preceded outer production when outer behavior changed.
- Parallel tracks were defined and respected.
- Refactor happened only with tests green.
- Gates pass or unrun gates are explicitly justified with risk.
- Spec, tasks, traceability, verification, and code converge.
- Gate 1 approved the spec modifications before they were written.
- Every changed task explicitly records sequential/parallel execution and track ownership.
- Gate 2 approved starting RED before test code was created, modified, or run.
- Each applicable scoped Gate 3 approved actual RED evidence before that production scope was created or modified.
- Discovery-driven changes received the required re-approval and gate reset before continuation.
- `RULE-COMMON_SDD_DOCUMENTATION_GATE` passed before convergence: the documentation workflow result and changed surfaces are recorded, or the workflow's explicit no-change result is recorded with its inspected surfaces and evidence.
