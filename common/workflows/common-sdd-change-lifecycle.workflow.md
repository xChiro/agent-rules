---
workflow_id: WORKFLOW-COMMON_SDD_CHANGE_LIFECYCLE_WORKFLOW
trigger: manual
description: End-to-end SDD lifecycle for any code change: spec, human verification, ATDD, TDD, refactor, gates, and convergence.
---

# Common SDD Change Lifecycle Workflow

Use this workflow as the parent lifecycle for feature work, integration work, UI behavior, infrastructure changes, and refactors. For a defect, invoke `common-sdd-fix-bug.workflow.md` first; it owns diagnosis, classification, regression evidence, and the decision to evolve or preserve the existing contract. Language-specific workflows may add details, but they must not skip test-first evidence.

## Phase 1: Prepare And Show The SDD Plan Read-Only

Inspect the repository and prepare the smallest useful specification plan without creating or modifying files.

Include:

- Feature/spec/artifact IDs.
- User Stories: actor, capability, and business reason.
- Actor or system boundary.
- Observable behavior.
- BDD Given/When/Then acceptance scenarios.
- `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW` for business value, shared examples, abstract scenarios, and living documentation.
- Out-of-scope.
- Edge cases and failure behavior.
- Non-functional constraints when relevant: performance, security, compatibility, observability, rollback.
- SOLID, Clean Architecture, CQRS, and project-specific architecture constraints that apply.
- Existing behavior that must remain unchanged.
- Parallel track constraints: maximum agents, ownership boundaries, dependencies, and merge order.
- Test ID strategy for acceptance and unit-level tests.
- Proposed spec folder and exact artifact files.
- Proposed `workflow-routing.md` with the primary and supporting workflow for every SDD phase and task.
- Sequential and parallel tasks, track IDs, dependencies, ownership, execution waves, merge order, and `max_parallel_agents`.
- Primary `workflow_id`, `workflow_phase`, supporting workflow IDs, and rationale for each task.
- Context budget plan: small task boundaries, current/next task state, and the checkpoint route if context reaches 60%.

Use `[NEEDS CLARIFICATION]` for unresolved product decisions. Do not silently turn ambiguity into implementation.

Show the complete proposed SDD plan to the user before any spec write.

## Phase 2: Human Gate 1 - Approve Spec Writes

Ask the user/product owner explicitly for permission to create or modify the proposed spec folders and artifacts.

When verification is requested, include:

- The behavior to approve.
- Open questions.
- User Stories and BDD acceptance scenarios.
- Out-of-scope.
- Risks and tradeoffs.
- The exact sequential/parallel task proposal, track ownership, execution waves, and maximum concurrent agents.

Do not create or modify `specs/**`, history, contracts, decisions, or related spec documentation before approval. This gate cannot be skipped for low-risk, mechanical, or unambiguous work.

## Phase 3: Create Or Update The Approved Spec

After approval, create or update the approved folder and artifacts, then translate the behavior into the technical plan.

Cover:

- Architecture boundaries and ownership.
- SOLID, Clean Architecture, CQRS, and local architecture rules that constrain the design.
- Contracts, DTOs, events, schemas, or UI states touched.
- Data model and migration impact.
- Acceptance harness or public boundary to test through.
- Unit test targets.
- HTTP integration tests needed for backend public wiring and local resources; component/page tests for frontend behavior.
- Architecture, security, performance, coverage, CRAP, or mutation gates that apply.
- Rollback or operational verification when relevant.
- Parallel tracks: maximum concurrent agents, file/module ownership, dependencies, and sequential merge policy.

Select supporting boundary workflows from the task routing matrix before writing `workflow-routing.md`:

| Task surface | Supporting workflows |
| --- | --- |
| REST endpoint | `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + language REST workflow |
| API Gateway/Lambda REST | REST workflow + `WORKFLOW-COMMON_AWS_LAMBDA_REST_WORKFLOW` + language REST workflow |
| SNS publisher/domain event | `WORKFLOW-COMMON_AWS_SNS_PUBLISH_WORKFLOW` + language messaging rules |
| SQS Lambda consumer | `WORKFLOW-COMMON_AWS_SQS_CONSUMER_WORKFLOW` + language messaging rules |
| React + TypeScript + Vite REST client | `WORKFLOW-COMMON_REST_API_DESIGN_WORKFLOW` + `WORKFLOW-REACT_REST_API_CLIENT_WORKFLOW` |

The language implementation workflow remains primary. Supporting workflows are invoked at the phase that owns the boundary decision; record every invocation and result in `workflow-routing.md`, `tasks.md`, and `verification.md`.

The active spec is a mutable baseline. If repository evidence changes the approved behavior, plan, architecture, contract, risk, test strategy, scope, ordering, ownership, or gates, pause the current task. Invoke `common-sdd-evolve-spec.workflow.md`, use `common/templates/spec-adjustment-request.md`, obtain approval, update affected artifacts and append-only history, and reset impacted gates before continuing. Never absorb discovery as an unrecorded deviation.

## Phase 4: Create Sequential And Parallel Tasks

Break the plan into small tasks. Each task should reference at least one User Story, requirement or acceptance scenario, parallel track, artifact ID, test ID, verification method, and canonical backend `work_type` when applicable.

Every task must declare:

- `track_id`.
- `workflow_id` and `workflow_phase`.
- `supporting_workflow_ids` when a focused procedure is required.
- `parallelizable: true|false`.
- `depends_on` and `blocked_by`.
- `can_run_with` when safe.
- File/module/contract ownership.
- Execution wave and merge position.
- One concrete outcome, `done_when`, `verification_command`, and `next_step`.

Good task shape:

```text
T001: Add failing acceptance scenario for REQ-003.
T002: Add failing unit test for the policy invariant behind SCN-003.
T003: Implement the smallest domain/application change.
T004: Wire adapter/API/UI boundary and add boundary test.
T005: Refactor with tests green.
T006: Run gates and update convergence notes.
```

Do not create large mixed tasks. Split work by one scenario, one business rule, one boundary, one adapter, or one protected refactor.

When no tasks can run concurrently, state why and keep `max_parallel_agents: 1`. When tasks can run concurrently, show the exact task IDs assigned to each agent slot.

## Phase 5: Human Gate 2 - Approve RED

Show the written spec artifacts, final User Stories and scenarios, task/track table, parallel execution waves, traceability, risks, and the first acceptance plus unit RED tests planned.

Ask explicitly for permission to begin RED. Do not create, modify, or run test code before approval.

## Phase 6: Acceptance RED

Invoke `WORKFLOW-COMMON_BDD_SPECIFICATION_WORKFLOW`, then create the smallest executable acceptance evidence at the closest stable boundary. The scenario remains abstract and business-readable; boundary-specific setup belongs in the test implementation and verification record. Run it and confirm it fails for the intended missing behavior. If it passes before implementation, investigate the contract or harness.

When the current task is a REST, Lambda, SNS, SQS, or React REST-client boundary, invoke the selected supporting workflow after the abstract scenario is approved and before writing boundary-specific RED evidence. It may refine contracts and test setup, but it may not bypass Gate 2, the focused unit-level RED, or Gate 3.

## Phase 7: Unit-Level ATDD-Style Test RED

Write the smallest focused test for the next domain/application/component rule.

Apply `RULE-COMMON_TEST_ASSERTION_STRUCTURE`: Given/Arrange prepares, When/Act performs one behavior call, and Then/Assert is the only section that may call assertion APIs.

The unit test should:

- Have or map to a stable `TEST-*` ID.
- Name behavior in Given/When/Then or local convention.
- Use fixtures and assertions that read as Given, When, Then where practical.
- Assert observable outcome.
- Keep every `assert`, `require`, `expect`, `Should`, or equivalent call in the `Then/Assert` section; setup, action, fixtures, and helpers return data/errors instead of asserting.
- Avoid private internals and fragile call-order assertions.
- Use real values and simple fakes/spies for outgoing boundaries.

Run it and confirm it fails for the intended reason.

Do not edit production code until this unit-level test is RED. If a true unit test is impossible for the slice, write the closest unit-level/component test and document the exception in `verification.md` before production edits.

## Phase 8: Human Gate 3 - Review Test Evidence Before Green

Invoke `common-sdd-review-test-evidence.workflow.md` after the acceptance/public-boundary and focused unit-level tests have been created and confirmed RED.

Show the actual test files, `TEST-*` IDs, Given/When/Then intent, commands, concise failure output, assertions, fixtures, isolation, and confirmation that production files are unchanged. Ask explicitly for permission to edit production code. Record the decision in `verification.md`.

Do not continue when the user rejects the tests. Modify only the authorized test/spec artifacts, rerun RED, and request Gate 3 again.

## Phase 9: Green

Implement the smallest code change that satisfies the current failing test.

Rules:

- Do not broaden scope.
- Do not introduce speculative abstractions.
- Keep business decisions in the owning domain/application/UI behavior boundary.
- Keep adapters focused on translation and I/O.
- Preserve Clean Architecture dependency direction and CQRS command/query separation when the project uses them.
- Stay inside the current parallel track ownership.
- Rerun the failing test after each meaningful change.
- Update `red-green-refactor.md` with the minimal implementation, command, and passing result.
- Mark the current `T-*` task and its evidence in `tasks.md`, `verification.md`, and `change-summary.md` before starting another task.

## Phase 10: Refactor

Refactor only while tests are green.

Focus on:

- Names that reveal behavior.
- Duplicate rules, mappings, permissions, and error decisions.
- Boundary leaks.
- Excessive branching or file size.
- Unused helpers, fields, ports, and extension points.
- Test clarity and acceptance harness stability.

After each small refactor, rerun the smallest relevant tests. For broad refactors, run the full affected suite before continuing.
Record the behavior-preserving changes and final green evidence in `red-green-refactor.md` before entering the gates.

## Phase 11: Verify Gates

Run the checks that match the touched surface.

Baseline:

- Targeted unit tests.
- Acceptance test or public-boundary test.
- Build/typecheck/lint/format when available.
- Mandatory `common-sdd-code-quality-gate.workflow.md` for every created/modified file, including names, size limits, ownership, Clean Code, SOLID, Clean Architecture, CQRS, complexity, duplication, and required behavior-preserving refactors.

When relevant:

- Backend HTTP integration tests or frontend component/page tests.
- Architecture/dependency checks.
- Mandatory `common-sdd-security-gate.workflow.md` with a recorded `security_role`, changed trust boundaries, security evidence, and no unresolved Critical/High findings before completion.
- Mandatory `common-sdd-coverage-gate.workflow.md` for every completed spec; with production code in scope it requires `>= 90%` aggregate coverage for the complete project production scope and no affected-scope regression.
- CRAP/complexity checks.
- `common-sdd-mutation-gate.workflow.md` for L2 non-trivial business logic and every L3 change.
- `common-sdd-critical-e2e.workflow.md` for L3 or any journey explicitly marked critical in the spec.
- `common-sdd-validate-change.workflow.md` through the `sdd-policy` CI/PR check.
- `common-sdd-context-checkpoint.workflow.md` when consumed context reaches 60% or the host warns about compaction.
- Security, performance, observability, smoke, or rollback checks.

Do not report completion with a failing gate. If a gate cannot run, state why and what risk remains.

## Phase 12: Converge

Before finishing, reconcile:

- Spec.
- Human change summary.
- Workflow routing.
- Artifact IDs and traceability records.
- User Stories.
- Acceptance scenarios.
- Plan.
- Tasks.
- Parallel tracks.
- Contracts/schemas/events.
- Code.
- Tests.
- Documentation.
- Operational notes.

If context reaches 60% before convergence, stop starting new tasks and invoke `common-sdd-context-checkpoint.workflow.md`. Update the active spec folder and request a new context; do not report the feature complete merely because the current context is ending.

If behavior, architecture, testing, CI, deployment, public contracts, or repository structure changed, invoke `common-sdd-update-documentation.workflow.md` through a traceable `documentation` task before reporting completion. If no documentation surface is affected, record `no_documentation_change_reason` in `spec.md` and `verification.md`.

When all implementation and documentation tasks are complete, invoke `common-sdd-complete-spec.workflow.md` to obtain final completion approval, create the AI snapshot, update its index, and move the feature folder to `specs/features/completed/<number>-<slug>/`.

Completion is blocked until the code-quality workflow passes for every created/modified file, the security workflow records no unresolved findings, and the coverage workflow records its command, scope, result, threshold, and exclusions in `verification.md` and `change-summary.md`; production scopes must reach `>= 90%`.

Final report should include:

- Spec or behavior implemented.
- User Stories and BDD scenarios covered.
- Acceptance evidence.
- Unit-level RED/GREEN evidence, boundary evidence, and gate evidence.
- The standardized `red-green-refactor.md` report with one entry per behavior partition.
- Context checkpoint path and resume instruction when a context handoff occurred.
- Gate 1, Gate 2, and Gate 3 decisions and evidence.
- Coverage command, affected scope, measured percentage, `>= 90%` threshold, and exclusions.
- Parallel track outcome and agent count if multiple tracks were used.
- Code-quality gate result, reviewed file scope, metrics, findings, refactors, exceptions, and human decision.
- Security gate result, `security_role`, trust-boundary review, commands, findings, exceptions, and residual risk.
- Refactors performed.
- Files changed.
- Residual risk or manual verification still needed.
- Any spec-adjustment request, approved delta, repeated gates, and exact resume action.
- Documentation task outcome or explicit `no_documentation_change_reason`.
- Completion approval, completed-spec path, snapshot ID/path, and snapshot-index evidence.
